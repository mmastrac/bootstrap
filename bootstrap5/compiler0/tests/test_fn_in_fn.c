// n is ignored
int function_a(int n) {
    return 10;
}

int function_c(int a, int b) {
    return a + b;
}

int result_fn_in_fn() {
    // Call a function with the results of another function, ensuring that the first argument is not corrupted
    return function_c(32, function_a(13));
}
