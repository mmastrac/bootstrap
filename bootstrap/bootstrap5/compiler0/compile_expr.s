#include "regs.h"
#include "../bootstrap5/lex/lex.h"

:_binary_expression_table
    dd @TOKEN_EQ_OP, &"    eq @tmp0, @tmp1\n    mov @tmp0, 1\n    mov^ @tmp0, 0"
    dd @TOKEN_NE_OP, &"    eq @tmp0, @tmp1\n    mov @tmp0, 0\n    mov^ @tmp0, 1"
    dd @TOKEN_GE_OP, &"    lt @tmp0, @tmp1\n    mov @tmp0, 0\n    mov^ @tmp0, 1"
    dd @TOKEN_LE_OP, &"    gt @tmp0, @tmp1\n    mov @tmp0, 0\n    mov^ @tmp0, 1"
    dd @TOKEN_LEFT_OP, &""
    dd @TOKEN_RIGHT_OP, &""
    dd @TOKEN_AND_OP, &"    and @tmp0, @tmp1"
    dd @TOKEN_OR_OP, &"    or @tmp0, @tmp1"
    dd '<', &"    lt @tmp0, @tmp1\n    mov @tmp0, 1\n    mov^ @tmp0, 0"
    dd '>', &"    gt @tmp0, @tmp1\n    mov @tmp0, 1\n    mov^ @tmp0, 0"
    dd '+', &"    add @tmp0, @tmp1"
    dd '-', &"    sub @tmp0, @tmp1"
    dd '/', &"    div @tmp0, @tmp1"
    dd '%', &"    mod @tmp0, @tmp1"
    dd '*', &"    mul @tmp0, @tmp1"
    dd '|', &""
    dd '&', &""
    dd 0, 0

:_binary_expressions
    dd 0

:_binary_op_allowed
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

    mov @tmp0, 1
    st.d [:_binary_op_allowed], @tmp0
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
    %local last_size

    mov @last_size, 4

    ld.d @ht, [:_binary_expressions]
    eq @ht, 0
    jump^ .inited

	%call :_ht_init, :_ht_int_key_hash, :_ht_int_key_compare
	mov @ht, @ret
	mov @tmp0, :_binary_expressions
	st.d [@tmp0], @ht
	%call :_ht_insert_table, @ht, :_binary_expression_table

.inited
    %call :_lex_peek, @file, 0, 0
    mov @tmp0, .jump_table
    jump :_compiler_jump_table

.error
    %call :_fatal, &"Unexpected token in _compile_expr_stack!\n"
    dd 0

.jump_table
    dd @TOKEN_CONSTANT, .constant
    dd @TOKEN_STRING_LITERAL, .string_literal
    dd @TOKEN_IDENTIFIER, .identifier
    dd '(', .paren
    dd '-', .unary_neg
    dd '!', .unary_not
    dd '*', .unary_deref
    dd '&', .unary_address_of
    dd @TOKEN_NONE, .error

.unary_not
    ld.d @tmp0, [:_binary_op_allowed]
    push @tmp0
    mov @tmp0, 0
    st.d [:_binary_op_allowed], @tmp0

    %call :_lex, @file, @buf, @buflen
    %call :_compiler_out, &"# unary neg\n"
    %call :_compile_expr_stack, @file, @buf, @buflen
    %call :_compiler_out, &"    pop @tmp0\n"
    %call :_compiler_out, &"    eq @tmp0, 0\n"
    %call :_compiler_out, &"    mov? @tmp0, 1\n"
    %call :_compiler_out, &"    mov^ @tmp0, 0\n"
    %call :_compiler_out, &"    push @tmp0\n"

    pop @tmp0
    st.d [:_binary_op_allowed], @tmp0

    jump .done

