int is_type_token(int token) {
    while (1) {
        if (token == TOKEN_INT) return 1;
        if (token == TOKEN_CHAR) return 1;
        if (token == TOKEN_SHORT) return 1;
        if (token == TOKEN_CONST) return 1;
        if (token == TOKEN_UNSIGNED) return 1;
        if (token == TOKEN_VOID) return 1;
        if (token == '*') return 1;
        return 0;
    }
}

void compile_function_type(int* file, char* buf, int buflen) {
    int token;

    token = lex(file, buf, buflen);
    if (!is_type_token(token)) {
        fatal("Unexpected type token encountered\n");
    }

    while (1) {
        token = lex_peek(file, buf, buflen);
        if (!is_type_token(token)) {
            return;
        }
        lex(file, buf, buflen);
    }
}

void compile_function_args(int* file, char* buf, int buflen) {
    compiler_read_expect(file, buf, buflen, '(');
    compiler_out("# arguments\n");

    while (1) {
        int token = lex_peek(file, buf, buflen);
        if (token == ')') {
            break;
        }
        if (token == ',') {
            lex(file, buf, buflen);
            continue;
        }

        compile_function_type(file, buf, buflen);
        compiler_read_expect(file, buf, buflen, TOKEN_IDENTIFIER);
        if (is_global(buf)) {
            fatal("Parameter cannot shadow a global");
        }
        compiler_out("    %arg %s\n", buf);
    }

    lex(file, buf, buflen);
}
