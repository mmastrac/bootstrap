#include "syscall.h"

:_main
	mov r0, :pass
	call :_dprintf
	ret

:pass
	ds "Pass!" 10
