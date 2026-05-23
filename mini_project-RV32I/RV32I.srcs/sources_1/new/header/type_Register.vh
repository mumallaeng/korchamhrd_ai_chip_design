        // R-type (Register)
        instr_rom[0]  = 32'h0031_02b3;  // add  x5,  x2,  x3
        instr_rom[1]  = 32'h4031_02b3;  // sub  x5,  x2,  x3
        instr_rom[2]  = 32'h0031_72b3;  // and  x5,  x2,  x3
        instr_rom[3]  = 32'h0031_62b3;  // or   x5,  x2,  x3
        instr_rom[4]  = 32'h0031_42b3;  // xor  x5,  x2,  x3
        instr_rom[5]  = 32'h0031_12b3;  // sll  x5,  x2,  x3
        instr_rom[6]  = 32'h00b5_52b3;  // srl  x5,  x10, x11
        instr_rom[7]  = 32'h40b5_52b3;  // sra  x5,  x10, x11
        instr_rom[8]  = 32'h00b5_22b3;  // slt  x5,  x10, x11
        instr_rom[9]  = 32'h00b5_32b3;  // sltu x5,  x10, x11
        instr_rom[20] = 32'h0020_81b3;  // add  x3,  x1,  x2
