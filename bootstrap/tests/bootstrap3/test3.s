# Test for virtual ops

mov r60, $1000
call :myfunc
mov r0, $999

:myfunc
	mov r0, $123
	ret
