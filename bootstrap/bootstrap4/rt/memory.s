#include "regs.h"

#===========================================================================
#
#===========================================================================
:_malloc
# @tmp0 is the currently free address
	ld.d @tmp0, [:__heap]
# Save the size
	mov @tmp1, r0
# We return that currently free address
	mov r0, @tmp0
# Add size + old free address
	add @tmp0, @tmp1
# Store that back into the heap pointer
	st.d [:__heap], @tmp0
	ret

#===========================================================================
# Args:
#   R0: Dest
#   R1: Source
#   R2: Size
# Returns:
#   R0: Dest
#===========================================================================
:_memcpy
.loop
	eq r2, 0
	ret?
	ld.b @tmp0, [r1]
	st.b [r0], @tmp0
	sub r2, 1
	add r0, 1
	add r1, 1
	jump .loop

#===========================================================================
# Args:
#   R0: memory
# Returns:
#   R0: 32-bit contents
#===========================================================================
:_memread32
	ld.d r0, [r0]
	ret

#===========================================================================
# Args:
#   R0: pointer
#   R1: index
# Returns:
#   R0: 32-bit contents
#===========================================================================
:_arrayread32
	mul r1, 4
	add r0, r1
	ld.d r0, [r0]
	ret

#===========================================================================
# Args:
#   R0: pointer
#   R1: index
#   R2: value
#===========================================================================
:_arraywrite32
	mul r1, 4
	add r0, r1
	st.d [r0], r2
	ret
