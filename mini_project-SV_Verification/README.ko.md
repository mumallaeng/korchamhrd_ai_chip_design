[English](README.md) | 한국어

# Verification of UART FIFO Loopback Using SystemVerilog

김연우

2026.05.12 ~ 2026.05.17

## 1. 개요 (Overview)

### 1.1 목적 및 목표

이번 프로젝트의 목적은 기존 Verilog 학습 범위 중에 UART loopback 구조 UART RX -> FIFO -> UART TX를 SystemVerilog로 다시 작성하고, 그 과정에서 설계와 검증이 어떻게 더 명확해지는지 확인하는 것이다. 단순히 문법만 바꾸는 것이 아니라, 설계 의도 표현과 검증 역할 분리가 실제 RTL과 testbench에서 어떻게 달라지는지를 구현 결과로 확인하는 것을 목표로 했다. 핵심 목표는 다음과 같다.

- 외부 rx로 들어온 serial UART 데이터를 내부에서 byte로 복원하고, FIFO에 저장한 뒤, 다시 serial tx로 내보내는 buffered loopback path를 구현한다.
- 기존 Verilog식 표현에서 드러나는 wire/reg, always, 상태 표현, TB 역할 혼재 문제를 SystemVerilog 기준으로 개선한다.
- 모듈 TB 3개와 top TB 1개를 self-checking 구조로 구성하고, PASS/FAIL 기준을 명확히 한다.

이번 프로젝트에서 바뀐 핵심은 기능 구조 자체보다, 기존에 학습한 내용을 SystemVerilog 기준으로 다시 정리하고 검증 기준을 명확하게 만든 점이다.

### 1.2 Verilog에서 불편했던 점

| 항목 | Verilog 표현 | 단점 |
|---|---|---|
| 순차/조합 block 구분 | always @(posedge clk), always @(*) | 둘 다 always로 시작해 sensitivity와 내부 코드를 같이 봐야 block 의도를 판단 가능 |
| 신호 선언 구분 | wire, reg | assign와 procedural block 기준으로 나뉘어, 선언만 보고 역할을 읽기 번거로움 |
| reg 의미 | reg state;, reg y; | 이름은 register에서 왔지만 조합 논리 block에서도 선언될 수 있어 플립플롭 여부를 바로 읽기 어려움 |
| FSM 상태 표현 | 2'b00, 2'b01, parameter IDLE = 0 | 숫자와 이름이 분리돼 state 의미를 코드에서 바로 읽기 어려움 |
| 데이터 묶음 표현 | 신호 여러 개를 따로 선언 | 관련 필드가 늘어날수록 구조적 데이터 표현이 번거로움 |
| 배열 표현 | mem[0:255] 중심 | 단순 memory 표현은 가능하지만 검증용 데이터 저장 방식이 제한적 |
| TB 역할 분리 | module, task, 변수 여러 개로 직접 구성 | 입력 생성, DUT 구동, 출력 관찰, 결과 비교가 한곳에 섞이기 쉬움 |

Verilog만으로도 설계와 검증은 충분히 가능하지만, 코드가 커질수록 해당 block이 순차/조합 논리인지, 어떤 역할의 신호인지, 어떤 상태의 값인지와 같이 사람이 해석해야 하는 부분이 많았다. 이 불편함은 협업에서 더욱 크게 다가온다.

### 1.3 SystemVerilog에서 개선된 점 - 설계/검증 공통

| 요소 | 의미 | 기대 효과 |
|---|---|---|
| logic | 일반적인 단일 드라이버 RTL 신호 선언 | wire/reg를 먼저 고르는 부담 감소 |
| bit, int, string | 목적별 데이터 타입 | 계산, flag, 메시지 표현을 더 분명하게 구분 |
| typedef enum | 값 집합에 이름 부여 | 숫자 대신 의미로 상태를 읽기 쉬움 |
| struct | 관련 필드를 한 덩어리로 묶음 | 데이터 의미를 구조적으로 표현 |
| queue | 순서가 있는 가변 자료구조 | expected/actual data 저장에 유용 |
| dynamic array | 실행 중 크기 결정 배열 | 길이가 달라지는 데이터 저장에 유용 |
| associative array | key 기반 배열 | key별 결과나 상태 저장에 유용 |
| interface | 관련 신호 묶음 정의 | DUT-TB 연결 관점을 정리 |

각 Object를 더 직관적으로 표현할 수 있어, Verilog와 동일한 기능을 구현하더라도 코드에서 의미를 파악하고 흐름을 연결하는 과정이 더 자연스러워진다.

### 1.4 SystemVerilog에서 개선된 점 - 설계

| 요소 | Verilog식 표현 대비 차이 | 설계에서 좋아진 점 |
|---|---|---|
| always_ff | always @(posedge clk)를 의도 중심으로 분리 | 상태 저장 block을 바로 읽을 수 있음 |
| always_comb | always @(*)를 의도 중심으로 분리 | next-state와 조합 논리 block을 바로 읽을 수 있음 |
| logic | wire/reg 구분 부담 감소 | reset, register, next-state 신호를 더 일관되게 선언 |
| typedef enum logic | 상태값을 이름 있는 값 집합으로 정의 | IDLE, START, DATA, STOP 흐름을 숫자 대신 의미로 읽을 수 있음 |
| interface | 관련 신호를 한곳에 연결 | 상위 모듈 연결과 DUT-TB 연결을 정리 가능 |

