#include "regs.h"

:_main
	%call :_test_main, :_lex_io_test
	%call :_test_main, :_lex_test
	%ret