.unary_neg
    ld.d @tmp0, [:_binary_op_allowed]
    push @tmp0
    mov @tmp0, 0
    st.d [:_binary_op_allowed], @tmp0

    %call :_lex, @file, @buf, @buflen
    %call :_compiler_out, &"# unary neg\n"
    %call :_compile_expr_stack, @file, @buf, @buflen
    %call :_compiler_out, &"    pop @tmp0\n"
    %call :_compiler_out, &"    mov @tmp1, 0\n"
    %call :_compiler_out, &"    sub @tmp1, @tmp0\n"
    %call :_compiler_out, &"    push @tmp1\n"

    pop @tmp0
    st.d [:_binary_op_allowed], @tmp0

    jump .done

.unary_address_of
    ld.d @tmp0, [:_binary_op_allowed]
    push @tmp0
    mov @tmp0, 0
    st.d [:_binary_op_allowed], @tmp0

    %call :_lex, @file, @buf, @buflen
    %call :_lex, @file, @buf, @buflen
    %call :_compiler_out, &"    push [:_%s]\n", @buf

    pop @tmp0
    st.d [:_binary_op_allowed], @tmp0

    jump .done

.paren
    %call :_compile_expr_paren_stack, @file, @buf, @buflen
    jump .done

.constant
    %call :_lex, @file, @buf, @buflen
    %call :_compiler_out, &"    push %s\n", @buf
    jump .done

.string_literal
    %call :_lex, @file, @buf, @buflen
    %call :_compiler_out, &"    push &\""
    mov @tmp0, 0
.string_loop
    ld.b @tmp1, [@buf]
    eq @tmp1, 0
    jump? .string_loop_end
    eq @tmp1, 10
    jump? .escape_n
    eq @tmp1, 13
    jump? .escape_r
    eq @tmp1, '"'
    jump? .escape_quote
    %call :_compiler_out, &"%c", @tmp1
    jump .string_loop_continue
.escape_n
    %call :_compiler_out, &"\\n"
    jump .string_loop_continue
.escape_r
    %call :_compiler_out, &"\\r"
    jump .string_loop_continue
.escape_quote
    %call :_compiler_out, &"\\\""
.string_loop_continue
    add @buf, 1
    jump .string_loop
.string_loop_end
    %call :_compiler_out, &"\"\n"
    jump .done

.identifier
    %call :_lex, @file, @buf, @buflen
    %call :_lex_peek, @file, 0, 0
    eq @ret, '('
    jump? .call
    eq @ret, '='
    jump? .assign
    %call :_is_global, @buf
    mov @last_size, @ret
    eq @ret, 0
    jump^ .identifier_global
    %call :_is_local, @buf
    mov @last_size, @ret
    eq @ret, 0
    jump? .identifier_not_found
    %call :_compiler_out, &"    push @%s\n", @buf
    jump .done
.identifier_global
    %call :_compiler_out, &"    push [:_%s]\n", @buf
    jump .done
.identifier_not_found
    %call :_fatal, &"Undefined variable in assignment\n"
    jump .done

.unary_deref
    %call :_lex, @file, @buf, @buflen
    %call :_lex, @file, @buf, @buflen
    %call :_compiler_out, &"    # deref %s\n", @buf
    %call :_is_global, @buf
    mov @last_size, @ret
    eq @ret, 0
    jump^ .deref_identifier_global
    %call :_is_local, @buf
    mov @last_size, @ret
    eq @ret, 0
    jump? .deref_identifier_not_found
    %call :_compiler_out, &"    mov @tmp0, @%s\n", @buf
    jump .deref_done
.deref_identifier_global
    %call :_compiler_out, &"    mov @tmp0, [:_%s]\n", @buf
    jump .deref_done
.deref_done
    %call :_lex_peek, @file, 0, 0
    eq @ret, '='
    jump? .assign_deref
    eq @last_size, 4
    jump? .deref_load_d
    %call :_compiler_out, &"    ld.b @tmp0, [@tmp0]\n"
    %call :_compiler_out, &"    push @tmp0\n"
    jump .done
.deref_load_d
    %call :_compiler_out, &"    ld.d @tmp0, [@tmp0]\n"
    %call :_compiler_out, &"    push @tmp0\n"
    jump .done
