#include "regs.h"
#include "../bootstrap4/lex/lex.h"

int binary_expression_table[][2] = {
    {TOKEN_EQ_OP, (int)"    eq @tmp0, @tmp1\n    mov @tmp0, 1\n    mov^ @tmp0, 0"},
    {TOKEN_NE_OP, (int)"    eq @tmp0, @tmp1\n    mov @tmp0, 0\n    mov^ @tmp0, 1"},
    {TOKEN_GE_OP, (int)"    lt @tmp0, @tmp1\n    mov @tmp0, 0\n    mov^ @tmp0, 1"},
    {TOKEN_LE_OP, (int)"    gt @tmp0, @tmp1\n    mov @tmp0, 0\n    mov^ @tmp0, 1"},
    {TOKEN_LEFT_OP, (int)""},
    {TOKEN_RIGHT_OP, (int)""},
    {TOKEN_AND_OP, (int)""},
    {TOKEN_OR_OP, (int)""},
    {'<', (int)"    lt @tmp0, @tmp1\n    mov @tmp0, 1\n    mov^ @tmp0, 0"},
    {'>', (int)"    gt @tmp0, @tmp1\n    mov @tmp0, 1\n    mov^ @tmp0, 0"},
    {'+', (int)"    add @tmp0, @tmp1"},
    {'-', (int)"    sub @tmp0, @tmp1"},
    {'/', (int)"    div @tmp0, @tmp1"},
    {'*', (int)"    mul @tmp0, @tmp1"},
    {'|', (int)""},
    {'&', (int)""},
    {0, 0}
};

int* binary_expressions = 0;
int compile_next_label = 0;

int compile_get_next_label() {
    int tmp = compile_next_label;
    compile_next_label = compile_next_label + 1;
    return tmp;
}

