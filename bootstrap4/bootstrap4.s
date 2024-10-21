# Stage 4 bootstrap
# =================
#
# Historical note: this was previously bootstrap3 and used the raw VM
# opcodes. We introduced a new bootstrap3 in 2024 and mechanically
# translated each line 1:1 with the newer syntax to make this stage
# easier to maintain.
#
# Implements an assembler that supports a much richer, more human-readable format
#
# Includes real, two-pass label support (up to 32 chars long), simple call/return semantics

# TODO:
#   - During mechanical translation, labels were not expanded to 8+ chars,
#     and we did not trim the extraneous trailing underscores that are no
#     longer necessary.
#   - Polish/performance:
#     - Symbol table with local symbs should be "rolled back" at next global symbol for perf
#        - Can we do local fixups per global?
#     - Short immediate constants should use '=!x.' format
#     - readtok_ subroutines should be real functions
#     - macro for locals/args copy (ie: r0->r4, r1->r5, pushed/restored automatically)

# Register notes:
#
# Ra-Re = 0, 1, 2, 4, 8 values
# Rx = Temp var
# Ry = Stack pointer
# Rz = PC

:entry___
# Ra = Zero register
	sub ra, ra
# Rb = One register
	ldh rb, 0001
# Rc = Two register
	ldh rc, 0002
# Rd = Four register
	ldh rd, 0004
# Re = Eight register
	ldh re, 0008

