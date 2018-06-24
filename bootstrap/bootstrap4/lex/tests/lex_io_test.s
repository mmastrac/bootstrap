#include "regs.h"

:_lex_io_test
	dd &"lex_io"
	dd :_lex_io_test_create, &"test_create"
	dd 0, 0

:_lex_io_include_path
	dd &"bootstrap/bootstrap4/lex_io_test"

:_lex_io_test_create
	%local ll
	%local node

# Create the include list
	%call :_ll_init
	mov @ll, @ret
	%call :_ll_create_node, 4
	mov @node, @ret
	st.w [@node], :_lex_io_include_path
	%call :_ll_insert_head, @ll, @node

# Create the lex environment
	%call :__lex_create, @ll

	%ret
