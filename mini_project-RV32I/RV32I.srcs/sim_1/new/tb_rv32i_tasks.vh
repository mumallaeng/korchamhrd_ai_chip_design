function automatic logic [31:0] reg_word(input int unsigned index);
    return dut.U_RV32_CPU.U_DATAPATH.U_REG_FILE.cpu_reg[index];
endfunction

function automatic logic [31:0] ram_word(input int unsigned index);
    return dut.U_DATA_MEM.data_ram[index];
endfunction

task automatic set_reg(input int unsigned index, input logic [31:0] value);
    dut.U_RV32_CPU.U_DATAPATH.U_REG_FILE.cpu_reg[index] = value;
endtask

task automatic set_ram(input int unsigned index, input logic [31:0] value);
    dut.U_DATA_MEM.data_ram[index] = value;
endtask

task automatic set_pc(input logic [31:0] value);
    dut.U_RV32_CPU.U_DATAPATH.U_PC.pc_reg = value;
endtask

task automatic apply_reset;
    begin
        clk = 0;
        rst = 1;
        @(negedge clk);
        @(negedge clk);
        rst = 0;
    end
endtask

task automatic expect_eq32(
    input string label,
    input logic [31:0] got,
    input logic [31:0] expected
);
    begin
        if (got !== expected) begin
            $display("[FAIL] %s got=%08h expected=%08h", label, got, expected);
            error_count++;
        end else begin
            $display("[PASS] %s value=%08h", label, got);
        end
    end
endtask

task automatic clear_cpu_regs;
    int idx;
    begin
        for (idx = 0; idx < 32; idx = idx + 1) begin
            set_reg(idx, 32'h0000_0000);
        end
    end
endtask

task automatic clear_data_ram;
    int idx;
    begin
        for (idx = 0; idx < 256; idx = idx + 1) begin
            set_ram(idx, 32'h0000_0000);
        end
    end
endtask

task automatic preload_alu_operands;
    begin
        set_reg(TB_X2,  TB_VAL_SMALL_2);      // x2 = 2: ADD/SUB/SLL/SLTI base operand
        set_reg(TB_X3,  TB_VAL_SMALL_3);      // x3 = 3: second ALU operand and BEQ source
        set_reg(TB_X10, TB_VAL_SIGNED_NEG1);  // x10 = -1: signed compare and SRA sign-fill test
        set_reg(TB_X11, TB_VAL_SHIFT_ONE);    // x11 = 1: shift amount and signed compare partner
    end
endtask

task automatic preload_branch_operands;
    begin
        set_reg(TB_X2,  TB_VAL_SMALL_2);             // unsigned 2 for BLTU/BGEU
        set_reg(TB_X3,  TB_VAL_SMALL_3);             // BEQ left, unsigned 3 for BGEU
        set_reg(TB_X4,  TB_VAL_BRANCH_EQUAL);        // BEQ right, equal to x3
        set_reg(TB_X5,  TB_VAL_BNE_LEFT);            // BNE left, later compared with x6=9 in ROM tail
        set_reg(TB_X6,  TB_VAL_BNE_RIGHT_INITIAL);   // initial x6; ROM tail changes it to 9 before BNE
        set_reg(TB_X10, TB_VAL_SIGNED_NEG1);         // signed -1 for BLT/BGE
        set_reg(TB_X11, TB_VAL_SHIFT_ONE);           // signed +1 for BLT/BGE
    end
endtask

task automatic preload_load_store_operands;
    begin
        set_reg(TB_X12, TB_VAL_STORE_PATTERN);  // store source data for SW/SH/SB
        set_reg(TB_X13, TB_ADDR_DATA_WORD0);    // effective address 0x40 -> data_ram[16]
        set_reg(TB_X14, TB_ADDR_DATA_WORD1);    // effective address 0x44 -> data_ram[17]
        set_reg(TB_X15, TB_ADDR_DATA_WORD2);    // effective address 0x48 -> data_ram[18]

        set_ram(TB_RAM_WORD_ACCESS, TB_RAM_WORD_PATTERN);  // LW reads full 32-bit word
        set_ram(TB_RAM_BYTE_ACCESS, TB_RAM_BYTE_PATTERN);  // LB/LBU read byte 0x80
        set_ram(TB_RAM_HALF_ACCESS, TB_RAM_HALF_PATTERN);  // LH/LHU read halfword 0xffff
    end
endtask

task automatic preload_type_demo_state(input logic [31:0] jalr_target);
    begin
        clear_cpu_regs();
        clear_data_ram();

        set_reg(TB_X_ZERO, TB_VAL_ZERO);
        set_reg(TB_X_RA,   32'h0000_0005);  // non-zero seed makes link-register overwrite easy to see
        preload_alu_operands();
        preload_branch_operands();
        preload_load_store_operands();
        set_reg(TB_X20, jalr_target);
    end
endtask

task automatic preload_register_type_state(input logic [31:0] start_pc);
    begin
        clear_cpu_regs();
        preload_alu_operands();
        set_pc(start_pc);
    end
endtask

task automatic preload_immediate_type_state(input logic [31:0] start_pc);
    begin
        preload_type_demo_state(TB_ADDR_JALR_FOCUSED);
        set_pc(start_pc);
    end
endtask

task automatic preload_store_type_state(input logic [31:0] start_pc);
    begin
        clear_cpu_regs();
        clear_data_ram();
        preload_load_store_operands();
        set_pc(start_pc);
    end
endtask

task automatic preload_branch_type_state(input logic [31:0] start_pc);
    begin
        clear_cpu_regs();
        preload_branch_operands();
        set_pc(start_pc);
    end
endtask

task automatic preload_pc_only_state(input logic [31:0] start_pc);
    begin
        clear_cpu_regs();
        clear_data_ram();
        set_pc(start_pc);
    end
endtask
