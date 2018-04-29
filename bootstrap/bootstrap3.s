# Fourth stage bootstrap
# Line prefix determines behavior:
#   '#': Comment
#   ':': Defines an 8-byte label
#   '=': Defines a 2-byte hex constant
#   'tab': Assemble chars until a newline (:label refs auto-replaced)
#   'newline': Blank line, skipped
#
# Implements an assembler that supports a much richer, more human-readable format
#
# Includes real, two-pass label support (up to 32 chars long), simple call/return semantics

# The previous stage has some helpful macros for function calls:
#
# @ret.: Return from proc
# @ret?: Return from proc if flag
# @jump: Jump to address (@jump:label___)
# @jmp?: Jump to address if flag (@jmp?:label___)
# @call: Call address (@call:label___)
# @pshN: Push register N to the stack (supports 0-3)

# TODO:
#   - Need to support decimal/octal constants for C compat
#   - String support (should also auto-round address to power of 4)
#   - sys
#   - push/pop
#   - token logging should be optional based on command-line
#   - #include
#   - (?) object file support to make C easier?
#   - Symbol table with local symbs should be "rolled back" at next global symbol for perf
#   - Short immediate constants should use '=!x.' format

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
=zero____ 0030
=comma___ 002c
=plus____ 002b
=minus___ 002d
=left[___ 005b
=left{___ 007b
=left(___ 0028
=at______ 0040
=period__ 002e
=x_______ 0078
=z_______ 007a
=question 003f
=exclaim_ 0021
=gt______ 003e
=lt______ 003c
=multiply 002a
=div_____ 002f
=and_____ 0026
=or______ 007c
=quote___ 0022

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
# String
=T_STR___ 0006

:tokens__
	EOF 
	IMM 
	REF 
	INS 
	REG 
	EOL 
	STR 

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
# Does not return
#===========================================================================
:exit____
	=$0 :SC_EXIT_
	- 11
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
#  R0: Dest
#  R1: Src
# Returns:
#  R0: Dest
#===========================================================================
:strcpy__
	@psh0
:strcpyl_
	=[21
	[=02
	?=2a
	@jmp?:strcpyd_
	+ 0b
	+ 1b
	@jump:strcpyl_
:strcpyd_
	@pop0
	@ret.
#===========================================================================


#===========================================================================
# Args:
#  R0: String 1
#  R1: String 2
# Returns:
#  Equal? in flags
#===========================================================================
:strcmp__
:strcmpl_
	=[20
	=[31
	?!23
	@jmp?:retfalse
	?=2a
	@ret?
	+ 0b
	+ 1b
	@jump:strcmpl_
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
#   R0: Size
# Returns:
#   R0: Address
#===========================================================================
:malloc__
	=$x :heap____
	=(xx
	= 1x
	+ 10
	= 0x
	=$x :heap____
	(=x1
	@ret.
#===========================================================================


#===========================================================================
# Args:
#   R0: String
# Returns:
#   R0: Address
#===========================================================================
:mallocst
	@psh0
	@call:strlen__
	+ 0b
	@call:malloc__
	=$x :heap____
	=(xx
	@pop1
	@jump:strcpy__
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
	@jmp?:open_ro_
	=$3 :O_RDWR__
	=$x :O_TRUNC_
	| 3x
	=$x :O_CREAT_
	| 3x
:open_ro_
	S+203   
	+ 2b
	?!2a
	@jmp?:opensucc

	=$0 :eopfail_
	@jump:error___

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
	=$3 :in_hand_
	=(33
	S+0312  
	@ret.
#===========================================================================


#===========================================================================
# Args:
#   R0: NUL-terminated definition name
# Returns:
#   R0: Token type
#   R1: Token data
#===========================================================================
:lookupdf
	@psh0
	=$2 :deftab__

:lookdfl_
# Get the definition record
	=(22
	?=2a
	@jmp?:lookdfnf
# Get the pointer to the string
	+ 2e
	=(12
	@pop0
	@psh0
	@psh2
	@call:strcmp__
	@pop2
	@jmp?:lookdff_
	+ 2d
	@jump:lookdfl_

# Found
:lookdff_
	- 2d
	=(02
	- 2d
	=(12
	@pop2
	@ret.

:lookdfnf
	=$0 :elookdf_
	@jump:error___

:elookdf_
	define not found:__null__
#===========================================================================


#===========================================================================
# Args:
#   R0: Definition name
#   R1: Token type
#   R2: Token value
#===========================================================================
:createdf
	@psh0
	@psh1
	@psh2
# Allocate a record
	=#0 0010
	@call:malloc__
# Read the current record
	=$x :deftab__
	=(xx
# Write everything to the struct
	= 10
	@pop2
	(=12
	+ 1d
	@pop2
	(=12
	+ 1d
	@pop2
	(=12
	+ 1d
	(=1x
# Write the struct as the latest
	=$x :deftab__
	(=x0
	@ret.
#===========================================================================



#===========================================================================
# Args:
#   R0: String A (or 0)
#   R1: String B (or 0)
# Returns:
#   Equals in flag
#===========================================================================
:comparsm
	?=0a
	@jmp?:comparsz
	?=1a
	@jmp?:comparsz
	@jump:strcmp__
:comparsz
	?=01
	@ret.


#===========================================================================
# Args:
#   R0: Global symbol name
#   R1: Local symbol name
# Returns:
#   R0: Address
#===========================================================================
:lookupsm
	@psh0
	@psh1
	=$2 :symtab__

:looksml_
# Get the symbol record
	=(22
	?=2a
	@jmp?:looksmnf
# Get the pointer to the local name
	+ 2d
	=(12
	@pop0
	@psh0
	@psh2
	@call:comparsm
	@pop2
# Not a match, next record
	+^2e
	@jmp^:looksml_

	@pop1
	@pop0
	@psh0
	@psh1
	+ 2d
	=(12
	@psh2
	@call:comparsm
	@pop2
# Not a match, next record
	+^2d
	@jmp^:looksml_

	- 2e
	=(02
	@pop2
	@pop2
	@ret.

:looksmnf
	=$0 :elooksm_
	@jump:error___

:elooksm_
	symbol not found:__null__
#===========================================================================


#===========================================================================
# Args:
#   R0: Global symbol
#   R1: Local symbol (0 ok)
#   R2: Address
#===========================================================================
:createsm
	@psh0
	@psh1
	@psh2
# Allocate a record
	=#0 0010
	@call:malloc__
# Read the current record
	=$x :symtab__
	=(xx
# Write everything to the struct
	= 10
	@pop2
	(=12
	+ 1d
	@pop2
	(=12
	+ 1d
	@pop2
	(=12
	+ 1d
	(=1x
# Write the struct as the latest
	=$x :symtab__
	(=x0
	@ret.
#===========================================================================


#===========================================================================
# Args:
#   R0: Global symbol
#   R1: Local symbol (0 ok)
#   R2: Address
#===========================================================================
:createfx
	@psh0
	@psh1
	@psh2
# Allocate a record
	=#0 0010
	@call:malloc__
# Read the current record
	=$x :fixuptab
	=(xx
# Write everything to the struct
	= 10
	@pop2
	(=12
	+ 1d
	@pop2
	(=12
	+ 1d
	@pop2
	(=12
	+ 1d
	(=1x
# Write the struct as the latest
	=$x :fixuptab
	(=x0
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
	@call:istoksep
	@jmp?:readtok_

	=$x :newline_
	?=0x
	=$x :readtknl
	=?zx

	=$x :hash____
	?=0x
	=$x :readtok#
	=?zx

	=$x :period__
	?=0x
	=$x :readtok:
	=?zx

	=$x :colon___
	?=0x
	=$x :readtok:
	=?zx

	=$x :at______
	?=0x
	=$x :readtok:
	=?zx

	=$x :dollar__
	?=0x
	=$x :readtok$
	=?zx

	=$x :quote___
	?=0x
	=$x :readtokq
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
	@jump:error___

#***************************

:readtok:
	@psh0
	= 2a
	@psh2
:readtk:_
	@call:readchar
	@call:islabelc

	=$1 :readtkbf
	@pop2
	+ 12
	+ 2b
	@psh2
	=$x :readtk:y
	=?zx

# Store trailing NUL
	- 00
	[=10
# Put back the non-label char
	@call:rewind__

	@pop0
	@call:logtoken

	@pop0
	=$x :at______
	?!0x
	@jmp?:readtk:r

# This is a macro, so search for the definition
	=$0 :readtkbf
	@call:lookupdf
	@ret.

:readtk:r
# Return a reference token
	=$x :period__
	?=0x
# Token flag: 0 for local, 1 for global
	=?2a
	=^2b
	=$0 :T_REF___
	=$1 :readtkbf
	@jump:readtret

:readtk:y
# Store that last char
	[=10
	@jump:readtk:_

#***************************

:readtok#
	- 22
	@psh2
:readtk#l
# Eat chars until a newline
	@call:readchar
	@pop2
	=$x :newline_
	?=0x
	@jmp?:readtk#d
	=#3 0006
	?=23
	=$1 :readtkbf
	+ 12
	+ 2b
	[=10
	@jmp?:readtk#c
	@psh2
	@jump:readtk#l

# Fast look when we don't need to match #define
:readtk#f
	@call:readchar
	=$x :newline_
	?=0x
	@jmp?:readtk#d
	@jump:readtk#f

# We matched #define, so need to process this in a special way
:readtk#c
# NUL terminate, then compare against "define "
	+ 1b
	[=1a
	=$1 :readtkbf
	=$0 :readtk#s
	@call:strcmp__
	@jmp^:readtk#f
# Zero out the buffer
	=$0 :readtkbf
	- 11
	=#2 0020
	@call:memset__
# Definition name
	- 00
	@call:readtkwd
	=$0 :readtkbf
	@call:mallocst
	@psh0
# Read the next token
	@call:readtok_
	@psh0
	@psh1
# Expect an EOL
	@call:readeol_
	@pop2
	@pop1
	@pop0
	@call:createdf

# Return EOL for a comment
:readtk#d
	=$0 :T_EOL___
	@jump:readtret

:readtk#s
	define :__null__

#***************************

# We've read two chars at this point
:readtokr
# Make sure the first one was an 'r'
	=$x :letterr_
	?!1x
	@jmp?:readtinv

	=$x :zero____
	- 0x
	= 10
:readtkrl
	@psh1
	@call:readchar
	@pop1
	@call:istoksep
	@jmp?:readtkrd
	=$x :newline_
	?=0x
	@jmp?:readtkrd

	=#x 000a
	* 1x
	=$x :zero____
	- 0x
	+ 10
	@jump:readtkrl

:readtkrd

	@psh1
	@call:rewind__
	@pop1
	=$0 :T_REG___
	@jump:readtret

#***************************

:readtok$
	- 11
:readtk$l
	@psh1
	@call:readchar
	@pop1
	@call:istoksep
	@jmp?:readtk$d
	=$x :newline_
	?=0x
	@jmp?:readtk$d

	=#x 000a
	* 1x
	=$x :zero____
	- 0x
	+ 10
	@jump:readtk$l

:readtk$d

	@psh1
	@call:rewind__
	@pop1

	=$0 :T_IMM___
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
	@call:istoksep
	@jmp?:readtkid
	=$x :newline_
	?=0x
	@jmp?:readtkid

# If the instruction ends in a ?, this means it is only executed if flag == true
	=$x :question
	?=0x
	=?3b
	@jmp?:readtkip

# If the instruction ends in a ^, this means it is only executed if flag == false
	=$x :hat_____
	?=0x
	=?3c
	@jmp?:readtkip

# Store and continue
# TODO: We should probably check if this is alpha
# .. or use the new helper function
	[=20
	+ 2b
	@jump:readtkil

:readtkid
# Put the whitespace back
	@call:rewind__

:readtkip
	=#0 0006
	@call:logtoken

# Search the instruction table for a match
	=$0 :instruct
	=$2 :readtkbf
	=(22
	=$3 :lastinst
:readtkis
	=(10
	?=12
	@jmp?:readtkir
	+ 0e
# We need to skip the NOP from address refs too
	+ 0d
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
	Unknown instruction :__null__

#***************************

:readtokq
	=$2 :readtkbf
:readtkql
	@psh2
	@call:readchar
	@pop2
	=$x :quote___
	?=0x
	@jmp?:readtkqd
	[=20
	+ 2b
	@jump:readtkql
:readtkqd
# Trailing null
	[=2a
	=$x :readtkbf
	- 2x
	= 02
	@call:logtoken

	=$0 :T_STR___
	=$1 :readtkbf
	@jump:readtret

#***************************

:readtknl
	=$0 :T_EOL___
	@jump:readtret

#***************************

:readtret
# Write the token to stderr for debugging
	= 50
	* 5d
	=$x :tokens__
	+ 5x
	=$3 :SC_WRITE
	= 4c
	S+345d  
	=$x :rtnlbyte
	=$3 :SC_WRITE
	S+34xb  
	@ret.

:rtnlbyte
	:newline_

:rtspbyte
	:space___

# This is enough for 32-byte labels/identifiers/strings
:readtkbf
	........
	........
	........
	........

# r0 = len
:logtoken
	@psh1
	@psh2
	@psh3
	=$1 :readtkbf
	=#2 0002
	=$3 :SC_WRITE
	S+3210  
	=$1 :rtspbyte
	=#2 0002
	=$3 :SC_WRITE
	S+321b  
	@pop3
	@pop2
	@pop1
	@ret.

# r0 = offset into readtkbf
# returns r0 = last char
:readtkwd
	@psh0
:readtkwl
	@call:readchar
	@call:islabelc
	@jmp^:readtkwe
	@pop1
	=$x :readtkbf
	+ x1
	[=x0
	+ 1b
	@psh1
	@jump:readtkwl
:readtkwe
	@pop1
# Write a trailing NUL
	=$x :readtkbf
	+ x1
	[=xa
# Rewind that char
	@psh0
	@call:rewind__
	@pop0
	@ret.

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
# Args:
#   R0: Char
# Returns:
#   Flag in appropriate state
#   R0: Char
#===========================================================================
:istoksep
	=$x :space___
	?=0x
	@jmp?:rettrue_

	=$x :tab_____
	?=0x
	@jmp?:rettrue_

	=$x :comma___
	?=0x
	@jmp?:rettrue_

	@jump:retfalse
#===========================================================================


#===========================================================================
# Returns:
#   R0: File offset
#===========================================================================
:outtell_
	=$0 :out_hand
	=(00
	=$1 :SC_SEEK_
	- 22
	=$3 :SEEK_CUR
	S+1023  
	= 01
	@ret.
#===========================================================================


#===========================================================================
# Args:
#   R0: File offset
#===========================================================================
:outseek_
	=$2 :out_hand
	=(22
	=$1 :SC_SEEK_
	=$3 :SEEK_SET
	S+1203  
	@ret.
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
# Args:
#   R0: Char
#===========================================================================
:writech_
	=$x :writchbf
	[=x0
	=$0 :out_hand
	=(00
	=$1 :SC_WRITE
	= 2x
	= 3b
	S+1023  
	@ret.
:writchbf
	....
#===========================================================================



#===========================================================================
# Args:
#   R0: 32-bit value
#===========================================================================
:write32_
	=$x :writ32bf
	(=x0
	=$0 :out_hand
	=(00
	=$1 :SC_WRITE
	= 2x
	= 3d
	S+1023  
	@ret.
:writ32bf
	....
#===========================================================================


#===========================================================================
# Args:
#   R0: 16-bit value
#===========================================================================
:write16_
	=$x :writ16bf
	(=x0
	=$0 :out_hand
	=(00
	=$1 :SC_WRITE
	= 2x
	= 3c
	S+1023  
	@ret.
:writ16bf
	....
#===========================================================================


#===========================================================================
# Args:
#   R0: Buffer
#   R1: Length
#===========================================================================
:writebuf
	=$2 :out_hand
	=(22
	=$3 :SC_WRITE
	S+3201  
	@ret.
:writ32bf
	....
#===========================================================================


#===========================================================================
# Does not return
#===========================================================================
:errtoken
	=$x :einvtok_
	@jump:error___

:einvtok_
	Invalid token encountered:__null__
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

	@call:patchins

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

	=$x :T_REF___
	?=0x
	@jmp?:mlref___

	=$x :T_INS___
	?=0x
	@jmp?:mlins___

	@jump:errtoken

:mlref___
# Make a copy of this label string
	= 01
	@psh2
	@call:mallocst
	@pop2

# Global?
	?=2b
	@jmp?:mlref_g_

# Create a local symbol using the current global
	= 10
	@psh1
	@call:outtell_
	= 20
	@pop1
	=$x :mlglobal
	=(0x
	@call:createsm
	@jump:mainloop

:mlref_g_
# Store this as our global
	=$x :mlglobal
	(=x0
	@psh0
	@call:outtell_
	= 20
	@pop0
	- 11
	@call:createsm
	@jump:mainloop

:mlins___
# Extract the conditional execution flag
# TODO

# Perform a call to a mini-function that will jump to the next address
	@call:mlinsi__
	@jump:mainloop

:mlinsi__
	= z1

	@jump:mlfinish

:mlfinish

	=$x :fixuptab
	=(0x

:mlfixup_
	?=0a
	@jmp?:mlfixupd
	@psh0
# Address
	=(10
	+ 0d
	@psh1
# Local
	=(20
	+ 0d
# Global
	=(30
	+ 0d
	= 03
	= 12
	@call:lookupsm
	@pop1
	@psh0
	= 01
# Seek to address, fixup
	@call:outseek_
	@pop0
	@call:write32_
	@pop0
	+ 0d
	+ 0e
	=(00
	@jump:mlfixup_

:mlfixupd
	=#0 0000
	@call:exit____

# Current global label
:mlglobal
	:__null__
#===========================================================================


#===========================================================================
# Args:
#   None
#===========================================================================
:readeol_
	@call:readtok_
	=$x :T_EOL___
	?!0x
	=$x :eexpceol
	=?0x
	@jmp?:error___
	@ret.

:eexpceol
	Expected EOL:__null__
#===========================================================================


#===========================================================================
# Returns:
#   Register encoding in r0
#===========================================================================
:readreg_
	@call:readtok_
	=$x :T_REG___
	?!0x
	=$x :eexpregi
	=?0x
	@jmp?:error___
	@jump:encodreg

:eexpregi
	Expected register   :__null__
#===========================================================================


#===========================================================================
# Returns:
#   Register encoding in r0
#===========================================================================
:readropt
	@call:readtok_
	=$x :T_EOL___
	?=0x
	-?00
	@ret?

	=$x :T_REG___
	?!0x
	=$x :eexpregi
	=?0x
	@jmp?:error___
	@jump:encodreg
#===========================================================================


#===========================================================================
# Args:
#   R1: The register index
# Returns:
#   Register encoding in r0
#===========================================================================
:encodreg
# Move the reg# to r0
	=$0 :register
	+ 01
# Load the character representing the register
	=[00
	@ret.
#===========================================================================


#===========================================================================
# Args:
#   R0: Token type
#   R1: Token value
#   R2: Token flag
#===========================================================================
:encrefim
	=$x :T_REF___
	?=0x
	@jmp?:encref__

	=$x :T_IMM___
	?=0x
	@jmp?:encimm__

	@jump:errtoken

:encref__
# Create a fixup
	?=2b
	@jmp?:i__valrg
# For a local ref we use the global symbol and copy the local token
	= 01
	@call:mallocst
	= 10
	@psh1
	@call:outtell_
	= 20
	@pop1
	=$x :mlglobal
	=(0x
	@call:createfx
# Use a fake address for now
	=#1 1234
	@psh1
	@jump:enc32___
:i__valrg
# For a global ref we need to copy the token
	= 01
	@call:mallocst
	@psh0
	@call:outtell_
# Add 4 to file position for fixup
	= 20
	@pop0
	- 11
	@call:createfx
# Use a fake address for now
	=#1 1234
	@psh1
	@jump:enc32___
:encimm__
	@psh1
	@jump:enc32___

:enc32___
	@pop0
	@call:write32_
	@ret.
#===========================================================================


#===========================================================================
# Returns:
#   R0: Register encoding for value
#===========================================================================
:readval_
	@call:readtok_
	=$x :T_REG___
	?=0x
	@jmp?:encodreg

# If it's not a register, assign it to x
	@psh0
	@psh1
	@psh2
	=$0 :xeqconst
	= 1d
	@call:writebuf
	@pop2
	@pop1
	@pop0

	@call:encrefim

	=$0 :x_______
	@ret.

:xeqconst
	=$x 
:i_stdbf1
	....
:i_stdbf2
	....
#===========================================================================

# Syntax highlighters get confused by our unmatched brackets
# This is an unfortunate necessity
	]})]})]})]})


# Standard instruction
:i_stnd__
	=$2 :i_stdbf1
	(=20
	=$2 :i_stdbf2
	(=21
# Target register
	@call:readreg_
	@psh0
# Source register/value
	@call:readval_
	@psh0
	=$1 :i_stdbf1
	=(01
	@call:writech_
	=$1 :i_stdbf2
	=(01
	@call:writech_
	@pop1
	@pop0
	@psh1
	@call:writech_
	@pop0
	@call:writech_
	@call:readeol_
	@ret.

# Standard store instruction
:i_stndst
	=$2 :i_stdbf1
	(=20
# Source register/value
	@call:readval_
	@psh0
# Target register
	@call:readreg_
	@psh0
	=$1 :i_stdbf1
	=(01
	@call:writech_
	=$0 :equals__
	@call:writech_
	@pop1
	@pop0
	@psh1
	@call:writech_
	@pop0
	@call:writech_
	@call:readeol_
	@ret.


:i_mov___
	=$0 :equals__
	=$1 :space___
	@jump:i_stnd__
:i_add___
	=$0 :plus____
	=$1 :space___
	@jump:i_stnd__
:i_sub___
	=$0 :minus___
	=$1 :space___
	@jump:i_stnd__
:i_mul___
	=$0 :multiply
	=$1 :space___
	@jump:i_stnd__
:i_div___
	=$0 :div_____
	=$1 :space___
	@jump:i_stnd__
:i_or____
	=$0 :or______
	=$1 :space___
	@jump:i_stnd__
:i_and___
	=$0 :and_____
	=$1 :space___
	@jump:i_stnd__
:i_xor___
	=$0 :hat_____
	=$1 :space___
	@jump:i_stnd__
:i_sub___
	=$0 :minus___
	=$1 :space___
	@jump:i_stnd__
:i_push__
	@call:readropt
	?=0a
	@ret?
	@jump:i_push__
:i_pop___
	@call:readropt
	?=0a
	@ret?
	@jump:i_pop___
:i_ldb___
	=$0 :equals__
	=$1 :left[___
	@jump:i_stnd__
	@ret.
:i_ldw___
	=$0 :equals__
	=$1 :left{___
	@jump:i_stnd__
	@ret.
:i_ldd___
	=$0 :equals__
	=$1 :left(___
	@jump:i_stnd__
	@ret.
:i_stb___
	=$0 :left[___
	@jump:i_stndst
	@ret.
:i_stw___
	=$0 :left{___
	@jump:i_stndst
	@ret.
:i_std___
	=$0 :left(___
	@jump:i_stndst
	@ret.
:i_eq____
	=$0 :question
	=$1 :equals__
	@jump:i_stnd__
	@ret.
:i_ne____
	=$0 :question
	=$1 :exclaim_
	@jump:i_stnd__
	@ret.
:i_gt____
	=$0 :question
	=$1 :gt______
	@jump:i_stnd__
	@ret.
:i_lt____
	=$0 :equals__
	=$1 :lt______
	@jump:i_stnd__
	@ret.
:i_call__
# Note that call doesn't support a register target yet - this is possible but would complicate
# this code
	=$0 :i_call_s
	=#1 0014
	@call:writebuf
	@call:readtok_
	@call:encrefim
	@ret.
:i_jump__
	@call:readtok_
	=$x :T_REG___
	?=0x
	@jmp?:i_jump_r
	@psh0
	@psh1
	@psh2
	=$0 :i_jump_s
	=#1 0004
	@call:writebuf
	@pop2
	@pop1
	@pop0
	@call:encrefim
	@ret.
:i_jump_r
# Emit faster jump to a register
	@psh1
	=$0 :equals__
	@call:writech_
	=$0 :space___
	@call:writech_
	=$0 :z_______
	@call:writech_
	@pop1
	@call:encodreg
	@call:writech_
	@ret.
:i_ret___
	@call:readeol_
	=$0 :i_ret__s
	=#1 000c
	@call:writebuf
	@ret.
:i_ret__s
	=(xy+!y.= zx
:i_sys___
	@call:readropt
	?=0a
	@ret?
	@jump:i_sys___
:i_db____
	@call:readtok_
	=$x :T_EOL___
	?=0x
	@ret?
	=$x :T_IMM___
	?=0x
	@jmp?:i_db_i__
	=$x :T_STR___
	?=0x
	@jmp?:i_db_s__
	@jump:errtoken
:i_db_i__
	= 01
	=#1 00ff
	?>01
	@jmp?:errtoken
	@call:writech_
	@jump:i_db____
:i_db_s__
	@psh1
	= 01
	@call:strlen__
	= 10
	@pop0
	@call:writebuf
	@jump:i_db____
:i_dw____
	@call:readtok_
	=$x :T_EOL___
	?=0x
	@ret?
	=$x :T_IMM___
	?=0x
	@jmp?:i_dw_i__
	@jump:errtoken
:i_dw_i__
	= 01
	@call:write16_
	@jump:i_dw____
:i_dd____
	@call:readtok_
	=$x :T_EOL___
	?=0x
	@ret?
	@call:encrefim
	@jump:i_dd____
:i_ds____
	@call:i_db____
:i_ds_alg
# Alignment loop
	- 00
	@call:writech_
	@call:outtell_
	=#1 0003
	& 01
	?!0a
	@jmp?:i_ds_alg
	@ret.

# Syntax highlighters get confused by our unmatched brackets
# This is an unfortunate necessity
	]})]})]})]})

#===========================================================================
# Called at init time to patch some of our instruction strings
#===========================================================================
:patchins
# Patch the constant into ret
	=$x :i_ret__s
	=#0 0007
	+ x0
	=#0 0004
	[=x0

# Patch the constants into call
	=$x :i_call_s
	=#0 0003
	+ x0
	=#0 0004
	[=x0
	+ x0
	=#0 000c
	[=x0

	@ret.

:i_call_s
	-!y.=!x.+ xz(=yx=$z 
:i_jump_s
	=$z 
#===========================================================================

# Simple lookup table for registers
:register
	0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz..

# Instruction table
:instruct
	mov 
	:i_mov___

	add 
	:i_add___

	sub 
	:i_sub___

	mul 
	:i_mul___

	div 
	:i_div___

	or  
	:i_or____

	and 
	:i_and___

	xor 
	:i_xor___

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

	eq  
	:i_eq____

	ne  
	:i_ne____

	gt  
	:i_gt____

	lt  
	:i_lt____

	call
	:i_call__

	jump
	:i_jump__

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

# Linked list of symbols:
# [global symbol pointer] [local symbol pointer] [write address] [prev symbol]
:symtab__
	:__null__

# Linked list of defines:
# [define string pointer] [token type] [token value] [prev define]
:deftab__
	:__null__

# Linked list of fixups:
# [fixup address] [global symbol pointer] [local symbol pointer] [prev fixup]
:fixuptab
	:__null__

# Current heap pointer
:heap____
	:scratch_

:scratch_

