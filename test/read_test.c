#include <unistd.h>
#include <string.h>

int main() {
    char buf[128];
    read(0, buf, sizeof(buf));
    write(1, buf, strlen(buf));  // Should print "intercepted_read"
}