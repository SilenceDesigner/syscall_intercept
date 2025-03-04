#define _GNU_SOURCE
#include "libsyscall_intercept_hook_point.h"
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sched.h> // For CLONE_* flags
#include <stdlib.h>

static int hook(long syscall_number,
                long arg0, long arg1,
                long arg2, long arg3,
                long arg4, long arg5,
                long *result)
{
    if (syscall_number == SYS_clone) {
        printf("[HOOK] clone intercepted! flags: 0x%lx\n", arg0);
    }
    return 1;
}

static void hook_clone_parent(long child_pid)
{
	printf("Executing parent hook: %d - Its child pid should be %lu\n",getpid(),child_pid);
}

static void hook_clone_child(void)
{
	printf("Executing child hook: %d\n", getpid());
}

static __attribute__((constructor)) void
init(void)
{
    intercept_hook_point = hook;
	intercept_hook_point_clone_child = hook_clone_child;
    intercept_hook_point_clone_parent = hook_clone_parent;
}
