# Entry point for applications built on this basic C runtime

#include "syscall.h"
#include "regs.h"

:_start
	# Initialize the stack
	mov r0, @SC_GETMEMSIZE
	sys r0
	mov @sp, r0
	sub @sp, 4

	call :__init_args
	call :_main

	mov r1, @SC_EXIT
	sys r1 r0

:__init_args
	# Get the size of argv
	mov r0, @SC_GETARGV
	mov r1, 0
	sys r0 r1 r1

	# Allocate a buffer big enough for argv
	mov r8, r0
	call :_malloc
	mov r1, @SC_GETARGV
	sys r1 r0 r8

	st.d :__argv, r0

	# Initialize __argc to the appropriate value
	mov r1, 0
.argc_loop
	ld.d r2, r0
	eq r2, 0
	st.d? :__argc, r1
	ret?
	add r1, 1
	add r0, 4
	jump .argc_loop

# Heap initially points to a special linker-defined symbol "__END__"
:__heap
	dd :__END__

:__argv
	dd 0

:__argc
	dd 0
