[English](README.md) | 한국어

# UART LOOPBACK

김연우
2026.04.22 ~ 2026.04.27

## 1. 개요 (Overview)

### 1.1 목적 및 목표

- Timepiecer 프로젝트에서 드러난 한계를 바탕으로, 보드 외부와 데이터를 주고받는 UART 구조의 필요성을 설명한다.
- UART 이론, loopback 구조, FSM/ASM/RTL, 시뮬레이션, 구현, 이후 수업 연결까지 최종 발표 흐름에 맞춰 정리한다.

이번 프로젝트의 목적은 이전 Timepiecer 프로젝트에서 7-Segment로만 확인하던 값을 PC와 직접 주고받을 수 있는 형태로 확장하는 데 있다. 이를 위해 Basys3 보드와 PC 사이의 UART 통신 경로를 구성하고, 비동기 직렬 통신의 핵심인 baud rate, frame, start/stop bit, bit 순서, sampling timing을 직접 설명하고 검증하는 것을 목표로 하였다.

### 1.2 설계 범위

- **포함 범위**: 이전 프로젝트 한계 정리, UART 기초 이론, bit/byte와 serial 개념, shift register, UART frame, block diagram, RX/TX FSM/ASM/RTL, 시뮬레이션, 구현 결과
- **제외 범위**: parity bit, 다중 바이트 buffering, FIFO 실제 구현, 고속 프로토콜 최적화

### 1.3 프로젝트 요약

- Timepiecer 이후 단계로, Basys3와 PC를 UART로 연결해 수신한 1바이트를 다시 송신하는 loopback 시스템
- 핵심 키워드: Timepiecer 확장, UART 8N1, serial communication, shift register, RX/TX FSM, stop bit troubleshooting

### 1.4 설계 사양 요약 (Specification Summary)

주요 설계 및 발표 기준 파라미터는 아래와 같다.

- 시스템 클럭: 100 MHz
- Baud rate: 9600 bps
- Sampling: 16x oversampling, start bit center re-check
- 프레임: 8 data bits, no parity, 1 stop bit (8N1)
- 목표: 이전 프로젝트의 한계를 통신 구조로 확장하고, 수신 데이터와 재송신 데이터가 일치함을 확인

### 1.5 AS-IS / TO-BE (선택)

- **AS-IS**: Timepiecer는 보드 내부 표시 중심 구조라서 외부 장치와 직접 데이터를 주고받는 통신 경로가 없었다.
- **TO-BE**: USB-UART 경로를 이용해 PC와 연결하고, 수신한 값을 즉시 다시 송신하는 loopback 구조를 통해 외부 통신의 출발점을 만든다.
- **주요 개선 사항**: 통신 필요성 제시, UART 기본 이론 학습, RX/TX FSM 정리, stop bit 기준 비교, 이후 수업 확장 방향 도출

## 2. 프로젝트 관리 (Project Management)

### 2.1 일정 계획 (Schedule)

| 단계 | 기간 | 주요 작업 |
|---|---|---|
| 문제 인식/이론 정리 | 2026.04.22 ~ 2026.04.23 | Timepiecer 한계, Basys3 통신 필요성, UART 기초 개념 정리 |
| 구조 설계 | 2026.04.23 ~ 2026.04.24 | UART frame, block diagram, RX/TX FSM/ASM 정리 |
| RTL/시뮬레이션 | 2026.04.24 ~ 2026.04.25 | RTL 구조 확인, testbench, ASCII 0x30 loopback 파형 검증 |
| 트러블슈팅/구현 | 2026.04.26 | 23 tick stop bit 비교, 보드 구현 확인 |
| 최종 발표/정리 | 2026.04.27 | 최종 발표, 일정표/일지/완료보고서 내용 정리 |

### 2.2 개발 환경 (Development Environment)

| 분류 | 기술 |
|---|---|
| 학습 자료 | 수업 자료, 발표 슬라이드, 보드 실습 결과 |
| 문서 | Microsoft PowerPoint, Word, Excel, Markdown |

### 2.3 설계 환경 (Design Environment)

| 분류 | 내용 |
|---|---|
| 언어 | Verilog HDL |
| FPGA | Digilent Basys 3 (Artix-7 XC7A35T) |
| EDA | Vivado 2020.2 |
| Simulator | Vivado XSim, Icarus Verilog |

## 3. 아키텍처 설계 (Architecture)

### 3.1 시스템 구조

<img width="1812" height="466" alt="image3" src="https://github.com/user-attachments/assets/8fcb8c6a-b307-449d-9a1e-79f4bb688b69" />

