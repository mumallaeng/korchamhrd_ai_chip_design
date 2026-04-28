# 26-04-28 - UART 버튼 입력과 TX 시작

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | 버튼 디바운스, `sw[7:0]` 전송, 보드 핀 연결 |
| 목표 | 버튼 한 번으로 UART TX가 정확히 한 프레임 시작되게 만들기 |
| 핵심 | `uart_button`, `button_debounce`, `tb_uart_button`, `full.xdc` |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sources_1/new/uart_button.v` | `3-15` | top I/O, `btnR`, `sw`, `led`, `tx` |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sources_1/new/uart_button.v` | `17-35` | 버튼을 `w_start` pulse로 바꾸는 부분 |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sources_1/new/uart_button.v` | `37-52` | `sw[7:0]`를 UART TX 데이터로 넣는 부분 |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sources_1/imports/new/button_debounce.v` | `17-29` | sync, level, tick 출력 정의 |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sources_1/imports/new/button_debounce.v` | `40-81` | 샘플링, history, stable 판정 |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/constrs_1/new/full.xdc` | `64-69` | `rst`, `btnR` 버튼 핀 |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/constrs_1/new/full.xdc` | `130-132` | UART `rx`, `tx` 핀 |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sim_1/new/tb_uart_button.v` | `65-71` | 버튼 누름 task |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sim_1/new/tb_uart_button.v` | `93-111` | 버튼 후 실제 전송 데이터 확인 |

## 입력에서 전송까지 흐름

| 단계 | 설명 |
| --- | --- |
| 버튼 입력 | `btnR`는 그대로 쓰지 않고 먼저 디바운스한다 |
| 시작 pulse | `o_btn_tick`이 `w_start`가 되어 TX 시작 신호가 된다 |
| 전송 데이터 | `sw[7:0]`만 UART에 실린다 |
| 눈으로 보는 값 | `led = sw`라서 스위치 상태를 바로 확인할 수 있다 |

## 코드에서 꼭 볼 줄

| 위치 | 포인트 |
| --- | --- |
| `uart_button.v:23` | `led = sw`라서 입력 스위치 값을 바로 본다 |
| `uart_button.v:43-45` | 버튼 pulse가 들어오면 `sw[7:0]`를 TX 데이터로 잡는다 |
| `button_debounce.v:28` | `o_btn_tick = level_reg & ~level_d1_reg`라서 1회 pulse가 나온다 |
| `button_debounce.v:67-70` | history가 전부 `1` 또는 `0`일 때만 level을 바꾼다 |
| `tb_uart_button.v:96-107` | 실제로 `8'hA5`가 전송 데이터로 들어갔는지 테스트한다 |

## 주의점

| 오해 | 정리 |
| --- | --- |
| 버튼 level이 곧 `tx_start`다 | 실제로는 디바운스 후 1회 pulse가 더 중요하다 |
| `sw[15:0]` 전부 전송된다 | 현재 전송 데이터는 `sw[7:0]`만 쓴다 |
| XDC는 마지막에만 보면 된다 | 보드 입출력 프로젝트는 RTL과 핀맵을 같이 봐야 한다 |

## 연결 노트

- [[260429-shift-register-rx-fifo]]
- [[260430-fifo-sensor-interface]]
