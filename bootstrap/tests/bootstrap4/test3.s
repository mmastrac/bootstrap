#include "syscall.h"

:_main
	push :pass
	%call :_dprintf, :string
	ret

:string
	ds "%s\n"

:pass
	ds "Pass!" 10
