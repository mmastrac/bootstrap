# Fourth stage bootstrap
# Human-readable/writable assembly

# Whitespace in lines is removed during processing
# Labels starting with : are global labels
# Labels starting with . are local labels, scoped to previous global label
# #define is allowed, but the contents must be a decimal integer or a register (rX)

# Calling convention:
#  - Argument registers are not preserved (r0-r7)
#  - Return values provided in r0 or r0+r1
#  - All other registers must be restored to state before call, other than temps

#include "include/syscall.h"


# Get argv after the code segment
mov r0, @SC_GETARGV
mov r1, :scratch
mov r2, $1000
sys r0 r1 r2

# Open argv[1] as input
mov r0, :scratch
add r0, $4
ld.d r0, r0
mov r0, @OPEN_READ
call :open
st.d :input_handle, r0

# Open argv[2] as output
mov r0, :scratch
add r0, $8
ld.d r0, r0
mov r0, @OPEN_WRITE
call :open
st.d :output_handle, r0

:fatal


:input_handle
dd $0

:output_handle
dd $0

:readbuf_
dd $0

:scratch


