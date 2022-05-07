void* create_lex() {
    void* ll = _ll_init();
    void* ll_node = _ll_create_node_int("bootstrap/bootstrap4/compiler0/tests/lex_io_test");
    void* lex;
    _ll_insert_head(ll, ll_node);
    lex = __lex_create(ll);
    return lex;
}

int _main(int argc, char** argv) {
    void* lex = create_lex();
    void* array = _array_init(argc);
    _memcpy(_array_get_buffer(array), argv, argc * 4);
    _array_size_set(array, argc);
    void* item = _array_get(array, 0);
    _quicklog("Hello, world! %d %s\n", argc, item);
}
