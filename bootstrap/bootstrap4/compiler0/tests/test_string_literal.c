int result_string_literal() {
    const char* s;
    s = "hello world";
    // Currently not doing the C ABI naming right here
    return ((_strlen(s) + _strlen("hello world")) * 2) - 2;
}
