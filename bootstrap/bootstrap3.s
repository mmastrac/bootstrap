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
#   - Need to support decimal/hex constants for C compat
#   - sys
#   - push/pop
#   - #include
#   - (?) object file support to make C easier?
#   - Symbol table with local symbs should be "rolled back" at next global symbol for perf
#      - Can we do local fixups per global?
#   - Short immediate constants should use '=!x.' format
#   - readtok_ subroutines should be real functions

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
# Define
=T_DEF___ 0007

:tokens__
	EOF\00
	IMM\00
	REF\00
	INS\00
	REG\00
	EOL\00
	STR\00
	DEF\00

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
	____

# Global: Output file handle
:out_hand
	____

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
# Register-friendly stderr logging.
# Args:
#   R0: String
# Returns:
#   All registers: Unchanged
#===========================================================================
:log_____
	@psh1
	@psh2

	@psh0
	@call:strlen__
	= 20
	@pop0

	=$1 :SC_WRITE
	S+1c02  
	@pop2
	@pop1
	@ret.

.stash___
	____
#===========================================================================


#===========================================================================
# Register-friendly stderr logging.
# Args:
#   R0: Number
# Returns:
#   All registers: Unchanged
#===========================================================================
:lognum__
	@psh0
	@psh1
	@psh2

	@psh0
# Clear the buffer
	=$0 .buffer__
	= 1a
	=#2 0010
	@call:memset__
	@pop0

	= MM

# Start at the end of the buffer
	=$1 .buffer__
	=#x 000e
	+ 1x

.loop____
	= 20
# Get the lowest digit
	=#x 000a
	% 2x
