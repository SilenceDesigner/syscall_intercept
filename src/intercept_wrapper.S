#
# Copyright 2016-2024, Intel Corporation
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

 # intercept_wrapper.s -- see asm_wrapper.md

 # the function in this file
 .globl intercept_wrapper
 # .local intercept_wrapper # again, how to translate .hidden from x86_64?
 .type intercept_wrapper, @function

 # the C function in intercept.c
 .globl intercept_routine
 # .local intercept_routine
 .type intercept_routine, @function

 # the other C function in intercept.c, called right after cloning a thread
 .globl intercept_routine_post_clone
 # .local intercept_routine_post_clone
 .type intercept_routine_post_clone, @function

 .text

 intercept_wrapper:
   # Decreasing sp to allocate needed space to save caller-saved registers but
   # t5 and t6 which are already clobbered, original sp value around the ecall
   # and patch_desc pointer
   addi sp, sp, -288
   # Saving temporary and function arguments registers, which are both
   # caller-saved onto the stack
   sd ra, 0(sp)
   sd t0, 8(sp)
   sd t1, 16(sp)
   sd t2, 24(sp)
   sd t3, 32(sp)
   sd t4, 40(sp)

   # fetching original value of sp
   ld t6, 288(sp)
   sd t6, 48(sp)

   # fetching pointer to patch_desc
   ld t6, 296(sp)
   sd t6, 56(sp)

   sd a0, 64(sp)
   sd a1, 72(sp)
   sd a2, 80(sp)
   sd a3, 88(sp)
   sd a4, 96(sp)
   sd a5, 104(sp)
   sd a6, 112(sp)
   sd a7, 120(sp)
   sd ft0, 128(sp)
   sd ft1, 136(sp)
   sd ft2, 144(sp)
   sd ft3, 152(sp)
   sd ft4, 160(sp)
   sd ft5, 168(sp)
   sd ft6, 176(sp)
   sd ft7, 184(sp)
   sd ft8, 192(sp)
   sd ft9, 200(sp)
   sd ft10, 208(sp)
   sd ft11, 216(sp)
   sd fa0, 224(sp)
   sd fa1, 232(sp)
   sd fa2, 240(sp)
   sd fa3, 248(sp)
   sd fa4, 256(sp)
   sd fa5, 264(sp)
   sd fa6, 272(sp)
   sd fa7, 280(sp)

   # argument passed to intercept_routine
   mv a0, sp

   li t0, 1
   beq t5, t0, l0 # which function should be called?

   jal intercept_routine
   j l1
 l0:
   jal intercept_routine_post_clone
 l1:

   # At this point, the return value of the C
   # function (a struct wrapper_ret instance) is in a0, a1.
   #
   # This function doesn't use these values for anything, just
   # forwards them to the higher level wrapper function, generated
   # from the template.

   mv t6, a1

   # Restoring temporary and funcion arguments registers
   ld ra, 0(sp)
   ld t0, 8(sp)
   ld t1, 16(sp)
   ld t2, 24(sp)
   ld t3, 32(sp)
   ld t4, 40(sp)
   # no point in restoring in context values at 48(sp), 56(sp) and 64(sp)
   ld a1, 72(sp)
   ld a2, 80(sp)
   ld a3, 88(sp)
   ld a4, 96(sp)
   ld a5, 104(sp)
   ld a6, 112(sp)
   ld a7, 120(sp)
   ld ft0, 128(sp)
   ld ft1, 136(sp)
   ld ft2, 144(sp)
   ld ft3, 152(sp)
   ld ft4, 160(sp)
   ld ft5, 168(sp)
   ld ft6, 176(sp)
   ld ft7, 184(sp)
   ld ft8, 192(sp)
   ld ft9, 200(sp)
   ld ft10, 208(sp)
   ld ft11, 216(sp)
   ld fa0, 224(sp)
   ld fa1, 232(sp)
   ld fa2, 240(sp)
   ld fa3, 248(sp)
   ld fa4, 256(sp)
   ld fa5, 264(sp)
   ld fa6, 272(sp)
   ld fa7, 280(sp)
   # Increasing sp to its original value
   addi sp, sp, 288
   ret
