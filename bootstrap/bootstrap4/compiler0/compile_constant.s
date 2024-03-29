#include "regs.h"
#include "../bootstrap4/lex/lex.h"

#===========================================================================
# Compiles a constant initializer as int-sized data statements.
#===========================================================================
:_compile_constant
    %arg file
    %arg buf
    %arg buflen
    %local label

    %call :_lex_peek, @file, @buf, @buflen
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
    %call :_compiler_out, &"    dd %s\n", @buf
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
    %call :_compile_get_next_label
    mov @label, @ret
    %call :_compiler_out, &"    dd :__array_data_%d\n", @label
    %call :_compiler_out, &":__array_data_%d\n", @label

    %call :_compiler_read_expect, @file, @buf, @buflen, '{'
.array_loop
    %call :_compile_constant, @file, @buf, @buflen
    %call :_lex_peek, @file, @buf, @buflen
    eq @ret, '}'
    jump? .array_done
    %call :_compiler_read_expect, @file, @buf, @buflen, ','
    jump .array_loop

.array_done
    %call :_compiler_read_expect, @file, @buf, @buflen, '}'

.done
    %ret
