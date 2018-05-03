# Fourth stage bootstrap
# Human-readable/writable assembly

# Whitespace in lines is removed during processing
# Labels starting with : are global labels
# Labels starting with . are local labels, scoped to previous global label
# #define is allowed, but the contents must be a decimal integer or a register (rX)

# Calling convention:
#  - Argument registers are not preserved (r0-r8)
#  - Return values provided in r0 or r0+r1
#  - All other registers must be restored to state before call, other than temps

#include "include/syscall.h"
#define SC_OPEN $0
#define O_RDONLY $0
#define O_WRONLY $1
#define O_RDWR $2
#define O_CREAT $200
#define O_TRUNC $400

#define SC_READ $1
#define SC_WRITE $2
#define SC_SEEK $3
#define SC_CLOSE $4
#define SC_GETARGV $5
#define SC_GETMEMSIZE $6
#define SC_EXIT $7

#define OPEN_READ $0
#define OPEN_WRITE $1

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