# Set stack to memsize
	ldc r0, :SC_GTMEM
	sys r0
	mov ry, r0
	sub ry, rd

	jump :main____

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
=undersc_ 005f
=left{___ 007b
=left(___ 0028
=at______ 0040
=period__ 002e
=L_______ 004c
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
# Immediate indirect (data = value)
=T_IMI___ 0002
# Reference (constant or label, data = ptr to zero-terminated label)
=T_REF___ 0003
# Reference indirect (constant or label, data = ptr to zero-terminated label)
=T_RFI___ 0004
# Instruction (data = ins handler function)
=T_INS___ 0005
# Register (data = reg #)
=T_REG___ 0006
# Register indirect (data = reg #)
=T_RGI___ 0007
# EOL
=T_EOL___ 0008
# String
=T_STR___ 0009
# Define
=T_DEF___ 000a
# Include
=T_INC___ 000b
# String immediate
=T_SIM___ 000c

=INS_UNCO 0000
=INS_IF_T 0001
=INS_IF_F 0002

=OPEN_RO_ 0000
=OPEN_RW_ 0001

:tokens__
	data EOF\00
	data IMM\00
	data IMI\00
	data REF\00
	data RFI\00
	data INS\00
	data REG\00
	data RGI\00
	data EOL\00
	data STR\00
	data DEF\00
	data INC\00
	data SIM\00

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
	data \38\ff\ff\ff

:inclhand
	dd 0

# Stack of input file handles, used for #include
:in_hands
	dd 0

# Global: Output file handle
:out_hand
	dd 0


#===========================================================================
# Special jump table proc
# Preserves all registers except x
# Args:
#   Stack 0: Lookup
#   Stack 1: Table
#===========================================================================
:jumptabl
# Stash the return value in .ret_____
	pop r0
	ldc rx, .ret_____
	std [rx], r0
# Table address
	pop r0
	mov rx, r0
# Lookup value
	pop r0

# Preserve R0-R3
	push r1
	push r2
	push r3

# R3 holds the table
	mov r3, rx
# R2 holds the magic constant
	ldc r2, :JUMPEND_

.loop____
	ldd [r1], r3
	eq r1, r2
	jump? .done____
	eq r1, r0
	jump? .found___
	add r3, re
	jump .loop____

.found___
	add r3, rd
# Put the address in Rx
	ldd [rx], r3
	pop r3
	pop r2
	pop r1
# Jump (not call)
	mov rz, rx

.done____
# Restore
	pop r3
	pop r2
	pop r1

# Manual jump
	ldc rx, .ret_____
	ldd [rx], rx
	mov rz, rx

.ret_____
	dd 0
#===========================================================================


#===========================================================================
# Args:
#   R0: Error string
# Does not return
#===========================================================================
:error___
# Stash R0 in stack
	push r0
	call :strlen__
	pop r3
	ldc r1, :SC_WRITE
	ldh r2, 0002
	sys r1, r2, r3, r0
# Write a newline
	ldc r1, :SC_WRITE
	ldh r3, 000a
	stb [r3], r3
	sys r1, r2, r3, rb
# Exit with code 1
	ldc r0, :SC_EXIT_
	ldh r1, 0001
	sys r0, r1
#===========================================================================


#===========================================================================
# Register-friendly stderr logging.
# Args:
#   R0: String
# Returns:
#   All registers: Unchanged
#===========================================================================
:log_____
	eq r0, ra
	ret?
	push r1
	push r2

	push r0
	call :strlen__
	mov r2, r0
	pop r0

	ldc r1, :SC_WRITE
	sys r1, rc, r0, r2
	pop r2
	pop r1
	ret

.stash___
	dd 0
#===========================================================================


#===========================================================================
# Register-friendly stderr logging.
# Args:
#   R0: Number
# Returns:
#   All registers: Unchanged
#===========================================================================
:lognum__
	push r0
	push r1
	push r2

	push r0
# Clear the buffer
	ldc r0, .buffer__
	mov r1, ra
	ldh r2, 0010
	call :memset__
	pop r0

# Start at the end of the buffer
	ldc r1, .buffer__
	ldh rx, 000e
	add r1, rx

.loop____
	mov r2, r0
# Get the lowest digit
	ldh rx, 000a
	mod r2, rx
# Get the ASCII version
	ldc rx, .digits__
	add r2, rx
	ldb [r2], r2
# Write it to the buffer
	stb [r1], r2
	sub r1, rb
	ldh rx, 000a
# If we still have digits to write, continue
	div r0, rx
	gt r0, ra
	jump? .loop____

	mov r0, r1
	add r0, rb
	call :log_____

	pop r2
	pop r1
	pop r0
	ret

.buffer__
	dd 0
	dd 0
	dd 0
	dd 0

.digits__
	data 0123456789__

#===========================================================================


#===========================================================================
# Register-friendly stderr logging.
# Args:
#   R0: Number
# Returns:
#   All registers: Unchanged
#===========================================================================
:lognumh_
	push r0
	push r1
	push r2

	push r0
# Clear the buffer
	ldc r0, .buffer__
	mov r1, ra
	ldh r2, 0010
	call :memset__
	pop r0

# Start at the end of the buffer
	ldc r1, .buffer__
	ldh rx, 000e
	add r1, rx

.loop____
	mov r2, r0
# Get the lowest digit
	ldh rx, 0010
	mod r2, rx
# Get the ASCII version
	ldc rx, .digits__
	add r2, rx
	ldb [r2], r2
# Write it to the buffer
	stb [r1], r2
	sub r1, rb
	ldh rx, 0010
# If we still have digits to write, continue
	div r0, rx
	gt r0, ra
	jump? .loop____

	mov r0, r1
	ldc rx, :x_______
	stb [r0], rx
	sub r0, rb
	ldc rx, :zero____
	stb [r0], rx
	call :log_____

	pop r2
	pop r1
	pop r0
	ret

.buffer__
	dd 0
	dd 0
	dd 0
	dd 0

.digits__
	data 0123456789abcdef

#===========================================================================


#===========================================================================
# Does not return
#===========================================================================
:exit____
	ldc r0, :SC_EXIT_
	sub r1, r1
	sys r0, r1
#===========================================================================


#===========================================================================
# Args:
#   R0: Which
# Returns:
#   R0: Pointer to string (zero terminated)
#===========================================================================
:getargv_
	ldc rx, :args____
	mul r0, rd
	add r0, rx
	ldd [r0], r0
	ret
#===========================================================================


#===========================================================================
# Returns:
#   R0: Argument count (includes argv[0] which is the binary)
#===========================================================================
:getargc_
	ldc r1, :args____
	sub r0, r0
.loop____
	ldd [rx], r1
	eq rx, ra
	ret?
	add r0, rb
	add r1, rd
	jump .loop____
#===========================================================================


#===========================================================================
# Args:
#   R0: String
# Returns:
#   R0: Length
#===========================================================================
:strlen__
	mov r1, r0
.loop____
	ldb [r2], r0
	eq r2, ra
	jump? .ret_____
	add r0, rb
	jump .loop____
.ret_____
	sub r0, r1
	ret
#===========================================================================


#===========================================================================
# Args:
#  R0: Dest
#  R1: Src
# Returns:
#  R0: Dest
#===========================================================================
:strcpy__
	push r0
.loop____
	ldb [r2], r1
	stb [r0], r2
	eq r2, ra
	jump? .ret_____
	add r0, rb
	add r1, rb
	jump .loop____
.ret_____
	pop r0
	ret
#===========================================================================


#===========================================================================
# Args:
#  R0: String 1
#  R1: String 2
# Returns:
#  Equal? in flags
#===========================================================================
:strcmp__
	ldb [r2], r0
	ldb [r3], r1
	ne r2, r3
	jump? :retfalse
	eq r2, ra
	ret?
	add r0, rb
	add r1, rb
	jump :strcmp__
#===========================================================================


#===========================================================================
# Args:
#   R0: Address
#   R1: Value
#   R2: Length
#===========================================================================
:memset__
# If length == 0, return
	eq r2, ra
	ret?
	stb [r0], r1
	add r0, rb
	sub r2, rb
	jump :memset__
#===========================================================================


#===========================================================================
# Args:
#   R0: Size
# Returns:
#   R0: Address
#===========================================================================
:malloc__
	ldc rx, :heap____
	ldd [rx], rx
	mov r1, rx
	add r1, r0
	mov r0, rx
	ldc rx, :heap____
	std [rx], r1
	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: String
# Returns:
#   R0: Address
#===========================================================================
:mallocst
	push r0
	call :strlen__
	add r0, rb
	call :malloc__
	ldc rx, :heap____
	ldd [rx], rx
	pop r1
	jump :strcpy__
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
	push r2
	push r0
	push r1

	call :is_vrbos
	jump^ .nolog___

	push r0
	ldc r0, .opening_
	call :log_____
	pop r0
	call :log_____
	ldc r0, .as______
	call :log_____

	pop r1
	push r1
	mul r1, rd
	ldc rx, .mode____
	add r1, rx
	ldd [r0], r1
	call :log_____

.nolog___
	pop r1
	pop r0
	pop r2
	eq r2, rb
	jump? .relative
	ldc r4, :AT_FDCWD
	ldd [r4], r4
	jump .doopen__
.relative
	ldc r4, :inclhand
	ldd [r4], r4
.doopen__
	ldc r2, :SC_OPNAT
	ldc r3, :O_RDONLY
	ldc rx, :OPEN_RO_
	eq r1, rx
	jump? .readonly
	ldc r3, :O_RDWR__
	ldc rx, :O_TRUNC_
	or r3, rx
	ldc rx, :O_CREAT_
	or r3, rx
.readonly
	sys r2, r4, r0, r3
	add r2, rb
	ne r2, ra
	jump? .success_

	call :log_____
	ldc r0, .errfail_
	jump :error___

.success_
	mov r0, r2
	sub r0, rb
	ret

.opening_
	data Opening '\00
.as______
	data ' as \00
.s_ro____
	data read-only\0a\00
.s_rw____
	data read/write\0a\00
.mode____
	.s_ro____
	.s_rw____
.errfail_
	data \3a Failed to open file\00
#===========================================================================


#===========================================================================
# Steps back in the input file by one char
# No args/return
#===========================================================================
:rewind__
	call :getinhnd
	ldc r3, :SC_SEEK_
	sub r1, r1
	sub r1, rb
	ldc r2, :SEEK_CUR
	sys r3, r0, r1, r2
	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: NUL-terminated definition name
# Returns:
#   R0: Token type
#   R1: Token data
#===========================================================================
:lookupdf
	push r0
	ldc r2, :deftab__

.loop____
# Get the definition record
	ldd [r2], r2
	eq r2, ra
	jump? .notfound
# Get the pointer to the string
	add r2, re
	ldd [r1], r2
	pop r0
	push r0
	push r2
	call :strcmp__
	pop r2
	jump? .found___
	add r2, rd
	jump .loop____

# Found
.found___
	sub r2, rd
	ldd [r0], r2
	sub r2, rd
	ldd [r1], r2
	pop r2
	ret

.notfound
	call :log_____
	ldc r0, .errnotfo
	jump :error___

.errnotfo
	data \3a define not found\00
#===========================================================================


#===========================================================================
# Args:
#   R0: Definition name
#   R1: Token type
#   R2: Token value
#===========================================================================
:createdf
	push r0
	push r1
	push r2
# Allocate a record
	ldh r0, 0010
	call :malloc__
# Read the current record
	ldc rx, :deftab__
	ldd [rx], rx
# Write everything to the struct
	mov r1, r0
	pop r2
	std [r1], r2
	add r1, rd
	pop r2
	std [r1], r2
	add r1, rd
	pop r2
	std [r1], r2
	add r1, rd
	std [r1], rx
# Write the struct as the latest
	ldc rx, :deftab__
	std [rx], r0

# If we're in a global, just return
	ldc rx, :inglobal
	ldb [rx], rx
	eq rx, rb
	ret?

	ldc rx, :lastdef_
	std [rx], r0

	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: String A (or 0)
#   R1: String B (or 0)
# Returns:
#   Equals in flag
#===========================================================================
:comparsm
	eq r0, ra
	jump? .zero____
	eq r1, ra
	jump? .zero____
	jump :strcmp__
.zero____
	eq r0, r1
	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: Global symbol name
#   R1: Local symbol name
# Returns:
#   R0: Address
#===========================================================================
:lookupsm
	push r0
	push r1
	ldc r2, :symtab__

.loop____
# Get the symbol record
	ldd [r2], r2
	eq r2, ra
	jump? .notfound
# Get the pointer to the local name
	add r2, rd
	ldd [r1], r2
	pop r0
	push r0
	push r2
	call :comparsm
	pop r2
# Not a match, next record
	add^ r2, re
	jump^ .loop____

	pop r1
	pop r0
	push r0
	push r1
	add r2, rd
	ldd [r1], r2
	push r2
	call :comparsm
	pop r2
# Not a match, next record
	add^ r2, rd
	jump^ .loop____

	sub r2, re
	ldd [r0], r2
	pop r2
	pop r2
	ret

.notfound
	call :log_____
	ldc r0, .errnotfo
	jump :error___

.errnotfo
	data \3a symbol not found\00
#===========================================================================


#===========================================================================
# Args:
#   R0: Global symbol
#   R1: Local symbol (0 ok)
#   R2: Address
#===========================================================================
:createsm
	push r0
	push r1
	push r2
# Allocate a record
	ldh r0, 0010
	call :malloc__
# Read the current record
	ldc rx, :symtab__
	ldd [rx], rx
# Write everything to the struct
	mov r1, r0
	pop r2
	std [r1], r2
	add r1, rd
	pop r2
	std [r1], r2
	add r1, rd
	pop r2
	std [r1], r2
	add r1, rd
	std [r1], rx
# Write the struct as the latest
	ldc rx, :symtab__
	std [rx], r0
	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: Global symbol
#   R1: Local symbol (0 ok)
#   R2: Address
#===========================================================================
:createfx
	push r0
	push r1
	push r2
# Allocate a record
	ldh r0, 0010
	call :malloc__
# Read the current record
	ldc rx, :fixuptab
	ldd [rx], rx
# Write everything to the struct
	mov r1, r0
	pop r2
	std [r1], r2
	add r1, rd
	pop r2
	std [r1], r2
	add r1, rd
	pop r2
	std [r1], r2
	add r1, rd
	std [r1], rx
# Write the struct as the latest
	ldc rx, :fixuptab
	std [rx], r0
	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: Immediate string
#   R1: Fixup address
#===========================================================================
:createsi
	push r0
	push r1
# Allocate a record
	ldh r0, 0010
	call :malloc__
# Read the current record
	ldc rx, :defsttab
	ldd [rx], rx
# Write everything to the struct
	mov r1, r0
	pop r2
	std [r1], r2
	add r1, rd
	pop r2
	std [r1], r2
	add r1, rd
	std [r1], rx
# Write the struct as the latest
	ldc rx, :defsttab
	std [rx], r0
	ret
#===========================================================================


#===========================================================================
# Args/returns: none
#===========================================================================
:newfile_
	ldc rx, :inglobal
	stb [rx], ra
	ldc rx, :mlglobal
	std [rx], ra
	ldc rx, :deftab__
	std [rx], ra
	ldc rx, :lastdef_
	std [rx], ra
	ret
#===========================================================================


#===========================================================================
# Args/returns: none
#===========================================================================
:newglobl
# Roll the current definition back to the last global one
	ldc rx, :lastdef_
	ldd [r0], rx
	ldc rx, :deftab__
	std [rx], r0

	ldc rx, :inglobal
	stb [rx], rb

	ldc rx, :curlocal
	ldh r0, 0008
	stb [rx], r0
	ldc rx, :curarg__
	sub r0, r0
	stb [rx], r0
	ret
#===========================================================================

:curlocal
	db 0

:curarg__
	db 0

:lastdef_
	dd 0

:inglobal
	db 0

#===========================================================================
# Returns
#   The next register index to use
#===========================================================================
:nextlocl
	ldc rx, :curlocal
	ldb [r0], rx
	mov r1, r0
	add r1, rb
	stb [rx], r1
	ret
#===========================================================================


#===========================================================================
# Returns
#   The next argument register index
#===========================================================================
:nextarg_
	ldc rx, :curarg__
	ldb [r0], rx
	mov r1, r0
	add r1, rb
	stb [rx], r1
	ret
#===========================================================================


#===========================================================================
# Returns:
#   R0: Pointer to label string (not malloc'd)
#===========================================================================
:readlbl_
	mov r1, ra
	push r1
.loop____
	sub r0, r0
	call :readchar
	call :islabelc
	jump^ .done____
	pop r1
	ldh rx, 001f
	gt r1, rx
	jump? .toolong
	ldc rx, .buffer__
	add rx, r1
	stb [rx], r0
	add r1, rb
	push r1
	jump .loop____
.done____
	pop r1
# Write a trailing NUL
	ldc rx, .buffer__
	add rx, r1
	stb [rx], ra
# Rewind that char
	call :rewind__
	ldc r0, .buffer__
	ret
.toolong
	ldc r0, .buffer__
	call :log_____
	ldc r0, .toolong_msg
	jump :error___
.toolong_msg
	data \0aLabel too long\00

# This is enough for 32-byte labels/identifiers/strings
.buffer__
	data ________
	data ________
	data ________
	data ________
	db 0
#===========================================================================


#===========================================================================
# Returns:
#   R0: Pointer to string (not malloc'd)
#===========================================================================
:readstr_
# Eat whitespace
	call :rdcskwsp
	ldc rx, :quote___
	ne r0, rx
	ldc rx, .errinvch
	mov? r0, rx
	jump? :error___

	ldc r2, .buffer__
.loop____
	push r2
	call :readchar
	pop r2
	ldc rx, :quote___
	eq r0, rx
	jump? .done____
	ldc rx, :bslash__
	eq r0, rx
	jump? .escape__
	stb [r2], r0
	add r2, rb
	jump .loop____
.escape__
	push r2
	call :readchar
	pop r2
	ldh r1, ffff

	ldc rx, :n_______
	eq r0, rx
	ldc rx, :newline_
	mov? r1, rx

	ldc rx, :quote___
	eq r0, rx
	ldc rx, :quote___
	mov? r1, rx

	ldc rx, :bslash__
	eq r0, rx
	ldc rx, :bslash__
	mov? r1, rx

	ldc rx, :zero____
	eq r0, rx
	sub? r1, r1

	ldh rx, ffff
	eq r1, rx
	ldc rx, .errescap
	mov? r0, rx
	jump? :error___

	stb [r2], r1
	add r2, rb
	jump .loop____
.done____
# Trailing null
	stb [r2], ra

	ldc r0, .buffer__
	ret

# This is enough for 32-byte labels/identifiers/strings
.buffer__
	data ________
	data ________
	data ________
	data ________
	db 0

.errescap
	data Invalid escape\00

.errinvch
	data Invalid character (expected double quote)\00
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
	ldc rx, .isneg___
	stb [rx], ra

	call :rdcskwsp

	push r0
	ldc r0, .jumptabl
	push r0
	call :jumptabl

	call :isdigit_
	jump? .readdec_

	ldc r0, .errinvch
	call :error___

.jumptabl
	:minus___
	.negative
	:dollar__
	.immhex__
	:zero____
	.immzero_
	:JUMPEND_

.readdec_
	call :isdigit_
	jump? .immdec__

	ldc r0, .errinvch
	call :error___

.negative
# Set the negative flag
	ldc rx, .isneg___
	stb [rx], rb
	call :readchar
	jump .readdec_

.immzero_
# If the number started with zero, look for 'x' to signify hex, otherwise done
	call :readchar
	ldc rx, :x_______
	eq r0, rx
	jump? .immhex__

	sub r1, r1
	jump .immdone_

.immdec__
# Populate with the first digit we read
	ldc rx, :zero____
	sub r0, rx
	mov r1, r0

.immdloop
# Base 10 loop
	push r1
	call :readchar
	pop r1
	call :isdigit_
	jump^ .immdone_
	ldc rx, :newline_
	eq r0, rx
	jump? .immdone_

	ldh rx, 000a
	mul r1, rx
	ldc rx, :zero____
	sub r0, rx
	add r1, r0
	jump .immdloop

.immhex__
	sub r1, r1

.immhloop
# Base 16 loop
	push r1
	call :readchar
	pop r1
	call :istkspel
	jump? .immdone_
	ldc rx, :newline_
	eq r0, rx
	jump? .immdone_

# Use self-modifying code to read this digit
	ldc rx, .immhdigi
	stb [rx], r0
	data =#0 000
.immhdigi
	data _

	ldh rx, 0010
	mul r1, rx
	add r1, r0
	jump .immhloop

.immdone_
# Common exit point for base 10/16
	push r1
	call :rewind__
	pop r0

	ldc rx, .isneg___
	ldb [rx], rx
	eq rx, ra
	ret?

	sub rx, rx
	sub rx, r0
	mov r0, rx
	ret

.isneg___
	db 0

.errinvch
	data Invalid immediate character\00
#===========================================================================

#===========================================================================
# Returns:
#   R0: Token type
#   R1: Token data
#===========================================================================
:readtok_
	call :_readtok
# If not verbose, just return
	call :is_vrbos
	ret^

	jump :logtoken
#===========================================================================

#===========================================================================
# Returns:
#   R0: Token type
#   R1: Token data
#===========================================================================
:_readtok
# Whitespace is ignored
	call :rdcskwsp

# Default jump table
	push r0
	ldc r0, .jumptabl
	push r0
	call :jumptabl

	call :isdigit_
	jump? .imm_____

# Make sure it's alpha-numeric
	call :isalnum_
	jump^ .readtinv

# Otherwise if it's alnum, it's an instruction
	call :isalnum_
	jump? .ins_____

# Anything else is invalid
	jump .readtinv

#***************************

.jumptabl
# Return zero at EOF
	dd 0
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
	.ind_____
	:r_______
	.regmaybe
	:JUMPEND_

#***************************

.label___
	push r0
	call :readlbl_
	mov r1, r0
	pop r0
	ldc rx, :at______
	ne r0, rx
	jump? .labelref

# This is a macro, so search for the definition
	mov r0, r1
	push r0
	ldc r1, .localsiz
	call :strcmp__
	pop r0
	jump^ .notlocal

# Special macro: @__LOCALS_SIZE__
	ldc r0, :T_IMM___
	ldc r1, :curlocal
	ldb [r1], r1
	sub r1, re
	add r1, rb
	mul r1, rd
	jump .ret_____

.notlocal
	call :lookupdf
	jump .ret_____

.labelref
# Return a reference token
	ldc rx, :period__
	eq r0, rx
# Token flag: 0 for local, 1 for global
	mov? r2, ra
	mov^ r2, rb
	ldc r0, :T_REF___
	jump .ret_____

#***************************

.strimm__
	call :readstr_
	call :mallocst
# Immediate strings create temp symbols
	mov r1, r0
	ldc r0, :T_SIM___
	jump .ret_____

#***************************

.ccmt____
	call :readchar
	ldc rx, :fslash__
	eq r0, rx
	jump? .ccmtloop

	ldc r0, .errinvch
	jump :error___

.ccmtloop
	call :readchar
	ldc rx, :newline_
	eq r0, rx
	jump? .cmtdone_
	jump .ccmtloop

#***************************

.cmt_____
	sub r2, r2
.cmtloop_
# Eat chars until a newline
	push r2
	call :readchar
	pop r2
	ldc rx, :newline_
	eq r0, rx
	jump? .cmtdone_
	ldc r1, .buffer__
	add r1, r2
	add r2, rb
	stb [r1], r0
	ldh r3, 0007
	eq r2, r3
	jump? .cmtdef__
	ldh r3, 0008
	eq r2, r3
	jump? .cmtinc__
	jump .cmtloop_

# Fast look when we don't need to match #define
.cmtfastl
	call :readchar
	ldc rx, :newline_
	eq r0, rx
	jump? .cmtdone_
	jump .cmtfastl

# We matched #define, so need to process this in a special way
.cmtdef__
# NUL terminate, then compare against "define "
	add r1, rb
	stb [r1], ra
	ldc r1, .buffer__
	ldc r0, .cmtdstrd
	push r2
	call :strcmp__
	pop r2
	jump^ .cmtloop_

# It's a #define token, so return that
	ldc r0, :T_DEF___
	jump .ret_____

# We matched #include, so need to process this in a special way
.cmtinc__
# NUL terminate, then compare against "include "
	add r1, rb
	stb [r1], ra
	ldc r1, .buffer__
	ldc r0, .cmtdstri
	call :strcmp__
	jump^ .cmtfastl

# It's an #include token, so return that
	ldc r0, :T_INC___
	jump .ret_____

# Return EOL for a comment
.cmtdone_
	ldc r0, :T_EOL___
	jump .ret_____

.cmtdstrd
	data define\20
	dd 0

.cmtdstri
	data include\20
	dd 0

#***************************

.ind_____
# Recursive call, but skip logging
	call :_readtok

	ldc rx, :T_REG___
	eq r0, rx
	ldc rx, :T_RGI___
	mov? r0, rx
	jump? .ind_done

	ldc rx, :T_IMM___
	eq r0, rx
	ldc rx, :T_IMI___
	mov? r0, rx
	jump? .ind_done

	ldc rx, :T_REF___
	eq r0, rx
	ldc rx, :T_RFI___
	mov? r0, rx
	jump? .ind_done

	jump .readtinv

.ind_done
	push r0
	push r1
	push r2

	call :readchar
	ldc rx, :right]__
	ne r0, rx
	ldc r0, .indbrerr
	jump? :error___

	pop r2
	pop r1
	pop r0
	jump .ret_____


.indbrerr
	data Expected ]\00

