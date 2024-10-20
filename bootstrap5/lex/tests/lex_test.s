#include "regs.h"
#include "../lex/lex.h"

#define BUFFER_SIZE 256

:_lex_test
	dd :_lex_test_operators, &"test_operators"
	dd :_lex_test_tokens, &"test_tokens"
	dd :_lex_test_tokens_define, &"test_tokens_define"
	dd :_lex_test_tokens_include, &"test_tokens_include"
	dd 0, 0

:_lex_test_operators
	# Need the lex tables initialized
	%call :__lex_init

	%call :__lex_is_valid_operator, &""
	mov @tmp0, @ret
	%call :_test_assert_equal, @tmp0, 0, &"Incorrect token"

	%call :__lex_is_valid_operator, &"+"
	mov @tmp0, @ret
	%call :_test_assert_equal, @tmp0, '+', &"Incorrect token"

	%call :__lex_is_valid_operator, &"-"
	mov @tmp0, @ret
	%call :_test_assert_equal, @tmp0, '-', &"Incorrect token"

	%call :__lex_is_valid_operator, &"a"
	mov @tmp0, @ret
	%call :_test_assert_equal, @tmp0, 0, &"Incorrect token"

	%call :__lex_is_valid_operator, &"++"
	mov @tmp0, @ret
	%call :_test_assert_equal, @tmp0, @TOKEN_INC_OP, &"Incorrect token"

	%call :__lex_is_valid_operator, &"--"
	mov @tmp0, @ret
	%call :_test_assert_equal, @tmp0, @TOKEN_DEC_OP, &"Incorrect token"

	%call :__lex_is_valid_operator, &"+-"
	mov @tmp0, @ret
	%call :_test_assert_equal, @tmp0, 0, &"Incorrect token"

	%ret

# Checks a stream of tokens against what comes out of a file
:__lex_confirm_tokens
	%arg lex
	%arg file
	%arg buf
	%arg next_token

.loop
	%call :_lex_peek, @file, @buf, @BUFFER_SIZE
	mov @tmp1, @ret
	ld.d @tmp0, [@next_token]
	%call :_test_assert_equal, @tmp0, @tmp1, &"Incorrect token during peek"

	%call :_lex, @file, @buf, @BUFFER_SIZE
	mov @tmp1, @ret
	ld.d @tmp0, [@next_token]
	%call :_test_assert_equal, @tmp0, @tmp1, &"Incorrect token"

	add @next_token, 4

	ld.d @tmp0, [@next_token]
	%call :_strcmp, @tmp0, @buf

	# Useful for debugging...
	#push @ret
	#ld.d @tmp0, [@next_token]
	#%call :_quicklog, &"<%s> <%s>\n", @tmp0, @buf
	#pop @ret

	%call :_test_assert_equal, @ret, 0, &"Incorrect token string"

	add @next_token, 4
	ld.d @tmp0, [@next_token]
	eq @tmp0, 0
	jump^ .loop

	%ret

:__lex_confirm_file
	%arg filename
	%arg tokens

	%local lex
	%local file
	%local buf

	# Allocate a 256-byte buffer
	%call :_malloc, @BUFFER_SIZE
	mov @buf, @ret

	# Create the lexer
	%call :__lex_test_create_lex
	mov @lex, @ret

	# Open a file
	%call :__lex_open, @lex, @filename
	mov @file, @ret

	%call :__lex_confirm_tokens, @lex, @file, @buf, @tokens
	%ret


:__lex_test_tokens_expected
	dd @TOKEN_INT
	dd &"int"
	dd @TOKEN_IDENTIFIER
	dd &"main"
	dd '('
	dd &"("
	dd @TOKEN_ELLIPSIS
	dd &"..."
	dd ')'
	dd &")"
	dd '{'
	dd &"{"
	dd @TOKEN_STRING_LITERAL
	dd &"this is a \"string\"!"
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
	%call :__lex_confirm_file, &"bootstrap5/lex/tests/c/test.c", :__lex_test_tokens_expected
	%ret

:__lex_test_tokens_define_expected
	dd @TOKEN_CONSTANT
	dd &"1"
	dd @TOKEN_CONSTANT
	dd &"2"
	dd @TOKEN_CONSTANT
	dd &"3"
	dd 0

:_lex_test_tokens_define
	%call :__lex_confirm_file, &"bootstrap5/lex/tests/c/test_define.c", :__lex_test_tokens_define_expected
	%ret

:__lex_test_tokens_include_expected
	dd @TOKEN_CONSTANT
	dd &"1"
	dd @TOKEN_CONSTANT
	dd &"2"
	dd @TOKEN_CONSTANT
	dd &"3"
	dd 0

:_lex_test_tokens_include
	%call :__lex_confirm_file, &"bootstrap5/lex/tests/c/test_include.c", :__lex_test_tokens_include_expected
	%ret
