void* __argv;
int __argc;

void fatal(char* message) {
    syscall_write(2, message, strlen(message));
    syscall_write(2, "\n", 1);
    syscall_exit(1);
}

void init_args() {
    int length;
    void* buffer;
    void* current;

    length = syscall_getargv(0, 0);
    buffer = malloc(length);
    syscall_getargv(buffer, length);

    __argv = buffer;
    current = buffer;

    while (*current != 0) {
        __argc = __argc + 1;
        current = current + 4;
    }
}

void _reset_crt() {
    int program_end;
    __asm__("mov @program_end, :__END__");
    init_heap(program_end);
    init_args();
}

void _start1() {
    int ret;
    _reset_crt();
    ret = main(__argc, __argv);
    syscall_exit(ret);
}
