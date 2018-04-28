#include "include/syscall.h"

/**

Simple subset of C.

 - Two fundamental types: char, int
 - Single-level pointer supported
 - malloc (but no free)
 - alloca (freed on function return)
 - Simple assignment only (does not support -= += ++ -- etc)
 - No forward declarations, but symbol resolution is two-pass
 - No cast expression, but assignment always succeeds
*/

#define OPEN_READ 0
#define OPEN_WRITE 1

char* newline = "\n";
int input_handle;
int output_handle;

/***********************************************************************/
/* Utility routines */
/***********************************************************************/

void fatal(char* error) {
	syscall(SC_WRITE, 2, error, strlen(error));
	syscall(SC_WRITE, 2, newline, 1);
	syscall(SC_EXIT, 1);
}

/***********************************************************************/
/* String routines */
/***********************************************************************/

void memset(char* buffer, int value, int length) {
	char* ptr = buffer;
	while (length > 0) {
		*ptr = value;
		ptr = ptr + 1;
		length = length - 1;
	}
}

void strlen(char* string) {
	char* ptr = string;
	int length = 0;
	while (*ptr != 0) {
		ptr = ptr + 1;
		length = length + 1;
	}
	return length;
}

/***********************************************************************/
/* Syscall routines */
/***********************************************************************/

int open(char* filename, int mode) {
	int handle;
	if (mode == OPEN_READ) {
		handle = syscall(SC_OPEN, filename, O_RDONLY);
	} else {
		handle = syscall(SC_OPEN, filename, O_RDWR | O_TRUNC | O_CREAT);
	}

	if ((handle + 1) == 0) {
		fatal("Failed to open file");
	}

	return handle;
}

char* getargv(int index) {
	/* Returns a buffer that is still technically on the stack but it'll work alright */
	int* buffer = alloca(0x1000);
	syscall(SC_GETARGV, buffer, 0x1000);
	char* s = buffer[index + 1];
	return s;
}

/***********************************************************************/
/* Main */
/***********************************************************************/

int main() {
	if (getargv(1) == 0 || getargv(2) == 0) {
		error("Usage: bootstrap5 [input] [output]");
	}

	input_handle = open(getargv(1), OPEN_READ);
	output_handle = open(getargv(2), OPEN_WRITE);
}
