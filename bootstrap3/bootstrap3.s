# Stage 3 bootstrap
# =================
#
# Macro assembler that improves on the previous stage, allowing
# for longer label lengths, and a simple assembler format to
# isolate the source from the underlying op encoding.
#
# This is the final stage that uses hand-assembled opcodes for the
# majority of its work.

# TODO:
#   - Remove the a-e register use?
#     - eq|add|sub rX, ra/rb -> eq|add|sub rX, 0/1
#   - Consider `ldd r0, [r1]` rather than `ldd [r1], r0`
#   - Multi-file support

=ARGVSIZE 1000
=SYMTSIZE 5000
=FXUPSIZE 5000
=STTBSIZE 5000

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
=SC_CLOSE 0004
=SC_GTARG 0005
=SC_GTMEM 0006
=SC_EXIT_ 0007
=SC_OPNAT 0008

# Allocate argv, symbol and fixup table addresses
:entry___
# Set stack to memsize
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

	=$0 :SC_GTMEM
	S 0 
	= y0
	- yd

	=$0 :ARGVSIZE
	@call:malloc__
	= 10
	=$0 :argv____
	@call:store32_

	=$0 :SYMTSIZE
	@call:malloc__
	= 10
	=$0 :symtab__
	@call:store32_

	=$0 :FXUPSIZE
	@call:malloc__
	= 10
	=$0 :fixuptab
	@call:store32_

	=$0 :STTBSIZE
	@call:malloc__
	= 10
	=$0 :stringtb
	@call:store32_

# Get argv at :argv____
	=$0 :argv____
	@call:load32__
	=$1 :SC_GTARG
	=$2 :ARGVSIZE
	S+102   
# Open argv[1] as r/o in R8 (input)
	=#0 0001
	@call:getargv_
	=$1 :SC_OPEN_
	S 10
	=$0 :curr_ifd
	@call:store32_

# Open argv[2] as r/w in R9 (output)
	=#0 0002
	@call:getargv_
	=#2 0602
	=$1 :SC_OPEN_
	S+102   
	=$0 :curr_ofd
	@call:store32_

# Set the table to the main table
	=$0 :mjumptbl
	@jump:mainloop

# Character jump table
# Labels allow a small amount of indirection
:jumptabl
# Pointer to current table
	____

=CHR_EOF_ 0000
=CHR_TAB_ 0009
=CHR_NL__ 000a
=CHR_SPAC 0020
=CHR_HASH 0023
=CHR_STAR 002a
=CHR_DOT_ 002e
=CHR_COLN 003a
=CHR_QUES 003f
=CHR_EQL_ 003d
=CHR_AT__ 0040
=CHR_BKSL 005c
=CHR_DEFL ffff

# Main jump table
:mjumptbl
	:CHR_EOF_:chr_eof_
	:CHR_TAB_:chr_assm
	:CHR_NL__:chr_nl__
	:CHR_HASH:chr_cmnt
	:CHR_COLN:chr_lblg
	:CHR_DOT_:chr_lbll
	:CHR_EQL_:chr_defn
# Default
	:CHR_DEFL:chr_err_

# Assembler jump table
:ajumptbl
	:CHR_EOF_:chr_eof_
	:CHR_NL__:chr_nla_
	:CHR_COLN:chr_fxpg
	:CHR_DOT_:chr_fxpl
	:CHR_AT__:chr_mcro
	:CHR_BKSL:chr_escp
# Default
	:CHR_DEFL:chr_copy

# Comment jump table
:cjumptbl
	:CHR_EOF_:chr_eof_
	:CHR_NL__:chr_nl__
# Default
	:CHR_DEFL:chr_ignr

# Read/dispatch function
:mainloop
	= 10
	=$0 :jumptabl
	@call:store32_

:contloop
# Read a char
	@call:readone_
# Look up how to handle it from the current table
	= 10
	=$0 :jumptabl
	@call:load32__
	= 20

# R1 holds the current character
# R2 holds the current search address
.loop1___
	= 02
	@call:load32__
	= 30
	+ 2d
	= 02
	@call:load32__
	= 40
	+ 2d
	= 01

# If we found a match, jump to the address
	?=13
	J?4 
# If we ran out of table entries, jump to the default
	=$x :CHR_DEFL
	?=3x
	J?4 
	@jump.loop1___

