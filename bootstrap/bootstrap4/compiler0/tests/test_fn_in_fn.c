int function_a(int a, int b) {
    return a + b;
}

int function_b(int a, int b) {
    return a * b;
}

int function_c(const char* a, int b, int c) {
    return (_strlen(a) * 3) + (3 * b) + c;
}

int result_fn_in_fn() {
    // Call a function with the results of another function, ensuring that the string argument is not corrupted
    return function_c("1234567", function_a(1, 2), function_b(3, 4));
}