#***************************

.regmaybe
	call :readchar
	call :isdigit_
	jump? .regyes__

	call :rewind__
	jump .ins_____

.regyes__
# Rewind the digit and the "r"
	call :rewind__
	call :rewind__

.reg_____
	call :readregr
	mov r1, r0
	ldc r0, :T_REG___
	jump .ret_____

#***************************

.imm_____
	call :rewind__
	call :readimm_
	mov r1, r0
	ldc r0, :T_IMM___
	jump .ret_____

#***************************

.charimm_
	call :readchar
	push r0
	call :readchar
	pop r1
	ldc r0, :T_IMM___
	jump .ret_____

#***************************

.insperc_
	jump .ins_____

.ins_____
	call :rewind__
# Clear the token buffer
	ldc r0, .buffer__
	mov r1, ra
	ldh r2, 0020
	call :memset__
	ldc r2, .buffer__

# Read until we get a space, tab or newline
.insloop_
	push r2
	call :readchar
	pop r2
	call :istkspel
	jump? .insdone_

# If the instruction ends in a ?, this means it is only executed if flag == true
	ldc rx, :question
	eq r0, rx
	ldc rx, :INS_IF_T
	mov? r3, rx
	jump? .inssrch_

# If the instruction ends in a ^, this means it is only executed if flag == false
	ldc rx, :hat_____
	eq r0, rx
	ldc rx, :INS_IF_F
	mov? r3, rx
	jump? .inssrch_

