
#include <stdint.h>
#include "shared.h"
#include "test.h"

struct big1 ti_func1(signed char a1, short a2, int a3)
{
	struct big1 b1 = { .a = {401, -402}, };
	CHECK(a1 == 1);
	CHECK(a2 == -2);
	CHECK(a3 == 3);
	return b1;
}

struct big2 ti_func2(signed char a1, short a2, int a3)
{
	struct big2 b2 = { .a = {501, -502, 503}, };
	CHECK(a1 == 1);
	CHECK(a2 == -2);
	CHECK(a3 == 3);
	return b2;
}

struct big3 ti_func3(signed char a1, short a2, int a3)
{
	struct big3 b3;
	unsigned int i;
	int j, k;

	CHECK(a1 == 1);
	CHECK(a2 == -2);
	CHECK(a3 == 3);

	for (i = 0, j = 1, k = 601; i < ARRAY_SIZE(b3.a); i++, j = -1 * j, k++) {
		b3.a[i] = j * k;
	}

	return b3;
}

int ti_func_check1(void)
{
	struct big1 b1;

	b1 = gcc_func1(1, -2, 3);
	CHECK(b1.a[0] == 101);
	CHECK(b1.a[1] == -102);

	return 0;
}

int ti_func_check2(void)
{
	struct big2 b2;

	b2 = gcc_func2(1, -2, 3);
	CHECK(b2.a[0] == 201);
	CHECK(b2.a[1] == -202);
	CHECK(b2.a[2] == 203);

	return 0;
}

int ti_func_check3(void)
{
	struct big3 b3;
	unsigned int i;
	int j, k;

	b3 = gcc_func3(1, -2, 3);
	for (i = 0, j = 1, k = 301; i < ARRAY_SIZE(b3.a); i++, j = -1 * j, k++) {
		CHECK(b3.a[i] == j * k);
	}

	return 0;
}

