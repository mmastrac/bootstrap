#include "regs.h"
#include "../lex/lex.h"

#===========================================================================
# Compiles a constant initializer as int-sized data statements.
#===========================================================================
:_compile_constant
    %arg file
    %arg buf
    %arg buflen
    %arg size
    %local label

    %call :_lex_peek, @file, 0, 0
    mov @tmp0, .jump_table
    jump :_compiler_jump_table

.error
    %call :_fatal, &"Unexpected token in _compile_expr_stack!\n"
    dd 0

.jump_table
    dd @TOKEN_CONSTANT, .constant
    dd @TOKEN_STRING_LITERAL, .string_literal
    dd @TOKEN_IDENTIFIER, .identifier
    dd '{', .array
    dd '}', .done
    dd @TOKEN_NONE, .error

.constant
    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_CONSTANT
    eq @size, 1
    jump? .use_db
    %call :_compiler_out, &"    dd %s\n", @buf
    jump .end_constant
.use_db
    %call :_compiler_out, &"    db %s\n", @buf
.end_constant
    jump .done

.string_literal
    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_STRING_LITERAL
    %call :_compiler_out, &"    dd &\"%s\"\n", @buf
    jump .done

.identifier
    %call :_compiler_read_expect, @file, @buf, @buflen, @TOKEN_IDENTIFIER
    %call :_compiler_out, &"    dd :%s\n", @buf
    jump .done

.array
    # Create an indirection for array data
    %call :_compiler_out, &"    dd :__array_data_%s\n", @buf
    %call :_compiler_out, &":__array_data_%s\n", @buf

    %call :_compiler_read_expect, @file, @buf, @buflen, '{'
.array_loop
    %call :_compile_constant, @file, @buf, @buflen, @size
    %call :_lex_peek, @file, @buf, @buflen
    eq @ret, '}'
    jump? .array_done
    %call :_compiler_read_expect, @file, @buf, @buflen, ','
    jump .array_loop

.array_done
    %call :_compiler_read_expect, @file, @buf, @buflen, '}'

.done
    %ret
