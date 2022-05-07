#include "regs.h"
#include "../bootstrap4/lex/lex.h"

:_is_type_token
    %arg token
    mov @tmp0, .jump_table
    mov @ret, @token
    jump :_compiler_jump_table

.jump_table
    dd @TOKEN_INT, .ok
    dd @TOKEN_CHAR, .ok
    dd @TOKEN_CONST, .ok
    dd @TOKEN_UNSIGNED, .ok
    dd @TOKEN_VOID, .ok
    dd '*', .ok
    dd @TOKEN_NONE, .bad

.bad
    mov @ret, 0
    %ret
.ok
    mov @ret, 1
    %ret

:_compile_function_type
    %arg file
    %arg buf
    %arg buflen
    %local token

    # First token must be a type token
    %call :_lex, @file, @buf, @buflen
    %call :_is_type_token, @ret
    jump? .loop
	%call :_fatal, &"Unexpected type token encountered\n"

.loop
    %call :_lex_peek, @file, @buf, @buflen
    %call :_is_type_token, @ret
    eq @ret, 1
    jump^ .done
    %call :_lex, @file, @buf, @buflen
    jump .loop

.done
    %ret

# Assumes that we are positioned after the function's opening bracket
:_compile_function_args
    %arg file
    %arg buf
    %arg buflen

    %call :_compiler_out, &"# arguments\n"
# We're pretty loose about parsing function args here
.loop
    %call :_lex_peek, @file, @buf, @buflen
	eq @ret, ')'
    jump? .done
    eq @ret, ','
    jump? .comma

    %call :_compile_function_type, @file, @buf, @buflen
    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_IDENTIFIER
    %call :_compiler_out, &"    %%arg %s\n", @buf
    jump .loop

.comma
    %call :_lex, @file, @buf, @buflen
    jump .loop

.done
    %call :_lex, @file, @buf, @buflen
    %ret