# Process newline (\n)
:chr_nl__
# Move the parser into the default mode
	=$0 :mjumptbl
	@jump:mainloop

# Process comment (#)
:chr_cmnt
# Move the parser into the comment mode
	=$0 :cjumptbl
	@jump:mainloop

# Process assembler line (tab)
:chr_assm
# Move the parser into the assembler mode
	=$0 :linebuf_
	=#2 0020
	@call:memzro16
	=$0 :linebufo
	= 1a
	@call:store32_
	=$0 :ajumptbl
	@jump:mainloop

# Process newline (\n)
:chr_nla_
# Move the parser into the default mode
	@call:dolinebf
	=$0 :mjumptbl
	@jump:mainloop

# Copy a char
:chr_copy
	@call:copyone_
	@jump:contloop

# Ignore a char
:chr_ignr
	@jump:contloop

# Backslash escape
:chr_escp
	@call:read8___
	= 10
	=$0 :charbuf_
	@call:store8__
	@call:copyone_
	@jump:contloop

# Process label (:)
:chr_lblg
	=$0 :currlocl
	= 1a
	@call:store16_
	@call:readlabl
	= 10
	=$0 :currglob
	@call:store16_
	@call:outtell_
	= 10
	=$0 :currpos_
	@call:store16_

	=$0 :symtab__
	=$1 :currglob
	=#2 0003
	@call:rcinsert
	@jump:contloop

:chr_lbll
	@call:readlabl
	= 10
	=$0 :currlocl
	@call:store16_
	@call:outtell_
	= 10
	=$0 :currpos_
	@call:store16_

	=$0 :symtab__
	=$1 :currglob
	=#2 0003
	@call:rcinsert
	@jump:contloop

# Process define (=)
:chr_defn
	@call:readlabl
	= 10
	=$0 :currglob
	@call:store16_

	@call:read16__
	= 10
	=$0 :currpos_
	@call:store16_

	=$0 :currlocl
	= 1a
	@call:store16_

	=$0 :symtab__
	=$1 :currglob
	=#2 0003
	@call:rcinsert

# The trailing newline will get handled by the main loop
	=$0 :mjumptbl
	@jump:mainloop

# Write a fixup - assumes label reference is at EOL
:chr_fxpg
	@call:dolinebf
	@call:readlabl
	= 10
	=$0 :fxupglob
	@call:store16_
	=$0 :fxuplocl
	= 1a
	@call:store16_
	@call:outtell_
	= 10
	=$0 :fxuppos_
	@call:store16_

	=$0 :fixuptab
	=$1 :fxupglob
	=#2 0003
	@call:rcinsert

	@call:writeone
	@call:writeone
	@call:writeone
	@call:writeone

	=$0 :mjumptbl
	@jump:mainloop

# Write a fixup - assumes label reference is at EOL
:chr_fxpl
	@call:dolinebf
	=$0 :currglob
	@call:load32__
	= 10
	=$0 :fxupglob
	@call:store16_
	@call:readlabl
	= 10
	=$0 :fxuplocl
	@call:store16_
	@call:outtell_
	= 10
	=$0 :fxuppos_
	@call:store16_

	=$0 :fixuptab
	=$1 :fxupglob
	=#2 0003
	@call:rcinsert

	@call:writeone
	@call:writeone
	@call:writeone
	@call:writeone

	=$0 :mjumptbl
	@jump:mainloop

:chr_mcro
	@jump:mainloop

# Exit/cleanup
:chr_eof_
# Walk all fixups
# Fixup is global/local/pos
# Symbol table is global/local/pos
	=$0 :fixuptab
	@call:load32__

.fxuploop
	@psh0
	= 10
# Decrement fixup count by 1
	=$0 :fixuptbl
	@call:load32__
	?=0a
	@jmp?.fxupdone
	- 0b
	= 10
	=$0 :fixuptbl
	@call:store32_
# Search for current fixup
	@pop0
	@psh0
	= 10
	=$0 :symtab__
	=#2 0002
	=#3 0003
	@call:rcsearch
# Print ERROR if symbol not found
	?=0a
	@jmp?:chr_err_
	- 0b
# Locate symbol offset
	=#1 0006
	* 01
	+ 0d
	= 10
	=$0 :symtab__
	@call:load32__
	+ 01
	@call:load16__
