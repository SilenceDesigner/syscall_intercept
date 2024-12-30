#include <unistd.h>
#include <fcntl.h>
#include <string.h>

int main() {
    int fd = openat(AT_FDCWD,"non_existing_original_file.txt", O_RDONLY);
    char buf[128] = "Specified file doesn't exist - Test is ok if previous line is:\n"
                     "\"Proof of openat interception\"\n";
    if (fd >= 0) {
        write(1, "Success: File opened\n", 21);
    } else {
        write(1, buf, strlen(buf));
    }
}