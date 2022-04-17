#include "regs.h"

:_main
	%call :_test_main, :_lex_io_test
	%call :_test_main, :_lex_test
	%ret

:__lex_test_create_lex
	%local ll
	%local node

	# Create the include list
	%call :_ll_init
	mov @ll, @ret
	%call :_ll_create_node, 4
	mov @node, @ret
	st.w [@node], &"bootstrap/bootstrap4/lex0/tests/lex_io_test"
	%call :_ll_insert_head, @ll, @node

	# Create the lex environment
	%call :__lex_create, @ll
	%ret
