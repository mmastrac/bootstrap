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
	# TODO: Not sure why but if I get rid of these locals the test hangs...
	%local unused1
	%local unused2

	%local lex
	%local file
	%local buf
	%local next_token

	# Allocate a 256-byte buffer
	%call :_malloc, @BUFFER_SIZE
	mov @buf, @ret

	# Create the lexer
	%call :__lex_test_create_lex
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

	add @next_token, 4

	ld.d @tmp0, [@next_token]
	%call :_strcmp, @tmp0, @buf

	%call :_test_assert_equal, @ret, 0, &"Incorrect token string"

	add @next_token, 4
	ld.d @tmp0, [@next_token]
	eq @tmp0, 0
	jump^ .loop

	%ret
