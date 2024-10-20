#!/usr/bin/env python3
import sys
import re

INSTRUCTION_PATTERNS_1 = {
    "+": "add",
    "-": "sub",
    "*": "mul",
    "/": "div",
    "=": "mov",
    "%": "mod",
    "|": "or",
    "&": "and",
    "^": "xor",
}

INSTRUCTION_PATTERNS_2 = {
    "?=": "eq",
    "?!": "ne",
    "?>": "gt",
    "?<": "lt",
    "(=": "std",
    "[=": "stb",
    "{=": "stw",
    "=[": "ldb",
    "={": "ldw",
    "=(": "ldd",
}

MACRO_PATTERNS = {
    "psh": "push r",
    "pop": "pop r",
    "jump": "jump ",
    "jmp?": "jump? ",
    "jmp^": "jump^ ",
    "call": "call ",
    "ret.": "ret",
    "ret?": "ret?",
    "ret^": "ret^",
}

def process_global_label(line):
    label = line[1:].strip()
    return f":{label:8}"

def process_local_label(line):
    label = line[1:].strip()
    return f".{label:8}"

def process_constant(line):
    parts = line[1:].split()
    name, value = parts[0], parts[1]
    return f"={name:8} {value:4}"

def process_macro(line):
    if line[2:5] in MACRO_PATTERNS:
        return f"\t{MACRO_PATTERNS[line[2:5]]}{line[5:]}"
    if line[2:6] in MACRO_PATTERNS:
        return f"\t{MACRO_PATTERNS[line[2:6]]}{line[6:]}"
    sys.stderr.write(f"Error: Unrecognized macro: {line}\n")
    sys.exit(1)

def process_instruction(line):
    line = line[1:]
    if line == "\\00":
        return "\tdb 0"
    if line == "\\00\\00":
        return "\tdw 0"
    if line == "\\00\\00\\00\\00":
        return "\tdd 0"
    if line == "\\00\\00\\00\\00\\00\\00\\00\\00":
        return "\tdd 0\n\tdd 0"
    if len(line) < 4:
        return f"\tdata {line}"
    
    if line[0] == ':' or line[0] == '.':
        if len(line) == 9:
            return f"\t{line}"
        sys.stderr.write(f"Error: Unrecognized line: {line}\n")
        sys.exit(1)
    
    if line[0] == "S" and (re.match(r'S [\da-zA-Z ][\da-zA-Z ]', line) or re.match(r'S\+[\da-zA-Z ][\da-zA-Z ][\da-zA-Z ][\da-zA-Z ][\da-zA-Z ][\da-zA-Z ]', line)):
        # Parse syscall opcode. Spaces mean no register.
        # "S 0 " -> sys r0
        # "S 01" -> sys r0, r1
        # "S+012345" -> sys r0, r1, r2, r3, r4, r5
        registers = line[1:].strip()
        if registers.startswith('+'):
            registers = registers[1:]
        registers = [f"r{r}" for r in registers]
        while len(registers) < 6:
            registers.append('')
        return f"\tsys {', '.join(r for r in registers if r)}"
    if len(line) == 8 and line[:2] == "=#":
        return f"\tldh r{line[2]}, {line[4:]}"
    if len(line) == 13 and line[:2] == "=$":
        return f"\tldc r{line[2]}, {line[4:]}"
    if line[:2] in INSTRUCTION_PATTERNS_2 and len(line) == 4:
        return f"\t{INSTRUCTION_PATTERNS_2[line[:2]]} r{line[2]}, r{line[3]}"
    if line[0] in INSTRUCTION_PATTERNS_1 and len(line) == 4 and line[1] in " ^?":
        return f"\t{INSTRUCTION_PATTERNS_1[line[0]]}{line[1] if line[1] != ' ' else ''} r{line[2]}, r{line[3]}"
    
    if ":" in line:
        parts = line.split(':')
        if len(parts) != 2:
            sys.stderr.write(f"Error: Unrecognized line: {line}\n")
            sys.exit(1)
        space = '\\20'
        return f"\tdata {parts[0].replace(' ', space)}\n\t:{parts[1]}"
    if "." in line:
        sys.stderr.write(f"Error: Unrecognized line: {line}\n")
        sys.exit(1)
    if line.endswith(' '):
        sys.stderr.write(f"Error: Unrecognized line: {line}\n")
        sys.exit(1)
    return f"\tdata {line}"

def process_comment(line):
    return line

def process_empty_line(line):
    return ""

def migrate_assembly():
    for line in sys.stdin:
        line = line.rstrip("\n")
        if line.startswith(':'):
            print(process_global_label(line))
        elif line.startswith('.'):
            print(process_local_label(line))
        elif line.startswith('='):
            print(process_constant(line))
        elif line.startswith('\t@'):
            print(process_macro(line))
        elif line.startswith('\t'):
            print(process_instruction(line))
        elif line.startswith('#'):
            print(process_comment(line))
        elif not line:
            print(process_empty_line(line))
        else:
            sys.stderr.write(f"Error: Unrecognized line format: {line}\n")
            sys.exit(1)

if __name__ == "__main__":
    migrate_assembly()
