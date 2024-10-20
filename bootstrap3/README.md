# Stage-3 bootstrap

Implements a full assembler that supports text-format instructions, macros, and
labels up to 15 characters long.

## TODO

 - Multi-file support
 - Multiple register push/pop

## Syntax

The first character read from a line determines the behaviour of this assembler:

 - `#`: Comment (ignore text until newline)
 - `=abcd`: Defines a 2-byte (16-bit) hex constant
 - `:abcdefgh`: Defines a global label
 - `.abcdefgh`: Defines a local label (local to the enclosing global)
 - `tab`: Assemble (copy) chars to output until a newline
 - `newline`: Blank line, skipped

## Instruction set

| Instruction | Expansion | Notes |
|-------------|-----------|-------|
| `data ...` | `...` | Literal data. Use backslash hex for escapes (`\00`, `\ff`) |
| `mov? r1, r2` | `=?12` | Loads a register from another |
| `ldc r1,` | `=$1 ` | Load constant |
| `ldh r1, 2345` | `=#1 2345` | Load high bits |
| `ldb [r1], r2` | `=[12` | Load byte |
| `ldw [r1], r2` | `={12` | Load word |
| `ldd [r1], r2` | `=(12` | Load double word |
| `stb [r1], r2` | `[=12` | Store byte |
| `stw [r1], r2` | `{=12` | Store word |
| `std [r1], r2` | `(=12` | Store double word |
| `add? r1, r2` | `+?12` | Add with optional condition |
| `sub? r1, r2` | `-?12` | Subtract with optional condition |
| `mul? r1, r2` | `*?12` | Multiply with optional condition |
| `div? r1, r2` | `/?12` | Divide with optional condition |
| `mod? r1, r2` | `%?12` | Modulo with optional condition |
| `or? r1, r2` | `\|?12` | Bitwise OR with optional condition |
| `and? r1, r2` | `&?12` | Bitwise AND with optional condition |
| `xor? r1, r2` | `^?12` | Bitwise XOR with optional condition |
| `eq r1, r2` | `?=12` | Compare equal |
| `ne r1, r2` | `?!12` | Compare not equal |
| `gt r1, r2` | `?>12` | Compare greater than |
| `lt r1, r2` | `?<12` | Compare less than |
| `push r1` | `- yd(=y1` | Push to stack |
| `pop r1` | `=(1y+ yd` | Pop from stack |
| `sys r1` | `S 1 ` | System call with 1 argument |
| `sys r1, r2` | `S 12` | System call with 2 arguments |
| `sys r1, r2, r3` | `S+123   ` | System call with 3 arguments |
| `sys r1, r2, r3, r4` | `S+1234  ` | System call with 4 arguments |
| `sys r1, r2, r3, r4, r5` | `S+12345 ` | System call with 5 arguments |
| `sys r1, r2, r3, r4, r5, r6` | `S+123456` | System call with 6 arguments |
| `jump` | `=$z ` | Unconditional jump |
| `jump^` | `+?ze=$z ` | Jump if flag |
| `jump?` | `+^ze=$z ` | Jump if not zero |
| `ret` | `=(xy+ yd= zx` | Unconditional return |
| `ret?` | `=(xy+?yd=?zx` | Conditional return |
| `call` | `- yd=#x 000c+ xz(=yx=$z ` | Function call |
| `db 0` | `\00` | Define zero byte |
| `dw 0` | `\00\00` | Define zero word |
| `dd 0` | `\00\00\00\00` | Define zero double word |
