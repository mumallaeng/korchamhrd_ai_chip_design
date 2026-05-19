# CPU 기본 구조 및 RISC-V R-Type 명령어 데이터 경로 설계

CPU는 명령어 메모리에서 명령어를 읽고, Register File에서 피연산자를 읽은 뒤, ALU에서 연산을 수행하는 구조로 설계함.  
기본 명령어 흐름은 `PC -> Instruction Memory -> Register File -> ALU -> Write Back` 경로로 구성함.  
본 설계는 32비트 데이터 경로와 RISC-V 명령어 형식을 기준으로 정의함.

## 1. CPU 기본 구성 요소

### 1.1 하드웨어 구성

- PC
  - Program Counter
  - 현재 실행할 명령어 주소 저장
  - 다음 명령어 주소 생성 경로 제공

- Register File
  - 범용 레지스터 집합
  - 두 개의 읽기 포트 제공
  - 하나의 쓰기 포트 제공

- Control Unit
  - 명령어 필드 해석
  - ALU 제어 신호 생성
  - Register File 쓰기 제어 신호 생성

- ALU
  - 산술 연산 수행
  - 논리 연산 수행
  - 비교 연산 수행

- Instruction Memory
  - ROM 기반 명령어 메모리
  - PC 주소 기반 명령어 출력

- Data Memory
  - RAM 기반 데이터 메모리
  - 데이터 읽기 수행
  - 데이터 쓰기 수행

## 2. RISC-V 명령어 형식

### 2.1 Core Instruction Formats

RISC-V 명령어는 32비트 길이를 사용한다.
명령어 형식은 `opcode`, `rd`, `rs1`, `rs2`, `funct3`, `funct7`, `imm` 필드 조합으로 구성된다.

| Format | Bit 31:27 | Bit 26:25 | Bit 24:20 | Bit 19:15 | Bit 14:12 | Bit 11:7 | Bit 6:0 |
|---|---|---|---|---|---|---|---|
| R-type | funct7 | funct7 | rs2 | rs1 | funct3 | rd | opcode |
| I-type | imm[11:0] | imm[11:0] | imm[11:0] | rs1 | funct3 | rd | opcode |
| S-type | imm[11:5] | imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode |
| B-type | imm[12\|10:5] | imm[12\|10:5] | rs2 | rs1 | funct3 | imm[4:1\|11] | opcode |
| U-type | imm[31:12] | imm[31:12] | imm[31:12] | imm[31:12] | imm[31:12] | rd | opcode |
| J-type | imm[20\|10:1\|11\|19:12] | imm[20\|10:1\|11\|19:12] | imm[20\|10:1\|11\|19:12] | imm[20\|10:1\|11\|19:12] | imm[20\|10:1\|11\|19:12] | rd | opcode |

### 2.2 R-Type 필드 구조

R-Type 명령어는 Register File의 두 소스 레지스터와 하나의 목적지 레지스터를 사용하는 형식임.

| 필드 | 비트 범위 | 비트 폭 | 설명 |
|---|---:|---:|---|
| funct7 | `[31:25]` | 7 | 세부 연산 구분 필드 |
| rs2 | `[24:20]` | 5 | 두 번째 소스 레지스터 주소 |
| rs1 | `[19:15]` | 5 | 첫 번째 소스 레지스터 주소 |
| funct3 | `[14:12]` | 3 | 연산 종류 구분 필드 |
| rd | `[11:7]` | 5 | 목적지 레지스터 주소 |
| opcode | `[6:0]` | 7 | 명령어 기본 형식 구분 필드 |

### 2.3 R-Type 필드 추출

