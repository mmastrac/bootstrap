char __fputchar_buffer[] = { 0 };
void* __print_function = 0;
int __print_function_data = 0;
char* __digit_buffer = "....................";

int fputchar(char c) {
    __fputchar_buffer[0] = c;
    syscall_write(__print_function_data, __fputchar_buffer, 1);
}

void __printf_putchar(char c) {
    int f = __print_function;
    if (f == fputchar) {
        fputchar(c);
    }
}

void __printf_putstring(char* s) {
    int f = __print_function;
    if (f == fputchar) {
        while (*s != 0) {
            fputchar(*s);
            s = s + 1;
        }
    }
}

int __printf(char* s, int arg0, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6) {
    int arg = 0;
    int arg_value;
    int c;
    char* digit_ptr;

    while (*s != 0) {
        if (*s == '%') {
            s = s + 1;
            c = *s;
            if (c == '%') {
                __printf_putchar(c);
            } else {
                if (arg == 0) {
                    arg_value = arg0;
                } else if (arg == 1) {
                    arg_value = arg1;
                } else if (arg == 2) {
                    arg_value = arg2;
                } else if (arg == 3) {
                    arg_value = arg3;
                } else {
                    arg_value = 0;
                }
                arg = arg + 1;
                if (c == 'c') {
                    __printf_putchar(arg_value);
                } else if (c == 's') {
                    __printf_putstring(arg_value);
                } else if ((c == 'd') || (c == 'x') || (c == 'p')) {
                    if (arg_value == 0) {
                        __printf_putchar('0');
                    } else {
                        digit_ptr = &__digit_buffer + 20;
                        while (arg_value > 0) {
                            digit_ptr = digit_ptr - 1;
                            *digit_ptr = '0' + (arg_value % 10);
                            arg_value = arg_value / 10;
                        }
                        __printf_putstring(digit_ptr);
                    }
                } else {
                    __printf_putchar('%');
                    __printf_putchar(*s);
                }
            }
        } else {
            __printf_putchar(*s);
        }
        s = s + 1;
    }
}

int printf(char* s, int arg0, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6) {
    __print_function = fputchar;
    __print_function_data = 1;
    return __printf(s, arg0, arg1, arg2, arg3, arg4, arg5, arg6);
}

void set_fprintf_fd(int fd) {
    __print_function_data = fd;
}

int call_fprintf(char* s, int arg0, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6) {
    __print_function = fputchar;
    return __printf(s, arg0, arg1, arg2, arg3, arg4, arg5, arg6);
}
