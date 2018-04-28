# Fourth stage bootstrap
# Line prefix determines behavior:
#   '#': Comment
#   ':': Defines an 8-byte label
#   '=': Defines a 2-byte hex constant
#   'tab': Assemble chars until a newline (:label refs auto-replaced)
#   'newline': Blank line, skipped
#	'@': Macro definition
#
# Implements an assembler that supports a much richer, more human-readable format
#
# Includes real, two-pass label support (up to 12 chars long), simple call/return semantics,
# better opcode format

# Return from proc
# @ret.: =(xy+ yd== zx
# Return from proc if flag
# @ret?: =(xy+?yd==?zx
# Jump to address (@jump:label___)
# @jump: =$z 
# Call address (@call:label___)
# @call: =(yz- yd=$z 

# Rx = Temp var
# Ry = Stack pointer
# Rz = PC

:entry___
# Ra = Zero register
	- aa
# Rb = One register
	=#b 0001
# Rc = Two register
	=#c 0002
# Rd = Four register
	=#d 0004
# Re = Eight register
	=#e 0008

# Set stack to memsize
	=$0 :SC_GTMEM
	S 0 
	= y0
	- yd

	@jump:main____

=__null__ 0000
=newline_ 000a
=hash____ 0023
=colon___ 003a
=tab_____ 0009
=space___ 0020
=equals__ 003d
=dollar__ 0024
=letterr_ 0072
=question 003f
=hat_____ 005e

# EOF
=T_EOF___ 0000
# Immediate constant (data = value)
=T_IMM___ 0001
# Reference (constant or label, data = ptr to zero-terminated label)
=T_REF___ 0002
# Instruction (data = ins handler function)
=T_INS___ 0003
# Register (data = reg #)
=T_REG___ 0004
# EOL
=T_EOL___ 0005

:tokens__
	EOF 
	IMM 
	REF 
	INS 
	REG 
	EOL 

=SC_OPEN_ 0000
=O_RDONLY 0000
=O_WRONLY 0001
=O_RDWR__ 0002
=O_TRUNC_ 0200
=O_CREAT_ 0400

=SC_READ_ 0001
=SC_WRITE 0002

=SC_SEEK_ 0003
=SEEK_SET 0000
=SEEK_CUR 0001
=SEEK_END 0002

=SC_CLOSE 0004
=SC_GTARG 0005
=SC_GTMEM 0006
=SC_EXIT_ 0007


# Global: Input file handle
:in_hand_
	....

# Global: Output file handle
:out_hand
	....

#===========================================================================
# Args:
#   R0: Error string
# Does not return
#===========================================================================
:error___
# Stash R0 in stack
	@psh0
	@call:strlen__
	@pop3
	=$1 :SC_WRITE
	=#2 0002
	S+1230  
