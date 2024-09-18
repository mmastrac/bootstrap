#include "syscall.h"
#include "regs.h"

# int open(char* file, int mode)
:_syscall_open
    mov @tmp0, @SC_OPEN
    sys @tmp0 r0 r1
    mov @ret, @tmp0
    ret

# int read(int fd, void* buffer, int length)
:_syscall_read
    mov @tmp0, @SC_READ
    sys @tmp0 r0 r1 r2
    mov @ret, @tmp0
    ret

# int write(int fd, void* buffer, int length)
:_syscall_write
    mov @tmp0, @SC_WRITE
    sys @tmp0 r0 r1 r2
    mov @ret, @tmp0
    ret

# int seek(int fd, int offset, int whence)
:_syscall_seek
    mov @tmp0, @SC_SEEK
    sys @tmp0 r0 r1 r2
    mov @ret, @tmp0
    ret

# int close(int fd)
:_syscall_close
    mov @tmp0, @SC_CLOSE
    sys @tmp0 r0
    mov @ret, @tmp0
    ret

# int getargv(void* buffer, int size)
:_syscall_getargv
    mov @tmp0, @SC_GETARGV
    sys @tmp0 r0 r1
    mov @ret, @tmp0
    ret

# int getmemsize()
:_syscall_getmemsize
    mov @tmp0, @SC_GETMEMSIZE
    sys @tmp0
    mov @ret, @tmp0
    ret

# void exit(int code)
:_syscall_exit
    mov @tmp0, @SC_EXIT
    sys @tmp0 r0
    mov @ret, @tmp0
    ret

# int openat(int dirfd, const char *pathname, int flags)
:_syscall_openat
    mov @tmp0, @SC_OPENAT
    sys @tmp0 r0 r1 r2
    mov @ret, @tmp0
    ret

:__program_end__
    dd :__END__
