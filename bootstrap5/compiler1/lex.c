#define SLOT_COUNT 16
#define BUFFER_SIZE 128

void* lex_lexer;
void** lex_token_buffers;
int lex_token_slot;
int* lex_tokens;

// Initialize the lexer
//
// We build an array that allows us to create the token stack, giving us a place to stash tokens while
// we continue parsing source. This is useful for things like function calls and local assignment, as
// we may need to compute an expression's value before we store it to the local.
void lex_init(const char* file) {
    void* ll = _ll_init();
    void* ll_node = _ll_create_node_int("bootstrap4");
    int i;
    _ll_insert_head(ll, ll_node);
    lex_lexer = __lex_open(__lex_create(ll), file);

    // Create the token slots
    for (i = 0; i < SLOT_COUNT; i = i + 1) {
        _arraywrite32(lex_token_buffers, i, _malloc(BUFFER_SIZE));
    }
    lex_tokens = _malloc(SLOT_COUNT * 4);
}

void lex_init_string(const char* s) {
    int i;
    lex_lexer = __lex_open_string(__lex_create(0), s);
    // Create the token slots
    for (i = 0; i < SLOT_COUNT; i = i + 1) {
        _arraywrite32(lex_token_buffers, i, _malloc(BUFFER_SIZE));
    }
    lex_tokens = _malloc(SLOT_COUNT * 4);
}

// Read a token
//
// This reads a token into the current token stack slot and returns the token type. lex_token_buffer can
// be used to retrieve this buffer's text, and lex_token_equals can be used to compare the value of this
// buffer with a given string constant.
int lex_read() {
    int token = _lex(lex_lexer, _arrayread32(lex_token_buffers, lex_token_slot), BUFFER_SIZE);
    _arraywrite32(lex_tokens, lex_token_slot, token);
    return token;
}

// Peek a token
//
// This peeks at the next token, but does not retrieve it. The token text for the peeked token is not
// available - only the token type.
int lex_peek() {
    return _lex_peek(lex_lexer, 0, 0);
}

// Get the token buffer
const char* lex_token_buffer() {
    return _arrayread32(lex_token_buffers, lex_token_slot);
}

// Returns the last lexed token
int lex_token() {
    return lex_tokens[lex_token_slot];
}

// Compares the lex token to the given string
int lex_token_equals(const char* token) {
    return _streq(lex_token_buffer(), token);
}

// Pushes the lex token context, storing the old token for later use
void lex_push() {
    lex_token_slot = lex_token_slot + 1;
}

// Pops the lex token context
void lex_pop() {
    lex_token_slot = lex_token_slot - 1;
}
