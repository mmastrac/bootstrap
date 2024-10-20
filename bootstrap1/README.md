# Stage-1 bootstrap

Loads from `bootstrap2.s`, ignoring comment lines and supporting a special :abcd syntax
that sets the current write address to that address. This allows for code layout at
absolute addresses to avoid having to manually calculate jump targets.

## Functionality of this stage

This stage assembles a single source file to a binary output. By adding the ability to seek within the
output file to a given write address, we avoid having to manually hand-link our source at the instruction level
(assuming that enough space is given for each code block).

We also support real comments at this stage, making source code much more readable.

The first character read from a line determines the behaviour of this assembler:

 - `#`: Comment (ignore text until newline)
 - `:abcd`: Set write address to hex 'abcd'
 - `tab`: Assemble (copy) chars to output until a newline
 - `newline`: Blank line, skipped

## Notes on syntax in this file

`bootstrap0` does not allow this file to contain comments, but we can roughly encode them between code
segments. Labels are not allowed, so all jumps must be hand-calculated. See `bootstrap0.bin` for more details.

It is not recommended to make major changes to this bootstrap as it is difficult to modify.