# Store and continue
# TODO: We should probably check if this is alpha
# .. or use the new helper function
	stb [r2], r0
	add r2, rb
	jump .insloop_

.insdone_
# Put the whitespace back
	call :rewind__
	ldc rx, :INS_UNCO
	mov r3, rx

.inssrch_
# Search the instruction table for a match
	ldc r0, :instruct
	ldc r2, .buffer__
	ldd [r2], r2
	ldc r4, :lastinst
.inssrchl
# Note that we only match the first four chars for each instruction
	ldd [r1], r0
	eq r1, r2
	jump? .insfound
	add r0, re
	add r0, re
	eq r0, r4
	jump? .inserror
	jump .inssrchl

.insfound
	mov r1, r0
	mov r2, r3
# Return
	ldc r0, :T_INS___
	jump .ret_____

.inserror
	ldc r0, .buffer__
	call :log_____
	ldc r0, .inserr__
	jump :error___

.inserr__
	data \2e Unknown instruction\00

#***************************

.string__
	call :rewind__
	call :readstr_
	call :mallocst
	mov r1, r0
	ldc r0, :T_STR___
	jump .ret_____

#***************************

.eol_____
	ldc r0, :T_EOL___
	jump .ret_____

#***************************

.ret_____
	ret

# This is enough for 32-byte labels/identifiers/strings
.buffer__
	data ________
	data ________
	data ________
	data ________

.space___
	:space___

.readtinv
	ldc r0, .errinvch
	jump :error___

.localsiz
	data __LOCALS_SIZE__\00

.errinvch
	data Invalid character\00

#===========================================================================


#===========================================================================
# Logs the return value of readtok_, preserving all registers
#===========================================================================
:logtoken
# Write the token to stderr for debugging
	push r0
	push r1
	push r2

	mov r5, r0
	mul r5, rd
	ldc rx, :tokens__
	add r5, rx

	push r0
	mov r0, r5
	call :log_____
	pop r0

	push r0
	ldc r0, .jumptabl
	push r0
	call :jumptabl

	jump .logdone_

.jumptabl
	:T_EOL___
	.logeol__
	:T_INS___
	.logins__
	:T_REG___
	.logreg__
	:T_RGI___
	.logreg__
	:T_REF___
	.logref__
	:T_RFI___
	.logref__
	:T_IMM___
	.logimm__
	:T_IMI___
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
	push r0
	ldc r0, .s_br_l__
	call :log_____
	pop r0
	ret
.log_br_r
	push r0
	ldc r0, .s_br_r__
	call :log_____
	pop r0
	ret
.s_br_l__
	data (\00\00\00
.s_br_r__
	data ) \00\00
.s_hat___
	data ^\00\00\00
.s_ques__
	data ?\00\00\00
.logeol__
.logeof__
	ldc r0, .newline_
	call :log_____
	jump .logdone_

.logspace
	ldc r0, .space___
	call :log_____
	jump .logdone_

.logins__
	call .log_br_l
	mov r0, r1
	call :log_____
	ldc rx, :INS_UNCO
	eq r2, rx
	jump? .logins_u
	ldc rx, :INS_IF_T
	eq r2, rx
	jump? .logins_t
	ldc rx, :INS_IF_F
	eq r2, rx
	jump? .logins_f
.logins_t
	ldc r0, .s_ques__
	call :log_____
	jump .logins_u
.logins_f
	ldc r0, .s_hat___
	call :log_____
	jump .logins_u
.logins_u
	call .log_br_r
	jump .logdone_

.logreg__
	call .log_br_l
	mov r0, r1
	call :encodreg
	ldc rx, .buffer__
	stb [rx], r0
	add rx, rb
	stb [rx], ra
	ldc r0, .buffer__
	call :log_____
	call .log_br_r
	jump .logdone_

.logref__
	call .log_br_l
	mov r0, r1
	call :log_____
	call .log_br_r
	jump .logdone_

.logimm__
	call .log_br_l
	mov r0, r1
	call :lognum__
	call .log_br_r
	jump .logdone_

.logstr__
	call .log_br_l
	mov r0, r1
	call :log_____
	call .log_br_r
	jump .logdone_

.logstimm
	call .log_br_l
	mov r0, r1
	call :log_____
	call .log_br_r
	jump .logdone_

.logdone_
	pop r2
	pop r1
	pop r0
	ret

.newline_
	:newline_

.space___
	:space___

.buffer__
	dd 0
#===========================================================================

# Useful function ends to return false or true in the flag

:retfalse
	ne r1, r1
	ret

:rettrue_
	eq r1, r1
	ret

#===========================================================================
# Args:
#   R0: Char
# Returns:
#   Flag in appropriate state
#   R0: Char
#===========================================================================
:islabelc
# Underscore is cool
	ldc rx, :undersc_
	eq r0, rx
	ret?

	jump :isalnum_
#===========================================================================


#===========================================================================
# Args:
#   R0: Char
# Returns:
#   Flag in appropriate state
#   R0: Char
#===========================================================================
:isnumber
	ldh rx, 0030
	lt r0, rx
	jump? :retfalse

	ldh rx, 003a
	lt r0, rx
	jump? :rettrue_

	jump :retfalse
#===========================================================================


#===========================================================================
# Args:
#   R0: Char
# Returns:
#   Flag in appropriate state
#   R0: Char
#===========================================================================
:isdigit_
	ldh rx, 0030
	lt r0, rx
	jump? :retfalse

	ldh rx, 003a
	lt r0, rx
	jump? :rettrue_

	jump :retfalse
#===========================================================================


#===========================================================================
# Args:
#   R0: Char
# Returns:
#   Flag in appropriate state
#   R0: Char
#===========================================================================
:isalnum_
	ldh rx, 0030
	lt r0, rx
	jump? :retfalse

	ldh rx, 003a
	lt r0, rx
	jump? :rettrue_

	ldh rx, 0041
	lt r0, rx
	jump? :retfalse

	ldh rx, 005b
	lt r0, rx
	jump? :rettrue_

	ldh rx, 0061
	lt r0, rx
	jump? :retfalse

	ldh rx, 007b
	lt r0, rx
	jump? :rettrue_

	jump :retfalse
#===========================================================================


#===========================================================================
# Args:
#   R0: Char
# Returns:
#   Flag in appropriate state
#   R0: Char
#===========================================================================
:istoksep
	ldc rx, :space___
	eq r0, rx
	jump? :rettrue_

	ldc rx, :tab_____
	eq r0, rx
	jump? :rettrue_

	ldc rx, :comma___
	eq r0, rx
	jump? :rettrue_

	jump :retfalse
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
	ldc rx, :space___
	eq r0, rx
	jump? :rettrue_

	ldc rx, :tab_____
	eq r0, rx
	jump? :rettrue_

	ldc rx, :comma___
	eq r0, rx
	jump? :rettrue_

	ldc rx, :newline_
	eq r0, rx
	jump? :rettrue_

	eq r0, ra
	jump? :rettrue_

	jump :retfalse
