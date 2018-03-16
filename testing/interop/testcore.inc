
PRU_CGT ?= /usr

OUT := out
TARGET := test

TESTCASE := $(shell basename `pwd`)

COMMON_CFLAGS := -DTESTCASE=\"$(TESTCASE)\" -I../

TI_CFLAGS := -v3 -O2 --display_error_number --endian=little --hardware_mac=on
TI_CFLAGS += -I$(PRU_CGT)/include
# TODO - GNU LD PRU port does not yet support debug REL relocations.
TI_CFLAGS += --symdebug:none

# Do not put mabi=ti here. We need stdlib to execute
# the tests. We also want to exercise large return values
# when a result is not ignored. Tests have been carefully
# designed to walk the fine line.
#
# But we need some of the option activated by mabi=ti, like
# -mno-relax that guards against missing PRU_S10_PCREL relocations
# in code produced by TI toolchain.
GCC_CFLAGS += -O1 -g -Wall -Wextra -mmcu=sim
GCC_LDFLAGS += -mno-relax

all: $(OUT)/$(TARGET)
	pru-run $<
	@echo PASS: $(TESTCASE)

$(OUT):
	mkdir -p $(OUT)

$(OUT)/ti-mod.o: ti-mod.c $(OUT) $(wildcard *.h)
	$(PRU_CGT)/bin/clpru $(TI_CFLAGS) $(COMMON_CFLAGS) -fe $@ $<

$(OUT)/gcc-main.o: gcc-main.c $(OUT) $(wildcard *.h)
	pru-gcc $(GCC_CFLAGS) $(COMMON_CFLAGS) -c -o $@ $<

$(OUT)/$(TARGET): $(OUT)/ti-mod.o $(OUT)/gcc-main.o
	pru-gcc $(GCC_CFLAGS) $(COMMON_CFLAGS) $^ $(GCC_LDFLAGS) -o $@

clean:
	rm -fr $(OUT)

$(OUT)/selftest-host: ti-mod.c gcc-main.c | $(OUT) $(wildcard *.h)
	gcc -O2 -Wall -Wextra -lm $(COMMON_CFLAGS) $^ -o $@

selftest: $(OUT)/selftest-host
	./$<
	@echo PASS:host: $(TESTCASE)

.PHONY: clean selftest
