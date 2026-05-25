`timescale 1ns / 1ps
`include "../../sources_1/new/header/define.vh"

module tb_rv32i_type_store_branch_upper_jump;
    logic clk, rst;
    `include "tb_rv32i_constants.vh"

    localparam int unsigned SIM_MODE = `SIM_MODE_TYPE_STORE_BRANCH_UPPER_JUMP;
    localparam int TEST_COUNT = 12;

    bit seen[0:TEST_COUNT-1];
    string test_name[0:TEST_COUNT-1];
    int i;
    int error_count;
    logic [31:0] prev_instr;

    RV32I_SoC #(
        .SIM_MODE(SIM_MODE)
    ) dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;
    `include "tb_rv32i_tasks.vh"

    initial begin
        test_name[0]  = "SW x12, 0(x13)";
        test_name[1]  = "SH x12, 0(x13)";
        test_name[2]  = "SB x12, 0(x13)";
        test_name[3]  = "BEQ x3, x4, +8";
        test_name[4]  = "LUI x5, 0x12345";
        test_name[5]  = "AUIPC x5, 0x1";
        test_name[6]  = "JAL x1, +8";
        test_name[7]  = "BNE x5, x6, +8";
        test_name[8]  = "BLT x10, x11, +8";
        test_name[9]  = "BGE x11, x10, +8";
        test_name[10] = "BLTU x2, x3, +8";
        test_name[11] = "BGEU x3, x2, +8";

        for (i = 0; i < TEST_COUNT; i = i + 1) begin
            seen[i] = 0;
        end
        error_count = 0;
        prev_instr = 32'h0000_0013;

        apply_reset();
        preload_type_demo_state(TB_ADDR_JALR_TYPE_ALL);
        set_pc(TB_PC_TYPE_STORE_BRANCH_UJ);
        #1 prev_instr = dut.instr_code;

        repeat (80) @(posedge clk);

        for (i = 0; i < TEST_COUNT; i = i + 1) begin
            if (!seen[i]) begin
                $display("[FAIL] %s was not observed", test_name[i]);
                error_count++;
            end
        end

        if (error_count == 0) begin
            $display("[PASS] tb_rv32i_type_store_branch_upper_jump completed successfully.");
        end else begin
            $fatal(1, "tb_rv32i_type_store_branch_upper_jump failed with %0d error(s)", error_count);
        end
        $finish;
    end

    always @(posedge clk) begin
        if (!rst) begin
            #1;
            case (prev_instr)
                32'h00c6_a023: if (!seen[0]) begin
                    seen[0] = 1;
                    expect_eq32("SW x12, 0(x13)", ram_word(TB_RAM_WORD_ACCESS), 32'h1234_5678);
                end
                32'h00c6_9023: if (!seen[1]) begin
                    seen[1] = 1;
                    expect_eq32("SH x12, 0(x13)", ram_word(TB_RAM_WORD_ACCESS) & 32'h0000_ffff, 32'h0000_5678);
                end
                32'h00c6_8023: if (!seen[2]) begin
                    seen[2] = 1;
                    expect_eq32("SB x12, 0(x13)", ram_word(TB_RAM_WORD_ACCESS) & 32'h0000_00ff, 32'h0000_0078);
                end
                32'h0041_8463: if (!seen[3]) begin
                    seen[3] = 1;
                    expect_eq32("BEQ x3, x4, +8 next PC", dut.instr_addr, 32'h0000_0064);
                end
                32'h1234_52b7: if (!seen[4]) begin
                    seen[4] = 1;
                    expect_eq32("LUI x5, 0x12345", reg_word(TB_X5), 32'h1234_5000);
                end
                32'h0000_1297: if (!seen[5]) begin
                    seen[5] = 1;
                    expect_eq32("AUIPC x5, 0x1", reg_word(TB_X5), 32'h0000_1068);
                end
                32'h0080_00ef: if (!seen[6]) begin
                    seen[6] = 1;
                    expect_eq32("JAL x1, +8 link", reg_word(TB_X_RA), 32'h0000_0070);
                    expect_eq32("JAL x1, +8 next PC", dut.instr_addr, 32'h0000_0074);
                end
                32'h0062_9463: if (!seen[7]) begin
                    seen[7] = 1;
                    expect_eq32("BNE x5, x6, +8 next PC", dut.instr_addr, 32'h0000_00f4);
                end
                32'h00b5_4463: if (!seen[8]) begin
                    seen[8] = 1;
                    expect_eq32("BLT x10, x11, +8 next PC", dut.instr_addr, 32'h0000_00fc);
                end
                32'h00a5_d463: if (!seen[9]) begin
                    seen[9] = 1;
                    expect_eq32("BGE x11, x10, +8 next PC", dut.instr_addr, 32'h0000_0104);
                end
                32'h0031_6463: if (!seen[10]) begin
                    seen[10] = 1;
                    expect_eq32("BLTU x2, x3, +8 next PC", dut.instr_addr, 32'h0000_010c);
                end
                32'h0021_f463: if (!seen[11]) begin
                    seen[11] = 1;
                    expect_eq32("BGEU x3, x2, +8 next PC", dut.instr_addr, 32'h0000_0114);
                end
            endcase
            prev_instr = dut.instr_code;
        end
    end
endmodule
