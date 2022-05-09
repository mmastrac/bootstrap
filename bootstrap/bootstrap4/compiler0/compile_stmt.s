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

    %call :_lex_peek, @file, @buf, @buflen
    mov @tmp0, .jump_table
    jump :_compiler_jump_table

.jump_table
    dd ';', .done
    dd @TOKEN_IF, .if
    dd @TOKEN_FOR, .for
    dd @TOKEN_WHILE, .while
    dd @TOKEN_IDENTIFIER, .identifier
    dd @TOKEN_RETURN, .return
    # Assume anything else is a local declaration
    dd @TOKEN_NONE, .local

.if
    %call :_compile_stmt_if, @file, @buf, @buflen
    jump .done

.for
    %call :_compile_stmt_for, @file, @buf, @buflen
    jump .done

.while
    %call :_compile_stmt_while, @file, @buf, @buflen
    jump .done

.identifier
    %call :_compile_expr_ret, @file, @buf, @buflen
    %call :_compiler_read_expect, @file, @buf, @buflen, ';'
    jump .done

.return
    %call :_compile_stmt_return, @file, @buf, @buflen
    jump .done

.local
    %call :_compile_stmt_local, @file, @buf, @buflen
    jump .done

.done
    %ret

:_compile_stmt_if
    %arg file
    %arg buf
    %arg buflen
    %local label

    %call :_compile_get_next_label
    mov @label, @ret

    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_IF
    %call :_compiler_out, &"# if\n"
    %call :_compile_expr_paren_ret, @file, @buf, @buflen
    %call :_compiler_out, &"# if test\n"
    %call :_compiler_out, &"    eq @ret, 0\n"
    %call :_compiler_out, &"    jump? .end_%d\n", @label
    %call :_compile_block, @file, @buf, @buflen
    %call :_compiler_out, &".end_%d\n", @label
    %ret

:_compile_stmt_for
    %arg file
    %arg buf
    %arg buflen
    %local label

    %call :_compile_get_next_label
    mov @label, @ret

    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_FOR
    %call :_compiler_read_expect, @file, @buf, @buflen, '('

    # The initial expression
    %call :_compile_expr_ret, @file, @buf, @buflen
    %call :_compiler_read_expect, @file, @buf, @buflen, ';'

    # The test expression
    %call :_compiler_out, &".test_%d\n", @label
    %call :_compile_expr_ret, @file, @buf, @buflen
    %call :_compiler_out, &"    eq @ret, 0\n"
    %call :_compiler_out, &"    jump^ .begin_%d\n", @label
    %call :_compiler_out, &"    jump .end_%d\n", @label
    %call :_compiler_read_expect, @file, @buf, @buflen, ';'

    # The increment expression
    %call :_compiler_out, &".inc_%d\n", @label
    %call :_compile_expr_ret, @file, @buf, @buflen
    %call :_compiler_out, &"    jump .test_%d\n", @label

    %call :_compiler_read_expect, @file, @buf, @buflen, ')'

    # The loop
    %call :_compiler_out, &".begin_%d\n", @label
    %call :_compile_block, @file, @buf, @buflen
    %call :_compiler_out, &"    jump .inc_%d\n", @label
    %call :_compiler_out, &".end_%d\n", @label

    %ret

:_compile_stmt_while
    %arg file
    %arg buf
    %arg buflen
    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_WHILE
    %ret

:_compile_stmt_return
    %arg file
    %arg buf
    %arg buflen

    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_RETURN
    %call :_compiler_out, &"# return\n"
    # This will leave the return value in @ret
    %call :_compile_expr_ret, @file, @buf, @buflen
    %call :_compiler_out, &"    %%ret\n"
    %call :_compiler_read_expect, @file, @buf, @buflen, ';'
    %ret

:_compile_stmt_local
    %arg file
    %arg buf
    %arg buflen
    %local label

    %call :_compile_function_type, @file, @buf, @buflen
    %call :_compiler_out, &"# local\n"
    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_IDENTIFIER
    %call :_is_global, @buf
    eq @ret, 0
    jump? .no_shadow
    %call :_fatal, &"Local cannot shadow a global"
.no_shadow
    %call :_compiler_out, &"    %%local %s\n", @buf
    %call :_lex_peek, @file, 0, 0
    eq @ret, '='
    jump^ .done

    %call :_compile_get_next_label
    mov @label, @ret
    %call :_compiler_out, &"# assign %s (#%d)\n", @buf, @label
    %call :_compiler_out, &"    jump .assign_value_1_%d\n", @label
    %call :_compiler_out, &".assign_value_2_%d\n", @label
    %call :_compiler_out, &"    mov @%s, @ret\n", @buf
    %call :_compiler_out, &"    jump .assign_value_3_%d\n", @label
    %call :_compiler_read_expect, @file, 0, 0, '='
    %call :_compiler_out, &".assign_value_1_%d\n", @label
    %call :_compile_expr_ret, @file, @buf, @buflen
    %call :_compiler_out, &"    jump .assign_value_2_%d\n", @label
    %call :_compiler_out, &".assign_value_3_%d\n", @label

.done
    %call :_compiler_read_expect, @file, @buf, @buflen, ';'

    %ret
