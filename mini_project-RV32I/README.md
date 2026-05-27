English | [한국어](README.ko.md)

# RV32I Single-Cycle CPU

Kim Yeonwoo

2026.05.22 ~ 2026.05.27

## 1. Overview and Design Scope

### 1.1 Purpose and Objectives

The purpose of this project is to design an RV32I single-cycle CPU, compile C source code through the compiler and assembler stages into an instruction memory initialization file in RV32I machine code hex format, reflect this into the instruction ROM, and analyze how instruction fetching, control flow changes, function calls, and data memory access are performed at the RTL level. The goal is to describe the process by which the control structures and data structures of C source code are concretized into stack frames, local variable placement, pointer dereferencing, function calls and returns, and branch and jump sequences, in conjunction with the CPU datapath and control path. The core objectives are as follows:

- Design a 32-bit datapath and control path based on RV32I in a single-cycle structure.
- Explain the roles of instruction_mem, data_mem, rv32i_control, rv32i_datapath, program_counter, register_file, and alu separately.
- Organize R/I/S/B/U/J formats and JAL/JALR, LB/LBU/LH/LHU/LW, SB/SH/SW based on control/datapath criteria.
- Centered on the execution image of sum_counting.c, using buble_sort.c as a supplementary case, analyze stack pointer, local variable placement, pointers, function calls and returns, and comparison statement operations at the instruction level.
- Compile together verifiable items based on current testbench and waveform observation criteria along with verification limitations.

### 1.2 Design Scope

| Category | In-Scope | Out-of-Scope |
|---|---|---|
| CPU Structure | RV32I single-cycle, separate instruction/data memory | multi-cycle, pipeline, hazard handling |
| ISA Scope | R/I/S/B/U/J, JAL/JALR, byte/halfword/word load-store | M/A/F/D/C extensions |
| Program Analysis | sum_counting.c, buble_sort.c | compiler backend detailed implementation |
| Verification Scope | Current tb_rv32i.sv based execution, internal signal observation, conditional auxiliary instruction sequence analysis | self-checking scoreboard TB, coverage-based verification |
| Result Scope | Simulation-centric feature analysis | board I/O, separate FPGA demo |

### 1.3 Project Summary

This design is an educational single-cycle CPU implementation targeting the RV32I integer basic instruction set. The top-level module RV32I serves as a wrapper, instantiating top_rv32i_soc internally and connecting instruction_mem, rv32i_sv, and data_mem in its lower hierarchy. The basic instruction memory initialization image is buble_sort.mem, and sum_counting.mem is provided together as an alternative execution image. Accordingly, this report analyzes function calls and cumulative sum calculation structures through sum_counting, and comprehensively describes arrays, pointers, nested loops, comparison branches, and boundary condition problems through buble_sort.

### 1.4 Design Specification Summary (Specification Summary)

| Item | Content |
|---|---|
| top module | RV32I |
| Internal SoC top | top_rv32i_soc |
| CPU core | rv32i_sv |
| Data width | 32-bit |
| Instruction width | 32-bit |
| Instruction memory | 128 words |
| Data memory | 256 words |
| Addressing scheme | byte-addressed |
| Internal memory index | Primarily based on addr[31:2] word index |
| Basic execution image | buble_sort.mem |
| Alternative execution image | sum_counting.mem |
| Design goal | Single-cycle RV32I CPU configuration capable of analyzing C program execution flow and memory structure |

### 1.5 AS-IS / TO-BE

| Category | AS-IS | TO-BE |
|---|---|---|
| Learning status | Partially understands instruction formats and basic datapath | Integrated into RV32I single-cycle structure connecting to C program execution flow |
| Memory | Word/byte concepts mixed with low explanation consistency | Separately explains addressing, alignment, byte lane, sign/zero extension |
| Program | Fragmented explanations focused on individual instructions | Explains stack, local variables, pointers, function calls and returns based on sum_counting, buble_sort |
| Verification perspective | Centered on simple execution or partial waveform observation | Explicitly defines verification scope and limitations based on execution scenarios and observed signals |

### 1.6 Theoretical Development and Design Scope Summary

#### 1.6.1 RISC-V Overview

RISC-V is a public standard ISA originating from UC Berkeley's fifth RISC ISA project. Since V in the name means the Roman numeral 5, it is read as RISC-Five. RISC-V is based on RISC design philosophy that constructs program operations by combining simple and regular instructions, and its instruction fields and decode rules are relatively clear, making it suitable for educational CPU implementation.

#### 1.6.2 Modular Structure of RISC-V ISA

The RISC-V ISA consists of a combination of a basic ISA and extension ISAs, not a single fixed instruction set. Centered on the basic integer ISA I, extensions such as M, A, C can be selectively added as needed.

| Notation | Meaning | Description |
|---|---|---|
| I | Integer | Basic integer instruction set |
| M | Multiply/Divide | Multiplication and division extension |
| A | Atomic | atomic memory operation extension |
| C | Compressed | 16-bit compressed instruction extension |

#### 1.6.3 This Design Scope: RV32I Single-Cycle CPU

This design implements the RISC-V based 32-bit basic integer ISA, RV32I, in a single-cycle structure. RV32I is a basic ISA that uses 32-bit integer registers and a 32-bit address space, including basic integer operations, branches, jumps, and load/store instructions. Since this design aims for CPU structure learning and verification scope limitations, M, A, C extensions are excluded, defining RV32I as the implementation target.

## 2. Project Management and Development Environment

### 2.1 Schedule (Schedule)

| Phase | Duration | Key Tasks |
|---|---|---|
| Requirements clarification | 2026.05.22 | Confirm presentation scope, report scope, C code analysis target |
| Architecture design | 2026.05.22 ~ 2026.05.23 | Organize RV32I -> top_rv32i_soc -> instruction_mem/data_mem/core structure |
| RTL organization | 2026.05.23 | Align RV32I project structure based on 20260519_rv32i, maintain top name |
| Program analysis | 2026.05.23 ~ 2026.05.24 | Organize sum_counting.c, buble_sort.c, .mem, disassembly flow |
| Verification | 2026.05.24 ~ 2026.05.26 | Simulation confirmation |
| Presentation preparation and deliverables organization | 2026.05.25 ~ 2026.05.27 | Write completion report, organize presentation materials |

### 2.2 Development and Design Environment (Development Environment)

| Category | Content |
|---|---|
| RTL language | SystemVerilog (.sv) |
| Program language | C |
| FPGA target board | Digilent Basys 3 |
| Project tool | Vivado 2020.2 |
| Version control | Git |

## 3. RV32I Design Theory and CPU Structure

<img width="1672" height="758" alt="image4" src="https://github.com/user-attachments/assets/25139455-6914-4d16-a174-aa139d1a6e04" />

### 3.1 Single-Cycle Structure and Harvard Architecture Selection
A single-cycle structure completes one instruction within a single clock cycle. In this architecture, the instruction fetch, decode, register read, ALU operation, memory access, write-back, and PC update must all be connected within one cycle. While this simplicity makes it ideal for learning datapath and control path design, it is constrained by the clock period being determined by the longest instruction path.

The reason for separating instruction memory and data memory in this design relates to the memory access characteristics of a single-cycle structure. Load/store instructions may require both the next instruction fetch and data memory access within a single cycle. If a single memory port is shared, an instruction fetch and data access could collide in the same cycle; therefore, this design employs a Harvard Architecture-based structure that separates instruction memory and data memory.

