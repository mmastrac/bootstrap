#include "regs.h"

:_malloc
# @tmp0 is the currently free address
	ld.d @tmp0, :__heap
# Save the size
	mov @tmp1, r0
# We return that currently free address
	mov r0, @tmp0
# Add size + old free address
	add @tmp0, @tmp1
# Store that back into the heap pointer
	st.d :__heap, @tmp0
	ret
