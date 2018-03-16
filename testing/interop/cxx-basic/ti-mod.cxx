
#include <stdint.h>
#include "shared.hxx"
#include "test.h"

int A::test1(int pa, int pb)
{
	CHECK(pa == 0x101202);
	CHECK(pb == 0x303404);
	return 0x505606;
}
int b::B::test1(int pa, int pb)
{
	CHECK(pa == 0x707808);
	CHECK(pb == 0x909a0a);
	return 0x10b0c0c0;
}