| Structure | Memory Access Method | Characteristics |
|---|---|---|
| Von Neumann | Instruction and data share the same memory path | Simple structure but collision possible in single-cycle load/store |
| Harvard | Instruction memory and data memory are separated | Separation of instruction fetch and data access paths |
| Multi-cycle + Von Neumann | Divides cycles to reuse a single memory | Implementable but parallel access is not possible |

### 3.2 Necessity of Instruction/Data Memory Block Separation and Access Rules

As shown in the upper-level block diagram, memory is separated into instruction_mem and data_mem. The Instruction Memory acts as a ROM that outputs the current instr_code to be executed based on the instr_addr provided by the Program Counter. The Data Memory acts as a RAM that reads or writes data for load/store operations based on the daddr calculated by the ALU. In other words, while the two memory blocks are separated due to Harvard Architecture, separate rules are needed to interpret the address values passed by the CPU into actual memory array locations.

Since RV32I uses a byte-addressed memory model, all addresses generated by the CPU—PC, branch/jump targets, and load/store addresses—are interpreted as byte-unit addresses. In contrast, ROMs and RAMs in RTL are typically implemented as 32-bit word arrays. Therefore, rules are needed to convert the byte addresses generated by the CPU into both the word index of the actual memory array and the byte lane within that word.

The memory access rule is not merely a performance optimization; its core purpose is to accurately map RV32I's byte-addressed memory model to the actual RTL memory structure. Performance issues relate to the choice of Harvard Architecture, while address interpretation rules are necessary for functional correctness.

### 3.3 Memory Access Model

#### 3.3.1 Addressing / Alignment

Addressing defines how the CPU represents memory locations as addresses. In RV32I, PC and load/store addresses are represented as byte-unit addresses. Alignment refers to whether an access address is positioned at a boundary matching the data size.

| Item | Reason Needed | Meaning |
|---|---|---|
| byte-addressed memory | RV32I addresses are defined as byte-unit addresses | PC, branch/jump targets, and load/store addresses represent byte locations |
| alignment check | 32-bit instructions and word data default to aligned address access | Verifies whether the address is aligned according to the access size |

| Access Type | Access Size | Alignment Condition |
|---|---|---|
| Instruction fetch | 4 bytes | address [1:0] = 00 |
| lw, sw | 4 bytes | address [1:0] = 00 |
| lh, sh | 2 bytes | address [0] = 0 |
| lb, sb | 1 byte | No alignment constraint |

#### 3.3.2 Byte-Addressed vs Word Index

A single RV32I address value represents one byte location. However, if the RTL memory is in the form of `logic [31:0] mem [0:DEPTH-1]`, then mem[0] represents a 32-bit word (4 bytes), not a single byte. Therefore, byte addresses cannot be used directly as array indices and must be interpreted as follows:

```
address[31:2] = word index
address[1:0]  = byte lane
```

| Byte Address | Word Index address[31:2] | Byte Lane address[1:0] | Meaning |
|---|---|---|---|
| 0x00000000 | 0 | 00 | byte 0 of word 0 |
| 0x00000001 | 0 | 01 | byte 1 of word 0 |
| 0x00000002 | 0 | 10 | byte 2 of word 0 |
| 0x00000003 | 0 | 11 | byte 3 of word 0 |
| 0x00000004 | 1 | 00 | byte 0 of word 1 |

#### 3.3.3 Byte Lane / Sign Extension / Zero Extension

Even though Data RAM is composed of 32-bit words, RV32I load/store instructions support access in byte, halfword, and word units. Therefore, the byte lane within a 32-bit word must be selected using address[1:0]. Since load instructions must store the read value into a 32-bit register, sign extension or zero extension is performed depending on the data width and signedness.

| Item | Reason Needed | Meaning |
|---|---|---|
| byte lane | Need to select byte/halfword position within a single 32-bit word | Selects the byte position within the word using address[1:0] |
| sign extension | Extends signed load results to a 32-bit register value | Copies MSB to upper bits |
| zero extension | Extends unsigned load results to a 32-bit register value | Fills upper bits with 0 |

| Instruction | Read Size | Extension Method | Result |
|---|---|---|---|
| lb | 8-bit | sign extension | 32-bit signed value |
| lh | 16-bit | sign extension | 32-bit signed value |
| lw | 32-bit | No extension | 32-bit value |
| lbu | 8-bit | zero extension | 32-bit unsigned value |
| lhu | 16-bit | zero extension | 32-bit unsigned value |

### 3.5 ISA Perspective and Instruction Decode Prerequisites

ISA defines the execution rules between software and hardware. From a software perspective, it defines what instructions can represent program operations. From a compiler perspective, it defines how C code operations, branches, and memory accesses are converted into instruction sequences. From a hardware perspective, it defines how the CPU interprets bit fields of an instruction and performs internal operations. From a memory perspective, it defines how addresses are interpreted as units and how load/store operations are executed.
| Perspective | What ISA Defines | Connection to RV32I |
|---|---|---|
| Software perspective | How program behavior can be expressed in terms of instructions | Express operations, memory access, branching, and jumps using RV32I instructions |
| Compiler perspective | How to translate C code operations, branching, and memory access into instructions | Convert arithmetic operations, load/store, conditionals, and loops into RV32I instruction sequences |
| Hardware perspective | What bit fields the CPU reads and what actions it performs | Decode opcode, funct3, funct7, rs1, rs2, rd, imm fields |
| Memory perspective | How addresses are interpreted in terms of units and how load/store operations are performed | Interpret byte-addressed addresses and load/store access widths |

### 3.6 32-bit Machine Instruction Examples

RV32I instructions are stored in the Instruction Memory as 32-bit machine instructions. The value that the CPU actually fetches is not assembly code in string form, but a 32-bit instruction converted according to RV32I encoding rules.

The meaning of `addi x5, x0, 10` in assembly is as follows:

```
x5 = x0 + 10
```

The 32-bit machine instruction stored in the Instruction Memory can be interpreted as follows:

```
000000001010 00000 000 00101 0010011
```

| Field | Bit range | Value | Meaning |
|---|---|---|---|
| imm[11:0] | [31:20] | 000000001010 | Immediate value 10 |
| rs1 | [19:15] | 00000 | x0 |
| funct3 | [14:12] | 000 | addi family operation |
| rd | [11:7] | 00101 | x5 |
| opcode | [6:0] | 0010011 | I-type ALU immediate instruction |

### 3.7 Datapath Configuration Requirements Derivation

The preceding Memory Access Model defines how addresses are interpreted when accessing the Instruction/Data Memory blocks. In contrast, this section's Datapath configuration requirements derive what operation blocks and selection paths are needed for the CPU core to execute instructions internally.

The RV32I CPU fetches machine instructions from the Instruction Memory, decodes instruction fields to generate internal control signals. Since instructions can use register operands, immediate operands, memory addresses, branch/jump targets, etc., the Datapath must have a structure capable of generating and selecting these values. Therefore, the Datapath for this design is configured based on the following requirements:

