[English](README.md) | 한국어

# SPI/I2C Serial Communication IP UVM 검증

김연우

2026.06.11 ~ 2026.06.18

## 1. 개요 (Overview)

### 1.1 목적 및 목표

본 프로젝트는 SPI와 I2C 직렬 통신 RTL을 직접 구현하고, UVM 1.2 testbench에서 자동 검증하는 것을 목표로 한다. UVM 구조에서는 driver, monitor, scoreboard, coverage, collector의 역할을 나누어 검증 근거를 추적할 수 있다.

- SPI: 1 Controller : 1 Target, MODE0, 1-byte MSB-first full-duplex 동작 검증
- I2C: 1 Controller : 1 Target, 7-bit address 0x12, 1-byte write, ACK 및 target receive 확인
- UVM: smoke, basic, boundary, random, back-to-back, regression sequence 구성
- Evidence: scoreboard pass/fail, functional coverage, collector report, Verdi waveform 확보

### 1.2 설계 범위

| 구분 | 포함 범위 | 제외 범위 |
|---|---|---|
| SPI | 1:1 topology, MODE0, 1-byte, MSB-first, controller/target 양방향 data path | multi-target, CPOL/CPHA 전체 mode, burst transfer |
| I2C | 7-bit address 0x12, write-only, ACK, target receive | read transaction, arbitration, clock stretching, address mismatch recovery |
| 검증 | UVM transaction, sequence, driver, monitor, scoreboard, coverage, collector | protocol별 독립 agent 확장, formal verification |
| Board demo | board-visible 결과와 Logic Analyzer evidence는 별도 자료로 분리 | UVM pass/fail 근거와 board demo 근거를 같은 결과로 취급하지 않음 |

표 1. 프로젝트 설계 및 검증 범위

### 1.3 프로젝트 요약

SPI/I2C 통신 IP를 교육용 RTL로 구성하고, UVM에서 expected/actual 비교와 coverage hit를 통해 동작을 확인했다. 문서는 RTL 구조, FSM/ASM, 파형, UVM architecture, VCS/Verdi/coverage evidence 순서로 구성했다.

### 1.4 설계 사양 요약 (Specification Summary)

| 항목 | 내용 |
|---|---|
| RTL 언어 | SystemVerilog |
| 검증 프레임워크 | UVM 1.2 |
| Simulator / Debug | Synopsys VCS W-2024.09-SP2, Verdi X-2025.06-1 |
| FPGA Tool / Board | Vivado 2020.2, Digilent Basys3 Artix-7 |
| SPI PASS 기준 | ctrl_rx_data == target_tx_data, target_rx_data == ctrl_tx_data |
| I2C PASS 기준 | ack_seen == 1, target_rx_seen == 1, target_rx_data == ctrl_tx_data |

표 2. 설계 사양 요약

### 1.5 AS-IS / TO-BE

| 구분 | AS-IS | TO-BE |
|---|---|---|
| 학습 관점 | SPI/I2C를 이미 만들어진 통신 IP나 예제 코드로 사용하는 대상으로 이해했다. | SCLK, CS, controller/target data line, SCL/SDA, ACK가 RTL 상태 전이와 어떻게 연결되는지 설명할 수 있게 되었다. |
| 설계 관점 | 파형이나 데모 결과를 먼저 보고 동작을 추측하는 수준이었다. | Controller/Target, FSM/ASM, shift register, open-drain ACK 구조를 직접 구현하며 동작 흐름을 확인했다. |
| 검증 관점 | testbench는 값을 넣고 waveform을 확인하는 절차로만 생각했다. | UVM sequence, driver, monitor, scoreboard, coverage 역할을 나누고 expected/actual 비교 기준을 만들었다. |
| 증거 관점 | 캡처 이미지 중심으로 결과를 설명했다. | VCS log, scoreboard pass/fail, coverage, FSDB 구간을 연결해 보고서와 발표 evidence로 사용했다. |

표 3. AS-IS / TO-BE 비교

개선 효과는 수업 전에는 멀게 느껴졌던 SPI/I2C와 UVM을 RTL 구현, transaction 비교, coverage 근거로 직접 설명할 수 있게 된 점이다.

## 2. 프로젝트 관리 (Project Management)

### 2.1 일정 계획 (Schedule)

| 단계 | 기간 | 주요 작업 |
|---|---|---|
| 요구사항 확인 | 2026.06.11 | 구현 범위, 제출 산출물, 보드 demo와 UVM evidence 분리 기준 확정 |
| 구조 설계 | 2026.06.11 - 2026.06.13 | SPI/I2C block diagram, FSM/ASM, 검증 scenario, scoreboard 기준 수립 |
| RTL 구현 | 2026.06.11 - 2026.06.13 | SPI/I2C controller, target, wrapper, board top 구현 |
| UVM 검증 | 2026.06.12 - 2026.06.16 | sequence, driver, monitor, scoreboard, coverage, collector 작성 및 VCS 실행 |
| 발표 및 제출 준비 | 2026.06.16 - 2026.06.18 | PPT, 보고서, 파형/coverage 설명, 제출 파일 점검 |

표 4. 프로젝트 일정 요약

### 2.2 개발 환경 (Development Environment)

