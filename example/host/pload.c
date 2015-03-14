#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <err.h>

#include <libelf.h>

#include "prussdrv.h"
#include "pruss_intc_mapping.h"

#define AM33XX_PRUSS_IRAM_SIZE               8192
#define AM33XX_PRUSS_DRAM_SIZE               8192

/*
 * PRU elf executable file for a core.
 *
 * NOTE: We rely on LD to put all Program Memory into the PF_X ELF segment,
 * and all data, bss and ro.data memory variables into the PF_R|PF_W ELF
 * segment.
 */
struct pruelf {
	int fd;
	Elf *e;
	Elf32_Phdr *imem_phdr;
	Elf_Data *imem_data;
	Elf32_Phdr *dmem_phdr;
	Elf_Data *dmem_data;
};

struct prufw {
	int coreid;
	struct pruelf elf;
	void *dmem;
};

static int pru_open_elf(struct pruelf *elf, const char *filename)
{
	size_t phdrnum;
	Elf32_Phdr *phdr;

	if (elf_version(EV_CURRENT) == EV_NONE)
		errx(EXIT_FAILURE, "ELF library initialization failed: %s",
				elf_errmsg(-1));

	if ((elf->fd = open(filename, O_RDONLY, 0)) < 0)
		err(EXIT_FAILURE, "open \%s\" failed", filename);

	if ((elf->e = elf_begin(elf->fd, ELF_C_READ, NULL)) == NULL)
		errx(EXIT_FAILURE, "elf_begin() failed: %s.", elf_errmsg(-1));

	if (elf_kind(elf->e) != ELF_K_ELF)
		errx(EXIT_FAILURE, "%s is not an ELF object.", filename);

	if (elf_getphdrnum(elf->e, &phdrnum))
		errx(EXIT_FAILURE, "%s: elf_getphdrnum() failed: %s",
				filename, elf_errmsg(-1));

	if ((phdr = elf32_getphdr(elf->e)) == 0)
		errx(EXIT_FAILURE, "%s: elf_getphdr() failed: %s",
				filename, elf_errmsg(-1));

	while (phdrnum-- > 0) {
		if (phdr->p_flags & PF_X) {
			elf->imem_phdr = phdr;
			elf->imem_data = elf_getdata_rawchunk(elf->e,
					phdr->p_offset, phdr->p_filesz,
					SHF_ALLOC | SHF_EXECINSTR);
		} else if ((phdr->p_flags & (PF_W | PF_R)) == (PF_W | PF_R)) {
			elf->dmem_phdr = phdr;
			elf->dmem_data = elf_getdata_rawchunk(elf->e,
					phdr->p_offset, phdr->p_filesz,
					SHF_ALLOC | SHF_WRITE);
		}
		phdr++;
	}

	if (!elf->dmem_phdr || !elf->dmem_data)
		warnx("%s: could not find a .data segment\n", filename);
	if (!elf->imem_phdr || !elf->imem_data)
		warnx("%s: could not find a .text segment\n", filename);

	return elf->dmem_data && elf->imem_data ? 0 : -1;
}


static int pru_load_elf(int coreid, struct prufw *fw, const char *filename)
{
	int ret;
	unsigned int dram_id;
	unsigned int iram_id;

	memset(fw, 0, sizeof(*fw));

	fw->coreid = coreid;

	if (coreid == 0) {
		dram_id = PRUSS0_PRU0_DATARAM;
		iram_id = PRUSS0_PRU0_IRAM;
	} else if (coreid == 1) {
		dram_id = PRUSS0_PRU1_DATARAM;
		iram_id = PRUSS0_PRU1_IRAM;
	} else {
		return -1;
	}

	ret = pru_open_elf(&fw->elf, filename);
	if (ret)
		return ret;

	if (fw->elf.imem_phdr->p_memsz > AM33XX_PRUSS_IRAM_SIZE)
		errx(EXIT_FAILURE, "TEXT file section cannot fit in IRAM.\n");
	if (fw->elf.dmem_phdr->p_memsz > AM33XX_PRUSS_DRAM_SIZE)
		errx(EXIT_FAILURE, "DATA file section cannot fit in DRAM.\n");

	prussdrv_pru_disable(coreid);
	prussdrv_map_prumem (dram_id, &fw->dmem);

	/* TODO: take care of non-zero DATA or TEXT load address. */
	if (fw->elf.imem_phdr->p_memsz > fw->elf.imem_phdr->p_filesz) {
		/* must zero-fill the portion of memory not present in file
		 * (this is usually BSS segment)
		 */
		void *p = calloc(1, fw->elf.imem_phdr->p_memsz);
		prussdrv_pru_write_memory(iram_id, 0, p,
				fw->elf.imem_phdr->p_memsz);
		free(p);
	}
	prussdrv_pru_write_memory(iram_id, 0, fw->elf.imem_data->d_buf,
				fw->elf.imem_data->d_size);

	if (fw->elf.dmem_phdr->p_memsz > fw->elf.dmem_phdr->p_filesz) {
		/* must zero-fill the portion of memory not present in file
		 * (this is usually BSS segment)
		 */
		void *p = calloc(1, fw->elf.dmem_phdr->p_memsz);
		prussdrv_pru_write_memory(dram_id, 0, p,
				fw->elf.dmem_phdr->p_memsz);
		free(p);
	}
	prussdrv_pru_write_memory(dram_id, 0, fw->elf.dmem_data->d_buf,
				fw->elf.dmem_data->d_size);

	return ret;
}

static int pru_close_elf(struct prufw *fw)
{
	elf_end(fw->elf.e);
	close(fw->elf.fd);

	memset(fw, 0, sizeof(*fw));
	
	return 0;
}

int main (int argc, char *argv[])
{
	tpruss_intc_initdata pruss_intc_initdata = PRUSS_INTC_INITDATA;
	struct prufw fw[2];
	int ret;

	if (argc != 3)
		errx(EXIT_FAILURE, "Usage: %s <PRU0.elf> <PRU1.elf>\n",
				argv[0]);

	printf("Initializing the PRUs...\n");
	prussdrv_init();

	/* Open PRU Interrupt */
	ret = prussdrv_open(PRU_EVTOUT_0);
	if (ret)
		errx(EXIT_FAILURE, "prussdrv_open open failed\n");

	/* Get the interrupt initialized */
	prussdrv_pruintc_init(&pruss_intc_initdata);

	ret = pru_load_elf(0, &fw[0], argv[1]);
	if (ret)
		errx(EXIT_FAILURE, "could not load \"%s\".\n", argv[1]);
	pru_load_elf(1, &fw[1], argv[2]);
	if (ret)
		errx(EXIT_FAILURE, "could not load \"%s\".\n", argv[2]);

	printf("Starting ...\n");
	prussdrv_pru_enable(0);
	prussdrv_pru_enable(1);

	/* let it run for some time */
	usleep(30 * 1000 * 1000);

	/* disable PRU and close memory mapping */
	printf("Stopping PRU... ");
	fflush(stdout);
	prussdrv_pru_disable(0);
	prussdrv_pru_disable(1);
	
	pru_close_elf(&fw[0]);
	pru_close_elf(&fw[1]);
	prussdrv_exit();

	printf("done.\n");

	return EXIT_SUCCESS;
}