| Design Requirement | Required Configuration |
|---|---|
| Next instruction address management | Program Counter |
| Store machine instruction to be executed | Instruction Memory |
| Interpret instruction fields and generate control signals | Control Unit |
| Generate formatted immediate values | Immediate Extend |
| Manage source/destination registers | Register File |
| Select register operand or immediate | ALU Source MUX |
| Perform arithmetic/logic operations, address calculation, branch judgment | ALU |
| Store data for load/store targets | Data Memory |
| Select write-back data among ALU result, memory read data, PC + 4 | Register File Source MUX |
| Select next PC among PC + 4, branch target, jump target | PC Source MUX |

### 3.8 CPU Internal Operation Flow

<img width="1196" height="818" alt="image5" src="https://github.com/user-attachments/assets/bdabb13e-b7c9-4d34-813b-4847e84f78b6" />

| Block | Role |
|---|---|
| Program Counter | Provides current instruction address to ROM, updates next instruction address |
| Immediate Extend | Expands constant fields within the instruction to a 32-bit immediate value; immediate is a constant value directly included in the instruction |
| Register File | Reads source register values, stores execution results |
| ALU MUX | Selects register value or immediate value based on ALU second input |
| ALU | Performs arithmetic/logic operations, calculates RAM access address for load/store |
| Register File Source MUX | Selects write-back value among ALU result, RAM data, PC-related values; finally reflects execution result in register |

The overall flow is as follows:

```
Program Counter -> Provides the fetch address to Instruction Memory
-> Outputs the 32-bit machine instruction -> Control Unit decodes opcode, funct3, and funct7
-> Register File outputs the rs1 and rs2 operands -> Immediate Extend generates the immediate
-> ALU Source MUX selects the ALU operand -> ALU performs operations, address calculation, and branch comparison
-> Data Memory performs load/store -> Register File Source MUX selects the write-back data
-> PC Source MUX selects the next PC -> Program Counter is updated
```

The Program Counter provides the instruction fetch address to the Instruction Memory. The Instruction Memory outputs the 32-bit machine instruction stored at that address. The Control Unit interprets the opcode, funct3, and funct7 of the instruction to generate control signals required for ALU input selection, memory control, write-back selection, and next PC selection. The Register File outputs the source operand corresponding to the rs1, rs2 fields, and the Immediate Extend generates an immediate value matching the instruction format. The ALU performs arithmetic operations, logic operations, address calculation, and branch comparison according to control signals. The value to be stored in the register among the operation result, Data Memory read data, and PC + 4 is selected by the Register File Source MUX. The next PC value is selected from PC + 4, branch target, or jump target by the PC Source MUX and updated in the Program Counter.

## 4. RV32I Instruction Type Design and Verification

### 4.1 RV32I Instruction Type Definitions

RV32I expresses all instructions as 32-bit fixed-length formats, but since the required operand configurations differ depending on the instruction purpose, it uses R/I/S/B/U/J-type instruction formats.

| Type | Bit field structure | Representative usage |
|---|---|---|
| R-type | funct7 rs2 rs1 funct3 rd opcode | Register-register operations |
| I-type | imm[11:0] rs1 funct3 rd opcode | Immediate operations, load, jalr |
| S-type | imm[11:5] rs2 rs1 funct3 imm[4:0] opcode | Store |
| B-type | imm[12,10:5] rs2 rs1 funct3 imm[4:1,11] opcode | Conditional branch |
| U-type | imm[31:12] rd opcode | Upper immediate |
| J-type | imm[20,10:1,11,19:12] rd opcode | Jump |

### 4.2 Immediate Field and Immediate Extend
Immediate is an operand that includes constant values and memory offsets required for program execution within the instruction. While RV32I instructions use a 32-bit fixed length, the position of the immediate field varies by instruction format.

The I-type uses imm[11:0] as a contiguous field. The S-type divides the immediate into two segments because it requires rs2 for store operations but does not need rd. B-type and J-type split the immediate bits across multiple fields to represent branch or jump target offsets. Therefore, an Immediate Extend block is required to extract the immediate value based on the instruction format and perform sign extension or shifting to make it usable for 32-bit operations.

| Type | Immediate Usage |
|---|---|
| I-type | ALU operand, load offset, jalr target offset |
| S-type | store address offset |
| B-type | branch target offset |
| U-type | upper 20-bit immediate |
| J-type | jump target offset |

### 4.3 Type-Specific Datapath Operation and Verification

Describing types is not a step of defining new structures, but rather verifying which path among the previously defined datapaths becomes active. In this design, conditional auxiliary instructions and actual program execution images were used together to verify type-specific control signals, ALU paths, memory paths, write-back paths, and PC update paths.

Verification for all types except R-Type and I-Type Arithmetic was conducted simultaneously.

#### 4.3.1 R-type

R-type instruction fields are composed in the order of funct7 / rs2 / rs1 / funct3 / rd / opcode (each representing: operation distinction field, second source register, first source register, large operation family distinction, destination register, instruction group distinction field).

| Instruction | Operation | Operation Description |
|---|---|---|
| ADD | rd = rs1 + rs2 | Addition |
| SUB | rd = rs1 - rs2 | Subtraction |
| AND | rd = rs1 & rs2 | Logical AND |
| OR | rd = rs1 \| rs2 | Logical OR |
| XOR | rd = rs1 ^ rs2 | Exclusive OR |
| SLL | rd = rs1 << rs2 | Logical left shift |
| SRL | rd = rs1 >> rs2 | Logical right shift |
| SRA | rd = rs1 >> rs2 | Arithmetic right shift, msb-extends |
| SLT | rd = (rs1 < rs2) ? 1 : 0 | Signed comparison result storage |
| SLTU | rd = (rs1 < rs2) ? 1 : 0 | Unsigned comparison result storage |

R-type instructions read two registers to perform ALU operations in the format of writing the result back to rd, similar to add, sub, and, or.

```
rd = rs1 op rs2
PC = PC + 4
```

<img width="2048" height="1681" alt="image6" src="https://github.com/user-attachments/assets/af54a53c-1335-4b03-bf52-24031b3cb494" />

##### 4.3.1.1 Control Unit

| Signal Name | Value | Description |
|---|---|---|
| opcode[6:0] | R_TYPE | Register-Register ALU operation |
| rf_we | 1 | Store operation result to Register File |
| alu_src_sel | 0 | Select RD2 as ALU input B |
| alu_control | {funct7[5], funct3} | Determine ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND |
| rf_src_sel | 0 | ALU result write-back |
| mem_mode | 0 | Data RAM not used |
| dwe | 0 | Memory write disabled |
| branch | 0 | Branch not executed |
| JAL | 0 | Jump not executed |
| JALR | 0 | Jump Register not executed |

##### 4.3.1.2 DataPath

| Block | Input | Output | Description |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | R-Type instruction fetch |
| Control Unit | opcode, funct3, funct7[5] | alu_control, rf_we, alu_src_sel, rf_src_sel | Generate R-Type control signals |
| Register File | rs1, rs2 | RD1, RD2 | Read two source registers |
| ALU MUX | RD2 / imm_extend | alu_RD2 | Select RD2 because alu_src_sel=0 |
| ALU | RD1, RD2 | alu_result | Perform register-register operation |
| Write Back MUX | alu_result | WD | rf_src_sel=0 |
| Register File | WD | rd storage | Store result |

