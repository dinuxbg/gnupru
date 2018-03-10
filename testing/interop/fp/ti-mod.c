
#include <math.h>
#include "shared.h"
#include "test.h"

int ti_func1(float a, float b, float c)
{
	CHECK(!isnan(a));
	CHECK(!isinf(b));
	CHECK(trunc(c) == 5);
	return 0;
}
