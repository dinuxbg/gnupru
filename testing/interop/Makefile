
TESTDIRS := $(dir $(wildcard */Makefile))

all:
	$(foreach D,$(TESTDIRS),make -C $(D))

# Check the testsuite itself on a host. Implies that there
# are no architecture-specific tests.
selftest:
	$(foreach D,$(TESTDIRS),make -C $(D) selftest)
	

.PHONY: all selftest
