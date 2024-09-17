int global_array_int[] = { 10, 20, 30 };
char* global_string = "abcd";

int result_deref() {
    int* ptr = &global_array_int;
    char* ptr_byte = global_string;

    _test_assert_equal(ptr[0], 10, "ptr[0]");
    _test_assert_equal(*ptr, 10, "*ptr");
    *ptr = 20;
    _test_assert_equal(ptr[0], 20, "ptr[0]");
    _test_assert_equal(*ptr, 20, "*ptr");
    ptr[1] = 30;
    _test_assert_equal(ptr[1], 30, "ptr[1]");

    _test_assert_equal(ptr_byte[0], 'a', "ptr_byte[0]");
    _test_assert_equal(ptr_byte[1], 'b', "ptr_byte[1]");
    _test_assert_equal(*ptr_byte, 'a', "*ptr");
    *ptr_byte = 'z';
    _test_assert_equal(ptr_byte[0], 'z', "ptr_byte[0]");
    _test_assert_equal(ptr_byte[1], 'b', "ptr_byte[1]");
    _test_assert_equal(*ptr_byte, 'z', "*ptr");

    return (*ptr + *ptr_byte) - 100; // z = 122
}
