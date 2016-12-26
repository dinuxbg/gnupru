
#include <stdint.h>

/*
 * WARNING: GCC does not support the ||SYMBOL|| construct, and instead
 * prepends an underscore to all symbol names.
 *
 * WARNING: GCC does no register packing. Hence we use only uint32_t
 * functional arguments only.
 */

#include <stdint.h>

#include "shared.h"

uint32_t ti_u32 = 0xccbbeedd;
uint16_t ti_u16 = 0x4532;
uint8_t ti_u8 = 0x25;

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

