#define NULL 0
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
int* compile_ternary();
int* compile_logical_or();
int* compile_logical_and();
int* compile_equality();
int* compile_relational();
int* compile_additive();
int* compile_multiplicative();
int* compile_unary();
int* compile_primary();
int* compile_function_call();
int* compile_assignment();
int* compile_array_access();
int* compile_expr(int precedence);
int* compile_expr_paren();
int* compile_expr_stack();
void compile_expr_ret();
int* compile_struct_access();
int* compile_struct_deref();

int* binary_expressions = 0;
int compile_next_label = 0;

extern char* lex_buffer;
extern int* function_scope;
extern int* global_scope;

extern int* type_int;
extern int* type_char_ptr;

int compile_get_next_label() {
    int tmp = compile_next_label;
    compile_next_label = compile_next_label + 1;
    return tmp;
}

void emit_comment(char* format, int arg0, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6) {
    compiler_out("# ");
    compiler_out(format, arg0, arg1, arg2, arg3, arg4, arg5, arg6);
    compiler_out("\n");
}

// Helper functions for stack operations
void push_constant(char* value) {
    compiler_out("    push %s\n", value);
}

void push_constant_number(int value) {
    compiler_out("    push %d\n", value);
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
    compiler_out("    mov @ctmp0, @fp\n");
    compiler_out("    add, @ctmp0, @L_%s\n", var);
    compiler_out("    push @ctmp0\n");
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

int* compile_ternary() {
    int token;
    int label_false;
    int label_end;
    int* type;

    type = compile_logical_or();
    
    token = compiler_peek(NULL);
    if (token == '?') {
        compiler_read_expect(token);
        emit_comment("ternary operator");
        
        label_false = compile_get_next_label();
        label_end = compile_get_next_label();
        
        compiler_out("    pop @tmp0\n");
        compiler_out("    eq @tmp0, 0\n");
        compiler_out("    jump? .L%d\n", label_false);
        
        type = compile_expr(0);
        compiler_read_expect(':');
        
        compiler_out("    jump .L%d\n", label_end);
        emit_label(label_false);
        
        type = compile_expr(0);
        
        emit_label(label_end);
    }
    return type;
}

int* compile_logical_or() {
    int token;
    int* type = compile_logical_and();
    
    token = compiler_peek(NULL);
    if (token == TOKEN_OR_OP) {
        compiler_read_expect(token);
        type = compile_logical_and();
        emit_comment("operator '||'");
        op2(TOKEN_OR_OP);
    }
    return type;
}

int* compile_logical_and() {
    int token;
    int* type = compile_equality();
    
    token = compiler_peek(NULL);
    if (token == TOKEN_AND_OP) {
        compiler_read_expect(token);
        type = compile_equality();
        emit_comment("operator '&&'");
        op2(TOKEN_AND_OP);
    }
    return type;
}

int* compile_equality() {
    int token;
    int* type = compile_relational();
    
    while (1) {
        token = compiler_peek(NULL);
        if ((token == TOKEN_EQ_OP) || (token == TOKEN_NE_OP)) {
            compiler_read_expect(token);
            type = compile_relational();
            emit_comment("operator '%s'", lex_buffer);
            op2(token);
        } else {
            return type;
        }
    }
}

int* compile_relational() {
    int token;
    int* type = compile_additive();
    
    while (1) {
        token = compiler_peek(NULL);
        if ((token == '<') || ((token == '>') || ((token == TOKEN_LE_OP) || (token == TOKEN_GE_OP)))) {
            compiler_read_expect(token);
            type = compile_additive();
            emit_comment("operator '%s'", lex_buffer);
            op2(token);
        } else {
            return type;
        }
    }
}

int* compile_additive() {
    int token;
    int* type = compile_multiplicative();
    
    while (1) {
        token = compiler_peek(NULL);
        if ((token == '+') || (token == '-')) {
            compiler_read_expect(token);
            type = compile_multiplicative();
            emit_comment("operator '%s'", lex_buffer);
            op2(token);
        } else {
            return type;
        }
    }
}

int* compile_multiplicative() {
    int token;
    int* type = compile_unary();
    
    while (1) {
        token = compiler_peek(NULL);
        if ((token == '*') || ((token == '/') || (token == '%'))) {
            compiler_read_expect(token);
            type = compile_unary();
            emit_comment("operator '%s'", lex_buffer);
            op2(token);
        } else {
            return type;
        }
    }
}

int* compile_unary() {
    int token = compiler_peek(NULL);
    int* type;
    
    if ((token == '-') || (token == '!')) {
        compiler_read_expect(token);
        type = compile_unary();
        emit_comment("unary %c", token);
        op1(token);
    } else {
        type = compile_primary();
    }
    return type;
}

int* compile_primary() {
    int token;
    int next_token;
    int label;
    int arg_count;
    int* type;
    char primary_buffer[256];

    token = compiler_peek(primary_buffer);
    emit_comment("primary %s", primary_buffer);

    if (token == TOKEN_SIZEOF) {
        return compile_sizeof();
    } else if (token == TOKEN_CONSTANT) {
        compiler_read_expect(token);
        push_constant(primary_buffer);
        return type_int;
    } else if (token == TOKEN_STRING_LITERAL) {
        compiler_read_expect(token);
        push_string(primary_buffer);
        return type_char_ptr;
    } else if (token == TOKEN_IDENTIFIER) {
        compiler_read_expect(token);
        next_token = compiler_peek(NULL);
        if (next_token == '(') {
            return compile_function_call(primary_buffer);
        } else if (next_token == '=') {
            return compile_assignment(primary_buffer);
        } else if (next_token == '.') {
            return compile_struct_access(primary_buffer);
        } else if (next_token == TOKEN_PTR_OP) {
            return compile_struct_deref(primary_buffer);
        } else {
            type = scope_lookup(global_scope, primary_buffer);
            if (type) {
                push_global(primary_buffer);
            } else {
                type = scope_lookup(function_scope, primary_buffer);
                if (type) {
                    push_local(primary_buffer);
                } else {
                    compiler_fatal("Unknown identifier '%s'", primary_buffer);
                }
            }
            return type;
        }
    } else if (token == '(') {
        return compile_expr_paren();
    } else if (token == '[') {
        return compile_array_access();
    } else {
        compiler_fatal("Unexpected token in compile_primary!\n");
    }
}

int* compile_sizeof() {
    int token;
    int* type;    
    char name[256];

    compiler_read_expect(TOKEN_SIZEOF);
    compiler_read_expect('(');

    token = compiler_peek(name);
    if (type_is_type_token(token)) {
        type = parse_type_specifier(name);
        compiler_read_expect(')');
        push_constant_number(type_size(type));
    } else if (token == TOKEN_IDENTIFIER) {
        compiler_read_expect(TOKEN_IDENTIFIER);
        type = scope_lookup(function_scope, name);
        if (!type) {
            type = scope_lookup(global_scope, name);
            if (!type) {
                compiler_fatal("Unknown identifier for sizeof: '%s'", name);
            }
        }
        compiler_read_expect(')');
        push_constant_number(type_size(type));
    } else {
        compiler_fatal("Invalid sizeof argument");
    }
    return type_int;
}

int* compile_function_call(char* func_name) {
    int arg_count = 0;
    int i;

    emit_comment("call %s", func_name);
    
    compiler_read_expect('(');
    while (compiler_peek(NULL) != ')') {
        if (arg_count > 0) {
            compiler_read_expect(',');
        }
        emit_comment("arg %d", arg_count);
        compile_expr(0);
        arg_count = arg_count + 1;
    }
    compiler_read_expect(')');
    
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
    return NULL; // TODO: Return function return type
}

int* compile_assignment() {
    int* type;
    char var_name[256];
    strcpy(var_name, lex_buffer);

    emit_comment("assign %s", var_name);
    
    compiler_read_expect('=');
    type = compile_expr(0);
    
    type = scope_lookup(global_scope, var_name);
    if (type) {
        store_global(var_name);
    } else {
        type = scope_lookup(function_scope, var_name);
        if (type) {
            store_local(var_name);
        } else {
            compiler_fatal("Unknown identifier '%s'", var_name);
        }
    }
    push_reg("ret");
    return type;
}

int* compile_array_access() {
    int* type;
    emit_comment("array access");
    compiler_read_expect('[');
    type = compile_expr(0);
    op2('+');
    op1('*');
    compiler_read_expect(']');
    return type;
}

int* compile_struct_access() {
    // TODO: Implement struct member access (.)
    return NULL;
}

int* compile_struct_deref() {
    // TODO: Implement struct pointer dereference (->)
    return NULL;
}

int* compile_expr(int precedence) {
    return compile_ternary();
}

int* compile_expr_paren() {
    int* type;
    compiler_read_expect('(');
    type = compile_expr(0);
    compiler_read_expect(')');
    return type;
}

int* compile_expr_stack() {
    return compile_expr(0);
}

void compile_expr_ret() {
    compile_expr_stack();
    compiler_out("    pop @ret\n", lex_buffer);
}