# Write a newline
	=$1 :SC_WRITE
	=#3 000a
	[=33
	S+123b  
# Exit with code 1
	=$0 :SC_EXIT_
	=#1 0001
	S 01
#===========================================================================


#===========================================================================
# Args:
#   R0: Which
# Returns:
#   R0: Pointer to string (zero terminated)
#===========================================================================
:getargv_
	=$1 :SC_GTARG
	=$2 :scratch_
	=#3 1000
	S+123   
	* 0d
	+ 02
	=(00
	@ret.
#===========================================================================


#===========================================================================
# Args:
#   R0: String
# Returns:
#   R0: Length
#===========================================================================
:strlen__
	= 10
:strlenl_
	=[20
	?=2a
	@jmp?:strlenr_
	+ 0b
	@jump:strlenl_
:strlenr_
	- 01
	@ret.
#===========================================================================


#===========================================================================
# Args:
#   R0: Address
#   R1: Value
#   R2: Length
#===========================================================================
:memset__
# If length == 0, return
	?=2a
	@ret?
	[=01
	+ 0b
	- 2b
	@jump:memset__
#===========================================================================


#===========================================================================
# Args:
#   R0: Filename
#   R1: Mode (0 = read, 1 = write)
# Returns:
#   R0: Handle
#===========================================================================
:open____
	=$2 :SC_OPEN_
	=$3 :O_RDONLY
	?=1a
	=$x :open_ro_
	=$3 :O_RDWR__
	=$x :O_TRUNC_
	| 3x
	=$x :O_CREAT_
	| 3x
:open_ro_
	S+2013  
	+ 2b
	?!2a
	@jmp?:opensucc

	=$0 :eopfail_
	@call:error___

:opensucc
	= 02
	- 0b
	@ret.


:eopfail_
	Failed to open file :__null__
#===========================================================================



#===========================================================================
# Steps back in the input file by one char
# No args/return
#===========================================================================
:rewind__
	=$0 :SC_SEEK_
	- 11
	- 1b
	=$2 :SEEK_CUR
	S+0812  
	@ret.
#===========================================================================


#===========================================================================
# Returns:
#   R0: Token type
#   R1: Token data
#===========================================================================
:readtok_
	@call:readchar

# Whitespace is ignored
	=$x :space___
	?=0x
	=$x :readtok_
	=?zx

# Whitespace is ignored
	=$x :tab_____
	?=0x
	=$x :readtok_
	=?zx

	=$x :newline_
	?=0x
	=$x :readtknl
	=?zx

	=$x :hash____
	?=0x
	=$x :readtok#
	=?zx

	=$x :colon___
	?=0x
	=$x :readtok:
	=?zx

	=$x :dollar__
	?=0x
	=$x :readtok$
	=?zx

# Return zero at EOF
	?=0a
	@jmp?:readtret

# Make sure it's alpha-numeric
	@call:isalnum_
	@jmp^:readtinv

# This might be an instruction or register at this point, so read a second char
	@psh0
	@call:readchar
	@pop1

# If this one is a number, it's a register
	@call:isnumber
	@jmp?:readtokr

# Otherwise if it's alnum, it's an instruction
	@call:isalnum_
	@jmp?:readtoki

:readtinv
	=$0 :einvchar
	@call:error___

#***************************

:readtok:
	- 22
:readtk:_
	@call:readchar
	@call:islabelc

	=$1 :readtkbf
	+ 12
	=$x :readtk:y
	=?zx

# Store trailing NUL
	- 00
	[=10
# Put back the non-label char
	@call:rewind__
# Return a reference token
	=$0 :T_REF___
	=$1 :readtkbf
	@jump:readtret

:readtk:y
# Store that last char
	[=10
	@jump:readtk:_

#***************************

:readtok#
# Eat chars until a newline
	@call:readchar
	=$x :newline_
	?!0x
	=$x :readtok#
	=?zx
# Return EOL for a comment
	=$0 :T_EOL___
	@jump:readtret

#***************************

# We've read two chars at this point
:readtokr
# Make sure the first one was an 'r'
	=$x :letterr_
	?!1x
	@jmp?:readtinv

	=$0 :T_REG___
	@jump:readtret

#***************************

# We've read two chars at this point (r1 and r0)
:readtoki
# Clear the token buffer
	@psh0
	@psh1
	=$0 :readtkbf
	=#1 0020
	=#2 0020
	@call:memset__
	@pop1
	@pop0
	=$2 :readtkbf
	[=21
	+ 2b
	[=20
	+ 2b
	- 33

# Read until we get a space, tab or newline
:readtkil
	@psh2
	@psh3
	@call:readchar
	@pop3
	@pop2
	=$x :space___
	?=0x
	@jmp?:readtkid
	=$x :tab_____
	?=0x
	@jmp?:readtkid
	=$x :newline_
	?=0x
	@jmp?:readtkid

# If the instruction ends in a ?, this means it is only executed if flag == true
	=$x :question
	?=0x
	=?3b
	@jmp?:readtkid

# If the instruction ends in a ^, this means it is only executed if flag == false
	=$x :hat_____
	?=0x
	=?3c
	@jmp?:readtkid

# Store and continue
# TODO: We should probably check if this is alpha
	[=20
	+ 2b
	@jump:readtkil

:readtkid
# Put the whitespace back
	@call:rewind__

	=$0 :SC_WRITE
	=#1 0002
	=$2 :readtkbf
	=#3 0006
	S+0123  

# Search the instruction table for a match
	=$0 :instruct
	=(22
	=$3 :lastinst
:readtkis
	=(10
	?=12
	@jmp?:readtkir
	+ 0e
	?=03
	@jmp?:readtkie
	@jump:readtkis

:readtkir
# Read instruction address
	+ 0d
	=(10
# Return
	=$0 :T_INS___
	@jump:readtret

:readtkie
	=$0 :inserr__
	@jump:error___

:inserr__
	Unknown instruction:__null__

#***************************

:readtok$
	=$0 :T_IMM___
	@jump:readtret

#***************************

:readtknl
	=$0 :T_EOL___
	@jump:readtret

#***************************

:readtret
# Write the token to stderr for debugging
	= 20
	* 2d
	=$x :tokens__
	+ 2x
	=$3 :SC_WRITE
	= 1c
	S+312d  
	@ret.

# This is enough for 32-byte labels
:readtkbf
	........
	........
	........
	........

:einvchar
	Invalid character   :__null__
#===========================================================================

# Useful function ends to return false or true in the flag

:retfalse
	?!11
	@ret.

:rettrue_
	?=11
	@ret.

#===========================================================================
# Args:
#   R0: Char
# Returns:
#   Flag in appropriate state
#   R0: Char
#===========================================================================
:islabelc
# Underscore is cool
	=#x 005f
	?=0x
	@ret?

	@jump:isalnum_
#===========================================================================


#===========================================================================
# Args:
#   R0: Char
# Returns:
#   Flag in appropriate state
#   R0: Char
#===========================================================================
:isnumber
	=#x 0030
	?<0x
	=$x :retfalse
	=?zx

	=#x 003a
	?<0x
	=$x :rettrue_
	=?zx

	@jump:retfalse
#===========================================================================


#===========================================================================
# Args:
#   R0: Char
# Returns:
#   Flag in appropriate state
#   R0: Char
#===========================================================================
:isalnum_
	=#x 0030
	?<0x
	=$x :retfalse
	=?zx

	=#x 003a
	?<0x
	=$x :rettrue_
	=?zx

	=#x 0041
	?<0x
	=$x :retfalse
	=?zx

	=#x 005b
	?<0x
	=$x :rettrue_
	=?zx

	=#x 0061
	?<0x
	=$x :retfalse
	=?zx

	=#x 007b
	?<0x
	=$x :rettrue_
	=?zx

	@jump:retfalse
#===========================================================================


#===========================================================================
# Returns:
#   R0: Char (zero if EOF)
#===========================================================================
:readchar
	=$0 :in_hand_
	=(00
	=$1 :SC_READ_
	=$2 :readchbf
	[=2a
	= 3b
	S+1023  
	=[02
	@ret.
:readchbf
	????
#===========================================================================


#===========================================================================
# Main loop
#===========================================================================
:main____

# Open argv[1] as ro, store in in_hand_
	= 0b
	@call:getargv_
	= 1a
	@call:open____
	=$x :in_hand_
	(=x0

# Open argv[2] as rw, store in out_hand_
	= 0c
	@call:getargv_
	= 1b
	@call:open____
	=$x :out_hand
	(=x0


:mainloop
# Read a token
	@call:readtok_

# EOF?
	=$x :T_EOF___
	?=0x
	@jmp?:mlfinish

# EOL?
	=$x :T_EOL___
	?=0x
	@jmp?:mainloop

	=$x :T_IMM___
	?!0x
	@jmp?:mlnotimm

# Immediate

:mlnotimm

	=$z :T_INS___
	?!0z
	=$z :mlnotins

:mlnotins

	=$0 :einvtok_
	@call:error___


:mlfinish

#TODO
	xxxx

:einvtok_
	Invalid token encountered   :__null__
#===========================================================================




:i_mov___
:i_add___
:i_sub___
:i_push__
:i_pop___
:i_ldb___
:i_ldw___
:i_ldd___
:i_stb___
:i_stw___
:i_std___
:i_call__
:i_ret___
:i_sys___
:i_db____
:i_dw____
:i_dd____
:i_ds____

# Instruction table
:instruct
	mov 
	:i_mov___

	add 
	:i_add___

	sub 
	:i_sub___

	push
	:i_push__

	pop 
	:i_pop___

	ld.b
	:i_ldb___

	ld.w
	:i_ldw___

	ld.d
	:i_ldd___

	st.b
	:i_stb___

	st.w
	:i_stw___

	st.d
	:i_std___

	call
	:i_call__

	ret 
	:i_ret___

	sys 
	:i_sys___

	db  
	:i_db____

	dw  
	:i_dw____

	dd  
	:i_dd____

	ds  
	:i_ds____

:lastinst
:scratch_

