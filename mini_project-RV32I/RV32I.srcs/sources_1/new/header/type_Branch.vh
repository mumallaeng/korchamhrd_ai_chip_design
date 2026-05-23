        // B-type (Branch)
        instr_rom[23] = 32'h0041_8463;  // beq  x3,  x4,  +8

        // TYPE_ALL coverage tail for remaining branch instructions
        instr_rom[54] = 32'h0080_0293;  // addi  x5,  x0, 8
        instr_rom[55] = 32'h0080_0313;  // addi  x6,  x0, 8
        instr_rom[56] = 32'h0062_8463;  // beq   x5,  x6,  +8
        instr_rom[57] = 32'h0000_0013;  // nop   (skipped when BEQ is taken)
        instr_rom[58] = 32'h0090_0313;  // addi  x6,  x0, 9
        instr_rom[59] = 32'h0062_9463;  // bne   x5,  x6,  +8
        instr_rom[60] = 32'h0000_0013;  // nop   (skipped when BNE is taken)
        instr_rom[61] = 32'h00b5_4463;  // blt   x10, x11, +8
        instr_rom[62] = 32'h0000_0013;  // nop   (skipped when BLT is taken)
        instr_rom[63] = 32'h00a5_d463;  // bge   x11, x10, +8
        instr_rom[64] = 32'h0000_0013;  // nop   (skipped when BGE is taken)
        instr_rom[65] = 32'h0031_6463;  // bltu  x2,  x3,  +8
        instr_rom[66] = 32'h0000_0013;  // nop   (skipped when BLTU is taken)
        instr_rom[67] = 32'h0021_f463;  // bgeu  x3,  x2,  +8
        instr_rom[68] = 32'h0000_0013;  // nop   (skipped when BGEU is taken)
