`timescale 1ns / 1ps
`include "header/define.vh"

module rv32i_datapath (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    input  logic        rf_we,
    input  logic        branch,
    input  logic        alu_src_sel,
    input  logic [ 3:0] alu_control,
    input  logic [ 2:0] rf_src_sel,
    input  logic        JAL,
    input  logic        JALR,
    input  logic [31:0] drdata,
    output logic [31:0] instr_addr,
    output logic [31:0] daddr,
    output logic [31:0] dwdata
);
    logic [31:0] RD2, alu_RD2, RD1, alu_result, rf_src_mux_out;
    logic [31:0] imm_extend, w_pc_add;
    logic [31:0] pc_imm, pc_next;
    logic b_taken;

    assign daddr  = alu_result;
    assign dwdata = RD2;

    imm_extend U_IMM_EXTEND (
        .instr_code(instr_code),
        .imm_extend(imm_extend)
    );

    register_file U_REG_FILE (
        .clk(clk),
        .rst(rst),
        .RA1(instr_code[19:15]),
        .RA2(instr_code[24:20]),
        .WA(instr_code[11:7]),
        .rf_we(rf_we),
        .WD(rf_src_mux_out),
        .RD1(RD1),
        .RD2(RD2)
    );

    program_counter U_PC (
        .clk(clk),
        .rst(rst),
        .pc_in(instr_addr),
        .pc_RD1(RD1),
        .pc_add(imm_extend),
        .JAL(JAL),
        .JALR(JALR),
        .b_taken(b_taken),
        .branch(branch),
        .pc_out(instr_addr),
        .pc_imm(pc_imm),
        .pc_next(pc_next)
    );

    alu U_ALU (
        .alu_control(alu_control),
        .a(RD1),
        .b(alu_RD2),
        .alu_result(alu_result),
        .b_taken(b_taken)
    );

    mux_2x1 U_ALU_MUX (
        .in0(RD2),
        .in1(imm_extend),
        .sel(alu_src_sel),
        .mux_out(alu_RD2)
    );

    mux_5x1 U_REG_FILE_SRC_MUX (
        .in0(alu_result),
        .in1(drdata),
        .in2(imm_extend),
        .in3(pc_imm),
        .in4(pc_next),
        .sel(rf_src_sel),
        .mux_out(rf_src_mux_out)

    );

endmodule

module register_file (
    input  logic        clk,
    input  logic        rst,
    input  logic [ 4:0] RA1,
    input  logic [ 4:0] RA2,
    input  logic [ 4:0] WA,
    input  logic        rf_we,
    input  logic [31:0] WD,
    output logic [31:0] RD1,
    output logic [31:0] RD2
);

    logic [31:0] cpu_reg[0:31];
