`timescale 1ns / 1ps

module RV32I_SoC #(
    parameter int unsigned SIM_MODE = 2,
    parameter string SUM_COUNTING_MEM_FILE = "sum_counting.mem",
    parameter string BUBBLE_SORT_MEM_FILE  = "bubble_sort.mem",
    parameter string BUBBLE_SORT_BOUNDARY_BUG_MEM_FILE = "bubble_sort_boundary_bug.mem"
) (
    input logic clk,
    input logic rst
);

    logic [31:0] instr_code;
    logic [31:0] instr_addr, daddr, dwdata, drdata;
    logic [2:0] mem_mode;
    logic       dwe;

    instruction_mem #(
        .SIM_MODE(SIM_MODE),
        .SUM_COUNTING_MEM_FILE(SUM_COUNTING_MEM_FILE),
        .BUBBLE_SORT_MEM_FILE(BUBBLE_SORT_MEM_FILE),
        .BUBBLE_SORT_BOUNDARY_BUG_MEM_FILE(BUBBLE_SORT_BOUNDARY_BUG_MEM_FILE)
    ) U_RV32_ROM (.*);

    RV32I U_RV32_CPU (.*);

    data_mem U_DATA_MEM (.*);

endmodule
