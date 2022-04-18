#include "regs.h"
#include "../bootstrap4/lex/lex.h"

# Assumes that we are positioned after the function's opening bracket
:_compile_function_args
    %arg file
    %arg buf
    %arg buflen

    %call :_compiler_out, &"# arguments\n"
# We're pretty loose about parsing function args here
.loop
    %call :_lex, @file, @buf, @buflen
	eq @ret, ')'
    jump? .done
    eq @ret, ','
    jump? .loop

    %call :_compiler_expect, @ret, @buf, @TOKEN_INT
    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_IDENTIFIER
    %call :_compiler_out, &"    %%arg %s\n", @buf
    jump .loop

.done
    %ret
