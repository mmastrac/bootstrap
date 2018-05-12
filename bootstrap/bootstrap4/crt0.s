# Entry point for applications built on this basic C runtime

# - Initializes argc/argv
# - Initializes the stack/heap
# - Calls _main with argc and argv as parameters
# - Exits with return value from _main

#include "syscall.h"
#include "regs.h"

:_start
	# Initialize the stack
	mov r0, @SC_GETMEMSIZE
	sys r0
	mov @sp, r0
	sub @sp, 4

	call .init_args
	ld.d r0, :__argc
	mov r1, :__argv
	call :_main

	sys @SC_EXIT r0

.init_args
	# Get the size of argv
	mov r0, @SC_GETARGV
	mov r1, 0
	sys r0 r1 r1

	# Allocate a buffer big enough for argv
	mov r8, r0
	call :_malloc
	sys @SC_GETARGV r0 r8

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

:_fatal
	mov r8, r0
	call :_strlen
	sys @SC_WRITE, r8, r0
	mov r0, 1
	sys @SC_EXIT, r0

# Heap initially points to a special linker-defined symbol "__END__"
:__heap
	dd :__END__

:__argv
	dd 0

:__argc
	dd 0
