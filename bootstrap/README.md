# Bootstrap stages

## bootstrap0.bin

A basic VM written in pure VM ASCII. The goal of this stage is to get a slightly more readable `bootstrap1.bin` compiled by ignoring any
control character bytes (< 0x20).

## bootstrap1.s

A basic assembler that skips comments (lines starting with `#`) and allows the use of a colon address (ie: `:ABCD`) to seek the output
file to a given hex offset. All "assembled" lines must start with a tab character.

## bootstrap2.s

A more complex assembler with support for two-level symbols (ie: `:global__` + `.local___`) and two-pass symbol resolution. Also supports
constant-style symbols that can be defined via `=symbol__ ABCD`. Note that all symbols MUST be eight characters long - no more, no less.

There are a few hard-coded macros in this stage that allow `bootstrap3` to be simpler:

```
@ret.: Return from proc
@ret?: Return from proc if flag
@ret^: Return from proc if not flag
@jump: Jump to address (@jump:label___)
@jmp?: Jump to address if flag (@jmp?:label___)
@jmp^: Jump to address if not flag (@jmp^:label___)
@call: Call address (@call:label___)
@pshN/@popN: Push/pop register N to the stack (supports 0-3)
```

## bootstrap3.s

A "complete" assembler that allows input from multiple files, linked together to create an output executable. This assembler has a more
natural, intel-like syntax.

The output for a given opcode from this assembler may or may not correspond to a single VM opcode. The compiler takes over one of the VM
registers as a "compiler temporary", allowing us to create some CISC-style ops that drastically reduce instruction counts for various 
types of operations.

This assembler also allows for more complex macros that make procedure calls, arguments and locals much simpler. As part of this 
functionality, the compiler defines a calling convention that determines which registers are caller- or callee-saved.

See `README.md` under `bootstrap4` for more details (TODO: move this to bootstrap3!)

## bootstrap4/

This is the first stage C compiler that compilers a (very reduced) subset of C. Currently a work-in-progress.
