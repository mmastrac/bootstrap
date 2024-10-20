# Stage-2 bootstrap

Implements an assembler that supports two-pass labels (8-char long only), simplistic macros,
and 16-bit constants.

## Functionality of this stage

This stage assembles a single source file to a binary output. The stage adds a number of useful helps to
avoid any need to hand-calculate addresses and to make forward and backward jumps trivial. In addition,
macros allow for usage of a virtual stack, making nested function calls possible.

The first character read from a line determines the behaviour of this assembler:

 - `#`: Comment (ignore text until newline)
 - `=abcd`: Defines a 2-byte (16-bit) hex constant
 - `:abcdefgh`: Defines an 8-byte global label
 - `.abcdefgh`: Defines an 8-byte local label (local to the enclosing global)
 - `tab`: Assemble (copy) chars to output until a newline
 - `newline`: Blank line, skipped
 - `@xyz`: Replace with contents of macro `xyz` (hardcoded)

If a label (`:label___`) or constant (`=abcd`) appears in assembled code, it is replaced by the 16-bit constant
that it represents.

The supported macros are:

 - `@ret.`: Return from proc
 - `@ret?`: Return from proc if flag
 - `@ret^`: Return from proc if not flag
 - `@jump`: Jump to address (`@jump:label___`)
 - `@jmp?`: Jump to address if flag (`@jmp?:label___`)
 - `@jmp^`: Jump to address if not flag (`@jmp^:label___`)
 - `@call`: Call address (`@call:label___`)
 - `@pshN`/`@popN`: Push/pop register N to the stack (supports 0-3)

## Notes on syntax in this file

Code blocks are allocated by hand as we only have access to a seek-style (`:abcd`) "label". Some small amount
of hand-linking is required for the parsing loops.

See `bootstrap1.s` for more details.
