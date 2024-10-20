int result_if_else() {
    int result = 0;
    int i;
    for (i = 0; i < 10; i = i + 1) {
        if (i == 0) {
            result = result + 1;
        } else if (i == 1) {
            result = result + 2;
        } else if (i == 2) {
            result = result + 3;
        } else if (i == 3) {
            result = result + 4;
        } else {
            result = result + 5;
        }
    }
    return result + (42 - (1 + (2 + (3 + (4 + (5 + (5 + (5 + (5 + (5 + 5))))))))));
}
