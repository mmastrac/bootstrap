#include "syscall.h"

:_main
	mov r0, 2
	mov r1, :pass
	call :_dprintf
	sub r0, r0
	ret

:pass
	ds "Pass!" 10
