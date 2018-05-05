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


#===========================================================================
# Args:
#   R0: char
# Returns:
#   R0: Hex value, or -1 if none
#===========================================================================
:_hexchar
	lt r0, '0'
	jmp? .retnone
	lt r0, ':'
	jmp? .retdigit
	lt r0, 'A'
	jmp? .retnone
	lt r0, 'G'
	jmp? .retLETTER
	lt r0, 'a'
	jmp? .retnone
	lt r0, 'g'
	jmp? .retletter
.retnone
	mov r0, $-1
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
	jmp? .retfalse
	lt r0, ':'
	jmp? .rettrue
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
	jmp? .retfalse
	lt r0, '['
	jmp? .rettrue
	lt r0, 'a'
	jmp? .retfalse
	lt r0, '{'
	jmp? .rettrue
.retfalse
	mov r0, $0
	ret
.rettrue
	mov r0, $1
	ret
#===========================================================================





