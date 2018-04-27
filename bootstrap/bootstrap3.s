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

=__null__ 0000
=newline_ 000a
=hash____ 0023
=colon___ 003a
=tab_____ 0009
=equals__ 003d

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

=SC_OPEN_ 0000
=O_RDONLY 0000
=O_WRONLY 0001
=O_RDWR__ 0002
=O_TRUNC_ 0200
=O_CREAT_ 0400

=SC_READ_ 0001
=SC_WRITE 0002
=SC_SEEK_ 0003
=SC_CLOSE 0004
=SC_GTARG 0005
=SC_GTMEM 0006
=SC_EXIT_ 0007

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

# Rx = Temp var
# Ry = Stack pointer
# Rz = PC

:entry___
	@jump:main____



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

#===========================================================================


#===========================================================================
# Args:
#   R0: Which
# Returns:
#   R0: Pointer to string (zero terminated)
#===========================================================================
:getargv_

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
	- 2b
	=[01
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
	?!0a
	=$x :opensucc
	J?z 

	=$0 :eopfail_
	@call:error___

:opensucc
	= 02
	@ret.


:eopfail_
	Failed to open file :__null__
#===========================================================================



#===========================================================================
# Returns:
#   R0: Token type
#   R1: Token data
#===========================================================================
:readtok_
	@call:readchar

	=$z :newline_
	=?0z
	=$z :readtok_
	J?z 

	=$z :hash____
	=?0z
	=$z :readtok#
	J?z 

	=$z :colon___
	=?0z
	=$z :readtok:
	J?z 

	=!0a
	=$z :readtoke
	J?z 

# Return zero at EOF
	@ret.

:readtoke
	=$0 :einvchar
	@call:error___

:readtok$

:readtok#
# Eat chars until a newline
	@call:readchar
	=$z :newline_
	?=0z
	=$z :readtok_
	J?z 

:readtokr
:readtok:

:einvchar
	Invalid character   :__null__
#===========================================================================



#===========================================================================
# Args:
#   R0: Handle
# Returns:
#   R0: Char (zero if EOF)
#===========================================================================
:readchar
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
	=$z :T_EOF___
	?=0z
	=$z :mlfinish

	=$z :T_IMM___
	?!0z
	=$z :mlnotimm

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
	....

:einvtok_
	Invalid token encountered :__null__
#===========================================================================




:i_mov___
:i_add___
:i_sub___
:i_pus___
:i_pop___
:i_ldb___
:i_ldw___
:i_ldd___
:i_call__
:i_ret___
:i_sys___
:i_dat___

# Instruction table
:instruct
	mov 
	:i_mov___

	add 
	:i_add___

	sub 
	:i_sub___

	psh 
	:i_pus___

	pop 
	:i_pop___

	ldb 
	:i_ldb___

	ldw 
	:i_ldw___

	ldd 
	:i_ldd___

	cal 
	:i_call__

	ret 
	:i_ret___

	sys 
	:i_sys___

	dat 
	:i_dat___

:scratch_
