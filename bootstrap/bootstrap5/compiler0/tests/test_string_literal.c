int result_string_literal() {
    const char* s = "\"hello\" world\n";
    test_assert_equal(s[0], '"', "s[0]");
    test_assert_equal(s[1], 'h', "s[1]");
    return ((strlen(s) + strlen("\"hello\" world\n")) * 2) - 14;
}
