[English](README.md) | 한국어

# RV32I Single-Cycle CPU

김연우

2026.05.22 ~ 2026.05.27

## 1. 개요 및 설계 범위

### 1.1 목적 및 목표

본 프로젝트의 목적은 RV32I single-cycle CPU를 설계하고, C 소스 코드를 compiler 및 assembler 단계를 거쳐 RV32I machine code hex 형태의 명령어 메모리 초기화 파일로 정리한 뒤 이를 명령어 ROM에 반영하여, 명령어 인출, 제어 흐름 변화, 함수 호출, 데이터 메모리 접근이 RTL 수준에서 어떻게 수행되는지를 분석하는 데 있다. C 소스 코드의 제어 구조와 데이터 구조가 stack frame, 지역 변수 배치, pointer 역참조, 함수 호출 및 복귀, 분기 및 점프 시퀀스로 구체화되는 과정을 CPU datapath 및 control path와 연계하여 기술하는 것을 목표로 하였다. 핵심 목표는 다음과 같다.

- RV32I 기준 32-bit datapath와 control path를 single-cycle 구조로 설계한다.
- instruction_mem, data_mem, rv32i_control, rv32i_datapath, program_counter, register_file, alu의 역할을 분리해 설명한다.
- R/I/S/B/U/J 형식과 JAL/JALR, LB/LBU/LH/LHU/LW, SB/SH/SW를 control/datapath 기준으로 정리한다.
- sum_counting.c 실행 이미지를 중심으로, buble_sort.c를 보조 사례로 활용하여 stack pointer, 지역 변수 배치, pointer, 함수 호출 및 복귀, 비교문 동작을 명령어 수준에서 분석한다.
- 현재 testbench와 waveform 관찰 기준으로 확인 가능한 항목과 검증 한계를 함께 정리한다.

### 1.2 설계 범위

| 구분 | 포함 범위 | 제외 범위 |
|---|---|---|
| CPU 구조 | RV32I single-cycle, 분리형 instruction/data memory | multi-cycle, pipeline, hazard 처리 |
| ISA 범위 | R/I/S/B/U/J, JAL/JALR, byte/halfword/word load-store | M/A/F/D/C 확장 |
| 프로그램 분석 | sum_counting.c, buble_sort.c | compiler backend 상세 구현 |
| 검증 범위 | 현재 tb_rv32i.sv 기반 실행, 내부 신호 관찰, 조건부 보조 명령열 분석 | 자가 판정형(self-checking) scoreboard TB, coverage 기반 검증 |
| 결과 범위 | 시뮬레이션 중심 기능 분석 | 보드 I/O, 별도 FPGA demo |

### 1.3 프로젝트 요약

본 설계는 RV32I 정수 기본 명령어 집합을 대상으로 하는 교육용 single-cycle CPU 구현이다. 최상위 모듈 RV32I는 상위 래퍼 역할을 수행하며, 내부에서 top_rv32i_soc를 인스턴스화하고 그 하위 계층에서 instruction_mem, rv32i_sv, data_mem을 연결한다. 기본 명령어 메모리 초기화 이미지는 buble_sort.mem이며, sum_counting.mem을 대체 실행 이미지로 함께 제공한다. 이에 따라 본 보고서에서는 sum_counting를 통해 함수 호출 및 누적 합 계산 구조를 분석하고, buble_sort를 통해 배열, pointer, 중첩 반복문, 비교 분기, 경계 조건 문제를 종합적으로 기술한다.

### 1.4 설계 사양 요약 (Specification Summary)

| 항목 | 내용 |
|---|---|
| top module | RV32I |
| 내부 SoC top | top_rv32i_soc |
| CPU core | rv32i_sv |
| 데이터 폭 | 32-bit |
| 명령어 폭 | 32-bit |
| 명령어 메모리 | 128 words |
| 데이터 메모리 | 256 words |
| 주소 체계 | byte-addressed |
| 내부 memory index | 주로 addr[31:2] 기반 word index |
| 기본 실행 이미지 | buble_sort.mem |
| 대체 실행 이미지 | sum_counting.mem |
| 설계 목표 | C 프로그램 실행 흐름과 메모리 구조를 분석할 수 있는 single-cycle RV32I CPU 구성 |

### 1.5 AS-IS / TO-BE

| 구분 | AS-IS | TO-BE |
|---|---|---|
| 학습 상태 | 명령어 형식과 기본 datapath를 부분적으로 이해한 상태 | C 프로그램 실행 흐름까지 연결되는 RV32I single-cycle 구조로 통합 |
| 메모리 | word/byte 개념이 혼재되어 설명 일관성이 낮은 상태 | addressing, alignment, byte lane, sign/zero extension을 분리하여 설명 |
| 프로그램 | 개별 명령어 위주의 단편적 설명 | sum_counting, buble_sort 기준 stack, 지역 변수, pointer, 함수 호출 및 복귀까지 설명 |
| 검증 관점 | 단순 실행 또는 부분 파형 확인 중심 | 실행 시나리오와 관찰 신호를 기준으로 검증 범위와 한계를 명시 |

### 1.6 이론 전개와 설계 범위 요약

#### 1.6.1 RISC-V 개요

RISC-V는 UC Berkeley의 다섯 번째 RISC ISA 프로젝트에서 출발한 공개 표준 ISA이다. 명칭의 V는 로마 숫자 5를 의미하므로 RISC-Five로 읽는다. RISC-V는 단순하고 규칙적인 명령어를 조합하여 프로그램 동작을 구성하는 RISC 설계 철학을 기반으로 하며, 명령어 field와 decode 규칙이 비교적 명확해 교육용 CPU 구현에 적합하다.

#### 1.6.2 RISC-V ISA의 모듈형 구조

RISC-V ISA는 하나의 고정된 명령어 집합이 아니라 기본 ISA와 확장 ISA의 조합으로 구성된다. 기본 정수 ISA인 I를 중심으로, 필요에 따라 M, A, C 등의 확장을 선택적으로 추가할 수 있다.

| 표기 | 의미 | 설명 |
|---|---|---|
| I | Integer | 기본 정수 명령어 집합 |
| M | Multiply/Divide | 곱셈 및 나눗셈 확장 |
| A | Atomic | atomic memory operation 확장 |
| C | Compressed | 16-bit 압축 명령어 확장 |

#### 1.6.3 본 설계 범위: RV32I Single-Cycle CPU

본 설계는 RISC-V 기반 32-bit 기본 정수 ISA인 RV32I를 single-cycle 구조로 구현한다. RV32I는 32-bit 정수 레지스터와 32-bit 주소 공간을 사용하는 기본 ISA이며, 기본적인 정수 연산, 분기, jump, load/store 명령어를 포함한다. 본 설계는 CPU 구조 학습과 검증 범위 제한을 목표로 하므로 M, A, C 확장은 제외하고 RV32I만을 구현 대상으로 정의한다.

## 2. 프로젝트 관리 및 개발 환경

### 2.1 일정 계획 (Schedule)

| 단계 | 기간 | 주요 작업 |
|---|---|---|
| 요구사항 정리 | 2026.05.22 | 발표 범위, 보고서 범위, C 코드 분석 대상 확정 |
| 아키텍처 설계 | 2026.05.22 ~ 2026.05.23 | RV32I -> top_rv32i_soc -> instruction_mem/data_mem/core 구조 정리 |
| RTL 정리 | 2026.05.23 | 20260519_rv32i 기준으로 RV32I 프로젝트 구조 정렬, top name 유지 |
| 프로그램 분석 | 2026.05.23 ~ 2026.05.24 | sum_counting.c, buble_sort.c, .mem, disassembly 흐름 정리 |
| 검증 | 2026.05.24 ~ 2026.05.26 | 시뮬레이션 확인 |
| 발표 준비 및 산출물 정리 | 2026.05.25 ~ 2026.05.27 | 완료보고서 작성, 발표 자료 정리 |

### 2.2 개발 및 설계 환경 (Development Environment)

| 분류 | 내용 |
|---|---|
| RTL 언어 | SystemVerilog (.sv) |
| 프로그램 언어 | C |
| FPGA 대상 보드 | Digilent Basys 3 |
| 프로젝트 툴 | Vivado 2020.2 |
| 형상 관리 | Git |

## 3. RV32I 설계 이론 및 CPU 구조

<img width="1672" height="758" alt="image4" src="https://github.com/user-attachments/assets/25139455-6914-4d16-a174-aa139d1a6e04" />

### 3.1 Single-Cycle 구조와 Harvard Architecture 선택