```text
Instruction[31:25] -> funct7
Instruction[24:20] -> rs2
Instruction[19:15] -> rs1
Instruction[14:12] -> funct3
Instruction[11:7]  -> rd
Instruction[6:0]   -> opcode
````

### 2.4 Register File 연결 기준

| RISC-V 필드 | Register File 신호 | 설명         |
| --------- | ---------------- | ---------- |
| `rs1`     | `RA0`            | 첫 번째 읽기 주소 |
| `rs2`     | `RA1`            | 두 번째 읽기 주소 |
| `rd`      | `WA`             | 쓰기 주소      |

```text
Instruction[19:15] -> RA0
Instruction[24:20] -> RA1
Instruction[11:7]  -> WA
```

## 3. ADD 명령어 예시

### 3.1 명령어 표현

```asm
ADD rd = rs1 + rs2
```

### 3.2 레지스터 예시

```asm
x5 = x2 + x3
```

### 3.3 동작 의미

* `x2` 값을 Register File에서 읽음
* `x3` 값을 Register File에서 읽음
* ALU에서 `x2 + x3` 수행
* 결과를 `x5`에 저장함

### 3.4 데이터 흐름

```text
Instruction[19:15] -> rs1 -> RA0 -> x2
Instruction[24:20] -> rs2 -> RA1 -> x3
Instruction[11:7]  -> rd  -> WA  -> x5

RD0 = Register[x2]
RD1 = Register[x3]

ALU_Result = RD0 + RD1

Register[x5] = ALU_Result
```

## 4. 전체 데이터 경로

```text
                  ┌──────────────┐
                  │      PC      │
                  └──────┬───────┘
                         │
                         │ Instr_Addr
                         │ 32
                         ▼
            ┌────────────────────────┐
            │                        │
            │   Instruction Memory   │
            │        ROM             │
            │                        │
            └───────────┬────────────┘
                        │
                        │ Instr_Code / Instruction
                        │ 32
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    Instruction Field Split                  │
│                                                             │
│ Instruction[31:25] -> funct7                                │
│ Instruction[24:20] -> rs2                                   │
│ Instruction[19:15] -> rs1                                   │
│ Instruction[14:12] -> funct3                                │
│ Instruction[11:7]  -> rd                                    │
│ Instruction[6:0]   -> opcode                                │
└───────────────┬───────────────────────────────┬─────────────┘
                │                               │
                │                               ▼
                │                    ┌────────────────────┐
                │                    │    Control Unit    │
                │                    │ funct7             │
                │                    │ funct3             │
                │                    │ opcode             │
                │                    └─────────┬──────────┘
                │                              │
                │                              │ ALU_control
                │                              │ WE
                │                              ▼
                ▼
┌──────────────────────────────┐        ┌────────────────────┐
│        Register File         │        │        ALU         │
│                              │        │                    │
│ RA0 <- Instruction[19:15]    │ RD0 ──►│ A                  │
│ RA1 <- Instruction[24:20]    │ RD1 ──►│ B                  │
│ WA  <- Instruction[11:7]     │        │                    │
│ WE  <- Control Unit          │        │ ALU_Control        │
│ WD  <- ALU_Result            │        │                    │
│                              │        │ ALU_Result         │
└──────────────────────────────┘        └─────────┬──────────┘
                                                   │
                                                   │ 32
                                                   ▼
                                           Write Back to WD
```

## 5. Program Counter

### 5.1 정의

PC는 Program Counter를 의미한다.
PC는 현재 실행할 명령어 주소를 저장한다.
PC는 Instruction Memory의 `Instr_Addr`로 연결된다.

### 5.2 입력 신호

| 신호      | 비트 폭 | 설명        |
| ------- | ---: | --------- |
| clk     |    1 | PC 갱신 클럭  |
| rst     |    1 | PC 초기화 신호 |
| next_PC |   32 | 다음 명령어 주소 |

### 5.3 출력 신호

| 신호 | 비트 폭 | 설명        |
| -- | ---: | --------- |
| PC |   32 | 현재 명령어 주소 |

### 5.4 동작

* `clk` 기준으로 PC 갱신
* `rst` 활성화 시 PC 초기화
* 기본 다음 주소는 `PC + 4`
* 명령어 주소는 32비트 사용

### 5.5 PC 증가 회로

```text
             ┌──────────────┐
             │      PC      │
             └──────┬───────┘
                    │
                    │ 32
                    ▼
              ┌──────────┐
      4 ─────►│    +     │
              └────┬─────┘
                   │
                   │ 32
                   ▼
                next_PC
