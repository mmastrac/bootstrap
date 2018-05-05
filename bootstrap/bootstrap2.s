# Third stage bootstrap
# Line prefix determines behavior:
#   '#': Comment
#   ':': Set write address to hex 'abcd'
#   'tab': Assemble chars until a newline
#   'newline': Blank line, skipped
#
# Implements an assembler that supports two-pass labels (8-char long only)

# TODO:
#   - Avoid using so many registers (future planned register symbol 
#     re-allocation) - maybe a lookup func?
#		- =$x symb / call would look up "symb"
#   - Backslash for hex escape (ie: \2e -> period, \00 -> null)

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

# RA = Exit/cleanup address
	=#A 0900
# RB = Input line buffer base address
	=#B 2000
# RC = Symbol table address
	=#C 3000
# RD = Symbol table length
	- DD
# RE = Fixup table address
	=#E 8000
# RF = Fixup table length
	- FF
# RG = Main loop address (ie: read/process a line)
	=#G 0200
# RI = Current offset in output (used for fixup)
	=#I 0000
# RJ = Error handler
	=#J 0f00
# RK = Line number
	- KK
# RL = Last global symbol (high word)
	- LL
# RM = Last global symbol (low word)
	- MM

# Get argv at $5000
	=#0 0005
	=#1 5000
	=#2 1000
	S+012   

