
PRU_CGT ?= /usr/share/ti/cgt-pru

OUT := out
TARGET := test

TI_CFLAGS := -v3 -O2 --display_error_number --endian=little --hardware_mac=on
# TODO - GNU LD PRU port does not yet support debug REL relocations.
TI_CFLAGS += --symdebug:none
GCC_CFLAGS := -O1 -g -Wall -Wextra -mmcu=sim
GCC_LDFLAGS :=

all: $(OUT)/$(TARGET)
	pru-run $<

$(OUT):
	mkdir $(OUT)

$(OUT)/ti-mod.o: ti-mod.c $(OUT) shared.h
	$(PRU_CGT)/bin/clpru $(TI_CFLAGS) -fe $@ $<

$(OUT)/gcc-main.o: gcc-main.c $(OUT) shared.h
	pru-gcc $(GCC_CFLAGS) -c -o $@ $<

$(OUT)/$(TARGET): $(OUT)/ti-mod.o $(OUT)/gcc-main.o
	pru-gcc $(GCC_CFLAGS) $(GCC_LDFLAGS) $^ -o $(OUT)/$(TARGET)

clean:
	rm -fr $(OUT)
