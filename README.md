# bootstrap 

[![Build Status](https://travis-ci.org/mmastrac/bootstrap.svg?branch=master)](https://travis-ci.org/mmastrac/bootstrap)

Bootstrap is a small VM (< 20 ops) with an ASCII encoding. The goal of this project is to create a readable and auditable
bootstrapping process to generate C binaries for this virtual platform or any other.

## Why?

 1. Trusted compilation - every program involved in compiling a given C program can be audited (combined with [diverse double-compilation](https://www.dwheeler.com/trusting-trust/) by running the VM on multiple platforms)
 2. Longevity - the VM spec is small enough that it can be contained in the executables it produces, allowing them to be run
    decades into the future

## Bootstrap stages

### Stage 0

Status: *complete* ✅

[`bootstrap0.bin`](bootstrap/bootstrap0.bin): A basic assembler written in pure VM ASCII. The goal of this stage is
to get a slightly more readable `bootstrap1.bin` compiled by ignoring any control character bytes (< 0x20).

### Stage 1

Status: *complete* ✅

[`bootstrap1.s`](bootstrap/bootstrap1/bootstrap1.s): A basic assembler that skips comments (lines starting with `#`) and allows
the use of a colon address (ie: `:ABCD`) to seek the output file to a given hex offset. All "assembled" lines must start with a tab character.

### Stage 2

Status: *complete* ✅

[`bootstrap2.s`](bootstrap/bootstrap2/bootstrap2.s): A more complex assembler with support for two-level symbols (ie: `:global__` + `.local___`)
and two-pass symbol resolution. Also supports constant-style symbols that can be defined via `=symbol__ ABCD`. Note that all symbols MUST
be eight characters long - no more, no less. Includes a few hard-coded stack manipulation macros in this stage to make nested function calls simpler.

### Stage 3

Status: *complete* ✅

[`bootstrap3`](bootstrap/bootstrap3/): A "complete" assembler that allows input from multiple files, linked together to create an output
executable. This assembler has a more natural, intel-like syntax.

The output for a given opcode from this assembler may or may not correspond to a single VM opcode. The compiler takes over one of the VM
registers as a "compiler temporary", allowing us to create some CISC-style ops that drastically reduce instruction counts for various 
types of operations.

This assembler also allows for more complex macros that make procedure calls, arguments and locals much simpler. As part of this 
functionality, the compiler defines a calling convention that determines which registers are caller- or callee-saved.

### Stage 4

Status: *work in progress* 🚧

[`bootstrap4`](bootstrap/bootstrap4/):This is the first stage C compiler that compilers a (very reduced) subset of C. Currently a work-in-progress.

There are multiple stages inside bootstrap4 to build a basic compiler.

### Stage 5

Status: *proof-of-concept*

A full C85 compiler written in a simpler subset of C than can compile a full CXX compiler (as long as it conforms to C85). Currently a work-in-progress.
