`timescale 1ns / 1ps
`include "header/define.vh"

module rv32i_control (
    input  logic [31:0] instr_code,
    output logic        alu_src_sel,
    output logic        rf_we,
    output logic        dwe,
    output logic [ 3:0] alu_control,
    output logic        branch,
    output logic [ 2:0] rf_src_sel,
    output logic [ 2:0] mem_mode,
    output logic        JAL,
    output logic        JALR
);
    logic [6:0] funct7;
    logic [2:0] funct3;
    logic [6:0] opcode;
    assign funct7 = instr_code[31:25];
    assign funct3 = instr_code[14:12];
    assign opcode = instr_code[6:0];

    //[DEBUG]
    typedef enum logic [6:0] {
        DBG_R_TYPE  = `R_TYPE,
        DBG_S_TYPE  = `S_TYPE,
        DBG_LI_TYPE = `LI_TYPE,
        DBG_I_TYPE  = `I_TYPE,
        DBG_B_TYPE  = `B_TYPE,
        DBG_U_TYPE  = `U_TYPE,
        DBG_AU_TYPE = `AU_TYPE,
        DBG_J_TYPE  = `J_TYPE,
        DBG_JL_TYPE = `JL_TYPE
    } opcode_dbg_e;
    opcode_dbg_e opcode_dbg;
    assign opcode_dbg = opcode_dbg_e'(opcode);

    typedef enum logic [5:0] {
        DBG_UNKNOWN = 6'd0,
        DBG_NOP     = 6'd1,
        DBG_ADD     = 6'd2,
        DBG_SUB     = 6'd3,
        DBG_SLL     = 6'd4,
        DBG_SLT     = 6'd5,
        DBG_SLTU    = 6'd6,
        DBG_XOR     = 6'd7,
        DBG_SRL     = 6'd8,
        DBG_SRA     = 6'd9,
        DBG_OR      = 6'd10,
        DBG_AND     = 6'd11,
        DBG_ADDI    = 6'd12,
        DBG_SLTI    = 6'd13,
        DBG_SLTIU   = 6'd14,
        DBG_XORI    = 6'd15,
        DBG_ORI     = 6'd16,
        DBG_ANDI    = 6'd17,
        DBG_SLLI    = 6'd18,
        DBG_SRLI    = 6'd19,
        DBG_SRAI    = 6'd20,
        DBG_LB      = 6'd21,
        DBG_LH      = 6'd22,
        DBG_LW      = 6'd23,
        DBG_LBU     = 6'd24,
        DBG_LHU     = 6'd25,
        DBG_SB      = 6'd26,
        DBG_SH      = 6'd27,
        DBG_SW      = 6'd28,
        DBG_BEQ     = 6'd29,
        DBG_BNE     = 6'd30,
        DBG_BLT     = 6'd31,
        DBG_BGE     = 6'd32,
        DBG_BLTU    = 6'd33,
        DBG_BGEU    = 6'd34,
        DBG_LUI     = 6'd35,
        DBG_AUIPC   = 6'd36,
        DBG_JAL     = 6'd37,
        DBG_JALR    = 6'd38
    } instr_dbg_e;
    instr_dbg_e instr_dbg;

    always_comb begin
        rf_we = 0;
        alu_control = 0;
        alu_src_sel = 0;
        rf_src_sel = 0;
        mem_mode = 0;
        dwe = 0;
        branch = 0;
        JAL = 0;
        JALR = 0;
        instr_dbg = DBG_UNKNOWN;
        case (opcode)
            `R_TYPE: begin
                rf_we = 1'b1;
                alu_src_sel = 0;
                alu_control = {funct7[5], funct3};
                rf_src_sel = 0;
                mem_mode = 0;
                dwe = 0;
                branch = 0;
                JAL = 0;
                JALR = 0;
                case ({funct7[5], funct3})
                    `ADD:  instr_dbg = DBG_ADD;
                    `SUB:  instr_dbg = DBG_SUB;
                    `SLL:  instr_dbg = DBG_SLL;
                    `SLT:  instr_dbg = DBG_SLT;
                    `SLTU: instr_dbg = DBG_SLTU;
                    `XOR:  instr_dbg = DBG_XOR;
                    `SRL:  instr_dbg = DBG_SRL;
                    `SRA:  instr_dbg = DBG_SRA;
                    `OR:   instr_dbg = DBG_OR;
                    `AND:  instr_dbg = DBG_AND;
                    default: instr_dbg = DBG_UNKNOWN;
                endcase
            end
            `S_TYPE: begin
                rf_we = 0;
                alu_src_sel = 1;
                alu_control = `ADD;
                rf_src_sel = 0;
                mem_mode = funct3;
                dwe = 1;
                branch = 0;
                JAL = 0;
                JALR = 0;
                case (funct3)
                    `SB: instr_dbg = DBG_SB;
                    `SH: instr_dbg = DBG_SH;
                    `SW: instr_dbg = DBG_SW;
                    default: instr_dbg = DBG_UNKNOWN;
                endcase
            end
            `LI_TYPE: begin  // I-type (Immediate): load instructions
                rf_we = 1;
                alu_src_sel = 1;  //rs1+imm
                alu_control = `ADD;
                rf_src_sel = 1;
                mem_mode = funct3;
                dwe = 0;
                branch = 0;
                JAL = 0;
                JALR = 0;
                case (funct3)
                    `LB:  instr_dbg = DBG_LB;
                    `LH:  instr_dbg = DBG_LH;
                    `LW:  instr_dbg = DBG_LW;
                    `LBU: instr_dbg = DBG_LBU;
                    `LHU: instr_dbg = DBG_LHU;
                    default: instr_dbg = DBG_UNKNOWN;
                endcase
            end
            `I_TYPE: begin  // I-type (Immediate): arithmetic / logic
                rf_we = 1;
                alu_src_sel = 1;  //rs1+imm
                case (funct3)
                    3'b000: begin
                        alu_control = `ADD;  // ADDI
                        if (instr_code == 32'h0000_0013) begin
                            instr_dbg = DBG_NOP;
                        end else begin
                            instr_dbg = DBG_ADDI;
                        end
                    end
                    3'b010: begin
                        alu_control = `SLT;  // SLTI
                        instr_dbg = DBG_SLTI;
                    end
                    3'b011: begin
                        alu_control = `SLTU;  // SLTIU
                        instr_dbg = DBG_SLTIU;
                    end
                    3'b100: begin
                        alu_control = `XOR;  // XORI
                        instr_dbg = DBG_XORI;
                    end
                    3'b110: begin
                        alu_control = `OR;  // ORI
                        instr_dbg = DBG_ORI;
                    end
                    3'b111: begin
                        alu_control = `AND;  // ANDI
                        instr_dbg = DBG_ANDI;
                    end
                    3'b001: begin
                        alu_control = `SLL;  // SLLI
                        instr_dbg = DBG_SLLI;
                    end
                    3'b101: begin
                        alu_control = funct7[5] ? `SRA : `SRL;  // SRAI / SRLI
                        if (funct7[5]) begin
                            instr_dbg = DBG_SRAI;
                        end else begin
                            instr_dbg = DBG_SRLI;
                        end
                    end
                    default: instr_dbg = DBG_UNKNOWN;
                endcase
                rf_src_sel = 0;
                mem_mode = 0;
                dwe = 0;
                branch = 0;
                JAL = 0;
                JALR = 0;
            end
            `B_TYPE: begin
                rf_we = 0;
                alu_src_sel = 0;  //rs1+imm
                alu_control = {1'b0, funct3};
                rf_src_sel = 0;
                mem_mode = 0;
                dwe = 0;
                branch = 1;
                JAL = 0;
                JALR = 0;
                case ({1'b0, funct3})
                    `BEQ:  instr_dbg = DBG_BEQ;
                    `BNE:  instr_dbg = DBG_BNE;
                    `BLT:  instr_dbg = DBG_BLT;
                    `BGE:  instr_dbg = DBG_BGE;
                    `BLTU: instr_dbg = DBG_BLTU;
                    `BGEU: instr_dbg = DBG_BGEU;
                    default: instr_dbg = DBG_UNKNOWN;
                endcase
            end
            `U_TYPE: begin  // U-type (Upper Immediate): LUI
                rf_we = 1;
                alu_src_sel = 0;  //xx
                alu_control = `ADD;
                rf_src_sel = 2;
                mem_mode = 0;
                dwe = 0;
                branch = 0;
                JAL = 0;
                JALR = 0;
                instr_dbg = DBG_LUI;
            end
            `AU_TYPE: begin  // U-type (Upper Immediate): AUIPC
                rf_we = 1;
                alu_src_sel = 0;  //xx
                alu_control = `ADD;
                rf_src_sel = 3;
                mem_mode = 0;
                dwe = 0;
                branch = 0;
                JAL = 0;
                JALR = 0;
                instr_dbg = DBG_AUIPC;
            end
            `J_TYPE: begin  // J-type (Jump): JAL
                rf_we = 1;
                alu_src_sel = 0;  //xx
                alu_control = `ADD;
                rf_src_sel = 4;
                mem_mode = 0;
                dwe = 0;
                branch = 0;
                JAL = 1;
                JALR = 0;
                instr_dbg = DBG_JAL;
            end
            `JL_TYPE: begin  // I-type (Immediate): JALR
                rf_we = 1;
                alu_src_sel = 0;  //xx
                alu_control = `ADD;
                rf_src_sel = 4;
                mem_mode = 0;
                dwe = 0;
                branch = 0;
                JAL = 1;
                JALR = 1;
                instr_dbg = DBG_JALR;
            end
        endcase

    end
endmodule
