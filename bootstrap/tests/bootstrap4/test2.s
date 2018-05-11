#include "syscall.h"

:_main
	mov r0, 0
	sys @SC_WRITE r0 r1 r2
	ret

:pass
	ds "Pass!" 10
