#include "regs.h"
#include "syscall.h"
#include "../lex/lex.h"

#define LEX_INCLUDE_DIRS 0
#define LEX_SIZE 4

#define LEX_FILE_LEX 0
#define LEX_FILE_TOKENS 4
#define LEX_FILE_MACROS 8
#define LEX_FILE_PEEK 12
#define LEX_FILE_PEEK_BUFFER 16
#define LEX_FILE_SIZE 144

#define LEX_TOKEN_OFFSET 0
#define LEX_TOKEN_DATA 4
#define LEX_TOKEN_READ_FN 8
#define LEX_TOKEN_PEEK_CHAR 12
#define LEX_TOKEN_SIZE 16

:__lex_hash_table_test_key_cmp
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
	%local token_source_stack

	%call :_malloc, @LEX_SIZE
	mov @lex, @ret
	%call :_store_record, @lex, @LEX_INCLUDE_DIRS, @include_dirs
	mov @ret, @lex
	%ret
#===========================================================================


#===========================================================================
# void _lex_activate(lex_file* lex, int offset, int data, void* read_fn)
#===========================================================================
:__lex_activate
	%arg fd
	%arg offset
	%arg data
	%arg read_fn
	%arg peek_fn
	%local ll
	%local node

	# Activate source
	%call :_load_record, @fd, @LEX_FILE_TOKENS
	mov @ll, @ret
	%call :_ll_create_node, @LEX_TOKEN_SIZE
	mov @node, @ret

	%call :_store_record, @node, @LEX_TOKEN_OFFSET, @offset
	%call :_store_record, @node, @LEX_TOKEN_DATA, @data
	%call :_store_record, @node, @LEX_TOKEN_READ_FN, @read_fn

	%call :_ll_insert_head, @ll, @node

	mov @ret, 1
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
	%local fd

	%call :_open, @name, 0
	mov @fd, @ret
	%call :__lex_open_something, @lex, @fd, :__lex_read_fd
	%ret
#===========================================================================


#===========================================================================
# lex_file* _lex_open_string(lex* lex, char* string)
#
# Opens a top-level string.
#===========================================================================
:__lex_open_string
	%arg lex
	%arg s
	%local fd

	%call :__lex_open_something, @lex, @s, :__lex_read_macro
	%ret
#===========================================================================


#===========================================================================
# lex_file* __lex_open_something(lex* lex, void* read_context, void* read_fn)
#
# Opens a top-level lexer "something" (could be a file or string).
#===========================================================================
:__lex_open_something
	%arg lex
	%arg read_context
	%arg read_fn
	%local file
	%local ll
	%local ht
	%local token_buf
	%local fd

	%call :_malloc, @LEX_FILE_SIZE
	mov @file, @ret

	# Include/macro linked list
	%call :_ll_init
	mov @ll, @ret

	# Allocate a hash table for the macros
	%call :_ht_init, :__lex_hash_table_test_key_hash, :__lex_hash_table_test_key_cmp
	mov @ht, @ret

	%call :_store_record, @file, @LEX_FILE_LEX, @lex
	%call :_store_record, @file, @LEX_FILE_TOKENS, @ll
	%call :_store_record, @file, @LEX_FILE_MACROS, @ht
	%call :_store_record, @file, @LEX_FILE_PEEK, @TOKEN_NONE

	%call :__lex_activate, @file, 0, @read_context, @read_fn

	mov @ret, @file
	%ret
#===========================================================================


#===========================================================================
# void _lex_open_include(lex_file* lex, char* name)
#
# Opens a lexer file as an include. Returns the same file as parent if
# successful, otherwise 0. Future reads will take place from the include
# file until it reaches EOF (at which time it will return a virtual EOL and
# return to the parent file).
#===========================================================================
:__lex_open_include
	%arg file
	%arg name
	%local fd
	%local lex
	%local ll_include

	%call :_load_record, @file, @LEX_FILE_LEX
	mov @lex, @ret
	%call :_load_record, @lex, @LEX_INCLUDE_DIRS
	mov @ll_include, @ret

	%call :_ll_search, @ll_include, :__lex_open_search, @name
	mov @fd, @ret2

	%call :__lex_activate, @file, 0, @fd, :__lex_read_fd
	%ret
#===========================================================================


:__lex_open_search
	%arg node
	%arg data
	ld.d @node, [@node]
	%call :_open2, @node, @data, 0
	mov @ret2, @ret
	%ret