state 전이와 timing이 코드상으로 훨씬 직관적이기에 '어디가 상태 저장이고, 어디가 조합 논리인지'가 더 빨리 읽힌다는 것이 설계 관점에서 핵심적으로 개선된 부분이다.

### 1.5 SystemVerilog에서 개선된 점 - 검증

| 요소 | 역할 | 검증에서 좋아진 점 |
|---|---|---|
| virtual interface | class 내부에서 실제 DUT 신호 묶음 접근 | class와 DUT 핀을 자연스럽게 연결 |
| class | generator, driver, monitor, scoreboard 같은 역할 정의 | 입력 생성, DUT 구동, 출력 관찰, 결과 비교를 역할별로 분리 |
| mailbox | class 사이 데이터 전달 | 검증 데이터 흐름을 명시적으로 구성 |
| event | 실행 시점 동기화 | race를 줄이고 단계 전환 시점을 맞춤 |
| fork ... join 계열 | 병렬 thread 실행과 종료 제어 | 송신/수신 동시 실행 같은 구조를 명확히 표현 |
| randomize(), constraint | 자극 자동 생성과 제한 조건 | 경계값과 예외값을 체계적으로 섞기 쉬움 |
| queue, dynamic array, associative array | expected model, 임시 버퍼, key 기반 저장 | 비교 대상과 관찰 결과를 구조적으로 정리 |
| simple assert | 기본 조건 빠른 확인 | reset 직후 상태 같은 기본 계약을 짧게 확인 |
| coverage | 미리 정한 검증 조건과 상태의 등장 여부 확인 | PASS/FAIL과 별도로 검증 항목 확인 범위를 정리 |
| covergroup | coverage 항목 정의와 측정 | 검증 항목을 코드로 직접 측정 |

검증 관점에서 SystemVerilog의 핵심은 입력 생성, DUT 구동, 출력 관찰, 결과 비교, 병렬 실행, coverage 확인을 하나의 언어 안에서 구조적으로 연결해 표현할 수 있다는 점이다. 즉 검증 흐름을 '무엇을 넣고, 무엇을 보고, 어떤 기준으로 PASS/FAIL을 판단하는가'라는 기준으로 더 선명하게 정리할 수 있다.

### 1.6 AS-IS / TO-BE

| 구분 | AS-IS | TO-BE |
|---|---|---|
| 구현 기준 | UART+FIFO+SENSOR+Watch_Stopwatch가 Verilog로 구현되어 있음 | 그중 UART RX -> FIFO -> UART TX를 SystemVerilog으로 다시 구현 |
| 기능 구조 | uart_rx -> fifo -> uart_tx 기능 자체는 이미 존재 | 조절한 범위를 SystemVerilog로 설계 RTL과 검증 testbench로 재정리 |
| 설계 표현 | Verilog식 표현: wire/reg, always 등 | SystemVerilog식 표현: logic, always_ff, always_comb, enum 등 |
| 검증 설명 | 파형 관찰 중심 | 시나리오, 기준, 결과를 구조적으로 정리 가능 |

이번 학습 흐름은 Watch_Stopwatch -> UART -> FIFO -> SENSOR 순서로 확장됐다. 이 순서에서 Watch_Stopwatch는 상태 전이와 시간 제어를 읽는 데는 좋지만, 데이터가 어디서 들어와 어디를 지나 어디로 나가는지까지 한 번에 설명하기에는 한계가 있다. SENSOR는 외부 프로토콜 설명 비중이 커서 SystemVerilog 구조 개선 자체가 흐려지기 쉽다. 반면 UART+FIFO는 다음 네 가지를 한 번에 보여 준다.

- serial 입력이 byte로 복원되는 과정
- 복원된 byte가 FIFO에 저장되는 과정
- 저장된 byte가 같은 순서로 다시 송신되는 과정
- 이 전체 경로를 driver/monitor/scoreboard 역할 분리로 검증하는 과정

따라서 학습 순서 전체 안에서 UART+FIFO를 SystemVerilog 개선점이 가장 잘 드러나는 구간으로 선택했다.

### 1.7 설계 사양 요약 (Specification Summary)

| 항목 | 내용 |
|---|---|
| 시스템 클럭 | 100 MHz |
| Baud rate | 9600 bps |
| Oversampling | 16x |
| UART frame | 8 data bits, no parity, 1 stop bit |
| FIFO depth | 16 |
| top module | uart_fifo_loopback |
| 설계 목표 | buffered loopback path 구현 및 self-checking 검증 완료 |

## 2. 프로젝트 관리 (Project Management)

### 2.1 일정 계획 (Schedule)

| 단계 | 기간 | 주요 작업 |
|---|---|---|
| 요구사항 정리 | 2026.05.12 | 목적을 바탕으로 및 목표 범위 확정, TB방향 확정 |
| 아키텍처 설계 | 2026.05.13 | UART RX -> FIFO -> UART TX 설계 |
| RTL | 2026.05.13 | SystemVerilog로 설계 코드 작성하여 RTL 확인 |
| 검증 | 2026.05.14 ~ 2026.05.15 | 검증 시나리오 확정 및 코드 작성 |
| 산출물 정리 | 2026.05.16 ~ 2026.05.17 | 발표자료, 완료보고서, 일정표, 일지 정리 |

### 2.2 설계 환경 (Design Environment)

| 구분 | 내용 |
|---|---|
| 언어 | SystemVerilog |
| EDA | Vivado 2020.2 |
| FPGA 대상 보드 | Digilent Basys 3 |

