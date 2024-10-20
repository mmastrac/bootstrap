#include "regs.h"
#include "../bootstrap5/lex/lex.h"

# Returns the size of the type token:
# - 0 if not a type token
# - 99 if a pointer marker character (*)
# - Otherwise, returns the size in bytes (1, 2, or 4)
:_is_type_token
    %arg token
    mov @tmp0, .jump_table
    mov @ret, @token
    jump :_compiler_jump_table

.jump_table
    dd @TOKEN_INT, .ok4
    dd @TOKEN_CHAR, .ok1
    dd @TOKEN_SHORT, .ok2
    dd @TOKEN_CONST, .ok4
    dd @TOKEN_UNSIGNED, .ok4
    dd @TOKEN_VOID, .ok4
    dd '*', .ok0
    dd @TOKEN_NONE, .bad

.bad
    mov @ret, 0
    %ret
.ok0
    mov @ret, 99
    %ret
.ok1
    mov @ret, 1
    %ret
.ok2
    mov @ret, 2
    %ret
.ok4
    mov @ret, 4
    %ret

# Returns the size of the type token
:_compile_function_type
    %arg file
    %arg buf
    %arg buflen
    %local token
    %local size

    mov @size, 0

    # First token must be a type token
    %call :_lex, @file, @buf, @buflen
    %call :_is_type_token, @ret
    eq @ret, 0
    jump? .error
    eq @ret, 99
    jump? .loop
    mov @size, @ret

.loop
    %call :_lex_peek, @file, @buf, @buflen
    %call :_is_type_token, @ret
    eq @ret, 0
    jump? .done
    eq @ret, 99
    jump? .skip
    mov @size, @ret
.skip
    %call :_lex, @file, @buf, @buflen
    jump .loop

.done
    %call :_compiler_out, &"# size: %d\n", @size
    mov @ret, @size
    %ret

.error
    %call :_fatal, &"Unexpected type token encountered\n"

# Assumes that we are positioned at the function args' opening bracket
:_compile_function_args
    %arg file
    %arg buf
    %arg buflen
    %local size

    %call :_compiler_read_expect, @file, @buf, @buflen, '('
    %call :_compiler_out, &"# arguments\n"
# We're pretty loose about parsing function args here
.loop
    %call :_lex_peek, @file, @buf, @buflen
	eq @ret, ')'
    jump? .done
    eq @ret, ','
    jump? .comma
    eq @ret, @TOKEN_ELLIPSIS
    jump? .comma

    %call :_compile_function_type, @file, @buf, @buflen
    mov @size, @ret
    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_IDENTIFIER
    %call :_is_global, @buf
    eq @ret, 0
    jump? .no_shadow
    %call :_fatal, &"Parameter cannot shadow a global"
.no_shadow
    %call :_track_local, @buf, @size
    %call :_compiler_out, &"    %%arg %s\n", @buf
    jump .loop

.comma
    %call :_lex, @file, @buf, @buflen
    jump .loop

.done
    %call :_lex, @file, @buf, @buflen
    %ret
