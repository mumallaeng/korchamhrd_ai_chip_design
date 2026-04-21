# 26-04-21 - UART 기초와 TX FSM

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | UART 프레임, `baud tick`, TX 상태기계 |
| 목표 | `tx_start`가 들어오면 start, data, stop 비트가 어떤 순서로 나가는지 이해 |
| 핵심 | `uart`, `uart_tx`, `baud_tick_gen`, `tb_uart` |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sources_1/new/uart.v` | `3-48` | `uart` top, TX, RX, baud generator 연결 |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sources_1/new/uart.v` | `175-301` | `uart_tx` 상태기계 |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sources_1/new/uart.v` | `303-333` | `baud_tick_gen`, `BAUD x16` tick 생성 |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sim_1/new/tb_uart.v` | `27-40` | 저속 파라미터로 DUT 연결 |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sim_1/new/tb_uart.v` | `98-135` | start, data, stop 비트 확인 |

## 프레임과 상태

| 상태 | 핵심 동작 |
| --- | --- |
| `IDLE` | `tx = 1`, 전송 대기 |
| `START` | `tx = 0`, 시작 비트 1개 출력 |
| `DATA` | `data_reg[0]`부터 `LSB first`로 8비트 전송 |
| `STOP` | `tx = 1`, 정지 비트 출력 후 `IDLE` 복귀 |

## 코드에서 꼭 볼 줄

| 위치 | 포인트 |
| --- | --- |
| `uart.v:231-237` | `tx_start`가 들어오면 `tx_data`를 내부 레지스터로 잡고 `START`로 이동 |
| `uart.v:240-248` | `START` 상태에서는 라인을 `0`으로 내려 start bit를 만든다 |
| `uart.v:255-267` | `DATA` 상태에서 `data_reg[0]`을 내보내고 시프트한다 |
| `uart.v:275-283` | `STOP` 뒤에 `tx_busy`를 내리고 `IDLE`로 복귀한다 |
| `tb_uart.v:114-129` | 테스트벤치가 각 data bit와 stop bit를 직접 비교한다 |

## 주의점

| 오해 | 정리 |
| --- | --- |
| `baud tick`이 곧 data bit 타이밍이다 | 여기서는 `BAUD x16` tick을 만들고 그 안에서 bit 시간을 센다 |
| TX는 비트를 한 번에 보낸다 | 실제로는 `START -> DATA -> STOP` 상태를 순서대로 돈다 |
| idle이 `0`이다 | UART 라인 idle은 기본적으로 `1`이다 |

## 연결 노트

- [[260422-uart-tx-rx]]
- [[260428-uart-button-tx]]
