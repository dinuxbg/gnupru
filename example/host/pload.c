#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <err.h>
#include <errno.h>

#include <libelf.h>

#include "prussdrv.h"
#include "pruss_intc_mapping.h"

#include "md5.h"

#define AM33XX_PRUSS_IRAM_SIZE               8192
#define AM33XX_PRUSS_DRAM_SIZE               8192

/*
 * PRU elf executable file for a core.
 *
 * NOTE: We rely on LD to put all Program Memory into the text ELF section,
 * and all Data Memory variables into the data ELF section. Bss and ro.data
 * should be merged into data!
 */
struct pruelf {
	int fd;
	Elf *e;
	Elf_Scn *text;
	Elf32_Shdr *text_shdr;
	Elf_Scn *data;
	Elf32_Shdr *data_shdr;
};

struct prufw {
	int coreid;
	struct pruelf elf;
	void *dmem;
};

static int pru_open_elf(struct pruelf *elf, const char *filename)
{
	const unsigned int text_flags = SHF_ALLOC | SHF_EXECINSTR;
	const unsigned int data_flags = SHF_ALLOC | SHF_WRITE;
	size_t shstrndx;
	Elf_Scn *scn;

	if (elf_version(EV_CURRENT) == EV_NONE)
		errx(EXIT_FAILURE, "ELF library initialization failed: %s",
				elf_errmsg(-1));

	if ((elf->fd = open(filename, O_RDONLY, 0)) < 0)
		err(EXIT_FAILURE, "open \%s\" failed", filename);

	if ((elf->e = elf_begin(elf->fd, ELF_C_READ, NULL)) == NULL)
		errx(EXIT_FAILURE, "elf_begin() failed: %s.", elf_errmsg(-1));

	if (elf_kind(elf->e) != ELF_K_ELF)
		errx(EXIT_FAILURE, "%s is not an ELF object.", filename);

	if (elf_getshdrstrndx(elf->e, &shstrndx) != 0)
		errx(EXIT_FAILURE, "elf_getshdrstrndx() failed: %s.",
			elf_errmsg(-1));

	for (scn = NULL; (scn = elf_nextscn(elf->e, scn)) != NULL; ) {
		Elf32_Shdr *shdr;
		char *name;

		if ((shdr = elf32_getshdr(scn)) == NULL)
			errx(EXIT_FAILURE, "getshdr() failed: %s.",
					elf_errmsg(-1));
		if ((name = elf_strptr(elf->e, shstrndx, shdr->sh_name)) == NULL)
			errx(EXIT_FAILURE, "elf_strptr() failed: %s.",
					elf_errmsg(-1));

		if (!strcmp(name, ".text") && shdr->sh_flags == text_flags) {
			elf->text = scn;
			elf->text_shdr = shdr;
		}
		if (!strcmp(name, ".data") && shdr->sh_flags == data_flags) {
			elf->data = scn;
			elf->data_shdr = shdr;
		}
		/* printf ("Parsing section %s\n", name); */
	}

	if (!elf->data)
		warnx("%s: could not find a .data section\n", filename);
	if (!elf->text)
		warnx("%s: could not find a .text section\n", filename);

	return elf->data && elf->text ? 0 : -1;
}

static int pru_load_elf_section(unsigned int memid,
		size_t memsize, Elf_Scn *scn)
{
	Elf_Data *data;
	size_t n;

	data = NULL;
	n = 0;
	while (n < memsize && (data = elf_getdata(scn, data)) != NULL) {
		prussdrv_pru_write_memory(memid, n, data->d_buf, data->d_size);
		n += data->d_size;
	}

	return 0;
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

	if (fw->elf.text_shdr->sh_size > AM33XX_PRUSS_IRAM_SIZE)
		errx(EXIT_FAILURE, "TEXT file section cannot fit in IRAM.\n");
	if (fw->elf.data_shdr->sh_size > AM33XX_PRUSS_DRAM_SIZE)
		errx(EXIT_FAILURE, "DATA file section cannot fit in DRAM.\n");

	prussdrv_pru_disable(coreid);
	prussdrv_map_prumem (dram_id, &fw->dmem);

	/* TODO: take care of non-zero DATA or TEXT load address. */
	pru_load_elf_section(iram_id, fw->elf.text_shdr->sh_size, fw->elf.text);
	pru_load_elf_section(dram_id, fw->elf.data_shdr->sh_size, fw->elf.data);

	return ret;
}