```

## 6. Instruction Memory

### 6.1 정의

Instruction Memory는 명령어를 저장하는 메모리임.
Instruction Memory는 ROM으로 구성함.
PC에서 전달된 주소를 기반으로 32비트 명령어를 출력함.

### 6.2 입력 신호

| 신호         | 비트 폭 | 설명        |
| ---------- | ---: | --------- |
| Instr_Addr |   32 | 명령어 주소    |
| RAddr      |   32 | 명령어 읽기 주소 |

### 6.3 출력 신호

| 신호         | 비트 폭 | 설명        |
| ---------- | ---: | --------- |
| Instr_Code |   32 | 명령어 코드    |
| Instr_Data |   32 | 명령어 데이터   |
| Instr_All  |   32 | 전체 명령어 비트 |
| RData      |   32 | 읽기 데이터    |

### 6.4 구조

```text
Instruction Memory
ROM

       Instr_Addr / RAddr
              │
              │ 32
              ▼
┌────────────────────────────┐
│                            │
│          Memory            │
│                            │
└──────────────┬─────────────┘
               │
               │ 32
               ▼
 Instr_Code / Instr_Data / Instr_All / RData
```

### 6.5 동작

* PC 출력이 `Instr_Addr`로 입력된다
* Instruction Memory는 해당 주소의 명령어를 읽는다
* 읽은 명령어는 32비트 `Instr_Code`로 출력된다
* `Instr_Code`는 필드 분리 후 Control Unit과 Register File로 전달된다

## 7. Instruction Field Split

### 7.1 정의

Instruction Field Split은 32비트 명령어에서 제어 필드와 레지스터 주소 필드를 분리하는 경로임.
R-Type 기준으로 `funct7`, `rs2`, `rs1`, `funct3`, `rd`, `opcode`를 분리함.

### 7.2 출력 경로

| 명령어 필드   |     비트 범위 | 연결 대상               |
| -------- | --------: | ------------------- |
| `funct7` | `[31:25]` | Control Unit        |
| `rs2`    | `[24:20]` | Register File `RA1` |
| `rs1`    | `[19:15]` | Register File `RA0` |
| `funct3` | `[14:12]` | Control Unit        |
| `rd`     |  `[11:7]` | Register File `WA`  |
| `opcode` |   `[6:0]` | Control Unit        |

### 7.3 구조

```text
Instruction[31:25] ─────► funct7 ─────► Control Unit
Instruction[14:12] ─────► funct3 ─────► Control Unit
Instruction[6:0]   ─────► opcode ─────► Control Unit

Instruction[24:20] ─────► rs2 ────────► Register File.RA1
Instruction[19:15] ─────► rs1 ────────► Register File.RA0
Instruction[11:7]  ─────► rd ─────────► Register File.WA
```

## 8. Register File

### 8.1 정의

Register File은 CPU 내부 레지스터 집합임.
Register File은 두 개의 소스 레지스터를 동시에 읽음.
Register File은 하나의 목적지 레지스터에 데이터를 씀.

### 8.2 입력 신호

| 신호  | 비트 폭 | 연결                        | 설명          |
| --- | ---: | ------------------------- | ----------- |
| RA0 |    5 | `Instruction[19:15]`      | `rs1` 읽기 주소 |
| RA1 |    5 | `Instruction[24:20]`      | `rs2` 읽기 주소 |
| WA  |    5 | `Instruction[11:7]`       | `rd` 쓰기 주소  |
| WE  |    1 | Control Unit              | 쓰기 활성화      |
| WD  |   32 | ALU Result 또는 Memory Data | 쓰기 데이터      |
| rst |    1 | Reset                     | 초기화         |

### 8.3 출력 신호

| 신호  | 비트 폭 | 연결      | 설명          |
| --- | ---: | ------- | ----------- |
| RD0 |   32 | ALU `A` | 첫 번째 읽기 데이터 |
| RD1 |   32 | ALU `B` | 두 번째 읽기 데이터 |

### 8.4 구조

```text
Register File

Instruction[19:15] ───► RA0
Instruction[24:20] ───► RA1
Instruction[11:7]  ───► WA
Control Unit       ───► WE
ALU_Result         ───► WD