Single-cycle 구조는 한 명령어를 한 clock cycle 안에서 완료하는 방식이다. 이 구조에서는 instruction fetch, decode, register read, ALU 연산, memory access, write-back, PC 갱신을 한 cycle 안에 연결해야 한다. 구조가 단순해 datapath와 control path를 학습하기 좋지만, clock period가 가장 긴 명령어 경로에 맞춰진다는 제약이 있다.

본 설계에서 instruction memory와 data memory를 분리한 이유는 single-cycle 구조의 memory 접근 특성과 관련된다. load/store 명령어는 한 cycle 안에서 다음 명령어 fetch와 data memory access를 모두 필요로 할 수 있다. 단일 memory port를 공유하면 instruction fetch와 data access가 같은 cycle에 충돌할 수 있으므로, 본 설계는 instruction memory와 data memory를 분리한 Harvard Architecture 기반 구조를 사용한다.

| 구조 | 메모리 접근 방식 | 특징 |
|---|---|---|
| Von Neumann | instruction과 data가 동일 memory path 공유 | 단일 구조이지만 single-cycle load/store에서 충돌 가능 |
| Harvard | instruction memory와 data memory 분리 | instruction fetch와 data access 경로 분리 |
| Multi-cycle + Von Neumann | cycle을 나누어 단일 memory 재사용 | 구현 가능하지만 병렬 접근 불가 |

### 3.2 Instruction/Data Memory Block과 접근 규칙 필요성

상위 block diagram에서 memory는 instruction_mem과 data_mem으로 분리된다. Instruction Memory는 Program Counter가 제공하는 instr_addr를 기준으로 현재 실행할 instr_code를 출력하는 ROM 역할을 한다. Data Memory는 ALU가 계산한 daddr를 기준으로 load/store 대상 데이터를 읽거나 쓰는 RAM 역할을 한다. 즉 두 memory block은 Harvard Architecture 때문에 분리되지만, CPU가 전달하는 주소값을 실제 memory array 위치로 해석하는 규칙은 별도로 필요하다.

RV32I는 byte-addressed memory model을 사용하므로 CPU가 생성하는 PC, branch/jump target, load/store address는 모두 byte 단위 주소로 해석된다. 반면 RTL에서 ROM과 RAM은 보통 32-bit word array로 구현된다. 따라서 CPU가 생성한 byte address를 실제 memory array의 word index와 word 내부 byte lane으로 변환하는 규칙이 필요하다.

Memory access rule은 단순한 성능 최적화가 아니다. 핵심 목적은 RV32I의 byte-addressed memory model을 실제 RTL memory 구조에 정확히 매핑하는 것이다. 성능 이슈는 Harvard Architecture 선택과 관련이 있으며, address 해석 규칙은 기능적 정확성을 위해 필요하다.

### 3.3 Memory Access Model

#### 3.3.1 Addressing / Alignment

Addressing은 CPU가 메모리 위치를 어떤 단위의 주소로 표현하는지를 정의한다. RV32I에서 PC와 load/store address는 byte 단위 주소로 표현된다. Alignment는 접근 주소가 데이터 크기에 맞는 경계에 위치하는지를 의미한다.

| 항목 | 필요한 이유 | 의미 |
|---|---|---|
| byte-addressed memory | RV32I 주소는 byte 단위 주소로 정의됨 | PC, branch/jump target, load/store address는 byte 위치 |
| alignment check | 32-bit instruction과 word data는 정렬 주소 접근이 기본 | 접근 크기에 맞게 주소가 정렬되어 있는지 확인 |

| 접근 종류 | 접근 크기 | 정렬 조건 |
|---|---|---|
| Instruction fetch | 4 byte | address [1:0] = 00 |
| lw, sw | 4 byte | address [1:0] = 00 |
| lh, sh | 2 byte | address [0] = 0 |
| lb, sb | 1 byte | 정렬 제약 없음 |

#### 3.3.2 Byte-Addressed vs Word Index

RV32I 주소값 하나는 1 byte 위치를 의미한다. 그러나 RTL memory가 `logic [31:0] mem [0:DEPTH-1]` 형태라면 mem[0]은 1 byte가 아니라 32-bit word, 즉 4 byte를 포함한다. 따라서 byte address를 그대로 array index로 사용할 수 없고, 다음처럼 나누어 해석해야 한다.

```
address[31:2] = word index
address[1:0]  = byte lane
```

| Byte address | Word index address[31:2] | Byte lane address[1:0] | 의미 |
|---|---|---|---|
| 0x00000000 | 0 | 00 | word 0의 byte 0 |
| 0x00000001 | 0 | 01 | word 0의 byte 1 |
| 0x00000002 | 0 | 10 | word 0의 byte 2 |
| 0x00000003 | 0 | 11 | word 0의 byte 3 |
| 0x00000004 | 1 | 00 | word 1의 byte 0 |

#### 3.3.3 Byte Lane / Sign Extension / Zero Extension

Data RAM이 32-bit word 단위로 구성되어 있어도 RV32I load/store 명령어는 byte, halfword, word 단위 접근을 지원한다. 따라서 address[1:0]을 이용해 32-bit word 내부의 byte lane을 선택해야 한다. Load 명령어는 읽은 값을 32-bit register에 저장해야 하므로 데이터 폭과 signed 여부에 따라 sign extension 또는 zero extension을 수행한다.

| 항목 | 필요한 이유 | 의미 |
|---|---|---|
| byte lane | 하나의 32-bit word 안에서 byte/halfword 위치 선택 필요 | address[1:0]로 word 내부 byte 위치 선택 |
| sign extension | signed load 결과를 32-bit register 값으로 확장 | MSB를 상위 bit로 복제 |
| zero extension | unsigned load 결과를 32-bit register 값으로 확장 | 상위 bit를 0으로 채움 |

| 명령어 | 읽는 크기 | 확장 방식 | 결과 |
|---|---|---|---|
| lb | 8-bit | sign extension | 32-bit signed value |
| lh | 16-bit | sign extension | 32-bit signed value |
| lw | 32-bit | 확장 없음 | 32-bit value |
| lbu | 8-bit | zero extension | 32-bit unsigned value |
| lhu | 16-bit | zero extension | 32-bit unsigned value |

### 3.5 ISA 관점과 Instruction Decode 전제

ISA는 소프트웨어와 하드웨어 사이의 실행 규칙이다. 소프트웨어 관점에서는 프로그램 동작을 어떤 명령어로 표현할 수 있는지를 정의하고, 컴파일러 관점에서는 C 코드의 연산, 분기, 메모리 접근을 어떤 instruction sequence로 변환할지를 정의한다. 하드웨어 관점에서는 CPU가 instruction의 bit field를 어떻게 해석하고 어떤 내부 동작을 수행할지를 정의한다. 메모리 관점에서는 주소를 어떤 단위로 해석하고 load/store를 어떻게 수행할지를 정의한다.

| 관점 | ISA가 정의하는 것 | RV32I와의 연결 |
|---|---|---|
| 소프트웨어 관점 | 어떤 명령어로 프로그램 동작을 표현할 수 있는가 | 연산, 메모리 접근, 분기, jump를 RV32I 명령어로 표현 |
| 컴파일러 관점 | C 코드의 연산, 분기, 메모리 접근을 어떤 명령어로 바꿀 것인가 | 산술 연산, load/store, 조건문, 반복문을 RV32I instruction sequence로 변환 |
| 하드웨어 관점 | CPU가 어떤 bit field를 읽고 어떤 동작을 수행할 것인가 | opcode, funct3, funct7, rs1, rs2, rd, imm field를 decode |
| 메모리 관점 | 주소를 어떤 단위로 해석하고 load/store를 어떻게 수행할 것인가 | byte-addressed 주소와 load/store 접근 폭을 해석 |

### 3.6 32-bit Machine Instruction 예시

RV32I 명령어는 Instruction Memory에 32-bit machine instruction으로 저장된다. CPU가 실제로 fetch하는 값은 문자열 형태의 assembly code가 아니라, RV32I encoding 규칙에 따라 변환된 32-bit instruction이다.

`addi x5, x0, 10` 이 assembly의 의미는 다음과 같다.

```
x5 = x0 + 10
```

Instruction Memory에 저장되는 32-bit machine instruction은 다음처럼 해석할 수 있다.

```
000000001010 00000 000 00101 0010011
```

| Field | Bit range | 값 | 의미 |
|---|---|---|---|
| imm[11:0] | [31:20] | 000000001010 | immediate 값 10 |
| rs1 | [19:15] | 00000 | x0 |
| funct3 | [14:12] | 000 | addi 계열 연산 |
| rd | [11:7] | 00101 | x5 |
| opcode | [6:0] | 0010011 | I-type ALU immediate 명령 |

