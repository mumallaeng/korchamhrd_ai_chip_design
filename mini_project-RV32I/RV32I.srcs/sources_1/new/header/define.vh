
// Simulation mode IDs
// TYPE family: focused instruction-image checks
`define SIM_MODE_TYPE_ALL              0
`define SIM_MODE_TYPE_REGISTER         1
`define SIM_MODE_TYPE_IMMEDIATE        2
`define SIM_MODE_TYPE_STORE            3
`define SIM_MODE_TYPE_BRANCH           4
`define SIM_MODE_TYPE_UPPER_IMMEDIATE  5
`define SIM_MODE_TYPE_JUMP             6
`define SIM_MODE_TYPE_STORE_BRANCH_UPPER_JUMP 7

// MC_CODE family: compiled program images from .mem files
`define SIM_MODE_MC_CODE_SUM_COUNTING  10
`define SIM_MODE_MC_CODE_BUBBLE_SORT   11
`define SIM_MODE_MC_CODE_BUBBLE_SORT_BOUNDARY_BUG 12

`ifndef RV32I_SIM_MODE_TYPEDEF
`define RV32I_SIM_MODE_TYPEDEF
typedef enum int unsigned {
    RV32I_SIM_TYPE_ALL                    = `SIM_MODE_TYPE_ALL,
    RV32I_SIM_TYPE_REGISTER               = `SIM_MODE_TYPE_REGISTER,
    RV32I_SIM_TYPE_IMMEDIATE              = `SIM_MODE_TYPE_IMMEDIATE,
    RV32I_SIM_TYPE_STORE                  = `SIM_MODE_TYPE_STORE,
    RV32I_SIM_TYPE_BRANCH                 = `SIM_MODE_TYPE_BRANCH,
    RV32I_SIM_TYPE_UPPER_IMMEDIATE        = `SIM_MODE_TYPE_UPPER_IMMEDIATE,
    RV32I_SIM_TYPE_JUMP                   = `SIM_MODE_TYPE_JUMP,
    RV32I_SIM_TYPE_STORE_BRANCH_UPPER_JUMP = `SIM_MODE_TYPE_STORE_BRANCH_UPPER_JUMP,

    RV32I_SIM_MC_CODE_SUM_COUNTING        = `SIM_MODE_MC_CODE_SUM_COUNTING,
    RV32I_SIM_MC_CODE_BUBBLE_SORT         = `SIM_MODE_MC_CODE_BUBBLE_SORT,
    RV32I_SIM_MC_CODE_BUBBLE_SORT_BOUNDARY_BUG = `SIM_MODE_MC_CODE_BUBBLE_SORT_BOUNDARY_BUG
} rv32i_sim_mode_t;
`endif

// Opcode[6:0]
// R-type (Register)
`define R_TYPE 7'b011_0011
// S-type (Store)
`define S_TYPE 7'b010_0011
// I-type (Immediate) - load instructions
`define LI_TYPE 7'b000_0011
// I-type (Immediate) - arithmetic / logic immediate instructions
`define I_TYPE 7'b001_0011
// B-type (Branch)
`define B_TYPE 7'b110_0011
// U-type (Upper Immediate) - LUI
`define U_TYPE 7'b011_0111
// U-type (Upper Immediate) - AUIPC
`define AU_TYPE 7'b001_0111
// J-type (Jump) - JAL
`define J_TYPE 7'b110_1111
// I-type (Immediate) - JALR
`define JL_TYPE 7'b110_0111
// R-type (Register) instruction
// {funct7,funct3} = 10bit
`define ADD 4'b0000
`define SUB 4'b1000
`define SLL 4'b0001
`define SLT 4'b0010
`define SLTU 4'b0011
`define XOR 4'b0100
`define SRL 4'b0101
`define SRA 4'b1101
`define OR 4'b0110
`define AND 4'b0111

// S-type (Store) instruction
`define SB 3'b000
`define SH 3'b001
`define SW 3'b010
// I-type (Immediate) load instruction
`define LB 3'b000
`define LH 3'b001
`define LW 3'b010
`define LBU 3'b100
`define LHU 3'b101
// B-type (Branch) instruction
`define BEQ  4'b0000
`define BNE  4'b0001
`define BLT  4'b0100
`define BGE  4'b0101
`define BLTU 4'b0110
`define BGEU 4'b0111