.deref_identifier_not_found
    %call :_fatal, &"Undefined variable in deref\n"
    jump .done

.call
    sub @sp, 32
    mov @label, @sp
    %call :_strcpy, @label, @buf
    mov @arg_count, 0
    %call :_compiler_out, &"# call %s\n", @buf
    %call :_compiler_read_expect, @file, @buf, @buflen, '('
.call_loop
    mov @tmp0, 1
    st.d [:_binary_op_allowed], @tmp0

    %call :_lex_peek, @file, 0, 0
    eq @ret, ')'
    jump? .call_done
    eq @ret, ','
    jump? .call_comma
    %call :_compiler_out, &"# arg\n"
    %call :_compile_expr_stack, @file, @buf, @buflen
    add @arg_count, 1
    jump .call_loop
.call_comma
    %call :_compiler_out, &"# ,\n"
    %call :_compiler_read_expect, @file, @buf, @buflen, ','
    jump .call_loop
.call_done
    %call :_compiler_read_expect, @file, @buf, @buflen, ')'
    
    # Pop each arg, starting from the last one
    push @arg_count
.assign_args_loop
    eq @arg_count, 0
    jump? .assign_args_done
    mov @tmp0, @arg_count
    sub @tmp0, 1
    %call :_compiler_out, &"    pop @_carg%d\n", @tmp0
    sub @arg_count, 1
    jump .assign_args_loop
.assign_args_done
    pop @arg_count

    # Now call the function
    %call :_compiler_out, &"    %%call :_%s ", @label

    mov @label, 0

.write_args_loop
    eq @label, @arg_count
    jump? .write_args_done
    %call :_compiler_out, &"@_carg%d", @label
    add @label, 1
    eq @label, @arg_count
    jump? .write_args_done
    %call :_compiler_out, &", "
    jump .write_args_loop
.write_args_done

    %call :_compiler_out, &"\n"  
    %call :_compiler_out, &"    push @ret\n"

    add @sp, 32
    jump .done

.assign
    %call :_compile_get_next_label
    mov @label, @ret
    %call :_compiler_out, &"# assign %s (#%d)\n", @buf, @label
    %call :_compiler_out, &"    jump .assign_value_1_%d\n", @label
    %call :_compiler_out, &".assign_value_2_%d\n", @label
    %call :_is_global, @buf
    eq @ret, 0
    jump^ .assign_global
    %call :_compiler_out, &"    mov @%s, @ret\n", @buf
    jump .assign_finish
.assign_global
    %call :_compiler_out, &"    st.d [:_%s], @ret\n", @buf
.assign_finish
    %call :_compiler_out, &"    push @ret\n", @buf
    %call :_compiler_out, &"    jump .assign_value_3_%d\n", @label
    %call :_compiler_read_expect, @file, 0, 0, '='
    %call :_compiler_out, &".assign_value_1_%d\n", @label
    %call :_compile_expr_ret, @file, @buf, @buflen
    %call :_compiler_out, &"    jump .assign_value_2_%d\n", @label
    %call :_compiler_out, &".assign_value_3_%d\n", @label
    jump .done

.assign_deref
    %call :_compiler_read_expect, @file, 0, 0, '='
    %call :_compiler_out, &"# assign deref %s\n", @buf
    %call :_compiler_out, &"    push @tmp0\n"
    %call :_compile_expr_stack, @file, @buf, @buflen
    %call :_compiler_out, &"    pop @tmp1\n"
    %call :_compiler_out, &"    pop @tmp0\n"

    eq @last_size, 4
    jump? .assign_deref_d
    %call :_compiler_out, &"    st.b [@tmp0], @tmp1\n"
    jump .assign_deref_finish
.assign_deref_d
    %call :_compiler_out, &"    st.d [@tmp0], @tmp1\n"
.assign_deref_finish
    %call :_compiler_out, &"    push @tmp1\n"
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
    dd ']', .return
    dd @TOKEN_NONE, .binary

