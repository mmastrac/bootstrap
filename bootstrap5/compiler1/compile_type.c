#include "lex/lex.h"
#include "compiler1/type.h"
#define NULL 0

// The type for an int (used for sizeof)
int type_int[] = { TYPE_INT, NULL, 0, NULL, NULL };
// The type for a char
int type_char[] = { TYPE_CHAR, NULL, 0, NULL, NULL };

// The type for a char pointer (used for string literals)
int type_char_ptr[] = { TYPE_POINTER, _type_char, 0, NULL, NULL };

int* type_new(int kind, int* base, int size, int* fields, char* name) {
    int* type = malloc(20);
    type[0] = kind;
    type[1] = base;
    type[2] = size;
    type[3] = fields;
    type[4] = name;
    return type;
}

int type_get_kind(int* type) {
    return type[0];
}

int* type_get_base(int* type) {
    return type[1];
}

// Count of array items or struct fields
int* type_get_field_size(int* type) {
    return type[2];
}

int* type_get_fields(int* type) {
    return type[3];
}

char* type_get_name(int* type) {
    return type[4];
}

char* type_get_subtype_name(int* type, int index) {
    return type_get_fields(type)[(index * 2) + 0];
}

int* type_get_subtype_type(int* type, int index) {
    return type_get_fields(type)[(index * 2) + 1];
}

int type_size(int* type) {
    int kind = type_get_kind(type);
    int* base;
    int size;
    int* fields;
    int field_count;
    int* field_type;
    int i;

    if (kind == TYPE_VOID) {
        return 0;
    } else if (kind == TYPE_CHAR) {
        return 1;
    } else if ((kind == TYPE_INT) || (kind == TYPE_FLOAT)) {
        return 4;
    } else if (kind == TYPE_DOUBLE) {
        return 8;
    } else if (kind == TYPE_POINTER) {
        return 4;
    } else if (kind == TYPE_ARRAY) {
        base = type_get_base(type);
        size = type_get_field_size(type);
        return size * type_size(base);
    } else if (kind == TYPE_FUNCTION) {
        return 1; // Match GCC
    } else if (kind == TYPE_STRUCT) {
        size = 0;
        field_count = type_get_field_size(type);
        for (i = 0; i < field_count; i = i + 1) {
            field_type = type_get_subtype_type(type, i);
            size = size + type_size(field_type);
        }
        return size;
    } else {
        compiler_fatal("unknown type: %d", kind);
        return 0;
    }
}

void type_print(int* type) {
    int kind = type_get_kind(type);
    int* base;
    int size;
    int* fields;
    int field_count;
    int* field_type;
    int i;
    char* field_name;

    if (type == NULL) {
        compiler_out("<null type>");
    } if (kind == TYPE_VOID) {
        compiler_out("void");
    } else if (kind == TYPE_CHAR) {
        compiler_out("char");
    } else if (kind == TYPE_INT) {
        compiler_out("int");
    } else if (kind == TYPE_FLOAT) {
        compiler_out("float");
    } else if (kind == TYPE_DOUBLE) {
        compiler_out("double");
    } else if (kind == TYPE_POINTER) {
        base = type_get_base(type);
        compiler_out("pointer to (");
        type_print(base);
        compiler_out(")");
    } else if (kind == TYPE_ARRAY) {
        base = type_get_base(type);
        compiler_out("array %d of (", type_get_field_size(type));
        type_print(base);
        compiler_out(")");
    } else if (kind == TYPE_FUNCTION) {
        base = type_get_base(type);
        compiler_out("function ");
        field_name = type_get_name(type);
        if (field_name) {
            compiler_out("%s ", field_name);
        }
        compiler_out("(");
        field_count = type_get_field_size(type);
        for (i = 0; i < field_count; i = i + 1) {
            if (i > 0) {
                compiler_out("; ");
            }
            field_name = type_get_subtype_name(type, i);
            field_type = type_get_subtype_type(type, i);
            type_print(field_type);
            compiler_out(" %s", field_name);
        }
        compiler_out(") returning (");
        type_print(base);
        compiler_out(")");
    } else if (kind == TYPE_STRUCT) {
        compiler_out("struct ");
        field_name = type_get_name(type);
        if (field_name) {
            compiler_out("%s ", field_name);
        }
        compiler_out("{ ");
        field_count = type_get_field_size(type);
        for (i = 0; i < field_count; i = i + 1) {
            field_name = type_get_subtype_name(type, i);
            field_type = type_get_subtype_type(type, i);
            type_print(field_type);
            compiler_out(" %s; ", field_name);
        }
        compiler_out("}");
    } else {
        compiler_fatal("unknown type: %d", kind);
    }
}

