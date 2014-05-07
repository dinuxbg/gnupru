# Copyright (c) 2014, Dimitar Dimitrov
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the
#     distribution.
#   * Neither the name of the copyright holders nor the names of
#     contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.

# Very simple makefile to compile the PRU firmware loader

#CROSS_COMPILE ?= arm-none-eabi-
CROSS_COMPILE :=

CFLAGS += -g -O2
CFLAGS += -Wall -Wextra -Werror
LDFLAGS += -lpthread -lelf

OBJS := pload.o prussdrv.o md5.o md5-data.o

EXE := pload

# Where to output compiled objects
OUT := out

# ============================ DO NOT TOUCH BELOW ============================
all: $(OUT)/$(EXE)
	@echo Success: $^

OBJS := $(addprefix $(OUT)/, $(OBJS))

DEPS := $(OBJS:.o=.d)
-include $(DEPS)

$(OUT)/%.o : %.c
	$(CROSS_COMPILE)gcc $(CFLAGS) $< -c -o $@ -MMD

$(OUT)/%.o : %.S
	$(CROSS_COMPILE)gcc $(CFLAGS) $< -c -o $@ -MMD

$(OUT)/%.s : %.c
	$(CROSS_COMPILE)gcc $(CFLAGS) $< -S -o $@

%.s : %.elf
	$(CROSS_COMPILE)objdump -S -d $< > $@

$(OBJS): | $(OUT)

$(OUT):
	mkdir $(OUT)

$(OUT)/$(EXE): $(OBJS) | $(OUT)
	$(CROSS_COMPILE)gcc $(CFLAGS) $^ $(LDFLAGS) -o $@

clean:
	$(RM) -fr $(EXE) $(OBJS) $(OUT)

cscope:
	cscope -bR

run: $(OUT)/pload
	./$< ../pru/out/pru-core0.elf ../pru/out/pru-core1.elf

.PHONY: all clean cscope run