### 3.7 Datapath 구성 요구사항 도출

앞의 Memory Access Model은 Instruction/Data Memory block에 접근할 때 주소를 어떻게 해석할지를 정의한 것이다. 반면 이 절의 Datapath 구성 요구사항은 CPU core 내부에서 instruction을 실행하기 위해 어떤 연산 블록과 선택 경로가 필요한지를 도출하는 단계이다.

RV32I CPU는 Instruction Memory에서 machine instruction을 fetch하고, instruction field를 decode하여 내부 제어 신호를 생성해야 한다. 명령어는 register operand, immediate operand, memory address, branch/jump target 등을 사용할 수 있으므로, Datapath는 이러한 값을 생성하고 선택할 수 있는 구조를 가져야 한다. 따라서 본 설계의 Datapath는 다음 요구사항을 기준으로 구성한다.

| 설계 요구사항 | 필요 구성 |
|---|---|
| 다음 명령어 주소 관리 | Program Counter |
| 실행할 machine instruction 저장 | Instruction Memory |
| 명령어 field 해석 및 제어 신호 생성 | Control Unit |
| 형식별 immediate 생성 | Immediate Extend |
| source/destination register 관리 | Register File |
| register operand 또는 immediate 선택 | ALU Source MUX |
| 산술 연산, 논리 연산, 주소 계산, 분기 판단 | ALU |
| load/store 대상 데이터 저장 | Data Memory |
| ALU 결과, memory read data, PC + 4 중 write-back data 선택 | Register File Source MUX |
| PC + 4, branch target, jump target 중 next PC 선택 | PC Source MUX |

### 3.8 CPU 내부 동작 흐름

<img width="1196" height="818" alt="image5" src="https://github.com/user-attachments/assets/bdabb13e-b7c9-4d34-813b-4847e84f78b6" />

| 블록 | 역할 |
|---|---|
| Program Counter | 현재 instruction 주소 ROM에 제공, 다음 instruction 주소 갱신 |
| Immediate Extend | 명령어 내부 상수 필드를 32-bit immediate 값으로 확장, immediate는 명령어 안에 직접 포함된 상수 값 |
| Register File | source register 값 read, 실행 결과 저장 |
| ALU MUX | ALU 두 번째 입력값에 따라서 register 값 또는 immediate 값 선택 |
| ALU | 산술/논리 연산 수행, load/store용 RAM 접근 주소 계산 |
| Register File Source MUX | ALU 결과, RAM data, PC 관련 값 중 write-back 값 선택, 실행 결과를 register에 최종 반영 |

전체 흐름은 다음과 같다.

```
Program Counter -> Instruction Memory에 fetch address 제공
-> 32-bit machine instruction 출력 -> Control Unit에서 opcode, funct3, funct7 해석
-> Register File에서 rs1, rs2 operand 출력 -> Immediate Extend에서 immediate 생성
-> ALU Source MUX에서 ALU operand 선택 -> ALU에서 연산, 주소 계산, branch 비교 수행
-> Data Memory에서 load/store 수행 -> Register File Source MUX에서 write-back data 선택
-> PC Source MUX에서 next PC 선택 -> Program Counter 갱신
```

Program Counter는 Instruction Memory에 명령어 fetch 주소를 제공한다. Instruction Memory는 해당 주소에 저장된 32-bit machine instruction을 출력한다. Control Unit은 instruction의 opcode, funct3, funct7을 해석하여 ALU 입력 선택, memory 제어, write-back 선택, next PC 선택에 필요한 제어 신호를 생성한다. Register File은 rs1, rs2 field에 해당하는 source operand를 출력하고, Immediate Extend는 instruction 형식에 맞는 immediate 값을 생성한다. ALU는 제어 신호에 따라 산술 연산, 논리 연산, 주소 계산, branch 비교를 수행한다. 연산 결과, Data Memory read data, PC + 4 중 register에 저장할 값은 Register File Source MUX에서 선택된다. 다음 PC 값은 PC + 4, branch target, jump target 중 PC Source MUX에서 선택되어 Program Counter에 갱신된다.

## 4. RV32I 명령어 Type별 설계 및 검증

### 4.1 RV32I Instruction Type 정의

RV32I는 모든 명령어를 32-bit 고정 길이로 표현하지만, 명령어 목적에 따라 필요한 operand 구성이 다르므로 R/I/S/B/U/J-type instruction format을 사용한다.

| Type | Bit field 구조 | 대표 용도 |
|---|---|---|
| R-type | funct7 rs2 rs1 funct3 rd opcode | register-register 연산 |
| I-type | imm[11:0] rs1 funct3 rd opcode | immediate 연산, load, jalr |
| S-type | imm[11:5] rs2 rs1 funct3 imm[4:0] opcode | store |
| B-type | imm[12,10:5] rs2 rs1 funct3 imm[4:1,11] opcode | conditional branch |
| U-type | imm[31:12] rd opcode | upper immediate |
| J-type | imm[20,10:1,11,19:12] rd opcode | jump |

### 4.2 Immediate Field와 Immediate Extend

Immediate는 프로그램 실행에 필요한 상수값, 메모리 offset 등을 instruction 내부에 포함하기 위한 operand이다. RV32I 명령어는 32-bit 고정 길이를 사용하지만 immediate field의 위치는 명령어 형식에 따라 다르다.

I-type은 imm[11:0]을 연속된 field로 사용하고, S-type은 store 동작에 rs2가 필요하고 rd가 필요 없으므로 immediate를 두 구간으로 나누어 배치한다. B-type과 J-type은 branch 또는 jump target offset을 표현하기 위해 immediate bit가 여러 field에 나뉘어 배치된다. 따라서 CPU는 명령어 형식에 따라 immediate 값을 추출하고, 32-bit 연산에 사용할 수 있도록 sign extension 또는 shift를 수행하는 Immediate Extend 블록이 필요하다.

| Type | Immediate 용도 |
|---|---|
| I-type | ALU operand, load offset, jalr target offset |
| S-type | store address offset |
| B-type | branch target offset |
| U-type | 상위 20-bit immediate |
| J-type | jump target offset |

### 4.3 Type별 Datapath 동작과 검증

Type별 설명은 새로운 구조를 추가로 정의하는 단계가 아니라, 앞서 정의한 Datapath 중 어떤 경로가 활성화되는지를 확인하는 단계이다. 본 설계에서는 조건부 보조 명령열과 실제 프로그램 실행 이미지를 함께 사용하여 type별 control signal, ALU 경로, memory 경로, write-back 경로, PC 갱신 경로를 확인하였다.

R-Type과 I-Type Arithmetic을 제외한 나머지 Type들의 Verification은 한 번에 진행하였다.

#### 4.3.1 R-type

R-type 명령어 field는 funct7 / rs2 / rs1 / funct3 / rd / opcode 순으로 구성된다 (각각 세부 연산 구분 필드 / 두 번째 소스 레지스터 / 첫 번째 소스 레지스터 / 큰 연산 계열 구분 / 목적지 레지스터 / 명령어 그룹 구분 필드).

| 명령어 | 연산 | 연산 설명 |
|---|---|---|
| ADD | rd = rs1 + rs2 | 덧셈 |
| SUB | rd = rs1 - rs2 | 뺄셈 |
| AND | rd = rs1 & rs2 | 논리곱 |
| OR | rd = rs1 \| rs2 | 논리합 |
| XOR | rd = rs1 ^ rs2 | 배타적 논리합 |
| SLL | rd = rs1 << rs2 | 논리적 좌시프트 |
| SRL | rd = rs1 >> rs2 | 논리적 우시프트 |
| SRA | rd = rs1 >> rs2 | 산술적 우시프트, msb-extends |
| SLT | rd = (rs1 < rs2) ? 1 : 0 | signed 비교 결과 저장 |
| SLTU | rd = (rs1 < rs2) ? 1 : 0 | unsigned 비교 결과 저장 |

R-type은 add, sub, and, or처럼 register 두 개를 읽어 ALU 연산을 수행하고 결과를 rd에 write-back하는 형식이다.

```
rd = rs1 op rs2
PC = PC + 4
```

<img width="2048" height="1681" alt="image6" src="https://github.com/user-attachments/assets/af54a53c-1335-4b03-bf52-24031b3cb494" />

##### 4.3.1.1 Control Unit

