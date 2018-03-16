
PRU_CGT ?= /usr/share/ti/cgt-pru

OUT := out
TARGET := test

TESTCASE := $(shell basename `pwd`)

COMMON_CXXFLAGS := -DTESTCASE=\"$(TESTCASE)\" -I../

TI_CXXFLAGS := -v3 -O2 --display_error_number --endian=little --hardware_mac=on
TI_CXXFLAGS += -I$(PRU_CGT)/include
# TODO - GNU LD PRU port does not yet support debug REL relocations.
TI_CXXFLAGS += --symdebug:none
GCC_CXXFLAGS := -O1 -g -Wall -Wextra -mmcu=sim
GCC_LDFLAGS :=

all: $(OUT)/$(TARGET)
	pru-run $<
	@echo PASS: $(TESTCASE)

$(OUT):
	mkdir $(OUT)

$(OUT)/ti-mod.o: ti-mod.cxx $(OUT) $(wildcard *.hxx)
	$(PRU_CGT)/bin/clpru $(TI_CXXFLAGS) $(COMMON_CXXFLAGS) -fe $@ $<

$(OUT)/gcc-main.o: gcc-main.cxx $(OUT) $(wildcard *.hxx)
	pru-g++ $(GCC_CXXFLAGS) $(COMMON_CXXFLAGS) -c -o $@ $<

$(OUT)/$(TARGET): $(OUT)/ti-mod.o $(OUT)/gcc-main.o
	pru-g++ $(GCC_CXXFLAGS) $(COMMON_CXXFLAGS) $(GCC_LDFLAGS) $^ -o $@

clean:
	rm -fr $(OUT)

$(OUT)/selftest-host: ti-mod.cxx gcc-main.cxx | $(OUT) $(wildcard *.hxx)
	g++ -O2 -Wall -Wextra $(COMMON_CXXFLAGS) $^ -o $@

selftest: $(OUT)/selftest-host
	./$<
	@echo PASS:host: $(TESTCASE)

.PHONY: clean selftest
