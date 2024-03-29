#define OPEN_READ $0
#define OPEN_WRITE $1

#include "regs.h"
#include "syscall.h"

#===========================================================================
# R0: Filename (zero terminated)
# R1: Mode (0 = read, 1 = rw+create)
#===========================================================================
:_open
	%arg filename
	%arg mode
	eq @mode, @OPEN_READ
	jump? .read
# read/write
	mov @tmp1, @O_RDWR
	or @tmp1, @O_CREAT
	or @tmp1, @O_TRUNC
	jump .open
# readonly
.read
	mov @tmp1, @O_RDONLY
.open
	%call :syscall3, @SC_OPEN, @filename, @tmp1
	mov @tmp0, r0
	add @tmp0, $1
	eq @tmp0, $0
	%call? :_fatal, :open_error
	%ret

:open_error
	ds "Failed to open file"
#===========================================================================


#===========================================================================
# R0: Directory (zero terminated)
# R1: Filename (zero terminated)
# R2: Mode (0 = read, 1 = rw+create)
#===========================================================================
:_open2
	%arg directory
	%arg filename
	%arg mode
	%local fd
	eq @mode, @OPEN_READ
	jump? .read
# read/write
	mov @tmp1, @O_RDWR
	or @tmp1, @O_CREAT
	or @tmp1, @O_TRUNC
	jump .open
# readonly
.read
	mov @tmp1, @O_RDONLY
.open
	%call :syscall3, @SC_OPEN, @directory, @O_RDONLY
	mov @fd, r0
	%call :syscall3, @SC_OPENAT, @fd, @filename, @tmp1
	mov @tmp0, r0
	add @tmp0, $1
	eq @tmp0, $0
	%call? :_fatal, :open_error
	%ret

:open_error
	ds "Failed to open file"
#===========================================================================
