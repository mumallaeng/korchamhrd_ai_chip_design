# 26-05-19 - RV32I 구조와 single-cycle datapath 읽기

dedicated CPU 다음 단계에서는 범용 명령어 집합을 가진 RV32I CPU를 어떤 블록으로 쪼개서 읽어야 하는지가 핵심이 된다. `helloHDL/260519_lecture_RV32I`와 `helloHDL/260519_RV32I` 두 코드 트리는 같은 큰 구조를 공유하고, 하나는 학습용 분리형 코드, 다른 하나는 같은 내용을 조금 더 확장해서 한 파일에 묶어 둔 형태로 볼 수 있다.

## 먼저 잡아야 하는 기준

RISC-V는 ISA다. 즉 CPU가 어떤 명령어를 이해해야 하고, 레지스터와 메모리를 어떤 규칙으로 다뤄야 하는지를 정해 둔 규격이다.  
SystemVerilog 코드는 그 ISA를 실제 회로 구조로 옮긴 구현체다.  
따라서 `RV32I를 공부한다`는 말은 두 층을 같이 보는 것이다.

- ISA 관점에서는 `opcode`, `funct3`, `funct7`, immediate 형식, register 사용 규칙을 본다.
- RTL 관점에서는 control unit이 어떤 제어 신호를 만들고, datapath가 그 신호로 어떤 값을 흘리는지 본다.

이 구현에서는 ABI 자체를 깊게 구현하는 것이 아니라, 우선 ISA와 datapath를 읽는 감각을 잡는 것이 중심이다. ABI와 stack frame은 뒤의 calling convention, stack frame 학습으로 이어진다.

## compiler/linker와 hardware의 책임 경계

RISC-V register의 의미를 hardware가 직접 알고 있는 것은 아니다.
hardware는 `x0 ~ x31` register file, read/write port, memory access, PC update 같은 기계어 실행 규칙을 구현한다.
반면 어떤 register를 return address, stack pointer, argument register로 쓸지는 compiler, ABI, linker가 정한다.

| 관점 | 담당 |
| --- | --- |
| hardware | register 번호, ALU 연산, memory read/write, PC 갱신을 수행 |
| compiler / ABI | 함수 호출 규약, argument/return register, stack pointer 사용 규칙을 정함 |
| linker | program section과 symbol을 실제 address 공간에 배치 |

따라서 CPU 설계자는 `이 register 번호에 쓰라`, `이 주소를 읽거나 쓰라`는 기계어 계약을 정확히 수행하는 데 집중한다.
그 register가 software 관점에서 `ra`인지 `sp`인지까지 datapath가 해석하는 것은 아니다.

## 두 코드 트리에서 공통으로 보이는 CPU 큰 구조

두 코드 모두 top 수준에서는 아래 흐름으로 읽으면 된다.

```text
PC
-> instruction memory
-> instruction decode
-> register file / immediate / ALU
-> data memory
-> write-back
```

`top_rv32i_soc`는 instruction memory, CPU, data memory를 묶는 껍데기 역할이다.  
이 구조는 명령어 메모리와 데이터 메모리를 분리해 두었기 때문에 학습용으로는 Harvard 구조처럼 읽는 편이 자연스럽다.

- instruction memory는 현재 `PC`가 가리키는 주소의 명령어를 꺼낸다.
- CPU 내부 control unit은 명령어 비트를 해석해 제어 신호를 만든다.
- datapath는 register file, ALU, immediate generator, PC update 회로를 통해 실제 계산을 수행한다.
- data memory는 `load/store` 명령어가 있을 때만 동작한다.

## RV32I 명령어 형식을 코드에서 읽는 법

`define.vh`를 보면 기본 instruction format이 이미 이름으로 정리돼 있다.

