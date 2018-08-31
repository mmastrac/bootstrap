#include "regs.h"
#include "../bootstrap4/lex/lex.h"

#define BUFFER_SIZE 256

:_lex_test
	dd &"lex"
	dd :_lex_test_tokens, &"test_tokens"
	dd 0, 0

:_lex_test_tokens_expected
	dd @TOKEN_INT
	dd &"int"
	dd @TOKEN_IDENTIFIER
	dd &"main"
	dd '('
	dd &"("
	dd ')'
	dd &")"
	dd '{'
	dd &"{"
	dd @TOKEN_RETURN
	dd &"return"
	dd @TOKEN_IDENTIFIER
	dd &"i"
	dd @TOKEN_INC_OP
	dd &"++"
	dd ';'
	dd &";"
	dd '}'
	dd &"}"
	dd @TOKEN_EOF
	dd &""
	dd 0


:_lex_test_tokens
	%local ll
	%local node
	%local lex
	%local file
	%local buf
	%local next_token

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

	mov @next_token, :_lex_test_tokens_expected

.loop
	%call :_lex, @file, @buf, @BUFFER_SIZE
	mov @tmp1, @ret

	ld.d @tmp0, [@next_token]

	%call :_test_assert_equal, @tmp0, @tmp1, &"Incorrect token"

	add @next_token, 8
	ld.d @tmp0, [@next_token]
	eq @tmp0, 0
	jump^ .loop

	%ret
