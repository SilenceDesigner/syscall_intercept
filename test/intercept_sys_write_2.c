#include "libsyscall_intercept_hook_point.h"
#include <stddef.h>
#include <syscall.h>
#include <string.h>
#include <unistd.h>  // Include for the write function
#include <stdio.h>

static int
hook(long syscall_number,
     long arg0, long arg1,
     long arg2, long arg3,
     long arg4, long arg5,
     long *result)
{
    (void)arg0;
    (void)arg2;
    (void)arg3;
    (void)arg4;
    (void)arg5;
    (void)result;

    if (syscall_number == SYS_write) {
        const char interc[] = "intercepted_";
        const char *src = interc;

        /* write(fd, buf, len) */
        size_t len = (size_t)arg2;
        char *buf = (char *)arg1;

#ifdef EXPECT_SPURIOUS_SYSCALLS
        if (strcmp(buf, "original_syscall") != 0)
            return 1;
#endif

        if (len > sizeof(interc)) {
            while (*src != '\0')
                *buf++ = *src++;
        }
    }

    return 1;
}

static __attribute__((constructor)) void
init(void)
{
    intercept_hook_point = hook;
}

int main() {
    char buf[128] = "original_syscall";
    write(1, buf, strlen(buf));
    printf("\n");
    return 0;
}
