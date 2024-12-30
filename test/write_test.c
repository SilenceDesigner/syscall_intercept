#include <unistd.h>
#include <string.h>

int main() {
    char buf[128] = "original_syscall\n";
    write(1, buf, strlen(buf));
}