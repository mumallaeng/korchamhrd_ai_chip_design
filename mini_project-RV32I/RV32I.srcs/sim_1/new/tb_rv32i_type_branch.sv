`timescale 1ns / 1ps
`include "../../sources_1/new/header/define.vh"

module tb_rv32i_type_branch;
    logic clk, rst;
    `include "tb_rv32i_constants.vh"

    localparam int unsigned SIM_MODE = `SIM_MODE_TYPE_BRANCH;
    localparam int TEST_COUNT = 6;

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
        test_name[0] = "BEQ x3, x4, +8";
        test_name[1] = "BNE x5, x6, +8";
        test_name[2] = "BLT x10, x11, +8";
        test_name[3] = "BGE x11, x10, +8";
        test_name[4] = "BLTU x2, x3, +8";
        test_name[5] = "BGEU x3, x2, +8";

        for (i = 0; i < TEST_COUNT; i = i + 1) begin
            seen[i] = 0;
        end
        error_count = 0;
        prev_instr = 32'h0000_0013;

        apply_reset();
        preload_branch_type_state(TB_PC_TYPE_BRANCH);
        #1 prev_instr = dut.instr_code;

        repeat (50) @(posedge clk);

        for (i = 0; i < TEST_COUNT; i = i + 1) begin
            if (!seen[i]) begin
                $display("[FAIL] %s was not observed", test_name[i]);
                error_count++;
            end
        end

        if (error_count == 0) begin
            $display("[PASS] tb_rv32i_type_branch completed successfully.");
        end else begin
            $fatal(1, "tb_rv32i_type_branch failed with %0d error(s)", error_count);
        end
        $finish;
    end

    always @(posedge clk) begin
        if (!rst) begin
            #1;
            case (prev_instr)
                32'h0041_8463: if (!seen[0]) begin
                    seen[0] = 1;
                    expect_eq32("BEQ x3, x4, +8 next PC", dut.instr_addr, 32'h0000_0064);
                end
                32'h0062_9463: if (!seen[1]) begin
                    seen[1] = 1;
                    expect_eq32("BNE x5, x6, +8 next PC", dut.instr_addr, 32'h0000_00f4);
                end
                32'h00b5_4463: if (!seen[2]) begin
                    seen[2] = 1;
                    expect_eq32("BLT x10, x11, +8 next PC", dut.instr_addr, 32'h0000_00fc);
                end
                32'h00a5_d463: if (!seen[3]) begin
                    seen[3] = 1;
                    expect_eq32("BGE x11, x10, +8 next PC", dut.instr_addr, 32'h0000_0104);
                end
                32'h0031_6463: if (!seen[4]) begin
                    seen[4] = 1;
                    expect_eq32("BLTU x2, x3, +8 next PC", dut.instr_addr, 32'h0000_010c);
                end
                32'h0021_f463: if (!seen[5]) begin
                    seen[5] = 1;
                    expect_eq32("BGEU x3, x2, +8 next PC", dut.instr_addr, 32'h0000_0114);
                end
            endcase
            prev_instr = dut.instr_code;
        end
    end
endmodule
