void fatal(char* message) {
    _syscall_write(2, message, _strlen(message));
    _syscall_write(2, "\n", 1);
    _syscall_exit(1);
}

void _start1() {
    init_heap();
    _syscall_exit(0);
}