.binary
    %call :_lex, @file, @buf, @buflen
    eq @ret, '['
    jump? .load
    %call :_compiler_out, &"# operator '%s'\n", @buf
    # Check for invalid nesting
    ld.d @tmp0, [:_binary_op_allowed]
    eq @tmp0, 0
    jump? .no_binary_op
    mov @tmp0, 0
    st.d [:_binary_op_allowed], @tmp0
    # Do the RHS
    %call :_compile_expr_stack, @file, @buf, @buflen
    # Pop both sides
    %call :_compiler_out, &"    pop @tmp1\n"
    %call :_compiler_out, &"    pop @tmp0\n"
    %call :_ht_lookup, @ht, @saved_op   
    eq @ret, 0
    jump? .bad_op
    mov @buf, @ret
    %call :_compiler_out, &"%s\n", @buf
    %call :_compiler_out, &"    push @tmp0\n"
    mov @tmp0, 1
    st.d [:_binary_op_allowed], @tmp0

.return
    %call :_compiler_out, &"# expr end\n"
    %ret

.no_binary_op
    %call :_fatal, &"Nested binary operations must be parenthesized\n"
    %ret

.load
    mov @tmp0, 1
    st.d [:_binary_op_allowed], @tmp0
    %call :_compile_expr_stack, @file, @buf, @buflen
    mov @tmp0, 1
    st.d [:_binary_op_allowed], @tmp0
    %call :_compiler_read_expect, @file, @buf, @buflen, ']'
    %call :_lex_peek, @file, 0, 0
    eq @ret, '='
    jump? .store
    %call :_compiler_out, &"    pop @tmp0\n"
    %call :_compiler_out, &"    pop @tmp1\n"
    eq @last_size, 4
    jump? .load_d
    %call :_compiler_out, &"    add @tmp0, @tmp1\n"
    %call :_compiler_out, &"    ld.b @tmp0, [@tmp0]\n"
    jump .load_done
.load_d
    %call :_compiler_out, &"    mul @tmp0, 4\n"
    %call :_compiler_out, &"    add @tmp0, @tmp1\n"
    %call :_compiler_out, &"    ld.d @tmp0, [@tmp0]\n"
.load_done
    %call :_compiler_out, &"    push @tmp0\n"
    jump .done
.store
    %call :_compiler_read_expect, @file, @buf, @buflen, '='
    eq @last_size, 4
    jump? .store_d
    %call :_compiler_out, &"    pop @tmp0\n"
    %call :_compiler_out, &"    pop @tmp1\n"
    %call :_compiler_out, &"    add @tmp0, @tmp1\n"
    %call :_compiler_out, &"    push @tmp0\n"
    %call :_compile_expr_stack, @file, @buf, @buflen
    %call :_compiler_out, &"    pop @tmp1\n"
    %call :_compiler_out, &"    pop @tmp0\n"
    %call :_compiler_out, &"    st.b [@tmp0], @tmp1\n"
    jump .store_done
.store_d
    %call :_compiler_out, &"    pop @tmp0\n"
    %call :_compiler_out, &"    mul @tmp0, 4\n"
    %call :_compiler_out, &"    pop @tmp1\n"
    %call :_compiler_out, &"    add @tmp0, @tmp1\n"
    %call :_compiler_out, &"    push @tmp0\n"
    %call :_compile_expr_stack, @file, @buf, @buflen
    %call :_compiler_out, &"    pop @tmp1\n"
    %call :_compiler_out, &"    pop @tmp0\n"
    %call :_compiler_out, &"    st.d [@tmp0], @tmp1\n"
.store_done
    %call :_compiler_out, &"    push @tmp1\n"
    jump .done

.bad_op
    %call :_fatal, &"Unexpected binary operation\n"

:_compile_expr_paren_stack
    %arg file
    %arg buf
    %arg buflen

    mov @tmp0, 1
    st.d [:_binary_op_allowed], @tmp0

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
