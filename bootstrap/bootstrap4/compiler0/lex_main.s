# Stage 0 compiler: we want to get enough C that we can move out of assembly land

#include "regs.h"
#include "../bootstrap4/lex/lex.h"

#define BUFFER_SIZE 256

:_counter
	dd 0

:_main
	%local buf1
	%local buf2
	%local pending
	%local token
	%local len
	%local ll
	%local node
	%local lex
	%local file

# Allocate a 256-byte buffer
	%call :_malloc, @BUFFER_SIZE
	mov @buf1, @ret
	%call :_malloc, @BUFFER_SIZE
	mov @buf2, @ret
# Pending variable assignment
	%call :_malloc, @BUFFER_SIZE
	mov @pending, @ret

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
	%call :__lex_open, @lex, &"bootstrap/bootstrap4/compiler0/tests/lex_io_test/test_fib.c"
	mov @file, @ret
	%call :_compiler_out, &"# bootstrap/bootstrap4/compiler0/tests/lex_io_test/test_fib.c\n"

.loop
	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret

	eq @token, @TOKEN_EOF
	jump? .done

# We only support int functions for this basic parser
	eq @token, @TOKEN_INT
	jump^ .error

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

.error
	%ret

.done
	%call :_compiler_out, &"# EOF\n"
	%ret
