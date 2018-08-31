#include "regs.h"

#define BUFFER_SIZE 256

// TODO: move this to a lex.h file
#define TOKEN_INT 		116
#define TOKEN_IDENTIFIER 	133

:_lex_test
	dd &"lex"
	dd :_lex_test_simple, &"test_simple"
	dd 0, 0

:_lex_test_simple
	%local ll
	%local node
	%local lex
	%local file
	%local buf

# Allocate a 256-byte buffer
	%call :_malloc, @BUFFER_SIZE
	mov @buf, @ret

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
	%call :__lex_open, @lex, &"bootstrap/bootstrap4/lex/tests/lex_io_test/test.c"
	mov @file, @ret

	%call :_lex, @file, @buf, @BUFFER_SIZE
	mov @tmp0, @ret
	%call :_test_assert_equal, @TOKEN_INT, @tmp0, &"Expected first token to be 'int'"

	%call :_lex, @file, @buf, @BUFFER_SIZE
	mov @tmp0, @ret
	%call :_test_assert_equal, @TOKEN_IDENTIFIER, @tmp0, &"Expected second token to be an identifier"

	%call :_lex, @file, @buf, @BUFFER_SIZE
	mov @tmp0, @ret
	%call :_test_assert_equal, '(', @tmp0, &"Expected third token to be a left parenthesis"

	%ret
