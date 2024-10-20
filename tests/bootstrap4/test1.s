#define OPEN_READ 10
#define O_CREAT 0x200
#define O_TRUNC $400

mov r10, :scratch
add r0, $4
ld.d r0, [r0]
mov r0, @OPEN_READ

:scratch
mov r5, $1