┌──────────────────────────────┐
│                              │
│        Register Array        │
│                              │
│   x0                         │
│   x1                         │
│   x2                         │
│   x3                         │
│   ...                        │
│   x31                        │
│                              │
└──────────────┬───────────────┘
               │
       ┌───────┴────────┐
       │                │
       ▼                ▼
      RD0              RD1
       │                │
       │ 32             │ 32
       ▼                ▼
      ALU.A            ALU.B
```

### 8.5 동작

* `RA0`는 `rs1` 필드로부터 생성된다
* `RA1`는 `rs2` 필드로부터 생성된다
* `WA`는 `rd` 필드로부터 생성된다
* `RD0`는 `Register[rs1]` 값을 출력한다
* `RD1`는 `Register[rs2]` 값을 출력한다
* `WE`가 활성화되면 `WD`가 `Register[rd]`에 저장된다
* R-Type ADD 명령에서는 `WD = ALU_Result`이다

## 9. Control Unit

### 9.1 정의

Control Unit은 명령어의 `funct7`, `funct3`, `opcode` 필드를 해석함.
Control Unit은 ALU 연산을 선택하는 `ALU_Control` 신호를 생성함.
Control Unit은 Register File 쓰기 활성화 신호 `WE`를 생성함.

### 9.2 입력 신호

| 신호     | 비트 폭 |    명령어 비트 | 설명        |
| ------ | ---: | --------: | --------- |
| funct7 |    7 | `[31:25]` | 세부 연산 구분  |
| funct3 |    3 | `[14:12]` | 연산 종류 구분  |
| opcode |    7 |   `[6:0]` | 명령어 형식 구분 |

### 9.3 출력 신호

| 신호          | 비트 폭 | 설명                   |
| ----------- | ---: | -------------------- |
| ALU_Control |    3 | ALU 연산 선택            |
| WE          |    1 | Register File 쓰기 활성화 |

### 9.4 구조

```text
Instruction[31:25] ───► funct7
Instruction[14:12] ───► funct3
Instruction[6:0]   ───► opcode

┌──────────────────────────────┐
│         Control Unit         │
│                              │
│  Decode funct7               │
│  Decode funct3               │
│  Decode opcode               │
│                              │
└───────────┬──────────┬───────┘
            │          │
            │          │
            ▼          ▼
      ALU_Control      WE
```

### 9.5 R-Type 제어 동작

* `opcode`로 R-Type 명령 여부 판별
* `funct3`로 기본 연산 종류 판별
* `funct7`로 ADD/SUB 등 세부 연산 판별
* Register File 쓰기 명령이면 `WE = 1`
* ALU 연산에 맞는 `ALU_Control` 생성

## 10. ALU

### 10.1 정의

ALU는 Register File에서 읽은 두 값을 입력으로 받음.
ALU는 Control Unit에서 생성한 `ALU_Control`에 따라 연산을 수행함.
ALU 결과는 Register File의 Write Data로 되돌아감.

### 10.2 입력 신호

| 신호          | 비트 폭 | 연결                  | 설명        |
| ----------- | ---: | ------------------- | --------- |
| A           |   32 | Register File `RD0` | 첫 번째 피연산자 |
| B           |   32 | Register File `RD1` | 두 번째 피연산자 |
| ALU_Control |    3 | Control Unit        | 연산 선택 신호  |

### 10.3 출력 신호

| 신호         | 비트 폭 | 설명        |
| ---------- | ---: | --------- |
| ALU_Result |   32 | ALU 연산 결과 |

### 10.4 구조

```text
Register File.RD0 ─────► A
                         │
                         ▼
                   ┌──────────┐
ALU_Control ──────►│   ALU    │──────► ALU_Result
                   └──────────┘
                         ▲
                         │