// Parse the base type specifier (e.g., int, char)
int* parse_base_type_specifier() {
    int type;
    int token;
    int members;
    int i;
    char* name;
    char buffer[256];

    token = compiler_peek(buffer);

    if (token == TOKEN_INT) {
        type = TYPE_INT;
    } else if (token == TOKEN_CHAR) {
        type = TYPE_CHAR;
    } else if (token == TOKEN_FLOAT) {
        type = TYPE_FLOAT;
    } else if (token == TOKEN_DOUBLE) {
        type = TYPE_DOUBLE;
    } else if (token == TOKEN_VOID) {
        type = TYPE_VOID;
    } else if (token == TOKEN_STRUCT) {
        type = TYPE_STRUCT;
        compiler_read(NULL);
        token = compiler_peek(buffer);
        members = malloc(16 * 4);
        name = NULL;

        // This might be either a struct identifier or a struct tag
        if (token == TOKEN_IDENTIFIER) {
            compiler_read(buffer);
            name = stralloc(buffer);
            token = compiler_peek(buffer);
        } 
        
        if (token == '{') {
            i = 0;
            compiler_read_expect('{');
            while (compiler_peek(NULL) != '}') {
                if (i == 6) {
                    compiler_fatal("Struct too big");
                }
                type = parse_type_specifier(buffer);
                members[(i * 2) + 0] = stralloc(buffer);
                members[(i * 2) + 1] = type;
                i = i + 1;
                compiler_read_expect(';');
            }
            compiler_read_expect('}');
            return type_new(TYPE_STRUCT, NULL, i, members, name);
        } else {
            compiler_fatal("unknown token for struct: %s (%d)", token, buffer);
        }
    } else {
        compiler_fatal("unknown token for type: %s (%d)", token, buffer);
    }
    compiler_read(NULL);  // Move to the next token
    return type_new(type, NULL, 0, NULL, NULL);
}

// Parse a type specifier for a local/global variable or a function's return type
// This function handles pointers, function pointers, arrays, etc.
int* parse_type_specifier(char* name) {
    int* type;
    name[0] = 0;
    type = parse_base_type_specifier();
    return parse_type_specifier_recursive(name, type);
}

// Recursively parse a type specifier, handling pointers, arrays, and functions.
// WARNING: This is not correct for all types. It works well enough for our purposes,
// but the logic is flawed.
int* parse_type_specifier_recursive(char* name, int* type) {
    int token;
    int* child_type = NULL;
    int array_size;
    int* args = NULL;
    int i = 0;
    char buffer[256];

    token = compiler_peek(buffer);

    if (token == '*') {
        compiler_read(NULL);  // Move past '*'
        type = type_new(TYPE_POINTER, type, 0, NULL);
        type = parse_type_specifier_recursive(name, type);
        return type;
    } else if (token == '(') {
        compiler_read(NULL);  // Move past '('
        type = parse_type_specifier_recursive(name, type);
        compiler_read_expect(')');
    } else if (token == TOKEN_IDENTIFIER) {
        compiler_read(buffer);
        strcpy(name, buffer);
    } else {
        return type;
    }

    while (1) {
        token = compiler_peek(buffer);
        if (token == '(') {
            // Function
            compiler_read(NULL);
            args = malloc(16 * 4);
            while (token != ')') {
                if (i == 16) {
                    compiler_fatal("Too many function args");
                }
                token = compiler_peek(NULL);
                if (token == ')') {
                    compiler_read_expect(')');
                } else if (token == ',') {
                    compiler_read_expect(',');
                } else {
                    child_type = parse_type_specifier(buffer);
                    args[i] = stralloc(buffer);
                    i = i + 1;
                    args[i] = child_type;
                    i = i + 1;
                }
            }

            // This is not correct, but works well enough for our purposes
            type = type_insert_before_terminal(type, type_new(TYPE_FUNCTION, NULL, i / 2, args, NULL));
            token = compiler_peek(NULL);
        } else if (token == '[') {
            // Array
            compiler_read(NULL);
            token = compiler_peek(buffer);
            if (token == TOKEN_CONSTANT) {
                compiler_read(buffer);
                array_size = atou(buffer);
            } else {
                array_size = 0;
            }
            compiler_read_expect(']');

            // This is not correct, but works well enough for our purposes
            type = type_insert_before_terminal(type, type_new(TYPE_ARRAY, NULL, array_size, NULL, NULL));
            token = compiler_peek(NULL);
        } else {
            return type;
        }
    }
}

int* type_insert_before_terminal(int* type, int* new_type) {
    int* base;

    // If we are at the terminal, insert the new type here
    base = type_get_base(type);
    if (base == NULL) {
        new_type[1] = type;
        return new_type;
    }

    // If the base type is terminal, insert the new type between the current type and its base
    if (type_get_base(base) == NULL) {
        type[1] = new_type;
        new_type[1] = base;
        return type;
    }

    type_insert_before_terminal(base, new_type);
    return type;
}

int type_is_type_token(int token) {
    if (token == TOKEN_INT) {
        return 1;
    } else if (token == TOKEN_CHAR) {
        return 1;
    } else if (token == TOKEN_FLOAT) {
        return 1;
    } else if (token == TOKEN_DOUBLE) {
        return 1;
    } else if (token == TOKEN_VOID) {
        return 1;
    } else if (token == TOKEN_STRUCT) {
        return 1;
    } else {
        return 0;
    }
}
