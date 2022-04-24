#include "regs.h"
#include "syscall.h"
#include "../bootstrap4/lex/lex.h"

:__lex_hash_table_test_key_compare
	%arg a
	%arg b
	%call :_streq, @a, @b
	%ret

:__lex_hash_table_test_key_hash
	%arg key
	%call :_strhash, @key
	%ret

#===========================================================================
# lex* _lex_create(ll_head* include_dirs)
#
# Creates a lexer environment.
#===========================================================================
:__lex_create
	%arg include_dirs
	%local lex

	%call :_malloc, 4
	mov @lex, @ret
	st.w [@lex], @include_dirs

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
	%local ll
	%local node

	%call :_malloc, 16
	mov @file, @ret

	# Include/macro linked list
	%call :_ll_init
	mov @ll, @ret
	st.d [@file], @ll

	# This file becomes the first node
	%call :_ll_create_node, 16
	mov @node, @ret

	# Offset (@0)
	mov @tmp0, @node
	st.d [@tmp0], 0

	# fd (@4)
	%call :_open, @name, 0
	mov @tmp0, @node
	add @tmp0, 4
	st.d [@tmp0], @ret

	# Read function (@8)
	mov @tmp0, @node
	add @tmp0, 8
	st.d [@tmp0], :__lex_read_fd

	# Peek function (@12)
	mov @tmp0, @node
	add @tmp0, 12
	st.d [@tmp0], :__lex_peek_fd

	%call :_ll_insert_head, @ll, @node

	# Allocate a hash table for the macros
	%call :_ht_init, :__lex_hash_table_test_key_hash, :__lex_hash_table_test_key_compare
	mov @tmp0, @file
	add @tmp0, 4
	st.d [@tmp0], @ret

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
# Read function for fd-based source
#===========================================================================
:__lex_read_fd
	%arg fd
	%arg offset

	%call :syscall4, @SC_READ, @fd, .buffer, 1

	eq @ret, 0
	mov? @ret, @TOKEN_EOF
	%ret?

	ld.b @ret, [.buffer]
	%ret

.buffer
	db 0
#===========================================================================


#===========================================================================
# Read function for fd-based source
#===========================================================================
:__lex_peek_fd
	%arg fd
	%arg offset

	%call :syscall4, @SC_READ, @fd, .buffer, 1

	eq @ret, 0
	mov? @ret, @TOKEN_EOF
	%ret?

	# Seek back over that read
	%call :syscall4, @SC_SEEK, @fd, -1, @SEEK_CUR

	ld.b @ret, [.buffer]

	%ret

.buffer
	db 0
#===========================================================================


#===========================================================================
# Read function for macro-based source
#===========================================================================
:__lex_read_macro
	%arg fd
	%arg offset

	add @fd, @offset
	ld.b @tmp0, [@fd]

	# End of macro?
	eq @tmp0, 0
	mov? @ret, @TOKEN_EOF
	%ret?

	mov @ret, @tmp0
	%ret
#===========================================================================


#===========================================================================
# int _lex_read(lex_file* file)
#
# Reads a char or -1 for EOF.
#===========================================================================
:__lex_read
	%arg file
	%local ll
	%local fd
	%local offset
	%local read_fn
	%local node

	ld.d @ll, [@file]

.reread
	%call :_ll_get_head, @ll
	mov @node, @ret

	# If nothing left on the read stack, return EOF (-1)
	eq @ret, 0
	mov? @ret, @TOKEN_EOF
	%ret?

	ld.d @offset, [@ret]
	add @ret, 4
	ld.d @fd, [@ret]
	add @ret, 4
	ld.d @read_fn, [@ret]

	%call @read_fn, @fd, @offset

	# push @ret
	# mov @tmp0, @ret
	# %call :_quicklog, &"Read: %x %c\n", @tmp0, @tmp0
	# pop @ret

	ne @ret, @TOKEN_EOF
	add? @offset, 1
	st.d? [@node], @offset
	%ret?

	# We hit EOF on that particular file/macro, so return EOT and pop a step
	%call :_ll_remove_head, @ll
	# %call :_quicklog, &"Read: EOT\n"
	mov @ret, @TOKEN_EOT
	%ret

.buffer
	db 0
#===========================================================================


#===========================================================================
# int _lex_peek(lex_file* file)
#
# Reads a char or -1 for EOF.
#===========================================================================
:__lex_peek
	%arg file
	%local ll
	%local fd
	%local offset
	%local peek_fn
	%local node

	ld.d @ll, [@file]

.reread
	%call :_ll_get_head, @ll
	mov @node, @ret

	# If nothing left on the read stack, return EOF (-1)
	eq @ret, 0
	mov? @ret, @TOKEN_EOF
	%ret?

	ld.d @offset, [@ret]
	add @ret, 4
	ld.d @fd, [@ret]
	add @ret, 8
	ld.d @peek_fn, [@ret]

	%call @peek_fn, @fd, @offset

	# push @ret
	# mov @tmp0, @ret
	# %call :_quicklog, &"Peek: %x %c\n", @tmp0, @tmp0
	# pop @ret

	ne @ret, @TOKEN_EOF
	%ret?

	# We hit EOF on that particular file/macro, so return EOT
	# %call :_quicklog, &"Peek: EOT\n"
	mov @ret, @TOKEN_EOT
	%ret

.buffer
	db 0
#===========================================================================


#===========================================================================
# void _lex_define_macro(lex_file* file, char* name, char* value)
#
# Defines a lazily-parsed macro for the given name
#===========================================================================
:__lex_define_macro
	%arg fd
	%arg name
	%arg value
	%local ht

	add @fd, 4
	ld.d @ht, [@fd]

	%call :_ht_insert, @ht, @name, @value

	%ret
#===========================================================================


#===========================================================================
# int _lex_activate_macro(lex_file* file, char* name)
#
# Activates a macro, which means we'll parse that through full before
# returning to reading the file. Will return non-zero if successful.
#===========================================================================
:__lex_activate_macro
	%arg fd
	%arg name
	%local ht
	%local value
	%local ll
	%local node

	mov @tmp0, @fd
	add @tmp0, 4
	ld.d @ht, [@tmp0]

	%call :_ht_lookup, @ht, @name
	mov @value, @ret

	eq @value, 0
	mov? @ret, 0
	%ret?

	# Activate macro
	ld.d @ll, [@fd]

	%call :_ll_create_node, 16
	mov @node, @ret

	# Offset (@0)
	mov @tmp0, @node
	st.d [@tmp0], 0

	# Macro value (@4)
	mov @tmp0, @node
	add @tmp0, 4
	st.d [@tmp0], @value

	# Read function (@8)
	mov @tmp0, @node
	add @tmp0, 8
	st.d [@tmp0], :__lex_read_macro

	# Peek function (@12)
	mov @tmp0, @node
	add @tmp0, 12
	st.d [@tmp0], :__lex_read_macro

	%call :_ll_insert_head, @ll, @node

	mov @ret, 1
	%ret