Reads two register values, calculates them in the ALU, and records the result back to the destination register. The program counter is updated to the current address + 4 bytes (instruction size) for the next instruction execution.

| Condition | PC Output |
|---|---|
| General R-Type Execution | PC + 4 |

##### 4.3.1.3 Verification

<img width="1920" height="342" alt="image7" src="https://github.com/user-attachments/assets/6f4dd2c6-fef2-4609-af57-ead8401b69b1" />

| Category | ADD x5, x2, x3 | SUB x5, x2, x3 | AND x5, x2, x3 | OR x5, x2, x3 | XOR x5, x2, x3 |
|---|---|---|---|---|---|
| Operation | 2 + 3 | 2 - 3 | 2 & 3 | 2 \| 3 | 2 ^ 3 |
| Expected Result | x5 = 5 | x5 = -1 | x5 = 2 | x5 = 3 | x5 = 1 |
| Operation Description | Addition | Subtraction | Logical AND | Logical OR | Exclusive OR |

<img width="1920" height="326" alt="image8" src="https://github.com/user-attachments/assets/a24bbd5f-100f-4121-a427-ecf2af9f9b47" />

| Category | SLL x5, x2, x3 | SRL x5, x10, x11 | SRA x5, x10, x11 | SLT x5, x10, x11 | SLTU x5, x10, x11 |
|---|---|---|---|---|---|
| Operation | 2 << 3 | 0xffffffff >> 1 (logical) | 0xffffffff >>> 1 (arithmetic) | -1 < 1 | 0xffffffff < 0x00000001 (unsigned) |
| Expected Result | x5 = 0x70000010 | x5 = 0x7fffffff | x5 = 0xffffffff | x5 = 0x70000001 | x5 = 0x70000000 |
| Operation | Logical left shift | Logical right shift | Arithmetic right shift msb-extends | Signed comparison result storage | Unsigned comparison result storage |

#### 4.3.2 I-Type Arithmetic

<img width="2048" height="1681" alt="image9" src="https://github.com/user-attachments/assets/34688843-c036-4dcd-b814-c396f30d630a" />

I-type instruction fields are composed in the order of imm[11:0] / rs1 / funct3 / rd / opcode (each representing: constant or shift amount field, first source register, operation distinction field, destination register, instruction group distinction field).
| Command | Operation | Operation Description |
|---|---|---|
| ADDI | rd = rs1 + imm | immediate addition |
| ANDI / ORI / XORI | rd = rs1 op imm | immediate logical operation |
| SLLI / SRLI / SRAI | rd = rs1 shift imm[4:0] | immediate-based shift operation |
| SLTI / SLTIU | rd = (rs1 < imm) ? 1 : 0 | signed or unsigned immediate comparison |

The arithmetic immediate family reads the rs1 value from the Register File and selects the imm value created by Immediate Extend as ALU input B. Data Memory is not used, and the ALU result is written to the rd in the Register File.

##### 4.3.2.1 Control Unit

| Signal Name | Value | Description |
|---|---|---|
| opcode[6:0] | I_TYPE | Immediate ALU operation instruction |
| rf_we | 1 | Store ALU result to rd |
| alu_src_sel | 1 | Select immediate as ALU input B |
| alu_control | based on funct3, uses funct7[5] for shifts | Determines ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI |
| rf_src_sel | 0 | ALU result write-back |
| mem_mode | 0 | Data Memory not used |
| dwe | 0 | Memory write disabled |
| branch / JAL / JALR | 0 | Disable branch and jump paths |

##### 4.3.2.2 DataPath

| Block | Input | Output | Description |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | I-Type arithmetic instruction fetch |
| Register File | rs1 | RD1 | source register read |
| Immediate Extend | instr[31:20] | imm | Expand 12-bit immediate to 32-bit |
| ALU MUX | RD2 / imm | imm selection | alu_src_sel=1 |
| ALU | RD1, imm | alu_result | Perform immediate operation |
| Write Back MUX | alu_result | WD | rf_src_sel=0 |
| Register File | WD | rd store | ALU result write-back |
| Program Counter | current PC | PC + 4 | Move to next sequential instruction |

##### 4.3.2.3 Verification

<img width="960" height="176" alt="image10" src="https://github.com/user-attachments/assets/5f4062da-aba4-4e5f-9c83-c405df1c7a85" />

<img width="960" height="149" alt="image11" src="https://github.com/user-attachments/assets/17665e15-e864-4a43-9d71-7ec5ec9a2592" />

Verified using I-type Arithmetic verification waveforms, additional verification waveforms, and a results table.

#### 4.3.3 I-Type Load

The I-type Load instruction fields are composed in the order of imm[11:0] / rs1 / funct3 / rd / opcode (each representing load address offset / base address register / load width and extension mode distinction / destination register / load instruction group distinction field).

| Command | Read Size | Extension Mode | Operation Description |
|---|---|---|---|
| LB | 8-bit | sign extension | Read byte at rs1 + imm address and store to rd |
| LH | 16-bit | sign extension | Read halfword at rs1 + imm address and store to rd |
| LW | 32-bit | no extension | Read word at rs1 + imm address and store to rd |
| LBU | 8-bit | zero extension | unsigned byte load |
| LHU | 16-bit | zero extension | unsigned halfword load |

The Load family calculates rs1 + imm in the ALU like arithmetic immediate, but does not store this result directly to rd; instead, it uses it as a Data Memory address. The drdata read from memory is stored to rd via the Write Back MUX, and funct3 determines the load width and sign/zero extension mode.

<img width="2048" height="1680" alt="image12" src="https://github.com/user-attachments/assets/5b3fed82-5d85-4783-9766-fe02620eaca0" />

##### 4.3.3.1 Control Unit

| Signal Name | Value | Description |
|---|---|---|
| opcode[6:0] | LI_TYPE | Load instruction |
| rf_we | 1 | Store memory read result to rd |
| alu_src_sel | 1 | Select immediate as ALU input B |
| alu_control | ADD | Calculate effective address = rs1 + imm |
| rf_src_sel | 1 | Data Memory read data write-back |
| mem_mode | funct3 | Distinguish LB, LH, LW, LBU, LHU and extension mode |
| dwe | 0 | Memory write disabled |
| branch / JAL / JALR | 0 | Disable branch and jump paths |

##### 4.3.3.2 DataPath

| Block | Input | Output | Description |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | Load instruction fetch |
| Register File | rs1 | RD1 | base register read |
| Immediate Extend | instr[31:20] | imm | Generate load offset |
| ALU MUX | RD2 / imm | imm selection | alu_src_sel=1 |
| ALU | RD1, imm | alu_result | Calculate Data Memory effective address |
| Data Memory | daddr=alu_result, mem_mode | drdata | Byte/halfword/word read and extension |
| Write Back MUX | drdata | WD | rf_src_sel=1 |
| Register File | WD | rd store | load result write-back |
| Program Counter | current PC | PC + 4 | Move to next sequential instruction |

#### 4.3.4 I-Type JALR

The I-type JALR instruction fields are composed in the order of imm[11:0] / rs1 / funct3 / rd / opcode (each representing jump target offset / jump base register / JALR format distinction field / return address storage register / JALR instruction group distinction field).

| Command | Operation | Operation Description |
|---|---|---|
| JALR | rd = PC + 4; PC = rs1 + imm | Register indirect jump and return address storage |

