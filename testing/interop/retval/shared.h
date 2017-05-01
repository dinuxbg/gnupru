
#include <stdint.h>

struct big1 {
	int a[2];
};

struct big2 {
	int a[3];
};

struct big3 {
	int a[64];
};

struct big1 gcc_func1(signed char a1, short a2, int a3);
struct big2 gcc_func2(signed char a1, short a2, int a3);
struct big3 gcc_func3(signed char a1, short a2, int a3);

struct big1 ti_func1(signed char a1, short a2, int a3);
struct big2 ti_func2(signed char a1, short a2, int a3);
struct big3 ti_func3(signed char a1, short a2, int a3);

int ti_func_check1(void);
int ti_func_check2(void);
int ti_func_check3(void);
