#include "regs.h"
#include "../lex/lex.h"

:_compiler_out_fd
    # stdout by default
    dd 1

:_compiler_out_open
    %arg file
	%call :_open, @file, 1
    st.d [:_compiler_out_fd], @ret
    %ret

:_compiler_out
    %arg msg
    %arg out0
    %arg out1
    %arg out2
    %arg out3
    %local fd

    ld.d @fd, [:_compiler_out_fd]

    push @out3
    push @out2
    push @out1
    push @out0
	%call :_dprintf, @fd, @msg
    pop @out0
    pop @out1
    pop @out2
    pop @out3
    %ret

# Returns whether the next token is the expected one in the flags
:_compiler_peek_is
    %arg file
    %arg expected

    %call :_lex_peek, @file, 0, 0
    eq @ret, @expected
    %ret

:_compiler_read_expect
    %arg file
    %arg buf
    %arg buflen
    %arg expected

    %call :_lex, @file, @buf, @buflen
    eq @ret, @expected
    jump? .done

    push @ret
    %call :_compiler_fatal, @buf
    pop @ret

.done
    %ret

:_compiler_expect
    %arg token
    %arg buf
    %arg expected

    eq @token, @expected
    jump? .done

    push @ret
    %call :_compiler_fatal, @buf
    pop @ret

.done
    %ret

:_compiler_fatal
    %arg buf
	%call :_quicklog, &"buf = '%s'\n", @buf
	%call :_fatal, &"Unexpected token encountered\n"
    %ret

# This is not a function - you jump here with:
#  - tmp0 as the jump table address
#  - ret as the token to compare
:_compiler_jump_table
.jump_table_loop
    ld.d @tmp1, [@tmp0]
    # If last item, force equality
    eq @tmp1, @TOKEN_NONE
    mov? @tmp1, @ret
    add @tmp0, 4
    eq @tmp1, @ret
    ld.d? @tmp1, [@tmp0]
    mov? @pc, @tmp1
    add @tmp0, 4
    jump .jump_table_loop
