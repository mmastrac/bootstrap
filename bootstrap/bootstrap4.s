# Fourth stage bootstrap
# Human-readable/writable assembly

# Whitespace in lines is removed during processing
# Labels starting with : are global labels
# Labels starting with . are local labels, scoped to previous global label
# #define is allowed, but the contents must be a decimal integer or a register (rX)

# Calling convention:
#  - Argument registers are not preserved
#  - Return values provided in r0 or r0+r1
#  - All other registers must be restored to state before call, other than temps

#include "include/syscall.h"

# Register definitions
#define pc r61
#define sp r60
# The compiler uses r59 for compound ops
#define ctmp r59
# These are tmp regs free for use by code - no need to restore
#define tmp0 r58
#define tmp1 r57
#define tmp2 r56
#define tmp3 r55

# Get argv after the code segment
mov r0, @SC_GETARGV
mov r1, :scratch
mov r2, $1000
sys r0 r1 r2

# Open argv[1] as input
mov r0, :scratch
add r0, $4
ldd r0, r0
mov r0, @OPEN_READ
call :open
std :input_handle, r0

# Open argv[2] as output
mov r0, :scratch
add r0, $8
ldd r0, r0
mov r0, @OPEN_WRITE
call open
std :output_handle, r0

:fatal


#===========================================================================
# R0: Filename (zero terminated)
# R1: Mode (0 = read, 1 = rw+create)
#===========================================================================
:open
	eq r1, @OPEN_READ
	jump? .read
# read/write
	mov r3, @O_RDWR
	or r3, @O_CREAT
	or r3, @O_TRUNC
	jump .open
# readonly
.read
	mov r3, @O_RDONLY
.open
	mov tmp0, @SC_OPEN
	sys tmp0 r0 r3
	mov r0, tmp0
	add tmp0, $1
	eq tmp0, $0
	mov? r0, :open_error
	jump? :fatal
	pop r3
	ret

:open_error
	ds Failed to open file
#===========================================================================


#===========================================================================
# Args:
#   R0: String
# Returns:
#   R0: Length
#===========================================================================
:strlen
	push r1, r2
	mov r1, r0
.loop
	ld.b r2, r0
	eq r2, $0
	jump? .ret
	add r0, $1
	jump .loop
.ret
	sub r0, r1
	pop r2, r1
	ret
#===========================================================================


:input_handle
dd $0

:output_handle
dd $0

:readbuf_
dd $0

:scratch


