# Stage 0 compiler: we want to get enough C that we can move out of assembly land

#include "regs.h"
#include "../bootstrap4/lex/lex.h"

#define BUFFER_SIZE 256

:_counter
	dd 0

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

# Allocate a 256-byte buffer
	%call :_malloc, @BUFFER_SIZE
	mov @buf1, @ret
	%call :_malloc, @BUFFER_SIZE
	mov @buf2, @ret

# Create the include list
	%call :_ll_init
	mov @ll, @ret
	%call :_ll_create_node, 4
	mov @node, @ret
	st.w [@node], &"bootstrap/bootstrap4/compiler0/tests/lex_io_test"
	%call :_ll_insert_head, @ll, @node

# Create the lex environment
	%call :__lex_create, @ll
	mov @lex, @ret

# Open a file
	mov @args, :__argv
	ld.d @args, [@args]

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

	# We only support int functions for this basic parser
	%call :_compile_function_type, @file, @buf1, @BUFFER_SIZE

	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret

	%call :_compiler_out, &"# function %s\n:%s\n", @buf1, @buf1

	eq @token, @TOKEN_IDENTIFIER
	jump^ .error

	%call :_lex, @file, @buf2, @BUFFER_SIZE
	mov @token, @ret

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
	jump .loop

.done
	%call :_compiler_out, &"# EOF\n"
	mov @ret, 0
	%ret

.error
	%call :_compiler_out, &"# Error\n"
	mov @ret, 1
	%ret
