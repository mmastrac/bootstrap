# Stage-4 bootstrap

A "complete" assembler that allows input from multiple files, linked together to create an output
executable. This assembler has a more natural, intel-like syntax.

## Functionality of this stage

The output for a given opcode from this assembler may or may not correspond to a single VM opcode. The compiler takes over one of the VM
registers as a "compiler temporary", allowing us to create some CISC-style ops that drastically reduce instruction counts for various 
types of operations.

This assembler also allows for more complex macros that make procedure calls, arguments and locals much simpler. As part of this 
functionality, the compiler defines a calling convention that determines which registers are caller- or callee-saved.

## Assembly opcodes

TODO

## Calling convention

  - Argument registers (`r0`-`r7`) are not preserved across calls (caller-saved)
  - Return values provided in r0 (32-bit) or r0+r1 (64-bit)
  - Temporary registers (`r55`-`r58`) are not preserved across calls (caller-saved)
  - `r59` is a compiler temporary used for compound operations
  - `r60` is the stack pointer
  - `r61` is the program counter
  - All other registers must be restored to state before call

## Macros

Macros are prefixed with `%` to indicate that they are "local-variable" aware. `call` and `ret` both have non-macro versions that are not local-aware. If `ret` is used in the scope of a global label that uses `%local` or `%arg`, the compiler will throw an error.

| Macro | Description | Example |
|---|---|---|
| `%call` `[args...]` | Saves the current PC to the stack, calls the function placing args in `r0`-`r7` | `%call :strlen @mystring`  |
| `%tailcall` `[args...]` | Replaces the current stack frame with another function (equivalent to `%call` + `%ret`) | `%tailcall :strlen @mystring`  |
| `%ret` `[register]` | Returns from a function, popping off any saved `%local`s or `%arg`s | `%ret r0` |
| `%local` `[name...]` | Allocates local register(s), saving the previous value to the stack | `%local x, y` |
| `%arg` `[name...]` | Allocates argument register(s), saving the previous value to the stack and copying the argument value to it | `%arg x, y` |

## Linker symbols/macros

The linker defines multiple special symbols that can be used for determining the size of stack frames and code.

`:__END__` Points to the end of the binary in memory
`@__LOCALS_SIZE__` Equal to size of locals on stack
