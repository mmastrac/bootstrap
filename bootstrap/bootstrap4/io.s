

#===========================================================================
# R0: File handle
# R1: Format string
# Stack: printf arguments
#===========================================================================
:_fprintf
	ret

#===========================================================================
# R0: Filename (zero terminated)
# R1: Mode (0 = read, 1 = rw+create)
#===========================================================================
:_open
	eq r1, @OPEN_READ
	jump? .read
# read/write
	mov r3, @O_RDWR
	or r3, @O_CREAT
	or r3, @O_TRUNC
	jump .open
# readonly
.read
	mov r3, @O_RDONLY
.open
	mov @tmp0, @SC_OPEN
	sys @tmp0 r0 r3
	mov r0, @tmp0
	add @tmp0, $1
	eq @tmp0, $0
	mov? r0, :open_error
	jump? :fatal
	pop r3
	ret

:open_error
	ds "Failed to open file"
#===========================================================================


:_rewind


#===========================================================================
# R0: File handle
# Returns:
#   R0: Character (or -1 if EOF)
#===========================================================================
:_read_char
	


#===========================================================================
# R0: File handle
# Returns:
#   R0: Character (or -1 if EOF)
#===========================================================================
:_write_char
	
