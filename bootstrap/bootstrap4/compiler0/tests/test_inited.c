int global_int[] = { 10, 20, 30 };
char* global_str[] = { "abc", "1234", "abcde", 0 };
char global_char[] = { 'a', 'b', 'c' };

int result_inited() {
    int result = 0;
    test_assert_equal(global_int[0], 10, "global_int[0]");
    test_assert_equal(global_int[1], 20, "global_int[1]");
    test_assert_equal(global_int[2], 30, "global_int[2]");
    test_assert_equal(strlen(global_str[0]), 3, "strlen(global_str[0])");
    test_assert_equal(strlen(global_str[1]), 4, "strlen(global_str[1])");
    test_assert_equal(strlen(global_str[2]), 5, "strlen(global_str[2])");
    test_assert_equal(global_char[0], 'a', "global_char[0]");
    test_assert_equal(global_char[1], 'b', "global_char[1]");
    test_assert_equal(global_char[2], 'c', "global_char[2]");

    result = global_int[0] + (global_int[1] + (global_int[2] - 18));
    return result;
}
