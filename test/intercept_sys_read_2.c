#include "libsyscall_intercept_hook_point.h"
#include <stddef.h>
#include <syscall.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>


static int hook(long syscall_number,
                long arg0, long arg1,
                long arg2, long arg3,
                long arg4, long arg5,
                long *result)
{
    (void)arg3;
    (void)arg4;
    (void)arg5;
    (void)result;

    if (syscall_number == SYS_read) {
        char *buf = (char *)arg1;
        size_t len = (size_t)arg2;
        const char interc[] = "intercepted_read\n";
        const char *src = interc;

        if (len > sizeof(interc)) {
            *result = 0;
            while (*src != '\0')
                *buf++ = *src++;
            *result += 1;
        }
        return 0;
    }
    return 1;
}

static __attribute__((constructor)) void init(void)
{
    intercept_hook_point = hook;
}

int main() {
    char buf[128];
    read(0, buf, sizeof(buf));
    write(1, buf, strlen(buf));  // Should print "intercepted_read"
}