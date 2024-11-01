#define NULL 0
#define TOKEN_SIZE 256
#include "lex/lex.h"
#include "compiler1/type.h"

extern int* global_scope;

void compile_translation_unit() {
    int token;

    while (1) {
        token = compiler_peek(NULL);
        if ((token == TOKEN_EOF) || (token == TOKEN_NONE)) {
            // End of file
            return;
        }

        if (type_is_type_token(token)) {
            // This could be a function or a global variable declaration
            compile_declaration();
        } else {
            compiler_fatal("Unexpected token at global scope");
        }
    }
}

void compile_type_declaration(int* base_type) {
    compiler_out("# Type declaration\n# ");
    type_print(base_type);
    compiler_out("\n\n");
    compiler_read_expect(';');
}

void compile_fn_declaration(int* base_type, char* name) {
    scope_add(global_scope, stralloc(name), base_type);
    compiler_out("# Function declaration: %s\n# ", name);
    type_print(base_type);
    compiler_out("\n");

    compile_function(base_type, name);
}

void compile_fn_forward_declaration(int* base_type, char* name) {
    scope_add(global_scope, stralloc(name), base_type);
    compiler_out("# Function forward declaration: %s\n# ", name);
    type_print(base_type);
    compiler_out("\n\n");
    compiler_read_expect(';');
}

void compile_variable_declaration(int* base_type, char* name) {
    int size;
    scope_add(global_scope, stralloc(name), base_type);
    compiler_out("# Variable declaration: %s\n# ", name);
    type_print(base_type);
    size = type_size(base_type);
    compiler_out("\n# Size: %d\n", size);
    compiler_out(":%s\n", name);
    compiler_out("\tdz %d\n\n", size);
    compiler_read_expect(';');
}

void compile_declaration() {
    int* base_type;
    int* type;
    int next_token;
    char name[TOKEN_SIZE];

    base_type = parse_type_specifier(name);
    if (name[0] == 0) {
        if (type_get_kind(base_type) != TYPE_STRUCT) {
            compiler_fatal("Invalid type declaration");
        }
        compile_type_declaration(base_type);
    } else {
        if (type_get_kind(base_type) == TYPE_FUNCTION) {
            next_token = compiler_peek(NULL);
            if (next_token == '{') {
                compile_fn_declaration(base_type, name);
            } else {
                compile_fn_forward_declaration(base_type, name);
            }
        } else {
            compile_variable_declaration(base_type, name);
        }
    }
}