#===========================================================================


#===========================================================================
# Args:
#   R0: Filename
#   R2: Include file = 1
#===========================================================================
:openinpt
	push r2
	ldc r1, :OPEN_RO_
	call :open____
	push r0
	ldh r0, 000c
	call :malloc__
	pop r1
# Store the file handle
	std [r0], r1
# Write this new record to the open stack
	ldc rx, :in_hands
	ldd [r1], rx
	std [rx], r0
	add r0, rd
# Store the input mode
	pop r2
	std [r0], r2
	add r0, rd
# Store the next record
	std [r0], r1

	ret
#===========================================================================


#===========================================================================
# Args:
#   None
#===========================================================================
:popinput
# Load the current input record
	ldc rx, :in_hands
	ldd [rx], rx
# Determine which mode this record was in
	add rx, rd
	ldd [r0], rx
	eq r0, rb
	jump? .include_

# This is a new global file, so reset all global stuff
	call :newfile_

# Reload the current input record
	ldc rx, :in_hands
	ldd [rx], rx
	add rx, rd

.include_
	add rx, rd
# Pop the previous record
	ldd [rx], rx
	ldc r0, :in_hands
	std [r0], rx
	ret
#===========================================================================


#===========================================================================
# Returns:
#   R0: Current input handle
#===========================================================================
:getinhnd
	ldc rx, :in_hands
	ldd [r0], rx
	eq r0, ra
	ret?
	ldd [r0], r0
	ret
#===========================================================================


#===========================================================================
# Returns:
#   R0: File offset
#===========================================================================
:outtell_
	ldc r0, :out_hand
	ldd [r0], r0
	ldc r1, :SC_SEEK_
	sub r2, r2
	ldc r3, :SEEK_CUR
	sys r1, r0, r2, r3
	mov r0, r1
	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: File offset
#===========================================================================
:outseek_
	ldc r2, :out_hand
	ldd [r2], r2
	ldc r1, :SC_SEEK_
	ldc r3, :SEEK_SET
	sys r1, r2, r0, r3
	ret
#===========================================================================

#===========================================================================
# Returns:
#   R0: Char (zero if EOF)
#===========================================================================
:readchar
	call :getinhnd
	ldc r1, :SC_READ_
	ldc r2, .buffer__
	stb [r2], ra
	mov r3, rb
	sys r1, r0, r2, r3
	ldb [r0], r2
	ret
.buffer__
	data ????
#===========================================================================


#===========================================================================
# Reads a char, skipping whitespace.
# Returns:
#   R0: Char (zero if EOF)
#===========================================================================
:rdcskwsp
	call :readchar
	call :istoksep
	jump? :rdcskwsp
	ret
#===========================================================================


#===========================================================================
# Args:
#   R0: Char
#===========================================================================
:writech_
	ldc rx, .buffer__
	stb [rx], r0
	ldc r0, :out_hand
	ldd [r0], r0
	ldc r1, :SC_WRITE
	mov r2, rx
	mov r3, rb
	sys r1, r0, r2, r3
	ret
.buffer__
	dd 0
#===========================================================================



#===========================================================================
# Args:
#   R0: 32-bit value
#===========================================================================
:write32_
	ldc rx, .buffer__
	std [rx], r0
	ldc r0, :out_hand
	ldd [r0], r0
	ldc r1, :SC_WRITE
	mov r2, rx
	mov r3, rd
	sys r1, r0, r2, r3
	ret
.buffer__
	dd 0
#===========================================================================


#===========================================================================
# Args:
#   R0: 16-bit value
#===========================================================================
:write16_
	ldc rx, .buffer__
	std [rx], r0
	ldc r0, :out_hand
	ldd [r0], r0
	ldc r1, :SC_WRITE
	mov r2, rx
	mov r3, rc
	sys r1, r0, r2, r3
	ret
.buffer__
	dd 0
#===========================================================================


#===========================================================================
# Args:
#   R0: Buffer
#   R1: Length
#===========================================================================
:writebuf
	ldc r2, :out_hand
	ldd [r2], r2
	ldc r3, :SC_WRITE
	sys r3, r2, r0, r1
	ret
#===========================================================================


#===========================================================================
# Does not return
#===========================================================================
:errtoken
	ldc r0, .errtoken
	jump :error___

.errtoken
	data Invalid\20token\20encountered
	dd 0
#===========================================================================


:_isvrbfl
	db 0
:_iscmpfl
	db 0
:_islnkfl
	db 0

#===========================================================================
# Args:
#   None
# Returns:
#   Flag set to true if verbose
#===========================================================================
:is_vrbos
	ldc rx, :_isvrbfl
	ldb [rx], rx
	eq rx, rb
	ret

#===========================================================================
# Main
#===========================================================================
:main____
# Default include dir is working directory
	ldc rx, :AT_FDCWD
	ldd [rx], rx
	ldc r0, :inclhand
	std [r0], rx

# Get args size
	ldc r1, :SC_GTARG
	ldc r2, :args____
	sub r3, r3
	sys r1, r2, r3

	mov r3, r1
	ldc r1, :SC_GTARG
	ldc r2, :args____
	sys r1, r2, r3

# Point the heap past the end of args
	ldc rx, :heap____
	ldd [r0], rx
	add r0, r1
	std [rx], r0

	mov r0, rb
.argsloop
# Extract args
	push r0
	call :getargv_
	ldc r1, .verbose_
	call :strcmp__
	pop r0
	jump? .isverbos

	push r0
	call :getargv_
	ldc r1, .compile_
	call :strcmp__
	pop r0
	jump? .iscompil

	push r0
	call :getargv_
	ldc r1, .link____
	call :strcmp__
	pop r0
	jump? .islink__

	push r0
	call :getargv_
	ldc r1, .include_
	call :strcmp__
	pop r0
	jump? .isinclud

	jump .argsdone

.isverbos
	mov r1, rb
	ldc rx, :_isvrbfl
	stb [rx], r1
	add r0, rb
	push r0
	ldc r0, .verbmsg_
	call :log_____
	pop r0
	jump .argsloop

.iscompil
	mov r1, rb
	ldc rx, :_iscmpfl
	stb [rx], r1
	add r0, rb
	jump .argsloop

.islink__
	mov r1, rb
	ldc rx, :_islnkfl
	stb [rx], r1
	add r0, rb
	jump .argsloop

.isinclud
	add r0, rb
	push r0
	call :getargv_
	ldc r1, :SC_OPEN_
	ldc r2, :O_RDONLY
	sys r1, r0, r2
	ldc rx, :inclhand
	std [rx], r1
	pop r0
	add r0, rb
	jump .argsloop

.argsdone
# Open all files but the last one as input
	mov r1, r0
.openloop
	push r1
	call :getargc_
	pop r1
	sub r0, rb

	eq r1, r0
	mov r0, r1
	jump? .openout_

# Open argv[1] as input
	add r1, rb
	push r1
	call :getargv_
	sub r2, r2
	call :openinpt
	pop r1

	jump .openloop

.openout_
# Open last argument as rw, store in out_hand_
	call :getargv_
	ldc r1, :OPEN_RW_
	mov r2, ra
	call :open____
	ldc rx, :out_hand
	std [rx], r0

# If we aren't linking, just write directly to output
	ldc rx, :_islnkfl
	ldb [rx], rx
	eq rx, ra
	jump? :mainloop

# Write a jump to the _start symbol
	ldc r0, .startjmp
	ldh r1, 000c
	call :writebuf

# Create a fixup
	ldc r0, .start_s_
	sub r1, r1
	ldh r2, 0004
	call :createfx

	jump :mainloop

.start_s_
	data _start\00
.startjmp
	data =$x ????= zx

.verbose_
	data -v\00
.verbmsg_
	data Verbose mode\0a\00
.compile_
	data -c\00
.link____
	data -l\00
.include_
	data -I\00
#===========================================================================


#===========================================================================
# Main loop
#===========================================================================
:mainloop
# Read a token
	call :readtok_

	push r0
	ldc r0, .jumptabl
	push r0
	call :jumptabl

	jump :errtoken

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
	mov r0, r1
	push r2
	call :mallocst
	pop r2

# Global?
	eq r2, rb
	jump? .refgloba

# Create a local symbol using the current global
	mov r1, r0
	push r1
	call :outtell_
	mov r2, r0
	pop r1
	ldc rx, :mlglobal
	ldd [r0], rx
	call :createsm
	jump :mainloop

.refgloba
	push r0
	call :newglobl
	pop r0
# Store this as our global
	ldc rx, :mlglobal
	std [rx], r0
	push r0
	call :outtell_
	mov r2, r0
	pop r0
	sub r1, r1
	call :createsm
	jump :mainloop

.ins_____
# Extract the conditional execution flag
	ldc rx, :INS_UNCO
	eq r2, rx
	jump? .insuncon

	ldc rx, :INS_IF_T
	eq r2, rx
	jump? .ins_if_t

	ldc rx, :INS_IF_F
	eq r2, rx
	jump? .ins_if_f

