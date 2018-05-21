:_strings_test
	dd &"strings"
	dd :_strings_test_isdigit, &"test_isdigit"
	dd 0, 0

:_strings_test_isdigit
	%call :_isdigit, 'a'
	%call :_test_assert_zero, &"Expected false"
	%call :_isdigit, 'A'
	%call :_test_assert_zero, &"Expected false"
	%call :_isdigit, '1'
	%call :_test_assert_zero, &"Expected true"
	%ret
