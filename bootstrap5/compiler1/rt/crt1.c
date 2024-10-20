void fatal(char* message) {
    syscall_write(2, message, strlen(message));
    syscall_write(2, "\n", 1);
    syscall_exit(1);
}

int main() {
    int array[10];
}

void _start1() {
    int program_end;
    __asm__("mov @program_end, :__END__");
    init_heap(program_end);
    main();
    syscall_exit(0);
}