| 분류 | 기술 |
|---|---|
| 원격 실행 | Linux SSH, VCS/UVM license, Verdi GUI |
| 자동화 | Makefile, filelist.f, simv-remote, cov-remote, wave-remote |
| 산출물 | Powerpoint, Excel, Word, Markdown |

표 6. 개발 환경

### 2.3 설계 환경 (Design Environment)

| 분류 | 내용 |
|---|---|
| HDL | SystemVerilog, Verilog |
| 검증 | UVM 1.2, Synopsys VCS W-2024.09-SP2 |
| Debug | Synopsys Verdi X-2025.06-1, FSDB/VCD |
| FPGA | Digilent Basys3 Artix-7 |
| FPGA Tool | Vivado 2020.2 |

표 7. 설계 환경

## 3. 아키텍처 설계 (Architecture)

### 3.1 시스템 구조

DUT는 SPI와 I2C를 분리해서 구현하고, UVM testbench는 protocol field에 따라 drive/observe/compare 동작을 선택한다. board demo 구조는 별도 evidence로 유지하고, 본 보고서의 PASS/FAIL 기준은 UVM testbench 결과를 기준으로 한다.

### 3.2 설계 이론 및 배경 (Theory & Background)

<img width="300" alt="image4" src="https://github.com/user-attachments/assets/e02ebcb3-2b91-4d60-b0d3-682af2ccd54f" />
<img width="500" alt="image5" src="https://github.com/user-attachments/assets/ba428e6d-8f8e-4d83-925b-097c49ce36ab" />

SPI는 Controller가 SCLK와 CS를 만들고 ctrl_sdo/tgt_sdi, tgt_sdo/ctrl_sdi 경로로 Target과 동시에 byte를 교환한다. I2C는 SCL/SDA shared bus에서 START, address, ACK, data, STOP 조건으로 transaction을 구성한다. UVM은 protocol 선택 비용을 평가하는 도구가 아니라, 정의한 transaction이 DUT에서 기대값과 일치하는지 확인하는 검증 환경이다.

이번 보고서에서는 일반 문헌에서 쓰이는 Master/Slave 계열 표현을 주 용어로 사용하지 않고 Controller/Target으로 통일한다. MOSI/MISO는 표준 신호명을 설명할 때만 병기하고, RTL/UVM 설명은 프로젝트 신호명으로 연결한다.

| 대중 용어 | 적용 용어 | 적용 신호/대상 | 의미 |
|---|---|---|---|
| Master | Controller | SPI_controller, I2C_controller | transaction을 시작하고 clock, select, address/write sequence를 만든다. |
| Slave | Target | SPI_target, I2C_target | 선택되거나 address가 match되면 data를 수신하고 응답한다. |
| MOSI | ctrl_sdo / tgt_sdi | SPI Controller to Target data | Controller가 Target으로 보내는 serial data path이다. |
| MISO | tgt_sdo / ctrl_sdi | SPI Target to Controller data | Target response가 Controller로 들어오는 serial data path이다. |
| SS/CS | cs_n | SPI target select | active-low frame 구간을 표시하고 선택된 Target만 transaction에 참여한다. |
| SCL/SDA | scl / sda | I2C shared bus | SCL은 timing 기준, SDA는 address/data/ACK를 open-drain 방식으로 전달한다. |

표 8. SPI/I2C 용어 대조

| protocol | 특징 | 이번 프로젝트에서의 역할 |
|---|---|---|
| UART | 공유 clock 없이 baud timing 기반 송수신 | 비교용 protocol |
| SPI | SCLK/CS와 controller/target 양방향 data line을 사용하는 full-duplex 통신 | MODE0 1-byte full-duplex 검증 대상 |
| I2C | SCL/SDA shared bus, address, ACK 기반 통신 | address 0x12 write path 검증 대상 |

표 9. UART/SPI/I2C 비교

## 4. 상세 설계 (Detailed Design)

### 4.1 RTL 설계

| 구분 | 주요 모듈 | 역할 |
|---|---|---|
| SPI | SPI_controller, SPI_target, SPI wrapper | SCLK/CS 생성, ctrl_sdo/tgt_sdi 및 tgt_sdo/ctrl_sdi shift, rx_valid/done 출력 |
| I2C | I2C_controller, I2C_target, I2C wrapper | START/STOP, address/write, ACK, target receive 처리 |
| 공통 | board top, result path | 보드 표시용 결과와 내부 통신 결과 연결 |
| UVM top | tb_SPI_I2C_UVM | UVM 전용 SPI 1:1 + I2C 1:1 DUT 연결 |

표 10. RTL 구성

### 4.2 FSM and ASM

SPI는 Controller/Target 모두 FSM으로 상태 전이를 정의하고 ASM으로 state별 datapath 동작을 연결한다. I2C는 START, address, ACK, DATA, STOP 순서를 Controller/Target FSM 기준으로 확인한다.

#### 4.2.1 SPI

SPI는 MODE0 기준의 1 Controller : 1 Target 구조이며, Controller와 Target이 같은 frame 안에서 CS, SCLK, MOSI/MISO shift 동작을 맞춘다.

**SPI Controller FSM**
<img width="2812" height="956" alt="SPI Controller FSM" src="https://github.com/user-attachments/assets/a149dd8c-c229-4e93-98cd-96c084848f3d" />

**SPI Controller ASM**
<img width="3360" height="2508" alt="SPI Controller ASM" src="https://github.com/user-attachments/assets/18b9f72e-b5de-4086-b85c-f88d41178eec" />

