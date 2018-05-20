:_tests
	dd :_test_isdigit, &"test_isdigit"
	dd 0, 0

:_test_isdigit
	%call :_isdigit, 'a'
	%call :_test_assert_zero, &"Expected false"
	%call :_isdigit, 'A'
	%call :_test_assert_zero, &"Expected false"
	%call :_isdigit, '1'
	%call :_test_assert_zero, &"Expected true"
	%ret

:_main
	%call :_test_main, :tests
