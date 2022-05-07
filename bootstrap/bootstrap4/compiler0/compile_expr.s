#include "regs.h"
#include "../bootstrap4/lex/lex.h"

:_binary_expression_table
    dd @TOKEN_EQ_OP, &"    eq @tmp0, @tmp1\n    mov @tmp0, 1\n    mov^ @tmp0, 0"
    dd @TOKEN_NE_OP, &"    eq @tmp0, @tmp1\n    mov @tmp0, 0\n    mov^ @tmp0, 1"
    dd @TOKEN_GE_OP, &"    lt @tmp0, @tmp1\n    mov @tmp0, 0\n    mov^ @tmp0, 1"
    dd @TOKEN_LE_OP, &"    gt @tmp0, @tmp1\n    mov @tmp0, 0\n    mov^ @tmp0, 1"
    dd '<', &"    lt @tmp0, @tmp1\n    mov @tmp0, 1\n    mov^ @tmp0, 0"
    dd '>', &"    gt @tmp0, @tmp1\n    mov @tmp0, 1\n    mov^ @tmp0, 0"
    dd '+', &"    add @tmp0, @tmp1"
    dd '-', &"    sub @tmp0, @tmp1"
    dd '/', &"    div @tmp0, @tmp1"
    dd '*', &"    mul @tmp0, @tmp1"
    dd 0, 0

:_binary_expressions
    dd 0

:_compile_next_label
    dd 0

:_compile_get_next_label
    %local tmp
    ld.d @tmp, [:_compile_next_label]
    add @tmp, 1
    st.d [:_compile_next_label], @tmp
    mov @ret, @tmp
    %ret

#===========================================================================
# Compile an expression, returning it in @ret.
#===========================================================================
:_compile_expr_ret
    %arg file
    %arg buf
    %arg buflen

    %call :_compile_expr_stack, @file, @buf, @buflen
    %call :_compiler_out, &"    pop @ret\n", @buf
    %ret

#===========================================================================
# Compile an expression, returning it in on the stack.
#===========================================================================
:_compile_expr_stack
    %arg file
    %arg buf
    %arg buflen
    %local saved_op
    %local ht
    %local label
    %local arg_count

    ld.d @ht, [:_binary_expressions]
    eq @ht, 0
    jump^ .inited

	%call :_ht_init, :__lex_hash_table_test_key_hash, :__lex_hash_table_test_key_compare
	mov @ht, @ret
	mov @tmp0, :_binary_expressions
	st.d [@tmp0], @ht
	%call :_ht_insert_table, @ht, :_binary_expression_table

.inited
    %call :_lex_peek, @file, 0, 0
    mov @tmp0, .jump_table
    jump :_compiler_jump_table

.jump_table
    dd @TOKEN_CONSTANT, .constant
    dd @TOKEN_STRING_LITERAL, .string_literal
    dd @TOKEN_IDENTIFIER, .identifier
    dd '(', .paren
    dd @TOKEN_NONE, @TOKEN_NONE

.paren
    %call :_compile_expr_paren_stack, @file, @buf, @buflen
    jump .done

.constant
    %call :_lex, @file, @buf, @buflen
    %call :_compiler_out, &"    push %s\n", @buf
    jump .done

.string_literal
    %call :_lex, @file, @buf, @buflen
    %call :_compiler_out, &"    push &\"%s\"\n", @buf
    jump .done

.identifier
    %call :_lex, @file, @buf, @buflen
    %call :_lex_peek, @file, 0, 0
    eq @ret, '('
    jump? .call
    eq @ret, '='
    jump? .assign
    %call :_compiler_out, &"    push @%s\n", @buf
    jump .done

