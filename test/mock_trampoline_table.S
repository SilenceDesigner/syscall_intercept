#
# Copyright 2017, Intel Corporation
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#
#     * Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#
# mock_trampoline_table.S
#
#  This is used as trampoline table in all asm_pattern tests. During
# patching, some memory is allocated close (in 2GB range) to the
# text segment being patched. The address where this memory is allocated
# can not be predicted, therefore instead of allocating memory, the test
# libraries have their own space for trampoline table.
#  Using this method, it is very easy to predict the destination of jump
# instructions in a patched text segment, as this mock trampoline table
# is always at the same distance from the syscall instructions being patched.
#  In an actual trampoline table, each syscall has an entry assigned, which
# only contains another trampoline jump (to a 64 bit address). This mock
# trampoline table has the same format, each mock entry has the same size as
# as such a trampoline jump would have. Since these patched syscalls are
# never executed in these low level tests, these jumps don't need to be
# real functioning jumps, thus their destination is ".space 8, 0" in all
# cases -- the only thing that matters, is to have these at predictable
# addresses.

.globl trampoline_table;
.globl trampoline_table_end;

.data

trampoline_table:
dst0:
	addi sp, sp, -16
	sd t1, 0(sp)
	sd t2, 8(sp)
	sd t3, 16(sp)
	.space 20, 0
	lui t1, 0x7ffff
	ori t2, zero, 0x7ff
	slli t2, t2, 1
	ori t2, t2, 1
	or t1, t1, t2
	slli t1, t1, 1
	ori t1, t1, 1
	and t3, t3, t1
	or t0, t0, t3
	ld t1, 0(sp)
	ld t2, 8(sp)
	ld t3, 16(sp)
	addi sp, sp, 16
	jalr zero, t0, 0

trampoline_table_end:
