#include "lex/lex.h"

// Forward declarations
int compile_get_next_label();
void push_constant(char* value);
void push_string(char* value);
void push_reg(char* reg);
void pop_reg(int reg);
void pop_arg(int arg_num);
void push_global(char* var);
void push_local(char* var);
void store_global(char* var);
void store_local(char* var);
void emit_comment(char* format, ...);
void emit_jump(char* label);
void emit_label(int label);
void emit_call(char* func);
void swap_arg(char* reg, int stack_offset);
void op1(int op);
void op2(int op);
void compile_ternary(int* file, char* buf, int buflen);
void compile_logical_or(int* file, char* buf, int buflen);
void compile_logical_and(int* file, char* buf, int buflen);
void compile_equality(int* file, char* buf, int buflen);
void compile_relational(int* file, char* buf, int buflen);
void compile_additive(int* file, char* buf, int buflen);
void compile_multiplicative(int* file, char* buf, int buflen);
void compile_unary(int* file, char* buf, int buflen);
void compile_primary(int* file, char* buf, int buflen);
void compile_function_call(int* file, char* buf, int buflen);
void compile_assignment(int* file, char* buf, int buflen);
void compile_array_access(int* file, char* buf, int buflen);
void compile_expr(int* file, char* buf, int buflen, int precedence);
void compile_expr_paren(int* file, char* buf, int buflen);
void compile_expr_stack(int* file, char* buf, int buflen);
void compile_expr_ret(int* file, char* buf, int buflen);

int* binary_expressions = 0;
int compile_next_label = 0;

int compile_get_next_label() {
    int tmp = compile_next_label;
    compile_next_label = compile_next_label + 1;
    return tmp;
}

// Helper functions for stack operations
void push_constant(char* value) {
    compiler_out("    push %s\n", value);
}

void push_string(char* value) {
    compiler_out("    push &\"%s\"\n", value);
}

void push_reg(char* reg) {
    compiler_out("    push @%s\n", reg);
}

void pop_reg(int reg) {
    compiler_out("    pop @r%s\n", reg);
}

void pop_arg(int arg_num) {
    compiler_out("    pop @arg%d\n", arg_num);
}

void push_global(char* var) {
    compiler_out("    push [:%s]\n", var);
}

void push_local(char* var) {
    compiler_out("    push @%s\n", var);
}

void store_global(char* var) {
    compiler_out("    st.d [:%s], @ret\n", var);
}

void store_local(char* var) {
    compiler_out("    mov @%s, @ret\n", var);
}

void emit_jump(char* label) {
    compiler_out("    jump %s\n", label);
}

void emit_label(int label) {
    compiler_out(".L%d\n", label);
}

void emit_call(char* func) {
    compiler_out("    %%call :%s, @arg0, @arg1, @arg2, @arg3, @arg4, @arg5, @arg6, @arg7\n", func);
}

// Swap a register with a position on the stack
void swap_arg(char* reg, int stack_offset) {
    compiler_out("    mov @tmp0, @sp\n");
    compiler_out("    add @tmp0, %d\n", stack_offset);
    compiler_out("    ld.d @tmp1, [@tmp0]\n");
    compiler_out("    st.d [@tmp0], %s\n", reg);
    compiler_out("    mov %s, @tmp1\n", reg);
}

void op1(int op) {
    compiler_out("    pop @tmp0\n");
    if (op == '-') {
        compiler_out("    mov @tmp1, 0\n");
        compiler_out("    sub @tmp1, @tmp0\n");
        compiler_out("    push @tmp1\n");
    } else if (op == '!') {
        compiler_out("    eq @tmp0, 0\n");
        compiler_out("    mov? @tmp0, 1\n");
        compiler_out("    mov^ @tmp0, 0\n");
        compiler_out("    push @tmp0\n");
    } else if (op == '*') {
        compiler_out("    ld.d @tmp0, [@tmp0]\n");
        compiler_out("    push @tmp0\n");
    }
}

