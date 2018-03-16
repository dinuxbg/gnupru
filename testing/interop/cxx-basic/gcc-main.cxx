
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <stdint.h>

#include "shared.hxx"
#include "test.h"


int main(void)
{
	A a;
	b::B b;

	CHECK(a.test1(0x101202, 0x303404) == 0x505606);
	CHECK(b.test1(0x707808, 0x909a0a) == 0x10b0c0c0);

	return EXIT_SUCCESS;
}
