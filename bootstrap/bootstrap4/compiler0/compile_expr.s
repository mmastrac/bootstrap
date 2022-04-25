#include "regs.h"
#include "../bootstrap4/lex/lex.h"

:_binary_expression_table
    dd @TOKEN_EQ_OP, &"    eq @tmp0, @tmp1\n    mov? @tmp0, 1\n    mov^ @tmp0, 0"
    dd @TOKEN_NE_OP, &"    eq @tmp0, @tmp1\n    mov? @tmp0, 0\n    mov^ @tmp0, 1"
    dd '+', &"    add @tmp0, @tmp1"
    dd '-', &"    sub @tmp0, @tmp1"
    dd '/', &"    div @tmp0, @tmp1"
    dd '*', &"    mul @tmp0, @tmp1"
    dd 0, 0

:_binary_expressions
    dd 0

:_compile_expr
    %arg file
    %arg buf
    %arg buflen
    %local saved_op
    %local ht

    ld.d @ht, [:_binary_expressions]
    eq @ht, 0
    jump^ .inited

	%call :_ht_init, :__lex_hash_table_test_key_hash, :__lex_hash_table_test_key_compare
	mov @ht, @ret
	mov @tmp0, :_binary_expressions
	st.d [@tmp0], @ht
	%call :_ht_insert_table, @ht, :_binary_expression_table

.inited
    %call :_lex_peek, @file, @buf, @buflen
    mov @tmp0, .jump_table
    jump :_compiler_jump_table

.jump_table
    dd @TOKEN_CONSTANT, .constant
    dd @TOKEN_IDENTIFIER, .identifier
    dd '(', .paren
    dd @TOKEN_NONE, @TOKEN_NONE

.paren
    %call :_compile_expr_paren, @file, @buf, @buflen
    %ret

.constant
    %call :_lex, @file, @buf, @buflen
    %call :_compiler_out, &"    push %s\n", @buf
    jump .done

.identifier
    %call :_lex, @file, @buf, @buflen
    %call :_compiler_out, &"    push @%s\n", @buf
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
    # Do the RHS
    %call :_compile_expr, @file, @buf, @buflen
    # Pop both sides
    %call :_compiler_out, &"    pop @tmp0\n"
    %call :_compiler_out, &"    pop @tmp1\n"
    %call :_ht_lookup, @ht, @saved_op
    mov @buf, @ret
    %call :_compiler_out, &"%s\n", @buf
    %call :_compiler_out, &"    push @tmp0\n"

.return
    %ret

:_compile_expr_paren
    %arg file
    %arg buf
    %arg buflen

    %call :_compiler_read_expect, @file, @buf, @buflen, '('
    %call :_compile_expr, @file, @buf, @buflen
    %call :_compiler_read_expect, @file, @buf, @buflen, ')'

    %ret
