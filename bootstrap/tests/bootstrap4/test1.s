#include "syscall.h"

:_main
	mov r0, 2
	mov r1, :pass
	mov r2, 7
	sys @SC_WRITE r0 r1 r2
	sub r0, r0
	ret

:pass
	ds "Pass!" 10
