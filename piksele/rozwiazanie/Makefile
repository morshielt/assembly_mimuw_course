all: ppm

ppm: mainppm.c ppm.o
	gcc -o mainppm mainppm.c ppm.o -lm

.SECONDARY:

%.o: %.s
	as -o ppm.o ppm.s

clean:
	rm -f *.o mainppm
