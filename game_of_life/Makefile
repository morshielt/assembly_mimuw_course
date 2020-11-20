all: game

# suma1: suma1.o

# suma1a: suma1a.o

# suma2: suma2.o

game: gamemain.c game.o
	gcc -o game -g gamemain.c game.o -no-pie
	# TODO: usunąć  -g
	# gcc -o game gamemain.c game.o -no-pie

# locatea: locatemain.c locatea.o
# 	gcc -o locatea locatemain.c locatea.o -no-pie

# trim: trimmain.c trim.o
# 	gcc -o trim trimmain.c trim.o -no-pie

.SECONDARY:

%.o: %.asm
	nasm -f elf64 -F dwarf -g $<


%: %.o
	ld $< -o $@ -lc --dynamic-linker=/lib64/ld-linux-x86-64.so.2


# clean:
# 	rm -f *.o maks1 maks2