.ins_if_t
	ldc r0, .i_jmp_nt
	jump .ins_cond

.ins_if_f
	ldc r0, .i_jmp_if
	jump .ins_cond

.ins_cond
	push r1
# Write the skip instructions
	ldh r1, 000c
	call :writebuf
	call :outtell_
	sub r0, re
	pop r1
	push r0
# Dispatch to the instruction
	call .insdisp_
	call :outtell_
	mov r1, r0
	pop r0
	push r1
# Compute the relative jump
	mov r2, r1
	sub r1, r0
	sub r1, re
	push r1
# Go back to the relative jump load
	call :outseek_
	pop r0
	call :write32_
	pop r0
	call :outseek_
	jump :mainloop

.insuncon
# Perform a call to a mini-function that will jump to the next address
	call .insdisp_
	jump :mainloop

# Note: does not return here!
.insdisp_
# Load R2 w/the instruction address
	add r1, re
	ldd [r2], r1
# Point R0 at the instruction data
	add r1, rd
	mov r0, r1
# Jump to R2
	mov rz, r2

.def_____
# Definition name
	call :readref_
	call :mallocst
	push r0
# Read the next token
	call :readtok_
	push r0
	push r1
# Expect an EOL
	call :readeol_
	pop r2
	pop r1
	pop r0
	call :createdf
	jump :mainloop

.inc_____
	call :readstr_
# Filename in r0
	push r0
	call :readeol_
	pop r0
	mov r2, rb
	call :openinpt
	jump :mainloop

.eof_____
	call :popinput
	call :getinhnd
	eq r0, ra
	jump^ :mainloop

# Write the deferred strings
	ldc r4, :defsttab
.fixupsi_
	ldd [r4], r4
	eq r4, ra
	jump? .donesi__
	call :outtell_
	mov r5, r0
# The fixup address
	ldd [r6], r4
	add r4, rd
# The string pointer
	ldd [r7], r4
	add r4, rd
	mov r0, r7
	call :strlen__
	mov r1, r0
	add r1, rb
	mov r0, r7
# Write the string at the end (NUL terminated)
	call :writebuf
# Get our new location
	call :outtell_
	mov r7, r0
# Seek to the old location
	mov r0, r6
	call :outseek_
# Write the fixup
	mov r0, r5
	call :write32_
# Seek back to the end
	mov r0, r7
	call :outseek_
	jump .fixupsi_

.donesi__

# Create an __END__ symbol with the length of the output
	call :outtell_
	mov r2, r0
	ldc r0, .end_s___
	sub r1, r1
	call :createsm

# Do the fixups
	ldc rx, :fixuptab
	ldd [r0], rx

.dofixups
	eq r0, ra
	jump? .done____
	push r0
# Address
	ldd [r1], r0
	add r0, rd
	push r1


# Local
	ldd [r2], r0
	add r0, rd
# Global
	ldd [r3], r0
	add r0, rd
	mov r0, r3
	mov r1, r2

	call :is_vrbos
	jump^ .nolog1__
	push r0
	ldc r0, .glo_s___
	call :log_____
	pop r0
	push r0
	push r1
	call :log_____
	ldc r0, .loc_s___
	call :log_____
	mov r0, r1
	call :log_____
	ldc r0, .space___
	call :log_____
	pop r1
	pop r0
.nolog1__
	call :lookupsm

	call :is_vrbos
	jump^ .nolog2__
	push r0
	call :lognumh_
	ldc r0, .newline_
	call :log_____
	pop r0
.nolog2__

	pop r1
	push r0
	mov r0, r1
# Seek to address, fixup
	call :outseek_
	pop r0
	call :write32_
	pop r0
	add r0, rd
	add r0, re
	ldd [r0], r0
	jump .dofixups

.glo_s___
	data g\3a\00
.loc_s___
	data  l\3a\00
.space___
	data  \40 \00
.newline_
	data \0a\00

.done____
	ldh r0, 0000
	call :exit____
.end_s___
	data __END__\00
.i_jmp_if
	data =$x ????+?zx
.i_jmp_nt
	data =$x ????+^zx

#===========================================================================

# Current global label
:mlglobal
	dd 0

#===========================================================================
# Args:
#   None
#===========================================================================
:readeol_
	call :readtok_
	ldc rx, :T_EOL___
	ne r0, rx
	ldc rx, .error___
	mov? r0, rx
	jump? :error___
	ret

.error___
	data Expected\20EOL
	dd 0
#===========================================================================


#===========================================================================
# Args:
#   None
#===========================================================================
:readref_
# Eat whitespace
	call :rdcskwsp
	call :rewind__
	call :readlbl_
	mov r1, r0
	ldc r0, :T_REF___
	mov r2, ra
	call :is_vrbos
	jump^ .nolog___
	call :logtoken
.nolog___
	mov r0, r1
	ret
#===========================================================================


#===========================================================================
# Returns:
#   R0: Register index
#===========================================================================
:readregr
# First char must be "r"
	call :rdcskwsp
	ldc rx, :r_______
	eq r0, rx
	ldc r0, .error___
	jump^ :error___

# Second char must be a digit
	call :readchar
	call :isdigit_
	ldc rx, .error___
	mov^ r0, rx
	jump^ :error___

	ldc rx, :zero____
	sub r0, rx
	mov r1, r0

.loop____
	push r1
	call :readchar
	pop r1
	call :isdigit_
	jump^ .done____

	ldh rx, 000a
	mul r1, rx
	ldc rx, :zero____
	sub r0, rx

	add r1, r0
	jump .loop____

.done____
# If the register is > 64, that's an error
	ldh r0, 003f
	gt r1, r0
	ldc rx, .invalid_
	mov? r0, rx
	jump? :error___

	push r1
	call :rewind__
	pop r0
	ret

.error___
	data Expected register (rXX)\00

.invalid_
	data Invalid register (r0-r63 expected)\00
#===========================================================================


#===========================================================================
# Returns:
#   R0: Token type (T_REG___)
#   R1: Register index
#===========================================================================
:readreg_
	call :readtok_

	ldc rx, :T_REG___
	ne r0, rx
	ldc rx, .error___
	mov? r0, rx
	jump? :error___
	ret

.error___
	data Expected register\00
#===========================================================================


#===========================================================================
# Returns:
#   R0: Token type (T_RGI___)
#   R1: Register index
#===========================================================================
:readrgi_
	call :readtok_

	ldc rx, :T_RGI___
	ne r0, rx
	ldc rx, .error___
	mov? r0, rx
	jump? :error___
	ret

.error___
	data Expected register-indirect\00
#===========================================================================


#===========================================================================
# Returns:
#   R0: Token type (T_REG___ or T_EOL___)
#   R1: Register index
#===========================================================================
:readropt
	call :readtok_
	ldc rx, :T_EOL___
	eq r0, rx
	ret?

	ldc rx, :T_REG___
	ne r0, rx
	ldc rx, .error___
	mov? r0, rx
	jump? :error___
	ret

.error___
	data Expected register or EOL\00
#===========================================================================

#===========================================================================
# Args:
#   R1: The register index
# Returns:
#   Register encoding in r0
#===========================================================================
:encodreg
# Move the reg# to r0
	ldc r0, .register
	add r0, r1
# Load the character representing the register
	ldb [r0], r0
	ret

# Simple lookup table for registers
.register
	data 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz__
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
	ldc rx, :T_REF___
	eq r0, rx
	jump? .ref_____

	ldc rx, :T_IMM___
	eq r0, rx
	jump? .imm_____

	ldc rx, :T_SIM___
	eq r0, rx
	jump? .strimm__

	jump :errtoken

.ref_____
# Create a fixup
	eq r2, rb
	jump? .global__
# For a local ref we use the global symbol and copy the local token
	mov r0, r1
	call :mallocst
	mov r1, r0
	push r1
	call :outtell_
	mov r2, r0
	pop r1
	ldc rx, :mlglobal
	ldd [r0], rx
	call :createfx
# Use a fake address for now
	ldh r1, 1234
	push r1
	jump .enc32___
.global__
# For a global ref we need to copy the token
	mov r0, r1
	call :mallocst
	push r0
	call :outtell_
# Add 4 to file position for fixup
	mov r2, r0
	pop r0
	sub r1, r1
	call :createfx
# Use a fake address for now
	ldh r1, 1234
	push r1
	jump .enc32___
.imm_____
	push r1
	jump .enc32___

.strimm__
	push r1
	call :outtell_
	mov r1, r0
	pop r0
	call :createsi
# Use a fake address for now
	ldh r0, 1234
	push r0
	jump .enc32___

.enc32___
	pop r0
	call :write32_
	ret
#===========================================================================


