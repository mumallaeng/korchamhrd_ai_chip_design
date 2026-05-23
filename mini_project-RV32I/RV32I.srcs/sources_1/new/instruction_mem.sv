`timescale 1ns / 1ps
`include "header/define.vh"

module instruction_mem #(
    parameter int unsigned SIM_MODE = 2,
    parameter string SUM_COUNTING_MEM_FILE = "sum_counting.mem",
    parameter string BUBBLE_SORT_MEM_FILE  = "bubble_sort.mem",
    parameter string BUBBLE_SORT_BOUNDARY_BUG_MEM_FILE = "bubble_sort_boundary_bug.mem"
) (
    input  logic [31:0] instr_addr,
    output logic [31:0] instr_code
);
    logic [31:0] instr_rom[0:127];  // Word-aligned instruction ROM
    int i;

    initial begin
        for (i = 0; i < 128; i = i + 1) begin
            instr_rom[i] = 32'h0000_0013;  // nop = addi x0, x0, 0
        end

        if (SIM_MODE == `SIM_MODE_TYPE_ALL) begin
            `include "header/type_Register.vh"
            `include "header/type_Immediate.vh"
            `include "header/type_Store.vh"
            `include "header/type_Branch.vh"
            `include "header/type_UpperImmediate.vh"
            `include "header/type_Jump.vh"
        end else if (SIM_MODE == `SIM_MODE_TYPE_REGISTER) begin
            `include "header/type_Register.vh"
        end else if (SIM_MODE == `SIM_MODE_TYPE_IMMEDIATE) begin
            `include "header/type_ImmediateOrdered.vh"
        end else if (SIM_MODE == `SIM_MODE_TYPE_STORE) begin
            `include "header/type_Store.vh"
        end else if (SIM_MODE == `SIM_MODE_TYPE_BRANCH) begin
            `include "header/type_Branch.vh"
        end else if (SIM_MODE == `SIM_MODE_TYPE_UPPER_IMMEDIATE) begin
            `include "header/type_UpperImmediate.vh"
        end else if (SIM_MODE == `SIM_MODE_TYPE_JUMP) begin
            `include "header/type_Jump.vh"
        end else if (SIM_MODE == `SIM_MODE_TYPE_STORE_BRANCH_UPPER_JUMP) begin
            `include "header/type_Store.vh"
            `include "header/type_Branch.vh"
            `include "header/type_UpperImmediate.vh"
            `include "header/type_Jump.vh"
        end else if (SIM_MODE == `SIM_MODE_MC_CODE_SUM_COUNTING) begin
            $readmemh(SUM_COUNTING_MEM_FILE, instr_rom);
        end else if (SIM_MODE == `SIM_MODE_MC_CODE_BUBBLE_SORT) begin
            $readmemh(BUBBLE_SORT_MEM_FILE, instr_rom);
        end else if (SIM_MODE == `SIM_MODE_MC_CODE_BUBBLE_SORT_BOUNDARY_BUG) begin
            $readmemh(BUBBLE_SORT_BOUNDARY_BUG_MEM_FILE, instr_rom);
        end
    end

    // Byte-addressed PC to word-aligned instruction fetch
    assign instr_code = instr_rom[instr_addr[31:2]];

endmodule
