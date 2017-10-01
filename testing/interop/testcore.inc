
PRU_CGT ?= /usr

OUT := out
TARGET := test

TESTCASE := $(shell basename `pwd`)

COMMON_CFLAGS := -DTESTCASE=\"$(TESTCASE)\" -I../

TI_CFLAGS := -v3 -O2 --display_error_number --endian=little --hardware_mac=on
# TODO - GNU LD PRU port does not yet support debug REL relocations.
TI_CFLAGS += --symdebug:none
GCC_CFLAGS := -O1 -g -Wall -Wextra -mmcu=sim -mabi=ti
GCC_LDFLAGS :=

all: $(OUT)/$(TARGET)
	pru-run $<
	@echo PASS: $(TESTCASE)

$(OUT):
	mkdir $(OUT)

$(OUT)/ti-mod.o: ti-mod.c $(OUT) $(wildcard *.h)
	$(PRU_CGT)/bin/clpru $(TI_CFLAGS) $(COMMON_CFLAGS) -fe $@ $<

$(OUT)/gcc-main.o: gcc-main.c $(OUT) $(wildcard *.h)
	pru-gcc $(GCC_CFLAGS) $(COMMON_CFLAGS) -c -o $@ $<

$(OUT)/$(TARGET): $(OUT)/ti-mod.o $(OUT)/gcc-main.o
	pru-gcc $(GCC_CFLAGS) $(COMMON_CFLAGS) $(GCC_LDFLAGS) $^ -o $@

clean:
	rm -fr $(OUT)

$(OUT)/selftest-host: ti-mod.c gcc-main.c | $(OUT) $(wildcard *.h)
	gcc -O2 -Wall -Wextra $(COMMON_CFLAGS) $^ -o $@

selftest: $(OUT)/selftest-host
	./$<
	@echo PASS:host: $(TESTCASE)

.PHONY: clean selftest
