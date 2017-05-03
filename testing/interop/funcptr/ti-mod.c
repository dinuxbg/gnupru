
#include <stdint.h>
#include "shared.h"
#include "test.h"

int ti_func_argpack1(signed char a1, short a2, int a3, signed char a4, long a5,
		     signed char a6, short a7, short a8, short a9, short a10,
		     int (*f)(int,int),
		     signed char a11, signed char a12, signed char a13,
		     signed char a14, signed char a15, signed char a16,
		     long a17, signed char a18, signed char a19, int a20,
		     signed char a21)
{
	CHECK(a1 == 31);
	CHECK(a2 == -32);
	CHECK(a3 == 33);
	CHECK(a4 == -34);
	CHECK(a5 == 35);
	CHECK(a6 == -36);
	CHECK(a7 == 37);
	CHECK(a8 == -38);
	CHECK(a9 == 39);
	CHECK(a10 == -40);
	CHECK(a11 == 41);
	CHECK(a12 == -42);
	CHECK(a13 == 43);
	CHECK(a14 == -44);
	CHECK(a15 == 45);
	CHECK(a16 == -46);
	CHECK(a17 == 47);
	CHECK(a18 == -48);
	CHECK(a19 == 49);
	CHECK(a20 == -50);
	CHECK(a21 == 51);

	CHECK(f(103050709, 806040200) == 11111111);
	return 0;
}

static int ti_callback(int a, int b)
{
	CHECK(a == 123456789);
	CHECK(b == 876543210);
	return 2222222;
}
int ti_func_check_argpack1(void)
{
	gcc_func_argpack1(1, -2, 3, -4, 5, -6, 7, -8, 9, -10,
			  ti_callback,
			  11, -12, 13,
			  -14, 15, -16, 17, -18, 19, -20, 21);
	return 0;
}