#===========================================================================
# Read function for fd-based source
#===========================================================================
:__lex_read_fd
	%arg fd
	%arg offset

	mov @ret, @SC_READ
	mov @tmp0, .buffer
	mov @tmp1, 1
	sys @ret @fd @tmp0 @tmp1

	eq @ret, 0
	mov? @ret, @TOKEN_EOF
	%ret?

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
	%local node

	%call :_load_record, @file, @LEX_FILE_TOKENS
	mov @ll, @ret
	%call :_ll_get_head, @ll
	mov @node, @ret

	# If nothing left on the read stack, return EOF (-1)
	eq @ret, 0
	mov? @ret, @TOKEN_EOF
	%ret?

	%call :__lex_peek_node, @node
	eq @ret, @TOKEN_EOF
	jump? .eof
	push @ret
	%call :_store_record, @node, @LEX_TOKEN_PEEK_CHAR, 0
	pop @ret
	%ret

.eof
	# We hit EOF on that particular file/macro, so return whitespace and pop a step
	%call :_load_record, @file, @LEX_FILE_TOKENS
	%call :_ll_remove_head, @ll
	#%call :_quicklog, &"Read: EOT\n"
	mov @ret, ' '
	%ret

.buffer
	db 0
#===========================================================================


#===========================================================================
# Read a char from the current head node and places it into the peek char field.
#
# int _lex_read_node(node)
#===========================================================================
:__lex_read_node
	%arg node
	%local fd
	%local offset
	%local read_fn
	%local c

	%call :_load_record, @node, @LEX_TOKEN_OFFSET
	mov @offset, @ret
	%call :_load_record, @node, @LEX_TOKEN_DATA
	mov @fd, @ret
	%call :_load_record, @node, @LEX_TOKEN_READ_FN
	mov @read_fn, @ret

	%call @read_fn, @fd, @offset
	mov @c, @ret
	%call :_store_record, @node, @LEX_TOKEN_PEEK_CHAR, @c

	#%call :_quicklog, &"Read: %x %c\n", @c, @c

	add @offset, 1
	%call :_store_record, @node, @LEX_TOKEN_OFFSET, @offset
	mov @ret, 0
	%ret
#===========================================================================


#===========================================================================
# void* _lex_get_token_buf(lex_file* file)
#
# Returns the associated token buffer from the file.
#===========================================================================
:__lex_get_token_buf
	%arg file
	add @file, @LEX_FILE_PEEK_BUFFER
	mov @ret, @file
	%ret
#===========================================================================


#===========================================================================
# int _lex_get_peek_token(lex_file* file)
#===========================================================================
:__lex_get_peek_token
	%arg file
	%call :_load_record, @file, @LEX_FILE_PEEK
	%ret
#===========================================================================


#===========================================================================
# void _lex_set_peek_token(lex_file* file, int token)
#===========================================================================
:__lex_set_peek_token
	%arg file
	%arg token
	%call :_store_record, @file, @LEX_FILE_PEEK, @token
	%ret
#===========================================================================


#===========================================================================
# int _lex_peek(lex_file* file)
#
# Reads a char or -1 for EOF.
#===========================================================================
:__lex_peek
	%arg file
	%local c
	%local ll
	%local node
	
	%call :_load_record, @file, @LEX_FILE_TOKENS
	mov @ll, @ret
	%call :_ll_get_head, @ll
	mov @node, @ret

	# If nothing left on the read stack, return EOF (-1)
	eq @ret, 0
	mov? @ret, @TOKEN_EOF
	%ret?

	%call :__lex_peek_node, @node
	ne @ret, @TOKEN_EOF
	jump? .ret
	mov @ret, ' '
.ret
	%ret
#===========================================================================


:__lex_peek_node
	%arg node
	%call :_load_record, @node, @LEX_TOKEN_PEEK_CHAR
	ne @ret, 0
	%ret?

	%call :__lex_read_node, @node
	%call :_load_record, @node, @LEX_TOKEN_PEEK_CHAR
	%ret


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

	%call :_load_record, @fd, @LEX_FILE_MACROS
	mov @ht, @ret
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

	%call :_load_record, @fd, @LEX_FILE_MACROS
	mov @ht, @ret
	%call :_ht_lookup, @ht, @name
	mov @value, @ret

	eq @value, 0
	mov? @ret, 0
	%ret?

	#%call :_quicklog, &"macro=%s\n", @name
	%call :__lex_activate, @fd, 0, @value, :__lex_read_macro
	%ret
