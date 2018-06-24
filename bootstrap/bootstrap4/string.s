#include "regs.h"

# String/memory routines

#===========================================================================
# Args:
#   R0: String
# Returns:
#   R0: Length
#===========================================================================
:_strlen
	push r1, r2
	mov r1, r0
.loop
	ld.b r2, [r0]
	eq r2, $0
	jump? .ret
	add r0, $1
	jump .loop
.ret
	sub r0, r1
	pop r2, r1
	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: String
#   R1: Character
# Returns:
#   R0: Pointer to character, or null
#===========================================================================
:_strchr
.loop
	ld.b @tmp0, [r0]
	eq @tmp0, r1
	ret?
	eq @tmp0, 0
	mov? r0, 0
	ret?
	add r0, 1
	jump .loop
#===========================================================================


#===========================================================================
# Args:
#   R0: String 1
#   R1: String 2
# Returns:
#   +1 if S1>S2, -1 if S1<S2, 0 if S1=S2
#===========================================================================
:_strcmp
.loop
	ld.b @tmp0, [r0]
	ld.b @tmp1, [r1]
	ne @tmp0, @tmp1
	jump? .ne
	eq @tmp0, 0
	mov? @ret, 0
	ret?
	add r0, 1
	add r1, 1
	jump .loop
.ne
	gt @tmp0, @tmp1
	mov? @ret, 1
	mov^ @ret, -1
	ret
#===========================================================================


#===========================================================================
# Matches Java's hashCode()
# Args:
#   R0: String
# Returns:
#   R0: Hash
#===========================================================================
:_strhash
	mov @tmp0, 0
.loop
	ld.b @tmp1, [r0]
	eq @tmp1, 0
	mov? r0, @tmp0
	ret?
	mul @tmp0, 31
	add @tmp0, @tmp1
	add r0, 1
	jump .loop
#===========================================================================


#===========================================================================
# Args:
#   R0: char
# Returns:
#   R0: Hex value, or -1 if none
#===========================================================================
:_hexchar
	lt r0, '0'
	jump? .retnone
	lt r0, ':'
	jump? .retdigit
	lt r0, 'A'
	jump? .retnone
	lt r0, 'G'
	jump? .retLETTER
	lt r0, 'a'
	jump? .retnone
	lt r0, 'g'
	jump? .retletter
.retnone
	mov r0, -1
	ret
.retdigit
	mov @tmp0, '0'
	sub r0, @tmp0
	ret
.retLETTER
	mov @tmp0, 'K' # 'A' + 10
	sub r0, @tmp0
	ret
.retletter
	mov @tmp0, 133 # 'a' + 10 + 26
	sub r0, @tmp0
	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: char
# Returns:
#   R0: 1 if true
#===========================================================================
:_isdigit
	lt r0, '0'
	jump? .retfalse
	lt r0, ':'
	jump? .rettrue
.retfalse
	mov r0, $0
	ret
.rettrue
	mov r0, $1
	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: char
# Returns:
#   R0: 1 if true
#===========================================================================
:_isalpha
	lt r0, 'A'
	jump? .retfalse
	lt r0, '['
	jump? .rettrue
	lt r0, 'a'
	jump? .retfalse
	lt r0, '{'
	jump? .rettrue
.retfalse
	mov r0, $0
	ret
.rettrue
	mov r0, $1
	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: char
# Returns:
#   R0: 1 if true
#===========================================================================
:_iswhitespace
	eq r0, ' '
	jump? .rettrue
	eq r0, 9 #tab (\t)
	jump? .rettrue
	eq r0, 10 #lf (\n)
	jump? .rettrue
	eq r0, 13 #cr (\r)
	jump? .rettrue
.retfalse
	mov r0, $0
	ret
.rettrue
	mov r0, $1
	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: buffer
#   R1: byte
#   R2: length
# Returns:
#   R0: buffer
#===========================================================================
:_memset
	mov @tmp0, r0
.loop
	sub r2, 1
	st.b [@tmp0], r1
	add @tmp0, 1
.check
	eq r2, 0
	ret?
	jump .loop
#===========================================================================