**SPI Target FSM**
<img width="2876" height="988" alt="SPI Target FSM" src="https://github.com/user-attachments/assets/aa5dd0b3-f3ab-4ad7-81ba-aa868f06bf13" />

**SPI Target ASM**
<img width="4652" height="3324" alt="SPI Target ASM" src="https://github.com/user-attachments/assets/ea694c41-151d-4fd0-aa43-1874cdd9659c" />

| 단계 | Controller FSM/ASM | Target FSM/ASM | Check point |
|---|---|---|---|
| IDLE | start 대기, SCLK=CPOL, cs_n=High | deselected, sdo idle | frame 없음 |
| START | mode/data latch, selected CS assert | cs_start로 frame 감지 | target selected |
| SETUP | CPHA0 preload, response sample 준비 | CPOL/CPHA latch, target_tx_data 준비 | setup timing |
| TRANSFER | SCLK toggle, MISO sample, MOSI shift | MOSI sample, MISO shift | 8-bit MSB-first |
| DONE | rx_data/done/rx_valid, CS release | target_rx_data/rx_valid, cs_stop release | byte match |

표 11. SPI Controller/Target FSM-ASM 연결

#### 4.2.2 I2C

I2C는 open-drain SDA와 SCL을 기준으로 START/STOP condition을 만들고, target address 0x12 write transaction에서 ACK와 target receive를 확인한다.

| 구간 | Controller FSM | Target FSM | Check point |
|---|---|---|---|
| IDLE/START | start 입력 후 SDA High->Low | SDA falling while SCL High 감지 | START condition |
| ADDR | 0x12 + write bit를 MSB-first 전송 | address bit shift 및 target_addr 비교 | target selected |
| ACK | SDA release 후 ACK sample | matched address/data에서 SDA Low drive | ack_seen=1 |
| DATA | ctrl_tx_data 8-bit 전송 | target_rx_data shift-in | target_rx_seen=1 |
| STOP/DONE | STOP condition 생성, done pulse | STOP 감지 후 IDLE 복귀 | target_rx_data == ctrl_tx_data |

표 12. I2C Controller/Target FSM 관찰 포인트

**IIC Controller FSM**
<img width="2704" height="1544" alt="IIC Controller FSM" src="https://github.com/user-attachments/assets/b47ec65f-81dc-4e07-a81d-581e0ce039f7" />

**IIC Target FSM**
<img width="2928" height="1544" alt="IIC Target FSM" src="https://github.com/user-attachments/assets/65bc2192-2559-4489-ba60-222cecd772f6" />

### 4.3 Timing 설계

SPI는 MODE0 기준으로 SCLK idle low 상태, rising edge sample, falling edge shift, 8-bit 후 done/rx_valid pulse 시점을 확인한다.

I2C는 SCL High 상태에서 SDA edge로 START/STOP을 판정하고, byte 뒤 ACK phase와 target_rx_seen pulse 시점을 확인한다.

UVM monitor는 DUT 결과를 transaction item으로 변환하고, scoreboard는 expected field와 observed field를 비교한다.

Timing 확인은 파형 모양 자체보다 신호가 유효해지는 edge와 완료 pulse가 언제 발생하는지를 기준으로 본다. SPI는 SCLK idle low 상태에서 rising edge sample과 falling edge shift가 8-bit 동안 반복되는지 확인하고, I2C는 SCL High 구간에서 START/STOP 조건이 형성되는지와 ACK/receive pulse가 뒤따르는지를 확인한다.

| 구분 | Timing 기준 | 파형에서 보는 지점 |
|---|---|---|
| SPI edge | MODE0은 SCLK idle low이며 rising edge에서 sample, falling edge에서 shift가 반복된다. | SCLK clock row와 MOSI/MISO 8-bit data line 변화 |
| SPI 완료 | 8-bit 전송이 끝난 뒤 controller/target 수신값이 확정되고 done/rx_valid가 pulse로 올라간다. | 마지막 bit 이후 done / rx_valid 1-cycle pulse |
| I2C 조건 | START/STOP은 SCL이 High인 상태에서 SDA가 falling/rising 되는 조건으로 판정한다. | SCL clock row와 SDA address/data/ACK bit pattern |
| I2C ACK/RX | ADDR/DATA byte 뒤 ACK phase가 오고, target 수신 완료 시 ack_seen 및 target_rx_seen이 올라간다. | SDA의 ACK=0 구간과 ack_seen, target_rx_seen pulse |

표 13. Timing 관찰 기준

<img width="940" height="272" alt="image12" src="https://github.com/user-attachments/assets/d0f44c60-d6ec-4173-9cca-42ba8224a541" />

<img width="1500" height="212" alt="image13" src="https://github.com/user-attachments/assets/5eb20101-59d8-450c-8b6c-196a45a9668a" />

### 4.4 설계 전략 (Design Strategy)

- board demo 구조와 UVM 자동검증 구조를 분리해 evidence 기준이 섞이지 않게 했다.
- SPI와 I2C를 하나의 serial transaction 형식으로 다루되, protocol field로 driver/monitor 동작을 분기했다.
- coverage는 protocol, test_kind, data class, I2C addr/ACK/RX, latency를 중심으로 구성했다.

## 5. 시뮬레이션 및 검증 (Simulation & Verification)

