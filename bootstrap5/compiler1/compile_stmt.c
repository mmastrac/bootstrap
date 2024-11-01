#define NULL 0
#define TOKEN_SIZE 256
#include "lex/lex.h"

extern int function_locals_size;
extern int* function_scope;

void compile_block() {
    compiler_read_expect('{');
    compiler_out("# {\n");
    
    while (compiler_peek(NULL) != '}') {
        compile_stmt();
    }
    
    compiler_read_expect('}');
    compiler_out("# }\n");
}   

void compile_stmt() {
    int token = compiler_peek(NULL);
    
    if (token == ';') {
        return;
    } else if (token == TOKEN_IF) {
        compile_stmt_if();
        return;
    } else if (token == TOKEN_FOR) {
        compile_stmt_for(); 
        return;
    } else if (token == TOKEN_WHILE) {
        compile_stmt_while();
        return;
    } else if (token == TOKEN_ASM) {
        // compiler_read_expect(TOKEN_IDENTIFIER);
        // compiler_read_expect('(');
        // compiler_read_expect(TOKEN_STRING_LITERAL);
        // compiler_out("%s\n", lex_buffer);
        // compiler_read_expect(')');
        // compiler_read_expect(';');
        return;
    } else if ((token == TOKEN_IDENTIFIER) || (token == '*')) {
        compile_expr_ret();
        compiler_read_expect(';');
        return;
    } else if (token == TOKEN_RETURN) {
        compile_stmt_return();
        return;
    } else if (type_is_type_token(token)){
        compile_stmt_local();
        return;
    } else {
        compiler_fatal("Unexpected token: %d", token);
    }
}

void compile_stmt_if() {
//     int else_label = compile_get_next_label();
//     int end_label = compile_get_next_label();

//     compiler_read_expect(TOKEN_IF);
//     compiler_out("# if\n");
//     compile_expr_paren_ret();
//     compiler_out("# if test\n");
//     compiler_out("    eq @ret, 0\n");
//     compiler_out("    jump? .else_%d\n", else_label);
//     compile_block();
//     compiler_out("    jump .end_%d\n", end_label);
//     compiler_out(".else_%d\n", else_label);

//     while (compiler_peek(NULL) == TOKEN_ELSE) {
//         compiler_read_expect(TOKEN_ELSE);

//         if (compiler_peek(NULL) == TOKEN_IF) {
//             lex(lex_file, lex_buffer, TOKEN_SIZE);
//             else_label = compile_get_next_label();
//             compiler_out("# else if\n");
//             compile_expr_paren_ret();
//             compiler_out("# else if test\n");
//             compiler_out("    eq @ret, 0\n");
//             compiler_out("    jump? .else_%d\n", else_label);
//             compile_block();
//             compiler_out("    jump .end_%d\n", end_label);
//             compiler_out(".else_%d\n", else_label);
//         } else {
//             compiler_out("# else\n");
//             compile_block();
//             break;
//         }
//     }

//     compiler_out(".end_%d\n", end_label);
}

void compile_stmt_for() {
//     int label = compile_get_next_label();

//     compiler_read_expect(TOKEN_FOR);
//     compiler_read_expect('(');

//     compile_expr_ret();
//     compiler_read_expect(';');

//     compiler_out(".test_%d\n", label);
//     compile_expr_ret();
//     compiler_out("    eq @ret, 0\n");
//     compiler_out("    jump^ .begin_%d\n", label);
//     compiler_out("    jump .end_%d\n", label);
//     compiler_read_expect(';');

//     compiler_out(".inc_%d\n", label);
//     compile_expr_ret();
//     compiler_out("    jump .test_%d\n", label);

//     compiler_read_expect(')');

//     compiler_out(".begin_%d\n", label);
//     compile_block();
//     compiler_out("    jump .inc_%d\n", label);
//     compiler_out(".end_%d\n", label);
}

void compile_stmt_while() {
//     int label = compile_get_next_label();

//     compiler_read_expect(TOKEN_WHILE);
//     compiler_read_expect('(');

//     compiler_out(".test_%d\n", label);
//     compile_expr_ret();
//     compiler_out("    eq @ret, 0\n");
//     compiler_out("    jump? .end_%d\n", label);

//     compiler_read_expect(')');

//     compiler_out(".begin_%d\n", label);
//     compile_block();
//     compiler_out("    jump .test_%d\n", label);
//     compiler_out(".end_%d\n", label);
}

void compile_stmt_return() {
    compiler_read_expect(TOKEN_RETURN);
    compiler_out("# return\n");
    
    if (compiler_peek(NULL) != ';') {
        compile_expr_ret();
    }
    
    compiler_out("\tjump .__exit\n");
    compiler_read_expect(';');
}

void compile_stmt_local() {
    int* base_type;
    int token;
    int size;
    char name[TOKEN_SIZE];

    base_type = parse_type_specifier(name);
    scope_add(function_scope, stralloc(name), base_type);
    size = type_size(base_type);
    function_locals_size = function_locals_size + size;
    compiler_out("# local %s (%d)\n", name, size);
    compiler_out("#define L_%s %d\n", name, function_locals_size);

    token = compiler_peek(name);
    if (token == ',') {
        compiler_out("\tpush 0\n");
        compiler_read_expect(token);
        compiler_fatal("Not implemented");
    } else if (token == '=') {
        compiler_read_expect(token);
        compile_expr_stack();
        compiler_read_expect(';');
        return;
    } else if (token == ';') {
        compiler_out("\tpush 0\n");
        compiler_read_expect(token);
        return;
    } else {
        compiler_fatal("Unexpected token in compile_stmt_local");
    }
}
