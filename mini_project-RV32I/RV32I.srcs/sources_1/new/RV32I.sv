`timescale 1ns / 1ps

module RV32I (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    input  logic [31:0] drdata,
    output logic [31:0] instr_addr,
    output logic [ 2:0] mem_mode,
    output logic        dwe,
    output logic [31:0] daddr,
    output logic [31:0] dwdata
);
    logic       rf_we;
    logic [3:0] alu_control;
    logic       alu_src_sel;
    logic [2:0] rf_src_sel;
    logic       branch;
    logic       JAL;
    logic       JALR;
    
    rv32i_control  U_CONTROL_UNIT (.*);
    rv32i_datapath U_DATAPATH (.*);

endmodule
