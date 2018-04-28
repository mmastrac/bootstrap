#define OPEN_READ 1

mov r0, :scratch
add r0, $4
ldd r0, r0
mov r0, @OPEN_READ

:scratch
	dat 1
