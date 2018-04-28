
#include <stdint.h>

#include "shared.h"

uint32_t ti_u32 = 0xccbbeedd;
uint16_t ti_u16 = 0x4532;
uint8_t ti_u8 = 0x25;

uint32_t *ti_ptr16 = &gcc_array16[678];
uint32_t *ti_ptr32 = &gcc_array32[123];

uint32_t ti_func_arg4(uint32_t n, uint32_t arg1, uint32_t arg2,
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

