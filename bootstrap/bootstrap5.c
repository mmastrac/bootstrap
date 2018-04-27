#include "include/syscall.h"


#define OPEN_READ 0
#define OPEN_WRITE 1

open(filename, mode) {
	if (mode == OPEN_READ) {
		syscall(SC_OPEN, filename, O_RDONLY);
	} else {
		syscall(SC_OPEN, filename, O_RDWR | O_TRUNC | O_CREAT);
	}
}

main(argc, argv) {
	if (argc < 3) {
		error("Usage: bootstrap5 [input] [output]");
	}
}
