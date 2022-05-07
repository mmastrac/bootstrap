#include "regs.h"

:_compile_test
	dd &"compile"
	dd :_compile_test_basic, &"compile_test_basic"
	dd :_compile_test_binary, &"compile_test_binary"
    dd :_compile_test_char_literal, &"compile_test_char_literal"
	dd :_compile_test_compare, &"compile_test_compare"
	dd :_compile_test_fib, &"compile_test_fib"
	dd :_compile_test_for, &"compile_test_for"
	dd :_compile_test_function, &"compile_test_function"
	dd :_compile_test_local, &"compile_test_local"
    dd :_compile_test_string_literal, &"compile_test_string_literal"
	dd 0, 0

:_compile_test_basic
    %call :result_basic
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_binary
    %call :result_binary
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_char_literal
    %call :result_char_literal
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_compare
    %call :result_compare
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_fib
    %call :result_fib
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_for
    %call :result_for
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

:_compile_test_string_literal
    %call :result_string_literal
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_test_out
    %arg msg
    %arg out0
    %arg out1
    %arg out2
    %arg out3
    %local fd

    push @out3
    push @out2
    push @out1
    push @out0
	%call :_dprintf, 1, @msg
    pop @out0
    pop @out1
    pop @out2
    pop @out3
    %ret

:_main
	%call :_test_main, :_compile_test
    %ret
