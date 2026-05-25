`timescale 1ns / 1ps
`include "../../sources_1/new/header/define.vh"

module tb_rv32i_type_immediate;
    logic clk, rst;
    `include "tb_rv32i_constants.vh"

    localparam int unsigned SIM_MODE = `SIM_MODE_TYPE_IMMEDIATE;
    localparam int TEST_COUNT = 15;

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
        test_name[0]  = "ADDI x5, x2, 4";
        test_name[1]  = "ANDI x5, x3, 2";
        test_name[2]  = "ORI x5, x2, 1";
        test_name[3]  = "XORI x5, x2, 7";
        test_name[4]  = "SLLI x5, x2, 3";
        test_name[5]  = "SRLI x5, x10, 1";
        test_name[6]  = "SRAI x5, x10, 1";
        test_name[7]  = "SLTI x5, x2, 4";
        test_name[8]  = "SLTIU x5, x2, 1";
        test_name[9]  = "LB x5, 0(x14)";
        test_name[10] = "LBU x5, 0(x14)";
        test_name[11] = "LW x5, 0(x13)";
        test_name[12] = "LH x5, 0(x15)";
        test_name[13] = "LHU x5, 0(x15)";
        test_name[14] = "JALR x1, 0(x20)";

        for (i = 0; i < TEST_COUNT; i = i + 1) begin
            seen[i] = 0;
        end
        error_count = 0;
        prev_instr = 32'h0000_0013;

        apply_reset();
        preload_immediate_type_state(TB_PC_TYPE_IMMEDIATE);
        #1 prev_instr = dut.instr_code;

        repeat (40) @(posedge clk);

        for (i = 0; i < TEST_COUNT; i = i + 1) begin
            if (!seen[i]) begin
                $display("[FAIL] %s was not observed", test_name[i]);
                error_count++;
            end
        end

        if (error_count == 0) begin
            $display("[PASS] tb_rv32i_type_immediate completed successfully.");
        end else begin
            $fatal(1, "tb_rv32i_type_immediate failed with %0d error(s)", error_count);
        end
        $finish;
    end

    always @(posedge clk) begin
        if (!rst) begin
            #1;
            case (prev_instr)
                32'h0041_0293: if (!seen[0]) begin
                    seen[0] = 1;
                    expect_eq32("ADDI x5, x2, 4", reg_word(TB_X5), 32'h0000_0006);
                end
                32'h0021_f293: if (!seen[1]) begin
                    seen[1] = 1;
                    expect_eq32("ANDI x5, x3, 2", reg_word(TB_X5), 32'h0000_0002);
                end
                32'h0011_6293: if (!seen[2]) begin
                    seen[2] = 1;
                    expect_eq32("ORI x5, x2, 1", reg_word(TB_X5), 32'h0000_0003);
                end
                32'h0071_4293: if (!seen[3]) begin
                    seen[3] = 1;
                    expect_eq32("XORI x5, x2, 7", reg_word(TB_X5), 32'h0000_0005);
                end
                32'h0031_1293: if (!seen[4]) begin
                    seen[4] = 1;
                    expect_eq32("SLLI x5, x2, 3", reg_word(TB_X5), 32'h0000_0010);
                end
                32'h0015_5293: if (!seen[5]) begin
                    seen[5] = 1;
                    expect_eq32("SRLI x5, x10, 1", reg_word(TB_X5), 32'h7fff_ffff);
                end
                32'h4015_5293: if (!seen[6]) begin
                    seen[6] = 1;
                    expect_eq32("SRAI x5, x10, 1", reg_word(TB_X5), 32'hffff_ffff);
                end
                32'h0041_2293: if (!seen[7]) begin
                    seen[7] = 1;
                    expect_eq32("SLTI x5, x2, 4", reg_word(TB_X5), 32'h0000_0001);
                end
                32'h0011_3293: if (!seen[8]) begin
                    seen[8] = 1;
                    expect_eq32("SLTIU x5, x2, 1", reg_word(TB_X5), 32'h0000_0000);
                end
                32'h0007_0283: if (!seen[9]) begin
                    seen[9] = 1;
                    expect_eq32("LB x5, 0(x14)", reg_word(TB_X5), 32'hffff_ff80);
                end
                32'h0007_4283: if (!seen[10]) begin
                    seen[10] = 1;
                    expect_eq32("LBU x5, 0(x14)", reg_word(TB_X5), 32'h0000_0080);
                end
                32'h0006_a283: if (!seen[11]) begin
                    seen[11] = 1;
                    expect_eq32("LW x5, 0(x13)", reg_word(TB_X5), 32'h1234_5678);
                end
                32'h0007_9283: if (!seen[12]) begin
                    seen[12] = 1;
                    expect_eq32("LH x5, 0(x15)", reg_word(TB_X5), 32'hffff_ffff);
                end
                32'h0007_d283: if (!seen[13]) begin
                    seen[13] = 1;
                    expect_eq32("LHU x5, 0(x15)", reg_word(TB_X5), 32'h0000_ffff);
                end
                32'h000a_00e7: if (!seen[14]) begin
                    seen[14] = 1;
                    expect_eq32("JALR x1, 0(x20) link", reg_word(TB_X_RA), 32'h0000_003c);
                    expect_eq32("JALR x1, 0(x20) next PC", dut.instr_addr, 32'h0000_003c);
                end
            endcase
            prev_instr = dut.instr_code;
        end
    end
endmodule
