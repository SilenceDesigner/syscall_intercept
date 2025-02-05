/*
 * Copyright 2016-2020, Intel Corporation
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

#include <assert.h>
#include <string.h>
#include "../../disasm_wrapper.h"

#include "../../capstone_wrapper.h"

struct intercept_disasm_context {
	csh handle;
	cs_insn *insn;
	const unsigned char *begin;
	const unsigned char *end;
};

/*
 * intercept_disasm_next_instruction - Examines a single instruction
 * in a text section. This is only a wrapper around capstone specific code,
 * collecting data that can be used later to make decisions about patching.
 */
struct intercept_disasm_result
intercept_disasm_next_instruction(struct intercept_disasm_context *context,
					const unsigned char *code)
{
	struct intercept_disasm_result result = {.address = code, 0, };
	const unsigned char *start = code;
	size_t size = (size_t)(context->end - code + 1);
	uint64_t address = (uint64_t)code;

	if (!cs_disasm_iter(context->handle, &start, &size,
	    &address, context->insn)) {
		return result;
	}

	result.length = context->insn->size;

	assert(result.length != 0);

	result.is_syscall = (context->insn->id == RISCV_INS_ECALL);
#ifndef NDEBUG
	result.mnemonic = context->insn->mnemonic;
#endif

	switch (context->insn->id) {
    	/* PC-relative jumps */
		case RISCV_INS_BEQ:
		case RISCV_INS_BGE:
		case RISCV_INS_BGEU:
		case RISCV_INS_BLT:
		case RISCV_INS_BLTU:
		case RISCV_INS_BNE:
		case RISCV_INS_JAL:
		case RISCV_INS_C_J:
		case RISCV_INS_C_JAL:
		case RISCV_INS_C_BEQZ:
		case RISCV_INS_C_BNEZ:
			result.has_ip_relative_opr = true;
			result.is_jump = true;
			break;
		case RISCV_INS_AUIPC:
			result.has_ip_relative_opr = true;
			break;
		case RISCV_INS_JALR:
        case RISCV_INS_C_JR:
		case RISCV_INS_C_JALR:
        case RISCV_INS_MRET:
		case RISCV_INS_SRET:
		case RISCV_INS_URET:
			result.is_jump = true;
			break;
		default:
			result.is_jump = false;
			result.has_ip_relative_opr = false;
//			result.uses_ra = false;
			cs_riscv_op *op;
			result.uses_t6 = false;
			for (uint8_t op_i = 0; !result.uses_t6 &&
					 op_i < context->insn->detail->riscv.op_count; ++op_i) {
				op = context->insn->detail->riscv.operands + op_i;
				switch (op->type) {
					case RISCV_OP_REG:
						result.uses_t6 = op->reg == RISCV_REG_T6;
						break;
					case RISCV_OP_MEM:
						result.uses_t6 = op->mem.base == RISCV_REG_T6;
						break;
					default:
						break;
				}
			}
			break;
	}

	result.is_set = true;

	return result;
}
