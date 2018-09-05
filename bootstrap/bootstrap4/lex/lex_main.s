#include "regs.h"
#include "../bootstrap4/lex/lex.h"

#define BUFFER_SIZE 256

:_main
	%local buf
	%local token
	%local len
	%local ll
	%local node
	%local lex
	%local file

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

.loop
	%call :_lex, @file, @buf, @BUFFER_SIZE
	mov @token, @ret

	eq @token, -1
	jump? .done

	%call :_strlen, @buf
	mov @len, @ret

	push @buf
	push @len
	push @token
	%call :_dprintf, 1, &"<%x><%x><%s>\n"
	pop @token
	pop @len
	pop @buf

	jump .loop

.done
	mov @ret, 0
	%ret
