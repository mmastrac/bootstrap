#include "syscall.h"

:_main
	push :pass
	%call :_dprintf, 2, :string
	pop r0
	ret

:string
	ds "x%sx" 0xa

:pass
	ds "Pass!" 10