void op2(int op) {
    compiler_out("    pop @tmp1\n");
    compiler_out("    pop @tmp0\n");
    if (op == '+') {
        compiler_out("    add @tmp0, @tmp1\n");
    } else if (op == '-') {
        compiler_out("    sub @tmp0, @tmp1\n");
    } else if (op == '*') {
        compiler_out("    mul @tmp0, @tmp1\n");
    } else if (op == '/') {
        compiler_out("    div @tmp0, @tmp1\n");
    } else if (op == TOKEN_EQ_OP) {
        compiler_out("    eq @tmp0, @tmp1\n");
        compiler_out("    mov @tmp0, 1\n");
        compiler_out("    mov^ @tmp0, 0\n");
    } else if (op == TOKEN_NE_OP) {
        compiler_out("    eq @tmp0, @tmp1\n");
        compiler_out("    mov @tmp0, 0\n");
        compiler_out("    mov^ @tmp0, 1\n");
    } else if (op == '<') {
        compiler_out("    lt @tmp0, @tmp1\n");
        compiler_out("    mov @tmp0, 1\n");
        compiler_out("    mov^ @tmp0, 0\n");
    } else if (op == '>') {
        compiler_out("    gt @tmp0, @tmp1\n");
        compiler_out("    mov @tmp0, 1\n");
        compiler_out("    mov^ @tmp0, 0\n");
    } else if (op == TOKEN_LE_OP) {
        compiler_out("    gt @tmp0, @tmp1\n");
        compiler_out("    mov @tmp0, 0\n");
        compiler_out("    mov^ @tmp0, 1\n");
    } else if (op == TOKEN_GE_OP) {
        compiler_out("    lt @tmp0, @tmp1\n");
        compiler_out("    mov @tmp0, 0\n");
        compiler_out("    mov^ @tmp0, 1\n");
    }
    compiler_out("    push @tmp0\n");
}

void compile_ternary(int* file, char* buf, int buflen) {
    compile_logical_or(file, buf, buflen);
    
    if (lex_peek(file, buf, buflen) == '?') {
        lex(file, buf, buflen);
        emit_comment("ternary operator");
        
        int label_false = compile_get_next_label();
        int label_end = compile_get_next_label();
        
        compiler_out("    pop @tmp0\n");
        compiler_out("    eq @tmp0, 0\n");
        compiler_out("    jump? .L%d\n", label_false);
        
        compile_expr(file, buf, buflen, 0);
        compiler_read_expect(file, ':');
        
        compiler_out("    jump .L%d\n", label_end);
        emit_label(label_false);
        
        compile_expr(file, buf, buflen, 0);
        
        emit_label(label_end);
    }
}

void compile_logical_or(int* file, char* buf, int buflen) {
    compile_logical_and(file, buf, buflen);
    
    while (lex_peek(file, buf, buflen) == TOKEN_OR_OP) {
        lex(file, buf, buflen);
        emit_comment("operator '||'");
        compile_logical_and(file, buf, buflen);
        op2(TOKEN_OR_OP);
    }
}

void compile_logical_and(int* file, char* buf, int buflen) {
    compile_equality(file, buf, buflen);
    
    while (lex_peek(file, buf, buflen) == TOKEN_AND_OP) {
        lex(file, buf, buflen);
        emit_comment("operator '&&'");
        compile_equality(file, buf, buflen);
        op2(TOKEN_AND_OP);
    }
}

void compile_equality(int* file, char* buf, int buflen) {
    compile_relational(file, buf, buflen);
    
    while (1) {
        int token = lex_peek(file, buf, buflen);
        if ((token == TOKEN_EQ_OP) || (token == TOKEN_NE_OP)) {
            lex(file, buf, buflen);
            emit_comment("operator '%s'", buf);
            compile_relational(file, buf, buflen);
            op2(token);
        } else {
            return;
        }
    }
}

void compile_relational(int* file, char* buf, int buflen) {
    compile_additive(file, buf, buflen);
    
    while (1) {
        int token = lex_peek(file, buf, buflen);
        if ((token == '<') || ((token == '>') || ((token == TOKEN_LE_OP) || (token == TOKEN_GE_OP)))) {
            lex(file, buf, buflen);
            emit_comment("operator '%s'", buf);
            compile_additive(file, buf, buflen);
            op2(token);
        } else {
            return;
        }
    }
}

void compile_additive(int* file, char* buf, int buflen) {
    compile_multiplicative(file, buf, buflen);
    
    while (1) {
        int token = lex_peek(file, buf, buflen);
        if ((token == '+') || (token == '-')) {
            lex(file, buf, buflen);
            emit_comment("operator '%s'", buf);
            compile_multiplicative(file, buf, buflen);
            op2(token);
        } else {
            return;
        }
    }
}

