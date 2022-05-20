struct a {
    int a;
    int b;
};

int test() {
    struct a a;
    a.a = 1;
    a.b = 2;
    test_assert_equals(a.a + a.b, 3, "Incorrect sum of struct fields");
}
