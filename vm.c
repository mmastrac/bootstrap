#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define PROGRAM_LENGTH 65536
#define PC 61
#define dprintf if (verbose > VERBOSE_NONE) printf

#define VERBOSE_NONE 0
#define VERBOSE_DEBUG 1
#define VERBOSE_TRACE 2

int _argc;
const char** _argv;
int verbose = 0;
int dump = 0;

uint8_t flag;
uint8_t program[PROGRAM_LENGTH];
uint32_t registers[64];

void debug(const char* msg) {
	dprintf("DEBUG %s\n", msg);
}

void invalid() {
	printf("Invalid opcode\n");
	if (dump) {
		printf("Dumped memory to /tmp/memory.bin\n");
		int fd = open("/tmp/memory.bin", O_CREAT | O_TRUNC | O_WRONLY, 0777);
		write(fd, &program[0], sizeof(program));
		close(fd);
	}
	exit(1);
}

void write16(void* location, uint32_t value) {
	uint8_t* bytes = (uint8_t*)location;
	bytes[0] = value & 0xff;
	bytes[1] = (value >> 8) & 0xff;
}

void write32(void* location, uint32_t value) {
	uint8_t* bytes = (uint8_t*)location;
	bytes[0] = value & 0xff;
	bytes[1] = (value >> 8) & 0xff;
	bytes[2] = (value >> 16) & 0xff;
	bytes[3] = (value >> 24) & 0xff;
}

uint32_t read16(void* location) {
	uint8_t* bytes = (uint8_t*)location;
	return bytes[0] | bytes[1] << 8;
}

uint32_t read32(void* location) {
	uint8_t* bytes = (uint8_t*)location;
	return bytes[0] | bytes[1] << 8 | bytes[2] << 16 | bytes[3] << 24;
}

uint32_t readpc8() {
	uint8_t value = program[registers[PC]];
	registers[PC]++;
	return value;
}

uint32_t readpc32() {
	uint32_t value = read32(&program[registers[PC]]);
	registers[PC] += 4;
	return value;
}

int map_open_flags(uint32_t flags) {
	int out_flags = 0;
	switch (flags & 3) {
		case 0:
			out_flags |= O_RDONLY;
			break;
		case 1:
			out_flags |= O_WRONLY;
			break;
		case 2:
			out_flags |= O_RDWR;
			break;
	}

	if (flags & 0x200) {
		out_flags |= O_CREAT;
	}
	if (flags & 0x400) {
		out_flags |= O_TRUNC;
	}

	return out_flags;
}

int sc(uint32_t syscall,
	uint32_t arg1, uint32_t arg2, uint32_t arg3, uint32_t arg4, uint32_t arg5) {
	if (syscall == 0) {
		debug("open");
		dprintf("%s %08x (%08x)\n", (const char*)&program[arg1], arg2, map_open_flags(arg2));
		int r = open((const char*)&program[arg1], map_open_flags(arg2), 0777);
		if (r < 0) {
			perror("open");
		}
		return r;
	} else if (syscall == 1) {
		debug("read");
		return read(arg1, &program[arg2], arg3);
	} else if (syscall == 2) {
		debug("write");
		return write(arg1, &program[arg2], arg3);
	} else if (syscall == 3) {
		debug("lseek");
		int whence = 0;
		if (arg3 == 0) {
			whence = SEEK_SET;
		} else if (arg3 == 1) {
			whence = SEEK_CUR;
		} else if (arg3 == 2) {
			whence = SEEK_END;
		} else {
			invalid();
		}
		return (uint32_t)(int32_t)lseek(arg1, (off_t)(int32_t)arg2, whence);
	} else if (syscall == 4) {
		debug("close");
		return close(arg1);
	} else if (syscall == 5) {
		debug("getargv");
		uint32_t needed = _argc * 4; // includes trailing zero
		for (int i = 1; i < _argc; i++) {
			needed += strlen(_argv[i]) + 1;
		}
		uint8_t* address_write = &program[arg1];
		uint32_t string_write = arg1 + _argc * 4;
		if (needed <= arg2) {
			for (int i = 1; i < _argc; i++) {
				write32(address_write, string_write);
				strcpy((char*)&program[string_write], _argv[i]);
				string_write += strlen(_argv[i]) + 1;
				address_write += 4;
			}
			write32(address_write, 0);
		} else {
			dprintf("Buffer not large enough\n");
		}
		return needed;
	} else if (syscall == 6) {
		debug("getmemsize");
		return PROGRAM_LENGTH;
	} else if (syscall == 7) {
		debug("exit");
		if (dump) {
			printf("Dumped memory to /tmp/memory.bin\n");
			int fd = open("/tmp/memory.bin", O_CREAT | O_TRUNC | O_WRONLY, 0777);
			write(fd, &program[0], sizeof(program));
			close(fd);
		}
		exit(arg1);
		return 0;
	} else if (syscall == 8) {
		debug("openat");
		dprintf("%x %s %08x\n", arg1, (const char*)&program[arg2], arg3);
		int r = openat(arg1 == 0xffffff38 ? AT_FDCWD : (int)arg1, (const char*)&program[arg2], map_open_flags(arg3), 0777);
		if (r < 0) {
			perror("openat");
		}
		return r;
	} else {
		printf("%x\n", syscall);
		invalid();
	}
	return 0;
}