## 3. 아키텍처 설계

### 3.1 설계 이론 및 배경

#### 3.1.1 UART

<img width="1672" height="941" alt="image3" src="https://github.com/user-attachments/assets/acdd297e-f309-4a3b-b81e-5e31be9a9740" />

UART는 별도의 clock 선 없이 baud rate 약속으로 동작하는 비동기 직렬 통신이다. 이번 설계에서는 9600 bps, 8N1, 16x oversampling을 기준으로 한다.

#### 3.1.2 FIFO

FIFO는 First In, First Out 구조로, 먼저 들어온 데이터가 먼저 나오는 버퍼다. 이번 설계에서는 내부를 두 블록으로 유지했다.

#### 3.1.3 UART + FIFO 범위 선정 이유

범위 선정의 기준은 SystemVerilog가 설계와 검증을 함께 더 읽기 쉽게 만드는 구간을 고르는 것이다. UART + FIFO는 수신 -> 저장 -> 재송신 데이터 흐름이 명확하고, TB에서도 입력 생성 -> DUT 구동 -> 출력 관찰 -> 결과 비교 구조를 자연스럽게 대응시킬 수 있다.

### 3.2 시스템 구조

<img width="2048" height="1537" alt="image4" src="https://github.com/user-attachments/assets/5befa2b4-4c40-425b-a072-e14a3230513f" />

| 모듈 | 역할 | 핵심 신호 |
|---|---|---|
| baud_tick_gen | RX/TX 공통 baud_tick 생성 | o_baud_tick |
| uart_rx | serial 입력을 byte와 완료 pulse로 복원 | rx_data, rx_done |
| fifo | 수신 byte 임시 저장 및 순서 유지 | push_data, pop_data, full, empty |
| uart_tx | byte를 UART frame으로 재송신 | tx, tx_busy |
| uart_fifo_loopback | RX 완료와 FIFO 상태를 보고 송신 시작 제어 | w_tx_start |

## 4. 상세 설계

### 4.1 RTL 설계

<img width="1600" height="271" alt="image5" src="https://github.com/user-attachments/assets/850b41d0-afb2-4c9b-87d9-395f61030dfc" />

| 파일 | 설명 |
|---|---|
| baud_tick_gen.sv | 100 MHz 기준 9600 x 16 baud_tick 생성 |
| uart_rx.sv | IDLE -> START -> DATA -> STOP 수신 FSM |
| fifo.sv | register_file + control_unit 분리 FIFO |
| uart_tx.sv | IDLE -> START -> DATA -> STOP 송신 FSM |
| uart_fifo_loopback.sv | single FIFO top 연결과 w_tx_start 제어 |

### 4.2 Datapath / Control

| 구분 | 내용 |
|---|---|
| Datapath | rx serial 입력을 uart_rx가 byte로 복원하고, FIFO를 거쳐 uart_tx가 다시 serial tx로 변환 |
| RX control | start bit 감지, center sampling, rx_done 생성 |
| FIFO control | push, pop, wptr, rptr, full, empty 제어 |
| TX control | tx_start 감지, tx_busy 유지, start/data/stop 송신 |
| top control | rx_done로 push, !empty && !tx_busy로 pop과 송신 시작 |

## 5. 시뮬레이션 및 검증

### 5.1 검증 이론 및 배경

SoC의 규모와 복잡도가 커질수록 더 다양한 동작 조건을 충분히 확인해야 하므로 검증의 비중도 함께 커졌다. 기존 Verilog 기반 검증 환경은 복잡한 testbench 구성, 객체지향 검증 모델링, 제약 기반 random test, coverage 측정을 체계적으로 확장하는 데 한계가 있었다. 이를 보완하기 위해 SystemVerilog는 설계 문법뿐 아니라 검증 기능까지 포함하는 하드웨어 설계 및 검증 언어로 확장됐다.

하지만 SystemVerilog를 사용하더라도 프로젝트와 도구마다 검증 구조가 달라질 수 있으므로, 역할 분리와 재사용성을 더 일관되게 가져가기 위한 표준 방법론이 필요하다. 이 흐름에서 Accellera가 제시한 UVM은 SystemVerilog 기반 표준 검증 방법론으로 자리잡았으며, 검증 환경을 계층과 역할 기준으로 나누어 설명할 수 있게 했다. UVM 관점의 대표 구성은 다음과 같다.

| 구성 요소 | 일반적인 역할 | 이번 구현에서 대응한 요소 |
|---|---|---|
| test | 검증 실행 단위, 환경 구성과 scenario 선택 | 각 TB module의 실행 흐름과 env.run() 호출 |
| environment | 하위 검증 구성요소 연결과 종료 제어 | environment class |
| agent | 특정 interface 기준의 자극과 관찰 묶음 | 별도 agent class 없이 generator, driver, monitor로 단순화 |
| driver | transaction을 DUT 핀 자극으로 변환 | driver class |
| monitor | DUT 출력을 관찰해 transaction으로 복원 | monitor class |
| scoreboard | expected와 actual 비교 | scoreboard class |
| coverage collector | 시나리오/조건 등장 여부 수집 | PASS 기준에 포함한 반복 관찰 항목과 누적 확인 |

TB 구조는 UVM Class Library를 직접 import한 형태는 아니지만, UVM의 역할 분리 관점을 참고해 item, generator, driver, monitor, scoreboard, environment 중심의 self-checking 구조로 정리했다. 이후 각 TB 절에서는 DUT 특성과 trial 경계에 맞춰 mailbox, event, fork/join, wait() 선택 이유를 구체적으로 설명한다.

