CC := gcc
CROSS_COMPILE ?=

ifeq ($(filter aarch64-none-linux-gnu-%, $(CROSS_COMPILE)),aarch64-none-linux-gnu-)
    CC := $(CROSS_COMPILE)gcc
endif

SRC := writer.c
OBJ := $(SRC:.c=.o)
TARGET := writer

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) -o $@ $^

%.o: %.c
	$(CC) -c -o $@ $<

clean:
	rm -f $(OBJ) $(TARGET)
