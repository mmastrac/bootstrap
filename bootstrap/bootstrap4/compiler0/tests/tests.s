#include "regs.h"

:_compile_test
	dd &"compile"
	dd :_compile_test_basic, &"compile_test_basic"
	dd :_compile_test_binary, &"compile_test_binary"
	dd :_compile_test_fib, &"compile_test_fib"
	dd :_compile_test_function, &"compile_test_function"
	dd :_compile_test_local, &"compile_test_local"
	dd 0, 0

:_compile_test_basic
    %call :result_basic
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_binary
    %call :result_binary
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_fib
    %call :result_fib
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_function
    %call :result_function
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_local
    %call :result_local
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_main
	%call :_test_main, :_compile_test
    %ret
