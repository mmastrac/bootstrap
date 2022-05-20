#include "regs.h"

:_strings_test
	dd :_strings_test_isdigit, &"test_isdigit"
	dd :_strings_test_strchr, &"test_strchr"
	dd :_strings_test_strcmp, &"test_strcmp"
	dd :_strings_test_streq, &"test_streq"
	dd :_strings_test_stralloc, &"test_stralloc"
	dd 0, 0

:_strings_test_isdigit
	%call :_isdigit, 'a'
	%call :_test_assert_zero, r0, &"Expected false"
	%call :_isdigit, 'A'
	%call :_test_assert_zero, r0, &"Expected false"
	%call :_isdigit, '1'
	%call :_test_assert_nonzero, r0, &"Expected true"
	%ret

:_strings_test_strchr
	%call :_strchr, .haystack, 'a'
	sub @ret, .haystack
	%call :_test_assert_zero, r0, &"Expected return to be first position"
	%call :_strchr, .haystack, 0
	sub @ret, .haystack
	sub @ret, 6
	%call :_test_assert_zero, r0, &"Expected return to be trailing NULL char"
	%call :_strchr, .haystack, 'x'
	%call :_test_assert_zero, r0, &"Expected NULL"
	%ret

.haystack
	ds "abcdef"

:_strings_test_strcmp
	%call :_strcmp, &"ABC", &"ABC"
	%call :_test_assert_zero, r0, &"Expected equal"
	%call :_strcmp, &"ABC", &"ABCD"
	%call :_test_assert_equal, r0, -1, &"Expected -1"
	%call :_strcmp, &"ABCD", &"ABC"
	%call :_test_assert_equal, r0, 1, &"Expected +1"
	%call :_strcmp, &"ABC", &"DEF"
	%call :_test_assert_equal, r0, -1, &"Expected -1"
	%ret

:_strings_test_streq
	%call :_streq, &"ABC", &"ABC"
	%call :_test_assert_equal, r0, 1, &"Expected equal"
	%call :_streq, &"ABC", &"ABCD"
	%call :_test_assert_zero, r0, &"Expected not equal"
	%call :_streq, &"ABCD", &"ABC"
	%call :_test_assert_zero, r0, &"Expected not equal"
	%call :_streq, &"ABC", &"DEF"
	%call :_test_assert_zero, r0, &"Expected not equal"
	%ret

:_strings_test_stralloc
	%local a
	%local b

	%call :_stralloc, &"ABCDE"
	mov @a, @ret
	%call :_stralloc, &"FGHIJK"
	mov @b, @ret

	%call :_streq, @a, &"ABCDE"
	%call :_test_assert_nonzero, r0, &"Expected equal"
	%call :_streq, @b, &"FGHIJK"
	%call :_test_assert_nonzero, r0, &"Expected equal"

	# Expected that these strings are one after another in memory
	# This test might fail if malloc gets smarter!
	mov @tmp0, @a
	add @tmp0, 6
	%call :_test_assert_equal, @tmp0, @b, &"Expected equal"

	%ret
