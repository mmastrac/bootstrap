int x1;

// Declare struct x2 and variable x2
struct x2 { int x; int y; } x2;

int* x3;
int x4[3];
int bar();
int baz(int x, int y);

// declare foo as pointer to function (void) returning pointer to array 3 of int
int (*(*foo)(void ))[3];

int result_varied_types(int a, int b) {
    int ptr_size = sizeof(int*);

    test_assert_equal(4, sizeof(a), "sizeof(a)");
    test_assert_equal(4, sizeof(b), "sizeof(b)");
    test_assert_equal(4, sizeof(x1), "sizeof(x1)");
    test_assert_equal(8, sizeof(x2), "sizeof(x2)");
    test_assert_equal(ptr_size, sizeof(x3), "sizeof(x3)");
    test_assert_equal(12, sizeof(x4), "sizeof(x4)");

    // Forward declarations are 1 byte
    test_assert_equal(1, sizeof(bar), "sizeof(bar)");
    test_assert_equal(1, sizeof(baz), "sizeof(baz)");
    test_assert_equal(ptr_size, sizeof(foo), "sizeof(foo)");
    
    return 42;
}
