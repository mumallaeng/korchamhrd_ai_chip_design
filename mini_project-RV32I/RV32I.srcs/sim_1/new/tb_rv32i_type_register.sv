`timescale 1ns / 1ps
`include "../../sources_1/new/header/define.vh"

module tb_rv32i_type_register;
    logic clk, rst;
    `include "tb_rv32i_constants.vh"

    localparam int unsigned SIM_MODE = `SIM_MODE_TYPE_REGISTER;
    localparam int TEST_COUNT = 10;

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
        test_name[0] = "ADD x5, x2, x3";
        test_name[1] = "SUB x5, x2, x3";
        test_name[2] = "AND x5, x2, x3";
        test_name[3] = "OR x5, x2, x3";
        test_name[4] = "XOR x5, x2, x3";
        test_name[5] = "SLL x5, x2, x3";
        test_name[6] = "SRL x5, x10, x11";
        test_name[7] = "SRA x5, x10, x11";
        test_name[8] = "SLT x5, x10, x11";
        test_name[9] = "SLTU x5, x10, x11";

        for (i = 0; i < TEST_COUNT; i = i + 1) begin
            seen[i] = 0;
        end
        error_count = 0;

        apply_reset();
        preload_register_type_state(TB_PC_TYPE_REGISTER);
        #1 prev_instr = dut.instr_code;

        repeat (30) @(posedge clk);

        for (i = 0; i < TEST_COUNT; i = i + 1) begin
            if (!seen[i]) begin
                $display("[FAIL] %s was not observed", test_name[i]);
                error_count++;
            end
        end

        if (error_count == 0) begin
            $display("[PASS] tb_rv32i_type_register completed successfully.");
        end else begin
            $fatal(1, "tb_rv32i_type_register failed with %0d error(s)", error_count);
        end
        $finish;
    end

    always @(posedge clk) begin
        if (!rst) begin
            #1;
            case (prev_instr)
                32'h0031_02b3: if (!seen[0]) begin
                    seen[0] = 1;
                    expect_eq32("ADD x5, x2, x3", reg_word(TB_X5), 32'h0000_0005);
                end
                32'h4031_02b3: if (!seen[1]) begin
                    seen[1] = 1;
                    expect_eq32("SUB x5, x2, x3", reg_word(TB_X5), 32'hffff_ffff);
                end
                32'h0031_72b3: if (!seen[2]) begin
                    seen[2] = 1;
                    expect_eq32("AND x5, x2, x3", reg_word(TB_X5), 32'h0000_0002);
                end
                32'h0031_62b3: if (!seen[3]) begin
                    seen[3] = 1;
                    expect_eq32("OR x5, x2, x3", reg_word(TB_X5), 32'h0000_0003);
                end
                32'h0031_42b3: if (!seen[4]) begin
                    seen[4] = 1;
                    expect_eq32("XOR x5, x2, x3", reg_word(TB_X5), 32'h0000_0001);
                end
                32'h0031_12b3: if (!seen[5]) begin
                    seen[5] = 1;
                    expect_eq32("SLL x5, x2, x3", reg_word(TB_X5), 32'h0000_0010);
                end
                32'h00b5_52b3: if (!seen[6]) begin
                    seen[6] = 1;
                    expect_eq32("SRL x5, x10, x11", reg_word(TB_X5), 32'h7fff_ffff);
                end
                32'h40b5_52b3: if (!seen[7]) begin
                    seen[7] = 1;
                    expect_eq32("SRA x5, x10, x11", reg_word(TB_X5), 32'hffff_ffff);
                end
                32'h00b5_22b3: if (!seen[8]) begin
                    seen[8] = 1;
                    expect_eq32("SLT x5, x10, x11", reg_word(TB_X5), 32'h0000_0001);
                end
                32'h00b5_32b3: if (!seen[9]) begin
                    seen[9] = 1;
                    expect_eq32("SLTU x5, x10, x11", reg_word(TB_X5), 32'h0000_0000);
                end
            endcase
            prev_instr = dut.instr_code;
        end
    end
endmodule
