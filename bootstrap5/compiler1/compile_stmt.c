#include "regs.h"
#include "../lex/lex.h"
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static bool function_has_saved_stack = false;

static void compile_block(int file, char* buf, int buflen) {
    compiler_read_expect(file, buf, buflen, '{');
    compiler_out("# {\n");
    
    while (!compiler_peek_is(file, '}')) {
        compile_stmt(file, buf, buflen);
    }
    
    compiler_read_expect(file, buf, buflen, '}');
    compiler_out("# }\n");
}

static void compile_stmt(int file, char* buf, int buflen) {
    int token = lex_peek(file, buf, buflen);
    
    switch (token) {
        case ';':
            return;
        case TOKEN_IF:
            compile_stmt_if(file, buf, buflen);
            return;
        case TOKEN_FOR:
            compile_stmt_for(file, buf, buflen);
            return;
        case TOKEN_WHILE:
            compile_stmt_while(file, buf, buflen);
            return;
        case TOKEN_IDENTIFIER:
        case '*':
            if (strcmp(buf, "__asm__") == 0) {
                compiler_read_expect(file, buf, buflen, TOKEN_IDENTIFIER);
                compiler_read_expect(file, buf, buflen, '(');
                compiler_read_expect(file, buf, buflen, TOKEN_STRING_LITERAL);
                compiler_out("%s\n", buf);
                compiler_read_expect(file, buf, buflen, ')');
                compiler_read_expect(file, buf, buflen, ';');
            } else {
                compile_expr_ret(file, buf, buflen);
                compiler_read_expect(file, buf, buflen, ';');
            }
            return;
        case TOKEN_RETURN:
            compile_stmt_return(file, buf, buflen);
            return;
        default:
            compile_stmt_local(file, buf, buflen);
            return;
    }
}

static void compile_stmt_if(int file, char* buf, int buflen) {
    int else_label = compile_get_next_label();
    int end_label = compile_get_next_label();

    compiler_read_expect(file, buf, buflen, TOKEN_IF);
    compiler_out("# if\n");
    compile_expr_paren_ret(file, buf, buflen);
    compiler_out("# if test\n");
    compiler_out("    eq @ret, 0\n");
    compiler_out("    jump? .else_%d\n", else_label);
    compile_block(file, buf, buflen);
    compiler_out("    jump .end_%d\n", end_label);
    compiler_out(".else_%d\n", else_label);

    while (lex_peek(file, NULL, 0) == TOKEN_ELSE) {
        compiler_read_expect(file, buf, buflen, TOKEN_ELSE);

        if (lex_peek(file, NULL, 0) == TOKEN_IF) {
            lex(file, buf, buflen);
            else_label = compile_get_next_label();
            compiler_out("# else if\n");
            compile_expr_paren_ret(file, buf, buflen);
            compiler_out("# else if test\n");
            compiler_out("    eq @ret, 0\n");
            compiler_out("    jump? .else_%d\n", else_label);
            compile_block(file, buf, buflen);
            compiler_out("    jump .end_%d\n", end_label);
            compiler_out(".else_%d\n", else_label);
        } else {
            compiler_out("# else\n");
            compile_block(file, buf, buflen);
            break;
        }
    }

    compiler_out(".end_%d\n", end_label);
}

static void compile_stmt_for(int file, char* buf, int buflen) {
    int label = compile_get_next_label();

    compiler_read_expect(file, buf, buflen, TOKEN_FOR);
    compiler_read_expect(file, buf, buflen, '(');

    compile_expr_ret(file, buf, buflen);
    compiler_read_expect(file, buf, buflen, ';');

    compiler_out(".test_%d\n", label);
    compile_expr_ret(file, buf, buflen);
    compiler_out("    eq @ret, 0\n");
    compiler_out("    jump^ .begin_%d\n", label);
    compiler_out("    jump .end_%d\n", label);
    compiler_read_expect(file, buf, buflen, ';');

    compiler_out(".inc_%d\n", label);
    compile_expr_ret(file, buf, buflen);
    compiler_out("    jump .test_%d\n", label);

    compiler_read_expect(file, buf, buflen, ')');

    compiler_out(".begin_%d\n", label);
    compile_block(file, buf, buflen);
    compiler_out("    jump .inc_%d\n", label);
    compiler_out(".end_%d\n", label);
}

static void compile_stmt_while(int file, char* buf, int buflen) {
    int label = compile_get_next_label();

    compiler_read_expect(file, buf, buflen, TOKEN_WHILE);
    compiler_read_expect(file, buf, buflen, '(');

    compiler_out(".test_%d\n", label);
    compile_expr_ret(file, buf, buflen);
    compiler_out("    eq @ret, 0\n");
    compiler_out("    jump? .end_%d\n", label);

    compiler_read_expect(file, buf, buflen, ')');

    compiler_out(".begin_%d\n", label);
    compile_block(file, buf, buflen);
    compiler_out("    jump .test_%d\n", label);
    compiler_out(".end_%d\n", label);
}

static void compile_stmt_return(int file, char* buf, int buflen) {
    compiler_read_expect(file, buf, buflen, TOKEN_RETURN);
    compiler_out("# return\n");
    
    if (lex_peek(file, NULL, 0) != ';') {
        compile_expr_ret(file, buf, buflen);
    }
    
    if (function_has_saved_stack) {
        compiler_out("    pop @tmp0\n");
        compiler_out("    mov @sp, @tmp0\n");
    }
    
    compiler_out("    %ret\n");
    compiler_read_expect(file, buf, buflen, ';');
}

static void compile_stmt_local(int file, char* buf, int buflen) {
    if (function_has_saved_stack) {
        fatal("No locals may appear after an array local\n");
    }

    int size = compile_function_type(file, buf, buflen);
    compiler_out("# local\n");
    compiler_read_expect(file, buf, buflen, TOKEN_IDENTIFIER);
    track_local(buf, size);
    
    if (is_global(buf)) {
        fatal("Local cannot shadow a global");
    }
    
    compiler_out("    %local %s\n", buf);
    
    int token = lex_peek(file, NULL, 0);
    if (token == '[') {
        function_has_saved_stack = true;
        
        char local_name[32];
        strncpy(local_name, buf, sizeof(local_name));
        
        compiler_read_expect(file, NULL, 0, '[');
        compiler_read_expect(file, buf, buflen, TOKEN_CONSTANT);
        compiler_read_expect(file, NULL, 0, ']');
        
        compiler_out("    mov @tmp0, @sp\n");
        compiler_out("    mov @tmp1, %s\n", buf);
        compiler_out("    mul @tmp1, %d\n", size);
        compiler_out("    sub @sp, @tmp1\n");
        compiler_out("    mov @%s, @sp\n", local_name);
        compiler_out("    push @tmp0\n");
    } else if (token == '=') {
        int label = compile_get_next_label();
        compiler_out("# assign %s (#%d)\n", buf, label);
        compiler_out("    jump .assign_value_1_%d\n", label);
        compiler_out(".assign_value_2_%d\n", label);
        compiler_out("    mov @%s, @ret\n", buf);
        compiler_out("    jump .assign_value_3_%d\n", label);
        compiler_read_expect(file, NULL, 0, '=');
        compiler_out(".assign_value_1_%d\n", label);
        compile_expr_ret(file, buf, buflen);
        compiler_out("    jump .assign_value_2_%d\n", label);
        compiler_out(".assign_value_3_%d\n", label);
    }

    compiler_read_expect(file, buf, buflen, ';');
}
