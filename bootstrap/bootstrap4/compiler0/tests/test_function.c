int add_function(int a, int b, int c) {
    return (a + b) + c;
}

int result_function() {
    // 42
    return add_function(1, 2, 37 + 1) + 1;
}