# R2 holds the symbol offset
	= 20
	@pop0
	@psh0
	=#1 0004
	+ 01
	@call:load16__
# R3 holds the file offset
	= 30
# Seek to fixup offset
	=$0 :curr_ofd
	@call:load32__
	=$1 :SC_SEEK_
	=$4 :SEEK_SET
	S+1034  
# Write symbol offset
	=$0 :linebuf_
	= 12
	@call:store32_
	=$0 :curr_ofd
	@call:load32__
	=$1 :SC_WRITE
	=$2 :linebuf_
	=#3 0004
	S+1023  
	@pop0
	=#1 0006
	+ 01
	@jump.fxuploop

.fxupdone
	=$a :SC_EXIT_
	=#b 0000
	S ab

# Generic error, try to preserve registers
:chr_err_
	=$a :SC_WRITE
	=#b 0002
	=$c :errmsg__
	=#d 000c
	S+abcd  
	=$a :SC_EXIT_
	=#b 0001
	S ab

:errmsg__
	\0d\0aERROR!\0d\0a\0d\0a

# Dump the contents of the linebuffer before
# we switch to label mode or the next line.
# We'll compare each macro template with linebuf
# and if we find a match, we'll copy the data
# with the replacements.
:dolinebf
# R4: Pointer into macro table
# R5: Offset into linebuf
# R6: Offset into macro pattern
# R9: Parameter ? (?, ^, or (default) space)
# Exit early if empty line
	=$0 :linebufo
	@call:load32__
	?=0a
	@ret?

# Step 1: Identify the matching macro
	=$4 :macros__
.loop____
	= 04
	@call:load32__
	?=0a
	@jmp?.lineerro
	= 60
	=$5 :linebuf_
	= 7a
	= 8a
	=#9 0020
.loop2___
	= 06
	@call:load8___
	?=0a
	@jmp?.success_
	= 10
# Treat NUL in linebuf as space
	= 05
	@call:load8___
	?=0a
	=$2 :CHR_SPAC
	=?02
# Advance both cursors
	+ 5b
	+ 6b
# <= 8, store in :plachldr
	?>1e
	@jmp?.ne_place
	=$2 :plachldr
	+ 21
	- 2b
	= 10
	= 02
	@call:store8__
	@jump.loop2___
.ne_place
# = ?
	=$2 :CHR_QUES
	?!12
	@jmp?.ne_ques_
# If it's a space in linebuf, rewind
	=$2 :CHR_SPAC
	?!02
	@jmp?.eq_ques_
	- 5b
	@jump.loop2___
.eq_ques_
	= 90
	@jump.loop2___
.ne_ques_
# = *
	=$2 :CHR_STAR
	?!12
	@jmp?.ne_star_
# If matched, rewind linebuf by one byte and just copy everything left
	- 5b
	=$0 :linebuf_
	= 15
	- 10
	=$0 :linebufo
	@call:load32__
	- 01
	= 30
	=$0 :curr_ofd
	@call:load32__
	=$1 :SC_WRITE
	= 25
	S+1023  
	@ret.

.ne_star_
	?!01
	@jmp?.next____
	@jump.loop2___

.end2____

.next____
	+ 4e
	@jump.loop____

.success_
	@jump:wrlinebf

.lineerro
	=$0 :linebufo
	@call:load32__
	=$5 :linebuf_
	=$a :SC_WRITE
	=#b 0002
	= c5
	=#d 000a
	S+abcd  
	@jump:chr_err_

# Step 2: Copy the macro into the output line buffer
:wrlinebf
	= 04
	+ 0d
	@call:load32__
	= 40
.loop____
	= 04
	+ 4b
	@call:load8___
	=#1 00fe
	?=01
	@ret?

# <= 8, load from :plachldr
	?>0e
	@jmp?.ne_place
	=$2 :plachldr
	+ 02
	- 0b
	@call:load8___
	@jump.ne_ques_
.ne_place
	=#2 00fd
	?!02
	@jmp?.ne_ques_
	= 09
	@jump.ne_ques_
.ne_ques_
	= 10
	=$0 :charbuf_
	@call:store8__
	=$0 :curr_ofd
	@call:load32__
	=$1 :SC_WRITE
	=$2 :charbuf_
	= 3b
	S+1023  
	@jump.loop____

