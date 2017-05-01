
#include <stdint.h>
#include "shared.h"
#include "test.h"

int ti_func1(signed char a1, short a2, int a3, signed char a4, long a5,
	     struct big1 b1,
	     signed char a6, short a7, short a8, short a9, short a10,
	     struct big2 b2,
	     signed char a11, signed char a12, signed char a13,
	     struct big3 b3,
	     signed char a14, signed char a15, signed char a16,
	     long a17, signed char a18, signed char a19, int a20,
	     signed char a21)
{
	unsigned int i;
	int j, k;

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

	CHECK(b1.a[0] == 101);
	CHECK(b1.a[1] == -102);

	CHECK(b2.a[0] == 201);
	CHECK(b2.a[1] == -202);
	CHECK(b2.a[2] == 203);

	for (i = 0, j = 1, k = 301; i < ARRAY_SIZE(b3.a); i++, j = -1 * j, k++) {
		CHECK(b3.a[i] == j * k);
	}
	return 0;
}

int ti_func2(long long a1, long long a2, long long a3, long long a4,
	     long long a5, long long a6, long long a7, long long a8,
	     long long a9, long long a10, long long a11, long long a12,
	     long long a13, long long a14, long long a15, long long a16)
{
	CHECK(a1 == 10);
	CHECK(a2 == -20);
	CHECK(a3 == 30);
	CHECK(a4 == -40);
	CHECK(a5 == 50);
	CHECK(a6 == -60);
	CHECK(a7 == 70);
	CHECK(a8 == -80);
	CHECK(a9 == 90);
	CHECK(a10 == -100);
	CHECK(a11 == 110);
	CHECK(a12 == -120);
	CHECK(a13 == 130);
	CHECK(a14 == -140);
	CHECK(a15 == 150);
	CHECK(a16 == -160);

	return 0;
}

int ti_func_check1(void)
{
	struct big1 b1 = { .a = {101, -102}, };
	struct big2 b2 = { .a = {201, -202, 203}, };
	struct big3 b3;
	unsigned int i;
	int j, k;

	for (i = 0, j = 1, k = 301; i < ARRAY_SIZE(b3.a); i++, j = -1 * j, k++) {
		b3.a[i] = j * k;
	}

	gcc_func1(1, -2, 3, -4, 5, b1, -6, 7, -8, 9, -10,
		 b2, 11, -12, 13,
		 b3, -14, 15, -16, 17, -18, 19, -20, 21);

	return 0;
}

int ti_func_check2(void)
{
	gcc_func2(10, -20, 30, -40, 50, -60, 70, -80, 90, -100,
		  110, -120, 130, -140, 150, -160);

	return 0;
}
