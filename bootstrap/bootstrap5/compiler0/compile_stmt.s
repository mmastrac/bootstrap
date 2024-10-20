#include "regs.h"
#include "../lex/lex.h"

:_function_has_saved_stack
    dd 0

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
    dd @TOKEN_IDENTIFIER, .expr
    dd '*', .expr
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

.expr
    %call :_strcmp, @buf, &"__asm__"
    eq @ret, 0
    jump? .asm
    %call :_compile_expr_ret, @file, @buf, @buflen
    %call :_compiler_read_expect, @file, @buf, @buflen, ';'
    jump .done

.asm
    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_IDENTIFIER
    %call :_compiler_read_expect, @file, @buf, @buflen, '('
    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_STRING_LITERAL
    %call :_compiler_out, &"%s\n", @buf
    %call :_compiler_read_expect, @file, @buf, @buflen, ')'
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
    %local else_label
    %local end_label

    %call :_compile_get_next_label
    mov @else_label, @ret
    %call :_compile_get_next_label
    mov @end_label, @ret

    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_IF
    %call :_compiler_out, &"# if\n"
    %call :_compile_expr_paren_ret, @file, @buf, @buflen
    %call :_compiler_out, &"# if test\n"
    %call :_compiler_out, &"    eq @ret, 0\n"
    %call :_compiler_out, &"    jump? .else_%d\n", @else_label
    %call :_compile_block, @file, @buf, @buflen
    %call :_compiler_out, &"    jump .end_%d\n", @end_label
    %call :_compiler_out, &".else_%d\n", @else_label

.check_else
    %call :_lex_peek, @file, 0, 0
    eq @ret, @TOKEN_ELSE
    jump^ .done_if

    # We have an else, so consume it
    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_ELSE

    # Check if it's an else if
    %call :_lex_peek, @file, 0, 0
    eq @ret, @TOKEN_IF
    jump^ .else_block

    # It's an else if
    %call :_lex, @file, @buf, @buflen
    %call :_compile_get_next_label
    mov @else_label, @ret
    %call :_compiler_out, &"# else if\n"
    %call :_compile_expr_paren_ret, @file, @buf, @buflen
    %call :_compiler_out, &"# else if test\n"
    %call :_compiler_out, &"    eq @ret, 0\n"
    %call :_compiler_out, &"    jump? .else_%d\n", @else_label
    %call :_compile_block, @file, @buf, @buflen
    %call :_compiler_out, &"    jump .end_%d\n", @end_label
    %call :_compiler_out, &".else_%d\n", @else_label
    jump .check_else

.else_block
    %call :_compiler_out, &"# else\n"
    %call :_compile_block, @file, @buf, @buflen

.done_if
    %call :_compiler_out, &".end_%d\n", @end_label
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
    %local label

    %call :_compile_get_next_label
    mov @label, @ret

    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_WHILE
    %call :_compiler_read_expect, @file, @buf, @buflen, '('

    # The test expression
    %call :_compiler_out, &".test_%d\n", @label
    %call :_compile_expr_ret, @file, @buf, @buflen
    %call :_compiler_out, &"    eq @ret, 0\n"
    %call :_compiler_out, &"    jump? .end_%d\n", @label

    %call :_compiler_read_expect, @file, @buf, @buflen, ')'

    # The loop
    %call :_compiler_out, &".begin_%d\n", @label
    %call :_compile_block, @file, @buf, @buflen
    %call :_compiler_out, &"    jump .test_%d\n", @label
    %call :_compiler_out, &".end_%d\n", @label

    %ret

:_compile_stmt_return
    %arg file
    %arg buf
    %arg buflen

    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_RETURN
    %call :_compiler_out, &"# return\n"
    %call :_lex_peek, @file, 0, 0
    eq @ret, ';'
    jump? .just_return
    # This will leave the return value in @ret
    %call :_compile_expr_ret, @file, @buf, @buflen
.just_return
	ld.d @tmp0, [:_function_has_saved_stack]
	eq @tmp0, 0
	jump? .return_no_stack
	%call :_compiler_out, &"    pop @tmp0\n"
	%call :_compiler_out, &"    mov @sp, @tmp0\n"
.return_no_stack
    %call :_compiler_out, &"    %%ret\n"
    %call :_compiler_read_expect, @file, @buf, @buflen, ';'
    %ret

:_compile_stmt_local
    %arg file
    %arg buf
    %arg buflen
    %local label
    %local size

    ld.d @tmp0, [:_function_has_saved_stack]
    eq @tmp0, 1
    jump? .no_locals_after_array

    %call :_compile_function_type, @file, @buf, @buflen
    mov @size, @ret
    %call :_compiler_out, &"# local\n"
    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_IDENTIFIER
    %call :_track_local, @buf, @size
    %call :_is_global, @buf
    eq @ret, 0
    jump? .no_shadow
    %call :_fatal, &"Local cannot shadow a global"
.no_shadow
    %call :_compiler_out, &"    %%local %s\n", @buf
    %call :_lex_peek, @file, 0, 0
    eq @ret, '['
    jump? .local_array
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
    jump .done

.local_array
    mov @tmp0, 1
    st.d [:_function_has_saved_stack], @tmp0

    sub @sp, 32
    %call :_strcpy, @sp, @buf
    %call :_compiler_read_expect, @file, 0, 0, '['
    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_CONSTANT
    %call :_compiler_read_expect, @file, 0, 0, ']'
    %call :_compiler_out, &"    mov @tmp0, @sp\n"
    %call :_compiler_out, &"    mov @tmp1, %s\n", @buf
    %call :_compiler_out, &"    mul @tmp1, %d\n", @size
    %call :_compiler_out, &"    sub @sp, @tmp1\n"
    %call :_compiler_out, &"    mov @%s, @sp\n", @sp
    %call :_compiler_out, &"    push @tmp0\n"
    add @sp, 32

.done
    %call :_compiler_read_expect, @file, @buf, @buflen, ';'
    %ret

.no_locals_after_array
    %call :_fatal, &"No locals may appear after an array local\n"