- **Block Diagram**: 이전 프로젝트의 표시 중심 구조에서 한 단계 나아가, `clk/rst -> baud_tick_gen -> {uart_rx, uart_tx}`, `rx -> uart_rx`, `rx_data -> tx_data`, `rx_done -> tx_start`, `uart_tx -> tx` 구조로 PC와 연결되는 흐름을 정의하였다.
- **데이터 흐름 정의**: PC 또는 testbench에서 들어온 직렬 입력 `rx`를 수신부가 8비트 병렬 데이터로 조립하고, 수신 완료 시 같은 값을 다시 직렬 `tx`로 송신한다.

### 3.2 설계 이론 및 배경 (Theory & Background)

- 발표 초반부에서는 먼저 통신을 '같은 약속으로 비트를 주고받는 것'으로 정의하였다. 이 약속에는 속도, 시작과 끝, 비트 순서가 포함된다.
- 이후 bit가 모여 byte가 되는 구조, parallel과 serial의 차이, shift register의 역할을 설명하고, UART가 별도 clock 없이 baud rate 약속으로 동작하는 비동기 직렬 통신임을 정리하였다.
- 이번 설계는 9600 8N1, LSB-first, 16x oversampling을 기준으로 구성하였으며, RX는 start bit를 중앙 근처에서 재확인한 뒤 data를 샘플링한다.

관련 이론은 최종 발표 슬라이드의 '`Timepiecer 한계 -> UART 기초 이론 -> UART 구조`' 흐름과 수업 중 사용한 UART frame 설명을 기반으로 정리하였다.

- RX FSM
<img width="1283" height="641" alt="image4" src="https://github.com/user-attachments/assets/028f4381-7feb-4f94-88e8-cc863f6238ba" />

- TX FSM
<img width="1609" height="818" alt="image5" src="https://github.com/user-attachments/assets/a962c407-da4f-466c-b22a-98c0e5c1fd74" />

- RX ASM
<img width="1124" height="781" alt="image6" src="https://github.com/user-attachments/assets/57af01bc-a188-4fac-b952-7b078ece25af" />

- TX ASM
<img width="955" height="790" alt="image7" src="https://github.com/user-attachments/assets/06ba3ac5-dfe0-4de9-b653-ee571a461619" />

## 4. 상세 설계 (Detailed Design)

### 4.1 RTL

<img width="1225" height="577" alt="image8" src="https://github.com/user-attachments/assets/f4e17ad6-aa46-4213-9eda-a78b50eb1545" />

- **Module 구성**: `uart_loopback.v`(top), `uart.v`(내부에 `baud_tick_gen`, `uart_rx`, `uart_tx` 포함), `tb_uart_loopback.v`(기본 loopback 검증)
- **주요 구조 설명**: 발표 중에는 block diagram 다음에 RX FSM, TX FSM, RX ASM, TX ASM, RTL 순서로 설명하여 상위 구조에서 하위 동작으로 내려가는 흐름을 유지하였다.

### 4.2 Datapath / Control

- **연산 구조 정의**: RX는 직렬 입력을 shift-in 하여 병렬 데이터로 조립하고, TX는 병렬 데이터를 shift-out 하여 다시 직렬 데이터로 내보낸다. 이 과정이 loopback의 핵심 datapath이다.
- **상태 제어 로직**: `rx_done -> tx_start`, `rx_data -> tx_data` 연결로 별도 버퍼 없이 1바이트 echo를 구성하였다.

### 4.3 Timing 설계

- Timing 설계의 핵심은 baud tick 생성과 sampling 시점이다. 100MHz 시스템 클럭을 9600bps용 16배 기준 tick으로 분주하고, RX/TX가 이 tick을 공통으로 사용하도록 하였다.
- 발표에서 강조한 timing 포인트는 start bit 중앙 재확인, 16 tick 간격 data sampling, 그리고 stop bit 구간에서 done 시점이 언제 발생하는가였다.

### 4.4 설계 전략 (Design Strategy)

- 설계 전략: 복잡한 기능을 추가하기보다 수업 내용에 맞게 loopback 구조를 단순하게 유지하면서 UART의 원리가 잘 드러나도록 구성하였다.
- 따라서 이번 설계는 low power나 고속화보다, serial 통신 원리와 상태 전이 구조를 명확히 보여주는 교육용 구조에 초점을 두었다.
- 안정성 관점에서는 start bit 재확인, stop bit 확인, RX 입력 동기화, 그리고 파형 비교를 통한 트러블슈팅 절차를 사용하였다.

## 5. 시뮬레이션 및 검증 (Simulation & Verification)

### 5.1 Testbench

