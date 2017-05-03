
#include <stdint.h>

class A {
public:
	int a;
	char b;
	int c;
	virtual int test1(int pa, int pb);
};

namespace b {
class B : public A {
public:
	int d;
	virtual int test1(int pa, int pb);
};
};
