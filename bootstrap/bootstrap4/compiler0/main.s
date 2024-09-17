# Stage 0 compiler: we want to get enough C that we can move out of assembly land

#include "regs.h"
#include "../bootstrap4/lex/lex.h"

#define BUFFER_SIZE 256

# Track global identifiers
:_global_symbols
	dd 0

:_track_global
	%arg global
	%arg size
	%local ht
	ld.d @ht, [:_global_symbols]
	# Make a copy and insert it into the globals hash table
	%call :_stralloc, @global
	mov @global, @ret
	%call :_ht_insert, @ht, @global, @size
	%ret

:_is_global
	%arg global
	%local ht
	ld.d @ht, [:_global_symbols]
	%call :_ht_lookup, @ht, @global
	%ret

# Track local identifiers
:_local_symbols
	dd 0

:_track_local
	%arg local
	%arg size
	%local ht
	ld.d @ht, [:_local_symbols]
	# Make a copy and insert it into the locals hash table
	%call :_stralloc, @local
	mov @local, @ret
	%call :_ht_insert, @ht, @local, @size
	%ret

:_is_local
	%arg local
	%local ht
	ld.d @ht, [:_local_symbols]
	%call :_ht_lookup, @ht, @local
	%ret

:_teardown_locals
	# Leaks locals because we don't have a proper heap yet
	mov @tmp0, 0
	st.d [:_local_symbols], @tmp0
	%ret

:_main
	%arg argc
	%arg argv
	%local buf1
	%local buf2
	%local token
	%local ll
	%local node
	%local lex
	%local file
	%local args
	%local output
	%local size

# Allocate a 256-byte buffer
	%call :_malloc, @BUFFER_SIZE
	mov @buf1, @ret
	%call :_malloc, @BUFFER_SIZE
	mov @buf2, @ret

# Create the globals hash table
	%call :_ht_init, :__lex_hash_table_test_key_hash, :__lex_hash_table_test_key_compare
	st.d [:_global_symbols], @ret

# Create the include list
	%call :_ll_init
	mov @ll, @ret
	%call :_ll_create_node_int, &"bootstrap/bootstrap4"
	mov @node, @ret
	%call :_ll_insert_head, @ll, @node

# Create the lex environment
	%call :__lex_create, @ll
	mov @lex, @ret

# Open a file
	mov @args, @argv

	# Get argv[1] - the file the open
	add @args, 4
	ld.d @file, [@args]

	# Get argv[2] - the output file
	add @args, 4
	ld.d @output, [@args]
	%call :_compiler_out_open, @output

	%call :_compiler_out, &"# %s\n", @file
	%call :_compiler_out, &"#include \"regs.h\"\n"
	%call :__lex_open, @lex, @file
	mov @file, @ret

.loop
	%call :_lex_peek, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret

	eq @token, @TOKEN_EOF
	jump? .done

	eq @token, @TOKEN_EXTERN
	jump? .extern

	# We only support int functions for this basic parser
	%call :_compile_function_type, @file, @buf1, @BUFFER_SIZE
	mov @size, @ret

	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret
	eq @token, @TOKEN_IDENTIFIER
	jump^ .error

	%call :_compiler_out, &"# global %s\n:%s\n", @buf1, @buf1

	%call :_lex_peek, @file, 0, 0
	eq @ret, '('
	jump? .fn

	eq @ret, '='
	jump? .inited
	eq @ret, '['
	jump? .equal

	%call :_track_global, @buf1, @size
	%call :_compiler_out, &"    dd 0\n"
    %call :_compiler_read_expect, @file, @buf1, @BUFFER_SIZE, ';'
	jump .loop

.equal
	mov @size, 4
    %call :_compiler_read_expect, @file, 0, 0, '['
    %call :_compiler_read_expect, @file, 0, 0, ']'

.inited
	%call :_track_global, @buf1, @size
    %call :_compiler_read_expect, @file, 0, 0, '='
	%call :_compile_constant, @file, @buf1, @BUFFER_SIZE, @size
    %call :_compiler_read_expect, @file, @buf1, @BUFFER_SIZE, ';'
	jump .loop

.extern
	# extern (type) (identifier);
    %call :_compiler_read_expect, @file, @buf1, @BUFFER_SIZE, @TOKEN_EXTERN
	%call :_compile_function_type, @file, @buf1, @BUFFER_SIZE
	mov @size, @ret
	%call :_lex, @file, @buf1, @BUFFER_SIZE
	%call :_track_global, @buf1, @size
    %call :_compiler_read_expect, @file, @buf1, @BUFFER_SIZE, ';'
	jump .loop


.fn
	%call :_track_global, @buf1, @size
	%call :_ht_init, :__lex_hash_table_test_key_hash, :__lex_hash_table_test_key_compare
	st.d [:_local_symbols], @ret
	%call :_compile_function_args, @file, @buf1, @BUFFER_SIZE
	%call :_compiler_out, &"    %%arg arg0\n"
	%call :_compiler_out, &"    %%arg arg1\n"
	%call :_compiler_out, &"    %%arg arg2\n"
	%call :_compiler_out, &"    %%arg arg3\n"
	%call :_compiler_out, &"    %%arg arg4\n"
	%call :_compiler_out, &"    %%arg arg5\n"
	%call :_compiler_out, &"    %%arg arg6\n"
	%call :_compiler_out, &"    %%arg arg7\n"
	%call :_compile_block, @file, @buf1, @BUFFER_SIZE
	%call :_compiler_out, &"    %%ret\n"
	%call :_teardown_locals
	jump .loop

.done
	%call :_compiler_out, &"# EOF\n"
	mov @ret, 0
	%ret

.error
	%call :_compiler_out, &"# Error\n"
	mov @ret, 1
	%ret