### 5.1 Testbench

검증은 먼저 protocol별 directed TB에서 RTL 기본 동작을 확인한 뒤, 같은 DUT 조합을 UVM TB에서 sequence 기반 회귀검증으로 확장했다. 개별 TB는 파형과 mismatch를 빠르게 확인하는 기본 확인 단계이고, UVM TB는 scoreboard, coverage, collector가 포함된 최종 자동검증 기준이다.

| 검증 단계 | 대상/명령 | 확인 내용 | 역할 |
|---|---|---|---|
| SPI 개별 TB | tb_SPI.sv / make spi-sim | A5<->3C, 5A<->C3 전송 후 RX mismatch 확인 | SPI full-duplex 단위 확인 |
| I2C 개별 TB | tb_I2C.sv / make i2c-sim | addr 0x12 write A5/5A 후 ACK/RX mismatch 확인 | I2C write/bus 단위 확인 |
| UVM TB | tb_SPI_I2C_UVM.sv / make simv-remote | sequence별 pass/fail, coverage, report summary 확인 | 회귀검증 evidence 기준 |

표 14. Testbench 검증 단계

<img width="3124" height="2084" alt="image14" src="https://github.com/user-attachments/assets/95ef9ea1-6d9c-4dc5-aa66-eee541407454" />

| UVM 구성요소 | 역할 | 이번 프로젝트 연결 |
|---|---|---|
| serial_seq_item | protocol, test_kind, expected/observed field 보관 | SPI/I2C 공통 transaction |
| serial_driver | DUT interface 구동 | SPI start/data, I2C address/write start |
| serial_monitor | DUT 결과를 observed item으로 변환 | SPI done, I2C done/ack/rx_seen |
| serial_scoreboard | expected/actual 비교 | SPI byte match, I2C ACK/RX match |
| serial_coverage | coverpoint/cross hit 기록 | protocol, test_kind, data class, addr/ACK/RX, latency |
| serial_protocol_collector | report용 실행 요약 생성 | protocol별 count, test_kind 분포, 평균 latency |

표 15. UVM 구성요소

Scoreboard, coverage, collector는 서로 직접 판정을 주고받지 않는다. monitor가 관찰한 transaction을 각 컴포넌트가 받아 pass/fail, coverage hit, report summary를 각각 만든다.

### 5.2 시뮬레이션 시나리오

5.2에서는 개별 directed TB와 UVM sequence를 분리해 시나리오를 정리했다. 개별 TB는 RTL 기본 transaction을 빠르게 확인하는 단계이고, UVM sequence는 같은 DUT 동작을 자동 판정과 coverage 기준으로 확장한 단계이다.

| 구분 | 실행 대상 | 입력 시나리오 | 확인 기준 |
|---|---|---|---|
| SPI 개별 TB | tb_SPI.sv / make spi-sim | A5<->3C, 5A<->C3 | RX mismatch 없음, done/rx_valid 확인 |
| I2C 개별 TB | tb_I2C.sv / make i2c-sim | addr 0x12 write A5, 5A | ACK/RX match, target_rx_valid 확인 |
| UVM smoke/basic | serial_smoke_test, serial_basic_test | SPI A5/5A, I2C A5/5A | driver-monitor-scoreboard PASS |
| UVM regression | serial_regression_test | boundary/random/B2B 포함 | SPI 78건 + I2C 78건, pass 156/fail 0 |

표 16. 개별 TB 및 UVM 시뮬레이션 시나리오

| test | SPI stimulus | I2C stimulus | PASS 기준 |
|---|---|---|---|
| serial_smoke_test | A5 <-> 3C | addr 12, write A5 | pass 2/fail 0 |
| serial_basic_test | 5A <-> C3 | addr 12, write 5A | byte/data match |
| serial_boundary_test | 00/FF, FF/00, AA/55, 55/AA | 00, FF, AA, 55 | boundary match |
| serial_random_test | random 64건 | random 64건 | all match |
| serial_back_to_back_test | continuous 8건 | continuous 8건 | no dropped item |
| serial_regression_test | 전체 78건 | 전체 78건 | pass 156/fail 0 |

표 17. UVM sequence 세부 시나리오

개별 TB waveform은 RTL bring-up에서 SPI/I2C 단위 동작을 확인하는 용도로 사용했고, UVM waveform은 smoke transaction이 DUT 신호로 연결됐는지 보는 보조 evidence로 사용했다.

### 5.3 Waveform 분석

Waveform 분석은 앞쪽에서 개별 TB 파형을 확인하고, 마지막에 UVM smoke test를 SPI/I2C 대표 transaction을 Verdi로 확인하는 순서로 구성했다. 단, UVM의 최종 pass/fail 판단은 파형이 아니라 5.4의 log와 scoreboard 결과를 기준으로 한다.

개별 TB 파형은 protocol별 RTL 기본 동작을 먼저 검증한 evidence이다. SPI는 shift 방향과 완료 신호를 확인하고, I2C는 address ACK 이후 data 수신 완료를 확인했다.

<img width="1498" height="752" alt="image15" src="https://github.com/user-attachments/assets/df068cc4-390e-4946-a8df-1ea1b881cc3e" />

<img width="1688" height="771" alt="image16" src="https://github.com/user-attachments/assets/38653672-0c69-45f0-ac20-f5a4ba966057" />

