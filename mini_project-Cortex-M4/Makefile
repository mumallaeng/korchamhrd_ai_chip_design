.DEFAULT_GOAL := help

TARGET      := arm-none-eabi
CC          := $(TARGET)-gcc
OBJCOPY     := $(TARGET)-objcopy

BUILD_DIR   := build
IMAGE       := $(BUILD_DIR)/testudines

C_SOURCES   := $(shell find src platform/stm32f4 -name '*.c')
S_SOURCES   := $(shell find startup -name '*.s')

C_OBJECTS   := $(patsubst %.c,$(BUILD_DIR)/%.o,$(C_SOURCES))
S_OBJECTS   := $(patsubst %.s,$(BUILD_DIR)/%.o,$(S_SOURCES))
OBJECTS     := $(S_OBJECTS) $(C_OBJECTS)

CPPFLAGS    := -DSTM32F411xE -Iinclude -Iplatform/cmsis -Iplatform/stm32f4
CFLAGS      := -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard
CFLAGS      += -std=gnu11 -O0 -g3 -Wall -Wextra -ffreestanding
CFLAGS      += -fdata-sections -ffunction-sections -MMD -MP
LDFLAGS     := -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard
LDFLAGS     += -nostartfiles -nostdlib -T linker/rom_0x08000000.lds
LDFLAGS     += -Wl,-Map=$(IMAGE).map
LDLIBS      := -lgcc

.PHONY: help build flash clean

help:
	@echo "make build  - build ELF and BIN"
	@echo "make flash  - flash BIN through ST-LINK"

build: $(IMAGE).bin

$(IMAGE).elf: $(OBJECTS)
	@mkdir -p $(dir $@)
	$(CC) $(LDFLAGS) $^ $(LDLIBS) -o $@

$(IMAGE).bin: $(IMAGE).elf
	$(OBJCOPY) -O binary $< $@

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

flash: $(IMAGE).bin
	st-flash --reset write $< 0x08000000

clean:
	rm -rf $(BUILD_DIR)

-include $(OBJECTS:.o=.d)
