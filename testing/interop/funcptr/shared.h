
#include <stdint.h>

int gcc_func_argpack1(signed char a1, short a2, int a3, signed char a4, long a5,
		      signed char a6, short a7, short a8, short a9, short a10,
		      int (*f)(int,int),
		      signed char a11, signed char a12, signed char a13,
		      signed char a14, signed char a15, signed char a16,
		      long a17, signed char a18, signed char a19, int a20,
		      signed char a21);

int ti_func_argpack1(signed char a1, short a2, int a3, signed char a4, long a5,
		     signed char a6, short a7, short a8, short a9, short a10,
		     int (*f)(int,int),
		     signed char a11, signed char a12, signed char a13,
		     signed char a14, signed char a15, signed char a16,
		     long a17, signed char a18, signed char a19, int a20,
		     signed char a21);

int ti_func_check_argpack1(void);