# \01-\08
:plachldr
	________

# Read a label, returning its string table ID
:readlabl
	=$0 :linebuf_
	=#2 0020
	@call:memzro16
	=$0 :linebuf_
	=#1 0001
	+ 01
.loop____
	@psh0
	@call:readone_
	=$1 :CHR_SPAC
	?=01
	@jmp?.end_____
	=$1 :CHR_NL__
	?=01
	@jmp?.end_____
	= 10
	@pop0
	@call:store8__
	=#1 0001
	+ 01
	@jump.loop____
.end_____
	@pop1
# linebuf contains a length-prefixed label now
	=$0 :linebuf_
	- 10
	- 1b
	@call:store8__
	=$0 :stringtb
	=$1 :linebuf_
	=#2 0010
	=#3 0010
	@call:rcsearch
	?=0a
	@jmp?.notfound
	=$1 :linebuf_
	@ret.
.notfound
	=$0 :stringtb
	=$1 :linebuf_
	=#2 0010
	@call:rcinsert
	=$1 :linebuf_
	@ret.

:read8___
	=$0 :curr_ifd
	@call:load32__
	=$1 :SC_READ_
	=$2 .read8buf
	=#3 0002
	S+1023  
	=#0 00
.read8buf
	00
	@ret.

:read16__
	=$0 :curr_ifd
	@call:load32__
	=$1 :SC_READ_
	=$2 .read16bf
	=#3 0004
	S+1023  
	=#0 
.read16bf
	0000
	@ret.