#===========================================================================
# Writes an assignment from a register/register indirect, immediate, or 
# reference token, to another register by index.
#
# Args:
#  R0: Token type
#  R1: From
#  R2: (unused)
#  R3: To
#===========================================================================
:encasgnr
	ldc rx, :T_REG___
	eq rx, r0
	jump? .reg_____

	ldc rx, :T_RGI___
	eq rx, r0
	jump? .rgi_____

	ldc rx, :T_RFI___
	eq rx, r0
	jump? .refind__

	ldc rx, :T_IMI___
	eq rx, r0
	jump? .immind__

# Reference or immediate (we don't check this as encrefim will)
.refimm__
	push r0
	push r1
	push r2
	mov r1, r3
	call :encodreg
	ldc rx, .to_i____
	stb [rx], r0
	ldc r0, .buffer_i
	mov r1, rd
	call :writebuf
	pop r2
	pop r1
	pop r0
	call :encrefim
	ret

.refind__

# Load output w/the address
	push r3
	ldc r0, :T_REF___
	call .refimm__
	pop r3
# Now do the register indirect thing
	mov r1, r3
	jump .rgi_____

.immind__

# Load output w/the address
	push r3
	ldc r0, :T_IMM___
	call .refimm__
	pop r3
# Now do the register indirect thing
	mov r1, r3
	jump .rgi_____

.buffer_i
	data =$
.to_i____
	data ?\20

.reg_____
	call :encodreg
	ldc r2, .from_r__
	stb [r2], r0
	mov r1, r3
	call :encodreg
	ldc r2, .to_r____
	stb [r2], r0
	ldc r0, .buffer_r
	mov r1, rd
	call :writebuf
	ret

.rgi_____
	call :encodreg
	ldc r2, .from_n__
	stb [r2], r0
	mov r1, r3
	call :encodreg
	ldc r2, .to_n____
	stb [r2], r0
	ldc r0, .buffer_n
	mov r1, rd
	call :writebuf
	ret

.buffer_r
	data =\20
.to_r____
	data ?
.from_r__
	data ?

