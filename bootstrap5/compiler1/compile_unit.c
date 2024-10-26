#define NULL 0
#define TOKEN_SIZE 256
#include "lex/lex.h"

void compile_translation_unit() {
    int token;

    while (1) {
        token = compiler_peek(NULL);
        printf("token: %d\n", token);
        if ((token == TOKEN_EOF) || (token == TOKEN_NONE)) {
            // End of file
            return;
        }

        if (type_is_type_token(token)) {
            // This could be a function or a global variable declaration
            compile_function_or_declaration();
        } else {
            compiler_fatal("Unexpected token at global scope");
        }
    }
}

void compile_function_or_declaration() {
    int* base_type;
    int* type;
    int next_token;
    char name[TOKEN_SIZE];

    base_type = parse_type_specifier(name);
    printf("name: %s\n", name);
    type_print(base_type);
    printf("\n");
    next_token = compiler_peek(name);
    printf("next_token: %d %s\n", next_token, name);
    if (next_token == '{') {
        compiler_fatal("Function declaration not supported");
    } else {
        compiler_read_expect(';');
    }
}
