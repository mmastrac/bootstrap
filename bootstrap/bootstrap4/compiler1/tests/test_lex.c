#include "lex/lex.h"

void** lex_tests = {
    test_lex_simple, "test_lex_simple",
    test_lex_stack, "test_lex_stack",
    0, 0
};

void test_lex_simple() {
    lex_init_string("a b c");
    _test_assert_equal(TOKEN_IDENTIFIER, lex_read(), "Expected identifier");
    _test_assert_equal(TOKEN_IDENTIFIER, lex_read(), "Expected identifier");
    _test_assert_equal(TOKEN_IDENTIFIER, lex_read(), "Expected identifier");
    _test_assert_equal(TOKEN_EOF, lex_read(), "Expected EOF");
}

void test_lex_stack() {
    lex_init_string("a b c");
    _test_assert_equal(TOKEN_IDENTIFIER, lex_read(), "Expected identifier");
    _test_assert_equal(TOKEN_IDENTIFIER, lex_token(), "Expected identifier");
    _test_assert_string_equal("a", lex_token_buffer(), "Incorrect token string");
    lex_push();
    _test_assert_equal(TOKEN_IDENTIFIER, lex_read(), "Expected identifier");
    _test_assert_equal(TOKEN_IDENTIFIER, lex_token(), "Expected identifier");
    _test_assert_string_equal("b", lex_token_buffer(), "Incorrect token string");
    lex_push();
    _test_assert_equal(TOKEN_IDENTIFIER, lex_read(), "Expected identifier");
    _test_assert_equal(TOKEN_IDENTIFIER, lex_token(), "Expected identifier");
    _test_assert_string_equal("c", lex_token_buffer(), "Incorrect token string");
    lex_push();
    _test_assert_equal(TOKEN_EOF, lex_read(), "Expected EOF");
    lex_pop();
    _test_assert_equal(TOKEN_IDENTIFIER, lex_token(), "Expected identifier");
    _test_assert_string_equal("c", lex_token_buffer(), "Incorrect token string");
    lex_pop();
    _test_assert_equal(TOKEN_IDENTIFIER, lex_token(), "Expected identifier");
    _test_assert_string_equal("b", lex_token_buffer(), "Incorrect token string");
    lex_pop();
    _test_assert_equal(TOKEN_IDENTIFIER, lex_token(), "Expected identifier");
    _test_assert_string_equal("a", lex_token_buffer(), "Incorrect token string");
}