JALR uses the I-type format but differs from general ALU write-back or load in that the Program Counter path is central. It adds the rs1 value and immediate to create the next PC, while simultaneously storing PC + 4 (the address of the instruction following the current one) to rd, enabling it to be used as a function return address.

<img width="2048" height="1680" alt="image13" src="https://github.com/user-attachments/assets/38243cc6-294e-4040-86ea-c583ef17d2d6" />

##### 4.3.4.1 Control Unit
| Signal Name | Value | Description |
|---|---|---|
| opcode[6:0] | JL_TYPE | JALR instruction |
| rf_we | 1 | Store PC + 4 to rd |
| alu_src_sel | 0 | ALU path is effectively unused |
| alu_control | ADD | Maintain current RTL default value |
| rf_src_sel | 4 | pc_next, i.e., PC + 4 write-back |
| mem_mode | 0 | Data Memory not used |
| dwe | 0 | Memory write disabled |
| branch | 0 | Not a conditional branch |
| JAL | 1 | Jump path active |
| JALR | 1 | PC update based on rs1 + imm |

##### 4.3.4.2 DataPath

| Block | Input | Output | Description |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | JALR instruction fetch |
| Register File | rs1 | RD1 | Read jump base register |
| Immediate Extend | instr[31:20] | imm | Generate jump offset |
| Program Counter | RD1, imm, JALR | pc_out, pc_next | pc_out is rs1 + imm, pc_next is PC + 4 |
| Write Back MUX | pc_next | WD | rf_src_sel=4 |
| Register File | WD | rd store | Store return address |

#### 4.3.5 S-type

S-type instruction fields are composed in the order of imm[11:5] / rs2 / rs1 / funct3 / imm[4:0] / opcode (each corresponding to store offset upper field / data register to be stored / base address register / store width distinguishing field / store offset lower field / store instruction group distinguishing field).

| Instruction | Operation | Operation Description |
|---|---|---|
| SB | M[rs1 + imm][7:0] = rs2[7:0] | byte store |
| SH | M[rs1 + imm][15:0] = rs2[15:0] | halfword store |
| SW | M[rs1 + imm][31:0] = rs2[31:0] | word store |

S-type is a format that stores register values into Data Memory. Since rd is not required, the rd field position is used for imm[4:0], and instr[31:25] is used for imm[11:5] to construct the store offset.

<img width="2048" height="1680" alt="image14" src="https://github.com/user-attachments/assets/1bc2ea0e-91ee-4f98-b995-a5d5292fe135" />

##### 4.3.5.1 Control Unit

| Signal Name | Value | Description |
|---|---|---|
| opcode[6:0] | S_TYPE | Memory Store instruction |
| rf_we | 0 | No Register File write-back |
| alu_src_sel | 1 | Select ALU input B as immediate value |
| alu_control | ADD | Calculate address rs1 + imm |
| rf_src_sel | 0 | Unused |
| mem_mode | funct3 | Distinguish SB, SH, SW |
| dwe | 1 | Memory write active |
| branch/JAL/JALR | 0 | Not a PC-changing instruction |

##### 4.3.5.2 DataPath

| Block | Input | Output | Description |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | S-Type instruction fetch |
| Register File | rs1, rs2 | RD1, RD2 | Read base register and store data |
| Immediate Extend | store immediate field | imm | Generate store offset |
| ALU | RD1, imm | alu_result | Calculate effective address |
| Data Memory | daddr, dwdata, mem_mode, dwe | memory update | Perform store |

Calculate RAM address as rs1 + imm and store the rs2 value at that RAM location.

| Condition | PC Output |
|---|---|
| Normal S-Type execution | PC + 4 |

#### 4.3.6 B-type

B-type instruction fields are composed in the order of imm[12,10:5] / rs2 / rs1 / funct3 / imm[4:1,11] / opcode (each corresponding to branch offset upper/middle field / second comparison register / first comparison register / branch condition distinguishing field / branch offset lower/rearrange field / branch instruction group distinguishing field).

| Instruction | Operation | Operation Description |
|---|---|---|
| BEQ | if (rs1 == rs2) PC += imm | Branch if equal |
| BNE | if (rs1 != rs2) PC += imm | Branch if not equal |
| BLT | if (rs1 < rs2) PC += imm | Branch if signed less than |
| BGE | if (rs1 >= rs2) PC += imm | Branch if signed greater or equal |
| BLTU | if (rs1 < rs2) PC += imm | Branch if unsigned less than |
| BGEU | if (rs1 >= rs2) PC += imm | Branch if unsigned greater or equal |

B-type is a format that compares two registers and selects the next PC based on whether the condition is satisfied. There are no result registers or memory access; the core results are b_taken and the next PC.

<img width="2048" height="1682" alt="image15" src="https://github.com/user-attachments/assets/16f99138-3e2d-49fd-9d5a-b2c3d2e4d970" />

##### 4.3.6.1 Control Unit

