SRCROOT  = .
BUILD    = build
TARGET   = rtos_example
PLATFORM = st-nucleo-f103rb

CFLAGS  := -Wall -Wextra -pedantic -std=c99
override CFLAGS += -I$(SRCROOT) -I$(SRCROOT)/include

LDFLAGS :=
override LDFLAGS += -L $(BUILD)

LDLIBS  :=
override LDLIBS += -lrtos

ifeq ($(PLATFORM),st-nucleo-f103rb)
# For the ST Nucleo F103RB board:
# ==================
AR       = arm-none-eabi-ar
CC       = arm-none-eabi-gcc
AS       = $(CC) -x assembler-with-cpp
OBJCOPY  = arm-none-eabi-objcopy
SIZE     = arm-none-eabi-size

override CFLAGS +=                                 \
	-mcpu=cortex-m3 -mthumb                    \
	-DSTM32F103xB

override LDFLAGS +=                                \
	-mcpu=cortex-m3 -mthumb                    \
	-T $(SRCROOT)/startup/stm32f103rb.ld       \
	-nostdlib

STARTUP  = $(SRCROOT)/startup/stm32f103rb.c
override LDLIBS += -ldrivers
endif

override CFLAGS := $(strip $(CFLAGS))
override LDFLAGS := $(strip $(LDFLAGS))
override LDLIBS := $(strip $(LDLIBS))

.DEFAULT_GOAL = all

# drivers
# ==================
drivers_srcs = $(wildcard $(SRCROOT)/drivers/*.c)
drivers_objs = $(patsubst $(SRCROOT)/drivers/%,$(BUILD)/drivers.dir/%.o,$(drivers_srcs))
drivers_deps = $(drivers_objs:.o=.d)

$(BUILD)/drivers.dir/%.c.o: $(SRCROOT)/drivers/%.c | $(BUILD)/drivers.dir
	$(CC) $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -c $< -o $@

$(BUILD)/drivers.dir:
	mkdir -p $@

-include $(drivers_deps)

.PHONY: drivers
drivers: $(BUILD)/libdrivers.a
$(BUILD)/libdrivers.a: $(drivers_objs)
	$(AR) rcs $@ $^

# rtos
# ==================
rtos_srcs = $(wildcard $(SRCROOT)/rtos/*.c) $(wildcard $(SRCROOT)/rtos/*.s)
rtos_objs = $(patsubst $(SRCROOT)/rtos/%,$(BUILD)/rtos.dir/%.o,$(rtos_srcs))
rtos_deps = $(rtos_objs:.o=.d)

$(BUILD)/rtos.dir/%.c.o: $(SRCROOT)/rtos/%.c | $(BUILD)/rtos.dir
	$(CC) $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -c $< -o $@

$(BUILD)/rtos.dir/%.s.o: $(SRCROOT)/rtos/%.s | $(BUILD)/rtos.dir
	$(AS) $(CFLAGS) -c $< -o $@

$(BUILD)/rtos.dir:
	mkdir -p $@

-include $(rtos_deps)

.PHONY: rtos
rtos: $(BUILD)/librtos.a
$(BUILD)/librtos.a: $(rtos_objs)
	$(AR) rcs $@ $^

# Main target
# ==================
srcs = $(wildcard $(SRCROOT)/src/*.c) $(wildcard $(SRCROOT)/src/*.s)
objs = $(patsubst $(SRCROOT)/src/%,$(BUILD)/$(TARGET).dir/%.o,$(srcs)) $(BUILD)/$(TARGET).dir/startup.o
deps = $(objs:.o=.d)

$(BUILD)/$(TARGET).dir/%.c.o: $(SRCROOT)/src/%.c | $(BUILD)/$(TARGET).dir
	$(CC) $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -c $< -o $@

$(BUILD)/$(TARGET).dir/%.s.o: $(SRCROOT)/src/%.s | $(BUILD)/$(TARGET).dir
	$(AS) $(CFLAGS) -c $< -o $@

$(BUILD)/$(TARGET).dir/startup.o: $(STARTUP) | $(BUILD)/$(TARGET).dir
	$(CC) $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -c $< -o $@

$(BUILD)/$(TARGET).dir:
	mkdir -p $@

-include $(deps)

.PHONY: $(TARGET)
$(TARGET): $(BUILD)/$(TARGET).hex
$(BUILD)/$(TARGET).hex: $(objs) $(addprefix $(BUILD)/,$(patsubst -l%,lib%.a,$(LDLIBS)))
	$(CC) $(LDFLAGS) -o $(@:.hex=.elf) $(objs) $(LDLIBS)
	$(SIZE) $(@:.hex=.elf)
	$(OBJCOPY) -O ihex $(@:.hex=.elf) $@

# All
# ==================
.PHONY: all clean flash
all: $(TARGET)
clean:
	rm -rf $(BUILD)

flash: $(BUILD)/$(TARGET).hex
ifeq ($(PLATFORM),st-nucleo-f103rb)
	openocd -f board/st_nucleo_f103rb.cfg -c "program $< verify reset exit"
endif

$(BUILD):
	mkdir -p $@