| 신호 이름 | 값 | 설명 |
|---|---|---|
| opcode[6:0] | R_TYPE | Register-Register ALU 연산 |
| rf_we | 1 | 연산 결과를 Register File에 저장 |
| alu_src_sel | 0 | ALU 입력 B로 RD2 선택 |
| alu_control | {funct7[5], funct3} | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND 결정 |
| rf_src_sel | 0 | ALU 결과 write-back |
| mem_mode | 0 | Data RAM 사용 안함 |
| dwe | 0 | Memory write 비활성 |
| branch | 0 | Branch 수행 안함 |
| JAL | 0 | Jump 안함 |
| JALR | 0 | Jump Register 안함 |

##### 4.3.1.2 DataPath

| 블록 | 입력 | 출력 | 설명 |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | R-Type instruction fetch |
| Control Unit | opcode, funct3, funct7[5] | alu_control, rf_we, alu_src_sel, rf_src_sel | R-Type 제어 신호 생성 |
| Register File | rs1, rs2 | RD1, RD2 | source register 두 개 읽기 |
| ALU MUX | RD2 / imm_extend | alu_RD2 | alu_src_sel=0 이므로 RD2 선택 |
| ALU | RD1, RD2 | alu_result | register-register 연산 수행 |
| Write Back MUX | alu_result | WD | rf_src_sel=0 |
| Register File | WD | rd 저장 | 결과 저장 |

register 두 값을 읽어 ALU에서 계산하고, 그 결과를 다시 목적 register에 기록한다. program counter는 다음 명령어 실행을 위해 현재 주소 + 4byte(명령어 크기)로 갱신된다.

| 조건 | PC 출력 |
|---|---|
| 일반 R-Type 실행 | PC + 4 |

##### 4.3.1.3 Verification

<img width="1920" height="342" alt="image7" src="https://github.com/user-attachments/assets/6f4dd2c6-fef2-4609-af57-ead8401b69b1" />

| 구분 | ADD x5, x2, x3 | SUB x5, x2, x3 | AND x5, x2, x3 | OR x5, x2, x3 | XOR x5, x2, x3 |
|---|---|---|---|---|---|
| Operation | 2 + 3 | 2 - 3 | 2 & 3 | 2 \| 3 | 2 ^ 3 |
| Expected Result | x5 = 5 | x5 = -1 | x5 = 2 | x5 = 3 | x5 = 1 |
| 연산 설명 | 덧셈 | 뺄셈 | 논리곱 | 논리합 | 배타적 논리합 |

<img width="1920" height="326" alt="image8" src="https://github.com/user-attachments/assets/a24bbd5f-100f-4121-a427-ecf2af9f9b47" />

| 구분 | SLL x5, x2, x3 | SRL x5, x10, x11 | SRA x5, x10, x11 | SLT x5, x10, x11 | SLTU x5, x10, x11 |
|---|---|---|---|---|---|
| Operation | 2 << 3 | 0xffffffff >> 1 (logical) | 0xffffffff >>> 1 (arithmetic) | -1 < 1 | 0xffffffff < 0x00000001 (unsigned) |
| Expected Result | x5 = 0x70000010 | x5 = 0x7fffffff | x5 = 0xffffffff | x5 = 0x70000001 | x5 = 0x70000000 |
| 연산 | 논리적 좌시프트 | 논리적 우시프트 | 산술적 우시프트 msb-extends | signed 비교 결과 저장 | unsigned 비교 결과 저장 |

#### 4.3.2 I-Type Arithmetic

<img width="2048" height="1681" alt="image9" src="https://github.com/user-attachments/assets/34688843-c036-4dcd-b814-c396f30d630a" />

I-type 명령어 field는 imm[11:0] / rs1 / funct3 / rd / opcode 순으로 구성된다 (각각 상수 또는 shift amount field / 첫 번째 소스 레지스터 / 세부 연산 구분 필드 / 목적지 레지스터 / 명령어 그룹 구분 필드).

| 명령어 | 연산 | 연산 설명 |
|---|---|---|
| ADDI | rd = rs1 + imm | immediate 덧셈 |
| ANDI / ORI / XORI | rd = rs1 op imm | immediate 논리 연산 |
| SLLI / SRLI / SRAI | rd = rs1 shift imm[4:0] | immediate 기반 shift 연산 |
| SLTI / SLTIU | rd = (rs1 < imm) ? 1 : 0 | signed 또는 unsigned immediate 비교 |

Arithmetic immediate 계열은 Register File에서 rs1 값을 읽고, Immediate Extend가 만든 imm 값을 ALU 입력 B로 선택한다. Data Memory는 사용하지 않으며, ALU 결과를 Register File의 rd에 기록한다.

##### 4.3.2.1 Control Unit

| 신호 이름 | 값 | 설명 |
|---|---|---|
| opcode[6:0] | I_TYPE | Immediate ALU 연산 명령어 |
| rf_we | 1 | ALU 결과를 rd에 저장 |
| alu_src_sel | 1 | ALU 입력 B로 immediate 선택 |
| alu_control | funct3 기반, shift는 funct7[5] 함께 사용 | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI 결정 |
| rf_src_sel | 0 | ALU result write-back |
| mem_mode | 0 | Data Memory 사용 안함 |
| dwe | 0 | Memory write 비활성 |
| branch / JAL / JALR | 0 | 분기와 jump 경로 비활성 |

##### 4.3.2.2 DataPath

| 블록 | 입력 | 출력 | 설명 |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | I-Type arithmetic instruction fetch |
| Register File | rs1 | RD1 | source register 읽기 |
| Immediate Extend | instr[31:20] | imm | 12-bit immediate를 32-bit로 확장 |
| ALU MUX | RD2 / imm | imm 선택 | alu_src_sel=1 |
| ALU | RD1, imm | alu_result | immediate 연산 수행 |
| Write Back MUX | alu_result | WD | rf_src_sel=0 |
| Register File | WD | rd 저장 | ALU 결과 write-back |
| Program Counter | 현재 PC | PC + 4 | 다음 순차 명령어로 이동 |

##### 4.3.2.3 Verification

<img width="960" height="176" alt="image10" src="https://github.com/user-attachments/assets/5f4062da-aba4-4e5f-9c83-c405df1c7a85" />

<img width="960" height="149" alt="image11" src="https://github.com/user-attachments/assets/17665e15-e864-4a43-9d71-7ec5ec9a2592" />

I-type Arithmetic 검증 파형과 추가 검증 파형 및 결과 표로 확인하였다.

#### 4.3.3 I-Type Load

I-type Load 명령어 field는 imm[11:0] / rs1 / funct3 / rd / opcode 순으로 구성된다 (각각 load 주소 offset / base address 레지스터 / load 폭 및 확장 방식 구분 / 목적지 레지스터 / load 명령어 그룹 구분 필드).

| 명령어 | 읽는 크기 | 확장 방식 | 연산 설명 |
|---|---|---|---|
| LB | 8-bit | sign extension | rs1 + imm 주소의 byte를 읽어 rd에 저장 |
| LH | 16-bit | sign extension | rs1 + imm 주소의 halfword를 읽어 rd에 저장 |
| LW | 32-bit | 확장 없음 | rs1 + imm 주소의 word를 읽어 rd에 저장 |
| LBU | 8-bit | zero extension | unsigned byte load |
| LHU | 16-bit | zero extension | unsigned halfword load |

Load 계열은 arithmetic immediate와 동일하게 rs1 + imm를 ALU에서 계산하지만, 이 결과를 rd에 직접 저장하지 않고 Data Memory 주소로 사용한다. Memory에서 읽은 drdata가 Write Back MUX를 통해 rd에 저장되며, funct3는 load 폭과 sign/zero extension 방식을 결정한다.

<img width="2048" height="1680" alt="image12" src="https://github.com/user-attachments/assets/5b3fed82-5d85-4783-9766-fe02620eaca0" />

##### 4.3.3.1 Control Unit

| 신호 이름 | 값 | 설명 |
|---|---|---|
| opcode[6:0] | LI_TYPE | Load 명령어 |
| rf_we | 1 | Memory read 결과를 rd에 저장 |
| alu_src_sel | 1 | ALU 입력 B로 immediate 선택 |
| alu_control | ADD | effective address = rs1 + imm 계산 |
| rf_src_sel | 1 | Data Memory read data write-back |
| mem_mode | funct3 | LB, LH, LW, LBU, LHU 및 확장 방식 구분 |
| dwe | 0 | Memory write 비활성 |
| branch / JAL / JALR | 0 | 분기와 jump 경로 비활성 |

##### 4.3.3.2 DataPath

