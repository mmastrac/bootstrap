#include "regs.h"

:_compile_test
	dd &"compile"
	dd :_compile_test_basic, &"compile_test_basic"
	dd :_compile_test_fib, &"compile_test_fib"
	dd 0, 0

:_compile_test_basic
    %ret

:_compile_test_fib
    %ret

:_main
	%call :_test_main, :_compile_test
