int global_value = 21;
int global_value_2;

int result_global() {
    global_value_2 = global_value;
    return global_value + global_value_2;
}
