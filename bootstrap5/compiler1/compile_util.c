#define TOKEN_SIZE 256
#define NULL 0
int* lex_file;
char* lex_buffer;
int out_file;

extern int* global_scope;

void compiler_init(char* in, char* out) {
    void* ll;
    void* node;
    void* lex;
    int token;

    global_scope = scope_create();

    lex_buffer = malloc(TOKEN_SIZE);

    // Create the include list
    ll = ll_init();
    node = ll_create_node_int("bootstrap5");
    ll_insert_head(ll, node);

    // Create the lex environment
    lex = _lex_create(ll);
    lex_file = _lex_open(lex, in);

    out_file = open(out, 2);
}

void compiler_fatal(char* message, int arg0, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6) {
    printf("Fatal error: ");
    printf(message, arg0, arg1, arg2, arg3, arg4, arg5, arg6);
    printf("\n");
    syscall_exit(1);
}

int compiler_out(char* s, int arg0, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6) {
    set_fprintf_fd(out_file);
    return call_fprintf(s, arg0, arg1, arg2, arg3, arg4, arg5, arg6);
}

int compiler_read_expect(int token) {
    int next_token;

    next_token = lex(lex_file, lex_buffer, TOKEN_SIZE);
    if (next_token != token) {
        compiler_fatal("Unexpected token: %d %s", next_token, lex_buffer);
    }
    return next_token;
}

int compiler_peek(char* buffer) {
    int retval;
    retval = lex_peek(lex_file, lex_buffer, TOKEN_SIZE);
    if (buffer != NULL) {
        strcpy(buffer, lex_buffer);
    }
    return retval;
}

int compiler_read(char* buffer) {
    int retval;
    retval = lex(lex_file, lex_buffer, TOKEN_SIZE);
    if (buffer != NULL) {
        strcpy(buffer, lex_buffer);
    }
    return retval;
}