| 구분 | 대표 구간 | 파형에서 확인한 내용 | 판정 |
|---|---|---|---|
| SPI 개별 TB | MSB-first transfer | cs_n active 상태에서 SCLK edge 기준으로 ctrl_sdo/tgt_sdo가 shift되고, 수신 byte가 기대값과 일치하는지 확인 | PASS |
| I2C 개별 TB | ACK 및 DATA done | addr 0x12 write 이후 ACK가 관찰되고 target_rx_data가 A5/5A로 수신되는지 확인 | PASS |
| UVM Verdi | serial_smoke_test | SPI A5<->3C, I2C addr 0x12 write A5가 UVM sequence에서 DUT signal로 전달되는지 확인 | log와 연결 |

표 18. Waveform 확인 항목

아래의 Verdi 파형은 개별 TB가 아니라 UVM smoke test 실행 후 생성된 FSDB를 연 것이다. 파형은 대표 transaction 확인용이고, UVM 검증 결과는 다음 절의 log 분석으로 판단한다.

<img width="1656" height="729" alt="image17" src="https://github.com/user-attachments/assets/b238d1b1-e89e-4ed5-b02c-6244754df868" />

controller tx_data 1010_0101(0xA5)가 target rx_data로 들어가고, target tx_data 11_1100(0x3C)가 controller rx_data로 돌아와 full-duplex 교환이 정상적으로 확인된다.

<img width="1711" height="599" alt="image18" src="https://github.com/user-attachments/assets/ce2a93e1-8c7b-432f-b0ac-504d37d246aa" />

controller가 addr 1_0010(0x12) write와 data 1010_0101(0xA5)를 전송한 뒤 ACK가 관찰되고, target_rx_data가 0xA5로 갱신되어 target receive가 확인된다.

| 항목 | 값 |
|---|---|
| 실행 명령 | make wave-remote TEST=serial_smoke_test SEED=260618 CM_NAME=serial_smoke_full |
| SPI 구간 | 90 ns - 805 ns, controller A5, target 3C, full-duplex byte 교환 |
| I2C 구간 | 800 ns - 3995 ns, addr 12, write A5, ACK, target receive |
| 결과 context | 3985 ns - 4505 ns, scoreboard/coverage/collector report |

표 19. UVM Verdi 파형 evidence 위치

### 5.4 UVM log 분석

UVM 검증은 파형 확인 보다는 log에서 sequence 실행, driver 구동, monitor 관찰, scoreboard 판정, collector/coverage report가 이어지는지를 위주로 확인했다. 아래 log는 regression 실행에서 UVM 구조와 transaction 흐름, 최종 pass/fail 및 coverage 요약을 확인한 evidence이다.

<img width="1008" height="471" alt="image19" src="https://github.com/user-attachments/assets/e4d6a368-e734-40c1-b15d-ee1fc1a7329e" />

topology에는 uvm_test_top, env, agt 아래 drv/mon/sqr가 생성되고 env 내부에 collector, coverage, scoreboard가 별도 컴포넌트로 배치된 것이 보인다. monitor가 관찰한 transaction을 scoreboard, coverage, collector로 나누어 보내는 UVM 구조가 실제 build된 evidence이다.

<img width="1716" height="109" alt="image20" src="https://github.com/user-attachments/assets/3d7a8e3f-842e-40a8-bc3b-350491b00600" />

RANDOM test의 log에서는 각 test 단계별로 driver가 SPI/I2C transaction을 구동한 뒤 monitor가 ctrl_rx_data, target_rx_data, ack_seen, target_rx_seen, latency를 관찰하고 scoreboard가 PASS를 출력한다. 파형은 신호 변화를 보여주지만, 이 log는 expected 값과 actual 값이 어떤 기준으로 비교됐는지 직접 보여준다.

<img width="1397" height="705" alt="image21" src="https://github.com/user-attachments/assets/d9b5ed76-7428-467f-9d53-919d4e056d0b" />

collector는 SPI 78건, I2C 78건, test kind 분포 SMOKE 2, BASIC 2, BOUNDARY 8, RANDOM 128, BACK_TO_BACK 16과 평균 latency SPI 68 cycles, I2C 315 cycles를 출력했다. scoreboard 최종 결과는 pass 156, fail 0이므로 monitor가 관찰한 transaction이 누락되거나 mismatch된 항목은 없었다.

<img width="282" height="440" alt="image22" src="https://github.com/user-attachments/assets/b8ca8eb4-bb3a-4f65-9244-5883fb796ce3" />

UVM_WARNING, UVM_ERROR, UVM_FATAL이 모두 0으로 종료됐다. serial_driver, serial_monitor, serial_scoreboard의 report count가 156으로 맞아 구동, 관찰, 판정 수가 일치하고, 각 report_phase 항목 수는 collector 12개, coverage 16개, scoreboard 7개로 해석했다.

| 로그 분류 | 확인 수치/문구 | 판정 |
|---|---|---|
| Topology | env 내부 agent, collector, coverage, scoreboard 생성 | monitor transaction broadcast 구조 확인 |
| Transaction | driver/monitor/scoreboard log 156건 흐름 확인 | 구동, 관찰, 비교 흐름 일치 |
| Collector | SPI/I2C 각 78건, test kind 156건, avg latency SPI=68, I2C=315 cycles | report용 실행 요약 정상 생성 |
| Scoreboard | pass 156, fail 0 | planned transaction mismatch 없음 |
| Severity | UVM_WARNING 0, UVM_ERROR 0, UVM_FATAL 0 | 시뮬레이션 오류 없이 종료 |
| Coverage log | protocol, test_kind, SPI data/cross, I2C addr/ACK/RX, latency 출력 | coverage 항목이 regression log에서 확인됨 |