`ifdef TEST_SIMULATION
    int i = 0;
    initial begin
        for (i = 0; i < 16; i = i + 1) begin

            cpu_reg[i] = i;
        end
        for (i = 16; i < 32; i = i + 1) begin

            cpu_reg[i] = -i;
        end
    end
`endif

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            cpu_reg[0] <= 0;
        end else begin
            if (rf_we && (WA != 5'b00000)) begin
                cpu_reg[WA] <= WD;
            end
        end

    end
    assign RD1 = cpu_reg[RA1];
    assign RD2 = cpu_reg[RA2];

endmodule

module alu (
    input  logic [ 3:0] alu_control,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] alu_result,
    output logic        b_taken
);
    always_comb begin
        alu_result = 32'h0000_0000;
        b_taken = 1'b0;
        case (alu_control)
            `ADD:  alu_result = a + b;
            `SUB:  alu_result = a - b;
            `SLL:  alu_result = a << b[4:0];
            `SLT:  alu_result = ($signed(a) < $signed(b)) ? 1 : 0;
            `SLTU: alu_result = (a < b) ? 32'h0000_0001 : 32'h0000_0000;
            `XOR:  alu_result = a ^ b;
            `SRL:  alu_result = a >> b[4:0];
            `SRA:  alu_result = $signed(a) >>> b[4:0];
            `OR:   alu_result = a | b;
            `AND:  alu_result = a & b;
        endcase
        case (alu_control)
            `BEQ: begin
                if (a == b) b_taken = 1;
                else b_taken = 0;
            end
            `BNE: begin
                if (a != b) b_taken = 1;
                else b_taken = 0;
            end
            `BLT: begin
                if ($signed(a) < $signed(b)) b_taken = 1;
                else b_taken = 0;
            end
            `BGE: begin
                if ($signed(a) >= $signed(b)) b_taken = 1;
                else b_taken = 0;
            end
            `BLTU: begin
                if (a < b) b_taken = 1;
                else b_taken = 0;
            end
            `BGEU: begin
                if (a >= b) b_taken = 1;
                else b_taken = 0;
            end
            default: b_taken = 1'b0;
        endcase
    end

endmodule

module program_counter (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] pc_in,
    input  logic [31:0] pc_RD1,
    input  logic [31:0] pc_add,
    input  logic        JAL,
    input  logic        JALR,
    input  logic        b_taken,
    input  logic        branch,
    output logic [31:0] pc_out,
    output logic [31:0] pc_imm,
    output logic [31:0] pc_next
);

    logic [31:0] pc_RD1_mux_out;
    logic [31:0] pc_type_0, pc_type_1;
    logic [31:0] pc_final;
    logic [31:0] pc_reg;

    assign pc_RD1_mux_out = (JALR) ? pc_RD1 : pc_in;
    assign pc_type_0 = pc_in + 4;
    assign pc_type_1 = pc_RD1_mux_out + pc_add;
    assign pc_final = ((branch & b_taken) | JAL) ? pc_type_1 : pc_type_0;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            pc_reg <= 0;
        end else begin
            pc_reg <= pc_final;
        end
    end

    assign pc_out  = pc_reg;
    assign pc_imm  = pc_type_1;
    assign pc_next = pc_type_0;

endmodule

module imm_extend (
    input  logic [31:0] instr_code,
    output logic [31:0] imm_extend
);

    always_comb begin
        imm_extend = 0;
        case (instr_code[6:0])
            `S_TYPE:
            imm_extend = {
                {20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]
            };
            `LI_TYPE, `I_TYPE, `JL_TYPE: begin
                // I-type immediate format: load, arithmetic-immediate, JALR
                imm_extend = {{20{instr_code[31]}}, instr_code[31:20]};
            end
            `B_TYPE: begin
                imm_extend = {
                    {20{instr_code[31]}},  //20
                    instr_code[7],  //1
                    instr_code[30:25],  //6
                    instr_code[11:8],  //4
                    1'b0  //마지막 비트 1
                };
            end
            `U_TYPE, `AU_TYPE: imm_extend = {instr_code[31:12], 12'b0};
            `J_TYPE:
            imm_extend = {
                {12{instr_code[31]}},
                instr_code[19:12],
                instr_code[20],
                instr_code[30:21],
                1'b0
            };

        endcase
    end

endmodule

module mux_2x1 (
    input  logic [31:0] in0,
    input  logic [31:0] in1,
    input  logic        sel,
    output logic [31:0] mux_out
);
    assign mux_out = (sel) ? in1 : in0;
endmodule

module mux_5x1 (
    input  logic [31:0] in0,
    input  logic [31:0] in1,
    input  logic [31:0] in2,
    input  logic [31:0] in3,
    input  logic [31:0] in4,
    input  logic [ 2:0] sel,
    output logic [31:0] mux_out
);
    always_comb begin
        case (sel)
            3'b000:  mux_out = in0;
            3'b001:  mux_out = in1;
            3'b010:  mux_out = in2;
            3'b011:  mux_out = in3;
            3'b100:  mux_out = in4;
            default: mux_out = 32'h0000_0000;
        endcase
    end

endmodule
