
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdarg.h>

#include "shared.h"
#include "test.h"


struct big1 gcc_func1(signed char a1, ...)
{
	va_list ap;
	struct big1 b1 = { .a = {101, -102}, };
	struct big2 b2;

	CHECK(a1 == 1);

	va_start(ap, a1);
	CHECK(va_arg(ap, int) == -2);
	CHECK(va_arg(ap, long long) == 0x3132333435363738ll);
	b2 = va_arg(ap, struct big2);
	CHECK(b2.a[0] == 1801);
	CHECK(b2.a[1] == -1802);
	CHECK(b2.a[2] == 1803);
	va_end(ap);

	return b1;
}

struct big2 gcc_func2(int a1, int a2, signed char a3, signed char a4, ...)
{
	va_list ap;
	struct big2 b2 = { .a = {201, -202, 203}, };
	CHECK(a1 == 1);
	CHECK(a2 == -2);
	CHECK(a3 == 3);
	CHECK(a4 == -4);

	va_start(ap, a4);
	CHECK(va_arg(ap, int) == 5);
	CHECK(va_arg(ap, int) == -6);
	CHECK(va_arg(ap, int) == 7);
	CHECK(va_arg(ap, long long) == 0x4182838485868788ll);
	CHECK(va_arg(ap, int) == -8);
	va_end(ap);

	return b2;
}

struct big3 gcc_func3(signed char a1, int a2, ...)
{
	va_list ap;
	struct big2 b2;
	struct big3 b3;
	unsigned int i;
	int j, k;

	CHECK(a1 == 1);
	CHECK(a2 == -2);

	for (i = 0, j = 1, k = 301; i < ARRAY_SIZE(b3.a); i++, j = -1 * j, k++) {
		b3.a[i] = j * k;
	}

	va_start(ap, a2);
	CHECK(va_arg(ap, int) == 3);
	CHECK(va_arg(ap, long long) == 0x5091929394959697ll);
	b2 = va_arg(ap, struct big2);
	CHECK(b2.a[0] == 1901);
	CHECK(b2.a[1] == -1902);
	CHECK(b2.a[2] == 1903);
	CHECK(va_arg(ap, int) == -444);
	va_end(ap);

	return b3;
}

int gcc_func_check1(void)
{
	struct big1 b1;
	struct big2 b2 = { .a = { 801, -802, 803 }, };

	b1 = ti_func1(1, -2, 0x12345678a0b0c0d0ll, b2);
	CHECK(b1.a[0] == 401);
	CHECK(b1.a[1] == -402);

	return 0;
}

int gcc_func_check2(void)
{
	struct big2 b2;

	b2 = ti_func2(1, -2, 3, -4, 5, -6, 7, 0x1020304050607080ll, -8);
	CHECK(b2.a[0] == 501);
	CHECK(b2.a[1] == -502);
	CHECK(b2.a[2] == 503);

	return 0;
}

int gcc_func_check3(void)
{
	struct big2 b2 = { .a = { 901, -902, 903 }, };
	struct big3 b3;
	unsigned int i;
	int j, k;

	b3 = ti_func3(11, -22, 33, 0x12345678a0b0c0d0ll, b2, -44);
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
