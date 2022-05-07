int result_for() {
    int i;
    int j;
    j = 0;

    for (i = 0; i < 10; i = i + 1) {
        j = j + i;
    }

    // sum(0..9) - 3 = 42
    return j - 3;
}