| TB | 핵심 PASS 기준 |
|---|---|
| tb_fifo.sv | reset flags, full 진입과 overflow 보호, empty 진입과 underflow 보호, full/empty/부분 채움 상태의 push_pop, total_steps=68 |
| tb_uart_rx | 조기 rx_done 금지, stop window에서 1회 발생, 1-cycle pulse, data byte 일치, gap 4종 관찰 |
| tb_uart_tx | idle start, start bit=0, data byte 일치, 프레임 마지막 값=1, tx_busy 관찰과 idle restore, gap 4종 관찰 |
| tb_uart_fifo_loopback | ordering/data 일치, 프레임 마지막 값=1, 모든 trial에서 tx_busy 관찰, payload_len=1,2,3,4 관찰, 1->2/2->3/3->4 gap 4종 관찰, final idle restore |

### 5.2 tb_fifo.sv

#### 5.2.1 시나리오와 PASS 기준

| 순서 | 시나리오 | 반복 횟수 | PASS 기준 |
|---|---|---|---|
| 1 | reset 직후 기본 flag 상태 확인 | 1 | empty=1, full=0 |
| 2 | push_only로 full 진입과 overflow protection 확인 | DEPTH + 1 = 17 | full 진입과 overflow 보호 확인 |
| 3 | push_pop(full)로 full 상태 simultaneous push/pop 확인 | 1 | full 상태에서는 pop이 우선되어 level이 1 감소 |
| 4 | pop_only로 empty 진입과 underflow protection 확인 | DEPTH = 16 | empty 진입과 underflow 보호 확인 |
| 5 | push_pop(empty)로 empty 상태 simultaneous push/pop 확인 | 1 | empty 상태에서는 push가 반영되어 level이 1 증가 |
| 6 | refill로 부분 채움 상태 구간 준비 | HALF_DEPTH - 1 = 7 | 부분 채움 상태 구간 준비 |
| 7 | push_pop(mid)로 부분 채움 상태의 level 유지와 데이터 순환 확인 | DEPTH = 16 | 부분 채움 상태에서 level 유지와 데이터 순환 확인 |
| 8 | final pop_only로 최종 empty 복귀와 underflow 재확인 | HALF_DEPTH + 1 = 9 | 최종 empty 진입과 underflow 재확인 |

| TestCase | 의미 | PASS 기준 |
|---|---|---|
| TC-FIFO-001 | reset flags | reset 직후 empty=1, full=0이어야 한다 |
| TC-FIFO-002 | full entry와 overflow protection | full 진입 후 추가 push에도 overflow 보호가 유지되어야 한다 |
| TC-FIFO-003 | empty entry와 underflow protection | empty 진입 후 추가 pop에도 underflow 보호가 유지되어야 한다 |
| TC-FIFO-004 | full/empty/부분 채움 상태의 push_pop 계약 | 각 상태에서 simultaneous push/pop의 의도한 level 변화가 맞아야 한다 |
| TC-FIFO-005 | total_steps 확인 | scoreboard가 total_steps=68까지 포함해 step 누락 없이 완료해야 한다 |

FIFO TB의 반복 횟수는 모두 depth에서 직접 유도된다.

| 항목 | 값 | 이유 |
|---|---|---|
| PUSH_ONLY_REPEAT | DEPTH + 1 | full 진입 1회와 overflow 보호 1회를 한 번에 보기 위해서다. |
| PUSH_POP_FULL_REPEAT | 1 | full 상태에서 simultaneous push/pop의 의미는 한 번만 확인해도 충분하다. |
| POP_ONLY_REPEAT | DEPTH | 이전 단계에서 level이 DEPTH-1이 되므로, empty 진입과 underflow를 같이 보려면 정확히 DEPTH번이 필요하다. |
| PUSH_POP_EMPTY_REPEAT | 1 | empty 상태에서 simultaneous push/pop의 의미도 한 번이면 충분하다. |
| REFILL_REPEAT | HALF_DEPTH - 1 | 직전 step에서 level이 1이므로 half depth까지 올리려면 HALF_DEPTH-1번이 필요하다. |
| PUSH_POP_MID_REPEAT | DEPTH | 부분 채움 상태에서 level 유지가 반복적으로 성립하는지 충분히 보기 위해 depth만큼 반복했다. |
| FINAL_POP_REPEAT | HALF_DEPTH + 1 | 부분 채움 상태에서 다시 empty까지 비우고 마지막 underflow까지 포함하기 위해서다. |
| TOTAL_STEPS | 68 | scoreboard는 이 값까지 포함해 step 누락이 없는지 확인한다. |

#### 5.2.2 구조와 선택 이유

<img width="1590" height="955" alt="image6" src="https://github.com/user-attachments/assets/517ef38b-c8be-44e7-a82d-dc084a1d0246" />

| 요소 | 이유 |
|---|---|
| gen2drv_mbox | generator가 만든 step 정보를 driver가 cycle-accurate하게 적용하기 위해 필요하다. |
| gen2scb_mbox | scoreboard가 같은 step의 expected flag와 expected data를 받아야 하므로 필요하다. |
| mon2scb_mbox | monitor가 실제 full, empty, pop_data를 scoreboard로 전달해야 하므로 필요하다. |
| event_mon_next | FIFO는 한 step의 DUT 갱신 직후를 읽어야 의미가 맞으므로, driver가 DUT를 갱신한 직후 monitor가 샘플링하도록 barrier를 두었다. |

