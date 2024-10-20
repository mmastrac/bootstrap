#!/usr/bin/env python3
import sys
import re

def lint_bootstrap2_assembly(file_path):
    labels = set()
    label_uses = set()
    local_labels = {}
    current_global_label = None

    with open(file_path, 'r') as file:
        for line_number, line in enumerate(file, 1):
            if not line or line.startswith('#') or line == '\n':
                continue

            if line.startswith(':'):
                if len(line) != 10:
                    print(f"Warning: Global label '{line[:-1]}' on line {line_number} is less than 8 characters.")
                label = line[1:9]
                labels.add(label)
                current_global_label = label
                local_labels[current_global_label] = set()
            elif line.startswith('.'):
                if len(line) != 10:
                    print(f"Warning: Local label '{line[:-1]}' on line {line_number} is less than 8 characters.")
                if not current_global_label:
                    print(f"Warning: Local label on line {line_number} without a preceding global label.")
                else:
                    local_label = line[1:9]
                    if len(local_label) < 8:
                        print(f"Warning: Local label '{local_label}' on line {line_number} is less than 8 characters.")
                    local_labels[current_global_label].add(local_label)
            elif line.startswith('='):
                if len(line) != 15:
                    print(f"Warning: Invalid constant definition length on line {line_number}: {line} ({len(line)})")
                    continue
                else:
                    parts = [line[1:9], line[10:14]]
                if len(parts) != 2 or len(parts[0]) != 8 or len(parts[1]) != 4:
                    print(f"Warning: Invalid constant definition on line {line_number}: {line}")
                elif not all(c.isalnum() or c == '_' for c in parts[0]) or not all(c in '0123456789ABCDEFabcdef' for c in parts[1]):
                    print(f"Warning: Invalid constant definition on line {line_number}: {line}")
                labels.add(parts[0])
            elif line.startswith('\t@'):
                macro = line[2:6]
                valid_macros = {'ret.', 'ret?', 'ret^', 'jump', 'jmp?', 'jmp^', 'call', 'psh0', 'psh1', 'psh2', 'psh3', 'pop0', 'pop1', 'pop2', 'pop3'}
                if macro not in valid_macros:
                    print(f"Warning: Invalid macro on line {line_number}: {line}")
                label_matches = re.findall(r'[:.](.{8})', line)
                label_uses.update(label_matches)
                for match in label_matches:
                    if not line[:-1].endswith(match):
                        print(f"Warning: Label '{match}' on line {line_number} is not at the end of the line.")
            elif line.startswith('\t'):
                line = line[:-1]
                while True:
                    last_label_index = max(line.rfind(':'), line.rfind('.'))
                    if last_label_index == -1 or last_label_index + 9 > len(line):
                        break
                    
                    potential_label = line[last_label_index+1:last_label_index+9]
                    if len(potential_label) == 8 and all(c.isalnum() or c == '_' for c in potential_label):
                        label_uses.add(potential_label)
                        if not line.strip().endswith(potential_label):
                            print(f"Warning: Label '{potential_label}' on line {line_number} is not at the end of the line.")
                        line = line[:last_label_index] + line[last_label_index+9:]
                    else:
                        break
            else:
                print(f"Warning: Invalid line prefix on line {line_number}: {line}")

    # Check for unused labels
    unused_labels = labels - label_uses
    for label in unused_labels:
        print(f"Warning: Label '{label}' is defined but never used.")

    # Check for undefined labels
    undefined_labels = label_uses - labels - set().union(*local_labels.values())
    for label in undefined_labels:
        print(f"Warning: Label '{label}' is used but never defined.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python lint.py <assembly_file>")
        sys.exit(1)
    
    lint_bootstrap2_assembly(sys.argv[1])
