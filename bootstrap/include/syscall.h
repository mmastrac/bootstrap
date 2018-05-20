// int open(char* file, int mode)
#define SC_OPEN 0

#define O_RDONLY 0
#define O_WRONLY 1
#define O_RDWR 2

#define O_CREAT 0x200
#define O_TRUNC 0x400

// int read(int fd, void* buffer, int length)
#define SC_READ 1
// int write(int fd, void* buffer, int length)
#define SC_WRITE 2
// int seek(int fd, int offset, int whence)
#define SC_SEEK 3

#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

// int close(int fd)
#define SC_CLOSE 4
// int getargv(void* buffer, int size)
#define SC_GETARGV 5
// int getmemsize()
#define SC_GETMEMSIZE 6
// void exit(int code)
#define SC_EXIT 7
