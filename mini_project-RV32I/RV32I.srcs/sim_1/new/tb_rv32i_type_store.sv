`timescale 1ns / 1ps
`include "../../sources_1/new/header/define.vh"

module tb_rv32i_type_store;
    logic clk, rst;
    `include "tb_rv32i_constants.vh"

    localparam int unsigned SIM_MODE = `SIM_MODE_TYPE_STORE;
    localparam int TEST_COUNT = 3;

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
        test_name[0] = "SW x12, 0(x13)";
        test_name[1] = "SH x12, 0(x13)";
        test_name[2] = "SB x12, 0(x13)";

        for (i = 0; i < TEST_COUNT; i = i + 1) begin
            seen[i] = 0;
        end
        error_count = 0;

        apply_reset();
        preload_store_type_state(TB_PC_TYPE_STORE);
        #1 prev_instr = dut.instr_code;

        repeat (20) @(posedge clk);

        for (i = 0; i < TEST_COUNT; i = i + 1) begin
            if (!seen[i]) begin
                $display("[FAIL] %s was not observed", test_name[i]);
                error_count++;
            end
        end

        if (error_count == 0) begin
            $display("[PASS] tb_rv32i_type_store completed successfully.");
        end else begin
            $fatal(1, "tb_rv32i_type_store failed with %0d error(s)", error_count);
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
            endcase
            prev_instr = dut.instr_code;
        end
    end
endmodule