| Signal Name | Value | Description |
|---|---|---|
| opcode[6:0] | B_TYPE | Conditional branch instruction |
| rf_we | 0 | No Register File write-back |
| alu_src_sel | 0 | Select RD2 as ALU input B |
| alu_control | {1'b0, funct3} | Determine branch compare type |
| rf_src_sel | 0 | Do not use write-back path |
| mem_mode/dwe | 0 | Data RAM not used |
| branch | 1 | Branch judgment active |
| JAL/JALR | 0 | Not a jump |

##### 4.3.6.2 DataPath

| Block | Input | Output | Description |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | B-Type instruction fetch |
| Register File | rs1, rs2 | RD1, RD2 | Read two registers to compare |
| ALU | RD1, RD2 | b_taken | Generate branch condition comparison result |
| Immediate Extend | branch immediate field | imm | Generate branch offset |
| Program Counter | b_taken, imm | pc_out | Determine next PC based on taken status |

Compare rs1 and rs2 to create the branch condition, and select the next PC as either PC + 4 or PC + imm based on that result.

| Condition | PC Output |
|---|---|
| branch=1, b_taken=0 | PC + 4 |
| branch=1, b_taken=1 | PC + imm |

#### 4.3.7 U-Type LUI

U-type LUI instruction fields are composed in the order of imm[31:12] / rd / opcode (each corresponding to upper immediate field / destination register / LUI instruction group distinguishing field).

| Instruction | Operation | Operation Description |
|---|---|---|
| LUI | rd = imm << 12 | Directly record 20-bit upper immediate into rd |
LUI is an instruction that creates the immediate value itself as a register within the U-type format. It does not use rs1, rs2, funct3, or funct7; instead, it extends the instr[31:12] field into the upper immediate value from Immediate Extend and writes it to rd.

<img width="2048" height="1682" alt="image16" src="https://github.com/user-attachments/assets/ca2e0a4d-7a1d-46ca-89bd-0bd70312ee43" />

##### 4.3.7.1 Control Unit

| Signal Name | Value | Description |
|---|---|---|
| opcode[6:0] | U_TYPE | LUI instruction |
| rf_we | 1 | Store immediate value to rd |
| rf_src_sel | 2 | imm_extend write-back |
| alu_src_sel / alu_control | Not used / ADD default | Do not write back ALU result |
| mem_mode / dwe / branch / JAL / JALR | 0 | Disable memory, branch, and jump paths |

##### 4.3.7.2 DataPath

| Block | Input | Output | Description |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | LUI instruction fetch |
| Control Unit | opcode | rf_we, rf_src_sel | Generate LUI control signals |
| Immediate Extend | instr[31:12] | imm_extend | Generate upper immediate |
| Write Back MUX | imm_extend | WD | rf_src_sel=2 |
| Register File | WD | rd store | Upper immediate write-back |
| Program Counter | Current PC | PC + 4 | Move to next sequential instruction |

#### 4.3.8 U-Type AUIPC

The U-type AUIPC instruction field is composed of imm[31:12] / rd / opcode in order (each representing the upper immediate field added to PC, destination register, and AUIPC instruction group discriminator field).

| Instruction | Operation | Operation Description |
|---|---|---|
| AUIPC | rd = PC + (imm << 12) | Store PC-relative upper immediate address value in rd |

AUIPC uses the U-type format but, unlike LUI, does not store the immediate directly; instead, it records the sum of the current PC and the immediate into rd. In this case, PC + imm is the write-back data, not the next PC; after instruction execution, the actual PC proceeds to PC + 4.

<img width="2048" height="1682" alt="image17" src="https://github.com/user-attachments/assets/a89bda09-9d0d-4030-8ba9-183489f868ae" />

##### 4.3.8.1 Control Unit

| Signal Name | Value | Description |
|---|---|---|
| opcode[6:0] | AU_TYPE | AUIPC instruction |
| rf_we | 1 | Store PC + imm value in rd |
| rf_src_sel | 3 | pc_imm write-back |
| alu_src_sel / alu_control | Not used / ADD default | Do not write back ALU result |
| mem_mode / dwe / branch / JAL / JALR | 0 | Disable memory, branch, and jump paths |

##### 4.3.8.2 DataPath

| Block | Input | Output | Description |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | AUIPC instruction fetch |
| Control Unit | opcode | rf_we, rf_src_sel | Generate AUIPC control signals |
| Immediate Extend | instr[31:12] | imm_extend | Generate upper immediate |
| Program Counter | Current PC, imm_extend | pc_imm | Generate PC + imm write-back value |
| Write Back MUX | pc_imm | WD | rf_src_sel=3 |
| Register File | WD | rd store | PC-relative value write-back |
| Program Counter | Current PC | PC + 4 | Move to next sequential instruction |

#### 4.3.9 J-type

The J-type instruction field is composed of imm[20,10:1,11,19:12] / rd / opcode in order (each representing the jump target offset field, return address storage register, and JAL instruction group discriminator field).

| Instruction | Operation | Operation Description |
|---|---|---|
| JAL | rd = PC + 4; PC = PC + imm | Simultaneously perform PC-relative jump and link |

J-type simultaneously performs an unconditional jump and return address storage. rs1 and rs2 are not used; the jump immediate field and rd are key. rd stores PC + 4, and PC is updated to PC + imm.

<img width="2048" height="1680" alt="image18" src="https://github.com/user-attachments/assets/7fcde526-ab93-43ed-b8c5-1ccb56d9d30d" />

##### 4.3.9.1 Control Unit

| Signal Name | Value | Description |
|---|---|---|
| opcode[6:0] | J_TYPE | JAL |
| rf_we | 1 | Store PC + 4 in Register File |
| alu_src_sel | 0 | ALU path not used |
| alu_control | ADD | Maintain current RTL default |
| rf_src_sel | 4 | pc_next write-back |
| mem_mode / dwe / branch | 0 | Do not use Data RAM or branch |
| JAL | 1 | Enable jump path |
| JALR | 0 | Not register-relative jump |

##### 4.3.9.2 DataPath

| Block | Input | Output | Description |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | JAL fetch |
| Immediate Extend | jump immediate field | imm | Generate jump offset |
| Program Counter | pc_in, imm | pc_out, pc_next | Generate jump target and PC + 4 |
| Write Back MUX | pc_next | WD | rf_src_sel=4 |
| Register File | WD | rd store | Store return address |

Jump to PC + imm and simultaneously record PC + 4 into the destination rd.

| Condition | PC Output |
|---|---|
| JAL=1 | PC + imm |
| write-back value | PC + 4 |

#### 4.3.10 Type-Specific Integrated Verification

R-type and I-Type Arithmetic were individually verified with criteria in the preceding section. The remaining types are integrated for verification based on memory access, PC update, and write-back source selection as shown in the following table.
| Verification Target | Observation Criteria | Expected Result |
|---|---|---|
| I-Type Load | alu_src_sel=1, alu_control=ADD, rf_src_sel=1, mem_mode=funct3 | Data Memory read data at address rs1 + imm is stored in rd |
| I-Type JALR | JAL=1, JALR=1, rf_src_sel=4 | PC is updated to rs1 + imm, and rd stores PC + 4 |
| S-type | dwe=1, mem_mode=funct3, rf_we=0 | Value of rs2 is written to Data Memory at address rs1 + imm |
| B-type | branch=1, b_taken observed | When condition is satisfied, PC + imm is selected; otherwise, PC + 4 is selected |
| U-Type LUI | rf_we=1, rf_src_sel=2 | Immediate Extend result is stored in rd, and PC advances to PC + 4 |
| U-Type AUIPC | rf_we=1, rf_src_sel=3 | Result of PC + imm is stored in rd, and next PC is PC + 4 |
| J-type | JAL=1, rf_src_sel=4 | PC is updated to PC + imm, and rd stores PC + 4 |

<img width="2048" height="169" alt="image19" src="https://github.com/user-attachments/assets/703ead29-c55e-494a-ac1f-32904e98e39a" />

<img width="2048" height="244" alt="image20" src="https://github.com/user-attachments/assets/fa8e11f3-4250-4aae-adb1-4269cf3d7053" />

<img width="2048" height="200" alt="image21" src="https://github.com/user-attachments/assets/969c0d54-2ab0-49c6-924f-97937db2f318" />

The integrated verification results were confirmed using Store-type, Branch-type, and Upper/Jump-type simulation waveforms.

## 5. C Program Execution Analysis

In the presentation, a counter summing from 0 to 10 was used as the central case study. This report specifically explains the flow where C code leads to assembly, machine instructions, memory initialization files, and waveform observation results based on this case study.

The previous section verified which paths of the Datapath are activated for each instruction type. This section expands on the same content from the perspective of actual software execution. Variables, pointers, stack, function calls, conditionals, and loops in C code are observed internally as register operands, immediates, load/store operations, branches, jumps, and memory images by the CPU.

### 5.1 Software Execution Model

#### 5.1.1 Relationship Between C Code, Assembly, Machine Code, and Memory Initialization File

<img width="1911" height="240" alt="image22" src="https://github.com/user-attachments/assets/80203fab-7e5b-4232-9718-82a9cfe5814b" />

The CPU does not execute C source code directly. What the CPU executes is machine instruction encoded according to ISA rules. C code is converted to assembly code by a compiler, and assembly code is converted to machine code by an assembler. Subsequently, the linker determines the address layout of the code section and data section, and the final executable image is converted into a memory initialization file usable in simulation or FPGA environments.

| Stage | Example | Meaning |
|---|---|---|
| C source code | a = b + 10; | High-level program written by humans |
| Assembly code | addi x5, x6, 10 | ISA instruction expressed in a human-readable form |
| Machine instruction | 000000001010 00110 000 00101 0010011 | 32-bit instruction fetched and decoded by the CPU |
| Memory initialization file | 00a30293 | Value used for Instruction Memory initialization |

#### 5.1.2 Relationship Between Register Names and ABI

The RV32I ISA defines 32 integer registers from x0 to x31. Names such as sp, ra, and a0 are not register names defined by the ISA itself but rather purpose-based names defined by the ABI. To interpret function calls, argument passing, return values, and stack frames, both the register numbers of the ISA and the ABI names must be considered together.

| ABI Name | Actual Register | Role |
|---|---|---|
| zero | x0 | Always 0 |
| ra | x1 | Return address |
| sp | x2 | Stack pointer |
| a0-a7 | x10-x17 | Function argument / return value |
| t0-t6 | x5-x7, x28-x31 | Temporary register |
| s0-s11 | x8-x9, x18-x27 | Saved register |

#### 5.1.3 Program Memory and Data Memory Layout

This design is based on Harvard Architecture, separating Instruction Memory and Data Memory. Therefore, machine instructions to be executed are stored in Instruction Memory, and data targeted by load/store instructions is stored in Data Memory. To execute a C program, one must understand the layout of the .text, .data, .bss, and stack regions; this layout connects to the linker script and memory initialization file generation process.

| Region | General Section | Storage Location | Content |
|---|---|---|---|
| Instruction Memory | .text | ROM | Machine instructions to be executed |
| Constant Region | .rodata | ROM or separate memory | Constant data |
| Initialized data | .data | RAM | Global/static variables with initial values |
| Zero-initialized data | .bss | RAM | Global/static variables without initial values |
| Stack | stack region | RAM | Local variables, saved registers, return address |
| Heap | heap region | RAM | Dynamically allocated area |

#### 5.1.4 Memory Allocation Relationship of Internal Variables

Local variables in C code are not always stored in RAM. The compiler assigns variables to registers when possible. However, if the address of a variable is needed, if there are insufficient registers, or if values must be preserved across function call boundaries, they are stored on the stack. Therefore, the relationship between C variables and memory locations varies depending on variable type, compiler optimization, ABI, and stack frame configuration.

| C Variable Type | General Storage Location | Description |
|---|---|---|
| Local variable | register or stack | Compiler may assign to register; stored on stack if needed |
| Local variable whose address is used | stack | Memory location required because accessed via pointer |
| Global variable | .data or .bss | Placed in Data Memory |
| Static local variable | .data or .bss | Survives outside function scope |
| Constant | .rodata | Can be placed in ROM or read-only area |
| Function argument | a0-a7 or stack | Passed according to ABI rules |

### 5.2 Pointer Operation Mechanism

A pointer is a variable that stores a memory address. The operation of dereferencing a pointer is converted into load/store instructions that read or write values in memory using that address. Therefore, although pointers appear as a separate feature of C syntax, they are executed internally by the CPU as a combination of address calculation and memory access.
```c
int x = 10;
int *p = &x;
int y = *p;
```

```
# Assume a0 holds p, which is the address of x
lw a1, 0(a0)    # y = *p
```

| C Expression | Meaning | RV32I Operation |
|---|---|---|
| p = &x | Store the address of variable x in a pointer | Address calculation |
| *p | Read value at the address pointed to by the pointer | lw |
| *p = value | Write value to the address pointed to by the pointer | sw |
| p + 1 | Calculate the address of the next element | p + sizeof(*p) |

RV32I addresses are byte addresses. Therefore, in `int *p`, `p + 1` does not increment the address value by 1, but instead increments it by 4 bytes, which is the size of an int. This is also why the array index in the Bubble Sort example is shifted using `slli index, index, 2`, since one int element occupies 4 bytes.

### 5.3 Stack Pointer and Stack Operation Mode

The Stack Pointer is a register that stores the current top address of the stack area. In the RISC-V ABI, x2 is used as sp. When a function is called, the compiler adjusts the stack pointer to create a stack frame, into which local variables, saved registers, return addresses, and other data can be stored.

```
# Allocate a stack frame on function entry
addi sp, sp, -16
sw   ra, 12(sp)
sw   s0, 8(sp)

# Release the stack frame on function exit
lw   ra, 12(sp)
lw   s0, 8(sp)
addi sp, sp, 16
jalr x0, 0(ra)
```

In the standard RISC-V ABI, the stack increases in the direction of lower addresses. Therefore, when reserving stack space, the value is subtracted from sp by the required size, and it is added back upon function exit. Inside the stack frame, local variables, saved registers, return addresses, and temporary spill values can be placed.

### 5.4 C + Assembly + Memory Comparison

This section summarizes representative patterns of how C syntax translates into assembly instructions and memory operations. The core point is that C code syntax itself does not run directly on the CPU; instead, it is converted into an RV32I instruction sequence, fetched from Instruction Memory, and then executed.

#### 5.4.1 Simple Operations

```c
int y = x + 10;
```
```
addi a1, a0, 10
```

| Element | Description |
|---|---|
| Type | I-type |
| Immediate | Constant 10 |
| ALU Input | rs1, imm |
| Write-back | ALU result -> rd |
| PC | PC + 4 |

#### 5.4.2 Pointer Access

```c
int y = *p;
```
```
lw a1, 0(a0)
```

| Element | Description |
|---|---|
| Type | I-type load |
| Address Calculation | a0 + 0 |
| Memory Access | Data Memory read |
| Write-back | memory read data -> rd |
| Extension | lw is a 32-bit load, so no separate extension is needed |

#### 5.4.3 Local Variable Access

```c
int f(void) {
    int x = 3;
    return x + 1;
}
```

Internal variables are placed in registers or on the stack depending on compiler judgment. If a variable is placed in a register, it is processed using only the ALU and Register File without Data Memory access. Conversely, if placed on the stack, it is accessed using lw/sw instructions with an offset relative to sp or s0.

#### 5.4.4 Function Call / Return

```c
int add(int a, int b) {
    return a + b;
}
int main(void) {
    return add(1, 2);
}
```

| Operation | RV32I Instruction | Description |
|---|---|---|
| Function Call | jal ra, target | ra = PC + 4, PC = target |
| Function Return | jalr x0, 0(ra) | PC = ra |
| Argument Passing | a0, a1 | Use ABI argument registers |
| Return Value | a0 | Use ABI return value register |
| Stack Usage | sp adjustment | Store return address, saved registers as needed |

#### 5.4.5 if Statement

```c
if (a == b) {
    x = 1;
} else {
    x = 0;
}
```
```
beq  a0, a1, equal
addi a2, x0, 0
jal  x0, done
equal:
addi a2, x0, 1
done:
```

The if statement is executed via condition comparison and PC selection. If the condition is true, it branches to the target; otherwise, it proceeds along the path of the next instruction, PC + 4.

#### 5.4.6 for Loop

```c
for (int i = 0; i < n; i++) {
    sum += i;
}
```
```
addi t0, x0, 0      # i = 0
loop:
bge  t0, a0, done   # if i >= n, exit
add  t1, t1, t0     # sum += i
addi t0, t0, 1      # i++
jal  x0, loop
done:
```

| C Component | Assembly Operation |
|---|---|
| Initialization | addi |
| Condition Comparison | bge |
| Loop Body | ALU operation |
| Increment Expression | addi |
| Loop Jump | jal x0, loop |

#### 5.4.7 while Loop

<img width="272" height="265" alt="image23" src="https://github.com/user-attachments/assets/55ef5e86-acfc-4ba7-a543-78b5804cb569" />

<img width="296" height="559" alt="image24" src="https://github.com/user-attachments/assets/a6a72859-54cb-457a-b8d2-a7ed87c40632" />

The while loop checks the condition before entering the loop. The condition check is performed using a B-type branch, and after the loop body, a J-type jump or branch is used to return to the loop label.

### 5.5 Sum Counter from 0 to 10

A counter incrementing from 0 to 10 and its cumulative sum calculation were used as examples to explain software execution flow.

From the simplest counter perspective, C code that initializes a local variable count to 0 and increments it by 1 while the while condition is satisfied serves as the baseline. At the instruction level, this unfolds into local variable load/store, constant comparison, conditional branch, and loop back flow.

The Sum Counting C code, which includes function calls based on this basic code, adds a call to the adder(a, sum) function to the simple counter flow. This allows verification of local variables, loop branches, stack frames, function call/return, and return value write-back simultaneously.

Based on the main() frame, sum is stored at -24(s0) and a at -20(s0). In the waveform, these locations are observed as data_ram[58] and data_ram[59], respectively. Inside the loop, a is loaded, incremented by 1, and stored again. Then, arguments are prepared in a0 and a1 to call adder(). The return value is stored back into sum.

#### 5.5.1 main() Stack Frame and Variable Initialization

<img alt="image25" src="https://github.com/user-attachments/assets/42d20d16-3d20-4379-bbc2-692d4f152971" />
<img alt="image26" src="https://github.com/user-attachments/assets/6e87d34d-740d-4569-88c7-995cde7a28f9" />
| .mem line | Assembly | Meaning |
|---|---|---|
| 10000113 | addi sp, zero, 256 | Set stack start address |
| fe010113 | addi sp, sp, -32 | Create main() stack frame |
| 00112e23 | sw ra, 28(sp) | Store return address |
| 00812c23 | sw s0, 24(sp) | Store frame pointer |
| 02010413 | addi s0, sp, 32 | Set s0 as frame base |
| fe042623 | sw zero, -20(s0) | a = 0 |
| fe042423 | sw zero, -24(s0) | sum = 0 |
| 0200006f | jal zero, +32 | Jump to condition check location |

#### 5.5.2 Loop Body and adder() Call

<img width="1419" height="528" alt="image27" src="https://github.com/user-attachments/assets/459a8a9d-0d47-4dfa-bbbe-553964874c42" />

<img width="1598" height="675" alt="image28" src="https://github.com/user-attachments/assets/d9d62ee0-9287-4d4a-b67b-2f854d9274b1" />

| .mem line | Assembly | Meaning |
|---|---|---|
| fec42783 | lw a5, -20(s0) | Read a |
| 00178793 | addi a5, a5, 1 | a++ |
| fef42623 | sw a5, -20(s0) | Store a |
| fe842583 | lw a1, -24(s0) | Prepare sum as second argument |
| fec42503 | lw a0, -20(s0) | Prepare a as first argument |
| 028000ef | jal ra, +40 | Call adder() |
| fea42423 | sw a0, -24(s0) | Store return value in sum |
| fec42703 | lw a4, -20(s0) | Read a for condition comparison |
| 00900793 | addi a5, zero, 9 | Set comparison threshold to 9 |
| fce7dee3 | bge a5, a4, -36 | If a <= 9, loop back |

The `while (a < 10)` condition is implemented by the compiler as a branch that loops back if `9 >= a`. Therefore, although the C code condition and the assembly comparison direction may appear different, they are semantically equivalent because both result in looping until `a` reaches 10.

#### 5.5.3 adder() Function and Return Value

<img width="1598" height="611" alt="image29" src="https://github.com/user-attachments/assets/62d8c780-b514-4c54-b0c4-e5d20601f74e" />

| .mem line | Assembly | Meaning |
|---|---|---|
| fe010113 | addi sp, sp, -32 | Create adder() stack frame |
| 00112e23 | sw ra, 28(sp) | Store return address |
| 00812c23 | sw s0, 24(sp) | Store frame pointer |
| 02010413 | addi s0, sp, 32 | Set frame base |
| fea42623 | sw a0, -20(s0) | Store argument a |
| feb42423 | sw a1, -24(s0) | Store argument sum |
| fec42703 | lw a4, -20(s0) | Read a |
| fe842783 | lw a5, -24(s0) | Read sum |
| 00f707b3 | add a5, a4, a5 | a + sum |
| 00078513 | addi a0, a5, 0 | Place return value in a0 |
| 00008067 | jalr zero, 0(ra) | Return to caller |

Function calls are performed via `jal ra, target`, which stores PC + 4 in ra and jumps to the function start address. Function returns are executed using `jalr zero, 0(ra)`. According to ABI rules, the return value is placed in a0.

#### 5.5.4 Waveform Observation Criteria

| Observation Item | Final Value | Meaning |
|---|---|---|
| data_ram[58] | 55 | Cumulative sum of 1 + 2 + ... + 10 |
| data_ram[59] | 10 | Variable a at loop termination |

The waveform allows verification of whether `instr_code` is fetched in `.mem line` order, whether sp and s0 create and restore the stack frame, whether a0 and a1 are used as function arguments and return values, and whether PC changes according to jal, bge, and jalr instructions. These results demonstrate that C code's while-based counting and function calls are transformed into RV32I branch, load/store, jal/jalr, and register write-back flows for execution.

## 6. Conclusion and Reflection

Through this project, we established criteria to analyze the RV32I single-cycle CPU not just at the level of simple instruction examples, but from the perspective of executing actual C programs. After clarifying the scope of RISC-V and RV32I, we sequentially connected the single-cycle structure, the rationale for choosing Harvard Architecture, memory access model, instruction decode, datapath composition requirements, and internal CPU operation flow.

Additionally, in design and verification by type, we confirmed that R/I/S/B/U/J-types do not require new structures but rather utilize different paths within an already defined datapath. The necessity of Immediate Extend, ALU Source MUX, Register File Source MUX, and PC Source MUX was also derived from the instruction fields and execution behavior.

Finally, by analyzing the `sum_counting` execution image centrally and using `bubble_sort` as a supplementary case, we verified that C code enters Instruction Memory via assembly, machine instructions, and memory initialization files, and that the CPU fetches, decodes, and executes them. Through this, our design can be summarized as a learning-oriented RV32I CPU implementation capable of structurally explaining the execution path from RTL module implementation to C code -> instruction encoding -> datapath/control -> memory state, beyond just RTL module implementation.

## References

[1] RISC-V Instruction Set Manual, Unprivileged ISA https://docs.riscv.org/reference/isa/v20240411/unpriv/unpriv-index.html

[2] RISC-V ISA Extension Naming Conventions https://docs.riscv.org/reference/isa/unpriv/naming.html

[3] RV codec JS - https://luplab.gitlab.io/rvcodecjs

[4] Compiler Explorer - https://godbolt.org/

[5] RISC-V ASM Viewer - https://riscvasm.lucasteske.dev/
