# Fourth stage bootstrap
# Human-readable/writable assembly

# Whitespace in lines is removed during processing

#include include/syscall.h

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

:error


# R0: Filename (zero terminated)
# R1: Mode (0 = read, 1 = rw+create)
:open
push r2
mov r2, 
ret

:input_handle
dat $0000
dat $0000

:output_handle
dat $0000
dat $0000

:readbuf_
dat $0000
dat $0000

:scratch


