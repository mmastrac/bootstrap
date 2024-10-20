int result_local() {
    int sum = 10 * 2;
    char* string = "hello world";
    sum = sum + (strlen(string) * 2);
    return sum;
}
