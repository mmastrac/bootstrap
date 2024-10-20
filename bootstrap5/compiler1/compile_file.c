#include "lex/lex.h"

// Because we have an identifier in the mix, this pushes and then pops the token context, leaving the identifier
// in the token buffer for use by calling code.
int compile_declarator() {

}

void compile_translation_unit() {
    int type;

    while (1) {
        if (lex_peek() == TOKEN_EOF) {
            return;
        }

        // // Regardless of declaration, we have a type first (optionally with specifiers attached)
        type = compile_declarator();
    }
}