.buffer_n
	data =(
.to_n____
	data ?
.from_n__
	data ?
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
	ldc rx, :T_REG___
	eq r0, rx
	jump? .reg_____

# Assign to ctmp, then push that
	ldc r3, :R_ctmp__
	call :encasgnr

	ldc r0, :T_REG___
	ldc r1, :R_ctmp__

.reg_____
	call :encodreg
	ldc rx, .from____
	stb [rx], r0
	ldc r0, .buffer__
	mov r1, re
	call :writebuf
	ret

.buffer__
	data -!y\04(=y
.from____
	data ?
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
	ldc rx, :T_REG___
	eq r0, rx
	jump? .reg_____

	call :errtoken

.reg_____
	call :encodreg
	ldc rx, .to______
	stb [rx], r0
	ldc r0, .buffer__
	mov r1, re
	call :writebuf
	ret

.buffer__
	data =(
.to______
	data ?y+!y\04
#===========================================================================


#===========================================================================
# Returns:
#   R0: T_REG___ or T_EOL___
#   R1: Register index
#===========================================================================
:readvalo
	call :readtok_
	ldc rx, :T_EOL___
	eq r0, rx
	ret?

	ldc rx, :T_REG___
	eq r0, rx
	ret?

# If it's not a register, assign it to x
	ldc r3, :R_ctmp__
	call :encasgnr
	ldc r0, :T_REG___
	ldc r1, :R_ctmp__
	ret
#===========================================================================


#===========================================================================
# Returns:
#   R0: Register encoding for value
#===========================================================================
:readval_
	call :readvalo
	ldc rx, :T_REG___
	ne r0, rx
	jump? :errtoken

	call :encodreg

	ret
#===========================================================================


#===========================================================================
# Args:
#   R0-R2: Token
# Returns:
#   R0: Register encoding for address
#===========================================================================
:encind__
	push r0
	ldc r0, .jumptabl
	push r0
	call :jumptabl

	ldc r0, .error___
	jump :error___

.error___
	data Expected indirect (eg\3a [rXX], [\3aref], [immediate])\00

.jumptabl
	:T_RGI___
	.rgi_____
	:T_IMI___
	.imi_____
	:T_RFI___
	.rfi_____
	:JUMPEND_

.rgi_____
	call :encodreg
	ret

.imi_____
	ldc r0, :T_IMM___
	jump .imm_____

.rfi_____
	ldc r0, :T_REF___
	jump .imm_____

.imm_____
# If it's not a register, assign it to x
	ldc r3, :R_ctmp__
	call :encasgnr
	ldc r1, :R_ctmp__
	call :encodreg
	ret
#===========================================================================


#===========================================================================
# Returns:
#   R0: Register encoding for address
#===========================================================================
:readind_
	call :readtok_
	jump :encind__

#===========================================================================
# The vast majority of opcodes can be encoded with this method.
#
# If the second char is ' ', we treat it as a flexible opcode where we can
# use some additional characters:
#
#   ' ': The fourth char in the opcode is a register
#   '$': The fourth char in the opcode is a space and the next four bytes are
#        a 32-bit constant
#   '!': The fourth char in the opcode is a byte representing the exact vaule
#   '?': The instruction is skipped if the flag is false
#   '^': The instruction is skipped if the flag is true
#
# The LHS of any standard opcode must be a register, but the RHS is flexible
# and may be a register, an immediate, a reference, or an indirection of any
# of those.
#
# In the case of a load instruction (which we handle here as well), the RHS
# _must_ be an indirection. This is more for clarity of assembly rather than
# any technical reason.
#
# In the case of a store instruction, the LHS _must_ be an indirection, but
# if the LHS is a non-register indirection, we special-case it. Again, this
# is for clarity of assembly code.
#
# TODO: We should propagate the instruction conditional flag here if we can
# safely do so (ie: mov? r0, r1 -> =?01).
#
# Args:
#   R0: A pointer to 32-bit metadata for the instruction
#===========================================================================
# Standard instruction
:i_stnd__
# Copy the first two metadata bytes to the buffer
	ldc rx, .buf_____
	ldw [r1], r0
	stw [rx], r1
	add r0, rc

# Check for load/store
	ldb [r1], r0
	ldc rx, :L_______
	eq r1, rx
	mov? r1, rb
	mov^ r1, ra
	ldc rx, .isload__
	stb [rx], r1

	ldb [r1], r0
	ldc rx, :S_______
	eq r1, rx
	mov? r1, rb
	mov^ r1, ra
	ldc rx, .isstore_
	stb [rx], r1

# Target
	call :readtok_
	push r1
	push r2

# Loads the appropriate jump table (normal vs store)
	push r0
	ldc r0, .whichjmp
	ldc rx, .isstore_
	ldb [rx], rx
	mul rx, rd
	add r0, rx
	ldd [r0], r0
	push r0
	call :jumptabl

	ldc r0, .invtoken
	call :error___

.whichjmp
	.jumptabl
	.jumptabs

# The jumptable for store
.jumptabs
	:T_RGI___
	.rgi_____
	:T_RFI___
	.ind_____
	:T_IMI___
	.ind_____
	:JUMPEND_

# Regular jumptable
.jumptabl
	:T_REG___
	.std_____
	:JUMPEND_

# Standard-type instruction
.std_____
	pop r2
	pop r1
# Easy: write the register to the buffer
	call :encodreg
	ldc rx, .bufreg1_
	stb [rx], r0

# Now read whatever is in position #2 and write it out
	ldc rx, .isload__
	ldb [rx], rx
	eq rx, rb
	jump? .stdload_
	call :readval_
	jump .stddone_
.stdload_
	call :readind_
.stddone_
	ldc rx, .bufreg2_
	stb [rx], r0
	jump .fin_____

.rgi_____
	pop r2
	pop r1
# Easy: write the register to the buffer
	call :encodreg
	ldc rx, .bufreg1_
	stb [rx], r0
# Next bit can be anything
	call :readval_
	ldc rx, .bufreg2_
	stb [rx], r0
	jump .fin_____

.ind_____
	pop r2
	pop r1
# This one is a complex encoding
	call :encind__
	ldc rx, .bufreg1_
	stb [rx], r0
# Next has to be a simple reg
	call :readreg_
	call :encodreg
	ldc rx, .bufreg2_
	stb [rx], r0
	jump .fin_____

.fin_____
	ldc r0, .buf_____
	mov r1, rd
	call :writebuf
	ret

.isload__
	data ?
.isstore_
	data ?
.buf_____
	data ??
.bufreg1_
	data ?
.bufreg2_
	data ?

.invtoken
	data Unexpected token in first position\00
#===========================================================================


:i_call_s
	data -!y\04=!x\0c+ xz(=yx=$z\20
:i_jump_s
	data =$z\20
:i_ret__s
	data =(xy+!y\04= zx

:i_push__
	call :readvalo
	ldc rx, :T_EOL___
	eq r0, rx
	ret?
	call :encpush_
	jump :i_push__
:i_pop___
	call :i_poprec
	ret
:i_poprec
	call :readropt
	ldc rx, :T_EOL___
	eq r0, rx
	ret?
	push r0
	push r1
	call :i_poprec
	pop r1
	pop r0
	call :encpop__
	ret
:i_call__
# Note that call doesn't support a register target yet - this is possible but would complicate
# this code
	ldc r0, :i_call_s
	ldh r1, 0014
	call :writebuf
	call :readtok_
	call :encrefim
	ret
:i_jump__
	call :readtok_
	ldc rx, :T_REG___
	eq r0, rx
	jump? :i_jump_r
	push r0
	push r1
	push r2
	ldc r0, :i_jump_s
	ldh r1, 0004
	call :writebuf
	pop r2
	pop r1
	pop r0
	call :encrefim
	ret
:i_jump_r
# Emit faster jump to a register
	ldc r3, :R_pc____
	call :encasgnr
	ret
:i_ret___
	call :readeol_
	ldc r0, :i_ret__s
	ldh r1, 000c
	call :writebuf
	ret
:i_sys___
# Fill the syscall buffer with spaces
	ldc r0, .sys_____
	ldc r1, :space___
	ldh r2, 0008
	call :memset__
# Set the first char to S
	ldc r0, .sys_____
	ldc r1, :S_______
	stb [r0], r1
# Now pointed at the first reg spot
	add r0, rc
# First argument is allowed to be a value (makes calls where return value is ignored simpler)
	push r0
	call :readval_
	mov r1, r0
	pop r0
	stb [r0], r1
	add r0, rb
# Now read regs until we're done
.loop____
	push r0
	call :readropt
	ldc rx, :T_EOL___
	eq r0, rx
	jump? .write___
	call :encodreg
	mov r1, r0
	pop r0
	stb [r0], r1
	add r0, rb
	ldc rx, .sys_____
	mov r1, r0
	sub r1, rx
	ldh rx, 0009
	eq r1, rx
	jump^ .loop____
	ldc r0, .toomany_
	call :error___
.write___
	pop r0
	ldc rx, .sys_____
	mov r1, r0
	sub r1, rx
	ldh rx, 0005
	lt r1, rx
	jump? .short___
	ldc r1, .sys_____
	add r1, rb
	ldc rx, :plus____
	stb [r1], rx
	mov r1, re
	jump .writeit_
.short___
	mov r1, rd
.writeit_
	ldc r0, .sys_____
	call :writebuf
	ret
.sys_____
	data ????????
.toomany_
	data Too many registers for sys (maximum six)\00
:i_db____
	call :readtok_
	ldc rx, :T_EOL___
	eq r0, rx
	ret?
	ldc rx, :T_IMM___
	eq r0, rx
	jump? :i_db_i__
	ldc rx, :T_STR___
	eq r0, rx
	jump? :i_db_s__
	jump :errtoken
:i_db_i__
	mov r0, r1
	ldh r1, 0100
	lt r0, r1
	jump? .ok______
	sub rx, rx
	sub rx, r1
	sub rx, rb
	gt r0, rx
	jump? .ok______
	ldc r0, .toobig_s
	call :error___
.ok______
	call :writech_
	jump :i_db____
.toobig_s
	data db value is too large\00
:i_db_s__
	push r1
	mov r0, r1
	call :strlen__
	mov r1, r0
	pop r0
	call :writebuf
	jump :i_db____
:i_dw____
	call :readtok_
	ldc rx, :T_EOL___
	eq r0, rx
	ret?
	ldc rx, :T_IMM___
	eq r0, rx
	jump? :i_dw_i__
	jump :errtoken
:i_dw_i__
	mov r0, r1
	ldh r1, ffff
	add r1, rb
	lt r0, r1
	jump? .ok______
	sub rx, rx
	sub rx, r1
	sub rx, rb
	gt r0, rx
	jump? .ok______
	ldc r0, .toobig_s
	call :error___
.ok______
	call :write16_
	jump :i_dw____
.toobig_s
	data dw value is too large\00
:i_dd____
	call :readtok_
	ldc rx, :T_EOL___
	eq r0, rx
	ret?
	call :encrefim
	jump :i_dd____
:i_ds____
	call :i_db____
# Trailing NUL
	sub r0, r0
	call :writech_
	ret
:i_marg__
	call :nextlocl
	push r0
	call :readref_
	call :mallocst
	pop r2
	push r2
	ldc r1, :T_REG___
	push r1
	call :createdf

# Push the old value
	pop r0
	pop r1
	push r1
	push r0
	call :encpush_
# Assign to next arg
	call :nextarg_
	mov r1, r0
	pop r0
	pop r3
	call :encasgnr

	call :readeol_
	ret
:i_mret__
# Pop args/locals off before we return
	ldc rx, :curlocal
	ldb [r0], rx
.loop____
	eq r0, re
	jump? .done____
	sub r0, rb
	push r0
	mov r1, r0
	ldc r0, :T_REG___
	call :encpop__
	pop r0
	jump .loop____

.done____
# Regular return
	call :readeol_
	ldc r0, :i_ret__s
	ldh r1, 000c
	call :writebuf
	ret
:i_mlocal
	call :nextlocl
	push r0
	call :readref_
	call :mallocst
	pop r2
	push r2
	ldc r1, :T_REG___
	push r1
	call :createdf

# Push the old value
	pop r0
	pop r1
	call :encpush_

	call :readeol_
	ret
:i_mcall_
# Call target, must be immediate or reference, assigned to ctmp2
	call :readtok_
	ldc r3, :R_ctmp2_
	call :encasgnr

# Current output register
	sub r3, r3
.loop____
	push r3
	call :readtok_
	pop r3
	ldc rx, :T_EOL___
	eq r0, rx
	jump? .write___
	push r3
	call :encasgnr
	pop r3
	add r3, rb
	jump .loop____

.write___
	ldc r0, .call_s__
	ldh r1, 0014
	call :writebuf
	ret
.call_s__
	data -!y\04=!x\08+ xz(=yx= zw

# Instruction table
:instruct
# Standard ALU-type instructions
	data mov\00
	dd 0
	:i_stnd__
	mov r?, r?

	data add\00
	dd 0
	:i_stnd__
	add r?, r?

	data sub\00
	dd 0
	:i_stnd__
	sub r?, r?

	data mul\00
	dd 0
	:i_stnd__
	mul r?, r?

	data div\00
	dd 0
	:i_stnd__
	div r?, r?

	data mod\00
	dd 0
	:i_stnd__
	mod r?, r?

	data or\00\00
	dd 0
	:i_stnd__
	or r?, r?

	data and\00
	dd 0
	:i_stnd__
	and r?, r?

	data xor\00
	dd 0
	:i_stnd__
	xor r?, r?

# Load/store
	data ld\2eb
	dd 0
	:i_stnd__
	ldb [rL], r?

	data ld\2ew
	dd 0
	:i_stnd__
	ldw [rL], r?

	data ld\2ed
	dd 0
	:i_stnd__
	ldd [rL], r?

	data st\2eb
	dd 0
	:i_stnd__
	stb [rS], r?

	data st\2ew
	dd 0
	:i_stnd__
	stw [rS], r?

	data st\2ed
	dd 0
	:i_stnd__
	std [rS], r?

# Compare
	data eq\00\00
	dd 0
	:i_stnd__
	eq r?, r?

	data ne\00\00
	dd 0
	:i_stnd__
	ne r?, r?

	data gt\00\00
	dd 0
	:i_stnd__
	gt r?, r?

	data lt\00\00
	dd 0
	:i_stnd__
	lt r?, r?

# Push/pop/PC
	data push
	dd 0
	:i_push__
	data ????

	data pop\00
	dd 0
	:i_pop___
	data ????

	data call
	dd 0
	:i_call__
	data ????

	data jump
	dd 0
	:i_jump__
	data ????

	data ret\00
	dd 0
	:i_ret___
	data ????

	data sys\00
	dd 0
	:i_sys___
	data ????

# Data
	data db\00\00
	dd 0
	:i_db____
	data ????

	data dw\00\00
	dd 0
	:i_dw____
	data ????

	data dd\00\00
	dd 0
	:i_dd____
	data ????

	data ds\00\00
	dd 0
	:i_ds____
	data ????

# "Macros" with more complex behaviour
	data %ret\00\00\00\00
	:i_mret__
	data ????

	data %call\00\00\00
	:i_mcall_
	data ????

	data %local\00\00
	:i_mlocal
	data ????

	data %arg\00\00\00\00
	:i_marg__
	data ????

:lastinst

# Linked list of symbols:
# [global symbol pointer] [local symbol pointer] [write address] [prev symbol]
:symtab__
	dd 0

# Linked list of defines:
# [define string pointer] [token type] [token value] [prev define]
:deftab__
	dd 0

# Linked list of fixups:
# [fixup address] [global symbol pointer] [local symbol pointer] [prev fixup]
:fixuptab
	dd 0

# Deferred string table
# [fixup address] [string address in memory] [prev string]
:defsttab
	dd 0

# Current heap pointer
:heap____
	:scratch_

:args____
:scratch_

