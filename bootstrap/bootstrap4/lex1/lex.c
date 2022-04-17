// Stage 2 lexer, uses the basic C from the previous stage and adds more functionality on top

int lex_main() {
    int valid;
    while (valid) {
        valid = top();
    }
}

// Parse globals: functions/variables
int top() {
    int token;

    token = lex(file, buffer, BUFFER_SIZE);
    if (token == TOKEN_INT) {
        token = lex(file, buffer, BUFFER_SIZE);
        if (token == TOKEN_IDENTIFIER) {
            global_var();
        }
        if (token == '(') {
            function();            
        }
    }

    fail("Expected a global variable or function");
}

int global_var() {
    register_global();
}

int function_args() {

}

int function() {
    int args;
    int token;
    lex_print(":%s", name);
    args = 1;
    while (args) {
        token = lex(file, buffer, BUFFER_SIZE);
        if (token == ')') {
            break;
        }
        if (token == ',') {
            continue;
        }
        if (token == TOKEN_INT) {
            token = lex(file, buffer, BUFFER_SIZE);
            lex_print("    %%local %s", buffer);
        }
    }
}