표 20. UVM log 분석 항목

### 5.5 시뮬레이션 결과 및 Coverage 분석

| 항목 | 목표치 (Spec) | 측정치 (Sim Result) | 결과 |
|---|---|---|---|
| serial_smoke_test | SPI 1건 + I2C 1건 PASS | scoreboard pass 2, fail 0 | 달성 |
| serial_regression_test | 전체 sequence PASS | SPI count 78, I2C count 78, pass 156, fail 0 | 달성 |
| UVM severity | UVM_ERROR/FATAL 0 | UVM_WARNING=0, UVM_ERROR=0, UVM_FATAL=0 | 달성 |
| Functional coverage | planned covergroup 100% | Testbench Group Score 100% | 달성 |
| spi-sim directed TB | SPI 기본 frame 2건 PASS | tb_SPI.sv: A5<->3C, 5A<->C3 mismatch 없음 | 달성 |
| i2c-sim directed TB | I2C write 2건 PASS | tb_I2C.sv: addr 0x12 write A5/5A, ACK 및 target RX mismatch 없음 | 달성 |

표 21. 시뮬레이션 결과 요약

<img width="738" height="565" alt="image23" src="https://github.com/user-attachments/assets/52730893-c677-459d-8915-346dbe50ad45" />

전체 score는 50.81이고 세부 항목은 Line 43.27, Condition 53.81, Toggle 51.81, FSM 43.33, Branch 30.13, Assert 33.33, Group 100.00이다. Group 100.00은 이번 UVM 계획에서 정의한 protocol, test_kind, SPI data class, I2C ACK/RX 같은 functional coverage가 모두 hit됐다는 뜻이고, 낮은 code coverage는 SPI MODE0, 1-byte frame, I2C write-only 범위와 tool/UVM library 코드가 함께 집계된 영향이다.

<img width="1020" height="294" alt="image24" src="https://github.com/user-attachments/assets/cb2c73be-436f-48d7-9acb-e71f299df3d9" />

serial_uvm_pkg::serial_coverage::serial_cg의 score와 instance score가 모두 100.00으로 표시된다. AUTO BIN MAX 64와 PRINT MISSING 64는 covergroup report 설정값이며, 이번 scope 안에서 계획한 coverpoint와 cross가 hit됐는지를 보는 functional coverage 근거로 사용했다.

<img width="487" height="262" alt="image25" src="https://github.com/user-attachments/assets/dbaea470-98b8-4d83-808c-93026e003ebf" />

포함된 test는 1개이고 DB 이름은 simv/serial_regression이다. 여기서 test 1개는 UVM sequence가 1개라는 뜻이 아니라, coverage report에 포함된 simulation run이 1개라는 뜻이다. 이번 report는 여러 sequence를 포함한 단일 regression 실행 결과이므로 기능 달성 근거로는 사용할 수 있지만, random seed를 바꿔 반복 실행한 coverage merge 결과는 아니다. 즉, rand test의 데이터가 1회 뿐이므로 향후에는 여러 seed의 regression DB를 merge해 random data 조합과 cross coverage를 더 엄밀하게 확인할 필요가 있다.

<img width="1302" height="847" alt="image26" src="https://github.com/user-attachments/assets/3fde0b22-04cf-40f7-bb85-52d8162a595b" />

assertion은 총 3개 중 success 1개, uncovered 및 without attempts 2개, failure 0개로 표시된다. 성공한 항목은 UVM component name check이고, 미시도 항목은 uvm_pkg의 reg map read/write 관련 assertion이므로 이번 프로젝트의 SPI/I2C 동작을 직접 검증한 SVA가 부족했다는 개선 포인트로 해석했다.

<img width="3680" height="2380" alt="image27" src="https://github.com/user-attachments/assets/2f2ad487-7292-4d0f-ac3d-2d5b7d0a940e" />

tb_SPI_I2C_UVM module은 score 83.42, line 73.68, condition 100.00, toggle 100.00, branch 60.00으로 보인다. line coverage가 100이 아닌 이유는 waveform basename plusarg, FSDB dump option 같은 testbench option 코드의 일부 경로가 실행되지 않았기 때문이며, DUT transaction mismatch와는 분리해서 해석해야 한다.

<img width="3592" height="2292" alt="image28" src="https://github.com/user-attachments/assets/e15f8dd9-742b-4530-97e5-a711bbdf9206" />

tb_SPI_I2C_UVM에서 표시된 condition은 5개 중 5개가 covered되어 100.00이다. 예시 조건식인 spi_ctrl_cs_n == 0과 spi_tgt_sdo_oe 조합이 true/false 조합으로 관찰됐기 때문에, top interface의 선택 구간 조건은 충분히 toggle된 것으로 볼 수 있다.

<img width="3592" height="2292" alt="image29" src="https://github.com/user-attachments/assets/cb06b7c5-54b0-46ec-ab91-674e5f190ae4" />

