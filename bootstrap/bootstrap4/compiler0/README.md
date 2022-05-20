# compiler0

NOTE: This stage is a work-in-progress!

This compiler stage transpiles a very, very basic subset of C (with the bare minimum level of error checking)
to our assembly dialect. Note that all compiler stages use a common lexer that is robust enough to compile a full
C program that makes minimal use of preprocessing.

`compiler0` is used to compile `compiler1`, which is a much more feature-rich C compiler.

As we have a full assembler and linking environent, we can gradually replace the compiler itself with more
enhanced versions by changing the files we are linking.

This `compiler0` stage supports:

 * Simple, binary expressions, nesting and unary operations must use parentheses
 * Function calls
 * Local variables (defined top-of-function, int initialization allowed) and function args
 * Basic globals (int-style) with optional constant/array initializers only. `extern` is also supported for assembly interop.
 * `if` statements (no `else`)
 * `while`/`for` loops, plus `break` and `continue` (`break`/`continue` don't work w/nesting)
 