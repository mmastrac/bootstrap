#include "syscall.h"
#include "regs.h"

mov @sp, $1000

mov r0, 1
mov r1, 2
call :proc
sys @SC_EXIT

:proc
	%arg arg1
	%arg arg2
	%local local1
	%local local2
	mov @local1, 0
	mov @local2, 0
	add @local1, @arg1
	add @local2, @arg2
	add @local1, @local2
	mov r0, @local1
	%ret
