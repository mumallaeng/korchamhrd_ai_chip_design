`timescale 1ns / 1ps
`include "../../sources_1/new/header/define.vh"

`ifndef RV32I_TB_SIM_MODE
`define RV32I_TB_SIM_MODE RV32I_SIM_MC_CODE_BUBBLE_SORT
`endif

`ifndef RV32I_TB_SUM_COUNTING_MEM_FILE
`define RV32I_TB_SUM_COUNTING_MEM_FILE "sum_counting.mem"
`endif

`ifndef RV32I_TB_BUBBLE_SORT_MEM_FILE
`define RV32I_TB_BUBBLE_SORT_MEM_FILE "bubble_sort.mem"
`endif

`ifndef RV32I_TB_BUBBLE_SORT_BOUNDARY_BUG_MEM_FILE
`define RV32I_TB_BUBBLE_SORT_BOUNDARY_BUG_MEM_FILE "bubble_sort_boundary_bug.mem"
`endif

module tb_rv32i;
    logic clk;
    logic rst;

    localparam rv32i_sim_mode_t SIM_MODE = `RV32I_TB_SIM_MODE;
    localparam int unsigned RUN_CYCLES =
        (SIM_MODE == RV32I_SIM_MC_CODE_SUM_COUNTING) ? 350 :
        ((SIM_MODE == RV32I_SIM_MC_CODE_BUBBLE_SORT) ||
         (SIM_MODE == RV32I_SIM_MC_CODE_BUBBLE_SORT_BOUNDARY_BUG)) ? 1200 :
        100;

    RV32I_SoC #(
        .SIM_MODE(SIM_MODE),
        .SUM_COUNTING_MEM_FILE(`RV32I_TB_SUM_COUNTING_MEM_FILE),
        .BUBBLE_SORT_MEM_FILE(`RV32I_TB_BUBBLE_SORT_MEM_FILE),
        .BUBBLE_SORT_BOUNDARY_BUG_MEM_FILE(`RV32I_TB_BUBBLE_SORT_BOUNDARY_BUG_MEM_FILE)
    ) dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        repeat (2) @(negedge clk);
        rst = 1'b0;

        repeat (RUN_CYCLES) @(negedge clk);

        $finish;
    end
endmodule
