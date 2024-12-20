# bootstrap 

[![Build Status](https://github.com/mmastrac/bootstrap/actions/workflows/build.yml/badge.svg)](https://github.com/mmastrac/bootstrap/actions/workflows/build.yml)

Bootstrap is a small VM (< 20 ops) with an ASCII encoding. The goal of this
project is to create a readable and auditable bootstrapping process to generate
C binaries for this virtual platform or any other.

> If you wish to make an apple pie from scratch, you must first invent the universe

## Why?

 1. Trusted compilation - every program involved in compiling a given C program
    can be audited (combined with [diverse
    double-compilation](https://www.dwheeler.com/trusting-trust/) by running the
    VM on multiple platforms)
 2. Longevity - the VM spec is small enough that it can be contained in the
    executables it produces, allowing them to be run decades into the future
 3. Bootstrapping - the ability to get a C compiler running on any machine by
    implementing an extremely simple virtual machine.

## Philosophy

Each bootstrap stage should do just enough to compile the next stage. Our goal
is to hit a level of C89/C99 support that will allow us to compile and run
arbitrary software for the VM, and to build the entire software tower underneath
to get us there.

The stages should be easy to understand in isolation, and enough to hold
one-at-a-time in your head.

Stages contain _some_ but not _complete_ error checking for their inputs. Most
stages are designed to compile the next stage only and may miscompile. As the stages
advance, we add additional error checking.

In some cases we may define useful compilation utilities in earlier stages that
are re-used later in the bootstrap chain, for example linkers and shell-style
utilities.

Tools that perform strict error checking or other useful functions, but aren't
necessary for the development process may be written in any language.

## Bootstrap stages

### Stage 0

Status: *complete* ✅

Stage goal: More readable source.

[`bootstrap0.bin`](bootstrap0.bin): A basic assembler written in pure
VM ASCII. The goal of this stage is to get a slightly more readable
`bootstrap1.s` compiled by ignoring any control character bytes (< 0x20).

Enables:

```
=#0 0005
=#1 0300
=#2 1000
S+012   
```

### Stage 1

Status: *complete* ✅

Stage goal: More readable source and "hand-linking" 

[`bootstrap1.s`](bootstrap1/bootstrap1.s) ([README](bootstrap1/README.md)): A basic assembler that
skips comments (lines starting with `#`) and allows the use of a colon address
(ie: `:ABCD`) to seek the output file to a given hex offset. All "assembled"
lines must start with a tab character.

Enables:

```
:0200
# Read a char
	=#0 0001
	= 1B
	[=1a
	=#2 0001
	S+0812  
```

### Stage 2

Status: *complete* ✅

Stage goal: Automated linking, a stack

[`bootstrap2.s`](bootstrap2/bootstrap2.s) ([README](bootstrap2/README.md)): A more complex assembler
with support for two-level symbols (ie: `:global__` + `.local___`) and two-pass
symbol resolution. Also supports constant-style symbols that can be defined via
`=symbol__ ABCD`. Note that all symbols MUST be eight characters long - no more,
no less. Includes a few hard-coded stack manipulation macros in this stage to
make nested function calls simpler.

Enables:

```
# Read a char into R0
:readone_
	=$0 :curr_ifd
	@call:load32__
	=$1 :SC_READ_
```

### Stage 3

Status: *complete* ✅

Stage goal: Textual instrutions, reasonable length labels

[`bootstrap3.s`](bootstrap3/bootstrap3.s) ([README](bootstrap3/README.md)): A
fully-featured, though based assembler with support for variable-length,
two-level symbols (ie: `:global` + `.local`) and two-pass symbol resolution.
Also supports constant-style symbols that can be defined via `=symbol__ ABCD`.

Instructions are defined in textual format. This assembler has a more natural,
intel-like syntax.

Enables:

```
:read_token
# Whitespace is ignored
	call :readchar_skip_ws

# Default jump table
	push r0
	ldc r0, .jump_table
	push r0
	call :jump_table
```

### Stage 4

Status: *complete* ✅

Stage goal: A fully-featured assembler, reusable by the next stage

[`bootstrap4.s`](bootstrap4/bootstrap4.s) ([README](bootstrap4/README.md)): A
"complete" assembler that allows input from multiple files, linked together to
create an output executable. The assembler in this stage is an evolved and far
more featureful version of the one in stage 3.

The output for a given opcode from this assembler may or may not correspond to a
single VM opcode. The compiler takes over one of the VM registers as a "compiler
temporary", allowing us to create some CISC-style ops that drastically reduce
line counts for various types of operations.

This assembler also allows for more complex macros that make procedure calls,
arguments and locals much simpler. As part of this functionality, the compiler
defines a calling convention that determines which registers are caller- or
callee-saved.

Enables:

```
:__lex_consume_identifier
	%arg fd
	%arg buffer
	%arg buffer_length
	%local mark

	%call :__lex_read, @fd
	st.b [@buffer], @ret
```

### Stage 5

Status: *work in progress* 🚧

Stage goal: A reasonably-complete C compiler.

[`bootstrap5`](bootstrap5/) ([README](bootstrap5/README.md)): This is the first stage C compiler that
compilers a (very reduced) subset of C. Currently a work-in-progress.

There are multiple stages inside `bootstrap5` to build a basic compiler:
`compiler0` which builds a barebones C compiler and allows us to escape from the
world of assembly, and `compiler1` that is a much more familiar C program that
is used to compile `bootstrap6`.

The compiler outputs to assembly source that can be compiled and linked with the
previous stage.

### Stage 6

Status: *proof-of-concept* 💡

Stage goal: A fully-featured C85 (C99?) compiler.

[`bootstrap6`](bootstrap6/) ([README](bootstrap6/README.md)): A full C85 compiler written in a simpler subset of C than can compile a full CXX
compiler (as long as it conforms to C85). Currently a work-in-progress.

## Additional notes

### License

The project is under a *GPL license*, but as with the GNU C Compiler, outputs from
this program are considered copyright by the author of the input program. Mere
bundling of this bootstrap is not considered linking, nor is use of this
bootstrap to bootstrap any other system.

The GPL requires the source for this bootstrap to be transmitted with any binary
of the same program, ensuring that any use of this library is auditable and
traceable.

### On trustworthiness

To verify the trustworthiness of this source, it is highly recommended that you
use multiple VM implementations. In addition, this project ships with expected
SHA256 sums for each stage of the bootstrap that should be validated using your
own SHA256 implementation after compilation.