# Open argv[1] as r/o in R8 (input)
	=#1 5004
	=(11
	=#8 0000
	S 81

# Open argv[2] as r/w in R9 (output)
	=#1 5008
	=(11
	=#2 0602
	=#9 0000
	S+912   

# Set the table to the main table
	=#0 0100
	=#1 0170
	(=01

# Jump to main loop
	= 0G
	J G 

# Character jump table
# Labels allow a small amount of indirection
:0100
# Pointer to current table
	....
# Label lookup
	err_:0f00
	nl__:0300
	cmnt:0320
	assm:0340
	copy:0360
	ignr:0380
	labl:0400
	defn:0500
	escp:03a0
	fixp:0700
	mcro:0800
	eof_:0900

# Main jump table
:0170
	00:eof_
	09:assm
	0a:nl__
	23:cmnt
	2e:labl
	3a:labl
	3d:defn
# Default
	ff:err_

# Assembler jump table
:01a8
	00:eof_
	0a:nl__
	2e:fixp
	3a:fixp
	40:mcro
	5c:escp
# Default
	ff:copy

# Comment jump table
:01e0
	00:eof_
	0a:nl__
# Default
	ff:ignr

# Read/dispatch function
# This is the heart of the parser so it has some hand-linked jumps
:0200
# Read a char
	=#0 0001
	= 1B
	[=1a
	=#2 0001
	S+0812  

# Load the character we just read
	=[01

# Look up how to handle it from the current table
	=#1 0100
	=(11

#:loop1 (:0230)
# Load the two bytes into r2 by overwriting the instruction
	={31
	=#2 0246
	{=23
	=#2 00??
# Skip the colon
	+ 1b
	+ 1c
	?=20
	=#x 0280
	J?x 
	=#3 00ff
	?=32
	J?x 
# Add four to skip the label
	+ 1d
# Restart the loop
	=#x 0230
	J x 

#:found1 (:0280)
	=(21
# Now look up the label
	=#1 0104

#:loop2 (:028c)
	=(31
# Skip the colon
	+ 1b
	+ 1d
	?=32
	=(31
	+ 1d
	=#x 028c
	J^x 

# Load the address for the label and jump to it
	=#1 02c0
	(=13
	=#1 ????
	J 1 

# Process newline (\n)
:0300
# Move the parser into the default mode
	=#0 0100
	=#1 0170
	(=01
# Increment current line
	+ Kb
	J G 

# Process comment (#)
:0320
# Move the parser into the comment mode
	=#0 0100
	=#1 01e0
	(=01
	J G 

# Process assembler line (tab)
:0340
# Move the parser into the assembler mode
	=#0 0100
	=#1 01a8
	(=01
	J G 

# Copy a char
:0360
	=#0 0002
	= 1B
	=#2 0001
	S+0912  
	+ Ib

# Ignore a char
:0380
	J G 

# Backslash escape
:03a0
# Read two bytes to the input buffer
	=#2 0001
	S+28Bc  
# Load into zero
	={0B
	=#1 03c6
	{=10
	=#0 00??
	[=B0
	=#x 0360
	J x 

# Process label (:)
:0400
# Set flag if this is a global label
	=#1 003a
	?=10

# Load the current symbol table address
	= 1C
	+ 1D

# Read 8 bytes to the input buffer
	=#2 0001
	= 3B
	=#4 0008
	S+2834  

# Load symbol into 2/3
	= 2B
	=(22
	+ 3d
	=(33

# 4/5/6/7 become global/local
	=?42
	=?53
	=?6a
	=?7a
	=^4L
	=^5M
	=^62
	=^73

# Write 4/5/6/7
	(=14
	+ 1d
	(=15
	+ 1d
	(=16
	+ 1d
	(=17
	+ 1d
	+ De
	+ De

# Write current file address
	(=1I
	+ Dd

# If this is a global label, update the last global label
	=?L2
	=?M3

# The trailing newline will get handled by the main loop
	J G 

# Process define (=)
:0500
# Read 8 bytes to current symbol table address
	=#0 0001
	= 1C
	+ 1D
	=#2 0008
	S+0812  
# Treat this as a global label
	=(L1
	+ 1d
	=(M1
	+ 1d
	+ De
# Defines don't have local symbols
	+ De
	+ 1e
# Read five bytes (ie: space and value) and overwrite the instruction after the syscall
	=#0 0001
	=#2 055f
	=#3 0005
	S+0823  
	=#6 ????
# Write this constant to the symbol table too
	(=16
# Add 4 to symbol table address
	+ Dd
# The trailing newline will get handled by the main loop
	J G 


# Write a fixup for a global (:) or local (.) - assumes label reference is at EOL
:0700
# Set flag if this is a global label
	=#1 003a
	?=01

# Load the current fixup table address
	= 1E
	+ 1F

# Write fixup address
	(=1I
	+ 1d
	+ Fd

# Read 8 bytes to the input buffer
	=#2 0001
	= 3B
	=#4 0008
	S+2834  

# Load symbol into 2/3
	= 2B
	=(22
	+ 3d
	=(33

# 4/5/6/7 become global/local
	=?42
	=?53
	=?6a
	=?7a
	=^4L
	=^5M
	=^62
	=^73

# Write 4/5/6/7
	(=14
	+ 1d
	(=15
	+ 1d
	(=16
	+ 1d
	(=17
	+ 1d
	+ Fe
	+ Fe

# Writes four zero bytes to output (placeholders at this point)
	=#0 0002
	=#2 0004
	S+0912  

# Increment file offset (+4)
	+ Id

# The trailing newline will get handled by the main loop
	J G 

# Process macro within assember line (@)
:0800
# Read 4 chars for macro
	=#0 0001
	= 1B
	=#2 0004
	S+0812  
	=(21

	=#1 0880
	=#4 1000
	=#5 0020
	=#6 0850
	J 6 

# Loop over macro defs until we read a zero
:0850
	= 04
	=(30
	?=23
	J?1 
	+ 45
	?!3a
	J?6 

# Error
	J J 

:0880
# Write the macro bytes (reading the size from the macro itself)
	+ 0d
	=(30
	=#4 0898
	(=43
	=#2 ????
	+ 0d
	=#1 0002
	S+1902  
# Mark # of bytes output
	+ I2
# Continue processing assembler
	J G 

# Exit/cleanup
:0900
	=(2E
	+ Ed

# If we read a nul, means done/normal exit
	?=2a
	=#0 0007
	- 11
	S?01

# Seek to fixup
	=#0 0003
	S+092a  

# Global symbol (0/1)
	=(0E
	+ Ed
	=(1E
	+ Ed

# Local symbol (2/3)
	=(2E
	+ Ed
	=(3E
	+ Ed

# Search symbol table
	= 6C
	=#x 0960
	J x 

# Symbol search loop
:0960
# Load first dword
	=(46

# Zero global symbol means error
	?=4a
	=#x 09f0
	J?x 

# Diff with current symbol
	+ 6d
	- 40
	= 54
	=(46
	+ 6d
	- 41
	| 54
	=(46
	+ 6d
	- 42
	| 54
	=(46
	+ 6d
	- 43
	| 54

# If we don't have the right symbol, keep going
	?>5a
	=#x 0960
	+?6d
	J?x 

# Write address/value
	=#0 0002
	S+096d  
	+ 6d

# Next fixup
	=#x 0900
	J x 

:09f0
# Dump the symbol to stderr for debugging
	- Ee
	- Ee
	=#2 0002
	=#3 0002
	=#4 0010
	S+23E4  
	J J 


# Generic error, try to preserve registers
:0f00
	=#a 0002
	=#b 0002
	=#c 0ff0
	=#d 0006
	S+abcd  
	=#a 0007
	=#b 0001
	S ab

:0ff0
	ERROR!  

# Macros
# These could be defined in the next stage compiler, but we'll hard-code them
# for now to avoid adding more code in here
:1000
	ret.000c=(xy+ yd= zx
:1020
	ret?000c=(xy+?yd=?zx
:1040
	jump0004=$z 
:1060
# Conditional jump - works by skipping jump instruction if flag not set
	jmp?0008+^ze=$z 
:1080
	jmp^0008+?ze=$z 
:10a0
# Add 12 to the current address and push that as our return.
# This is not super-efficient as a call pattern but at this point
# in our bootstrap we don't care.
#
# sub sp, 4
# mov tmp, pc
# add tmp, 12
# mov [sp], tmp
# mov pc, address
	call0018- yd=#x 000c+ xz(=yx=$z 
# Support for push/pop for r0-r3
:10c0
	psh00008- yd(=y0
:10e0
	pop00008=(0y+ yd
:1100
	psh10008- yd(=y1
:1120
	pop10008=(1y+ yd
:1140
	psh20008- yd(=y2
:1160
	pop20008=(2y+ yd
:1180
	psh30008- yd(=y3
:11a0
	pop30008=(3y+ yd
:11c0
	ret^000c=(xy+^yd=^zx

# Input line buffer
:2000

# Symbol table
# 8-byte global symbol, 8-byte local symbol, 4-byte address
:3000

# Fixup table
:8000