# Read a char into R0
:readone_
	=$0 :curr_ifd
	@call:load32__
	=$1 :SC_READ_
	=$2 :charbuf_
	[=2a
	=#3 0001
	S+1023  
	=$0 :charbuf_
	@call:load8___
	@ret.

# Write the char in R0 to the output
:writeone
	= 10
	=$0 :charbuf_
	@call:store8__
	=$0 :curr_ofd
	@call:load32__
	=$1 :SC_WRITE
	=$2 :charbuf_
	=#3 0001
	S+1023  
	@ret.

:copyone_
	@psh0
	@psh1
	=$0 :linebufo
	@call:load32__
	=$1 :linebuf_
	+ 10
	=$0 :charbuf_
	@call:load8___
	= x0
	= 01
	= 1x
	@call:store8__
	=$0 :linebufo
	@call:load32__
	+ 0b
	= 10
	=$0 :linebufo
	@call:store32_
	@pop1
	@pop0
	@ret.

:charbuf_
	_

:outtell_
	=$0 :curr_ofd
	@call:load32__
	=$1 :SC_SEEK_
	- 22
	=$3 :SEEK_CUR
	S+1023  
	= 01
	@ret.

# Insert a record
# R0: pointer to the record list + len data
# R1: pointer to the record data
# R2: size of record data in WORDs
# Returns
# R0: the index (1-based)
:rcinsert
	@psh0
# R3 has the table data pointer
	@call:load32__
	= 30
# R4 has the table length
	@pop0
	@psh0
	+ 0d
	@psh0
	@call:load32__
	= 40
# Max size
	@pop0
	+ 0d
	@call:load32__
	@psh1
	= 10
# New pointer
	=#0 0002
	* 04
	* 02
	?>01
	@pop1
	@jmp?:overflow
	+ 03
	@psh0
	@call:memcpy16
	@pop0
	@pop0
	+ 0d
	= 14
	=#4 0001
	+ 14
	@call:store32_
	= 01
	@ret.

:overflow
	????
	@jump:chr_err_

# Search for a record by comparing record prefixes
# R0: pointer to the record list + len data
# R1: pointer to the record data
# R2: size of comparison data in WORDs
# R3: size of record data in WORDs
# Returns
# R0: the index (1-based) or 0 if not found
:rcsearch
	@psh0
# R4 has the table data pointer
	@call:load32__
	= 40
# R5 has the table length
	@pop0
	* 3c
	+ 0d
	@call:load32__
	= 50
	= 04
	= 45

# R0: record pointer
# R1: comparison pointer
# R2: comparison length
# R3: record stride
.loop____
# Out of records?
	?=5a
	@jmp?.notfound
# Compare the current record
	@psh0
	@psh1
	@psh2
	@call:memeq16_
	?=0b
	@jmp?.found___
	@pop2
	@pop1
	@pop0

	+ 03
	- 5b
	@jump.loop____
.found___
	@pop2
	@pop1
	@pop0
	- 45
	+ 4b
	= 04
	@ret.
.notfound
	=#0 0000
	@ret.


# Compare r2 WORDs in r0 and r1
# Returns 1 if same, 0 if different 
:memeq16_
	@psh3
.loop____
# Done?
	?=2a
	@jmp?.equal___
	@psh0
	@psh1
	={00
	={11
	?=01
	@pop0
	@pop1
	@jmp^.notequal

	+ 0c
	+ 1c
	- 2b
	@jump.loop____
.equal___
	=#0 0001
	@pop3
	@ret.
.notequal
	=#0 0000
	@pop3
	@ret.

# Copy r2 WORDs from r1 to r0
:memcpy16
	@psh3
.loop____
# Done?
	?=2a
	@jmp?.done____
	@psh1
	={11
	{=01
	@pop1

	+ 0c
	+ 1c
	- 2b
	@jump.loop____
.done____
	@pop3
	@ret.

# Zero r2 dwords at r0
:memzro16
	@psh3
.loop____
# Done?
	?=2a
	@jmp?.done____
	{=0a
	+ 0c
	- 2b
	@jump.loop____
.done____
	@pop3
	@ret.

:getargv_
	=$x :argv____
	=(xx
	* 0d
	+ 0x
	=(00
	@ret.

# R0: Size
:malloc__
	=$x :heap____
	=(xx
	= 1x
	+ 10
	= 0x
	=$x :heap____
	(=x1
	@ret.

# Store R1 in R0
:store32_
	(=01
	@ret.

# Store R1 in R0
:store16_
	{=01
	@ret.

# Store R1 in R0
:store8__
	[=01
	@ret.

# Load R0 from R0
:load32__
	=(00
	@ret.

# Load R0 from R0
:load16__
	- xx
	={x0
	= 0x
	@ret.

# Load R0 from R0
:load8___
	- xx
	=[x0
	= 0x
	@ret.

:argv____
	____

:curr_ifd
	____
:curr_ofd
	____

# The macro table. The statement may contain placeholders (\01, \02, etc)
# which are replaced with the actual parameters when the macro is expanded.
# A '*' will copy the remainder of the data.
:macros__
	:m_data__:M_data__
	:m_mov___:M_mov___
	:m_ldc___:M_ldc___
	:m_ldh___:M_ldh___
	:m_ldb___:M_ldb___
	:m_ldw___:M_ldw___
	:m_ldd___:M_ldd___
	:m_stb___:M_stb___
	:m_stw___:M_stw___
	:m_std___:M_std___
	:m_add___:M_add___
	:m_sub___:M_sub___
	:m_mul___:M_mul___
	:m_div___:M_div___
	:m_mod___:M_mod___
	:m_or____:M_or____
	:m_and___:M_and___
	:m_xor___:M_xor___
	:m_eq____:M_eq____
	:m_ne____:M_ne____
	:m_gt____:M_gt____
	:m_lt____:M_lt____
	:m_push__:M_push__
	:m_pop___:M_pop___
	:m_ret___:M_ret___
	:m_call__:M_call__
	:m_jump__:M_jump__
	:m_jump_n:M_jump_n
	:m_jump_y:M_jump_y
	:m_sys6__:M_sys6__
	:m_sys5__:M_sys5__
	:m_sys4__:M_sys4__
	:m_sys3__:M_sys3__
	:m_sys2__:M_sys2__
	:m_sys1__:M_sys1__
	:m_db_0__:M_db_0__
	:m_dw_0__:M_dw_0__
	:m_dd_0__:M_dd_0__
	\00\00\00\00

# \fe: End of pattern
# \fd: Substitute ?
# \01-\08: Pattern substitutes

:m_data__
	data *\00
:M_data__
	\fe

:m_mov___
	mov? r\01, r\02\00
:M_mov___
	=\fd\01\02\fe

:m_ldc___
	ldc r\01, \00
:M_ldc___
	=$\01 \fe

:m_ldh___
	ldh r\01, \02\03\04\05\00
:M_ldh___
	=#\01 \02\03\04\05\fe

:m_ldb___
	ldb [r\01], r\02\00
:M_ldb___
	=[\01\02\fe

:m_ldw___
	ldw [r\01], r\02\00
:M_ldw___
	={\01\02\fe

:m_ldd___
	ldd [r\01], r\02\00
:M_ldd___
	=(\01\02\fe

:m_stb___
	stb [r\01], r\02\00
:M_stb___
	[=\01\02\fe

:m_stw___
	stw [r\01], r\02\00
:M_stw___
	{=\01\02\fe

:m_std___
	std [r\01], r\02\00
:M_std___
	(=\01\02\fe

:m_add___
	add? r\01, r\02\00
:M_add___
	+\fd\01\02\fe

:m_sub___
	sub? r\01, r\02\00
:M_sub___
	-\fd\01\02\fe

:m_mul___
	mul? r\01, r\02\00
:M_mul___
	*\fd\01\02\fe

:m_div___
	div? r\01, r\02\00
:M_div___
	/\fd\01\02\fe

:m_mod___
	mod? r\01, r\02\00
:M_mod___
	%\fd\01\02\fe

:m_or____
	or? r\01, r\02\00
:M_or____
	|\fd\01\02\fe

:m_and___
	and? r\01, r\02\00
:M_and___
	&\fd\01\02\fe

:m_xor___
	xor? r\01, r\02\00
:M_xor___
	^\fd\01\02\fe

:m_eq____
	eq r\01, r\02\00
:M_eq____
	?=\01\02\fe

:m_ne____
	ne r\01, r\02\00
:M_ne____
	?!\01\02\fe

:m_gt____
	gt r\01, r\02\00
:M_gt____
	?>\01\02\fe

:m_lt____
	lt r\01, r\02\00
:M_lt____
	?<\01\02\fe

:m_push__
	push r\01\00
:M_push__
	- yd(=y\01\fe

:m_pop___
	pop r\01\00
:M_pop___
	=(\01y+ yd\fe

:m_sys1__
	sys r\01\00
:M_sys1__
	S \01 \fe

:m_sys2__
	sys r\01, r\02\00
:M_sys2__
	S \01\02\fe

:m_sys3__
	sys r\01, r\02, r\03\00
:M_sys3__
	S+\01\02\03   \fe

:m_sys4__
	sys r\01, r\02, r\03, r\04\00
:M_sys4__
	S+\01\02\03\04  \fe

:m_sys5__
	sys r\01, r\02, r\03, r\04, r\05\00
:M_sys5__
	S+\01\02\03\04\05 \fe

:m_sys6__
	sys r\01, r\02, r\03, r\04, r\05, r\06\00
:M_sys6__
	S+\01\02\03\04\05\06\fe

:m_jump__
	jump \00
:M_jump__
	=$z \fe

:m_jump_n
	jump^ \00
:M_jump_n
	+?ze=$z \fe

:m_jump_y
	jump? \00
:M_jump_y
	+^ze=$z \fe

:m_ret___
	ret?\00
:M_ret___
	=(xy+\fdyd=\fdzx\fe

:m_call__
	call \00
:M_call__
	- yd=#x 000c+ xz(=yx=$z \fe

:m_db_0__
	db 0\00
:M_db_0__
	\00\fe

:m_dw_0__
	dw 0\00
:M_dw_0__
	\00\00\fe

:m_dd_0__
	dd 0\00
:M_dd_0__
	\00\00\00\00\fe

:linebufo
	____

# Input line buffer
:linebuf_
	________________________________________
	________________________________________
	________________________________________
	________________________________________

:currglob
	\00\00
:currlocl
	\00\00
:currpos_
	\00\00

:fxupglob
	\00\00
:fxuplocl
	\00\00
:fxuppos_
	\00\00

# Symbol table address
# 4-byte global symbol, 4-byte local symbol, 4-byte address
:symtab__
	____
:symtabln
	\00\00\00\00
	:SYMTSIZE

# Fixup table address
# 4-byte global symbol, 4-byte local symbol, 4-byte address
:fixuptab
	____
:fixuptbl
	\00\00\00\00
	:FXUPSIZE

# The string table
# 1 byte length, 31 bytes symbol
:stringtb
	____
:strngtln
	\00\00\00\00
	:STTBSIZE

:heap____
	:scratch_

:scratch_
