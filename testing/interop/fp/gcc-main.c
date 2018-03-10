
#include <math.h>
#include "shared.h"
#include "test.h"

int gcc_func1(float a, float b, float c)
{
	CHECK(!isnan(a));
	CHECK(!isinf(b));
	CHECK(trunc(c) == 5);
	return 0;
}

int main(void)
{
	ti_func1(3.3, 4.4, 5.5);

	return EXIT_SUCCESS;
}
