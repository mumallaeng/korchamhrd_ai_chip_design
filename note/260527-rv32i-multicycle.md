# 26-05-27 - RV32I multi-cycle control/datapath

`single-cycle RV32I` 다음 단계에서는 instruction 실행을 여러 cycle로 나눌 때 control과 datapath가 어떻게 달라지는지를 봐야 한다.
중요한 구분은 `multi-cycle`과 `pipeline`을 섞지 않는 것이다. 둘 다 instruction 실행 단계를 나눈다는 점은 같지만, multi-cycle은 한 instruction을 여러 cycle에 걸쳐 처리하고, pipeline은 여러 instruction을 서로 다른 stage에 겹쳐 처리한다.

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | RV32I multi-cycle 구조, FSM 기반 control unit, stage register가 들어간 datapath |
| 이전 연결 | `0521~0522`에서 본 C program, stack frame, load/store, branch/jump 실행 흐름 |
| 핵심 흐름 | `FETCH -> DECODE -> EXECUTE -> MEMORY -> WRITE_BACK`로 instruction 실행을 나눠 읽기 |
| 주의점 | multi-cycle은 pipeline이 아니다. branch predictor, hazard 처리는 pipeline 확장 주제 |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260527_RV32I_Multi_Cycle/.../rv32i_multi_cycle.sv` | `27-63` | `control_unit`과 `datapath` 연결 |
| `helloHDL/260527_RV32I_Multi_Cycle/.../control_unit.sv` | `74-80` | `FETCH`, `DECODE`, `EXECUTE`, `MEMORY`, `WRITE_BACK` state 정의 |
| `helloHDL/260527_RV32I_Multi_Cycle/.../control_unit.sv` | `92-116` | opcode에 따른 next-state 흐름 |
| `helloHDL/260527_RV32I_Multi_Cycle/.../control_unit.sv` | `118-206` | state별 `rf_we`, `dwe`, `pc_en`, `ir_we`, `rf_src_sel` 생성 |
| `helloHDL/260527_RV32I_Multi_Cycle/.../datapath.sv` | `37-42` | `ir_we`가 켜진 cycle에 `instr_reg` 갱신 |
| `helloHDL/260527_RV32I_Multi_Cycle/.../datapath.sv` | `73-92` | decode stage 값인 `rs1`, `rs2`, `imm` 저장 |
| `helloHDL/260527_RV32I_Multi_Cycle/.../datapath.sv` | `131-150` | execute 결과와 PC 후보를 다음 cycle용 register에 저장 |

## single-cycle에서 multi-cycle로 넘어가는 이유

| 구조 | 한 instruction 처리 방식 | 장점 | 단점 |
| --- | --- | --- | --- |
| `single-cycle` | fetch, decode, execute, memory, write-back을 한 clock 안에 끝냄 | 제어가 단순하고 한 instruction이 한 cycle에 끝남 | clock period가 가장 긴 combinational path에 묶임 |
| `multi-cycle` | instruction을 여러 state/cycle로 나눠 처리 | 한 cycle의 combinational path를 줄이고 hardware 일부를 재사용 가능 | instruction당 cycle 수가 늘어남 |
| `pipeline` | 여러 instruction을 stage별로 겹쳐 실행 | throughput을 높일 수 있음 | hazard, flush, stall, forwarding, branch prediction 필요 |

즉 multi-cycle은 `single-cycle이 느린 이유`를 해결하려는 중간 단계다.
한 instruction의 전체 latency는 늘 수 있지만, 각 cycle에서 해야 할 일이 줄어들기 때문에 clock period를 더 짧게 잡을 수 있다.

single-cycle의 최악 경로는 register file 또는 PC register에서 출발해 조합논리를 지나 다시 register file/PC에 저장되는 경로로 본다.
R-type은 register file read -> ALU -> register file write-back, load는 register file read -> ALU address 계산 -> data memory read -> write-back까지 이어진다.
branch/jump는 PC와 register 값을 기준으로 target을 계산해 PC register로 되돌린다.
multi-cycle 코드는 `instr_reg`, decode/exe/writeback stage register와 `pc_en`, `rf_we` 같은 enable 신호로 이 긴 경로를 state 경계마다 끊는다.

## 현재 multi-cycle FSM 흐름

현재 `control_unit.sv`의 state 흐름은 아래처럼 읽으면 된다.

| state | 역할 | 다음 state |
| --- | --- | --- |
| `FETCH` | instruction memory에서 받은 `instr_code`를 `instr_reg`에 저장 | `DECODE` |
| `DECODE` | register file read와 immediate 준비 | `EXECUTE` |
| `EXECUTE` | ALU 연산, branch/jump 판단, load/store 주소 계산 | load/store면 `MEMORY`, 나머지는 `FETCH` |
| `MEMORY` | store write 또는 load read 대기 | store는 `FETCH`, load는 `WRITE_BACK` |
| `WRITE_BACK` | load 결과를 register file에 기록 | `FETCH` |

여기서 `R-type`, `I-type`, `B-type`, `U-type`, `JAL/JALR`은 `EXECUTE`에서 처리 후 바로 다음 instruction fetch로 돌아간다.
반면 `load/store`는 주소 계산 뒤 data memory 접근이 필요하므로 `MEMORY` state를 한 번 더 거친다. `load`는 메모리에서 읽은 값을 register에 써야 하므로 `WRITE_BACK`까지 간다.

## control signal을 state 기준으로 읽기

| state | 주요 제어 | 의미 |
| --- | --- | --- |
| `FETCH` | `ir_we=1` | 현재 `instr_code`를 instruction register에 저장 |
| `EXECUTE` + R/I | `rf_we=1`, `rf_src_sel=0`, `pc_en=1` | ALU 결과를 register에 쓰고 PC 갱신 |
| `EXECUTE` + B | `branch=1`, `pc_en=1` | ALU 비교 결과 `b_taken`에 따라 PC 분기 |
| `EXECUTE` + U/AU | `rf_src_sel=2/3`, `pc_en=1` | `LUI` 또는 `AUIPC` 결과를 register에 쓰기 |
| `EXECUTE` + J/JALR | `jal=1`, `jalr` 선택, `rf_src_sel=4`, `pc_en=1` | target으로 PC 이동, `PC+4`를 link address로 저장 |
| `EXECUTE` + load/store | `alu_src_sel=1`, `alu_control=ADD` | `rs1 + imm`로 data memory 주소 계산 |
| `MEMORY` + store | `dwe=1`, `mem_mode=funct3`, `pc_en=1` | data memory write 후 다음 instruction으로 이동 |
| `WRITE_BACK` + load | `rf_we=1`, `rf_src_sel=1`, `pc_en=1` | data memory read 값을 register file에 write-back |

이 구조를 보면 control unit은 단순히 opcode를 한 번 decode하는 블록이 아니라, `현재 state + opcode` 조합으로 datapath가 이번 cycle에 무엇을 해야 하는지 결정하는 FSM이다.

## datapath에서 stage register가 하는 일

multi-cycle datapath에는 값을 다음 cycle까지 들고 가기 위한 register가 들어간다.

| register | 역할 |
| --- | --- |
| `instr_reg` | fetch된 instruction을 이후 state에서 계속 사용 |
| `o_dec_rs1`, `o_dec_rs2`, `o_dec_imm` | decode 단계에서 읽은 source register와 immediate 보관 |
| `o_exe_alu` | execute 단계의 ALU 결과를 memory 단계 주소로 사용 |
| `o_wb_drdata` | data memory read 결과를 write-back 단계로 넘김 |

single-cycle에서는 같은 clock 안에서 `instr_code -> control -> ALU -> memory -> write-back`이 한 번에 이어진다.
multi-cycle에서는 중간 값을 register에 저장해 두고, 다음 cycle의 state가 그 값을 이어 받아 사용한다.

## load/store가 multi-cycle에서 가장 잘 보이는 이유

load/store는 multi-cycle 분할이 왜 필요한지 가장 잘 보여 준다.

```text
EXECUTE: rs1 + imm 계산 -> data memory address 생성
MEMORY: address로 RAM read/write
WRITE_BACK: load라면 read data를 rd에 저장
```

store는 register file에 다시 쓸 값이 없으므로 `MEMORY`에서 끝난다.
load는 memory read 결과를 `rd`에 써야 하므로 `WRITE_BACK` state가 필요하다.

이 차이를 보면 `R-type은 write-back이 있다`, `store는 write-back이 없다` 같은 문장을 state 흐름으로 직접 확인할 수 있다.

## pipeline과 hazard는 다음 단계 주제

원문 메모에 있던 branch predictor, bubble, hazard는 multi-cycle 자체보다 pipeline 확장 주제에 가깝다.

| pipeline 문제 | 의미 | 대표 처리 |
| --- | --- | --- |
| structural hazard | 같은 cycle에 같은 hardware 자원을 두 instruction이 요구 | resource 분리 또는 stall |
| data hazard | 이전 instruction 결과가 아직 준비되지 않았는데 다음 instruction이 사용 | forwarding 또는 bubble |
| control hazard | branch/jump target이 확정되기 전에 다음 instruction을 가져옴 | flush, stall, branch prediction |

multi-cycle은 instruction을 겹쳐 실행하지 않으므로 기본 구조에서는 pipeline hazard가 본격적으로 발생하지 않는다.
다만 stage를 `FETCH/DECODE/EXECUTE/MEMORY/WB`로 나누는 사고방식이 pipeline으로 넘어가는 준비 단계가 된다.

## 핵심 정리

multi-cycle RV32I는 single-cycle datapath를 그대로 길게 늘인 것이 아니라, instruction 실행을 state별로 끊고 중간 값을 register에 저장하면서 control unit을 FSM으로 바꾼 구조다.
pipeline은 여기서 한 단계 더 나아가 여러 instruction을 겹쳐 실행하는 확장이고, 그때부터 hazard와 branch prediction이 본격 문제가 된다.

## 구현 검토 포인트

- `datapath.sv`에는 `o_exe_rs2` register가 있지만 현재 `dwdata`는 `o_dec_rs2`에서 직접 나간다. store data를 어느 stage 값으로 고정하는지는 구현 검토 포인트다.

## 연결 노트

- [[260522-calling-convention-stack-frame]]
- [[260528-pipeline-memory-map-apb]]
