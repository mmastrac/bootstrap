#include "syscall.h"
#include "regs.h"

:_start
	# Initialize the stack
	mov r0, @SC_GETMEMSIZE
	sys r0
	mov @sp, r0
	sub @sp, 4
    jump :__start1