| 블록 | 입력 | 출력 | 설명 |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | Load instruction fetch |
| Register File | rs1 | RD1 | base register 읽기 |
| Immediate Extend | instr[31:20] | imm | load offset 생성 |
| ALU MUX | RD2 / imm | imm 선택 | alu_src_sel=1 |
| ALU | RD1, imm | alu_result | Data Memory effective address 계산 |
| Data Memory | daddr=alu_result, mem_mode | drdata | byte/halfword/word read 및 확장 |
| Write Back MUX | drdata | WD | rf_src_sel=1 |
| Register File | WD | rd 저장 | load 결과 write-back |
| Program Counter | 현재 PC | PC + 4 | 다음 순차 명령어로 이동 |

#### 4.3.4 I-Type JALR

I-type JALR 명령어 field는 imm[11:0] / rs1 / funct3 / rd / opcode 순으로 구성된다 (각각 jump target offset / jump base 레지스터 / JALR 형식 구분 필드 / return address 저장 레지스터 / JALR 명령어 그룹 구분 필드).

| 명령어 | 연산 | 연산 설명 |
|---|---|---|
| JALR | rd = PC + 4; PC = rs1 + imm | register indirect jump와 return address 저장 |

JALR은 I-type format을 사용하지만 일반 ALU write-back이나 load와 다르게 Program Counter 경로가 핵심이다. rs1 값과 immediate를 더해 다음 PC를 만들고, 동시에 현재 명령어 다음 주소인 PC + 4를 rd에 저장하여 함수 복귀 주소로 사용할 수 있게 한다.

<img width="2048" height="1680" alt="image13" src="https://github.com/user-attachments/assets/38243cc6-294e-4040-86ea-c583ef17d2d6" />

##### 4.3.4.1 Control Unit

| 신호 이름 | 값 | 설명 |
|---|---|---|
| opcode[6:0] | JL_TYPE | JALR 명령어 |
| rf_we | 1 | PC + 4를 rd에 저장 |
| alu_src_sel | 0 | ALU 경로는 실질적으로 사용하지 않음 |
| alu_control | ADD | 현재 RTL 기본값 유지 |
| rf_src_sel | 4 | pc_next, 즉 PC + 4 write-back |
| mem_mode | 0 | Data Memory 사용 안함 |
| dwe | 0 | Memory write 비활성 |
| branch | 0 | 조건 분기 아님 |
| JAL | 1 | jump path 활성 |
| JALR | 1 | rs1 + imm 기준 PC 갱신 |

##### 4.3.4.2 DataPath

| 블록 | 입력 | 출력 | 설명 |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | JALR instruction fetch |
| Register File | rs1 | RD1 | jump base register 읽기 |
| Immediate Extend | instr[31:20] | imm | jump offset 생성 |
| Program Counter | RD1, imm, JALR | pc_out, pc_next | pc_out은 rs1 + imm, pc_next는 PC + 4 |
| Write Back MUX | pc_next | WD | rf_src_sel=4 |
| Register File | WD | rd 저장 | return address 저장 |

#### 4.3.5 S-type

S-type 명령어 field는 imm[11:5] / rs2 / rs1 / funct3 / imm[4:0] / opcode 순으로 구성된다 (각각 store offset 상위 필드 / 저장할 데이터 레지스터 / base address 레지스터 / store 폭 구분 필드 / store offset 하위 필드 / store 명령어 그룹 구분 필드).

| 명령어 | 연산 | 연산 설명 |
|---|---|---|
| SB | M[rs1 + imm][7:0] = rs2[7:0] | byte store |
| SH | M[rs1 + imm][15:0] = rs2[15:0] | halfword store |
| SW | M[rs1 + imm][31:0] = rs2[31:0] | word store |

S-type은 register 값을 Data Memory에 저장하는 형식이다. rd가 필요 없기 때문에 rd field 위치는 imm[4:0]으로 사용되고, instr[31:25]는 imm[11:5]로 사용되어 store offset을 구성한다.

<img width="2048" height="1680" alt="image14" src="https://github.com/user-attachments/assets/1bc2ea0e-91ee-4f98-b995-a5d5292fe135" />

##### 4.3.5.1 Control Unit

| 신호 이름 | 값 | 설명 |
|---|---|---|
| opcode[6:0] | S_TYPE | Memory Store 명령어 |
| rf_we | 0 | Register File write-back 없음 |
| alu_src_sel | 1 | ALU 입력 B를 immediate 값으로 선택 |
| alu_control | ADD | rs1 + imm 주소 계산 |
| rf_src_sel | 0 | 미사용 |
| mem_mode | funct3 | SB, SH, SW 구분 |
| dwe | 1 | Memory write 활성 |
| branch/JAL/JALR | 0 | PC 변경 명령 아님 |

##### 4.3.5.2 DataPath

| 블록 | 입력 | 출력 | 설명 |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | S-Type instruction fetch |
| Register File | rs1, rs2 | RD1, RD2 | base register와 store data 읽기 |
| Immediate Extend | store immediate field | imm | store offset 생성 |
| ALU | RD1, imm | alu_result | effective address 계산 |
| Data Memory | daddr, dwdata, mem_mode, dwe | memory update | store 수행 |

rs1 + imm로 RAM 주소를 계산하고, rs2 값을 해당 RAM 위치에 저장한다.

| 조건 | PC 출력 |
|---|---|
| 일반 S-Type 실행 | PC + 4 |

#### 4.3.6 B-type

B-type 명령어 field는 imm[12,10:5] / rs2 / rs1 / funct3 / imm[4:1,11] / opcode 순으로 구성된다 (각각 branch offset 상위/중간 필드 / 두 번째 비교 레지스터 / 첫 번째 비교 레지스터 / branch 조건 구분 필드 / branch offset 하위/재배치 필드 / branch 명령어 그룹 구분 필드).

| 명령어 | 연산 | 연산 설명 |
|---|---|---|
| BEQ | if (rs1 == rs2) PC += imm | 같으면 분기 |
| BNE | if (rs1 != rs2) PC += imm | 다르면 분기 |
| BLT | if (rs1 < rs2) PC += imm | signed 작으면 분기 |
| BGE | if (rs1 >= rs2) PC += imm | signed 크거나 같으면 분기 |
| BLTU | if (rs1 < rs2) PC += imm | unsigned 작으면 분기 |
| BGEU | if (rs1 >= rs2) PC += imm | unsigned 크거나 같으면 분기 |

B-type은 두 register를 비교하고 조건 만족 여부에 따라 다음 PC를 선택하는 형식이다. 결과 register와 memory access는 없으며, 핵심 결과는 b_taken과 next PC이다.

<img width="2048" height="1682" alt="image15" src="https://github.com/user-attachments/assets/16f99138-3e2d-49fd-9d5a-b2c3d2e4d970" />

##### 4.3.6.1 Control Unit

