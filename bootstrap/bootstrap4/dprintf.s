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
	eq @string_ptr, 0
	jump? .null
	%call :_strlen, @string_ptr
	mov @length, r0
	%call :syscall4 @SC_WRITE @file_handle @string_ptr @length
	%ret
.null
	%call :syscall4 @SC_WRITE @file_handle &"(null)" 6
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
.loop
	ld.b @tmp1, [@string_ptr]
	eq @tmp1, 0
	%ret?
	eq @tmp1, '%'
	jump? .percent
	# Write that char
	mov @tmp0, 1
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
	%call :_memset, .digit_buffer, 0, 16
	ld.d @tmp1, [@varargs]
	mov @tmp0, .digit_buffer_end
.percent_d_loop
	sub @tmp0, 1
	mov @tmp2, @tmp1
	div @tmp1, 10
	mod @tmp2, 10
	add @tmp2, '0'
	st.b [@tmp0], @tmp2
	eq @tmp1, 0
	jump? .percent_d_done
	jump .percent_d_loop
.percent_d_done
	%call :_dputs, @file_handle, @tmp0
	add @varargs, 4
	jump .loop

.digit_buffer
	db 0 0 0 0 0 0 0 0
	db 0 0 0 0 0 0 0 0
.digit_buffer_end
	db 0
