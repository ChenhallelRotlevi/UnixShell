# Makefile for HW6 (AT&T Syntax Version)

TARGET = myshell
OBJS = main.o
CC = gcc

# Flags:
# -no-pie: Disable Position Independent Executable (Fixes your relocation error)
# -g:      Add debug symbols for GDB
CFLAGS = -no-pie -g

all: $(TARGET)

$(TARGET): main.s
	$(CC) $(CFLAGS) -o $(TARGET) main.s

clean:
	rm -f $(TARGET)