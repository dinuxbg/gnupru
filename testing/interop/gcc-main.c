
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <stdint.h>

#include "shared.h"

static volatile void * volatile ti_relocs[3] = { &ti_u32, &ti_u16, &ti_u8 };

uint32_t gcc_u32 = 0xccbbeedd;
uint16_t gcc_u16 = 0x4532;
uint8_t gcc_u8 = 0x25;

uint64_t gcc_func_arg1(uint32_t arg1)
{
	return arg1 | ((uint64_t)arg1 + 1) << 32;
}

uint32_t gcc_func_arg3(uint32_t arg1, uint32_t arg2, uint32_t arg3)
{
	return arg1 + (arg2 >> 1) + (arg3 >> 2);
}

uint32_t gcc_func_arg4(uint32_t n, uint32_t arg1, uint32_t arg2,
		       uint32_t arg3, uint32_t arg4)
{
        uint32_t s = 0;

        while (n--) {
                uint64_t tmp = gcc_func_arg1(arg1);

                s += tmp & 0xffffffff;
                s += tmp >> 32;
                s += gcc_func_arg3(arg2, arg3, arg4);
        }

        return s;
}


int main(void)
{
	const uint32_t ARG1 = 0x54321;
	const uint32_t ARG2 = 0x12345678;
	const uint32_t ARG3 = 0xaabbccdd;
	const uint32_t ARG4 = 0x0;

	uint32_t ti_result, gcc_result;

	ti_result = ti_func_arg4(10, ARG1, ARG2, ARG3, ARG4);
	gcc_result = ti_func_arg4(10, ARG1, ARG2, ARG3, ARG4);

	printf("TI: 0x%08"PRIx32", GCC: 0x%08"PRIx32"\n", ti_result, gcc_result);

	if (gcc_u32 != *(uint32_t*)ti_relocs[0]) {
		printf("TI/GCC DATA 32-bit relocation failure!\n");
		exit(EXIT_FAILURE);
	}
	if (gcc_u16 != *(uint16_t*)ti_relocs[1]) {
		printf("TI/GCC DATA 16-bit relocation failure!\n");
		exit(EXIT_FAILURE);
	}
	if (gcc_u8 != *(uint8_t*)ti_relocs[2]) {
		printf("TI/GCC DATA 8-bit relocation failure!\n");
		exit(EXIT_FAILURE);
	}

	if (ti_result != gcc_result) {
		printf("\n\nERROR: TI AND GCC RESULTS DIFFER!\n\n");
		return EXIT_FAILURE;
	} else {
		printf("SUCCESS\n");
		return EXIT_SUCCESS;
	}
}
