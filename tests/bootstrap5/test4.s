#include "syscall.h"

:_main
	push &"Pass"
	%call :_dprintf, 2, &"%s!\n"
	pop r0
	sub r0, r0
	ret