실행 구조는 fork ... join_none 후 wait(scb.done), disable fork다. monitor와 driver는 계속 살아 있는 worker이므로 join으로 묶으면 generator가 끝나도 run이 바로 닫히지 않고, join_any를 쓰면 하나의 thread만 먼저 끝나도 step 누락 가능성이 생긴다. 따라서 scoreboard가 모든 step을 확인해 done을 올릴 때까지 wait(scb.done)로 기다린 뒤 thread를 정리하는 방식이 가장 자연스럽다.

#### 5.2.3 시뮬레이션 확인

<img width="1597" height="287" alt="image7" src="https://github.com/user-attachments/assets/8af2a066-7ad2-4f08-87b3-a598c1cfd6e8" />

reset 직후 empty/full 초기 상태와 push_only 시작 구간과 full 진입 이후 overflow protection과 push_pop(full) 확인 구간.

<img width="1600" height="291" alt="image8" src="https://github.com/user-attachments/assets/c3c2a3c0-8c58-4227-b2d3-4792c9e20121" />

empty 진입 이후 underflow protection과 부분 채움 상태 push_pop(mid) 확인 구간.

<img width="1599" height="279" alt="image9" src="https://github.com/user-attachments/assets/04fdc14e-5210-4c28-a5aa-68efe5637c14" />

전체 동작 파형.

### 5.3 tb_uart_rx

#### 5.3.1 시나리오와 PASS 기준

| 순서 | 시나리오 | PASS 기준 |
|---|---|---|
| 1 | Random serial frame 64회를 반복 입력해 byte 복원 확인 | observed byte가 sent byte와 일치해야 한다 |
| 2 | data 구간의 조기 rx_done 발생 여부 확인 | data 구간에서 조기 rx_done가 없어야 한다 |
| 3 | stop window의 rx_done 발생 시점 확인 | stop window에서만 rx_done가 정확히 1회 발생해야 한다 |
| 4 | rx_done pulse width 확인 | rx_done pulse width가 1 cycle이어야 한다 |
| 5 | clk_gap_sel 4종 관찰 확인 | clk_gap_sel = 0,1,2,3이 모두 한 번 이상 관찰되어야 한다 |

| TestCase | 의미 | PASS 기준 |
|---|---|---|
| TC-RX-001 | 조기 rx_done 금지 | data 구간에서 조기 rx_done가 없어야 한다 |
| TC-RX-002 | stop window rx_done 확인 | stop window에서만 rx_done가 정확히 1회 발생해야 한다 |
| TC-RX-003 | rx_done pulse width 확인 | rx_done pulse width가 1 cycle이어야 한다 |
| TC-RX-004 | byte 복원 확인 | observed byte가 sent byte와 일치해야 한다 |
| TC-RX-005 | clk_gap_sel 전체 확인 | clk_gap_sel = 0,1,2,3이 모두 한 번 이상 관찰되어야 한다 |

| 항목 | 값 |
|---|---|
| RANDOM_REPEAT | 64 |
| RANDOM_SEED | 32'h0522_52A5 |
| gap 선택 | clk_gap_sel = 0,1,2,3 |
| 실제 gap | 0, 8, 16, 32 baud_tick |

RANDOM_REPEAT = 64로 둔 이유는 조건 관찰 범위와 runtime의 균형점으로 잡은 값이다.

- gap 4종이 모두 한 번 이상 나올 확률이 충분히 높아야 한다. 가장 단순한 miss 상계로 두면 N=64에서 충분히 작아진다.
- 동시에 8-bit data 조합도 너무 적은 수의 frame보다 다양하게 관찰할 수 있다.

#### 5.3.2 구조와 선택 이유

<img width="1582" height="950" alt="image10" src="https://github.com/user-attachments/assets/6b7b1b62-e018-4cca-8319-ebae81de5808" />

| 요소 | 이유 |
|---|---|
| gen2drv_mbox | generator가 만든 random frame 정보를 driver가 실제 UART rx 자극으로 변환해야 하기 때문이다. |
| gen2scb_mbox | scoreboard가 expected byte와 expected gap 선택값을 알아야 한다. |
| mon2scb_mbox | monitor가 관찰한 observed_byte, early_done_seen, done_hits_in_stop를 scoreboard로 넘겨야 한다. |

실행 구조는 fork ... join_none 후 wait(scb.done), disable fork다. RX driver, monitor, scoreboard는 동시에 돌아야 하고, generator는 foreground에서 64개 trial을 순서대로 공급한다. join은 long-lived worker 때문에 종료 기준이 흐려지고, join_any는 한 thread만 먼저 끝나도 frame 비교가 덜 끝난 상태로 빠질 수 있다. 따라서 종료 시점은 scoreboard가 모든 frame을 비교 완료했는지가 가장 명확하므로 wait(scb.done)를 사용했다.

### 5.4 tb_uart_tx

#### 5.4.1 시나리오와 PASS 기준

