# Test for virtual ops
#define sp r60
mov @sp, $1000
call :myfunc
mov r0, $999

:myfunc
	mov r0, $123
	ret
