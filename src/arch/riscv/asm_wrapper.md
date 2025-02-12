# RISC-V porting problems and solutions #

### Nop-trampoline heuristic ###

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
which are just highly unlikely to find (2 more bytes would be needed for a
`c.j` avoiding the nop trampoline on a sequential execution). For example, an
objdump of the glibc v2.39 RISC-V binary shows only 155 `nop` and `c.nop`
instructions in the entire library, while the same command executed on the
x86_64 reports more than 16k occurrences.

### Support register ###

As said above, the `auipc` and `jalr` sequence needs one support register
because the `auipc` writes the higher 20-bit of the destination address into a
register while the `jalr` adds a 12-bit signed offset to the value saved in
that register and perform an absolute jump to the obtained result address.
`jalr` is able of writing the return address into `$ra` but `ecall` is not
concerned by user-space calling conventions. For that reason saving the return
address in `$ra` with `jalr` would cause disruptive behaviour in leaf procedures.
The following function is an example from glibc v2.35 binary:

```asm
00000000000a9f1a <fstatfs>:
   a9f1a:	addi	a7,zero,44
   a9f1e:	ecall
   a9f22:	c.lui	a5,0xfffff
   a9f24:	bltu	a5,a0,a9f2c <fstatfs+0x12>
   a9f28:	c.addiw a0,0
   a9f2a:	c.jr	ra
   a9f2c:	auipc	a5,0x7c
   a9f30:	ld	a5,1732(a5) # 1265f0 <_GLOBAL_OFFSET_TABLE_+0x60>
   a9f34:	subw	a4,zero,a0
   a9f38:	c.li	a0,-1
   a9f3a:	c.add	a5,tp
   a9f3c:	c.sw	a4,0(a5)
   a9f3e:	c.jr	ra
```
As showed in the function, `$ra` is used as source register in both occurrences
of `c.jr` without being restored from stack. Patching the ecall with a `jalr`
writing to `$ra` would at least cause an infinite loop when returning from
`fstatfs`. Solving this problem would require 8 additional bytes adjacent to
the patch: 4 compressed instructions would be able to (i) decrement the stack
pointer (ii) store `$ra` on the stack (iii) loading it back from the stack and
(iv) restoring the stack pointer. Our first porting attempt tried to find 16
over-writable bytes, resulting in failing the patching of the majority of
occurrences of `ecall` since such an amount of suitable bytes is very unlikely
to be found.

For these reasons, `$t6` was empirically chosen as the destination register for
`auipc` and as the source register for `jalr`. By not saving its value on the
stack we chose to clobber it, deliberately not respecting calling conventions.
However, this choice never caused any problems with the tested glibc versions.
That said, nothing prevents us from developing a more careful approach by
determining a suitable register to be "sacrificed" for this purpose by parsing
the `ecall` following instructions until the end of the function. Still, this
solution does not set us free from the assumption that at least a register is
suitable to be clobbered.

### Building an absolute jump ###

Each trampoline and each jump returning to the original shared object after the
interception template require an instructions sequence in hand-coded machine
language. This means we can't use any comfort provided by assembly programming,
such as pseudo-instructions or labels. Similarly to `auipc`+`jalr`, we can
write a 32-bit constant into a register with the `lui`+`addi` sequence, which
handles the most significant 20 bit with the first instruction and the least
significant 12 with the latter. Difficulties originate from 32-bit addresses
being impossible to just be split into a 20-bit upper immediate for auipc and a
12-bit lower offset for `jalr`, as both instructions accept signed immediate
values: the `auipc` instruction stores a multiple of 4096 into its destination
register, and `jalr` sums an immediate offset in the range [−2048, 2046]. To
solve this inconsistency, each destination address whose remainder, divided by
4096, is 2048 or more will result in auipc encoding the next higher multiple of
4096 so that `jalr` can compute the correct destination using a negative offset.
A 64-bit constant is even more complex since it relies on building the two
halves of the constant while making sure the lower half is not sign extended.
This requires using a mask whose construction must deals with sign extension
itself. With this caution, building the 64-bit constant is in the end possible
by just logical ORing the upper half and the lower half.
The following lines constitute a typical machine language trampoline
wrote as a sequence of assembly instructions:
```asm
addi    sp, sp, -32
sd      t1, 0(sp)
sd      t2, 8(sp)
sd      t3, 16(sp)
lui     t6, 0x12345 #placeholder value
addi    t6, t6, 0x678 #placeholder value
slli    t6, t6, 32
lui     t3, 0x90abcd #placeholder value
addi    t3, t3, 0xdef #placeholder value
lui     t1, 0x7ffff
ori     t2, zero, 0x7ff
slli    t2, t2, 1
ori     t2, t2, 1
or      t1, t1, t2
slli    t1, t1, 1
ori     t1, t1, 1
and     t3, t3, t1
or      t6, t6, t3
ld      t1, 0(sp)
ld      t2, 8(sp)
ld      t3, 16(sp)
addi    sp, sp, 32
jalr    zero, t6, 0
```
`$t6` keeps being used as the source register for the jump destination since
it's already clobbered, while `$t1`, `$t2` and `$t3`are preserved.
The same 64-bit constant building sequence is appended to each occurrence of the
interception template to be able to return to the patched shared object without
using `$ra`.