| 신호 이름 | 신호 설명 |
|---|---|
| clk | 100MHz 메인 클럭. 전체 UART timing의 기준이 됨. |
| rst | 상태 레지스터와 카운터를 초기 상태로 되돌리는 reset 신호. |
| rx | PC 또는 testbench에서 들어오는 UART 직렬 입력. |
| tx | 수신한 값을 다시 내보내는 UART 직렬 출력. |
| b_tick | baud tick generator가 만드는 16x oversampling 기준 신호. |
| rx_data[7:0] | RX가 조립한 1바이트 병렬 데이터. |
| rx_done | 수신 완료 시점에 발생하는 제어 신호. loopback에서는 tx_start로 연결됨. |
| tx_start | TX 시작 신호. 이번 구조에서는 rx_done과 직접 연결된다. |

표 1. 최종 발표와 시뮬레이션 파형에서 확인한 주요 신호 정의

| State 이름 | State 설명 |
|---|---|
| RX_IDLE | line idle 상태에서 start bit가 들어올 때까지 대기한다. |
| RX_START | start bit를 감지한 뒤 중앙 근처에서 다시 확인한다. |
| RX_DATA | 16 tick마다 1비트씩 샘플링하여 8비트를 조립한다. |
| RX_STOP | stop bit 구간을 확인하고 수신 완료를 정리한다. |
| TX_IDLE | 송신 대기 상태로 tx=1을 유지한다. |
| TX_START | start bit 0을 출력하며 송신을 시작한다. |
| TX_DATA | data_reg[0]부터 LSB-first 순서로 데이터를 송신한다. |
| TX_STOP | stop bit 1을 출력하고 다음 송신을 준비한다. |

표 2. RX/TX FSM에서 사용한 상태 의미 정리

### 5.2 시뮬레이션 시나리오

- 시뮬레이션 시나리오 1. `8'h30`(ASCII "0")을 입력했을 때 UART frame이 수신되고, 동일한 값이 다시 tx로 출력되는지 확인한다.
- 시뮬레이션 시나리오 2. slide 19~21의 트러블슈팅에 맞춰, stop bit 구간에서 done 시점을 15 tick 기준과 23 tick 기준으로 비교한다.

## 6. 결과 분석 및 트러블슈팅 (Analysis & trouble shooting)

<img width="1380" height="427" alt="image9" src="https://github.com/user-attachments/assets/648d33e3-14d5-4ce7-927a-fbb1e315ee16" />

파형 분석에서는 start bit 이후 data bit가 LSB-first 순서로 이동하는 과정, `rx_done` 이후 `tx_start`가 연계되는 과정, 그리고 stop bit 처리 시점을 중점적으로 관찰하였다.

핵심 파형은 `rx_23_b_tick_cnt`, `rx_15_b_tick_cnt`, `rx15_data` 비교이며, 이를 통해 stop bit 보장 관점이 설명된다.

<img width="1379" height="556" alt="image10" src="https://github.com/user-attachments/assets/b3f4b545-3323-4d4b-b852-ca1221f7579e" />

기본 loopback 파형에서는 입력과 재송신 값이 일치함을 확인하였고, 추가 비교 파형에서는 stop bit 구간 이후 done 시점을 더 늦추는 쪽이 경계 설명에 유리함을 정리하였다.

## 7. 결론

이번 UART loopback 발표를 통해 이전 프로젝트의 한계를 통신 구조로 확장하고, bit/byte, serial, protocol, FSM, RTL, 파형, 구현까지 한 흐름으로 정리할 수 있었다.

Basys3와 PC를 micro-USB로 연결하여 UART loopback 구조를 설명하고, PC에서 입력한 값이 다시 돌아오는 echo 형태의 구현 결과를 제시하였다.

이 결과는 이전 Timepiecer 프로젝트가 보드 내부 표시에서 끝났던 구조에서, 보드 외부 통신으로 한 단계 확장되었다는 점에서 의미가 있다.

또한 UART 이론 설명과 FSM/RTL 설명, 시뮬레이션 파형, 구현 결과가 하나의 흐름으로 연결되도록 발표를 구성하여 학습 내용을 정리하였다.

Trade-off 관점에서는 FIFO나 error flag 같은 확장 기능은 제외했지만, 그만큼 UART의 기본 개념과 상태 전이 구조를 직관적으로 보여줄 수 있었다.

주요 문제 인식은 'STOP bit를 어디까지 확인해야 수신 완료를 더 안정적으로 설명할 수 있는가'였다. 이에 따라 15 tick 기준과 23 tick 기준을 비교했고, stop bit를 충분히 지난 뒤 done을 보는 관점이 발표와 설명 측면에서 더 적합하다고 정리하였다.

개선 방안: 이후에는 FIFO를 추가해 데이터 유실 방지 구조를 만들고, 센서 값을 UART로 출력해 실제 측정 데이터를 더 직접적으로 검증할 수 있다.