tb_SPI_I2C_UVM clock toggle은 0->1과 1->0이 모두 covered되어 100.00이지만, dashboard 전체 toggle은 51.81이다. top clock처럼 항상 움직이는 신호는 높게 나오고, 사용하지 않은 mode, read/error path, UVM recorder 쪽 신호는 낮게 남기 때문에 전체 toggle score가 내려갔다.

<img width="3592" height="2292" alt="image29" src="https://github.com/user-attachments/assets/cb06b7c5-54b0-46ec-ab91-674e5f190ae4" />

분석: tb_SPI_I2C_UVM의 branch는 10개 중 6개 covered, 60.00으로 표시된다. 특히 WAVE_BASENAME plusarg 미입력 경로와 DUMP_FSDB option처럼 한쪽만 실행된 분기가 missing else로 남아 있으며, 일부는 DUT 기능 부족이 아니라 testbench 실행 옵션을 한 가지로만 사용한 결과다.

<img width="1066" height="588" alt="image31" src="https://github.com/user-attachments/assets/fc714d26-a82e-4163-b9fe-ab5a30bf0bab" />

Verdi GUI에서도 평균 group score와 group instance score가 100.00으로 표시되고 U+C 29, C 29, U 0으로 나온다. protocol, test_kind, SPI MODE0, SPI full-duplex cross, I2C addr, ACK/RX, latency coverpoint가 HTML report와 동일한 DB에서 모두 hit됐음을 GUI로 재확인한 화면이다.

<img width="936" height="372" alt="image32" src="https://github.com/user-attachments/assets/72bc5204-807d-4529-ac20-bf882ec2b6ed" />

hierarchy/detail 화면은 I2C controller 60.45, I2C target 66.19, SPI controller 78.22, SPI target 86.75처럼 모듈별 code coverage 차이를 보여준다. SPI target은 현재 시나리오에 잘 맞아 높고, I2C와 FSM/toggle 항목은 write-only 및 정상 ACK 중심 시나리오 때문에 낮게 남았으며, uvm_custom_install_verdi_recording과 uvm_pkg는 tool/library 영향으로 따로 구분해야 한다.

이번 시뮬레이션에 대한 결과 요약은 아래와 같다.

| 분류 | 핵심 수치 | 원인 해석 | 개선 연결 |
|---|---|---|---|
| Functional group | Group 100.00, serial_cg 100.00 | 현재 계획한 protocol/test_kind/SPI/I2C coverpoint는 모두 hit | 다음에는 negative/read/mode coverage 추가 |
| Code coverage | Total 50.81, Branch 30.13, FSM 43.33 | 정상 write와 MODE0 중심이라 미사용 mode, option branch, tool/library 코드가 남음 | CPOL/CPHA, read, NACK, timeout, option path 시나리오 확장 |
| Assertions | 총 3개, success 1, failure 0, without attempts 2 | 프로젝트 SVA가 아니라 UVM package assertion 위주로 집계 | start-to-done, ACK, reset, CS/frame bound assertion 추가 |
| Tests page | 1 DB: simv/serial_regression | 단일 regression 실행 결과라 seed 간 편차는 확인하지 못함 | multi-seed regression 후 coverage merge 및 per-test 기여도 확인 |
| Verdi GUI | Group U+C 29, C 29, U 0 | HTML report와 Verdi에서 같은 functional coverage hit 확인 | coverage 확인을 마지막이 아니라 sequence 작성 단계부터 반복 |

표 22. Coverage report 화면별 확인 내용

개선에 대한 자세한 내용은 결과 분석에 포함된다.

## 6. 결과 분석

### 6.1 결과 해석

5장의 결과를 종합하면 기능 검증과 coverage 해석을 분리해서 봐야 한다. SPI/I2C 개별 TB는 기본 transaction mismatch 없이 통과했고, UVM regression은 scoreboard pass 156, fail 0 및 UVM_ERROR/FATAL 0으로 종료되어 계획한 정상 transaction은 모두 통과했다.

반면 coverage dashboard의 total score 50.81은 기능 실패가 아니라 검증 범위와 수집 대상의 차이에서 나온 값이다. Group 100.00은 이번 프로젝트가 직접 정의한 functional covergroup이 모두 hit됐다는 의미이고, Branch 30.13, FSM 43.33, Assert 33.33처럼 낮은 code/assertion 지표는 SPI MODE0, I2C write-only, 단일 정상 ACK 흐름, testbench option branch, UVM/tool library 코드가 함께 집계된 결과로 해석했다.

### 6.2 문제 원인 분석

| 구분 | 원인 | 해결 및 후속 조치 |
|---|---|---|
| UVM scope | 초기 구조에 SPI target 2개와 board demo 관점이 섞여 검증 범위가 흐려짐 | UVM top은 SPI 1:1, I2C 1:1로 고정하고 board demo evidence와 자동검증 evidence를 분리 |
| Coverage DB | 처음에는 coverage.vdb로 생각했지만 실제 Verdi/URG DB는 simv.vdb였음 | verdi -cov -covdir simv.vdb, urg -dir simv.vdb -report cov_report 기준으로 확인 |
| Code coverage | 정상 write, SPI MODE0, 1-byte frame 중심이라 mode/read/error/option branch가 실행되지 않음 | CPOL/CPHA 0~3, I2C read, repeated START, NACK, timeout, dump option path를 test로 추가 |
| Assertions | coverage report의 assertion은 uvm_pkg 항목 위주이고 프로젝트 동작 assertion은 부족함 | SPI start-to-done, CS frame bound, I2C ACK phase, reset valid low 같은 project-owned SVA 추가 |
| Coverage process | coverage 화면별 의미를 마지막 날에 확인해 결과 캡처는 했지만 closure 계획으로 쓰기에는 늦었음 | 다음 프로젝트는 covergroup/coverage checklist를 sequence 작성 전에 만들고 regression마다 dashboard와 group을 확인 |
| Report evidence | 파형만으로는 expected/actual 판정과 transaction 수를 설명하기 어려움 | UVM log, collector count, scoreboard pass/fail, coverage 수치를 함께 제시 |

