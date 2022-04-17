# compiler0

NOTE: This stage is a work-in-progress!

This compiler stage transpiles a very, very basic subset of C (with the bare minimum level of error checking)
to our assembly dialect.

As we have a full assembler and linking environent, we can gradually replace the compiler itself with more
enhanced versions by changing the files we are linking.

This `compiler0` stage supports:

 * Simple, un-nested binary expressions
 * Function calls
 * Local variables and function args
 * `if` statements (no `else`)
 * `while` loops, plus break and continue (limited to one per function)
