#include "lex/lex.h"

void lookup_struct() {
}

void lookup_type() {
}

void is_type_token() {
}

// Type bit layout
// WXYZ
// Z = type (bit 0 = signed, bits 1..7 = (void/char/short/int/struct))
// Y = pointer count (char = 0, char* = 1, char** = 2, etc)

// Returns a parsed type integer with bitfields indicating the type
int parse_type() {
    int token;
    int type = 0;
    int pointer_count = 0;

    while (1) {
        token = lex_peek();
        if (!is_type_token(token)) {
            return type | pointer_count;
        }

        token = lex_read();
        if (token == '*') {
            pointer_count = pointer_count + 1;
        }
        if (token == TOKEN_UNSIGNED) {
            type = type | 1;
        }
        if (token == TOKEN_VOID) {
            type = type | (0 << 1);
        }
        if (token == TOKEN_CHAR) {
            type = type | (1 << 1);
        }
        if (token == TOKEN_SHORT) {
            type = type | (2 << 1);
        }
        if (token == TOKEN_INT) {
            type = type | (4 << 1);
        }
        if (token == TOKEN_IDENTIFIER) {
            type = lookup_type(lex_token_buffer());
        }
        if (token == TOKEN_STRUCT) {
            type = lookup_struct(lex_token_buffer());
        }
    }
}
