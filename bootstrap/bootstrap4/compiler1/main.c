void* create_argument_array(int argc, char** argv) {
    void* array = _array_init(argc);
    _memcpy(_array_get_buffer(array), argv, argc * 4);
    _array_size_set(array, argc);
    return array;
}

int _main(int argc, char** argv) {
    void* args = create_argument_array(argc, argv);
    lex_init(_array_get(args, 1));
    int token;
    while (1) {
        token = lex_read();
        _quicklog("%d\n", token);
        _quicklog("%s\n", lex_token_buffer());
        if (token == 4294967295) {
            //break;
        }
    }
}