| 순서 | 시나리오 | PASS 기준 |
|---|---|---|
| 1 | frame 시작 전 idle 상태 확인 | frame 시작 전 tx=1, tx_busy=0 상태가 유지되어야 한다 |
| 2 | start bit 구간 확인 | start bit 구간에서 tx=0이어야 한다 |
| 3 | data byte decode 결과 확인 | decode한 data byte가 expected byte와 일치해야 한다 |
| 4 | 프레임 마지막 값 확인 | 프레임 마지막 값이 1이어야 한다 |
| 5 | tx_busy 및 idle restore 확인 | 매 frame에서 tx_busy가 실제로 관찰되고, 종료 후 idle이 복구되어야 한다 |
| 6 | clk_gap_sel 4종 관찰 확인 | clk_gap_sel = 0,1,2,3이 모두 한 번 이상 관찰되어야 한다 |

| TestCase | 의미 | PASS 기준 |
|---|---|---|
| TC-TX-001 | frame 시작 전 idle 상태 확인 | frame 시작 전 tx=1, tx_busy=0 상태가 유지되어야 한다 |
| TC-TX-002 | start bit 확인 | start bit 구간에서 tx=0이어야 한다 |
| TC-TX-003 | data byte decode 확인 | decode한 data byte가 expected byte와 일치해야 한다 |
| TC-TX-004 | 프레임 마지막 값 확인 | 프레임 마지막 값이 1이어야 한다 |
| TC-TX-005 | tx_busy 및 idle restore 확인 | 매 frame에서 tx_busy가 실제로 관찰되고, 종료 후 idle이 복구되어야 한다 |
| TC-TX-006 | clk_gap_sel 전체 확인 | clk_gap_sel = 0,1,2,3이 모두 한 번 이상 관찰되어야 한다 |

| 항목 | 값 |
|---|---|
| RANDOM_REPEAT | 64 |
| RANDOM_SEED | 32'h0522_BEE5 |
| gap 선택 | clk_gap_sel = 0,1,2,3 |
| 실제 gap | 0, 8, 16, 32 baud_tick |

RANDOM_REPEAT = 64를 둔 이유는 RX와 동일하다. gap 4종 miss 상계로 두면 N=64에서 충분히 작고, 동시에 8-bit data도 다양한 조합을 통과시킬 수 있다.

#### 5.4.2 구조와 선택 이유

<img width="1472" height="779" alt="image11" src="https://github.com/user-attachments/assets/46dee3dd-4d54-4af3-9676-8e798bf04cdf" />

| 요소 | 이유 |
|---|---|
| gen2drv_mbox | generator가 만든 random byte와 gap 선택값을 driver가 실제 tx_start/tx_data 자극으로 바꿔야 한다. |
| gen2scb_mbox | scoreboard가 expected byte와 expected gap 선택값을 알아야 한다. |
| mon2scb_mbox | monitor가 관찰한 observed_byte, idle_before_start, busy_seen, idle_restored를 scoreboard가 받아야 한다. |
| event_gen_next | TX는 monitor와 scoreboard가 현재 frame을 완전히 소비하기 전에 다음 expected item이 발행되면 expected/actual pairing이 밀릴 수 있다. 이를 막기 위해 scoreboard가 현재 frame 비교를 끝낸 뒤 generator가 다음 trial을 발행하도록 pacing했다. |

monitor 내부 capture_frame()는 fork ... join을 사용한다. 이유는 bit decode thread와 tx_busy 관찰 thread가 모두 끝나야 한 frame의 결과가 완성되기 때문이다. 둘 중 하나라도 빠지면 busy_seen 또는 idle restore 판정이 비게 되므로 plain join이 맞고, join_any나 join_none은 현재 frame 판정을 불완전하게 만들 수 있다.

environment의 실행 구조는 fork ... join_none 후 wait(scb.done), disable fork다. worker를 background로 실행하고, scoreboard 완료를 최종 종료 기준으로 삼는 점은 다른 TB와 동일하다. 여기서도 join은 worker가 계속 살아 있어 종료 제어가 어렵고, join_any는 아직 비교되지 않은 frame이 남은 상태에서 빠질 수 있으므로 선택하지 않았다.

### 5.5 tb_uart_fifo_loopback (top)

#### 5.5.1 시나리오와 PASS 기준

top TB는 random 1~4 byte 입력 묶음을 256회 반복해 RX -> FIFO -> TX 전체 경로를 end-to-end로 확인한다.

설명 편의를 위해 top 검증은 다음 4개의 상위 시나리오로도 묶어 볼 수 있다.

| 상위 시나리오 | 설명 |
|---|---|
| 1 | payload_len=4,3,2,1 역순 확인으로 4-byte부터 1-byte까지 입력 묶음이 모두 end-to-end로 정상 전달되는지 확인 |
| 2 | 같은 random 256회 trial에서 각 trial마다 ordering/data, 프레임 마지막 값, tx_busy가 정상인지 누적 검증 |
| 3 | 같은 random 256회 trial 전체를 누적해 payload_len=1,2,3,4와 byte gap 조건이 모두 한 번 이상 나왔는지 확인 |
| 4 | 모든 trial 종료 후 tx=1, tx_busy=0으로 idle 상태가 정상 복귀하는지 확인 |

대표 시뮬레이션 캡처는 payload_len=4,3,2,1 순서로 정리했다.

| 순서 | 시나리오 | PASS 기준 |
|---|---|---|
| 1 | End-to-end ordering/data 확인 | actual_q 길이가 expected_q와 같고, 각 byte가 같은 순서와 값으로 다시 나와야 한다 |
| 2 | 프레임 마지막 값 확인 | 모든 수신 결과에서 프레임 마지막 값이 1이어야 한다 |
| 3 | tx_busy 관찰 확인 | 모든 trial에서 tx_busy=1이 실제로 관찰되어야 한다 |
| 4 | payload_len=1,2,3,4 전체 확인 | random 256회 반복 동안 1~4 byte 입력 묶음이 모두 한 번 이상 관찰되어야 한다 |
| 5 | 1->2, 2->3, 3->4 byte gap 4종 확인 | 각 위치에서 0, 8, 16, 32 baud_tick 간격이 모두 한 번 이상 관찰되어야 한다 |
| 6 | 최종 idle restore 확인 | 모든 trial 종료 후 tx=1, tx_busy=0으로 끝나야 한다 |

