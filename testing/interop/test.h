
#include <stdio.h>
#include <stdlib.h>

#define ARRAY_SIZE(A)	(sizeof(A) / sizeof((A)[0]))

#define CHECK(B)					\
	do {						\
		if (!(B)) {				\
			printf("FAIL: %s: %s:%d\n",	\
			       TESTCASE,		\
			       __FILE__,		\
			       __LINE__);		\
			exit(EXIT_FAILURE);		\
		}					\
	} while (0)

#if defined(TESTCASE_GCCMOD)
  #define FNAME_SELF(N)	gcc_ ## N
  #define FNAME_PEER(N)	ti_ ## N
#else
  #define FNAME_SELF(N)	ti_ ## N
  #define FNAME_PEER(N)	gcc_ ## N
#endif
