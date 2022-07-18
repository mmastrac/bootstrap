# Stage-4 Bootstrap

Stage 4 builds a basic C-like compiler that is used to bootstrap the final C compiler in stage 5.

## Functionality of this stage

This stage contains multiple sub-stages where we bootstrap a compiler in assembly and gradually increase its complexity.

The lexer is written in assembly and used for both sub-stages. It handles C tokens and _very_ basic preprocessor declarations. It does
not support complex macros at this time.

### `compiler0`

The `compiler0` sub-stage is a very basic C compiler written entirely in assembly language. It uses the lexer directly and emits
equivalent, highly-unoptimized assembly from C-like code. It is very limited and cannot handle complex statements, expressions, and
has serious limitations around arrays.

### `compiler1`

The `compiler1` sub-stage is a much richer C compiler, written in C (though the dialect is limited to what `compiler0` supports). This
sub-stage is powerful enough to compile the `bootstrap5` full C compiler, which is written in a subset of C89 and is also compilable
by any standard C compiler.

Ideally the C portion of `compiler1` should compile with a standard C compiler, but this is not a hard requirement. 
