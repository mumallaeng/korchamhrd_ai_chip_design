# 26-05-20 - RV32I memory path와 write-back 경로

RV32I는 단순히 `명령어 형식이 있다` 수준으로 볼 것이 아니라, `load/store`, `branch`, `jump`, `write-back`이 datapath 안에서 어떻게 연결되는지 함께 읽어야 한다.
`lecture_RV32I`를 `R/I/load/store만 있는 최소 구조`로 축소해서 보면 안 된다. 현재 구현에는 branch, `JAL/JALR`, `LUI/AUIPC`를 처리하는 경로까지 이미 들어 있다.

## memory access는 ALU와 분리된 기능이 아니다

RV32I에서 메모리 접근은 독립 마법이 아니라 ALU 결과를 주소로 쓰는 동작이다.

- `load/store`의 유효 주소는 기본적으로 `rs1 + imm`로 계산한다.
- 이 덧셈은 ALU가 맡는다.
- 계산 결과가 `daddr`로 나간다.
- store라면 `rs2` 값이 `dwdata`로 data memory에 전달된다.
- load라면 data memory가 `drdata`를 만들고, 그 값이 write-back mux를 거쳐 `rd`로 들어간다.

즉 `load/store 경로`를 이해하려면 메모리만 보면 안 되고, `register file -> immediate -> ALU -> data memory -> write-back` 전체를 한 덩어리로 봐야 한다.

## control signal을 명령어별 계약으로 읽기

control unit은 명령어를 보고 datapath에 계약을 내려 준다.  
대표적으로 아래처럼 읽으면 된다.

### R-type

- `rf_we = 1`
- ALU 두 번째 입력은 `rs2`
- write-back 값은 ALU 결과
- data memory는 쓰지 않음
- PC는 기본적으로 `PC + 4`

즉 `ADD`, `SUB`, `SLT`, `SRA` 같은 일반 ALU 연산이 여기에 해당한다.

### I-type

- `rf_we = 1`
- ALU 두 번째 입력은 sign-extended immediate
- write-back 값은 ALU 결과
- data memory는 쓰지 않음

