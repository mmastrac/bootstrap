#include "syscall.h"
#include "regs.h"

#===========================================================================
# R0: File handle
# R1: String
#===========================================================================
:_dputs
	%arg file_handle
	%arg string_ptr
	%local length
	%call :_strlen, @string_ptr
	mov @length, r0
	%call :syscall4 @SC_WRITE @file_handle @string_ptr @length
	%ret
#===========================================================================


#===========================================================================
# R0: File handle
# R1: Format string
# Stack: printf arguments
#===========================================================================
:_dprintf
	%arg file_handle
	%arg string_ptr
	%local varargs
	mov @varargs, @sp
	add @varargs, @__LOCALS_SIZE__
	mov @tmp0, 1
.loop
	ld.b @tmp1, [@string_ptr]
	eq @tmp1, 0
	%ret?
	eq @tmp1, '%'
	jump? .percent
	# Write that char
	sys @SC_WRITE @file_handle @string_ptr @tmp0
	add @string_ptr, 1
	jump .loop
.percent
	add @string_ptr, 1
	ld.b @tmp1, [@string_ptr]
	add @string_ptr, 1
	eq @tmp1, 's'
	jump? .percent_s
	eq @tmp1, '%'
	jump? .percent_percent
	eq @tmp1, 'd'
	jump? .percent_d
	eq @tmp1, 'x'
	jump? .percent_x

	%call :_fatal, &"Invalid % escape"

.percent_percent
	%call :_dputs, @file_handle, &"%"
	jump .loop
.percent_s
	ld.d @tmp1, [@varargs]
	%call :_dputs, @file_handle, @tmp1
	add @varargs, 4
	jump .loop
.percent_x
.percent_d
	jump .loop

