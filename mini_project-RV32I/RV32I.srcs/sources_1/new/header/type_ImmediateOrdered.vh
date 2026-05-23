        // I-type (Immediate) dedicated image for the simple TB
        // Arithmetic immediate instructions
        instr_rom[0]  = 32'h0041_0293;  // addi  x5,  x2,  4
        instr_rom[1]  = 32'h0021_f293;  // andi  x5,  x3,  2
        instr_rom[2]  = 32'h0011_6293;  // ori   x5,  x2,  1
        instr_rom[3]  = 32'h0071_4293;  // xori  x5,  x2,  7
        instr_rom[4]  = 32'h0031_1293;  // slli  x5,  x2,  3
        instr_rom[5]  = 32'h0015_5293;  // srli  x5,  x10, 1
        instr_rom[6]  = 32'h4015_5293;  // srai  x5,  x10, 1
        instr_rom[7]  = 32'h0041_2293;  // slti  x5,  x2,  4
        instr_rom[8]  = 32'h0011_3293;  // sltiu x5,  x2,  1

        // Load instructions are also I-type in the ISA
        instr_rom[9]  = 32'h0007_0283;  // lb    x5,  0(x14)
        instr_rom[10] = 32'h0007_4283;  // lbu   x5,  0(x14)
        instr_rom[11] = 32'h0006_a283;  // lw    x5,  0(x13)
        instr_rom[12] = 32'h0007_9283;  // lh    x5,  0(x15)
        instr_rom[13] = 32'h0007_d283;  // lhu   x5,  0(x15)

        // Jump-register is also encoded as I-type
        instr_rom[14] = 32'h000a_00e7;  // jalr  x1,  x20, 0
