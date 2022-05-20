#include "regs.h"

:_array_test
	dd :_array_test_basic, &"test_basic"
	dd :_array_test_push_pop, &"test_push_pop"
	dd 0, 0

:_array_test_basic
    %local array
    %call :_array_init, 10
    mov @array, @ret
    %call :_array_size, @array
    %call :_test_assert_equal, @ret, 0, &"Expected size = 0"
    %call :_array_set, @array, 0, 123
    %call :_array_size, @array
    %call :_test_assert_equal, @ret, 1, &"Expected size = 1"
    %call :_array_get, @array, 0
    %call :_test_assert_equal, @ret, 123, &"Expected item = 123"
    %ret

:_array_test_push_pop
    %local array
    %call :_array_init, 10
    mov @array, @ret
    %call :_array_push, @array, 123
    %call :_array_push, @array, 456
    %call :_array_push, @array, 789
    %call :_array_size, @array
    %call :_test_assert_equal, @ret, 3, &"Expected size = 3"
    # Test a peek
    %call :_array_peek, @array
    %call :_test_assert_equal, @ret, 789, &"Expected item = 789"
    %call :_array_pop, @array
    %call :_test_assert_equal, @ret, 789, &"Expected item = 789"
    %call :_array_size, @array
    %call :_test_assert_equal, @ret, 2, &"Expected size = 2"
    %call :_array_pop, @array
    %call :_test_assert_equal, @ret, 456, &"Expected item = 456"
    %call :_array_size, @array
    %call :_test_assert_equal, @ret, 1, &"Expected size = 1"
    %call :_array_pop, @array
    %call :_test_assert_equal, @ret, 123, &"Expected item = 123"
    %call :_array_size, @array
    %call :_test_assert_equal, @ret, 0, &"Expected size = 0"
    %ret
