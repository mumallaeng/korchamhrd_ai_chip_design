// Shared constants for RV32I type testbenches.
// These names explain why each hard-coded value exists in the type tests.

localparam int unsigned TB_X_ZERO = 0;   // x0: hard-wired zero
localparam int unsigned TB_X_RA   = 1;   // x1: return address / link register
localparam int unsigned TB_X2     = 2;   // x2: small operand value 2
localparam int unsigned TB_X3     = 3;   // x3: small operand value 3
localparam int unsigned TB_X4     = 4;   // x4: BEQ compare partner
localparam int unsigned TB_X5     = 5;   // x5: common destination register
localparam int unsigned TB_X6     = 6;   // x6: BNE compare partner
localparam int unsigned TB_X10    = 10;  // x10: signed -1 test operand
localparam int unsigned TB_X11    = 11;  // x11: shift amount / signed +1 operand
localparam int unsigned TB_X12    = 12;  // x12: store write-data source
localparam int unsigned TB_X13    = 13;  // x13: base address 0x40 -> data_ram[16]
localparam int unsigned TB_X14    = 14;  // x14: base address 0x44 -> data_ram[17]
localparam int unsigned TB_X15    = 15;  // x15: base address 0x48 -> data_ram[18]
localparam int unsigned TB_X20    = 20;  // x20: JALR target register

localparam logic [31:0] TB_VAL_ZERO              = 32'h0000_0000;
localparam logic [31:0] TB_VAL_SMALL_2           = 32'h0000_0002;
localparam logic [31:0] TB_VAL_SMALL_3           = 32'h0000_0003;
localparam logic [31:0] TB_VAL_BRANCH_EQUAL      = 32'h0000_0003;
localparam logic [31:0] TB_VAL_BNE_LEFT          = 32'h0000_0008;
localparam logic [31:0] TB_VAL_BNE_RIGHT_INITIAL = 32'h0000_0008;
localparam logic [31:0] TB_VAL_SIGNED_NEG1       = 32'hffff_ffff;
localparam logic [31:0] TB_VAL_SHIFT_ONE         = 32'h0000_0001;
localparam logic [31:0] TB_VAL_STORE_PATTERN     = 32'h1234_5678;

localparam logic [31:0] TB_ADDR_DATA_WORD0 = 32'h0000_0040;  // byte addr 0x40 -> word index 16
localparam logic [31:0] TB_ADDR_DATA_WORD1 = 32'h0000_0044;  // byte addr 0x44 -> word index 17
localparam logic [31:0] TB_ADDR_DATA_WORD2 = 32'h0000_0048;  // byte addr 0x48 -> word index 18
localparam logic [31:0] TB_ADDR_JALR_FOCUSED = 32'h0000_003c;
localparam logic [31:0] TB_ADDR_JALR_TYPE_ALL = 32'h0000_0140;

localparam int unsigned TB_RAM_WORD_ACCESS = 16;  // data_ram[16] = 0x12345678 for LW/SW/SH/SB
localparam int unsigned TB_RAM_BYTE_ACCESS = 17;  // data_ram[17][7:0] = 0x80 for LB/LBU extension
localparam int unsigned TB_RAM_HALF_ACCESS = 18;  // data_ram[18][15:0] = 0xffff for LH/LHU extension

localparam logic [31:0] TB_RAM_WORD_PATTERN = 32'h1234_5678;
localparam logic [31:0] TB_RAM_BYTE_PATTERN = 32'h0000_0080;
localparam logic [31:0] TB_RAM_HALF_PATTERN = 32'h0000_ffff;

localparam int unsigned TB_PC_TYPE_REGISTER         = 32'd0;
localparam int unsigned TB_PC_TYPE_IMMEDIATE        = 32'd0;
localparam int unsigned TB_PC_TYPE_STORE            = 32'd44;
localparam int unsigned TB_PC_TYPE_BRANCH           = 32'd92;
localparam int unsigned TB_PC_TYPE_UPPER_IMMEDIATE  = 32'd100;
localparam int unsigned TB_PC_TYPE_JUMP             = 32'd108;
localparam int unsigned TB_PC_TYPE_STORE_BRANCH_UJ  = 32'd44;

localparam int unsigned TB_RUN_CYCLES_TYPE_ALL      = 100;
localparam int unsigned TB_RUN_CYCLES_SINGLE_TYPE   = 50;
