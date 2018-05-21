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
# @ret^: Return from proc if not flag
# @jump: Jump to address (@jump:label___)
# @jmp?: Jump to address if flag (@jmp?:label___)
# @jmp^: Jump to address if not flag (@jmp^:label___)
# @call: Call address (@call:label___)
# @pshN/@popN: Push/pop register N to the stack (supports 0-3)

# TODO:
#   - object file support
# Polish/performance
#   - Symbol table with local symbs should be "rolled back" at next global symbol for perf
#      - Can we do local fixups per global?
#   - Short immediate constants should use '=!x.' format
#   - readtok_ subroutines should be real functions
#   - macro for locals/args copy (ie: r0->r4, r1->r5, pushed/restored automatically)

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
=question 003f
=hat_____ 005e
=zero____ 0030
=amp_____ 0026
=comma___ 002c
=plus____ 002b
=minus___ 002d
=left[___ 005b
=right]__ 005d
=left{___ 007b
=left(___ 0028
=at______ 0040
=period__ 002e
=S_______ 0053
=n_______ 006e
=r_______ 0072
=x_______ 0078
=y_______ 0079
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
=squote__ 0027
=percent_ 0025
=bslash__ 005c
=fslash__ 002f

# Program counter
=R_pc____ 003d
# Stack pointer
=R_sp____ 003c
# Compiler temporary
=R_ctmp__ 003b
# Compiler temporary for %call
=R_ctmp2_ 003a

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
# Register indirect (data = reg #)
=T_RGI___ 0005
# EOL
=T_EOL___ 0006
# String
=T_STR___ 0007
# Define
=T_DEF___ 0008
# Include
=T_INC___ 0009
# String immediate
=T_SIM___ 000a

=INS_UNCO 0000
=INS_IF_T 0001
=INS_IF_F 0002

=OPEN_RO_ 0000
=OPEN_RW_ 0001

:tokens__
	EOF\00
	IMM\00
	REF\00
	INS\00
	REG\00
	RGI\00
	EOL\00
	STR\00
	DEF\00
	INC\00
	SIM\00

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
=SC_OPNAT 0008

=JUMPEND_ fefe

# Too large for a normal constant!
:AT_FDCWD
	\38\ff\ff\ff

:inclhand
	____

# Stack of input file handles, used for #include
:in_hands
	:__null__

# Global: Output file handle
:out_hand
	____


#===========================================================================
# Special jump table proc
# Preserves all registers except x
# Args:
#   Stack 0: Lookup
#   Stack 1: Table
#===========================================================================
:jumptabl
# Stash the return value in .ret_____
	@pop0
	=$x .ret_____
	(=x0
# Table address
	@pop0
	= x0
# Lookup value
	@pop0

# Preserve R0-R3
	@psh1
	@psh2
	@psh3

# R3 holds the table
	= 3x
# R2 holds the magic constant
	=$2 :JUMPEND_

.loop____
	=(13
	?=12
	@jmp?.done____
	?=10
	@jmp?.found___
	+ 3e
	@jump.loop____

.found___
	+ 3d
# Put the address in Rx
	=(x3
	@pop3
	@pop2
	@pop1
# Jump (not call)
	= zx

.done____
# Restore
	@pop3
	@pop2
	@pop1

# Manual jump
	=$x .ret_____
	=(xx
	= zx

.ret_____
	:__null__
#===========================================================================


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
	?=0a
	@ret?
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
# Register-friendly stderr logging.
# Args:
#   R0: Number
# Returns:
#   All registers: Unchanged
#===========================================================================
:lognumh_
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

# Start at the end of the buffer
	=$1 .buffer__
	=#x 000e
	+ 1x

.loop____
	= 20
# Get the lowest digit
	=#x 0010
	% 2x
# Get the ASCII version
	=$x .digits__
	+ 2x
	=[22
# Write it to the buffer
	[=12
	- 1b
	=#x 0010
# If we still have digits to write, continue
	/ 0x
	?>0a
	@jmp?.loop____

	= 01
	=$x :x_______
	[=0x
	- 0b
	=$x :zero____
	[=0x
	@call:log_____

	@pop2
	@pop1
	@pop0
	@ret.

.buffer__
	\00\00\00\00\00\00\00\00
	\00\00\00\00\00\00\00\00

.digits__
	0123456789abcdef

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
	=$x :args____
	* 0d
	+ 0x
	=(00
	@ret.
#===========================================================================


#===========================================================================
# Returns:
#   R0: Argument count (includes argv[0] which is the binary)
#===========================================================================
:getargc_
	=$1 :args____
	- 00
.loop____
	=(x1
	?=xa
	@ret?
	+ 0b
	+ 1d
	@jump.loop____
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
#   R2: Relative (0 = cwd, 1 = include)
# Returns:
#   R0: Handle
#===========================================================================
:open____
	@psh2
	@psh0
	@psh1

	@call:is_vrbos
	@jmp^.nolog___

	@psh0
	=$0 .opening_
	@call:log_____
	@pop0
	@call:log_____
	=$0 .as______
	@call:log_____

	@pop1
	@psh1
	* 1d
	=$x .mode____
	+ 1x
	=(01
	@call:log_____

.nolog___
	@pop1
	@pop0
	@pop2
	?=2b
	@jmp?.relative
	=$4 :AT_FDCWD
	=(44
	@jump.doopen__
.relative
	=$4 :inclhand
	=(44
.doopen__
	=$2 :SC_OPNAT
	=$3 :O_RDONLY
	=$x :OPEN_RO_
	?=1x
	@jmp?.readonly
	=$3 :O_RDWR__
	=$x :O_TRUNC_
	| 3x
	=$x :O_CREAT_
	| 3x
.readonly
	S+2403  
	+ 2b
	?!2a
	@jmp?.success_

	@call:log_____
	=$0 .errfail_
	@jump:error___

.success_
	= 02
	- 0b
	@ret.

.opening_
	Opening '\00
.as______
	' as \00
.s_ro____
	read-only\0a\00
.s_rw____
	read/write\0a\00
.mode____
	.s_ro____
	.s_rw____
.errfail_
	\3a Failed to open file\00
#===========================================================================


#===========================================================================
# Steps back in the input file by one char
# No args/return
#===========================================================================
:rewind__
	@call:getinhnd
	=$3 :SC_SEEK_
	- 11
	- 1b
	=$2 :SEEK_CUR
	S+3012  
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
	@call:log_____
	=$0 .errnotfo
	@jump:error___

.errnotfo
	\3a define not found\00
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

# If we're in a global, just return
	=$x :inglobal
	=[xx
	?=xb
	@ret?

	=$x :lastdef_
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
	@call:log_____
	=$0 .errnotfo
	@jump:error___

.errnotfo
	\3a symbol not found\00
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
# Args:
#   R0: Immediate string
#   R1: Fixup address
#===========================================================================
:createsi
	@psh0
	@psh1
# Allocate a record
	=#0 0010
	@call:malloc__
# Read the current record
	=$x :defsttab
	=(xx
# Write everything to the struct
	= 10
	@pop2
	(=12
	+ 1d
	@pop2
	(=12
	+ 1d
	(=1x
# Write the struct as the latest
	=$x :defsttab
	(=x0
	@ret.
#===========================================================================


#===========================================================================
# Args/returns: none
#===========================================================================
:newfile_
	=$x :inglobal
	[=xa
	=$x :mlglobal
	(=xa
	=$x :deftab__
	(=xa
	=$x :lastdef_
	(=xa
	@ret.
#===========================================================================


#===========================================================================
# Args/returns: none
#===========================================================================
:newglobl
# Roll the current definition back to the last global one
	=$x :lastdef_
	=(0x
	=$x :deftab__
	(=x0

	=$x :inglobal
	[=xb

	=$x :curlocal
	=#0 0008
	[=x0
	=$x :curarg__
	- 00
	[=x0
	@ret.
#===========================================================================

:curlocal
	\00

:curarg__
	\00

:lastdef_
	:__null__

:inglobal
	\00

#===========================================================================
# Returns
#   The next register index to use
#===========================================================================
:nextlocl
	=$x :curlocal
	=[0x
	= 10
	+ 1b
	[=x1
	@ret.
#===========================================================================


#===========================================================================
# Returns
#   The next argument register index
#===========================================================================
:nextarg_
	=$x :curarg__
	=[0x
	= 10
	+ 1b
	[=x1
	@ret.
#===========================================================================


#===========================================================================
# Returns:
#   R0: Pointer to label string (not malloc'd)
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


# Syntax highlighters get confused by our unmatched brackets
# This is an unfortunate necessity
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})

#===========================================================================
# Returns:
#   R0: Pointer to string (not malloc'd)
#===========================================================================
:readstr_
# Eat whitespace
	@call:rdcskwsp
	=$x :quote___
	?!0x
	=$x .errinvch
	=?0x
	@jmp?:error___

	=$2 .buffer__
.loop____
	@psh2
	@call:readchar
	@pop2
	=$x :quote___
	?=0x
	@jmp?.done____
	=$x :bslash__
	?=0x
	@jmp?.escape__
	[=20
	+ 2b
	@jump.loop____
.escape__
	@psh2
	@call:readchar
	@pop2
	=#1 ffff

	=$x :n_______
	?=0x
	=$x :newline_
	=?1x

	=$x :zero____
	?=0x
	=$x :__null__
	=?1x

	=#x ffff
	?=1x
	=$x .errescap
	=?0x
	@jmp?:error___

	[=21
	+ 2b
	@jump.loop____
.done____
# Trailing null
	[=2a

	=$0 .buffer__
	@ret.

# This is enough for 32-byte labels/identifiers/strings
.buffer__
	________
	________
	________
	________

.errescap
	Invalid escape\00

.errinvch
	Invalid character (expected double quote)\00
#===========================================================================


#===========================================================================
# Returns:
#   R0: The number
#===========================================================================
:readimm_
# Number prefix:
#   0x: Base 16
#   0: Base 8 (octal, unsupported)
#   $: Base 16
#   1-9: Base 10
# Reset the negative flag
	=$x .isneg___
	[=xa

	@call:rdcskwsp

	@psh0
	=$0 .jumptabl
	@psh0
	@call:jumptabl

	@call:isdigit_
	@jmp?.readdec_

	=$0 .errinvch
	@call:error___

.jumptabl
	:minus___
	.negative
	:dollar__
	.immhex__
	:zero____
	.immzero_
	:JUMPEND_

.readdec_
	@call:isdigit_
	@jmp?.immdec__

	=$0 .errinvch
	@call:error___

.negative
# Set the negative flag
	=$x .isneg___
	[=xb
	@call:readchar
	@jump.readdec_

.immzero_
# If the number started with zero, assume hex (unless it's a token separator)
	@call:readchar
	@call:istkspel
	=?1a
	@jmp?.immdone_

	=$x :x_______
	?=0x
	@jmp?.immhex__

	=$0 .errinvch
	@call:error___

.immdec__
# Populate with the first digit we read
	=$x :zero____
	- 0x
	= 10

.immdloop
# Base 10 loop
	@psh1
	@call:readchar
	@pop1
	@call:istkspel
	@jmp?.immdone_
	=$x :newline_
	?=0x
	@jmp?.immdone_

	=#x 000a
	* 1x
	=$x :zero____
	- 0x
	+ 10
	@jump.immdloop

.immhex__
	- 11

.immhloop
# Base 16 loop
	@psh1
	@call:readchar
	@pop1
	@call:istkspel
	@jmp?.immdone_
	=$x :newline_
	?=0x
	@jmp?.immdone_

# Use self-modifying code to read this digit
	=$x .immhdigi
	[=x0
	=#0 000
.immhdigi
	_

	=#x 0010
	* 1x
	+ 10
	@jump.immhloop

.immdone_
# Common exit point for base 10/16
	@psh1
	@call:rewind__
	@pop0

	=$x .isneg___
	=[xx
	?=xa
	@ret?

	- xx
	- x0
	= 0x
	@ret.

.isneg___
	\00

.errinvch
	Invalid immediate character\00
#===========================================================================


# Syntax highlighters get confused by our unmatched brackets
# This is an unfortunate necessity
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})

#===========================================================================
# Returns:
#   R0: Token type
#   R1: Token data
#===========================================================================
:readtok_
# Whitespace is ignored
	@call:rdcskwsp

# Default jump table
	@psh0
	=$0 .jumptabl
	@psh0
	@call:jumptabl

	@call:isdigit_
	@jmp?.imm_____

# Make sure it's alpha-numeric
	@call:isalnum_
	@jmp^.readtinv

# Otherwise if it's alnum, it's an instruction
	@call:isalnum_
	@jmp?.ins_____

# Anything else is invalid
	@jump.readtinv

#***************************

.jumptabl
# Return zero at EOF
	:__null__
	.ret_____
	:newline_
	.eol_____
	:hash____
	.cmt_____
	:fslash__
	.ccmt____
	:period__
	.label___
	:colon___
	.label___
	:at______
	.label___
	:amp_____
	.strimm__
	:dollar__
	.imm_____
	:zero____
	.imm_____
	:minus___
	.imm_____
	:quote___
	.string__
	:squote__
	.charimm_
	:percent_
	.insperc_
	:left[___
	.regind__
	:r_______
	.regmaybe
	:JUMPEND_

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
	@psh0
	=$1 .localsiz
	@call:strcmp__
	@pop0
	@jmp^.notlocal

# Special macro: @__LOCALS_SIZE__
	=$0 :T_IMM___
	=$1 :curlocal
	=[11
	- 1e
	+ 1b
	* 1d
	@jump.ret_____

.notlocal
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

.strimm__
	@call:readstr_
	@call:mallocst
# Immediate strings create temp symbols
	= 10
	=$0 :T_SIM___
	@jump.ret_____

#***************************

.ccmt____
	@call:readchar
	=$x :fslash__
	?=0x
	@jmp?.ccmtloop

	=$0 .errinvch
	@jump:error___

.ccmtloop
	@call:readchar
	=$x :newline_
	?=0x
	@jmp?.cmtdone_
	@jump.ccmtloop

#***************************

.cmt_____
	- 22
.cmtloop_
# Eat chars until a newline
	@psh2
	@call:readchar
	@pop2
	=$x :newline_
	?=0x
	@jmp?.cmtdone_
	=$1 .buffer__
	+ 12
	+ 2b
	[=10
	=#3 0007
	?=23
	@jmp?.cmtdef__
	=#3 0008
	?=23
	@jmp?.cmtinc__
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
	=$0 .cmtdstrd
	@psh2
	@call:strcmp__
	@pop2
	@jmp^.cmtloop_

# It's a #define token, so return that
	=$0 :T_DEF___
	@jump.ret_____

# We matched #include, so need to process this in a special way
.cmtinc__
# NUL terminate, then compare against "include "
	+ 1b
	[=1a
	=$1 .buffer__
	=$0 .cmtdstri
	@call:strcmp__
	@jmp^.cmtfastl

# It's an #include token, so return that
	=$0 :T_INC___
	@jump.ret_____

# Return EOL for a comment
.cmtdone_
	=$0 :T_EOL___
	@jump.ret_____

.cmtdstrd
	define :__null__

.cmtdstri
	include :__null__

#***************************

.regind__
	@call:readregr
	@psh0
	@call:readchar
	=$x :right]__
	?!0x
	@jmp?.errinvch

	=$0 :T_RGI___
	@pop1
	@jump.ret_____

#***************************

.regmaybe
	@call:readchar
	@call:isdigit_
	@jmp?.regyes__

	@call:rewind__
	@jump.ins_____

.regyes__
# Rewind the digit and the "r"
	@call:rewind__
	@call:rewind__

.reg_____
	@call:readregr
	= 10
	=$0 :T_REG___
	@jump.ret_____

#***************************

.imm_____
	@call:rewind__
	@call:readimm_
	= 10
	=$0 :T_IMM___
	@jump.ret_____

#***************************

.charimm_
	@call:readchar
	@psh0
	@call:readchar
	@pop1
	=$0 :T_IMM___
	@jump.ret_____

#***************************

.insperc_
	@jump.ins_____

.ins_____
	@call:rewind__
# Clear the token buffer
	=$0 .buffer__
	= 1a
	=#2 0020
	@call:memset__
	=$2 .buffer__

# Read until we get a space, tab or newline
.insloop_
	@psh2
	@call:readchar
	@pop2
	@call:istkspel
	@jmp?.insdone_

# If the instruction ends in a ?, this means it is only executed if flag == true
	=$x :question
	?=0x
	=$x :INS_IF_T
	=?3x
	@jmp?.inssrch_

# If the instruction ends in a ^, this means it is only executed if flag == false
	=$x :hat_____
	?=0x
	=$x :INS_IF_F
	=?3x
	@jmp?.inssrch_

# Store and continue
# TODO: We should probably check if this is alpha
# .. or use the new helper function
	[=20
	+ 2b
	@jump.insloop_

.insdone_
# Put the whitespace back
	@call:rewind__
	=$x :INS_UNCO
	= 3x

.inssrch_
# Search the instruction table for a match
	=$0 :instruct
	=$2 .buffer__
	=(22
	=$4 :lastinst
.inssrchl
	=(10
	?=12
	@jmp?.insfound
	+ 0e
	+ 0d
	?=04
	@jmp?.inserror
	@jump.inssrchl

.insfound
	= 10
	= 23
# Return
	=$0 :T_INS___
	@jump.ret_____

.inserror
	=$0 .buffer__
	@call:log_____
	=$0 .inserr__
	@jump:error___

.inserr__
	\2e Unknown instruction\00

#***************************

.string__
	@call:rewind__
	@call:readstr_
	@call:mallocst
	= 10
	=$0 :T_STR___
	@jump.ret_____

#***************************

.eol_____
	=$0 :T_EOL___
	@jump.ret_____

#***************************

.ret_____
# If not verbose, just return
	@call:is_vrbos
	@ret^

	@jump:logtoken

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

.localsiz
	__LOCALS_SIZE__\00

.errinvch
	Invalid character\00

#===========================================================================


#===========================================================================
# Logs the return value of readtok_, preserving all registers
#===========================================================================
:logtoken
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

	@psh0
	=$0 .jumptabl
	@psh0
	@call:jumptabl

	@jump.logdone_

.jumptabl
	:T_EOL___
	.logeol__
	:T_INS___
	.logins__
	:T_REG___
	.logreg__
	:T_REF___
	.logref__
	:T_IMM___
	.logimm__
	:T_STR___
	.logstr__
	:T_EOF___
	.logeof__
	:T_DEF___
	.logspace
	:T_INC___
	.logspace
	:T_SIM___
	.logstimm
	:JUMPEND_

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
.s_hat___
	^\00\00\00
.s_ques__
	?\00\00\00
.logeol__
.logeof__
	=$0 .newline_
	@call:log_____
	@jump.logdone_

.logspace
	=$0 .space___
	@call:log_____
	@jump.logdone_

.logins__
	@call.log_br_l
	= 01
	@call:log_____
	=$x :INS_UNCO
	?=2x
	@jmp?.logins_u
	=$x :INS_IF_T
	?=2x
	@jmp?.logins_t
	=$x :INS_IF_F
	?=2x
	@jmp?.logins_f
.logins_t
	=$0 .s_ques__
	@call:log_____
	@jump.logins_u
.logins_f
	=$0 .s_hat___
	@call:log_____
	@jump.logins_u
.logins_u
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
	= 01
	@call:log_____
	@call.log_br_r
	@jump.logdone_

.logstimm
	@call.log_br_l
	= 01
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

.space___
	:space___

.buffer__
	____
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
	@jmp?:retfalse

	=#x 003a
	?<0x
	@jmp?:rettrue_

	@jump:retfalse
#===========================================================================


#===========================================================================
# Args:
#   R0: Char
# Returns:
#   Flag in appropriate state
#   R0: Char
#===========================================================================
:isdigit_
	=#x 0030
	?<0x
	@jmp?:retfalse

	=#x 003a
	?<0x
	@jmp?:rettrue_

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
	@jmp?:retfalse

	=#x 003a
	?<0x
	@jmp?:rettrue_

	=#x 0041
	?<0x
	@jmp?:retfalse

	=#x 005b
	?<0x
	@jmp?:rettrue_

	=#x 0061
	?<0x
	@jmp?:retfalse

	=#x 007b
	?<0x
	@jmp?:rettrue_

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
# Token seperator or EOL/EOF
# Args:
#   R0: Char
# Returns:
#   Flag in appropriate state
#   R0: Char
#===========================================================================
:istkspel
	=$x :space___
	?=0x
	@jmp?:rettrue_

	=$x :tab_____
	?=0x
	@jmp?:rettrue_

	=$x :comma___
	?=0x
	@jmp?:rettrue_

	=$x :newline_
	?=0x
	@jmp?:rettrue_

	?=0a
	@jmp?:rettrue_

	@jump:retfalse
#===========================================================================


#===========================================================================
# Args:
#   R0: Filename
#   R2: Include file = 1
#===========================================================================
:openinpt
	@psh2
	=$1 :OPEN_RO_
	@call:open____
	@psh0
	=#0 000c
	@call:malloc__
	@pop1
# Store the file handle
	(=01
# Write this new record to the open stack
	=$x :in_hands
	=(1x
	(=x0
	+ 0d
# Store the input mode
	@pop2
	(=02
	+ 0d
# Store the next record
	(=01

	@ret.
#===========================================================================


#===========================================================================
# Args:
#   None
#===========================================================================
:popinput
# Load the current input record
	=$x :in_hands
	=(xx
# Determine which mode this record was in
	+ xd
	=(0x
	?=0b
	@jmp?.include_

# This is a new global file, so reset all global stuff
	@call:newfile_

# Reload the current input record
	=$x :in_hands
	=(xx
	+ xd

.include_
	+ xd
# Pop the previous record
	=(xx
	=$0 :in_hands
	(=0x
	@ret.
#===========================================================================


#===========================================================================
# Returns:
#   R0: Current input handle
#===========================================================================
:getinhnd
	=$x :in_hands
	=(0x
	?=0a
	@ret?
	=(00
	@ret.
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

# Syntax highlighters get confused by our unmatched brackets
# This is an unfortunate necessity
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})


#===========================================================================
# Returns:
#   R0: Char (zero if EOF)
#===========================================================================
:readchar
	@call:getinhnd
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
# Reads a char, skipping whitespace.
# Returns:
#   R0: Char (zero if EOF)
#===========================================================================
:rdcskwsp
	@call:readchar
	@call:istoksep
	@jmp?:rdcskwsp
	@ret.
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
	=$0 .errtoken
	@jump:error___

.errtoken
	Invalid token encountered:__null__
#===========================================================================


:_isvrbfl
	\00
:_iscmpfl
	\00
:_islnkfl
	\00

#===========================================================================
# Args:
#   None
# Returns:
#   Flag set to true if verbose
#===========================================================================
:is_vrbos
	=$x :_isvrbfl
	=[xx
	?=xb
	@ret.

#===========================================================================
# Main
#===========================================================================
:main____
# Default include dir is working directory
	=$x :AT_FDCWD
	=(xx
	=$0 :inclhand
	(=0x

# Get args size
	=$1 :SC_GTARG
	=$2 :args____
	- 33
	S+123   

	= 31
	=$1 :SC_GTARG
	=$2 :args____
	S+123   

# Point the heap past the end of args
	=$x :heap____
	=(0x
	+ 01
	(=x0

	= 0b
.argsloop
# Extract args
	@psh0
	@call:getargv_
	=$1 .verbose_
	@call:strcmp__
	@pop0
	@jmp?.isverbos

	@psh0
	@call:getargv_
	=$1 .compile_
	@call:strcmp__
	@pop0
	@jmp?.iscompil

	@psh0
	@call:getargv_
	=$1 .link____
	@call:strcmp__
	@pop0
	@jmp?.islink__

	@psh0
	@call:getargv_
	=$1 .include_
	@call:strcmp__
	@pop0
	@jmp?.isinclud

	@jump.argsdone

.isverbos
	= 1b
	=$x :_isvrbfl
	[=x1
	+ 0b
	@psh0
	=$0 .verbmsg_
	@call:log_____
	@pop0
	@jump.argsloop

.iscompil
	= 1b
	=$x :_iscmpfl
	[=x1
	+ 0b
	@jump.argsloop

.islink__
	= 1b
	=$x :_islnkfl
	[=x1
	+ 0b
	@jump.argsloop

.isinclud
	+ 0b
	@psh0
	@call:getargv_
	=$1 :SC_OPEN_
	=$2 :O_RDONLY
	S+102   
	=$x :inclhand
	(=x1
	@pop0
	+ 0b
	@jump.argsloop

.argsdone
# Open all files but the last one as input
	= 10
.openloop
	@psh1
	@call:getargc_
	@pop1
	- 0b

	?=10
	= 01
	@jmp?.openout_

# Open argv[1] as input
	+ 1b
	@psh1
	@call:getargv_
	- 22
	@call:openinpt
	@pop1

	@jump.openloop

.openout_
# Open last argument as rw, store in out_hand_
	@call:getargv_
	=$1 :OPEN_RW_
	= 2a
	@call:open____
	=$x :out_hand
	(=x0

# If we aren't linking, just write directly to output
	=$x :_islnkfl
	=[xx
	?=xa
	@jmp?:mainloop

# Write a jump to the _start symbol
	=$0 .startjmp
	=#1 000c
	@call:writebuf

# Create a fixup
	=$0 .start_s_
	- 11
	=#2 0004
	@call:createfx

	@jump:mainloop

.start_s_
	_start\00
.startjmp
	=$x ????= zx

.verbose_
	-v\00
.verbmsg_
	Verbose mode\0a\00
.compile_
	-c\00
.link____
	-l\00
.include_
	-I\00
#===========================================================================


#===========================================================================
# Main loop
#===========================================================================
:mainloop
# Read a token
	@call:readtok_

	@psh0
	=$0 .jumptabl
	@psh0
	@call:jumptabl

	@jump:errtoken

.jumptabl
	:T_EOF___
	.eof_____
	:T_EOL___
	:mainloop
	:T_REF___
	.ref_____
	:T_INS___
	.ins_____
	:T_DEF___
	.def_____
	:T_INC___
	.inc_____
	:JUMPEND_

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
	@psh0
	@call:newglobl
	@pop0
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
	=$x :INS_UNCO
	?=2x
	@jmp?.insuncon

	=$x :INS_IF_T
	?=2x
	@jmp?.ins_if_t

	=$x :INS_IF_F
	?=2x
	@jmp?.ins_if_f

.ins_if_t
	=$0 :i_jmp_nt
	@jump.ins_cond

.ins_if_f
	=$0 :i_jmp_if
	@jump.ins_cond

.ins_cond
	@psh1
# Write the skip instructions
	=#1 000c
	@call:writebuf
	@call:outtell_
	- 0e
	@pop1
	@psh0
# Dispatch to the instruction
	@call.insdisp_
	@call:outtell_
	= 10
	@pop0
	@psh1
# Compute the relative jump
	= 21
	- 10
	- 1e
	@psh1
# Go back to the relative jump load
	@call:outseek_
	@pop0
	@call:write32_
	@pop0
	@call:outseek_
	@jump:mainloop

.insuncon
# Perform a call to a mini-function that will jump to the next address
	@call.insdisp_
	@jump:mainloop

.insdisp_
# Note: does not return here!
	+ 1e
	=(11
	= z1

.def_____
# Definition name
	@call:readref_
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

.inc_____
	@call:readstr_
# Filename in r0
	@psh0
	@call:readeol_
	@pop0
	= 2b
	@call:openinpt
	@jump:mainloop

.eof_____
	@call:popinput
	@call:getinhnd
	?=0a
	@jmp^:mainloop

# Write the deferred strings
	=$4 :defsttab
.fixupsi_
	=(44
	?=4a
	@jmp?.donesi__
	@call:outtell_
	= 50
# The fixup address
	=(64
	+ 4d
# The string pointer
	=(74
	+ 4d
	= 07
	@call:strlen__
	= 10
	+ 1b
	= 07
# Write the string at the end (NUL terminated)
	@call:writebuf
# Get our new location
	@call:outtell_
	= 70
# Seek to the old location
	= 06
	@call:outseek_
# Write the fixup
	= 05
	@call:write32_
# Seek back to the end
	= 07
	@call:outseek_
	@jump.fixupsi_

.donesi__

# Create an __END__ symbol with the length of the output
	@call:outtell_
	= 20
	=$0 .end_s___
	- 11
	@call:createsm

# Do the fixups
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

	@call:is_vrbos
	@jmp^.nolog1__
	@psh0
	=$0 .glo_s___
	@call:log_____
	@pop0
	@psh0
	@psh1
	@call:log_____
	=$0 .loc_s___
	@call:log_____
	= 01
	@call:log_____
	=$0 .space___
	@call:log_____
	@pop1
	@pop0
.nolog1__
	@call:lookupsm

	@call:is_vrbos
	@jmp^.nolog2__
	@psh0
	@call:lognumh_
	=$0 .newline_
	@call:log_____
	@pop0
.nolog2__

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

.glo_s___
	g\3a\00
.loc_s___
	 l\3a\00
.space___
	 \40 \00
.newline_
	\0a\00

.done____
	=#0 0000
	@call:exit____
.end_s___
	__END__\00
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
	=$x .error___
	=?0x
	@jmp?:error___
	@ret.

.error___
	Expected EOL:__null__
#===========================================================================


#===========================================================================
# Args:
#   None
#===========================================================================
:readref_
# Eat whitespace
	@call:rdcskwsp
	@call:rewind__
	@call:readlbl_
	= 10
	=$0 :T_REF___
	= 2a
	@call:is_vrbos
	@jmp^.nolog___
	@call:logtoken
.nolog___
	= 01
	@ret.
#===========================================================================


#===========================================================================
# Returns:
#   R0: Register index
#===========================================================================
:readregr
# First char must be "r"
	@call:rdcskwsp
	=$x :r_______
	?=0x
	=$0 .error___
	@jmp^:error___

# Second char must be a digit
	@call:readchar
	@call:isdigit_
	=$x .error___
	=^0x
	@jmp^:error___

	=$x :zero____
	- 0x
	= 10

.loop____
	@psh1
	@call:readchar
	@pop1
	@call:isdigit_
	@jmp^.done____

	=#x 000a
	* 1x
	=$x :zero____
	- 0x

	+ 10
	@jump.loop____

.done____
# If the register is > 64, that's an error
	=#0 003f
	?>10
	=$x .invalid_
	=?0x
	@jmp?:error___

	@psh1
	@call:rewind__
	@pop0
	@ret.

.error___
	Expected register (rXX)\00

.invalid_
	Invalid register (r0-r63 expected)\00
#===========================================================================


#===========================================================================
# Returns:
#   R0: Token type (T_REG___)
#   R1: Register index
#===========================================================================
:readreg_
	@call:readtok_

	=$x :T_REG___
	?!0x
	=$x .error___
	=?0x
	@jmp?:error___
	@ret.

.error___
	Expected register\00
#===========================================================================


#===========================================================================
# Returns:
#   R0: Token type (T_REG___ or T_EOL___)
#   R1: Register index
#===========================================================================
:readropt
	@call:readtok_
	=$x :T_EOL___
	?=0x
	@ret?

	=$x :T_REG___
	?!0x
	=$x .error___
	=?0x
	@jmp?:error___
	@ret.

.error___
	Expected register or EOL\00
#===========================================================================


# Syntax highlighters get confused by our unmatched brackets
# This is an unfortunate necessity
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})


#===========================================================================
# Args:
#   R1: The register index
# Returns:
#   Register encoding in r0
#===========================================================================
:encodreg
# Move the reg# to r0
	=$0 .register
	+ 01
# Load the character representing the register
	=[00
	@ret.

# Simple lookup table for registers
.register
	0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz__
#===========================================================================


#===========================================================================
# Writes four bytes with either the immediate or a reference that will be
# fixed up later on. The argument to this function is a token.
#
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

	=$x :T_SIM___
	?=0x
	@jmp?.strimm__

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

.strimm__
	@psh1
	@call:outtell_
	= 10
	@pop0
	@call:createsi
# Use a fake address for now
	=#0 1234
	@psh0
	@jump.enc32___

.enc32___
	@pop0
	@call:write32_
	@ret.
#===========================================================================


#===========================================================================
# Writes an assignment from a register, immediate or reference token to
# another register by index.
#
# Args:
#  R0: Token type
#  R1: From
#  R2: (unused)
#  R3: To
#===========================================================================
:encasgnr
	=$x :T_REG___
	?=x0
	@jmp?.reg_____

# Reference or immediate (we don't check this as encrefim will)
	@psh0
	@psh1
	@psh2
	= 13
	@call:encodreg
	=$x .to_i____
	[=x0
	=$0 .buffer_i
	= 1d
	@call:writebuf
	@pop2
	@pop1
	@pop0
	@call:encrefim
	@ret.

.buffer_i
	=$
.to_i____
	?\20

.reg_____
	@call:encodreg
	=$2 .from_r__
	[=20
	= 13
	@call:encodreg
	=$2 .to_r____
	[=20
	=$0 .buffer_r
	= 1d
	@call:writebuf
	@ret.

.buffer_r
	=\20
.to_r____
	?
.from_r__
	?
#===========================================================================


#===========================================================================
# Writes a push from a register, immediate or reference token to
# another register by index.
#
# Args:
#  R0: Token type
#  R1: From
#  R2: (unused)
#===========================================================================
:encpush_
	=$x :T_REG___
	?=0x
	@jmp?.reg_____

# Assign to ctmp, then push that
	=$3 :R_ctmp__
	@call:encasgnr

	=$0 :T_REG___
	=$1 :R_ctmp__

.reg_____
	@call:encodreg
	=$x .from____
	[=x0
	=$0 .buffer__
	= 1e
	@call:writebuf
	@ret.

.buffer__
	-!y\04(=y
.from____
	?
#===========================================================================


#===========================================================================
# Writes a pop to a register by index.
#
# Args:
#  R0: Token type
#  R1: From
#  R2: (unused)
#===========================================================================
:encpop__
	=$x :T_REG___
	?=0x
	@jmp?.reg_____

	@call:errtoken

.reg_____
	@call:encodreg
	=$x .to______
	[=x0
	=$0 .buffer__
	= 1e
	@call:writebuf
	@ret.

.buffer__
	=(
.to______
	?y+!y\04
#===========================================================================


#===========================================================================
# Returns:
#   R0: T_REG___ or T_EOL___
#   R1: Register index
#===========================================================================
:readvalo
	@call:readtok_
	=$x :T_EOL___
	?=0x
	@ret?

	=$x :T_REG___
	?=0x
	@ret?

# If it's not a register, assign it to x
	=$3 :R_ctmp__
	@call:encasgnr
	=$0 :T_REG___
	=$1 :R_ctmp__
	@ret.
#===========================================================================


#===========================================================================
# Returns:
#   R0: Register encoding for value
#===========================================================================
:readval_
	@call:readvalo
	=$x :T_REG___
	?!0x
	@jmp?:errtoken

	@call:encodreg

	@ret.
#===========================================================================

# Syntax highlighters get confused by our unmatched brackets
# This is an unfortunate necessity
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})


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
	@call:encodreg
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
	@call:encodreg
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


:i_call_s
	-!y\04=!x\0c+ xz(=yx=$z 
:i_jump_s
	=$z 
:i_ret__s
	=(xy+!y\04= zx
:i_jmp_if
	=$x ????+?zx
:i_jmp_nt
	=$x ????+^zx

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
	@call:readvalo
	=$x :T_EOL___
	?=0x
	@ret?
	@call:encpush_
	@jump:i_push__
:i_pop___
	@call:i_poprec
	@ret.
:i_poprec
	@call:readropt
	=$x :T_EOL___
	?=0x
	@ret?
	@psh0
	@psh1
	@call:i_poprec
	@pop1
	@pop0
	@call:encpop__
	@ret.
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
	=$3 :R_pc____
	@call:encasgnr
	@ret.
:i_ret___
	@call:readeol_
	=$0 :i_ret__s
	=#1 000c
	@call:writebuf
	@ret.
:i_sys___
# Fill the syscall buffer with spaces
	=$0 .sys_____
	=$1 :space___
	=#2 0008
	@call:memset__
# Set the first char to S
	=$0 .sys_____
	=$1 :S_______
	[=01
# Now pointed at the first reg spot
	+ 0c
# First argument is allowed to be a value (makes calls where return value is ignored simpler)
	@psh0
	@call:readval_
	= 10
	@pop0
	[=01
	+ 0b
# Now read regs until we're done
.loop____
	@psh0
	@call:readropt
	=$x :T_EOL___
	?=0x
	@jmp?.write___
	@call:encodreg
	= 10
	@pop0
	[=01
	+ 0b
	=$x .sys_____
	= 10
	- 1x
	=#x 0009
	?=1x
	@jmp^.loop____
	=$0 .toomany_
	@call:error___
.write___
	@pop0
	=$x .sys_____
	= 10
	- 1x
	=#x 0005
	?<1x
	@jmp?.short___
	=$1 .sys_____
	+ 1b
	=$x :plus____
	[=1x
	= 1e
	@jump.writeit_
.short___
	= 1d
.writeit_
	=$0 .sys_____
	@call:writebuf
	@ret.
.sys_____
	????????
.toomany_
	Too many registers for sys (maximum six)\00
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
	=#1 0100
	?<01
	@jmp?.ok______
	- xx
	- x1
	- xb
	?>0x
	@jmp?.ok______
	=$0 .toobig_s
	@call:error___
.ok______
	@call:writech_
	@jump:i_db____
.toobig_s
	db value is too large\00
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
	=#1 ffff
	+ 1b
	?<01
	@jmp?.ok______
	- xx
	- x1
	- xb
	?>0x
	@jmp?.ok______
	=$0 .toobig_s
	@call:error___
.ok______
	@call:write16_
	@jump:i_dw____
.toobig_s
	dw value is too large\00
:i_dd____
	@call:readtok_
	=$x :T_EOL___
	?=0x
	@ret?
	@call:encrefim
	@jump:i_dd____
:i_ds____
	@call:i_db____
# Trailing NUL
	- 00
	@call:writech_
	@ret.
:i_marg__
	@call:nextlocl
	@psh0
	@call:readref_
	@call:mallocst
	@pop2
	@psh2
	=$1 :T_REG___
	@psh1
	@call:createdf

# Push the old value
	@pop0
	@pop1
	@psh1
	@psh0
	@call:encpush_
# Assign to next arg
	@call:nextarg_
	= 10
	@pop0
	@pop3
	@call:encasgnr

	@call:readeol_
	@ret.
:i_mret__
# Pop args/locals off before we return
	@call:nextlocl
.loop____
	?=0e
	@jmp?.done____
	- 0b
	@psh0
	= 10
	=$0 :T_REG___
	@call:encpop__
	@pop0
	@jump.loop____

.done____
# Regular return
	@call:readeol_
	=$0 :i_ret__s
	=#1 000c
	@call:writebuf
	@ret.
:i_mlocal
	@call:nextlocl
	@psh0
	@call:readref_
	@call:mallocst
	@pop2
	@psh2
	=$1 :T_REG___
	@psh1
	@call:createdf

# Push the old value
	@pop0
	@pop1
	@call:encpush_

	@call:readeol_
	@ret.
:i_mcall_
# Call target, must be immediate or reference, assigned to ctmp2
	@call:readtok_
	=$3 :R_ctmp2_
	@call:encasgnr

# Current output register
	- 33
.loop____
	@psh3
	@call:readtok_
	@pop3
	=$x :T_EOL___
	?=0x
	@jmp?.write___
	@psh3
	@call:encasgnr
	@pop3
	+ 3b
	@jump.loop____

.write___
	=$0 .call_s__
	=#1 0014
	@call:writebuf
	@ret.
.call_s__
	-!y\04=!x\08+ xz(=yx= zw

# Syntax highlighters get confused by our unmatched brackets
# This is an unfortunate necessity
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})
	]})]})]})]})]})]})]})]})

# Instruction table
:instruct
	mov\00:__null__
	:i_mov___

	add\00:__null__
	:i_add___

	sub\00:__null__
	:i_sub___

	mul\00:__null__
	:i_mul___

	div\00:__null__
	:i_div___

	or\00\00:__null__
	:i_or____

	and\00:__null__
	:i_and___

	xor\00:__null__
	:i_xor___

	push:__null__
	:i_push__

	pop\00:__null__
	:i_pop___

	ld\2eb:__null__
	:i_ldb___

	ld\2ew:__null__
	:i_ldw___

	ld\2ed:__null__
	:i_ldd___

	st\2eb:__null__
	:i_stb___

	st\2ew:__null__
	:i_stw___

	st\2ed:__null__
	:i_std___

	eq\00\00:__null__
	:i_eq____

	ne\00\00:__null__
	:i_ne____

	gt\00\00:__null__
	:i_gt____

	lt\00\00:__null__
	:i_lt____

	call:__null__
	:i_call__

	jump:__null__
	:i_jump__

	ret\00:__null__
	:i_ret___

	sys\00:__null__
	:i_sys___

	db\00\00:__null__
	:i_db____

	dw\00\00:__null__
	:i_dw____

	dd\00\00:__null__
	:i_dd____

	ds\00\00:__null__
	:i_ds____

	%ret\00\00\00\00
	:i_mret__

	%call\00\00\00
	:i_mcall_

	%local\00\00
	:i_mlocal

	%arg\00\00\00\00
	:i_marg__

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

# Deferred string table
# [fixup address] [string address in memory] [prev string]
:defsttab
	:__null__

# Current heap pointer
:heap____
	:scratch_

:args____
:scratch_

