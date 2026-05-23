        // I-type (Immediate)
        // Arithmetic immediate instructions
        instr_rom[18] = 32'h0041_0293;  // addi x5,  x2,  4
        instr_rom[19] = 32'h0030_0113;  // addi x2,  x0,  3
        instr_rom[24] = 32'h0630_0293;  // addi x5,  x0,  99
        instr_rom[28] = 32'h04d0_0493;  // addi x9,  x0,  77
        instr_rom[29] = 32'hf800_0293;  // addi x5,  x0,  -128
        instr_rom[30] = 32'h0440_0713;  // addi x14, x0,  68
        instr_rom[34] = 32'hfff0_0293;  // addi x5,  x0,  -1

        // I-type (Immediate)
        // Load instructions are also I-type in the ISA
        instr_rom[12] = 32'h0006_a283;  // lw   x5,  0(x13)
        instr_rom[22] = 32'h0000_2203;  // lw   x4,  0(x0)
        instr_rom[32] = 32'h0007_0283;  // lb   x5,  0(x14)
        instr_rom[33] = 32'h0007_4283;  // lbu  x5,  0(x14)
        instr_rom[36] = 32'h0007_9283;  // lh   x5,  0(x15)
        instr_rom[37] = 32'h0007_d283;  // lhu  x5,  0(x15)

        // I-type (Immediate)
        // JALR is also I-type, but this focused image leaves jump-register
        // behavior to the C-code execution scenario instead of a standalone slot.

        // Restore the base example operands before the I-type coverage tail.
        instr_rom[38] = 32'h0020_0113;  // addi  x2,  x0, 2
        instr_rom[39] = 32'h0030_0193;  // addi  x3,  x0, 3

        // TYPE_ALL coverage tail for I-type arithmetic, JALR, and branch setup
        instr_rom[40] = 32'h0041_2293;  // slti  x5,  x2,  4
        instr_rom[41] = 32'h0011_3293;  // sltiu x5,  x2,  1
        instr_rom[42] = 32'h0071_4293;  // xori  x5,  x2,  7
        instr_rom[43] = 32'h0011_6293;  // ori   x5,  x2,  1
        instr_rom[44] = 32'h0021_f293;  // andi  x5,  x3,  2
        instr_rom[45] = 32'h0031_1293;  // slli  x5,  x2,  3
        instr_rom[46] = 32'h0015_5293;  // srli  x5,  x10, 1
        instr_rom[47] = 32'h4015_5293;  // srai  x5,  x10, 1

        // Branch comparison source setup
        instr_rom[52] = 32'h0020_0113;  // addi  x2,  x0, 2
        instr_rom[53] = 32'h0030_0193;  // addi  x3,  x0, 3

        // JALR coverage
        instr_rom[72] = 32'h1400_0a13;  // addi  x20, x0, 320  (target = instr_rom[80])
        instr_rom[73] = 32'h000a_00e7;  // jalr  x1,  x20, 0
        instr_rom[74] = 32'h0630_0b13;  // addi  x22, x0, 99   (skipped by JALR)
        instr_rom[80] = 32'h0370_0b93;  // addi  x23, x0, 55   (JALR landing target)
