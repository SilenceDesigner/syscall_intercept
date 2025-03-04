/*
 * Copyright 2025, University of Turin
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in
 *       the documentation and/or other materials provided with the
 *       distribution.
 *
 *     * Neither the name of the copyright holder nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * The following test assumes 4096 bytes as the smallest page size. It
 * therefore makes sense on those architectures compliant with that
 * assumption, as both amd64 and riscv64 are. Following that assumption,
 * a brk(0) would result in an increase of the program break by 4096 bytes
 */

#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <assert.h>
#include <stdlib.h>

int main() {
    void *old_brk = sbrk(0); // Get current program break
    int fd = openat(AT_FDCWD, "../testfile.txt", O_RDWR | O_CREAT | O_TRUNC, 0666);
    printf("Old brk: %p\n", old_brk);

    void *new_brk = old_brk + 8192; // Allocate two pages
    dprintf(fd, "%p\n", new_brk);

    if (brk(new_brk) != 0) {
        perror("brk failed");
        return 1;
    }
    char buf[128];
    lseek(fd, 0, SEEK_SET);
    int n = read(fd, &buf, sizeof(buf));
    buf[n] = '\0';
    n = atoi(buf);
//    assert();
    printf("New brk: %p\n", sbrk(0));
}