표 23. 이슈 및 해결 과정

### 6.3 개선 방안

| 개선 항목 | 현재 한계 | 적용 방안 | 기대 효과 |
|---|---|---|---|
| Coverage-driven flow | 이번에는 UVM과 coverage report 기능을 학습하는 중이라 화면별 의미를 마지막에 정리함 | sequence 구현 전에 coverpoint, cross, SVA 목표를 먼저 정의하고 매 regression 후 dashboard, group, test, 검증 화면 확인 | 기능 통과 여부와 coverage gap을 동시에 관리 |
| Scenario expansion | SPI MODE0, 1-byte full-duplex, I2C addr 0x12 write-only 정상 흐름 중심 | SPI CPOL/CPHA 0~3, multi-target CS, I2C read, repeated START, address mismatch, NACK, timeout/recovery 추가 | Branch, FSM, toggle coverage 상승과 예외 상황 검증 강화 |
| Project SVA | 현재 assertion coverage는 UVM package 항목 위주라 DUT protocol rule을 직접 보장하지 못함 | SPI start 후 done latency, CS active frame bound, rx_valid 조건, I2C ACK 위치, reset 중 valid low assertion 추가 | scoreboard가 놓칠 수 있는 클럭 단위 timing rule 보강 |
| Multi-seed merge | coverage tests page가 simv/serial_regression 단일 DB만 사용 | seed별 regression을 실행하고 URG merge로 누적 coverage와 per-test 기여도 비교 | random test 편차 확인 및 coverage closure 근거 강화 |
| Report metrics | collector가 count와 평균 latency 중심으로 요약 | latency min/max, timeout count, protocol별 fail summary, test_kind별 pass/fail table 추가 | 발표와 완료보고서에서 원인 분석을 더 정량적으로 설명 |

표 24. 향후 개선 방안

정리하면 이번 프로젝트는 scoreboard pass/fail과 planned functional coverage 기준으로 정상 transaction 검증을 마쳤다. 그러나 code coverage와 assertion coverage를 함께 보니, 정상 write 중심 시나리오만으로는 분기, FSM, assertion 관점의 검증 공백이 남을 수 있다는 점도 확인했다. 다음 프로젝트에서는 coverage report를 사후 확인 자료가 아니라 검증 계획을 보완하는 기준으로 사용해, scenario 확장과 protocol assertion 추가를 더 이른 단계에서 반영할 계획이다.

## 7. 결론

이번 프로젝트에서는 기존에 주변장치나 library 형태로 사용하던 SPI/I2C 통신을 RTL과 UVM 관점에서 직접 구성했다. 통신 프로토콜이 실제로는 clock, data, select, ACK, timing, valid/done 조건이 맞아야 transaction이 성립한다는 점을 확인했다.

SPI는 Controller와 Target이 같은 frame에서 동시에 byte를 교환하는 full-duplex 구조로 이해했고, I2C는 address와 ACK를 통해 shared bus에서 Target 수신을 확인하는 write path로 이해했다. UVM 검증에서는 driver, monitor, scoreboard, coverage, collector 역할을 나누면서 어떤 조건을 확인했는지 설명할 수 있게 되었다.

남은 보완 항목은 SPI mode 확장, multi-target 검증, I2C read transaction, address mismatch, error/recovery scenario, protocol별 독립 agent 구성을 시도할 수 있다. 또한 coverage report와 assertion을 초기 검증 계획에 포함하면, 기능이 통과했는지만 확인하는 것이 아니라 검증되지 않은 조건이 무엇인지 함께 추적할 수 있다.

이번 작업을 통해 통신 IP를 설계하고 검증하는 흐름이 이전보다 구체적으로 보이기 시작했다.

## 참고 문헌

[0] Accellera Systems Initiative, Universal Verification Methodology (UVM) 1.2 User's Guide - https://www.accellera.org/images/downloads/standards/uvm/uvm_users_guide_1.2.pdf

[1] IEEE Standards Association, IEEE Std 1800-2023, SystemVerilog--Unified Hardware Design, Specification, and Verification Language - https://standards.ieee.org/ieee/1800/7743/

[2] NXP Semiconductors, UM10204 I2C-bus specification and user manual - https://www.nxp.com/documents/user_manual/UM10204.pdf

[3] Texas Instruments, Understanding the SPI Bus - https://www.ti.com/lit/pdf/sboa621

[4] Digilent, Basys 3 Reference Manual - https://digilent.com/reference/programmable-logic/basys-3/reference-manual

[5] AMD, Vivado Design Suite User Guide: Using the Vivado IDE (UG893) - https://docs.amd.com/r/en-US/ug893-vivado-ide
