#include "regs.h"

:_lex_io_test
	dd &"lex_io"
	dd :_lex_io_test_create, &"test_create"
	dd 0, 0

:_lex_io_test_create
	%local ll
	%local node
	%local lex
	%local file

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

	%call :__lex_read, @file
	mov @tmp0, @ret
	%call :_test_assert_equal, 'i', @tmp0, &"Expected first char to be 'i'"

	%ret
