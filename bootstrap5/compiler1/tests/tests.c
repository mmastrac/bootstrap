#include <stdio.h>

extern int result_basic();
extern int result_binary();
extern int result_char_literal();
extern int result_compare();
extern int result_deref();
extern int result_fib();
extern int result_fn_args();
extern int result_fn_in_fn();
extern int result_if_else();
extern int result_for();
extern int result_function();
extern int result_global();
extern int result_include();
extern int result_inited();
extern int result_local();
extern int result_string_literal();
extern int result_unary();

extern int result_varied_types();

struct test_case {
    int (*test)();
    const char* name;
};

struct test_case tests[] = {
    // compiler0 tests
    { result_basic, "basic" },
    { result_binary, "binary" },
    { result_char_literal, "char_literal" },
    { result_compare, "compare" },
    { result_deref, "deref" },
    { result_fib, "fib" },
    { result_fn_args, "fn_args" },
    { result_fn_in_fn, "fn_in_fn" },
    { result_if_else, "if_else" },
    { result_for, "for" },
    { result_function, "function" },
    { result_global, "global" },
    { result_include, "include" },
    { result_inited, "inited" },
    { result_local, "local" },
    { result_string_literal, "string_literal" },
    { result_unary, "unary" },
    // compiler1 tests
    { result_varied_types, "varied_types" },
    { NULL, NULL }
};

void test_assert_equal(int expected, int actual, const char* message) {
    if (expected != actual) {
        printf("Test failed: expected %d, got %d (%s)\n", expected, actual, message);
    }
}

int main() {
    int failed = 0;
    struct test_case* test;

    for (test = tests; test->test; test++) {
        int result = test->test();
        if (result != 42) {
            printf("Test '%s' failed: expected 42, got %d\n", test->name, result);
            failed++;
        } else {
            printf("Test '%s' passed\n", test->name);
        }
    }
    printf("%d tests failed\n", failed);
    return failed;
}

