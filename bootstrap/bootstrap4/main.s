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

#include "syscall.h"

