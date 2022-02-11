all:	link
	./main input_bytes_0.txt input_matrix_0.txt
link:	compile_c
	gcc  main.o encode_decode.o -o main
compile_c:	compile_assembly
	gcc -c   main_skeleton.c -o main.o

compile_assembly:
	nasm -f elf32  encode_decode.asm -o encode_decode.o