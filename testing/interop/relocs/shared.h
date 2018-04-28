
#include <stdint.h>

uint64_t gcc_func_arg1(uint32_t arg1);
uint32_t gcc_func_arg3(uint32_t arg1, uint32_t arg2, uint32_t arg3);

uint32_t ti_func_arg4(uint32_t n, uint32_t arg1, uint32_t arg2,
		      uint32_t arg3, uint32_t arg4);

extern uint32_t ti_u32;
extern uint16_t ti_u16;
extern uint8_t ti_u8;
extern uint32_t *ti_ptr16;
extern uint32_t *ti_ptr32;
extern uint32_t gcc_array16[1024];
extern uint32_t gcc_array32[1024];