- `R_TYPE`: 레지스터 두 개를 읽어 ALU 연산
- `I_TYPE`: immediate를 쓰는 ALU 연산
- `IL_TYPE` 또는 `LI_TYPE`: load 계열
- `S_TYPE`: store 계열
- `B_TYPE`: branch 계열
- `U_TYPE` 또는 `UL_TYPE`: `LUI`
- `AU_TYPE` 또는 `UA_TYPE`: `AUIPC`
- `J_TYPE`: `JAL`
- `JL_TYPE`: `JALR`

핵심은 `opcode`가 명령어 큰 분류를 결정하고, 같은 분류 안에서 `funct3`와 `funct7`이 세부 연산을 가른다는 점이다.

예를 들면 다음처럼 읽는다.

- `ADD`와 `SUB`는 같은 `R-type`이지만 `funct7[5]`가 다르다.
- `SRL`과 `SRA`도 같은 shift 계열이지만 `funct7[5]` 차이로 구분한다.
- `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`는 같은 `B-type` 안에서 `funct3`로 갈린다.

즉 control unit의 역할은 결국 `opcode/funct3/funct7`을 받아서 `지금 datapath가 무엇을 해야 하는가`를 신호로 바꾸는 것이다.

## control unit과 datapath를 분리해서 읽기

`lecture_RV32I`는 이 분리를 더 노골적으로 보여 준다.  
`rv32i_control_unit.sv`가 decode와 제어 신호 생성을 맡고, `rv32i_datapath.sv`가 실제 데이터 흐름을 맡는다.  
`20260519_rv32i`는 같은 내용을 `rv32i_sv.sv` 안에 묶어 놓았지만 구조 자체는 거의 같다.

control unit이 만드는 대표 신호는 아래와 같다.

- `rf_we`: register file write enable
- `alu_src_sel` 또는 `alusrc_sel`: ALU 두 번째 입력으로 `rs2`를 쓸지 immediate를 쓸지 선택
- `alu_control`: ALU 연산 종류 선택
- `rf_src_sel` 또는 `rfsrc_sel`: write-back 값의 출처 선택
- `mem_mode`: `LB/LH/LW/LBU/LHU/SB/SH/SW` 같은 메모리 접근 크기 선택
- `dwe`: data memory write enable
- `branch`, `jal`, `jalr`: PC 갱신 경로 선택

datapath는 이 제어 신호를 받아 실제 값을 흘린다.

- register file에서 `rs1`, `rs2`를 읽는다.
- immediate generator가 명령어 비트에서 `imm`를 만든다.
- ALU가 연산 결과나 유효 주소를 계산한다.
- write-back mux가 ALU 결과, 메모리 읽기값, immediate, `PC+imm`, `PC+4` 중 하나를 골라 `rd`로 보낸다.
- PC 회로가 다음 명령어 주소를 정한다.

## PC, 주소 체계, 정렬을 함께 이해하기

이번 RV32I 코드에서 가장 자주 헷갈리는 부분이 주소 체계다.

먼저 ISA 관점에서 주소는 byte-addressed다.  
즉 주소 `0, 1, 2, 3`은 각각 1바이트 단위를 가리킨다.  
하지만 instruction과 register 폭은 32비트이므로, word 단위로 보면 시작 주소가 `0, 4, 8, 12`처럼 증가한다.

그래서 코드에서는 보통 아래처럼 읽는다.

- instruction memory 접근: `instr_addr[31:2]`
- data memory word index: `daddr[31:2]`
- byte lane 선택: `daddr[1:0]`

이 말은 아키텍처 주소는 byte 주소를 유지하되, 내부 메모리 배열은 word index로 접근한다는 뜻이다.  
즉 `byte addressing`과 `word array 구현`은 동시에 성립할 수 있다.

## program memory layout을 CPU 관점으로 보기

program memory layout은 보통 text/code, data, BSS, heap, stack 같은 영역으로 나뉜다.
하지만 CPU가 해당 주소를 보면서 `여기는 BSS`, `여기는 heap`이라고 직접 판단하는 것은 아니다.

