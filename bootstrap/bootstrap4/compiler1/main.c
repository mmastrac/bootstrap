void* create_lex() {
    void* ll = _ll_init();
    void* ll_node = _ll_create_node_int("bootstrap/bootstrap4/compiler0/tests/lex_io_test");
    void* lex;
    _ll_insert_head(ll, ll_node);
    lex = __lex_create(ll);
    return lex;
}

void* create_argument_array(int argc, char** argv) {
    void* array = _array_init(argc);
    _memcpy(_array_get_buffer(array), argv, argc * 4);
    _array_size_set(array, argc);
    return array;
}

int _main(int argc, char** argv) {
    void* lex = create_lex();
    void* args = create_argument_array(argc, argv);
    int i;
    for (i = 0; i < argc; i = i + 1) {
        _quicklog("%s\n", _array_get(args, i));
    }
}