즉 `ADDI`, `SLTI`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI` 같은 immediate 연산이다.

### shift 계열

shift 계열은 ALU 연산이지만, 곱셈/나눗셈처럼 반복 cycle을 돌리는 동작으로 보면 안 된다.
하나의 instruction에서 bit 위치를 이동시키는 조합논리 연산으로 읽는다.

| 명령 | 의미 |
| --- | --- |
| `SLL` / `SLLI` | bit를 왼쪽으로 밀어 2의 n승을 곱한 효과를 만듦 |
| `SRL` / `SRLI` | bit를 오른쪽으로 밀고 상위 bit를 `0`으로 채움 |
| `SRA` / `SRAI` | bit를 오른쪽으로 밀되 sign bit를 유지 |

따라서 `SRL`과 `SRA`의 차이는 data memory의 sign/zero extension과 비슷하게, 빈 상위 bit를 무엇으로 채우는가에 있다.
unsigned처럼 보면 `SRL`, signed 값을 유지해야 하면 `SRA` 관점으로 읽는다.

### Load

- `rf_we = 1`
- ALU는 `rs1 + imm`로 주소 계산
- `mem_mode = funct3`
- write-back 값은 data memory 출력
- `dwe = 0`

따라서 `LB/LH/LW/LBU/LHU`는 모두 제어 골격은 같고, 실제 차이는 `mem_mode`가 결정한다.

### Store

- `rf_we = 0`
- ALU는 `rs1 + imm`로 주소 계산
- `dwdata = rs2`
- `mem_mode = funct3`
- `dwe = 1`

즉 `SB/SH/SW`는 결국 `어느 크기로, 어느 lane에 쓸 것인가`를 memory block이 결정하는 구조다.

### Branch, Jump, Upper-immediate

현재 구현에는 이 경로도 이미 있다.

- `B-type`: ALU 비교 결과 `b_taken`과 `branch` 신호로 PC 분기
- `JAL/JALR`: target 주소로 점프하면서 `PC + 4`를 `rd`에 저장
- `LUI`: immediate 자체를 write-back
- `AUIPC`: `PC + imm`를 write-back

즉 write-back mux가 여러 입력을 가져야 하는 이유가 바로 여기서 드러난다.

## immediate generator가 실제로 하는 일

immediate는 명령어 형식마다 배치가 달라서, 한 가지 공식으로 처리되지 않는다.

### I-type과 load, JALR

`instr[31:20]`을 sign extension해서 32비트로 만든다.  
그래서 음수 offset, 음수 immediate도 그대로 표현 가능하다.

### S-type

store는 immediate가 두 조각으로 쪼개져 있다.  
`instr[31:25]`와 `instr[11:7]`을 다시 이어 붙인 뒤 sign extension해야 한다.

load/store에서 immediate는 base register인 `rs1`에 더해지는 signed offset이다.
구현도 load(`IL_TYPE`)와 store(`S_TYPE`)에서 ALU 두 번째 입력으로 `imm_extend`를 선택하고, ALU 결과를 `daddr`로 넘긴다.
따라서 `rs1 + imm` 주소 계산을 읽을 때 imm은 sign extension된 offset으로 보아야 한다.

### B-type

branch offset은 비트가 더 흩어져 있다.  
그래서 `instr[31]`, `instr[7]`, `instr[30:25]`, `instr[11:8]`, 마지막 `0` 비트를 조합해 branch target offset을 만든다.

### U-type과 J-type

- `LUI`, `AUIPC`는 상위 20비트를 그대로 쓰고 하위 12비트를 `0`으로 채운다.
- `JAL`은 점프 오프셋 비트를 다시 모아 `PC + imm` 형태로 사용한다.

즉 branch/jump가 추가되면 immediate generator가 단순 상수 생성기가 아니라 `제어 흐름 주소 생성기` 역할까지 하게 된다.

## data memory를 읽을 때 꼭 분리해야 하는 것

data memory는 내부 배열이 32비트 word 단위지만, 외부 인터페이스는 byte-addressed 규칙을 따른다.
이 점을 이해하지 못하면 `LB/LH/SB/SH`가 왜 복잡해지는지 잡히지 않는다.

### word index와 lane 선택

- `daddr[31:2]`: 어떤 word를 읽거나 쓸지
- `daddr[1:0]`: 그 word 안에서 어떤 byte lane 또는 halfword lane을 쓸지

즉 address가 32비트라고 해서 메모리가 무조건 바이트 배열일 필요는 없다.  
이 구현은 word array를 쓰되, 하위 비트로 lane을 선택하는 쪽을 택했다.

### load 계열

- `LW`: word 전체를 그대로 읽음
- `LB`: 선택한 1바이트를 꺼낸 뒤 sign extension
- `LBU`: 선택한 1바이트를 꺼낸 뒤 zero extension
- `LH`: 선택한 2바이트를 꺼낸 뒤 sign extension
- `LHU`: 선택한 2바이트를 꺼낸 뒤 zero extension

따라서 `sign extension`과 `zero extension`은 추상 개념이 아니라 data memory 출력 조합논리 안에서 실제 비트 연결로 구현된다.

### store 계열

- `SW`: word 전체를 덮어씀
- `SH`: 하위 또는 상위 16비트 lane만 갱신
- `SB`: 4개 byte lane 중 하나만 갱신

이 구조를 보면 `SB`와 `SH`는 결국 partial write다.  
즉 한 word 전체를 바꾸는 것이 아니라 일부 비트만 선택적으로 바꾸는 동작이다.

## write-back mux가 왜 5개 입력까지 필요해지는가

`lecture_RV32I`와 `20260519_rv32i` 모두 write-back mux를 두고 있고, 여기서 RV32I가 범용 CPU가 되는 이유가 잘 보인다.

write-back 후보는 보통 아래 다섯 가지다.

- ALU 결과
- data memory 읽기값
- immediate 자체
- `PC + imm`
- `PC + 4`

명령어에 따라 대응 관계를 읽으면 다음과 같다.

- `R-type`, `I-type`: ALU 결과
- `load`: data memory 읽기값
- `LUI`: immediate
- `AUIPC`: `PC + imm`
- `JAL`, `JALR`: `PC + 4`

즉 RV32I CPU는 `연산 결과만 rd로 보내는 구조`가 아니라, 명령어 종류에 따라 `rd`가 받을 값의 성격 자체가 달라진다.

## branch와 jump에서 PC가 바뀌는 방식

branch와 jump를 이해할 때는 `PC는 무조건 +4`라는 습관을 버려야 한다.

### branch

ALU가 비교를 수행하고 `b_taken`을 만든다.  
control unit이 `branch`를 켜면, PC 회로는 `branch && b_taken`이 참일 때 `PC + imm` 쪽을 고른다.

### JAL

`JAL`은 무조건 점프다.

- target 주소는 `PC + imm`
- 동시에 현재 명령어의 다음 주소인 `PC + 4`를 `rd`에 남긴다

즉 `점프`와 `복귀 주소 저장`이 한 번에 일어난다.

### JALR

`JALR`은 `rs1 + imm`을 기준으로 점프한다.  
함수 복귀나 간접 점프를 만들 때 필요한 이유가 여기 있다.

즉 `PC mux`를 읽을 때는 `기본 증가`, `branch target`, `jump target`, `register-based jump target`이 어떻게 구분되는지를 봐야 한다.

## 핵심 정리

핵심은 `RV32I는 ALU만 있는 CPU가 아니라, memory path와 control-flow path까지 포함된 구조`라는 점이다.
구현 안에 `load/store`, `sign/zero extension`, `branch`, `JAL/JALR`, `LUI/AUIPC`, `PC+4 write-back`이 모두 보이므로, software 예제는 이 경로를 기준으로 읽으면 된다.

## 연결 노트

- [[260519-rv32i-datapath]]
- [[260521-c-to-instruction-memory]]
