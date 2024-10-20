#include "regs.h"
#include "../bootstrap5/lex/lex.h"

:_lex_io_test
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
	%call :__lex_open, @lex, &"bootstrap/bootstrap5/lex/tests/c/test.c"
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
	%call :_ll_create_node_int, &"bootstrap/bootstrap5/lex/tests"
	mov @node, @ret
	%call :_ll_insert_head, @ll, @node

	# Create the lex environment
	%call :__lex_create, @ll
	mov @lex, @ret

	# Open a file
	%call :__lex_open, @lex, &"bootstrap/bootstrap5/lex/tests/c/test.c"
	mov @file, @ret

	%call :_lex_check_read, @file, &"int "

	%ret

:_lex_io_test_macro
	%local ll
	%local lex
	%local file

	# Create the include list
	%call :_ll_init
	mov @ll, @ret

	# Create the lex environment
	%call :__lex_create, @ll
	mov @lex, @ret

	# Open an empty string
	%call :__lex_open_string, @lex, &"done"
	mov @file, @ret

	%call :__lex_define_macro, @file, &"macro1", &"hello world"
	%call :__lex_define_macro, @file, &"macro2", &"abc"

	%call :__lex_activate_macro, @file, &"macro2"
	%call :_lex_check_read, @file, &"abc done"

	%ret

:_lex_check_read
	%arg file
	%arg expected
	%local c
.loop
	ld.b @c, [@expected]
	add @expected, 1
	eq @c, 0
	%ret?

	%call :__lex_peek, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, @c, @tmp0, &"Mismatch in peeked character"

	%call :__lex_read, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, @c, @tmp0, &"Mismatch in read character"

	jump .loop
