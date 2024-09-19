#include "regs.h"

:_compile_test
	dd :_compile_test_basic, &"compile_test_basic"
	dd :_compile_test_binary, &"compile_test_binary"
    dd :_compile_test_char_literal, &"compile_test_char_literal"
	dd :_compile_test_compare, &"compile_test_compare"
    dd :_compile_test_deref, &"compile_test_deref"
	dd :_compile_test_fib, &"compile_test_fib"
	dd :_compile_test_fn_args, &"compile_test_fn_args"
	dd :_compile_test_fn_in_fn, &"compile_test_fn_in_fn"
    dd :_compile_test_if_else, &"compile_test_if_else",
	dd :_compile_test_for, &"compile_test_for"
	dd :_compile_test_function, &"compile_test_function"
	dd :_compile_test_global, &"compile_test_global"
	dd :_compile_test_include, &"compile_test_include"
	dd :_compile_test_inited, &"compile_test_inited"
	dd :_compile_test_local, &"compile_test_local"
    dd :_compile_test_string_literal, &"compile_test_string_literal"
	dd :_compile_test_unary, &"compile_test_unary"
	dd 0, 0

:_compile_test_basic
    %call :_result_basic
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_binary
    %call :_result_binary
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_char_literal
    %call :_result_char_literal
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_compare
    %call :_result_compare
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_deref
    %call :_result_deref
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_fib
    %call :_result_fib
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_fn_args
    %call :_result_fn_args
    %call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_fn_in_fn
    %call :_result_fn_in_fn
    %call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_for
    %call :_result_for
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_function
    %call :_result_function
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_global
    %call :_result_global
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_if_else
    %call :_result_if_else
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_include
    %call :_result_include
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_inited
    %call :_result_inited
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_local
    %call :_result_local
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_string_literal
    %call :_result_string_literal
	%call :_test_assert_equal, @ret, 42, &"Expected 42"
    %ret

:_compile_test_unary
    %call :_result_unary
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
	%call :_test_main, :_compile_test, &"compile_test"
    %ret
