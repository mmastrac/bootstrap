#include "regs.h"
#include "../bootstrap4/lex/lex.h"

:_compiler_out
    %arg msg
    %arg out0
    %arg out1
    %arg out2
    %arg out3

    push @out3
    push @out2
    push @out1
    push @out0
	%call :_dprintf, 1, @msg
    pop @out0
    pop @out1
    pop @out2
    pop @out3
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
	%call :_quicklog, &"buf = '%s'", @buf
	%call :_fatal, &"Unexpected token encountered"
    %ret
