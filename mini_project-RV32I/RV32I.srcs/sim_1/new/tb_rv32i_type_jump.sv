`timescale 1ns / 1ps
`include "../../sources_1/new/header/define.vh"

module tb_rv32i_type_jump;
    logic clk, rst;
    `include "tb_rv32i_constants.vh"

    localparam int unsigned SIM_MODE = `SIM_MODE_TYPE_JUMP;
    localparam int TEST_COUNT = 1;

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
        test_name[0] = "JAL x1, +8";
        seen[0] = 0;
        error_count = 0;
        prev_instr = 32'h0000_0013;

        apply_reset();
        preload_pc_only_state(TB_PC_TYPE_JUMP);
        #1 prev_instr = dut.instr_code;

        repeat (10) @(posedge clk);

        if (!seen[0]) begin
            $display("[FAIL] %s was not observed", test_name[0]);
            error_count++;
        end

        if (error_count == 0) begin
            $display("[PASS] tb_rv32i_type_jump completed successfully.");
        end else begin
            $fatal(1, "tb_rv32i_type_jump failed with %0d error(s)", error_count);
        end
        $finish;
    end

    always @(posedge clk) begin
        if (!rst) begin
            #1;
            case (prev_instr)
                32'h0080_00ef: if (!seen[0]) begin
                    seen[0] = 1;
                    expect_eq32("JAL x1, +8 link", reg_word(TB_X_RA), 32'h0000_0070);
                    expect_eq32("JAL x1, +8 next PC", dut.instr_addr, 32'h0000_0074);
                end
            endcase
            prev_instr = dut.instr_code;
        end
    end
endmodule
