// Initialize the lexer
//
// We build an array that allows us to create the token stack, giving us a place to stash tokens while
// we continue parsing source. This is useful for things like function calls and local assignment, as
// we may need to compute an expression's value before we store it to the local.
void lex_init() {
}

// Read a token
//
// This reads a token into the current token stack slot and returns the token type. lex_token_buffer can
// be used to retrieve this buffer's text, and lex_token_equals can be used to compare the value of this
// buffer with a given string constant.
int lex_read() {
}

// Peek a token
//
// This peeks at the next token, but does not retrieve it. The token text for the peeked token is not
// available - only the token type.
int lex_peek() {
}

// Get the token buffer
const char* lex_token_buffer() {
}

// Returns the last lexed token
int lex_token() {
}

// Compares the lex token to the given string
int lex_token_equals(const char* token) {
}

// Pushes the lex token context, storing the old token for later use
void lex_push() {
}

// Pops the lex token context
void lex_pop() {
}
