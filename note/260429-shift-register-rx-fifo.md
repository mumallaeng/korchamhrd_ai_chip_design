# 26-04-29 - Shift Register, RX Oversampling, FIFO 입문

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | UART TX 쉬프트, RX oversampling, FIFO 버퍼 |
| 목표 | 직렬 전송과 버퍼링을 저장 구조 관점에서 묶어 보기 |
| 핵심 | `uart_tx`, `uart_rx`, `uart_fifo_loopback`, `fifo` |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sources_1/new/uart.v` | `255-267` | TX가 `data_reg`를 쉬프트하며 `LSB first` 전송 |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sources_1/new/uart.v` | `128-145` | RX가 `16` tick마다 1비트씩 샘플링 |
| `helloHDL/260422_uart_fifo/uart_fifo.srcs/sources_1/new/uart_fifo_loopback.v` | `15-25` | UART와 TX 시작 조건 연결 |
| `helloHDL/260422_uart_fifo/uart_fifo.srcs/sources_1/new/uart_fifo_loopback.v` | `27-49` | RX FIFO, TX FIFO 연결 |
| `helloHDL/260506_remip/remip.srcs/sources_1/new/fifo.v` | `3-41` | FIFO top, `register_file`와 `control_unit` 연결 |
| `helloHDL/260506_remip/remip.srcs/sources_1/new/fifo.v` | `43-63` | 실제 데이터 저장소인 `register_file` |
| `helloHDL/260506_remip/remip.srcs/sources_1/new/fifo.v` | `67-149` | `wptr`, `rptr`, `full`, `empty` 제어 |
| `helloHDL/260422_uart_fifo/uart_fifo.srcs/sim_1/new/tb_uart_fifo_loopback.v` | `24-54` | UART 입력을 넣는 간단한 TB |

## 저장 구조 관점에서 보기

| 구조 | 코드 포인트 | 의미 |
| --- | --- | --- |
| TX shift register | `uart.v:255-267` | 병렬 8비트를 직렬 1비트씩 내보낸다 |
| RX shift register | `uart.v:134-139` | 들어오는 1비트를 모아 8비트 바이트를 만든다 |
| FIFO | `fifo.v:81-149` | write/read pointer로 순서를 보존한다 |

## 코드에서 꼭 볼 줄

| 위치 | 포인트 |
| --- | --- |
| `uart_fifo_loopback.v:18-19` | TX는 `~w_tx_pop_empty`일 때만 시작한다 |
| `uart_fifo_loopback.v:31-36` | RX 쪽은 `rx_done`가 나오면 FIFO에 push한다 |
| `uart_fifo_loopback.v:45-49` | TX FIFO는 `~w_tx_busy`일 때 pop한다 |
| `fifo.v:25` | `we = (~full) & push`라서 꽉 찼을 때는 쓰지 않는다 |
| `fifo.v:117-128` | pointer 비교로 `full`, `empty`를 갱신한다 |

## 주의점

| 오해 | 정리 |
| --- | --- |
| UART TX는 PIPO면 충분하다 | 직렬 출력이므로 `PISO`나 쉬프트 레지스터 관점이 더 맞다 |
| FIFO는 메모리만 있으면 끝이다 | 포인터, `full`, `empty`, push/pop 제어가 핵심이다 |
| 현재 TB가 자동 판정까지 다 한다 | `tb_uart_fifo_loopback.v`는 입력을 넣고 멈추는 쪽이라 self-check가 약하다 |

## 연결 노트

- [[260430-fifo-sensor-interface]]
- [[260415-ila와-시뮬레이션]]
