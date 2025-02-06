#include "libsyscall_intercept_hook_point.h"
#include <stddef.h>
#include <syscall.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>


static int hook(long syscall_number,
                long arg0, long arg1,
                long arg2, long arg3,
                long arg4, long arg5,
                long *result)
{
    if (syscall_number == SYS_openat) {
  	    write(1,"Proof of openat interception\n",29);
    }
    return 1;
}

static __attribute__((constructor)) void init(void)
{
    intercept_hook_point = hook;
}