.call
    %call :_compile_get_next_label
    mov @label, @ret
    mov @arg_count, 0
    %call :_compiler_out, &"# call %s\n", @buf
    %call :_compiler_out, &"    jump .setup_args_1_%d\n", @label
    %call :_compiler_out, &".setup_args_2_%d\n", @label
    %call :_compiler_out, &"    %%call :%s, @arg0, @arg1, @arg2, @arg3, @arg4, @arg5, @arg6, @arg7\n", @buf
    %call :_compiler_out, &"    push @ret\n"
    %call :_compiler_out, &"    jump .setup_args_3_%d\n", @label
    %call :_compiler_out, &".setup_args_1_%d\n", @label
    %call :_compiler_read_expect, @file, @buf, @buflen, '('
.call_loop
    %call :_lex_peek, @file, 0, 0
    eq @ret, ')'
    jump? .call_done
    eq @ret, ','
    jump? .call_comma
    %call :_compiler_out, &"# arg\n"
    %call :_compile_expr_stack, @file, @buf, @buflen
    %call :_compiler_out, &"# arg\n"
    add @arg_count, 1
    jump .call_loop
.call_comma
    %call :_compiler_out, &"# ,\n"
    %call :_compiler_read_expect, @file, @buf, @buflen, ','
    jump .call_loop
.call_done
    eq @arg_count, 0
    jump? .call_args_done
    sub @arg_count, 1
    %call :_compiler_out, &"    pop @arg%d\n", @arg_count
    jump .call_done
.call_args_done
    %call :_compiler_read_expect, @file, @buf, @buflen, ')'
    %call :_compiler_out, &"    jump .setup_args_2_%d\n", @label
    %call :_compiler_out, &".setup_args_3_%d\n", @label
    jump .done

.assign
    %call :_compile_get_next_label
    mov @label, @ret
    %call :_compiler_out, &"# assign %s (#%d)\n", @buf, @label
    %call :_compiler_out, &"    jump .assign_value_1_%d\n", @label
    %call :_compiler_out, &".assign_value_2_%d\n", @label
    %call :_compiler_out, &"    mov @%s, @ret\n", @buf
    %call :_compiler_out, &"    push @%s\n", @buf
    %call :_compiler_out, &"    jump .assign_value_3_%d\n", @label
    %call :_compiler_read_expect, @file, 0, 0, '='
    %call :_compiler_out, &".assign_value_1_%d\n", @label
    %call :_compile_expr_ret, @file, @buf, @buflen
    %call :_compiler_out, &"    jump .assign_value_2_%d\n", @label
    %call :_compiler_out, &".assign_value_3_%d\n", @label
    jump .done

.done
    %call :_lex_peek, @file, @buf, @buflen
    mov @saved_op, @ret
    mov @tmp0, .expression_table
    jump :_compiler_jump_table

.expression_table
    dd ')', .return
    dd ',', .return
    dd ';', .return
    dd @TOKEN_NONE, .binary

.binary
    %call :_lex, @file, @buf, @buflen
    %call :_compiler_out, &"# operator '%s'\n", @buf
    # Do the RHS
    %call :_compile_expr_stack, @file, @buf, @buflen
    # Pop both sides
    %call :_compiler_out, &"    pop @tmp1\n"
    %call :_compiler_out, &"    pop @tmp0\n"
    %call :_ht_lookup, @ht, @saved_op
    mov @buf, @ret
    %call :_compiler_out, &"%s\n", @buf
    %call :_compiler_out, &"    push @tmp0\n"

.return
    %call :_compiler_out, &"# expr end\n"
    %ret

:_compile_expr_paren_stack
    %arg file
    %arg buf
    %arg buflen

    %call :_compiler_read_expect, @file, @buf, @buflen, '('
    %call :_compile_expr_stack, @file, @buf, @buflen
    %call :_compiler_read_expect, @file, @buf, @buflen, ')'

    %ret

:_compile_expr_paren_ret
    %arg file
    %arg buf
    %arg buflen

    %call :_compiler_read_expect, @file, @buf, @buflen, '('
    %call :_compile_expr_ret, @file, @buf, @buflen
    %call :_compiler_read_expect, @file, @buf, @buflen, ')'

    %ret