void compile_expr_ret(int* file, char* buf, int buflen) {
    compile_expr_stack(file, buf, buflen);
    compiler_out("    pop @ret\n", buf);
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

void emit_comment(char* format, int arg0, int arg1, int arg2) {
    compiler_out("# ");
    compiler_out(format, arg0, arg1, arg2);
}

void emit_jump(char* label) {
    compiler_out("    jump %s\n", label);
}

void emit_label(char* label) {
    compiler_out("%s\n", label);
}

void emit_call(char* func) {
    compiler_out("    %%call :%s, @arg0, @arg1, @arg2, @arg3, @arg4, @arg5, @arg6, @arg7\n", func);
}

void op1(char* op) {
    compiler_out("    pop @tmp0\n");
    if (strcmp(op, "neg") == 0) {
        compiler_out("    mov @tmp1, 0\n");
        compiler_out("    sub @tmp1, @tmp0\n");
        compiler_out("    push @tmp1\n");
    } else if (strcmp(op, "not") == 0) {
        compiler_out("    eq @tmp0, 0\n");
        compiler_out("    mov? @tmp0, 1\n");
        compiler_out("    mov^ @tmp0, 0\n");
        compiler_out("    push @tmp0\n");
    } else if (strcmp(op, "load") == 0) {
        compiler_out("    ld.d @tmp0, [@tmp0]\n");
        compiler_out("    push @tmp0\n");
    }
}

void op2(char* op) {
    compiler_out("    pop @tmp1\n");
    compiler_out("    pop @tmp0\n");
    if (strcmp(op, "add") == 0) {
        compiler_out("    add @tmp0, @tmp1\n");
    } else if (strcmp(op, "sub") == 0) {
        compiler_out("    sub @tmp0, @tmp1\n");
    } else if (strcmp(op, "mul") == 0) {
        compiler_out("    mul @tmp0, @tmp1\n");
    } else if (strcmp(op, "div") == 0) {
        compiler_out("    div @tmp0, @tmp1\n");
    } else if (strcmp(op, "eq") == 0) {
        compiler_out("    eq @tmp0, @tmp1\n");
        compiler_out("    mov @tmp0, 1\n");
        compiler_out("    mov^ @tmp0, 0\n");
    } else if (strcmp(op, "ne") == 0) {
        compiler_out("    eq @tmp0, @tmp1\n");
        compiler_out("    mov @tmp0, 0\n");
        compiler_out("    mov^ @tmp0, 1\n");
    } else if (strcmp(op, "lt") == 0) {
        compiler_out("    lt @tmp0, @tmp1\n");
        compiler_out("    mov @tmp0, 1\n");
        compiler_out("    mov^ @tmp0, 0\n");
    } else if (strcmp(op, "gt") == 0) {
        compiler_out("    gt @tmp0, @tmp1\n");
        compiler_out("    mov @tmp0, 1\n");
        compiler_out("    mov^ @tmp0, 0\n");
    } else if (strcmp(op, "le") == 0) {
        compiler_out("    gt @tmp0, @tmp1\n");
        compiler_out("    mov @tmp0, 0\n");
        compiler_out("    mov^ @tmp0, 1\n");
    } else if (strcmp(op, "ge") == 0) {
        compiler_out("    lt @tmp0, @tmp1\n");
        compiler_out("    mov @tmp0, 0\n");
        compiler_out("    mov^ @tmp0, 1\n");
    }
    compiler_out("    push @tmp0\n");
}

void compile_expr_stack(int* file, char* buf, int buflen) {
    int saved_op;
    int* ht;
    int label;
    int arg_count;

    ht = binary_expressions;
    if (ht == 0) {
        ht = ht_init(ht_int_key_hash, ht_int_key_compare);
        binary_expressions = ht;
        ht_insert_table(ht, binary_expression_table);
    }

    int token = lex_peek(file, 0, 0);
    
    if (token == TOKEN_CONSTANT) {
        lex(file, buf, buflen);
        push_constant(buf);
    } else if (token == TOKEN_STRING_LITERAL) {
        lex(file, buf, buflen);
        push_string(buf);
    } else if (token == TOKEN_IDENTIFIER) {
        lex(file, buf, buflen);
        int next_token = lex_peek(file, 0, 0);
        if (next_token == '(') {
            // Function call
            label = compile_get_next_label();
            arg_count = 0;
            emit_comment("call %s", buf);
            emit_jump(".setup_args_1_%d", label);
            emit_label(".setup_args_2_%d", label);
            emit_call(buf);
            push_reg("ret");
            emit_jump(".setup_args_3_%d", label);
            emit_label(".setup_args_1_%d", label);
            compiler_read_expect(file, buf, buflen, '(');
            while (1) {
                token = lex_peek(file, 0, 0);
                if (token == ')') break;
                if (token == ',') {
                    compiler_read_expect(file, buf, buflen, ',');
                    continue;
                }
                emit_comment("arg");
                compile_expr_stack(file, buf, buflen);
                emit_comment("arg");
                arg_count = arg_count + 1;
            }
            while (arg_count > 0) {
                arg_count = arg_count - 1;
                pop_arg(arg_count);
            }
            compiler_read_expect(file, buf, buflen, ')');
            emit_jump(".setup_args_2_%d", label);
            emit_label(".setup_args_3_%d", label);
        } else if (next_token == '=') {
            // Assignment
            label = compile_get_next_label();
            emit_comment("assign %s (#%d)", buf, label);
            emit_jump(".assign_value_1_%d", label);
            emit_label(".assign_value_2_%d", label);
            if (is_global(buf)) {
                store_global(buf);
            } else {
                store_local(buf);
            }
            push_reg("ret");
            emit_jump(".assign_value_3_%d", label);
            compiler_read_expect(file, 0, 0, '=');
            emit_label(".assign_value_1_%d", label);
            compile_expr_ret(file, buf, buflen);
            emit_jump(".assign_value_2_%d", label);
            emit_label(".assign_value_3_%d", label);
        } else {
            // Variable
            if (is_global(buf)) {
                push_global(buf);
            } else {
                push_local(buf);
            }
        }
    } else if (token == '(') {
        compile_expr_paren_stack(file, buf, buflen);
    } else if (token == '-') {
        lex(file, buf, buflen);
        emit_comment("unary neg");
        compile_expr_stack(file, buf, buflen);
        op1("neg");
    } else if (token == '!') {
        lex(file, buf, buflen);
        emit_comment("unary not");
        compile_expr_stack(file, buf, buflen);
        op1("not");
    } else {
        fatal("Unexpected token in compile_expr_stack!\n");
    }

    saved_op = lex_peek(file, buf, buflen);
    if (saved_op != ')' && saved_op != ',' && saved_op != ';' && saved_op != ']') {
        lex(file, buf, buflen);
        if (saved_op == '[') {
            compile_expr_stack(file, buf, buflen);
            op2("add");
            op1("load");
            compiler_read_expect(file, buf, buflen, ']');
        } else {
            emit_comment("operator '%s'", buf);
            compile_expr_stack(file, buf, buflen);
            char* op_code = ht_lookup(ht, saved_op);
            if (op_code == 0) {
                fatal("Unexpected binary operation\n");
            }
            op2(op_code);
        }
    }

    emit_comment("expr end");
}

void compile_expr_paren_stack(int* file, char* buf, int buflen) {
    compiler_read_expect(file, buf, buflen, '(');
    compile_expr_stack(file, buf, buflen);
    compiler_read_expect(file, buf, buflen, ')');
}

void compile_expr_paren_ret(int* file, char* buf, int buflen) {
    compiler_read_expect(file, buf, buflen, '(');
    compile_expr_ret(file, buf, buflen);
    compiler_read_expect(file, buf, buflen, ')');
}