Register File.RD1 ─────► B
```

### 10.5 동작

* `A`는 `Register[rs1]` 값이다
* `B`는 `Register[rs2]` 값이다
* `ALU_Control`은 연산 종류를 결정한다
* `ALU_Result`는 32비트 결과로 출력된다
* R-Type 명령에서는 `ALU_Result`가 Register File의 `WD`로 연결된다

## 11. ALU Control 매핑

### 11.1 ALU Control 정의

`ALU_Control`은 3비트 제어 신호이다.
`funct7`, `funct3`, `opcode` 해석 결과로 생성된다.

### 11.2 매핑 테이블

| ALU_Control | Function | 연산 의미         | 결과식                            |    |
| ----------- | -------- | ------------- | ------------------------------ | -- |
| `000`       | ADD      | 덧셈            | `ALU_Result = A + B`           |    |
| `001`       | SUB      | 뺄셈            | `ALU_Result = A - B`           |    |
| `010`       | AND      | 비트 AND        | `ALU_Result = A & B`           |    |
| `011`       | OR       | 비트 OR         | `ALU_Result = A                | B` |
| `100`       | SLT      | Set Less Than | `ALU_Result = (A < B) ? 1 : 0` |    |

### 11.3 미사용 코드

* `101`은 미정의 또는 예비 코드로 둠
* `110`은 미정의 또는 예비 코드로 둠
* `111`은 미정의 또는 예비 코드로 둠

## 12. R-Type ADD 데이터 경로

### 12.1 명령어

```asm
ADD x5, x2, x3
```

### 12.2 명령어 의미

```text
x5 = x2 + x3
```

### 12.3 필드 연결

| 명령어 필드   | 값             | 연결 대상               |
| -------- | ------------- | ------------------- |
| `rs1`    | `x2`          | Register File `RA0` |
| `rs2`    | `x3`          | Register File `RA1` |
| `rd`     | `x5`          | Register File `WA`  |
| `funct3` | ADD 관련 코드     | Control Unit        |
| `funct7` | ADD 관련 코드     | Control Unit        |
| `opcode` | R-Type opcode | Control Unit        |

### 12.4 실행 순서

```text
1. PC가 Instruction Memory에 Instr_Addr 제공
2. Instruction Memory가 ADD 명령어 출력
3. Instruction[19:15]가 RA0로 전달된다
4. Instruction[24:20]가 RA1로 전달된다
5. Instruction[11:7]이 WA로 전달된다
6. Instruction[31:25], Instruction[14:12], Instruction[6:0]이 Control Unit으로 전달된다
7. Control Unit이 ALU_Control = 000 생성
8. Control Unit이 Register File WE = 1 생성
9. Register File이 x2 값을 RD0로 출력
10. Register File이 x3 값을 RD1로 출력
11. ALU가 RD0 + RD1 수행
12. ALU_Result가 Register File WD로 전달된다
13. WE 활성 상태에서 ALU_Result가 x5에 저장된다
14. PC가 PC + 4로 갱신된다
```

### 12.5 경로 표현

```text
PC
 └─► Instruction Memory
      └─► Instruction[31:0]
           ├─► Instruction[31:25] -> funct7 -> Control Unit
           ├─► Instruction[14:12] -> funct3 -> Control Unit
           ├─► Instruction[6:0]   -> opcode -> Control Unit
           ├─► Instruction[19:15] -> rs1 -> RA0
           ├─► Instruction[24:20] -> rs2 -> RA1
           └─► Instruction[11:7]  -> rd  -> WA

Register File
 ├─► RD0 -> ALU.A
 └─► RD1 -> ALU.B

Control Unit
 └─► ALU_Control -> ALU

ALU
 └─► ALU_Result -> Register File.WD

Control Unit
 └─► WE -> Register File.WE
```

## 13. Data Memory

### 13.1 정의

Data Memory는 데이터 저장 공간이다.
Data Memory는 RAM으로 구성한다.
Data Memory는 Load와 Store 계열 명령에서 사용된다.

### 13.2 입력 신호

| 신호    | 비트 폭 | 설명             |
| ----- | ---: | -------------- |
| WE    |    1 | 데이터 쓰기 활성화     |
| Addr  |   32 | 데이터 메모리 주소     |
| WData |   32 | 데이터 메모리 쓰기 데이터 |

### 13.3 출력 신호

| 신호    | 비트 폭 | 설명             |
| ----- | ---: | -------------- |
| RData |   32 | 데이터 메모리 읽기 데이터 |

### 13.4 구조

```text
Data Memory
RAM

              ┌────────────────────────┐
WE    ───────►│                        │
Addr  ───────►│      Data Memory       │──────► RData
WData ───────►│                        │
              └────────────────────────┘
