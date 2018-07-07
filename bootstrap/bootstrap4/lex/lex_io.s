#include "regs.h"

#===========================================================================
# lex* _lex_create(ll_head* include_dirs)
#
# Creates a lexer environment.
#===========================================================================
:__lex_create
	%arg include_dirs
	%call :_malloc, 4
	st.w [@ret], @include_dirs
	%ret

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
	# Parent pointer
	st.w [@file], 0
	# fd
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
# int _lex_read(lex_file* file)
#
# Reads a char or -1 for EOF.
#===========================================================================
:__lex_read

#===========================================================================
# int _lex_mark(lex_file* file)
#
# Marks the current position in the stream
#===========================================================================
:__lex_mark
	%ret

#===========================================================================
# void _lex_rewind(lex_file* file, int pos)
#
# Rewinds to the marked position
#===========================================================================
:__lex_rewind
	%ret
