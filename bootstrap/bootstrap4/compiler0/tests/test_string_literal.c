int result_string_literal() {
    // Currently not doing the C ABI naming right here
    return (_strlen("hello world") * 4) - 2;
}