| 영역 | software 관점 |
| --- | --- |
| text / code | instruction 저장 |
| data | 초기값이 있는 전역/static data |
| BSS | 초기값이 0인 전역/static data |
| heap | 동적 할당 영역 |
| stack | 함수 호출, local variable, return context |

이 영역 배치는 compiler/linker가 정하고, CPU 입장에서는 결국 `PC`가 instruction address를 만들고 `load/store`가 data address에 접근하는 동작으로만 보인다.
그래서 software section 이름과 hardware memory access를 구분해서 읽어야 한다.

## register file을 읽을 때 중요한 점

register file은 `x0 ~ x31`을 담고 있고, 두 개 읽기 포트와 한 개 쓰기 포트를 가진다.  
register file에서 반드시 기억할 점은 `x0`가 항상 `0`이어야 한다는 것이다.

`20260519_rv32i` 쪽 코드는 쓰기 단계에서 `WA != 0`을 확인해서 `x0`가 덮이지 않게 막고 있다.  
`lecture_RV32I` 쪽은 읽을 때 `raddr == 0`이면 강제로 `0`을 내보내는 방식이 들어가 있다.  
둘 다 학습용 구현이라는 점은 같지만, `x0` 보호를 어느 지점에서 하느냐는 구현 선택으로 볼 수 있다.

또 `20260519_rv32i`는 `TEST_SIMULATION` 구간에서 일부 레지스터를 양수와 음수로 미리 채워 둬서 `SLT`, `SLTU`, `SRA` 같은 연산을 바로 확인하기 좋게 만들어 두었다.

## immediate는 왜 형식마다 다르게 생겼는가

RISC-V 명령어는 형식마다 immediate 비트가 다른 위치에 박혀 있다.  
그래서 datapath 안에 immediate generator가 반드시 필요하다.

현재 구현에서 실제로 보이는 immediate 생성 규칙은 다음과 같다.

- `I-type`, `load`, `JALR`: 상위 비트를 부호 비트로 채워 sign extension
- `S-type`: `instr[31:25]`와 `instr[11:7]`를 이어 붙인 뒤 sign extension
- `B-type`: 비트가 흩어져 있으므로 순서를 다시 맞춰 branch offset 생성
- `U-type`: 상위 20비트를 그대로 두고 하위 12비트를 `0`으로 채움
- `J-type`: 점프 오프셋 비트를 다시 모아 `PC` 기준 큰 이동값 생성

즉 immediate generator는 단순 보조 블록이 아니라, instruction format을 hardware가 실제 주소/상수 값으로 바꾸는 핵심 단계다.

## 20260519_rv32i가 보여 주는 확장 포인트

`lecture_RV32I`가 구조를 분리해서 설명하는 데 유리하다면, `20260519_rv32i`는 그 구조가 실제 프로그램 실행으로 어떻게 커지는지 보여 준다.

- CPU 블록이 한 파일 안에 묶여 있어 전체 연결을 한 번에 보기 쉽다.
- `instruction_mem.sv` 안에 ALU, load/store, branch, jump 예제가 주석과 함께 들어 있다.
- `instruction_code.mem`, `instruction_code_2.mem`로 실제 machine code를 바꿔 넣을 수 있다.
- `compile_code/sum_counting.c`, `compile_code/buble_sort.c`가 있어서 C 코드에서 machine code로 내려가는 다음 단계와 이어진다.

핵심은 `RV32I는 추상 개념이 아니라, 이미 register file/ALU/memory/PC 회로로 쪼개서 읽을 수 있는 구조`라는 감각을 잡는 것이다.

## 핵심 정리

dedicated CPU는 특정 알고리즘 하나를 위한 datapath였다면, RV32I CPU는 instruction이 바뀌어도 같은 datapath를 재사용하는 범용 구조다.  
따라서 이제부터는 알고리즘 자체보다 `instruction format -> control signal -> datapath 동작`의 연결을 읽는 능력이 더 중요해진다.

## 연결 노트

- [[260518-dedicated-cpu-누적합]]
- [[260520-rv32i-memory-writeback]]
