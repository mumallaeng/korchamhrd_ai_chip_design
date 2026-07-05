# {student_name} {project_title} 일지

## 2026-04-22

- Timepiecer/Watch 프로젝트에서 값이 보드 안에서만 확인된다는 한계를 다시 정리했다.
- Basys3 단독 입출력 구조와 PC 연결 필요성을 확인했다.
- UART가 왜 이번 과제의 출발점이 되는지 방향을 잡았다.

## 2026-04-23

- 비트와 바이트의 관계, serial과 parallel의 차이, shift register 개념을 정리했다.
- UART protocol, 9600 8N1, LSB-first, oversampling 개념을 발표 흐름에 맞춰 정리했다.
- 이후 block diagram과 FSM 설명으로 넘어갈 수 있는 이론 흐름을 만들었다.

## 2026-04-24

- UART loopback block diagram을 기준으로 RX/TX/baud tick 구조를 정리했다.
- RX FSM, TX FSM, RX ASM, TX ASM을 각각 발표 순서에 맞춰 정리했다.
- RTL을 counter, shift register, state machine 조합으로 설명할 수 있게 구성했다.

## 2026-04-25

- `8'h30` 기준 loopback 시뮬레이션과 기본 파형을 확인했다.
- `rx_done`, `tx_start`, LSB-first 데이터 흐름을 중심으로 파형을 정리했다.
- 발표에서 어떤 파형을 먼저 보여줄지 기준을 잡았다.

## 2026-04-26

- STOP bit 보장을 위해 15 tick 기준과 23 tick 기준을 비교하는 관점으로 트러블슈팅을 정리했다.
- `rx_23_b_tick_cnt`, `rx_15_b_tick_cnt`, `rx15_data` 파형을 비교하며 설명 순서를 다듬었다.
- Basys3와 PC를 연결한 구현 결과와 발표 후반부 내용을 정리했다.

## 2026-04-27

- 최종 발표 흐름을 `이전 프로젝트 한계 -> UART 이론 -> 설계 -> 시뮬레이션/트러블슈팅 -> 구현 -> 이후 수업 연결` 순서로 맞췄다.
- 발표 이후 FIFO, 센서, SV 검증, RV32I로 이어지는 다음 단계 의미를 다시 정리했다.
- 완료보고서, 일정표, 일지 내용을 최종 발표 기준으로 정리했다.
