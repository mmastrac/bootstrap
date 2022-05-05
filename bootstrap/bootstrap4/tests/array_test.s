#include "regs.h"

:_array_test
	dd &"array_test"
	dd :_array_test_basic, &"test_basic"
	dd 0, 0

:_array_test_basic
    %local array
    %call :_array_init, 10
    mov @array, @ret
    %call :_array_size, @array
    %call :_test_assert_equal, @ret, 0, &"Expected size = 0"
    %call :_array_set, @array, 0, 123
    %call :_array_size, @array
    %call :_test_assert_equal, @ret, 0, &"Expected size = 1"
    %call :_array_get, @array, 0
    %call :_test_assert_equal, @ret, 123, &"Expected item = 123"
    %ret
