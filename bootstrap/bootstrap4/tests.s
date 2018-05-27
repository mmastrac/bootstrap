#include "regs.h"

:_main
	%call :_test_main, :_strings_test
	%call :_test_main, :_linked_list_test
	%ret
