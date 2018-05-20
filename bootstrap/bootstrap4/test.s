#include "regs.h"

:__assertion
	dd 0

#===========================================================================
# Args:
#   R0: Must be non-zero
#   R1: printf args
#===========================================================================
:_test_assert_nonzero
	eq r0, 0
	%ret^
	ld.d @tmp0, :__assertion
	add @tmp0, 1
	st.d :__assertion, @tmp0
	mov r0, 2
	call :dprintf
	%ret
#===========================================================================


#===========================================================================
# Args:
#   R0: List of test functions, followed by a trailing NUL
#===========================================================================
:_test_main
	%arg tests
	%local passed
	%local total
	%local test
	mov @passed, 0
	mov @total, 0
.loop
	ld.d @test, @tests
	eq @test, 0
	jump? .done
	add @total, 1
	add @tests, 4
	%call @test
	ld.d @tmp0, :__assertion
	eq @tmp0, 0
	jump? .loop
	add @total, 1

.done
	push @total
	push @passed
	%call :dprintf, &"Passed %d of %d test(s)\n"
	pop @total
	pop @passed
	%ret
#===========================================================================
