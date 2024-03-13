# Copyright (c) 2020 Thales.
# 
# Copyright and related rights are licensed under the Apache
# License, Version 2.0 (the "License"); you may not use this file except in
# compliance with the License.  You may obtain a copy of the License at
# https://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable law
# or agreed to in writing, software, hardware and materials distributed under
# this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#
# Author:         Sebastien Jacq - sjthales on github.com
#                 Kevin Eyssartier - EyssartK on github.com
#
# Additional contributions by:
#
#
# script Name:    Software application makefile
# Project Name:   CVA6 softcore
# Language:       Makefile
#
# Description:    Makefile to compile software application for CVA6 platform
#
# =========================================================================== #
# Revisions  :
# Date        Version  Author       Description
# 2020-10-06  0.1      S.Jacq       Created
# 2020-10-06  0.1      k.Eyssartier Created
# =========================================================================== #

ARCH = rv32im_zicsr_xadac1
PREFIX = riscv32-unknown-elf-

UTILS_DIR = ../utils
APP_DIR   = $(abspath .)
BSP_DIR   = ../bsp

GCC     = $(PREFIX)gcc
OBJCOPY = $(PREFIX)objcopy
AR      = $(PREFIX)ar
OBJDUMP = $(PREFIX)objdump
SPIKE   = spike
BIN2MEM = $(UTILS_DIR)/bin2mem.py
MEM2COE = $(UTILS_DIR)/mem2coe.py

PK = $(RISCV)/riscv32-unknown-elf/bin/pk

LDSCRIPT = $(BSP_DIR)/config/link.ld

BMARKS = \
	mnist \
	mnist_adac \
	mnist_base \
	mnist_clean

BSP_SRC_S = $(wildcard $(BSP_DIR)/hal/*.S)

BSP_SRC_C = \
	$(wildcard $(BSP_DIR)/hal/*.c) \
	$(wildcard $(BSP_DIR)/drivers/uart/*.c) 

BSP_OBJ_S = $(SRC_BSP_S:.S=.o)
BSP_OBJ_C = $(SRC_BSP_C:.c=.o)
BSP_OBJ   = $(BSP_OBJ_S) $(BSP_OBJ_C)

ALL_OBJ += $(BSP_OBJ)

INCS += \
	$(BSP_DIR)/config \
	$(BSP_DIR)/drivers/uart \
	$(BSP_DIR)/hal \
	$(APP_DIR)/coremark/simple \
	$(APP_DIR)/common
	
CFLAGS = -march=$(ARCH) -mabi=ilp32 -DPREALLOCATE=1 -fvisibility=hidden \
	-DSTDIO_THRU_UART -g -O3 -mcmodel=medany -static -Wall -pedantic 

LDFLAGS = -static -nostartfiles -T $(LDSCRIPT)

all: $(BMARKS)

define GEN_BMARK_RULES
$(1)_SRC = $$(shell find $(APP_DIR)/$(1) -name "*.c")
$(1)_OBJ = $$($(1)_SRC:.c=.o)

ALL_OBJ += $$($(1)_OBJ)

$(1).elf: $$($(1)_OBJ)
	$$(GCC) $$(BSP_OBJ) $$(CFLAGS) $$(LDFLAGS) -o $$@ $$^

$(1)_pk.elf: $$($(1)_OBJ)
	$$(GCC) $$(CFLAGS) -I $(APP_DIR)/$$(1) -o $$@ $$^

.PHONY: $(1)
$(1): $(1).elf $(1).dump $(1).hex $(1).bin $(1).mem $(1).coe

.PHONY:
$(1)_spike: $(1)_pk.elf $(1)_pk.dump
	$$(SPIKE) $$(PK) $(1)_pk.elf

endef

$(foreach BMARK,$(BMARKS),$(eval $(call GEN_BMARK_RULES,$(BMARK))))

%.dump: %.elf 
	$(OBJDUMP) -D $< > $@

%.hex: %.elf
	$(OBJCOPY) -O ihex $< $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.o: %.c
	$(GCC) $(CFLAGS) $(addprefix -I, $(INCS)) -o $@ -c $< 

%.o: %.S
	$(GCC) -o $@ -c $< $(CFLAGS)

%.mem: %.bin
	$(BIN2MEM) $(APP_DIR)/$<

%.coe: %.mem
	$(MEM2COE) $(APP_DIR)/$<

clean:
	rm -rf $(ALL_OBJ) *.elf *.o *.dump *.mem *.bin *.coe *.hex