| 신호 이름 | 값 | 설명 |
|---|---|---|
| opcode[6:0] | B_TYPE | 조건 분기 명령어 |
| rf_we | 0 | Register File write-back 없음 |
| alu_src_sel | 0 | ALU 입력 B로 RD2 선택 |
| alu_control | {1'b0, funct3} | branch compare 종류 결정 |
| rf_src_sel | 0 | write-back 경로 사용 안함 |
| mem_mode/dwe | 0 | Data RAM 사용 안함 |
| branch | 1 | Branch 판단 활성 |
| JAL/JALR | 0 | Jump 아님 |

##### 4.3.6.2 DataPath

| 블록 | 입력 | 출력 | 설명 |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | B-Type instruction fetch |
| Register File | rs1, rs2 | RD1, RD2 | 비교할 두 register 읽기 |
| ALU | RD1, RD2 | b_taken | branch 조건 비교 결과 생성 |
| Immediate Extend | branch immediate field | imm | branch offset 생성 |
| Program Counter | b_taken, imm | pc_out | taken 여부에 따라 다음 PC 결정 |

rs1과 rs2를 비교하여 분기 조건을 만들고, 그 결과에 따라 다음 PC를 PC + 4 또는 PC + imm로 선택한다.

| 조건 | PC 출력 |
|---|---|
| branch=1, b_taken=0 | PC + 4 |
| branch=1, b_taken=1 | PC + imm |

#### 4.3.7 U-Type LUI

U-type LUI 명령어 field는 imm[31:12] / rd / opcode 순으로 구성된다 (각각 upper immediate field / 목적지 레지스터 / LUI 명령어 그룹 구분 필드).

| 명령어 | 연산 | 연산 설명 |
|---|---|---|
| LUI | rd = imm << 12 | 20-bit upper immediate를 rd에 직접 기록 |

LUI는 U-type format 중 immediate 자체를 register 값으로 만드는 명령어이다. rs1, rs2, funct3, funct7은 사용하지 않고, instr[31:12] field를 Immediate Extend에서 상위 immediate 값으로 확장한 뒤 rd에 기록한다.

<img width="2048" height="1682" alt="image16" src="https://github.com/user-attachments/assets/ca2e0a4d-7a1d-46ca-89bd-0bd70312ee43" />

##### 4.3.7.1 Control Unit

| 신호 이름 | 값 | 설명 |
|---|---|---|
| opcode[6:0] | U_TYPE | LUI 명령어 |
| rf_we | 1 | immediate 값을 rd에 저장 |
| rf_src_sel | 2 | imm_extend write-back |
| alu_src_sel / alu_control | 실질 미사용 / ADD 기본값 | ALU 결과를 write-back하지 않음 |
| mem_mode / dwe / branch / JAL / JALR | 0 | Memory, branch, jump 경로 비활성 |

##### 4.3.7.2 DataPath

| 블록 | 입력 | 출력 | 설명 |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | LUI instruction fetch |
| Control Unit | opcode | rf_we, rf_src_sel | LUI 제어 신호 생성 |
| Immediate Extend | instr[31:12] | imm_extend | upper immediate 생성 |
| Write Back MUX | imm_extend | WD | rf_src_sel=2 |
| Register File | WD | rd 저장 | upper immediate write-back |
| Program Counter | 현재 PC | PC + 4 | 다음 순차 명령어로 이동 |

#### 4.3.8 U-Type AUIPC

U-type AUIPC 명령어 field는 imm[31:12] / rd / opcode 순으로 구성된다 (각각 PC에 더할 upper immediate field / 목적지 레지스터 / AUIPC 명령어 그룹 구분 필드).

| 명령어 | 연산 | 연산 설명 |
|---|---|---|
| AUIPC | rd = PC + (imm << 12) | PC 기준 upper immediate 주소 값을 rd에 저장 |

AUIPC는 U-type format을 사용하지만 LUI와 달리 immediate를 그대로 저장하지 않고 현재 PC와 더한 값을 rd에 기록한다. 이때 PC + imm는 다음 PC가 아니라 write-back data이며, 명령어 실행 후 실제 PC는 PC + 4로 진행한다.

<img width="2048" height="1682" alt="image17" src="https://github.com/user-attachments/assets/a89bda09-9d0d-4030-8ba9-183489f868ae" />

##### 4.3.8.1 Control Unit

| 신호 이름 | 값 | 설명 |
|---|---|---|
| opcode[6:0] | AU_TYPE | AUIPC 명령어 |
| rf_we | 1 | PC + imm 값을 rd에 저장 |
| rf_src_sel | 3 | pc_imm write-back |
| alu_src_sel / alu_control | 실질 미사용 / ADD 기본값 | ALU 결과를 write-back하지 않음 |
| mem_mode / dwe / branch / JAL / JALR | 0 | Memory, branch, jump 경로 비활성 |

##### 4.3.8.2 DataPath

| 블록 | 입력 | 출력 | 설명 |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | AUIPC instruction fetch |
| Control Unit | opcode | rf_we, rf_src_sel | AUIPC 제어 신호 생성 |
| Immediate Extend | instr[31:12] | imm_extend | upper immediate 생성 |
| Program Counter | 현재 PC, imm_extend | pc_imm | PC + imm write-back 값 생성 |
| Write Back MUX | pc_imm | WD | rf_src_sel=3 |
| Register File | WD | rd 저장 | PC-relative 값 write-back |
| Program Counter | 현재 PC | PC + 4 | 다음 순차 명령어로 이동 |

#### 4.3.9 J-type

J-type 명령어 field는 imm[20,10:1,11,19:12] / rd / opcode 순으로 구성된다 (각각 jump target offset field / return address 저장 레지스터 / JAL 명령어 그룹 구분 필드).

| 명령어 | 연산 | 연산 설명 |
|---|---|---|
| JAL | rd = PC + 4; PC = PC + imm | PC-relative jump와 link 동시 수행 |

J-type은 unconditional jump와 return address 저장을 동시에 수행한다. rs1과 rs2는 사용하지 않고, jump immediate field와 rd가 핵심이다. rd에는 PC + 4가 저장되고, PC는 PC + imm로 갱신된다.

<img width="2048" height="1680" alt="image18" src="https://github.com/user-attachments/assets/7fcde526-ab93-43ed-b8c5-1ccb56d9d30d" />

##### 4.3.9.1 Control Unit

| 신호 이름 | 값 | 설명 |
|---|---|---|
| opcode[6:0] | J_TYPE | JAL |
| rf_we | 1 | PC + 4를 Register File에 저장 |
| alu_src_sel | 0 | ALU 경로 실질 미사용 |
| alu_control | ADD | 현재 RTL 기본값 유지 |
| rf_src_sel | 4 | pc_next write-back |
| mem_mode / dwe / branch | 0 | Data RAM 및 branch 사용 안함 |
| JAL | 1 | jump path 활성 |
| JALR | 0 | register-relative jump 아님 |

##### 4.3.9.2 DataPath

| 블록 | 입력 | 출력 | 설명 |
|---|---|---|---|
| Instruction Memory | instr_addr | instr_code | JAL fetch |
| Immediate Extend | jump immediate field | imm | jump offset 생성 |
| Program Counter | pc_in, imm | pc_out, pc_next | jump target과 PC + 4 생성 |
| Write Back MUX | pc_next | WD | rf_src_sel=4 |
| Register File | WD | rd 저장 | return address 저장 |

PC + imm로 jump하고, 동시에 PC + 4를 목적 rd에 기록한다.

| 조건 | PC 출력 |
|---|---|
| JAL=1 | PC + imm |
| write-back 값 | PC + 4 |

#### 4.3.10 Type별 통합 Verification

R-type과 I-Type Arithmetic은 앞 절에서 개별 검증 기준을 제시하였다. 나머지 type은 memory access, PC update, write-back source 선택 관점에서 다음 표로 통합 검증한다.

| 검증 대상 | 관찰 기준 | 기대 결과 |
|---|---|---|
| I-Type Load | alu_src_sel=1, alu_control=ADD, rf_src_sel=1, mem_mode=funct3 | rs1 + imm 주소의 Data Memory read data가 rd에 저장됨 |
| I-Type JALR | JAL=1, JALR=1, rf_src_sel=4 | PC가 rs1 + imm로 갱신되고 rd에는 PC + 4가 저장됨 |
| S-type | dwe=1, mem_mode=funct3, rf_we=0 | rs1 + imm 주소에 rs2 값이 Data Memory로 write됨 |
| B-type | branch=1, b_taken 관찰 | 조건 만족 시 PC + imm, 불만족 시 PC + 4 선택 |
| U-Type LUI | rf_we=1, rf_src_sel=2 | Immediate Extend 결과가 rd에 저장되고 PC는 PC + 4로 진행 |
| U-Type AUIPC | rf_we=1, rf_src_sel=3 | PC + imm 결과가 rd에 저장되고 next PC는 PC + 4로 진행 |
| J-type | JAL=1, rf_src_sel=4 | PC가 PC + imm로 갱신되고 rd에는 PC + 4가 저장됨 |

<img width="2048" height="169" alt="image19" src="https://github.com/user-attachments/assets/703ead29-c55e-494a-ac1f-32904e98e39a" />

<img width="2048" height="244" alt="image20" src="https://github.com/user-attachments/assets/fa8e11f3-4250-4aae-adb1-4269cf3d7053" />

<img width="2048" height="200" alt="image21" src="https://github.com/user-attachments/assets/969c0d54-2ab0-49c6-924f-97937db2f318" />

Store-type, Branch-type, Upper/Jump-type 시뮬레이션 파형으로 위 통합 검증 결과를 확인하였다.

## 5. C 프로그램 실행 분석

발표에서는 0부터 10까지의 합 Counter를 중심 사례로 사용하였다. 본 보고서에서는 해당 사례를 기준으로 C 코드가 assembly, machine instruction, memory initialization file, waveform 관찰 결과로 이어지는 흐름을 구체적으로 설명한다.

앞선 절에서는 RV32I instruction type별로 Datapath의 어떤 경로가 활성화되는지 확인하였다. 이 절에서는 같은 내용을 실제 소프트웨어 실행 관점으로 확장한다. C 코드의 변수, pointer, stack, 함수 호출, 조건문, 반복문은 CPU 내부에서는 register operand, immediate, load/store, branch, jump, memory image로 관찰된다.

### 5.1 Software 실행 모델

#### 5.1.1 C Code, Assembly, Machine Code, Memory Initialization File 관계

<img width="1911" height="240" alt="image22" src="https://github.com/user-attachments/assets/80203fab-7e5b-4232-9718-82a9cfe5814b" />

CPU는 C 소스코드를 직접 실행하지 않는다. CPU가 실행하는 것은 ISA 규칙에 따라 인코딩된 machine instruction이다. C 코드는 compiler에 의해 assembly code로 변환되고, assembly code는 assembler에 의해 machine code로 변환된다. 이후 linker는 code section과 data section의 주소 배치를 결정하며, 최종 실행 이미지는 simulation 또는 FPGA 환경에서 사용할 수 있는 memory initialization file로 변환된다.

| 단계 | 예시 | 의미 |
|---|---|---|
| C source code | a = b + 10; | 사람이 작성한 고수준 프로그램 |
| Assembly code | addi x5, x6, 10 | ISA 명령어를 사람이 읽을 수 있는 형태로 표현 |
| Machine instruction | 000000001010 00110 000 00101 0010011 | CPU가 fetch하여 decode하는 32-bit instruction |
| Memory initialization file | 00a30293 | Instruction Memory 초기화에 사용되는 값 |

#### 5.1.2 Register Name과 ABI 관계

RV32I ISA는 x0부터 x31까지의 32개 integer register를 정의한다. sp, ra, a0 같은 이름은 ISA 자체의 register 이름이라기보다 ABI에서 정의한 용도 기반 이름이다. 함수 호출, 인자 전달, 반환값, stack frame을 해석하려면 ISA의 register 번호와 ABI 이름을 함께 보아야 한다.

| ABI 이름 | 실제 register | 역할 |
|---|---|---|
| zero | x0 | 항상 0 |
| ra | x1 | return address |
| sp | x2 | stack pointer |
| a0-a7 | x10-x17 | function argument / return value |
| t0-t6 | x5-x7, x28-x31 | temporary register |
| s0-s11 | x8-x9, x18-x27 | saved register |

#### 5.1.3 Program Memory와 Data Memory 배치

본 설계는 Harvard Architecture 기반으로 Instruction Memory와 Data Memory를 분리한다. 따라서 실행할 machine instruction은 Instruction Memory에 저장되고, load/store 명령어의 대상 데이터는 Data Memory에 저장된다. C 프로그램을 실행하려면 .text, .data, .bss, stack 영역의 배치를 이해해야 하며, 이 배치는 linker script와 memory initialization file 생성 과정과 연결된다.

| 영역 | 일반적 section | 저장 위치 | 내용 |
|---|---|---|---|
| Instruction Memory | .text | ROM | 실행할 machine instruction |
| Constant 영역 | .rodata | ROM 또는 별도 memory | 상수 데이터 |
| Initialized data | .data | RAM | 초기값 있는 전역/static 변수 |
| Zero-initialized data | .bss | RAM | 초기값 없는 전역/static 변수 |
| Stack | stack region | RAM | local variable, saved register, return address |
| Heap | heap region | RAM | 동적 할당 영역 |

#### 5.1.4 내부 변수의 Memory 할당 관계

C 코드의 지역 변수가 항상 RAM에 저장되는 것은 아니다. Compiler는 가능한 경우 변수를 register에 할당한다. 그러나 변수의 주소가 필요하거나 register가 부족하거나 함수 호출 경계를 넘어 값을 보존해야 하는 경우에는 stack에 저장한다. 따라서 C 변수와 memory 위치의 관계는 변수 종류, compiler 최적화, ABI, stack frame 구성에 따라 달라진다.

| C 변수 종류 | 일반적 저장 위치 | 설명 |
|---|---|---|
| 지역 변수 | register 또는 stack | compiler가 register에 둘 수 있으며, 필요 시 stack에 저장 |
| 주소가 사용되는 지역 변수 | stack | pointer로 접근해야 하므로 memory 위치 필요 |
| 전역 변수 | .data 또는 .bss | Data Memory에 배치 |
| static 지역 변수 | .data 또는 .bss | 함수 밖에서도 생존 기간 유지 |
| 상수 | .rodata | ROM 또는 read-only 영역에 배치 가능 |
| 함수 인자 | a0-a7 또는 stack | ABI 규칙에 따라 전달 |

### 5.2 Pointer 동작 방식

Pointer는 메모리 주소를 저장하는 변수이다. Pointer를 dereference하는 동작은 해당 주소를 이용해 memory에서 값을 읽거나 쓰는 load/store 명령어로 변환된다. 따라서 pointer는 C 문법의 별도 기능처럼 보이지만, CPU 내부에서는 주소 계산과 memory access의 조합으로 실행된다.

```c
int x = 10;
int *p = &x;
int y = *p;
```

```
# a0가 p, 즉 x의 주소를 가지고 있다고 가정
lw a1, 0(a0)    # y = *p
```

| C 표현 | 의미 | RV32I 동작 |
|---|---|---|
| p = &x | 변수 x의 주소를 pointer에 저장 | address 계산 |
| *p | pointer가 가리키는 주소에서 값 읽기 | lw |
| *p = value | pointer가 가리키는 주소에 값 쓰기 | sw |
| p + 1 | 다음 element 주소 계산 | p + sizeof(*p) |

RV32I 주소는 byte address이다. 따라서 int *p에서 p + 1은 주소값을 1 증가시키는 것이 아니라, int 크기인 4 byte만큼 증가시키는 동작으로 변환된다. Bubble Sort 예제에서 배열 index를 slli index, index, 2로 shift하는 이유도 int 원소 하나가 4 byte이기 때문이다.

### 5.3 Stack Pointer와 Stack 동작 방식

Stack Pointer는 stack 영역의 현재 top 주소를 저장하는 register이다. RISC-V ABI에서는 x2를 sp로 사용한다. 함수 호출 시 compiler는 stack pointer를 조정하여 stack frame을 만들고, 그 안에 local variable, saved register, return address 등을 저장할 수 있다.

```
# 함수 진입 시 stack frame 확보
addi sp, sp, -16
sw   ra, 12(sp)
sw   s0, 8(sp)

# 함수 종료 시 stack frame 해제
lw   ra, 12(sp)
lw   s0, 8(sp)
addi sp, sp, 16
jalr x0, 0(ra)
```

일반적인 RISC-V ABI에서는 stack이 낮은 주소 방향으로 증가한다. 따라서 stack 공간을 확보할 때 sp에서 필요한 크기만큼 빼고, 함수 종료 시 다시 더한다. Stack frame 내부에는 local variable, saved register, return address, 임시 spill 값이 배치될 수 있다.

### 5.4 C + Assembly + Memory 비교

이 절에서는 C 문법이 어떤 assembly 명령어와 memory 동작으로 바뀌는지 대표 패턴별로 정리한다. 핵심은 C 코드의 문법 자체가 CPU에서 직접 실행되는 것이 아니라, RV32I instruction sequence로 변환된 뒤 Instruction Memory에서 fetch되어 실행된다는 점이다.

#### 5.4.1 단순 연산

```c
int y = x + 10;
```
```
addi a1, a0, 10
```

| 요소 | 설명 |
|---|---|
| Type | I-type |
| Immediate | 상수 10 |
| ALU 입력 | rs1, imm |
| Write-back | ALU result -> rd |
| PC | PC + 4 |

#### 5.4.2 Pointer 접근

```c
int y = *p;
```
```
lw a1, 0(a0)
```

| 요소 | 설명 |
|---|---|
| Type | I-type load |
| Address 계산 | a0 + 0 |
| Memory access | Data Memory read |
| Write-back | memory read data -> rd |
| 확장 | lw는 32-bit load이므로 별도 확장 없음 |

#### 5.4.3 Local Variable 접근

```c
int f(void) {
    int x = 3;
    return x + 1;
}
```

내부 변수는 compiler 판단에 따라 register 또는 stack에 배치된다. 변수가 register에 배치되면 Data Memory 접근 없이 ALU와 Register File만으로 처리된다. 반면 stack에 배치되면 sp 또는 s0 기준 offset을 사용한 lw/sw 명령어로 접근한다.

#### 5.4.4 Function Call / Return

```c
int add(int a, int b) {
    return a + b;
}
int main(void) {
    return add(1, 2);
}
```

| 동작 | RV32I 명령어 | 설명 |
|---|---|---|
| 함수 호출 | jal ra, target | ra = PC + 4, PC = target |
| 함수 복귀 | jalr x0, 0(ra) | PC = ra |
| 인자 전달 | a0, a1 | ABI argument register 사용 |
| 반환값 | a0 | ABI return value register 사용 |
| stack 사용 | sp 조정 | 필요 시 return address, saved register 저장 |

#### 5.4.5 if 문

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

if 문은 조건 비교와 PC 선택으로 실행된다. 조건이 참이면 branch target으로 이동하고, 거짓이면 다음 명령어인 PC + 4 경로로 진행한다.

#### 5.4.6 for 문

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

| C 구성 | Assembly 동작 |
|---|---|
| 초기화 | addi |
| 조건 비교 | bge |
| 반복 본문 | ALU 연산 |
| 증가식 | addi |
| 반복 이동 | jal x0, loop |

#### 5.4.7 while 문

<img width="272" height="265" alt="image23" src="https://github.com/user-attachments/assets/55ef5e86-acfc-4ba7-a543-78b5804cb569" />

<img width="296" height="559" alt="image24" src="https://github.com/user-attachments/assets/a6a72859-54cb-457a-b8d2-a7ed87c40632" />

while 문은 loop 진입 전에 조건을 먼저 검사한다. 조건 검사는 B-type branch로 수행되고, 반복 본문 이후에는 loop label로 돌아가기 위해 J-type jump 또는 branch가 사용된다.

### 5.5 0부터 10까지의 합 Counter

소프트웨어 실행 흐름을 설명하기 위해 0부터 10까지 증가하는 counter와 누적합 계산을 예시로 사용하였다.

가장 단순한 counter 관점에서는 지역 변수 count를 0으로 초기화한 뒤, while 조건을 만족하는 동안 값을 1씩 증가시키는 C 코드가 기준이 된다. 명령어 수준에서는 local variable load/store, 상수 비교, 조건 branch, loop back 흐름으로 전개된다.

이 기본 코드에 함수 호출을 포함한 Sum Counting C 코드는 단순 counter 흐름에 adder(a, sum) 함수 호출을 추가하여 local variable, loop branch, stack frame, function call/return, return value write-back을 함께 확인할 수 있게 한다.

main() frame 기준으로 sum은 -24(s0), a는 -20(s0)에 저장된다. 파형에서는 이 위치가 각각 data_ram[58], data_ram[59]로 관찰된다. 반복문 내부에서는 a를 load하여 1 증가시키고 다시 store한 뒤, a0, a1에 인자를 준비해 adder()를 호출한다. 반환값은 다시 sum 위치에 저장된다.

#### 5.5.1 main() stack frame과 변수 초기화

<img alt="image25" src="https://github.com/user-attachments/assets/42d20d16-3d20-4379-bbc2-692d4f152971" />
<img alt="image26" src="https://github.com/user-attachments/assets/6e87d34d-740d-4569-88c7-995cde7a28f9" />

| .mem line | Assembly | 의미 |
|---|---|---|
| 10000113 | addi sp, zero, 256 | stack 시작 주소 설정 |
| fe010113 | addi sp, sp, -32 | main() stack frame 생성 |
| 00112e23 | sw ra, 28(sp) | return address 저장 |
| 00812c23 | sw s0, 24(sp) | frame pointer 저장 |
| 02010413 | addi s0, sp, 32 | s0 frame 기준점 설정 |
| fe042623 | sw zero, -20(s0) | a = 0 |
| fe042423 | sw zero, -24(s0) | sum = 0 |
| 0200006f | jal zero, +32 | 조건 검사 위치로 이동 |

#### 5.5.2 loop body와 adder() 호출

<img width="1419" height="528" alt="image27" src="https://github.com/user-attachments/assets/459a8a9d-0d47-4dfa-bbbe-553964874c42" />

<img width="1598" height="675" alt="image28" src="https://github.com/user-attachments/assets/d9d62ee0-9287-4d4a-b67b-2f854d9274b1" />

| .mem line | Assembly | 의미 |
|---|---|---|
| fec42783 | lw a5, -20(s0) | a 읽기 |
| 00178793 | addi a5, a5, 1 | a++ |
| fef42623 | sw a5, -20(s0) | a 저장 |
| fe842583 | lw a1, -24(s0) | sum을 두 번째 인자로 준비 |
| fec42503 | lw a0, -20(s0) | a를 첫 번째 인자로 준비 |
| 028000ef | jal ra, +40 | adder() 호출 |
| fea42423 | sw a0, -24(s0) | 반환값을 sum에 저장 |
| fec42703 | lw a4, -20(s0) | 조건 비교용 a 읽기 |
| 00900793 | addi a5, zero, 9 | 비교 기준값 9 |
| fce7dee3 | bge a5, a4, -36 | a <= 9이면 loop |

while (a < 10)은 compiler에 의해 9 >= a이면 loop로 돌아가는 branch 형태로 나타난다. 따라서 C 코드의 조건식과 assembly의 비교 방향이 다르게 보일 수 있지만, 의미는 a가 10이 되기 전까지 반복한다는 점에서 동일하다.

#### 5.5.3 adder() 함수와 return value

<img width="1598" height="611" alt="image29" src="https://github.com/user-attachments/assets/62d8c780-b514-4c54-b0c4-e5d20601f74e" />

| .mem line | Assembly | 의미 |
|---|---|---|
| fe010113 | addi sp, sp, -32 | adder() stack frame 생성 |
| 00112e23 | sw ra, 28(sp) | return address 저장 |
| 00812c23 | sw s0, 24(sp) | frame pointer 저장 |
| 02010413 | addi s0, sp, 32 | frame 기준점 설정 |
| fea42623 | sw a0, -20(s0) | 인자 a 저장 |
| feb42423 | sw a1, -24(s0) | 인자 sum 저장 |
| fec42703 | lw a4, -20(s0) | a 읽기 |
| fe842783 | lw a5, -24(s0) | sum 읽기 |
| 00f707b3 | add a5, a4, a5 | a + sum |
| 00078513 | addi a0, a5, 0 | 반환값을 a0에 배치 |
| 00008067 | jalr zero, 0(ra) | caller로 복귀 |

함수 호출은 jal ra, target으로 수행되어 ra에 PC + 4를 저장하고 함수 시작 주소로 이동한다. 함수 복귀는 jalr zero, 0(ra)로 수행되며, 반환값은 ABI 규칙에 따라 a0에 놓인다.

#### 5.5.4 waveform 관찰 기준

| 관찰 항목 | 최종 값 | 의미 |
|---|---|---|
| data_ram[58] | 55 | 1 + 2 + ... + 10 누적합 |
| data_ram[59] | 10 | 반복 종료 시 변수 a |

Waveform에서는 instr_code가 .mem line 순서대로 fetch되는지, sp와 s0가 stack frame을 만들고 복원하는지, a0와 a1이 함수 인자와 반환값으로 사용되는지, PC가 jal, bge, jalr에 따라 바뀌는지를 함께 확인한다. 이 결과는 C 코드의 while 기반 카운트와 함수 호출이 RV32I branch, load/store, jal/jalr, register write-back 흐름으로 변환되어 실행됨을 보여준다.

## 6. 결론 및 고찰

본 프로젝트를 통해 RV32I single-cycle CPU를 단순 명령어 예제 수준이 아니라 실제 C 프로그램 실행 관점에서 분석할 수 있는 기준을 수립하였다. RISC-V와 RV32I의 범위를 정리한 뒤, single-cycle 구조와 Harvard Architecture 선택 이유, memory access model, instruction decode, datapath 구성 요구사항, CPU 내부 동작 흐름을 순서대로 연결하였다.

또한 Type별 설계 및 검증에서는 R/I/S/B/U/J-type이 새로운 구조를 요구하는 것이 아니라, 이미 정의된 Datapath의 서로 다른 경로를 사용하는 방식임을 확인하였다. Immediate Extend, ALU Source MUX, Register File Source MUX, PC Source MUX의 필요성도 instruction field와 실행 동작에서 도출할 수 있었다.

마지막으로 sum_counting 실행 이미지를 중심으로 분석하고 buble_sort를 보조 사례로 확인하여 C 코드가 assembly, machine instruction, memory initialization file을 거쳐 Instruction Memory에 들어가고, CPU가 이를 fetch/decode/execute하는 과정을 확인하였다. 이를 통해 본 설계는 RTL module 구현뿐 아니라 C code -> instruction encoding -> datapath/control -> memory state로 이어지는 실행 경로를 구조적으로 설명할 수 있는 학습용 RV32I CPU 구현으로 정리할 수 있다.

## 참고 문헌

[1] RISC-V Instruction Set Manual, Unprivileged ISA https://docs.riscv.org/reference/isa/v20240411/unpriv/unpriv-index.html

[2] RISC-V ISA Extension Naming Conventions https://docs.riscv.org/reference/isa/unpriv/naming.html

[3] RV codec JS - https://luplab.gitlab.io/rvcodecjs

[4] Compiler Explorer - https://godbolt.org/

[5] RISC-V ASM Viewer - https://riscvasm.lucasteske.dev/
