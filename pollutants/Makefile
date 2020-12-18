all: pollutants

pollutants: pollutantsmain.c pollutants.o
	gcc -o pollutants pollutantsmain.c pollutants.o -no-pie

.SECONDARY:

%.o: %.asm
	nasm -f elf64 -F dwarf -g $<

%: %.o
	ld $< -o $@ -lc --dynamic-linker=/lib64/ld-linux-x86-64.so.2

clean:
	rm -f *.o pollutants

