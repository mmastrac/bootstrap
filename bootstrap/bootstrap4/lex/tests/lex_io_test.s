#include "regs.h"

:_lex_io_test
	dd &"lex_io"
	dd :_lex_io_test_create, &"test_create"
	dd :_lex_io_test_mark, &"test_mark"
	dd 0, 0

:_lex_io_test_create
	%local lex
	%local file

	# Create the lexer
	%call :__lex_test_create_lex
	mov @lex, @ret

	# Open a file
	%call :__lex_open, @lex, &"bootstrap/bootstrap4/lex/tests/lex_io_test/test.c"
	mov @file, @ret

	%call :__lex_read, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'i', @tmp0, &"Expected first char to be 'i'"

	%ret

:_lex_io_test_mark
	%local ll
	%local node
	%local lex
	%local file
	%local mark1
	%local mark2

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

	%call :__lex_mark, @file
	mov @mark1, @ret

	%call :__lex_read, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'i', @tmp0, &"Expected first char to be 'i'"

	%call :__lex_mark, @file
	mov @mark2, @ret

	%call :__lex_read, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'n', @tmp0, &"Expected second char to be 'n'"

	%call :__lex_rewind, @file, @mark2

	%call :__lex_read, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'n', @tmp0, &"Expected second char to be 'n' (second read)"

	%call :__lex_rewind, @file, @mark1

	%call :__lex_read, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'i', @tmp0, &"Expected first char to be 'i' (second read)"

	%ret
