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

 # intercept_template.s -- see asm_wrapper.md

 .globl intercept_asm_wrapper_tmpl
 # .local intercept_asm_wrapper_tmpl # x64 uses .hidden - how to port to RISC-V?
 .globl intercept_asm_wrapper_patch_desc_addr
 # .local intercept_asm_wrapper_patch_desc_addr
 .globl intercept_asm_wrapper_wrapper_level1_addr
 # .local intercept_asm_wrapper_wrapper_level1_addr
 .globl intercept_asm_wrapper_tmpl_end
 # .local intercept_asm_wrapper_tmpl_end

 .text

  # ld t0, 0(sp)
  # addi sp, sp, 16
  # preceding_ins_2
  # preceding_ins
 intercept_asm_wrapper_tmpl:
  li t5, 0 # choose intercept_routine
 l0:
  bnez t5, l3
  mv t6, sp # remember original sp
  j l4
 l3:
  ld t6, 0(sp) # we cloned, so save actual original sp
 l4:
  addi sp, sp, -32 # allocate stack for some locals
  sd t6, 0(sp) # original sp on stack
  sd ra, 16(sp) # patch->return_address on stack
  sd s0, 24(sp) # following conventions by saving s0 on stack since we use it
  bnez t5, intercept_asm_wrapper_patch_desc_addr
  li s0, 0 # s0 as flag: 1 if we are going for post_clone, 0 otherwise
 intercept_asm_wrapper_patch_desc_addr:
  # load patch_desc address in t0

  # the 5 following instructions are placeholders for the correct ones which are
  # overwritten in machine language by create_load_uint64t_into_t0()
  lui t0, 0x00000
  addi t0, t0, 0x000
  slli t0, t0, 32
  lui t3, 0x00000
  addi t3, t3, 0x000

  # the 9 following instructions load the 64-bit address in t0
  lui t1, 0x7ffff
  ori t2, zero, 0x7ff
  slli t2, t2, 1
  ori t2, t2, 1
  or t1, t1, t2
  slli t1, t1, 1
  ori t1, t1, 1
  and t3, t3, t1
  or t0, t0, t3

  sd t0, 8(sp) # patch_desc pointer on stack
 intercept_asm_wrapper_wrapper_level1_addr:
  # load intercept_wrapper address in t0

  # the 5 following instructions are placeholders for the correct ones which are
  # written in machine language in create_load_uint64t_into_t0() in patcher.c
  lui t0, 0x00000
  ori t0, t0, 0x000
  slli t0, t0, 32
  lui t3, 0x00000
  ori t3, t3, 0x000

  # the 9 following instructions load the 64-bit address in t0
  lui t1, 0x7ffff
  ori t2, zero, 0x7ff
  slli t2, t2, 1
  ori t2, t2, 1
  or t1, t1, t2
  slli t1, t1, 1
  ori t1, t1, 1
  and t3, t3, t1
  or t0, t0, t3

  # calling intercept_wrapper
  jalr ra, t0, 0


  # The intercept_wrapper function did restore all registers to their
  # original state, except for a0, sp and t6.
  #
  # If t6 is zero, rax contains a syscall number, and that syscall
  # is executed here.
  # If t6 is 1, rax contains the return value of the hooked syscall.
  # If t6 is 2, a clone syscall is executed here.

  beqz t6, l2
  li t0, 1
  beq t6, t0, restore_sp
  li t0, 2
  beq t6, t0, l1

  li a7, 94 # exit_group if t6 contains an invalid value, namely different from
  ecall 		# 0, 1 or 2

 l1:
  mv a7, a0
  ecall
  li t5, 1 # choose intercept_routine_post_clone
  li s0, 1 # flag to signal we cloned, restoring sp will require adding 64
  j l0
 l2:
  mv a7, a0
  ecall
 restore_sp:
  beqz s0, l5
  addi sp, sp, 32
 l5:
  ld ra, 16(sp)
  ld s0, 24(sp)
  addi sp, sp, 32

 intercept_asm_wrapper_tmpl_end:
 	# This template must be appended here with a
 	# jump back to the intercepted code.

 	# following_ins # !can't use ra as operand! need to check after disassembly
 	# jalr zero, ra, 0
