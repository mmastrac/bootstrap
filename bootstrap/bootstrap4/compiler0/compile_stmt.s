#include "regs.h"
#include "../bootstrap4/lex/lex.h"

:_compile_stmt
    %arg file
    %arg buf
    %arg buflen
    %local done
    %call :_lex, @file, @buf, @buflen

    mov @done, 0

    eq @ret, ';'
    jump? .done

    eq @ret, '}'
    mov? @done, 1
    jump? .done

    eq @ret, @TOKEN_IF
    jump^ .not_if

    %call :_compile_stmt_if, @file, @buf, @buflen
    jump .done

.not_if

    eq @ret, @TOKEN_WHILE
    jump^ .not_while

    %call :_compile_stmt_while, @file, @buf, @buflen
    jump .done

.not_while

    eq @ret, @TOKEN_INT
    jump^ .not_local

    %call :_compile_stmt_local, @file, @buf, @buflen
    jump .done

.not_local

    %call :_compiler_expect, @ret, @buf, @TOKEN_IDENTIFIER
    jump .done

.done
    %ret

:_compile_stmt_if
    %arg file
    %arg buf
    %arg buflen
    %ret

:_compile_stmt_while
    %arg file
    %arg buf
    %arg buflen
    %ret

:_compile_stmt_local
    %arg file
    %arg buf
    %arg buflen
    %ret

:_compile_stmt_assign
    %arg file
    %arg buf
    %arg buflen
    %ret