# Get the ASCII version
	=$x .digits__
	+ 2x
	=[22
# Write it to the buffer
	[=12
	- 1b
	=#x 000a
# If we still have digits to write, continue
	/ 0x
	?>0a
	@jmp?.loop____

	= 01
	+ 0b
	@call:log_____

	@pop2
	@pop1
	@pop0
	@ret.

.buffer__
	\00\00\00\00\00\00\00\00
	\00\00\00\00\00\00\00\00

.digits__
	0123456789__

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
.loop____
	=[20
	?=2a
	@jmp?.ret_____
	+ 0b
	@jump.loop____
.ret_____
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
.loop____
	=[21
	[=02
	?=2a
	@jmp?.ret_____
	+ 0b
	+ 1b
	@jump.loop____
.ret_____
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
	=[20
	=[31
	?!23
	@jmp?:retfalse
	?=2a
	@ret?
	+ 0b
	+ 1b
	@jump:strcmp__
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
	@jmp?.readonly
	=$3 :O_RDWR__
	=$x :O_TRUNC_
	| 3x
	=$x :O_CREAT_
	| 3x
.readonly
	S+203   
	+ 2b
	?!2a
	@jmp?.success_

	=$0 .errfail_
	@jump:error___

.success_
	= 02
	- 0b
	@ret.

.errfail_
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

.loop____
# Get the definition record
	=(22
	?=2a
	@jmp?.notfound
# Get the pointer to the string
	+ 2e
	=(12
	@pop0
	@psh0
	@psh2
	@call:strcmp__
	@pop2
	@jmp?.found___
	+ 2d
	@jump.loop____

# Found
.found___
	- 2d
	=(02
	- 2d
	=(12
	@pop2
	@ret.

.notfound
	=$0 .errnotfo
	@jump:error___

.errnotfo
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
	@jmp?.zero____
	?=1a
	@jmp?.zero____
	@jump:strcmp__
.zero____
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

.loop____
# Get the symbol record
	=(22
	?=2a
	@jmp?.notfound
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
	@jmp^.loop____

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
	@jmp^.loop____

	- 2e
	=(02
	@pop2
	@pop2
	@ret.

.notfound
	=$0 .errnotfo
	@jump:error___

.errnotfo
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
#   R0: Pointer to label string
#===========================================================================
:readlbl_
	= 1a
	@psh1
.loop____
	- 00
	@call:readchar
	@call:islabelc
	@jmp^.done____
	@pop1
	=$x .buffer__
	+ x1
	[=x0
	+ 1b
	@psh1
	@jump.loop____
.done____
	@pop1
# Write a trailing NUL
	=$x .buffer__
	+ x1
	[=xa
# Rewind that char
	@call:rewind__
	=$0 .buffer__
	@ret.

# This is enough for 32-byte labels/identifiers/strings
.buffer__
	________
	________
	________
	________
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
	=$x .eol_____
	=?zx

	=$x :hash____
	?=0x
	=$x .cmt_____
	=?zx

	=$x :period__
	?=0x
	=$x .label___
	=?zx

	=$x :colon___
	?=0x
	=$x .label___
	=?zx

	=$x :at______
	?=0x
	=$x .label___
	=?zx

	=$x :dollar__
	?=0x
	=$x .readtok$
	=?zx

	=$x :quote___
	?=0x
	=$x .readtokq
	=?zx

# Return zero at EOF
	?=0a
	@jmp?.ret_____

# Make sure it's alpha-numeric
	@call:isalnum_
	@jmp^.readtinv

# This might be an instruction or register at this point, so read a second char
	@psh0
	@call:readchar
	@pop1

# If this one is a number, it's a register
	@call:isnumber
	@jmp?.readtokr

# Otherwise if it's alnum, it's an instruction
	@call:isalnum_
	@jmp?.readtoki

#***************************

.label___
	@psh0
	@call:readlbl_
	= 10
	@pop0
	=$x :at______
	?!0x
	@jmp?.labelref

# This is a macro, so search for the definition
	= 01
	@call:lookupdf
	@jump.ret_____

.labelref
# Return a reference token
	=$x :period__
	?=0x
# Token flag: 0 for local, 1 for global
	=?2a
	=^2b
	=$0 :T_REF___
	@jump.ret_____

#***************************

.cmt_____
	- 22
	@psh2
.cmtloop_
# Eat chars until a newline
	@call:readchar
	@pop2
	=$x :newline_
	?=0x
	@jmp?.cmtdone_
	=#3 0006
	?=23
	=$1 .buffer__
	+ 12
	+ 2b
	[=10
	@jmp?.cmtdef__
	@psh2
	@jump.cmtloop_

# Fast look when we don't need to match #define
.cmtfastl
	@call:readchar
	=$x :newline_
	?=0x
	@jmp?.cmtdone_
	@jump.cmtfastl

# We matched #define, so need to process this in a special way
.cmtdef__
# NUL terminate, then compare against "define "
	+ 1b
	[=1a
	=$1 .buffer__
	=$0 .cmtdstr_
	@call:strcmp__
	@jmp^.cmtfastl

# It's a #define token, so return that
	=$0 :T_DEF___
	@jump.ret_____

# Return EOL for a comment
.cmtdone_
	=$0 :T_EOL___
	@jump.ret_____

.cmtdstr_
	define :__null__

#***************************

# We've read two chars at this point
.readtokr
# Make sure the first one was an 'r'
	=$x :letterr_
	?!1x
	@jmp?.readtinv

	=$x :zero____
	- 0x
	= 10
.readtkrl
	@psh1
	@call:readchar
	@pop1
	@call:istoksep
	@jmp?.readtkrd
	=$x :newline_
	?=0x
	@jmp?.readtkrd

	=#x 000a
	* 1x
	=$x :zero____
	- 0x
	+ 10
	@jump.readtkrl

.readtkrd

	@psh1
	@call:rewind__
	@pop1
	=$0 :T_REG___
	@jump.ret_____

#***************************

.readtok$
	- 11
.readtk$l
	@psh1
	@call:readchar
	@pop1
	@call:istoksep
	@jmp?.readtk$d
	=$x :newline_
	?=0x
	@jmp?.readtk$d

	=#x 000a
	* 1x
	=$x :zero____
	- 0x
	+ 10
	@jump.readtk$l

.readtk$d

	@psh1
	@call:rewind__
	@pop1

	=$0 :T_IMM___
	@jump.ret_____

#***************************

# We've read two chars at this point (r1 and r0)
.readtoki
# Clear the token buffer
	@psh0
	@psh1
	=$0 .buffer__
	= 1a
	=#2 0020
	@call:memset__
	@pop1
	@pop0
	=$2 .buffer__
	[=21
	+ 2b
	[=20
	+ 2b
	- 33

# Read until we get a space, tab or newline
.readtkil
	@psh2
	@psh3
	@call:readchar
	@pop3
	@pop2
	@call:istoksep
	@jmp?.readtkid
	=$x :newline_
	?=0x
	@jmp?.readtkid

# If the instruction ends in a ?, this means it is only executed if flag == true
	=$x :question
	?=0x
	=?3b
	@jmp?.readtkip

# If the instruction ends in a ^, this means it is only executed if flag == false
	=$x :hat_____
	?=0x
	=?3c
	@jmp?.readtkip

# Store and continue
# TODO: We should probably check if this is alpha
# .. or use the new helper function
	[=20
	+ 2b
	@jump.readtkil

.readtkid
# Put the whitespace back
	@call:rewind__

.readtkip
# Search the instruction table for a match
	=$0 :instruct
	=$2 .buffer__
	=(22
	=$3 :lastinst
.readtkis
	=(10
	?=12
	@jmp?.readtkir
	+ 0e
	?=03
	@jmp?.readtkie
	@jump.readtkis

.readtkir
	= 10
# Return
	=$0 :T_INS___
	@jump.ret_____

.readtkie
	=$0 .inserr__
	@jump:error___

.inserr__
	Unknown instruction :__null__

#***************************

.readtokq
	=$2 .buffer__
.readtkql
	@psh2
	@call:readchar
	@pop2
	=$x :quote___
	?=0x
	@jmp?.readtkqd
	[=20
	+ 2b
	@jump.readtkql
.readtkqd
# Trailing null
	[=2a

	=$0 :T_STR___
	=$1 .buffer__
	@jump.ret_____

#***************************

.eol_____
	=$0 :T_EOL___
	@jump.ret_____

#***************************

.ret_____
# If not verbose, just return
	=$x :isverbos
	=[xx
	?=xa
	@ret?

# Write the token to stderr for debugging
	@psh0
	@psh1
	@psh2

	= 50
	* 5d
	=$x :tokens__
	+ 5x

	@psh0
	= 05
	@call:log_____
	@pop0

	=$x :T_EOL___
	?=0x
	=$x .logeol__
	=?zx

	=$x :T_INS___
	?=0x
	=$x .logins__
	=?zx

	=$x :T_REG___
	?=0x
	=$x .logreg__
	=?zx

	=$x :T_REF___
	?=0x
	=$x .logref__
	=?zx

	=$x :T_IMM___
	?=0x
	=$x .logimm__
	=?zx

	=$x :T_STR___
	?=0x
	=$x .logstr__
	=?zx

	@jump.logdone_

.log_br_l
	@psh0
	=$0 .s_br_l__
	@call:log_____
	@pop0
	@ret.
.log_br_r
	@psh0
	=$0 .s_br_r__
	@call:log_____
	@pop0
	@ret.
.s_br_l__
	(\00\00\00
.s_br_r__
	) \00\00

.logeol__
	=$0 .newline_
	@call:log_____
	@jump.logdone_

.logins__
	@call.log_br_l
	=$0 .buffer__
	+ 0d
	[=0a
	=$0 .buffer__
	@call:log_____
	@call.log_br_r
	@jump.logdone_

.logreg__
	@call.log_br_l
	= 01
	@call:encodreg
	=$x .buffer__
	[=x0
	+ xb
	[=xa
	=$0 .buffer__
	@call:log_____
	@call.log_br_r
	@jump.logdone_

.logref__
	@call.log_br_l
	= 01
	@call:log_____
	@call.log_br_r
	@jump.logdone_

.logimm__
	@call.log_br_l
	= 01
	@call:lognum__
	@call.log_br_r
	@jump.logdone_

.logstr__
	@call.log_br_l
	=$0 .buffer__
	@call:log_____
	@call.log_br_r
	@jump.logdone_

.logdone_
	@pop2
	@pop1
	@pop0
	@ret.

.newline_
	:newline_

# This is enough for 32-byte labels/identifiers/strings
.buffer__
	________
	________
	________
	________

.space___
	:space___

.readtinv
	=$0 .errinvch
	@jump:error___

.errinvch
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
	=$2 .buffer__
	[=2a
	= 3b
	S+1023  
	=[02
	@ret.
.buffer__
	????
#===========================================================================


#===========================================================================
# Args:
#   R0: Char
#===========================================================================
:writech_
	=$x .buffer__
	[=x0
	=$0 :out_hand
	=(00
	=$1 :SC_WRITE
	= 2x
	= 3b
	S+1023  
	@ret.
.buffer__
	____
#===========================================================================



#===========================================================================
# Args:
#   R0: 32-bit value
#===========================================================================
:write32_
	=$x .buffer__
	(=x0
	=$0 :out_hand
	=(00
	=$1 :SC_WRITE
	= 2x
	= 3d
	S+1023  
	@ret.
.buffer__
	____
#===========================================================================


#===========================================================================
# Args:
#   R0: 16-bit value
#===========================================================================
:write16_
	=$x .buffer__
	(=x0
	=$0 :out_hand
	=(00
	=$1 :SC_WRITE
	= 2x
	= 3c
	S+1023  
	@ret.
.buffer__
	____
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
#===========================================================================


#===========================================================================
# Does not return
#===========================================================================
:errtoken
	=$x .errtoken
	@jump:error___

.errtoken
	Invalid token encountered:__null__
#===========================================================================


# Syntax highlighters get confused by our unmatched brackets
# This is an unfortunate necessity
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})

:isverbos
	__

#===========================================================================
# Main
#===========================================================================
:main____
	= 0b
	@call:getargv_
	=$1 .verbose_
	@call:strcmp__
	=$x :isverbos
	[=xa
	@jmp^.notverb_
	[=xb
	=$0 .verbmsg_
	@call:log_____
.notverb_
# Open argv[1] as ro, store in in_hand_
	= 0b
	=$x :isverbos
	=[xx
	+ 0x
	@call:getargv_
	= 1a
	@call:open____
	=$x :in_hand_
	(=x0

# Open argv[2] as rw, store in out_hand_
	= 0c
	=$x :isverbos
	=[xx
	+ 0x
	@call:getargv_
	= 1b
	@call:open____
	=$x :out_hand
	(=x0

	@call:patchins
	@jump:mainloop

.verbose_
	-v:__null__
.verbmsg_
	Verbose mode\0a\00
#===========================================================================


#===========================================================================
# Main loop
#===========================================================================
:mainloop
# Read a token
	@call:readtok_

# EOF?
	=$x :T_EOF___
	?=0x
	@jmp?.eof_____

# EOL?
	=$x :T_EOL___
	?=0x
	@jmp?:mainloop

	=$x :T_REF___
	?=0x
	@jmp?.ref_____

	=$x :T_INS___
	?=0x
	@jmp?.ins_____

	=$x :T_DEF___
	?=0x
	@jmp?.def_____

	@jump:errtoken

.ref_____
# Make a copy of this label string
	= 01
	@psh2
	@call:mallocst
	@pop2

# Global?
	?=2b
	@jmp?.refgloba

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

.refgloba
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

.ins_____
# Extract the conditional execution flag
# TODO

# Perform a call to a mini-function that will jump to the next address
	+ 1d
	=(11
	@call.insdisp_
	@jump:mainloop

.insdisp_
# Note: does not return here!
	= z1

.def_____
# Definition name
	@call:readlbl_
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
	@jump:mainloop

.eof_____
	=$x :fixuptab
	=(0x

.dofixups
	?=0a
	@jmp?.done____
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
	@jump.dofixups

.done____
	=#0 0000
	@call:exit____
#===========================================================================

# Current global label
:mlglobal
	:__null__

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
	@jmp?.ref_____

	=$x :T_IMM___
	?=0x
	@jmp?.imm_____

	@jump:errtoken

.ref_____
# Create a fixup
	?=2b
	@jmp?.global__
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
	@jump.enc32___
.global__
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
	@jump.enc32___
.imm_____
	@psh1
	@jump.enc32___

.enc32___
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
	=$0 .x_eq____
	= 1d
	@call:writebuf
	@pop2
	@pop1
	@pop0

	@call:encrefim

	=$0 :x_______
	@ret.

.x_eq____
	=$x 
#===========================================================================


:i_stdbf1
	____
:i_stdbf2
	____

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
	=(xy+!y_= zx
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
	]})]})]})]})]})]})]})]})

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
	-!y_=!x_+ xz(=yx=$z 
:i_jump_s
	=$z 
#===========================================================================

# Simple lookup table for registers
:register
	0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz__

# Instruction table
:instruct
	mov\00
	:i_mov___

	add\00
	:i_add___

	sub\00
	:i_sub___

	mul\00
	:i_mul___

	div\00
	:i_div___

	or\00\00
	:i_or____

	and\00
	:i_and___

	xor\00
	:i_xor___

	push
	:i_push__

	pop\00
	:i_pop___

	ld\2eb
	:i_ldb___

	ld\2ew
	:i_ldw___

	ld\2ed
	:i_ldd___

	st\2eb
	:i_stb___

	st\2ew
	:i_stw___

	st\2ed
	:i_std___

	eq\00\00
	:i_eq____

	ne\00\00
	:i_ne____

	gt\00\00
	:i_gt____

	lt\00\00
	:i_lt____

	call
	:i_call__

	jump
	:i_jump__

	ret\00
	:i_ret___

	sys\00
	:i_sys___

	db\00\00
	:i_db____

	dw\00\00
	:i_dw____

	dd\00\00
	:i_dd____

	ds\00\00
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

