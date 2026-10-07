// Copyright 2026 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// tb_s1_decode_system : MISC-MEM and SYSTEM decode tests
//
// FENCE, FENCE.I, Zicbom/Zicboz, the privileged instructions and Zicsr.
//
// Included by verif/unit/tb_s1_decode.sv inside the testbench module; it uses
// that module's DUT outputs, encoders and scoreboard tasks.
// =============================================================================

  task automatic test_system();
    // ==========================================================================
    // MISC-MEM / SYSTEM -- 19 instructions: fence, fence.i, cbo.inval/clean/
    // flush/zero, ecall, ebreak, sret, mret, wfi, dret, sfence.vma,
    // csrrw/rs/rc, csrrwi/rsi/rci.
    // ==========================================================================

    cur_test = "fence"; named("fence");
    instr = enc_fence(4'b0000, 4'b1111, 4'b1111, 3'b000); #1;  // fence iorw, iorw
    expect_common(UNIT_NONE, 1'b0, 1'b0, 1'b0, 1'b0);
    check_field("sys_op", dec_mxif_on.sys_op, SYS_FENCE);

    cur_test = "fence.i"; named("fence.i");
    instr = enc_fence(4'b0000, 4'b0000, 4'b0000, 3'b001); #1;
    check_field("sys_op", dec_mxif_on.sys_op, SYS_FENCE_I);
    check_field("illegal", dec_mxif_on.illegal, 1'b0);

    cur_test = "cbo.inval"; named("cbo.inval");
    // riscv-opcodes rv_zicbo: "cbo.inval rs1 31..20=0 14..12=2 11..7=0 6..2=0x03".
    instr = {12'h000, 5'd10, 3'b010, 5'b0, OP_MISC_MEM}; #1;
    expect_common(UNIT_LSU, 1'b0, 1'b0, 1'b1, 1'b0);
    check_field("cbo_op", dec_mxif_on.cbo_op, CBO_INVAL);

    cur_test = "cbo.clean"; named("cbo.clean");
    instr = {12'h001, 5'd10, 3'b010, 5'b0, OP_MISC_MEM}; #1;
    check_field("cbo_op", dec_mxif_on.cbo_op, CBO_CLEAN);
    check_field("illegal", dec_mxif_on.illegal, 1'b0);

    cur_test = "cbo.flush"; named("cbo.flush");
    instr = {12'h002, 5'd10, 3'b010, 5'b0, OP_MISC_MEM}; #1;
    check_field("cbo_op", dec_mxif_on.cbo_op, CBO_FLUSH);
    check_field("illegal", dec_mxif_on.illegal, 1'b0);

    cur_test = "cbo.zero"; named("cbo.zero");
    instr = {12'h004, 5'd10, 3'b010, 5'b0, OP_MISC_MEM}; #1;
    check_field("cbo_op", dec_mxif_on.cbo_op, CBO_ZERO);
    check_field("illegal", dec_mxif_on.illegal, 1'b0);

    cur_test = "CBO/reserved-imm12";
    // imm12 values other than 0/1/2/4 under funct3=010 are reserved.
    instr = {12'h003, 5'd10, 3'b010, 5'b0, OP_MISC_MEM}; #1;
    expect_unrecognised();
    check_field("cbo_op", dec_mxif_on.cbo_op, CBO_NONE);

    cur_test = "CBO/reserved-rd-nonzero";
    // Unlike FENCE, rd IS fixed to 0 for CBO (riscv-opcodes rv_zicbo: "11..7=0").
    instr = {12'h000, 5'd10, 3'b010, 5'd3, OP_MISC_MEM}; #1;
    expect_unrecognised();

    cur_test = "MISCMEM/rs1-nonzero-ignored";
    // riscv-opcodes rv_i::fence: "fm pred succ rs1 14..12=0 rd 6..2=0x03 1..0=3"
    // -- rs1 and rd are named fields, not fixed to 0. They are reserved for
    // future finer-grain fences, and base implementations must ignore them
    // rather than raise illegal instruction.
    instr = {12'b0, 5'd7, 3'b000, 5'b0, OP_MISC_MEM}; #1;
    check_field("illegal", dec_mxif_on.illegal, 1'b0);
    check_field("sys_op", dec_mxif_on.sys_op, SYS_FENCE);

    cur_test = "MISCMEM/rd-nonzero-ignored";
    instr = {12'b0, 5'b0, 3'b000, 5'd7, OP_MISC_MEM}; #1;
    check_field("illegal", dec_mxif_on.illegal, 1'b0);
    check_field("sys_op", dec_mxif_on.sys_op, SYS_FENCE);

    cur_test = "ecall"; named("ecall");
    instr = enc_sys12(12'h000, 5'd0, 5'd0); #1;
    expect_common(UNIT_NONE, 1'b0, 1'b0, 1'b0, 1'b0);
    check_field("sys_op", dec_mxif_on.sys_op, SYS_ECALL);

    cur_test = "ebreak"; named("ebreak");
    instr = enc_sys12(12'h001, 5'd0, 5'd0); #1;
    check_field("sys_op", dec_mxif_on.sys_op, SYS_EBREAK);

    cur_test = "sret"; named("sret");
    instr = enc_sys12(12'h102, 5'd0, 5'd0); #1;
    check_field("sys_op", dec_mxif_on.sys_op, SYS_SRET);

    cur_test = "mret"; named("mret");
    instr = enc_sys12(12'h302, 5'd0, 5'd0); #1;
    check_field("sys_op", dec_mxif_on.sys_op, SYS_MRET);

    cur_test = "wfi"; named("wfi");
    instr = enc_sys12(12'h105, 5'd0, 5'd0); #1;
    check_field("sys_op", dec_mxif_on.sys_op, SYS_WFI);

    cur_test = "dret"; named("dret");
    // riscv-opcodes rv_sdext::dret: "11..7=0 19..15=0 31..20=0x7b2 14..12=0
    // 6..2=0x1C 1..0=3" -- needed for FR-8 (debug exit); legality (must be in
    // Debug Mode) is checked at retire, SPEC 13.
    instr = enc_sys12(12'h7b2, 5'd0, 5'd0); #1;
    check_field("sys_op", dec_mxif_on.sys_op, SYS_DRET);
    check_field("illegal", dec_mxif_on.illegal, 1'b0);

    cur_test = "DRET/reserved-rs1-nonzero";
    instr = enc_sys12(12'h7b2, 5'd9, 5'd0); #1;
    expect_unrecognised();

    cur_test = "SYSTEM/reserved-imm12";
    instr = enc_sys12(12'hABC, 5'd0, 5'd0); #1;
    expect_unrecognised();

    cur_test = "ECALL/reserved-rd-nonzero";
    // Gap: instr[31:20]==0x000 alone is not sufficient:
    // rs1 and rd must also be 0 (table: "rs1,rd=0"). rd=x5 here must be illegal.
    instr = enc_sys12(12'h000, 5'd0, 5'd5); #1;
    expect_unrecognised();
    check_field("sys_op", dec_mxif_on.sys_op, SYS_NONE);

    cur_test = "MRET/reserved-rs1-nonzero";
    instr = enc_sys12(12'h302, 5'd9, 5'd0); #1;
    expect_unrecognised();

    cur_test = "sfence.vma"; named("sfence.vma");
    // funct7=0001001, rs1=vaddr, rs2=asid, funct3=000, rd=0 (SPEC 10.1's Sv39
    // MMU: satp is writable from v1.0 even though translation is bypassed
    // until Phase 5, so this decode needs to exist now, not later).
    instr = enc_r(7'b0001001, 5'd6, 5'd5, 3'b000, 5'd0, OP_SYSTEM); #1;
    expect_common(UNIT_NONE, 1'b0, 1'b0, 1'b1, 1'b1);
    check_field("sys_op", dec_mxif_on.sys_op, SYS_SFENCE_VMA);

    cur_test = "sfence.vma/rs1=x0-rs2=x0-legal";
    // "sfence.vma x0, x0" (flush everything) is the common case -- rs1/rs2
    // being zero must NOT be confused with them being architecturally fixed.
    instr = enc_r(7'b0001001, 5'd0, 5'd0, 3'b000, 5'd0, OP_SYSTEM); #1;
    check_field("sys_op", dec_mxif_on.sys_op, SYS_SFENCE_VMA);
    check_field("illegal", dec_mxif_on.illegal, 1'b0);

    cur_test = "SFENCEVMA/reserved-rd-nonzero";
    instr = enc_r(7'b0001001, 5'd6, 5'd5, 3'b000, 5'd3, OP_SYSTEM); #1;
    expect_unrecognised();
    check_field("sys_op", dec_mxif_on.sys_op, SYS_NONE);

    cur_test = "csrrw"; named("csrrw");
    instr = {12'h305, 5'd7, 3'b001, 5'd8, OP_SYSTEM}; #1;  // csrrw x8, mtvec, x7
    expect_common(UNIT_CSR, 1'b0, 1'b1, 1'b1, 1'b0);
    check_field("csr_op", dec_mxif_on.csr_op, CSR_RW);
    check_field("csr_addr", dec_mxif_on.csr_addr, 12'h305);
    check_field("csr_imm", dec_mxif_on.csr_imm, 1'b0);

    cur_test = "csrrs"; named("csrrs");
    instr = {12'hC00, 5'd0, 3'b010, 5'd5, OP_SYSTEM}; #1;  // csrrs x5, cycle, x0 == "csrr x5, cycle"
    check_field("csr_op", dec_mxif_on.csr_op, CSR_RS);
    check_field("rs1_re", dec_mxif_on.rs1_re, 1'b1);  // still a register read, even though it's x0

    cur_test = "csrrc"; named("csrrc");
    instr = {12'h300, 5'd1, 3'b011, 5'd5, OP_SYSTEM}; #1;
    check_field("csr_op", dec_mxif_on.csr_op, CSR_RC);

    cur_test = "csrrwi"; named("csrrwi");
    instr = {12'h304, 5'd17, 3'b101, 5'd6, OP_SYSTEM}; #1;  // csrrwi x6, mie, 17
    expect_common(UNIT_CSR, 1'b0, 1'b1, 1'b0, 1'b0);   // rs1 field is uimm, not a register read
    check_field("csr_op", dec_mxif_on.csr_op, CSR_RW);
    check_field("csr_imm", dec_mxif_on.csr_imm, 1'b1);
    check_field("imm", dec_mxif_on.imm, XLEN'(17));

    cur_test = "csrrsi"; named("csrrsi");
    instr = {12'h304, 5'd1, 3'b110, 5'd6, OP_SYSTEM}; #1;
    check_field("csr_op", dec_mxif_on.csr_op, CSR_RS);
    check_field("csr_imm", dec_mxif_on.csr_imm, 1'b1);

    cur_test = "csrrci"; named("csrrci");
    instr = {12'h304, 5'd1, 3'b111, 5'd6, OP_SYSTEM}; #1;
    check_field("csr_op", dec_mxif_on.csr_op, CSR_RC);

    cur_test = "SYSTEM/reserved-funct3-100";
    instr = {12'h300, 5'd1, 3'b100, 5'd6, OP_SYSTEM}; #1;
    expect_unrecognised();
    check_field("csr_op", dec_mxif_on.csr_op, CSR_NONE);
  endtask
