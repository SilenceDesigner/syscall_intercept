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

//int main() {
//    int fd = openat(AT_FDCWD,"non_existing_original_file.txt", O_RDONLY);
//    if (fd >= 0) {
//        write(1, "Success: File opened\n", 21);
//    } else {
//        write(1, "Specified file doesn't exist - Test is ok if previous line is:\n"
//                 "\"Proof of openat interception\"\n", 25);
//    }
//}
