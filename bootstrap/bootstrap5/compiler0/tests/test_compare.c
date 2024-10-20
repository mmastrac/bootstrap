// Mainly to test whether compare ops are correct in direction
int result_compare() {
    int sum = 0;

    if (1 < 2) {
        sum = sum + 1;
    }
    if (2 > 1) {
        sum = sum + 2;
    }
    if (2 == 2) {
        sum = sum + 4;
    }
    if (2 != 3) {
        sum = sum + 8;
    }
    if (2 <= 3) {
        sum = sum + 16;
    }
    if (3 >= 2) {
        sum = sum + 32;
    }
    // Hopefully 42
    return sum - 21;
}
