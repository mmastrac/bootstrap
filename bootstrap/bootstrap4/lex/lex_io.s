#include "regs.h"
#include "syscall.h"

#===========================================================================
# lex* _lex_create(ll_head* include_dirs)
#
# Creates a lexer environment.
#===========================================================================
:__lex_create
	%arg include_dirs
	%local lex

	%call :_malloc, 8
	mov @lex, @ret
	st.w [@lex], @include_dirs

	# Allocate a hash table for the macros
	%call :_ht_init, :_strhash, :_streq
	mov @tmp0, @lex
	add @tmp0, 4
	st.w [@tmp0], @ret

	mov @ret, @lex
	%ret
#===========================================================================


#===========================================================================
# lex_file* _lex_open(lex* lex, char* name)
#
# Opens a top-level lexer file.
#===========================================================================
:__lex_open
	%arg lex
	%arg name
	%local file
	%call :_malloc, 12

	# Include linked list (doesn't include current fd)
	%call :_ll_init
	st.w [@file], @ret

	# current fd is cached in the struct
	%call :_open, @name, 0
	mov @tmp0, @file
	add @tmp0, 4
	st.w [@tmp0], @ret

	# mark
	add @tmp0, 4
	st.w [@tmp0], 0
	mov @ret, @file

	%ret
#===========================================================================


#===========================================================================
# lex_file* _lex_open_include(lex* lex, lex_file* parent, char* name)
#
# Opens a lexer file as an include. Returns the same file as parent if
# successful, otherwise 0. Future reads will take place from the include
# file until it reaches EOF (at which time it will return a virtual EOL and
# return to the parent file).
#===========================================================================
:__lex_open_include
	%arg lex
	%arg parent
	%arg name
#===========================================================================


#===========================================================================
# int _lex_read(lex_file* file)
#
# Reads a char or -1 for EOF.
#===========================================================================
:__lex_read
	%arg file
	%local fd

	mov @tmp0, @file
	add @tmp0, 4
	ld.d @fd, [@tmp0]
	%call :syscall4, @SC_READ, @fd, .buffer, 1
	eq @ret, 0
	mov? @ret, -1
	%ret?

	ld.b @ret, [.buffer]
	%ret

.buffer
	db 0
#===========================================================================


#===========================================================================
# int _lex_mark(lex_file* file)
#
# Marks the current position in the stream
#===========================================================================
:__lex_mark
	%arg file
	%local fd

	mov @tmp0, @file
	add @tmp0, 4
	ld.d @fd, [@tmp0]

	%call :syscall4, @SC_SEEK, @fd, 0, @SEEK_CUR

	%ret
#===========================================================================


#===========================================================================
# void _lex_rewind(lex_file* file, int pos)
#
# Rewinds to the marked position
#===========================================================================
:__lex_rewind
	%arg file
	%arg pos
	%local fd

	mov @tmp0, @file
	add @tmp0, 4
	ld.d @fd, [@tmp0]

	%call :syscall4, @SC_SEEK, @fd, @pos, @SEEK_SET

	%ret
#===========================================================================


#===========================================================================
# void _lex_define_macro(lex* lex, char* name, char* value)
#
# Defines a lazily-parsed macro for the given name
#===========================================================================
:__lex_define_macro
	%ret


#===========================================================================
# void _lex_activate_macro(lex* lex, char* name)
#
# Activates a macro, which means we'll parse that through full before
# returning to reading the file.
#===========================================================================
:__lex_activate_macro
	%ret

