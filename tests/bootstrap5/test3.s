#include "syscall.h"

:_main
	push :pass
	%call :_dprintf, 2, :string
	pop r0
	sub r0, r0
	ret

:string
	ds "%s!" 0xa

:pass
	ds "Pass"
