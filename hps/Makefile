#
TARGET = Prac3

#
CROSS_COMPILE = arm-linux-gnueabihf-
ALT_DEVICE_FAMILY ?= soc_cv_av
CFLAGS = -static -g -Wall -I"C:\intelFPGA\19.1\embedded\ip\altera\hps\altera_hps\hwlib\include" -D$(ALT_DEVICE_FAMILY)
LDFLAGS = -g -Wall
CC = $(CROSS_COMPILE)gcc
ARCH= arm


build: $(TARGET)


$(TARGET): main.o
	$(CC) $(LDFLAGS) $^ -o $@

%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@


.PHONY: clean
clean:
	rm -f $(TARGET) *.a *.o *~