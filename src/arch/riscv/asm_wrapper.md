# RISC-V porting problems and solutions #

### Nop-trampoline heuristic

As in the x86_64 version of the library, the patching process aims at
overwriting the `ecall` instruction with a PC-relative jump reaching the
trampoline table allocated within the ±2GiB range, where an absolute jump will
transfer the execution to the interposition code anywhere in the 64-bit address
space. We surely dispose of the 4 byte occupied by the `ecall` instruction,
which would be enough for a `jal` instruction, which is capable of performing
just a PC-relative jump in the ±1MiB range, which is insufficient. Therefore, at
least eight adjacent bytes and a support register are required in order to
invoke a 32-bit relative jump with the `auipc` and `jalr` instructions. While
the original version would try to found an at least 7-bytes long `nop`, the
RISC-V version would require at least 10 bytes of consecutive `nop` or `c.nop`
which are just highly unlikely to find. For example, an objdump of the glibc
v2.39 RISC-V binary shows only 155 `nop` and `c.nop` instructions in the entire
library, while the same command executed on the x86_64 reports more than 16k
occurrences.