```

### 13.5 동작

* `Addr`는 접근할 데이터 주소를 지정함
* `WData`는 저장할 데이터를 제공함
* `WE = 1`이면 쓰기 동작 수행
* `WE = 0`이면 읽기 동작 수행
* `RData`는 Load 명령에서 Register File의 `WD`로 연결 가능함

## 14. 신호 폭 정의

| 신호 그룹              | 신호          | 비트 폭 |
| ------------------ | ----------- | ---: |
| PC                 | PC          |   32 |
| PC                 | next_PC     |   32 |
| PC                 | Instr_Addr  |   32 |
| Instruction Memory | Instr_Code  |   32 |
| Instruction Memory | Instr_Data  |   32 |
| Instruction Memory | Instr_All   |   32 |
| Instruction Field  | funct7      |    7 |
| Instruction Field  | rs2         |    5 |
| Instruction Field  | rs1         |    5 |
| Instruction Field  | funct3      |    3 |
| Instruction Field  | rd          |    5 |
| Instruction Field  | opcode      |    7 |
| Register File      | RA0         |    5 |
| Register File      | RA1         |    5 |
| Register File      | WA          |    5 |
| Register File      | WE          |    1 |
| Register File      | WD          |   32 |
| Register File      | RD0         |   32 |
| Register File      | RD1         |   32 |
| ALU                | A           |   32 |
| ALU                | B           |   32 |
| ALU                | ALU_Control |    3 |
| ALU                | ALU_Result  |   32 |
| Data Memory        | WE          |    1 |
| Data Memory        | Addr        |   32 |
| Data Memory        | WData       |   32 |
| Data Memory        | RData       |   32 |
| Clock              | clk         |    1 |
| Reset              | rst         |    1 |

## 15. 모듈별 연결 요약

| 출발 모듈              | 출발 신호       | 도착 모듈              | 도착 신호       | 비트 폭 |
| ------------------ | ----------- | ------------------ | ----------- | ---: |
| PC                 | PC          | Instruction Memory | Instr_Addr  |   32 |
| Instruction Memory | Instr_Code  | Register File      | RA0         |    5 |
| Instruction Memory | Instr_Code  | Register File      | RA1         |    5 |
| Instruction Memory | Instr_Code  | Register File      | WA          |    5 |
| Instruction Memory | Instr_Code  | Control Unit       | funct7      |    7 |
| Instruction Memory | Instr_Code  | Control Unit       | funct3      |    3 |
| Instruction Memory | Instr_Code  | Control Unit       | opcode      |    7 |
| Control Unit       | WE          | Register File      | WE          |    1 |
| Register File      | RD0         | ALU                | A           |   32 |
| Register File      | RD1         | ALU                | B           |   32 |
| Control Unit       | ALU_Control | ALU                | ALU_Control |    3 |
| ALU                | ALU_Result  | Register File      | WD          |   32 |
| ALU                | ALU_Result  | Data Memory        | Addr        |   32 |
| Register File      | RD1         | Data Memory        | WData       |   32 |
| Data Memory        | RData       | Register File      | WD          |   32 |

## 16. 설계 기준

* 전체 명령어 폭은 32비트로 정의함
* 전체 데이터 경로는 32비트로 정의함
* Register File 주소 폭은 5비트로 정의함
* RISC-V R-Type 필드 구조를 기준으로 Register File 주소를 연결함
* `rs1`은 `RA0`에 연결함
* `rs2`는 `RA1`에 연결함
* `rd`는 `WA`에 연결함
* `funct7`, `funct3`, `opcode`는 Control Unit에 연결함
* Control Unit은 `ALU_Control`과 `WE`를 생성함
* ALU Control은 3비트로 정의함
* ADD는 `ALU_Control = 000`으로 정의함
* SUB는 `ALU_Control = 001`으로 정의함
* AND는 `ALU_Control = 010`으로 정의함
* OR은 `ALU_Control = 011`으로 정의함
* SLT는 `ALU_Control = 100`으로 정의함
* PC는 기본적으로 `PC + 4`로 갱신함
* Instruction Memory는 ROM으로 구성함
* Data Memory는 RAM으로 구성함

```