int char_to_register(uint8_t reg) {
	if (reg >= '0' && reg <= '9') {
		return reg - '0';
	}
	if (reg >= 'A' && reg <= 'Z') {
		return reg - 'A' + 10;
	}
	if (reg >= 'a' && reg <= 'z') {
		return reg - 'a' + 36;
	}
	if (reg == ' ') {
		return 0;
	}
	invalid();
}

uint8_t hexchar(const char hex) {
	if (hex >= '0' && hex <= '9') {
		return hex - '0';
	}
	if (hex >= 'a' && hex <= 'f') {
		return hex - 'a' + 10;
	}
	invalid();
	return 0;
}

uint16_t readpchex() {
	return hexchar(readpc8()) << 12 | hexchar(readpc8()) << 8 | hexchar(readpc8()) << 4 | hexchar(readpc8()) << 0;
}

uint32_t rhs(uint8_t op2, uint8_t op4) {
	if (op2 == ' ') {
		return registers[char_to_register(op4)];
	}

	if (op2 == '!') {
		// Sign-extended
		return (int8_t)op4;
	}

	debug("invalid load");
	invalid();
}

int main(int argc, const char** argv) {
	int fd;

	while (argc > 1) {
		if (strcmp(argv[1], "-v") == 0) {
			verbose++;
		} else if (strcmp(argv[1], "-d") == 0) {
			dump++;
		} else {
			break;
		}
		argv++;
		argc--;
	}

	if (argc <= 1) {
		printf("USAGE: vm [-v [-v]] program [arguments...]\n");
		exit(1);
	}

	_argc = argc;
	_argv = argv;

	flag = 0;
	memset(program, 0, PROGRAM_LENGTH);
	memset(registers, 0, sizeof(registers));

	fd = open(argv[1], O_RDONLY);
	read(fd, program, PROGRAM_LENGTH);
	close(fd);

	while (1) {
		dprintf("PC = %08x\n", registers[PC]);
		if (verbose >= VERBOSE_TRACE) {
			for (int i = 0; i < sizeof(registers) / sizeof(registers[0]); i += 8) {
				dprintf("%08x %08x %08x %08x %08x %08x %08x %08x\n", registers[i], registers[i+1], registers[i+2], registers[i+3],
					registers[i+4], registers[i+5], registers[i+6], registers[i+7]);
			}
		}

		int pc = registers[PC];
		uint8_t op1 = program[pc+0];
		uint8_t op2 = program[pc+1];
		uint8_t op3 = program[pc+2];
		uint8_t op4 = program[pc+3];
		registers[PC] += 4;

		dprintf("%c%c%c%c\n", op1, op2, op3, op4);

		// Only if flag is set
		if (op2 == '?') {
			if (flag) {
				op2 = ' ';
			} else {
				// Skip
				continue;
			}
		}

		// Only if flag is not set
		if (op2 == '^') {
			if (!flag) {
				op2 = ' ';
			} else {
				// Skip
				continue;
			}
		}

		if (op1 == '=') {
			if (op2 == '#') {
				// 16-bit hex literal
				debug("hex literal");
				registers[char_to_register(op3)] = readpchex();
			} else if (op2 == '$') {
				// 32-bit binary literal
				debug("binary literal");
				registers[char_to_register(op3)] = readpc32();
			} else if (op2 == '[') {
				// 8-bit indirect load
				debug("8-bit indirect load");
				registers[char_to_register(op3)] = program[registers[char_to_register(op4)]];
			} else if (op2 == '{') {
				// 16-bit indirect load
				debug("16-bit indirect load");
				registers[char_to_register(op3)] = read16(&program[registers[char_to_register(op4)]]);
			} else if (op2 == '(') {
				// 32-bit indirect load
				debug("32-bit indirect load");
				registers[char_to_register(op3)] = read32(&program[registers[char_to_register(op4)]]);
			} else {
				registers[char_to_register(op3)] = rhs(op2, op4);
			}
		} else if (op1 == '[' && op2 == '=') {
			// 8-bit indirect store
			debug("8-bit indirect store");
			program[registers[char_to_register(op3)]] = registers[char_to_register(op4)];
		} else if (op1 == '{' && op2 == '=') {
			write16(&program[registers[char_to_register(op3)]], registers[char_to_register(op4)]);
		} else if (op1 == '(' && op2 == '=') {
			write32(&program[registers[char_to_register(op3)]], registers[char_to_register(op4)]);
		} else if (op1 == '+') {
			registers[char_to_register(op3)] += rhs(op2, op4);
		} else if (op1 == '-') {
			registers[char_to_register(op3)] -= rhs(op2, op4);
		} else if (op1 == '*') {
			registers[char_to_register(op3)] *= rhs(op2, op4);
		} else if (op1 == '/') {
			registers[char_to_register(op3)] /= rhs(op2, op4);
		} else if (op1 == '%') {
			registers[char_to_register(op3)] %= rhs(op2, op4);
		} else if (op1 == '&') {
			registers[char_to_register(op3)] &= rhs(op2, op4);
		} else if (op1 == '|') {
			registers[char_to_register(op3)] |= rhs(op2, op4);
		} else if (op1 == '^') {
			registers[char_to_register(op3)] ^= rhs(op2, op4);
		} else if (op1 == '>') {
			registers[char_to_register(op3)] >>= rhs(op2, op4);
		} else if (op1 == '<') {
			registers[char_to_register(op3)] <<= rhs(op2, op4);
		} else if (op1 == '?') {
			if (op2 == '=') {
				debug("equal?");
				flag = registers[char_to_register(op3)] == registers[char_to_register(op4)];
			} else if (op2 == '>') {
				debug("gt?");
				flag = registers[char_to_register(op3)] >registers[char_to_register(op4)];
			} else if (op2 == '<') {
				debug("lt?");
				flag = registers[char_to_register(op3)] < registers[char_to_register(op4)];
			} else if (op2 == '!') {
				debug("ne?");
				flag = registers[char_to_register(op3)] != registers[char_to_register(op4)];
			} else {
				invalid();
			}
		} else if (op1 == 'S') {
			// Syscall
			debug("syscall");
			if (op2 == ' ') {
				registers[char_to_register(op3)] = sc(registers[char_to_register(op3)], registers[char_to_register(op4)], 0, 0, 0, 0);
			} else if (op2 == '+') {
				int a = readpc8();
				int b = readpc8();
				int c = readpc8();
				int d = readpc8();
				registers[char_to_register(op3)] = sc(registers[char_to_register(op3)], registers[char_to_register(op4)],
					registers[char_to_register(a)], registers[char_to_register(b)],
					registers[char_to_register(c)], registers[char_to_register(d)]);
			} else {
				invalid();
			}
		} else if (op1 == 'J') {
			debug("jump");
			if (op2 == ' ') {
				registers[PC] = registers[char_to_register(op3)];
			} else {
				invalid();
			}
		} else {
			invalid();
		}
	}
	return 0;
}
