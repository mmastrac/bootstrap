int one_arg(int arg) {
    int local;

    local = arg;
}

int lots_of_args2(int arg0, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6, int arg7) {
    int local1 = 10;
    int local2 = 20;

    one_arg(100);

    return arg0 + (arg1 + (arg2 + (arg3 + (arg4 + (arg5 + (arg6 + (arg7 + (local1 + local2)))))))); 
}

int lots_of_args(int arg0, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6, int arg7) {
    int local1;
    int local2;

    local1 = lots_of_args2(arg1, arg2, arg3, arg4, arg5, arg6, arg7, 0);
    local2 = arg0;
    return local1 + local2;
}

int result_fn_args() {
    return lots_of_args2(1, 2, 3, 4, 5, 6, 7, 8) - 24;
}
