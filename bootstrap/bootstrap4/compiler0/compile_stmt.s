#include "regs.h"
#include "../bootstrap4/lex/lex.h"

:_compile_block
    %arg file
    %arg buf
    %arg buflen
    %call :_compiler_read_expect, @file, @buf, @buflen, '{'
    %call :_compiler_out, &"# {\n"
.loop
    %call :_compiler_peek_is, @file, '}'
    jump? .done
    %call :_compile_stmt, @file, @buf, @buflen
    jump .loop

.done
    %call :_compiler_read_expect, @file, @buf, @buflen, '}'
    %call :_compiler_out, &"# }\n"
    %ret

:_compile_stmt
    %arg file
    %arg buf
    %arg buflen

    %call :_lex, @file, @buf, @buflen
    mov @tmp0, .jump_table
    jump :_compiler_jump_table

.jump_table
    dd ';', .done
    dd @TOKEN_IF, .if
    dd @TOKEN_WHILE, .while
    dd @TOKEN_INT, .int
    dd @TOKEN_IDENTIFIER, .identifier
    dd @TOKEN_RETURN, .return
    dd @TOKEN_NONE, .error

.if
    %call :_compile_stmt_if, @file, @buf, @buflen
    jump .done

.while
    jump .done

.int
    %call :_compiler_out, &"# local\n"
    %call :_compile_stmt_local, @file, @buf, @buflen
    jump .done

.identifier
    %call :_compiler_peek_is, @file, '('
    jump? .invoke
    %call :_compiler_peek_is, @file, '='
    jump? .assign
    %call :_compiler_fatal, &"Expected ( or ="

.invoke
    %call :_compile_stmt_invoke, @file, @buf, @buflen
    jump .done

.assign
    %call :_compile_stmt_assign, @file, @buf, @buflen
    jump .done

.return
    %call :_compile_stmt_return, @file, @buf, @buflen
    jump .done

.error
    %call :_compiler_fatal, @buf

.done
    %ret

:_compile_stmt_if
    %arg file
    %arg buf
    %arg buflen

    %call :_compiler_out, &"# if\n"
    %call :_compile_expr_paren, @file, @buf, @buflen
    %call :_compiler_out, &"# if test\n"
    %call :_compiler_out, &"    pop @tmp0\n"
    %call :_compiler_out, &"    eq @tmp0, 0\n"
    %call :_compiler_out, &"    jump .end\n"
    %call :_compile_block, @file, @buf, @buflen
    %call :_compiler_out, &".end\n"
    %ret

:_compile_stmt_while
    %arg file
    %arg buf
    %arg buflen
    %ret

:_compile_stmt_return
    %arg file
    %arg buf
    %arg buflen

    %call :_compiler_out, &"# return\n"
    %call :_compile_expr, @file, @buf, @buflen
    %call :_compiler_out, &"    pop @ret\n"
    %call :_compiler_out, &"    %%ret\n"
    %call :_compiler_read_expect, @file, @buf, @buflen, ';'
    %ret

:_compile_stmt_local
    %arg file
    %arg buf
    %arg buflen

    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_IDENTIFIER
    %call :_compiler_out, &"    %%local %s\n", @buf

    %ret

:_compile_stmt_assign
    %arg file
    %arg buf
    %arg buflen
    %call :_compiler_out, &"# assign\n"
    %ret

:_compile_stmt_invoke
    %arg file
    %arg buf
    %arg buflen
    %call :_compiler_out, &"# invoke\n"
    %ret