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
#   R0: String
#   R1: Character
# Returns:
#   R0: Pointer to last occurrence of character, or null
#===========================================================================
:_strrchr
	push r2, r3
	mov r2, 0  # Last occurrence pointer
.loop
	ld.b r3, [r0]
	eq r3, r1
	mov? r2, r0  # Update last occurrence
	eq r3, 0
	jump? .done
	add r0, 1
	jump .loop
.done
	mov r0, r2  # Set return value to last occurrence
	pop r3, r2
	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: Destination string
#   R1: Source string
# Returns:
#   R0: Pointer to the resulting string (same as destination)
#===========================================================================
:_strcat
	push r2, r3, r4
	mov r2, r0

.find_end
	ld.b @tmp0, [r0]
	eq @tmp0, 0
	jump? .loop
	add r0, 1
	jump .find_end

# R0 is the write pointer
# R1 is the read pointer
.loop
	ld.b @tmp0, [r1]
	st.b [r0], @tmp0
	eq @tmp0, 0
	jump? .done
	add r0, 1
	add r1, 1
	jump .loop
.done
	mov r0, r2
	pop r4, r3, r2
	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: Dest
#   R1: Source
# Returns:
#   R0: Dest
#===========================================================================
:_strcpy
	mov @tmp1, r0
.loop
	ld.b @tmp0, [r1]
	st.b [r0], @tmp0
	eq @tmp0, 0
	mov? r0, @tmp1
	ret?

	add r0, 1
	add r1, 1
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
# Args:
#   R0: String 1
#   R1: String 2
# Returns:
#   1 if S1=S2, 0 otherwise
#===========================================================================
:_streq
.loop
	ld.b @tmp0, [r0]
	ld.b @tmp1, [r1]
	ne @tmp0, @tmp1
	jump? .ne
	eq @tmp0, 0
	mov? @ret, 1
	ret?
	add r0, 1
	add r1, 1
	jump .loop
.ne
	mov @ret, 0
	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: String
# Returns:
#   malloc'd copy, zero terminated
#===========================================================================
:_stralloc
	%arg s

	%call :_strlen, @s
	add @ret, 1
	%call :_malloc, @ret
	%call :_strcpy, @ret, @s

	%ret
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


#===========================================================================
# Args:
#   R0: String
# Returns:
#   R0: Unsigned integer value
#===========================================================================
:_atou
	push r1, r2
	mov r1, r0  # R1: current character pointer
	mov r2, 0   # R2: result

	# Skip leading whitespace
.skip_whitespace
	ld.b @tmp0, [r1]
	%call :_iswhitespace, @tmp0
	eq r0, 1
	jump^ .convert_loop
	add r1, 1
	jump .skip_whitespace

.convert_loop
	ld.b @tmp0, [r1]
	%call :_isdigit, @tmp0
	eq r0, 0
	jump? .done
	
	sub @tmp0, '0'
	mul r2, 10
	add r2, @tmp0
	
	add r1, 1
	jump .convert_loop

.done
	mov r0, r2  # Set return value
	pop r2, r1
	ret
#===========================================================================
