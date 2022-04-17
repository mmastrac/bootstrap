#include "regs.h"
#include "../bootstrap4/lex/lex.h"

#define BUFFER_SIZE 256

:_counter
	dd 0

:_main
	%local buf1
	%local buf2
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

# Create the include list
	%call :_ll_init
	mov @ll, @ret
	%call :_ll_create_node, 4
	mov @node, @ret
	st.w [@node], &"bootstrap/bootstrap4/lex/tests/lex_io_test"
	%call :_ll_insert_head, @ll, @node

# Create the lex environment
	%call :__lex_create, @ll
	mov @lex, @ret

# Open a file
	%call :__lex_open, @lex, &"bootstrap/bootstrap4/lex/tests/lex_io_test/test_fib.c"
	mov @file, @ret

.loop
	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret

	eq @token, @TOKEN_EOF
	jump? .done

# We only support int functions/globals for this basic parser
	eq @token, @TOKEN_INT
	jump^ .error

	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret

	eq @token, @TOKEN_IDENTIFIER
	jump^ .error

	%call :_lex, @file, @buf2, @BUFFER_SIZE
	mov @token, @ret

	eq @token, ';'
	jump? .global

	eq @token, '('
	jump? .function

	jump .error

.global
	%call :_dprintf, 1, &":%s\ndd 0\n", @buf1
	jump .loop

.function
	push @buf1
	push @buf1
	%call :_dprintf, 1, &"# function %s\n:_%s\n"
	pop @buf1
	pop @buf1

.function_args
	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret
	eq @token, ')'
	jump? .function_body

	eq @token, @TOKEN_INT
	jump^ .error

	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret
	eq @token, @TOKEN_IDENTIFIER
	jump^ .error

	push @buf1
	%call :_dprintf, 1, &"    %%arg %s\n"
	pop @buf1

	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret
	eq @token, ')'
	jump? .function_body

	eq @token, ','
	jump .function_args

	jump .error

.function_body
	%call :stmts, @file, @buf1
	jump .loop

.error
	%call :_quicklog, &"buf1 = '%s' buf2 = '%s'", @buf1, @buf2
	%call :_fatal, &"Unexpected token"
	mov @ret, 1
	%ret

.done
	mov @ret, 0
	%ret

# Parses a statement, which might be recursive
:stmts
	%arg file
	%arg buf1
	%local token

	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret
	eq @token, '{'
	jump^ .error
	%call :_dprintf, 1, &"# {\n"

.loop
	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret

	eq @token, @TOKEN_INT
	jump? .stmt_local

	eq @token, @TOKEN_IF
	jump? .stmt_if

	eq @token, @TOKEN_RETURN
	jump? .stmt_return

	eq @token, '}'
	jump? .stmt_end

	jump .error

	%ret

.stmt_end
	%call :_dprintf, 1, &"# }\n"
	%ret

.stmt_local
	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret
	eq @token, @TOKEN_IDENTIFIER
	jump^ .error

	push @buf1
	%call :_dprintf, 1, &"    %local %s\n"
	pop @buf1
	jump .loop

.stmt_if
	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret

	eq @token, '('
	jump^ .error

	%call :_dprintf, 1, &"# if\n"

	%call :expr, @file, @buf1

	%call :_dprintf, 1, &"    eq @tmp0, 1\n"
	%call :_dprintf, 1, &"    jump^ .end\n"

	%call :stmts, @file, @buf1

	jump .loop

.stmt_return
	%call :expr, @file, @buf1
	%call :_dprintf, 1, &"    mov @ret, %%tmp0\n"
	%call :_dprintf, 1, &"    %%ret\n"
	jump .loop

.error
	%call :_quicklog, &"buf1 = '%s'", @buf1
	%call :_fatal, &"Unexpected token in stmt"
	mov @ret, 1
	%ret

.done
	mov @ret, 0
	%ret

# Parses a simple expression and puts it into @tmp0
:expr
	%arg file
	%arg buf1
	%local token

	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret

	eq @token, '('
	jump? .paren

	eq @token, @TOKEN_CONSTANT
	jump .go

	# If it isn't a parenthesis or number, we expect an identifier
	eq @token, @TOKEN_IDENTIFIER
	jump^ .error

.go
	push @buf1
	%call :_dprintf, 1, &"    mov @tmp1, %s\n"
	pop @buf1

	# Now which type of expression?
	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret

	eq @token, @TOKEN_EQ_OP
	jump? .eq

	eq @token, '-'
	jump? .minus

	eq @token, ';'
	%ret?

	eq @token, ')'
	%ret?

.eq
	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret
	push @buf1
	%call :_dprintf, 1, &"    eq @tmp1, %s\n"
	pop @buf1
	%call :_dprintf, 1, &"    mov? @tmp0, 0\n"
	%call :_dprintf, 1, &"    mov^ @tmp0, 1\n"
	jump .done

.minus
	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret
	push @buf1
	%call :_dprintf, 1, &"    sub @tmp0, %s\n"
	pop @buf1
	jump .done

.paren
	%call :expr, @file, @buf1

	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret
	eq @token, ')'
	jump^ .error

	%ret

.error
	%call :_quicklog, &"buf1 = '%s'", @buf1
	%call :_fatal, &"Unexpected token in expr"

.done
	%call :_lex, @file, @buf1, @BUFFER_SIZE
	mov @token, @ret
	eq @token, ')'
	jump^ .error
	%ret
