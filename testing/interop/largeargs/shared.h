
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

int gcc_func1(signed char a1, short a2, int a3, signed char a4, long a5,
	      struct big1 b1,
	      signed char a6, short a7, short a8, short a9, short a10,
	      struct big2 b2,
	      signed char a11, signed char a12, signed char a13,
	      struct big3 b3,
	      signed char a14, signed char a15, signed char a16,
	      long a17, signed char a18, signed char a19, int a20,
	      signed char a21);

int gcc_func2(long long a1, long long a2, long long a3, long long a4,
	      long long a5, long long a6, long long a7, long long a8,
	      long long a9, long long a10, long long a11, long long a12,
	      long long a13, long long a14, long long a15, long long a16);

int ti_func1(signed char a1, short a2, int a3, signed char a4, long a5,
	     struct big1 b1,
	     signed char a6, short a7, short a8, short a9, short a10,
	     struct big2 b2,
	     signed char a11, signed char a12, signed char a13,
	     struct big3 b3,
	     signed char a14, signed char a15, signed char a16,
	     long a17, signed char a18, signed char a19, int a20,
	     signed char a21);

int ti_func2(long long a1, long long a2, long long a3, long long a4,
	     long long a5, long long a6, long long a7, long long a8,
	     long long a9, long long a10, long long a11, long long a12,
	     long long a13, long long a14, long long a15, long long a16);

int ti_func_check1(void);
int ti_func_check2(void);