| TestCase | 의미 | PASS 기준 |
|---|---|---|
| TC-LOOP-001 | ordering/data 확인 | actual_q 길이가 expected_q와 같고, 각 byte가 같은 순서와 값으로 다시 나와야 한다 |
| TC-LOOP-002 | 프레임 마지막 값 확인 | 모든 수신 결과에서 프레임 마지막 값이 1이어야 한다 |
| TC-LOOP-003 | tx_busy 관찰 확인 | 모든 trial에서 tx_busy=1이 실제로 관찰되어야 한다 |
| TC-LOOP-004 | payload_len 전체 확인 | payload_len=1,2,3,4가 모두 한 번 이상 관찰되어야 한다 |
| TC-LOOP-005 | byte gap 전체 확인 | 1->2, 2->3, 3->4 byte gap 각각에서 0, 8, 16, 32 baud_tick이 모두 한 번 이상 관찰되어야 한다 |
| TC-LOOP-006 | final idle restore 확인 | 모든 trial 종료 후 tx=1, tx_busy=0으로 idle이 복구되어야 한다 |

| 항목 | 값 |
|---|---|
| RANDOM_REPEAT | 256 |
| RANDOM_SEED | 32'h0522_C0DE |
| payload_len | 1, 2, 3, 4를 균등 분포로 선택 |
| byte gap 선택 | byte12_gap_sel, byte23_gap_sel, byte34_gap_sel = 0,1,2,3 |
| 실제 gap | 0, 8, 16, 32 baud_tick |

RANDOM_REPEAT = 256으로 둔 이유는 가장 드문 제어 경우가 빠질 확률을 충분히 줄이기 위해서다. 이 TB에서는 payload_len=4이면서 각 gap 위치의 특정 선택값이 동시에 필요한 경우가 가장 드물다.

gap 4종 관찰 miss 상계 형태로 보면 N=256에서 충분히 작아져, runtime을 과도하게 늘리지 않으면서 조건 등장 안정성을 확보할 수 있다.

#### 5.5.2 구조와 선택 이유

<img width="2048" height="1076" alt="image12" src="https://github.com/user-attachments/assets/9d6335b2-a65e-489f-b1e8-d00d4e1af0dd" />

| 요소 | 이유 |
|---|---|
| gen2drv_mbox | generator가 만든 variable-length payload를 driver가 실제 UART rx stream으로 바꿔야 한다. |
| gen2mon_mbox | monitor는 이번 trial에서 몇 byte를 받아야 하는지 알아야 한다. payload_len 정보가 없으면 capture_trial()의 종료 경계를 정할 수 없기 때문에 top TB에서만 추가로 필요하다. |
| gen2scb_mbox | scoreboard가 expected payload와 expected gap 선택값을 알아야 한다. |
| mon2scb_mbox | monitor가 복원한 actual_q, stop_bit_ok, busy_seen를 scoreboard가 받아야 한다. |
| event_gen_next | top TB는 variable-length trial이 섞여 있으므로, 현재 trial의 expected/actual 비교가 끝나기 전에 다음 item을 발행하면 pairing이 밀릴 수 있다. scoreboard가 현재 trial 비교를 끝낸 뒤 generator가 다음 trial을 발행하도록 pacing했다. |

monitor 내부 capture_trial()는 fork ... join을 사용한다. 하나의 thread는 payload_len만큼 byte를 받아 actual_q를 만들고, 다른 thread는 같은 trial 동안 tx_busy를 관찰한다. 둘 다 끝나야 한 trial의 결과가 완성되므로 plain join이 맞고, join_any나 join_none은 variable-length trial 결과를 불완전하게 만들 수 있다.

environment의 실행 구조는 fork ... join_none 후 wait(scb.done), disable fork다. driver, monitor, scoreboard를 background worker로 병렬 실행하고, generator는 foreground에서 trial pacing을 맡는다. join은 long-lived worker 때문에 종료 기준으로 부적절하고, join_any는 아직 비교되지 않은 trial이 남은 상태에서 빠질 수 있다. 종료 시점은 scoreboard가 256개 trial의 비교를 모두 끝내는 순간이 가장 명확하므로 wait(scb.done)를 사용했다.

또한 TC-LOOP-006은 scoreboard 완료 직후 바로 검사하지 않고, 먼저 drv.wait_final_idle()을 호출한 뒤 확인한다. 이유는 마지막 byte가 UART TX 내부에서 아직 물리적으로 drain 중일 수 있기 때문이다. 즉 'trial 비교 완료'와 '실제 tx=1, tx_busy=0 복귀 완료'는 다른 시점이므로, final idle restore는 drain 후 별도로 확인했다.

#### 5.5.3 시뮬레이션 확인

대표 시뮬레이션 캡처는 payload_len=4,3,2,1 순서의 대표 trial과 이후 random 누적 검증, final idle restore 순서로 정리했다.

**payload_len=4**

