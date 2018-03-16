
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <stdint.h>

#include "shared.h"
#include "test.h"

int gcc_func_argpack1(signed char a1, short a2, int a3, signed char a4, long a5,
		      signed char a6, short a7, short a8, short a9, short a10,
		      signed char a11, signed char a12, signed char a13,
		      signed char a14, signed char a15, signed char a16,
		      long a17, signed char a18, signed char a19, int a20,
		      signed char a21)
{
	CHECK(a1 == 1);
	CHECK(a2 == -2);
	CHECK(a3 == 3);
	CHECK(a4 == -4);
	CHECK(a5 == 5);
	CHECK(a6 == -6);
	CHECK(a7 == 7);
	CHECK(a8 == -8);
	CHECK(a9 == 9);
	CHECK(a10 == -10);
	CHECK(a11 == 11);
	CHECK(a12 == -12);
	CHECK(a13 == 13);
	CHECK(a14 == -14);
	CHECK(a15 == 15);
	CHECK(a16 == -16);
	CHECK(a17 == 17);
	CHECK(a18 == -18);
	CHECK(a19 == 19);
	CHECK(a20 == -20);
	CHECK(a21 == 21);

	return 0;
}

int main(void)
{
	ti_func_argpack1(31, -32, 33, -34, 35, -36, 37, -38, 39, -40, 41,
			 -42, 43, -44, 45, -46, 47, -48, 49, -50, 51);
	ti_func_check_argpack1();

	return EXIT_SUCCESS;
}
