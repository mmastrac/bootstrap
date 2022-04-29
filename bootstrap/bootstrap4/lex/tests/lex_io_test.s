#include "regs.h"
#include "../bootstrap4/lex/lex.h"

:_lex_io_test
	dd &"lex_io"
	dd :_lex_io_test_create, &"test_create"
	dd :_lex_io_test_read_peek, &"test_read_peek"
	dd :_lex_io_test_macro, &"test_macro"
	dd 0, 0

:_lex_io_test_create
	%local lex
	%local file

	# Create the lexer
	%call :__lex_test_create_lex
	mov @lex, @ret

	# Open a file
	%call :__lex_open, @lex, &"bootstrap/bootstrap4/lex/tests/c/test.c"
	mov @file, @ret

	%call :__lex_read, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'i', @tmp0, &"Expected first char to be 'i'"

	%ret

:_lex_io_test_read_peek
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
	st.w [@node], &"bootstrap/bootstrap4/compiler0/tests/lex_io_test"
	%call :_ll_insert_head, @ll, @node

	# Create the lex environment
	%call :__lex_create, @ll
	mov @lex, @ret

	# Open a file
	%call :__lex_open, @lex, &"bootstrap/bootstrap4/lex/tests/c/test.c"
	mov @file, @ret

	%call :__lex_peek, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'i', @tmp0, &"Expected first peek to be 'i'"

	%call :__lex_read, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'i', @tmp0, &"Expected first char to be 'i'"

	%call :__lex_peek, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'n', @tmp0, &"Expected second peek to be 'n'"

	%call :__lex_read, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'n', @tmp0, &"Expected second char to be 'n'"

	%ret

:_lex_io_test_macro
	%local ll
	%local lex
	%local file

	# Create the include list
	%call :_ll_init
	mov @ll, @ret

	# Open a file (required to define a macro - this probably needs to be fixed)
	%call :__lex_open, @lex, &"bootstrap/bootstrap4/lex/tests/c/test.c"
	mov @file, @ret

	# Create the lex environment
	%call :__lex_create, @ll
	mov @lex, @ret

	%call :__lex_define_macro, @file, &"macro1", &"hello world"
	%call :__lex_define_macro, @file, &"macro2", &"abc"

	%call :__lex_activate_macro, @file, &"macro2"


	%call :__lex_peek, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'a', @tmp0, &"Expected first peek to be 'a'"

	%call :__lex_read, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'a', @tmp0, &"Expected first char to be 'a'"

	%call :__lex_peek, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'b', @tmp0, &"Expected second peek to be 'b'"

	%call :__lex_read, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'b', @tmp0, &"Expected second char to be 'b'"

	%call :__lex_peek, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'c', @tmp0, &"Expected third peek to be 'c'"

	%call :__lex_read, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'c', @tmp0, &"Expected third char to be 'c'"

	%call :__lex_peek, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, @TOKEN_EOT, @tmp0, &"Expected fourth peek to be EOT"

	%call :__lex_read, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, @TOKEN_EOT, @tmp0, &"Expected fourth char to be EOT"

	%call :__lex_peek, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'i', @tmp0, &"Expected fifth peek to be 'i'"

	%call :__lex_read, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'i', @tmp0, &"Expected fifth char to be 'i'"

	%ret
