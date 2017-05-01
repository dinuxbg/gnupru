
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <stdint.h>

#include "shared.h"
#include "test.h"


struct big1 gcc_func1(signed char a1, short a2, int a3)
{
	struct big1 b1 = { .a = {101, -102}, };
	CHECK(a1 == 1);
	CHECK(a2 == -2);
	CHECK(a3 == 3);
	return b1;
}

struct big2 gcc_func2(signed char a1, short a2, int a3)
{
	struct big2 b2 = { .a = {201, -202, 203}, };
	CHECK(a1 == 1);
	CHECK(a2 == -2);
	CHECK(a3 == 3);
	return b2;
}

struct big3 gcc_func3(signed char a1, short a2, int a3)
{
	struct big3 b3;
	unsigned int i;
	int j, k;

	CHECK(a1 == 1);
	CHECK(a2 == -2);
	CHECK(a3 == 3);

	for (i = 0, j = 1, k = 301; i < ARRAY_SIZE(b3.a); i++, j = -1 * j, k++) {
		b3.a[i] = j * k;
	}

	return b3;
}

int gcc_func_check1(void)
{
	struct big1 b1;

	b1 = ti_func1(1, -2, 3);
	CHECK(b1.a[0] == 401);
	CHECK(b1.a[1] == -402);

	return 0;
}

int gcc_func_check2(void)
{
	struct big2 b2;

	b2 = ti_func2(1, -2, 3);
	CHECK(b2.a[0] == 501);
	CHECK(b2.a[1] == -502);
	CHECK(b2.a[2] == 503);

	return 0;
}

int gcc_func_check3(void)
{
	struct big3 b3;
	unsigned int i;
	int j, k;

	b3 = ti_func3(1, -2, 3);
	for (i = 0, j = 1, k = 601; i < ARRAY_SIZE(b3.a); i++, j = -1 * j, k++) {
		CHECK(b3.a[i] == j * k);
	}

	return 0;
}

int main(void)
{
	gcc_func_check1();
	ti_func_check3();
	gcc_func_check2();
	ti_func_check1();
	gcc_func_check3();
	ti_func_check2();

	return EXIT_SUCCESS;
}