void compile_multiplicative(int* file, char* buf, int buflen) {
    compile_unary(file, buf, buflen);
    
    while (1) {
        int token = lex_peek(file, buf, buflen);
        if ((token == '*') || ((token == '/') || (token == '%'))) {
            lex(file, buf, buflen);
            emit_comment("operator '%s'", buf);
            compile_unary(file, buf, buflen);
            op2(token);
        } else {
            return;
        }
    }
}

void compile_unary(int* file, char* buf, int buflen) {
    int token = lex_peek(file, 0, 0);
    
    if ((token == '-') || (token == '!')) {
        lex(file, buf, buflen);
        emit_comment("unary %c", token);
        compile_unary(file, buf, buflen);
        op1(token);
    } else {
        compile_primary(file, buf, buflen);
    }
}

void compile_primary(int* file, char* buf, int buflen) {
    int token = lex_peek(file, 0, 0);
    int next_token;
    int label;
    int arg_count;

    if (token == TOKEN_CONSTANT) {
        lex(file, buf, buflen);
        push_constant(buf);
    } else if (token == TOKEN_STRING_LITERAL) {
        lex(file, buf, buflen);
        push_string(buf);
    } else if (token == TOKEN_IDENTIFIER) {
        lex(file, buf, buflen);
        next_token = lex_peek(file, 0, 0);
        if (next_token == '(') {
            compile_function_call(file, buf, buflen);
        } else if (next_token == '=') {
            compile_assignment(file, buf, buflen);
        } else {
            if (is_global(buf)) {
                push_global(buf);
            } else {
                push_local(buf);
            }
        }
    } else if (token == '(') {
        compile_expr_paren(file, buf, buflen);
    } else if (token == '[') {
        compile_array_access(file, buf, buflen);
    } else {
        fatal("Unexpected token in compile_primary!\n");
    }
}

void compile_function_call(int* file, char* buf, int buflen) {
    int arg_count = 0;
    int i;
    char func_name[256];
    strcpy(func_name, buf);

    emit_comment("call %s", func_name);
    
    compiler_read_expect(file, '(');
    while (lex_peek(file, 0, 0) != ')') {
        if (arg_count > 0) {
            compiler_read_expect(file, ',');
        }
        emit_comment("arg %d", arg_count);
        compile_expr(file, buf, buflen, 0);
        arg_count = arg_count + 1;
    }
    compiler_read_expect(file, ')');
    
    // Save original register values
    for (i = 0; (i < arg_count) && (i < 8); i = i + 1) {
        push_reg("r%d", i);
    }
    
    // Swap arguments into registers
    for (i = arg_count - 1; (i >= 0) && (i >= (arg_count - 8)); i = i - 1) {
        swap_arg("r%d", ((arg_count - 1) - i) * 8);
    }
    
    // Call the function
    compiler_out("    call :%s\n", func_name);
    
    // Restore original register values
    for (i = arg_count - 1; (i >= 0) && (i >= (arg_count - 8)); i = i - 1) {
        pop_reg(i);
    }
    
    // Clean up any remaining arguments from the stack
    if (arg_count > 8) {
        compiler_out("    add @sp, %d\n", (arg_count - 8) * 8);
    }
    
    push_reg("ret");
}

void compile_assignment(int* file, char* buf, int buflen) {
    char var_name[256];
    strcpy(var_name, buf);

    emit_comment("assign %s", var_name);
    
    compiler_read_expect(file, '=');
    compile_expr(file, buf, buflen, 0);
    
    if (is_global(var_name)) {
        store_global(var_name);
    } else {
        store_local(var_name);
    }
    push_reg("ret");
}

void compile_array_access(int* file, char* buf, int buflen) {
    emit_comment("array access");
    compiler_read_expect(file, '[');
    compile_expr(file, buf, buflen, 0);
    op2('+');
    op1('*');
    compiler_read_expect(file, ']');
}

void compile_expr(int* file, char* buf, int buflen, int precedence) {
    compile_ternary(file, buf, buflen);
}

void compile_expr_paren(int* file, char* buf, int buflen) {
    compiler_read_expect(file, '(');
    compile_expr(file, buf, buflen, 0);
    compiler_read_expect(file, ')');
}

void compile_expr_stack(int* file, char* buf, int buflen) {
    compile_expr(file, buf, buflen, 0);
}

void compile_expr_ret(int* file, char* buf, int buflen) {
    compile_expr_stack(file, buf, buflen);
    compiler_out("    pop @ret\n", buf);
}
