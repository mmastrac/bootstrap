int result_string_literal() {
    const char* s = "\"hello\" world\n";
    _test_assert_equal(s[0], '"', "s[0]");
    _test_assert_equal(s[1], 'h', "s[1]");
    // Currently not doing the C ABI naming right here
    return ((_strlen(s) + _strlen("\"hello\" world\n")) * 2) - 14;
}
