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
	ld.d @tmp0, [:__assertion]
	add @tmp0, 1
	st.d [:__assertion], @tmp0
	push r1
	push r0
	mov r0, 2
	mov r1, &"Assertion failed: %s (%d == 0)\n"
	call :_dprintf
	pop r1
	pop r0
	%ret
#===========================================================================


#===========================================================================
# Args:
#   R0: Must be non-zero
#   R1: printf args
#===========================================================================
:_test_assert_zero
	eq r0, 0
	%ret?
	ld.d @tmp0, [:__assertion]
	add @tmp0, 1
	st.d [:__assertion], @tmp0
	push r1
	push r0
	mov r0, 2
	mov r1, &"Assertion failed: %s (%d != 0)\n"
	call :_dprintf
	pop r1
	pop r0
	%ret
#===========================================================================


#===========================================================================
# Args:
#   R0: Arg 1
#   R1: Arg 2
#   R2: printf args
#===========================================================================
:_test_assert_equal
	eq r0, r1
	%ret?
	ld.d @tmp0, [:__assertion]
	add @tmp0, 1
	st.d [:__assertion], @tmp0
	push r0
	push r1
	push r2
	%call :_dprintf, 2, &"Assertion failed: %s (%d != %d)\n"
	pop r2
	pop r1
	pop r0
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
	ld.d @tmp0, [@tests]
	push @tmp0
	%call :_dprintf, 2, &"Suite: %s\n"
	pop @tmp0
	add @tests, 4
.loop
	mov @tmp0, 0
	st.d [:__assertion], @tmp0
	ld.d @test, [@tests]
	eq @test, 0
	jump? .done
	add @total, 1
	add @tests, 4
	ld.d @tmp0, [@tests]
	add @tests, 4
	push @tmp0
	%call :_dprintf, 2, &"  - %s\n"
	pop @tmp0
	%call @test
	ld.d @tmp0, [:__assertion]
	eq @tmp0, 0
	add? @passed, 1
	jump .loop

.done
	push @total
	push @passed
	%call :_dprintf, 2, &"Passed %d of %d test(s)\n"
	pop @passed
	pop @total
	mov @ret, 0
	%ret
#===========================================================================