static int pru_close_elf(struct prufw *fw)
{
	elf_end(fw->elf.e);
	close(fw->elf.fd);

	memset(fw, 0, sizeof(*fw));
	
	return 0;
}

extern const char random_data_buf[];
extern const int random_data_buf_size;

static int pru_find_symbol_addr(struct prufw *fw, const char *symstr,
				uint32_t *addr)
{
	int symbol_count, i;
	Elf *elf;
	Elf_Scn *scn = NULL;
	Elf32_Shdr *shdr;
	Elf_Data *edata = NULL;

	elf = elf_begin(fw->elf.fd, ELF_C_READ, NULL);

	while((scn = elf_nextscn(elf, scn)) != NULL) {
		shdr = elf32_getshdr(scn);

		if(shdr->sh_type != SHT_SYMTAB)
			continue;

		edata = elf_getdata(scn, edata);
		symbol_count = shdr->sh_size / shdr->sh_entsize;

		for(i = 0; i < symbol_count; i++) {
			Elf32_Sym *sym;
			const char *s;

			sym = &((Elf32_Sym *)edata->d_buf)[i];
			s = elf_strptr(elf, shdr->sh_link, sym->st_name);

			if ((ELF32_ST_BIND(sym->st_info) == STB_GLOBAL)
				&& ELF32_ST_TYPE(sym->st_info) == STT_OBJECT
				&& !strcmp(symstr, s)) {

				*addr = sym->st_value;
				printf("%s: %08x\n", symstr, sym->st_value);
				return 0;

			}
		}
	}

	return -1;
}

static int pru_check_md5sum(struct prufw *fw)
{
	MD5_CTX md5ctx;
	unsigned char md5pru[16];
	unsigned char md5ref[16];
	uint32_t md5_offset;

	MD5_Init(&md5ctx);
	MD5_Update(&md5ctx, random_data_buf, random_data_buf_size);
	MD5_Final(md5ref, &md5ctx);

	if (pru_find_symbol_addr(fw, "md5res", &md5_offset)) {
		warnx("no MD5 buffer found in PRU%d firmware\n", fw->coreid);
		return -EIO;
	}

	memcpy(md5pru, (uint8_t *)fw->dmem + md5_offset, sizeof(md5pru));

	if (memcmp(md5pru, md5ref, sizeof(md5ref))) {
		unsigned int i;
		const uint8_t *host = (void *)md5ref;
		uint8_t *pru = (void *)md5pru;

		warnx("PRU%d: MD5 mismatch!\n", fw->coreid);
		printf("HOST PRU\n");
		for (i = 0; i < sizeof(md5ref); i++) {
			printf("%02x   %02x\n", *host++, *pru++);
		}

		return -EIO;
	}

	printf("MD5 sum has been successfully calculated by PRU%d.\n",
			fw->coreid);

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
	ret = pru_load_elf(1, &fw[1], argv[2]);
	if (ret)
		errx(EXIT_FAILURE, "could not load \"%s\".\n", argv[2]);

	printf("Starting ...\n");
	prussdrv_pru_enable(0);
	prussdrv_pru_enable(1);

	/* let it run for some time */
	usleep(5 * 1000 * 1000);

	/* disable PRU and close memory mapping */
	printf("Stopping PRU... ");
	fflush(stdout);
	prussdrv_pru_disable(0);
	prussdrv_pru_disable(1);

	pru_check_md5sum(&fw[1]);

	pru_close_elf(&fw[0]);
	pru_close_elf(&fw[1]);
	prussdrv_exit();

	printf("done.\n");

	return EXIT_SUCCESS;
}
