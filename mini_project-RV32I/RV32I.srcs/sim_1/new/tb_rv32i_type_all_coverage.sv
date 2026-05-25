`timescale 1ns / 1ps
`include "../../sources_1/new/header/define.vh"

module tb_rv32i_type_all_coverage;
    logic clk, rst;
    `include "tb_rv32i_constants.vh"

    localparam int unsigned SIM_MODE = `SIM_MODE_TYPE_ALL;

    localparam int IDX_ADD   = 0;
    localparam int IDX_SUB   = 1;
    localparam int IDX_SLL   = 2;
    localparam int IDX_SLT   = 3;
    localparam int IDX_SLTU  = 4;
    localparam int IDX_XOR   = 5;
    localparam int IDX_SRL   = 6;
    localparam int IDX_SRA   = 7;
    localparam int IDX_OR    = 8;
    localparam int IDX_AND   = 9;

    localparam int IDX_ADDI  = 10;
    localparam int IDX_SLTI  = 11;
    localparam int IDX_SLTIU = 12;
    localparam int IDX_XORI  = 13;
    localparam int IDX_ORI   = 14;
    localparam int IDX_ANDI  = 15;
    localparam int IDX_SLLI  = 16;
    localparam int IDX_SRLI  = 17;
    localparam int IDX_SRAI  = 18;

    localparam int IDX_LB    = 19;
    localparam int IDX_LH    = 20;
    localparam int IDX_LW    = 21;
    localparam int IDX_LBU   = 22;
    localparam int IDX_LHU   = 23;
    localparam int IDX_JALR  = 24;

    localparam int IDX_SB    = 25;
    localparam int IDX_SH    = 26;
    localparam int IDX_SW    = 27;

    localparam int IDX_BEQ   = 28;
    localparam int IDX_BNE   = 29;
    localparam int IDX_BLT   = 30;
    localparam int IDX_BGE   = 31;
    localparam int IDX_BLTU  = 32;
    localparam int IDX_BGEU  = 33;

    localparam int IDX_LUI   = 34;
    localparam int IDX_AUIPC = 35;
    localparam int IDX_JAL   = 36;
    localparam int TOTAL_MNEMONICS = 37;

    int hit_count[0:TOTAL_MNEMONICS-1];
    string mnemonic_name[0:TOTAL_MNEMONICS-1];
    int i;
    int error_count;
    int missing_count;

    RV32I_SoC #(
        .SIM_MODE(SIM_MODE)
    ) dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;
    `include "tb_rv32i_tasks.vh"

    initial begin
        mnemonic_name[IDX_ADD]   = "ADD";
        mnemonic_name[IDX_SUB]   = "SUB";
        mnemonic_name[IDX_SLL]   = "SLL";
        mnemonic_name[IDX_SLT]   = "SLT";
        mnemonic_name[IDX_SLTU]  = "SLTU";
        mnemonic_name[IDX_XOR]   = "XOR";
        mnemonic_name[IDX_SRL]   = "SRL";
        mnemonic_name[IDX_SRA]   = "SRA";
        mnemonic_name[IDX_OR]    = "OR";
        mnemonic_name[IDX_AND]   = "AND";

        mnemonic_name[IDX_ADDI]  = "ADDI";
        mnemonic_name[IDX_SLTI]  = "SLTI";
        mnemonic_name[IDX_SLTIU] = "SLTIU";
        mnemonic_name[IDX_XORI]  = "XORI";
        mnemonic_name[IDX_ORI]   = "ORI";
        mnemonic_name[IDX_ANDI]  = "ANDI";
        mnemonic_name[IDX_SLLI]  = "SLLI";
        mnemonic_name[IDX_SRLI]  = "SRLI";
        mnemonic_name[IDX_SRAI]  = "SRAI";

        mnemonic_name[IDX_LB]    = "LB";
        mnemonic_name[IDX_LH]    = "LH";
        mnemonic_name[IDX_LW]    = "LW";
        mnemonic_name[IDX_LBU]   = "LBU";
        mnemonic_name[IDX_LHU]   = "LHU";
        mnemonic_name[IDX_JALR]  = "JALR";

        mnemonic_name[IDX_SB]    = "SB";
        mnemonic_name[IDX_SH]    = "SH";
        mnemonic_name[IDX_SW]    = "SW";

        mnemonic_name[IDX_BEQ]   = "BEQ";
        mnemonic_name[IDX_BNE]   = "BNE";
        mnemonic_name[IDX_BLT]   = "BLT";
        mnemonic_name[IDX_BGE]   = "BGE";
        mnemonic_name[IDX_BLTU]  = "BLTU";
        mnemonic_name[IDX_BGEU]  = "BGEU";

        mnemonic_name[IDX_LUI]   = "LUI";
        mnemonic_name[IDX_AUIPC] = "AUIPC";
        mnemonic_name[IDX_JAL]   = "JAL";

        for (i = 0; i < TOTAL_MNEMONICS; i = i + 1) begin
            hit_count[i] = 0;
        end
        error_count = 0;

        apply_reset();
        preload_type_demo_state(TB_ADDR_JALR_TYPE_ALL);

        repeat (TB_RUN_CYCLES_TYPE_ALL) @(posedge clk);

        $display("\n==== TYPE_ALL MNEMONIC COVERAGE SUMMARY ====");
        missing_count = 0;
        for (i = 0; i < TOTAL_MNEMONICS; i = i + 1) begin
            if (hit_count[i] > 0) begin
                $display("[PASS] %-5s hit_count=%0d", mnemonic_name[i], hit_count[i]);
            end else begin
                $display("[MISS] %-5s hit_count=0", mnemonic_name[i]);
                missing_count++;
            end
        end

        if (missing_count != 0) begin
            $fatal(1, "TYPE_ALL mnemonic coverage failed: missing %0d instruction(s)", missing_count);
        end

        $display("[PASS] TYPE_ALL observed every targeted mnemonic at least once.");
        $finish;
    end

    always @(posedge clk) begin
        if (!rst) begin
            #1;
            sample_instruction(dut.instr_addr, dut.instr_code);
        end
    end

    task automatic mark_seen(
        input int idx,
        input logic [31:0] pc,
        input logic [31:0] instr
    );
        begin
            hit_count[idx] = hit_count[idx] + 1;
            if (hit_count[idx] == 1) begin
                $display(
                    "[SEEN] T=%0t PC=%08h INSTR=%08h %s",
                    $time,
                    pc,
                    instr,
                    mnemonic_name[idx]
                );
            end
        end
    endtask

    task automatic sample_instruction(
        input logic [31:0] pc,
        input logic [31:0] instr
    );
        logic [6:0] opcode;
        logic [2:0] funct3;
        logic [6:0] funct7;
        begin
            opcode = instr[6:0];
            funct3 = instr[14:12];
            funct7 = instr[31:25];

            case (opcode)
                `R_TYPE: begin
                    case ({funct7[5], funct3})
                        `ADD:  mark_seen(IDX_ADD,  pc, instr);
                        `SUB:  mark_seen(IDX_SUB,  pc, instr);
                        `SLL:  mark_seen(IDX_SLL,  pc, instr);
                        `SLT:  mark_seen(IDX_SLT,  pc, instr);
                        `SLTU: mark_seen(IDX_SLTU, pc, instr);
                        `XOR:  mark_seen(IDX_XOR,  pc, instr);
                        `SRL:  mark_seen(IDX_SRL,  pc, instr);
                        `SRA:  mark_seen(IDX_SRA,  pc, instr);
                        `OR:   mark_seen(IDX_OR,   pc, instr);
                        `AND:  mark_seen(IDX_AND,  pc, instr);
                    endcase
                end
                `I_TYPE: begin
                    if (instr != 32'h0000_0013) begin
                        case (funct3)
                            3'b000: mark_seen(IDX_ADDI,  pc, instr);
                            3'b010: mark_seen(IDX_SLTI,  pc, instr);
                            3'b011: mark_seen(IDX_SLTIU, pc, instr);
                            3'b100: mark_seen(IDX_XORI,  pc, instr);
                            3'b110: mark_seen(IDX_ORI,   pc, instr);
                            3'b111: mark_seen(IDX_ANDI,  pc, instr);
                            3'b001: mark_seen(IDX_SLLI,  pc, instr);
                            3'b101: begin
                                if (funct7[5]) begin
                                    mark_seen(IDX_SRAI, pc, instr);
                                end else begin
                                    mark_seen(IDX_SRLI, pc, instr);
                                end
                            end
                        endcase
                    end
                end
                `LI_TYPE: begin
                    case (funct3)
                        `LB:  mark_seen(IDX_LB,  pc, instr);
                        `LH:  mark_seen(IDX_LH,  pc, instr);
                        `LW:  mark_seen(IDX_LW,  pc, instr);
                        `LBU: mark_seen(IDX_LBU, pc, instr);
                        `LHU: mark_seen(IDX_LHU, pc, instr);
                    endcase
                end
                `JL_TYPE: begin
                    mark_seen(IDX_JALR, pc, instr);
                end
                `S_TYPE: begin
                    case (funct3)
                        `SB: mark_seen(IDX_SB, pc, instr);
                        `SH: mark_seen(IDX_SH, pc, instr);
                        `SW: mark_seen(IDX_SW, pc, instr);
                    endcase
                end
                `B_TYPE: begin
                    case ({1'b0, funct3})
                        `BEQ:  mark_seen(IDX_BEQ,  pc, instr);
                        `BNE:  mark_seen(IDX_BNE,  pc, instr);
                        `BLT:  mark_seen(IDX_BLT,  pc, instr);
                        `BGE:  mark_seen(IDX_BGE,  pc, instr);
                        `BLTU: mark_seen(IDX_BLTU, pc, instr);
                        `BGEU: mark_seen(IDX_BGEU, pc, instr);
                    endcase
                end
                `U_TYPE: begin
                    mark_seen(IDX_LUI, pc, instr);
                end
                `AU_TYPE: begin
                    mark_seen(IDX_AUIPC, pc, instr);
                end
                `J_TYPE: begin
                    mark_seen(IDX_JAL, pc, instr);
                end
            endcase
        end
    endtask
endmodule
