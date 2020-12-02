all: game

game: gamemain.c game.o
	gcc -o game gamemain.c game.o -no-pie

.SECONDARY:

%.o: %.asm
	nasm -f elf64 -F dwarf -g $<

%: %.o
	ld $< -o $@ -lc --dynamic-linker=/lib64/ld-linux-x86-64.so.2

clean:
	rm -f *.o game