<img width="918" height="294" alt="image13" src="https://github.com/user-attachments/assets/ef472edf-13ef-46e9-b204-53046c154c88" />

Reset 이후, payload_len=4 즉, 4byte 데이터가 연속으로 들어올 때를 보여줍니다. c_state를 확인하면 DATA State가 4번 활성되는 것이 보인다. 입력한 byte 개수만큼 rx_done이 발생하고, 그 값이 TX 쪽에서 같은 순서로 다시 나오는 것을 확인할 수 있다.

**payload_len=3**

<img width="950" height="329" alt="image14" src="https://github.com/user-attachments/assets/fc582571-8d97-40b3-8b39-e1d348d26d8b" />

**payload_len=2**

<img width="946" height="328" alt="image15" src="https://github.com/user-attachments/assets/141a7fa1-14aa-47a4-9c11-4508ef8f77bb" />

**payload_len=1**

<img width="946" height="256" alt="image16" src="https://github.com/user-attachments/assets/e988cf0d-c6c9-43e8-80bc-59d790d078e4" />

**random 256회 누적 구간에서 TC-LOOP-001 ~ 003 확인**

<img width="927" height="462" alt="image17" src="https://github.com/user-attachments/assets/41208b1e-e1fd-47c4-b2da-360cd8a3c171" />

random trial을 256회 반복하면서 ordering과 data 일치가 계속 유지되는지를 누적 검증한다.

시나리오2는 이 random 구간에서 각 trial마다 프레임 마지막 값이 1인지, tx_busy=1이 실제로 관찰되는지도 확인한다. 이는 TC-LOOP-001, TC-LOOP-002, TC-LOOP-003 PASS 로그에서 확인할 수 있다.

**같은 random 구간에서 TC-LOOP-004, TC-LOOP-005 확인**

<img width="961" height="431" alt="image18" src="https://github.com/user-attachments/assets/d5b0da8c-d2f2-4d89-95ce-c1e860f86a8a" />

시나리오 3은 앞의 동일한 random 구간에서 payload_len=1부터 4 구간의 간격 1에서 2는 0~8, 2에서 3은 8~16, 3에서 4는 16~32 byte baud_tick 간격이 모두 나왔는지를 확인한다.

Scoreboard에 누적된 TC-LOOP-004, TC-LOOP-005 PASS 로그로 빠른 확인이 가능하다.

**모든 trial 종료 후 TC-LOOP-006 final idle restore 확인**

<img width="931" height="426" alt="image19" src="https://github.com/user-attachments/assets/31cfa5d2-7c5f-44fd-b24e-9b527017cf7b" />

마지막 시나리오 4에서는 모든 trial 종료 후 tx=1, tx_busy=0으로 idle 상태가 정상 복귀하는지를 TC-LOOP-006에서 확인하는 것으로 전체 TestCase가 종료된다.

## 6. 결론 및 고찰

### 6.1 결론

이번 프로젝트에서는 SystemVerilog를 이용해 UART RX -> FIFO -> UART TX 구조의 loopback path를 설계부터 검증까지 직접 구현했다. 이 과정을 통해 Verilog 기반 작성 방식과 비교했을 때, SystemVerilog는 설계 의도와 검증 흐름을 역할 기준으로 더 구조적으로 정리할 수 있음을 확인했다.

또한 UART + FIFO loopback을 대상으로 모듈 TB 3개와 top TB 1개를 self-checking 구조로 구성함으로써, SystemVerilog의 class, mailbox, event, virtual interface 같은 기능과 UVM 방식의 역할 분리 구조를 실제 코드에 적용했다. 특히 검증 시나리오와 PASS 기준을 구체적으로 정리하는 과정에서, 설계 구조와 검증 결과를 같은 기준으로 읽을 수 있도록 맞추는 것이 중요함을 확인했다.

### 6.2 고찰 및 향후 방향

이번 검증 환경은 UVM Class Library를 직접 import해 사용하는 대신, generator, driver, monitor, scoreboard, environment에 대응하는 구조를 직접 구성하는 방향으로 진행했다. 이를 통해 표준 방법론을 활용하기 위해서는 단순히 라이브러리 사용법을 익히는 것보다, 각 구성 요소의 역할과 데이터 흐름, 동기화 방식 같은 내부 구조를 이해하는 것이 더 중요하다는 점을 확인했다.

또한 검증 시나리오를 더 구체적으로 작성하는 과정에서 설계 내용을 다시 꼼꼼히 확인하게 되었고, 이 과정에서 설계와 검증이 서로 독립된 절차가 아니라 상호 보완적인 관계라는 점도 확인할 수 있었다. 앞으로는 이번 경험을 바탕으로 아직 사용해보지 못한 SystemVerilog 기능과 실제 UVM Class Library까지 범위를 확장해, 더 다양한 검증 구조와 재사용 가능한 testbench 구성으로 발전시키고자 한다.

## 참고 문헌

- IEEE Std 1800, SystemVerilog Unified Hardware Design, Specification, and Verification Language
- Accellera UVM User's Guide 1.2
- IEEE 1800.2 계열 UVM Reference Implementation / Class Reference
- Accellera UVM 다운로드 (https://www.accellera.org/downloads/standards/uvm)
- Accellera UVM 1.0 Class Reference (https://www.accellera.org/images/downloads/standards/uvm/UVM_Class_Reference_Manual_1.0.pdf)
- MathWorks UVM 개요 (https://www.mathworks.com/discovery/uvm-verification.html)
- 수업 실습 코드와 강의 메모
