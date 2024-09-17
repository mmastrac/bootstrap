int result_string_literal() {
    const char* s = "hello world";
    _test_assert_equal(s[0], 'h', "s[0]");
    _test_assert_equal(s[1], 'e', "s[1]");
    // Currently not doing the C ABI naming right here
    return ((_strlen(s) + _strlen("hello world")) * 2) - 2;
}
