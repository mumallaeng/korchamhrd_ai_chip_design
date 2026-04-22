# 26-04-22 - UART 시스템 구조와 TX/RX

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | UART RX 샘플링, loopback 구조, `rx_done -> tx_start` 연결 |
| 목표 | TX와 RX를 따로 보는 게 아니라 한 시스템으로 이해 |
| 핵심 | `uart_rx`, `uart_loopback`, `tb_uart_loopback` |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sources_1/new/uart.v` | `50-173` | `uart_rx` 상태기계와 샘플링 로직 |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sources_1/new/uart_loopback.v` | `3-23` | `rx_done`를 `tx_start`로 바로 연결한 echo 구조 |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sim_1/new/tb_uart_loopback.v` | `40-59` | 외부 UART 송신기 역할 task |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sim_1/new/tb_uart_loopback.v` | `61-80` | `tx` 라인에서 다시 수신하는 task |
| `helloHDL/260421_uart_fsm/uart_fsm.srcs/sim_1/new/tb_uart_loopback.v` | `83-105` | loopback 결과 비교 |

## RX 샘플링 흐름

| 단계 | 코드 위치 | 의미 |
| --- | --- | --- |
| `IDLE` | `uart.v:101-107` | 라인이 `1 -> 0`으로 내려가면 start bit 후보로 본다 |
| `START` | `uart.v:110-124` | `7` tick까지 가서 비트 중앙 부근에서 start를 다시 확인한다 |
| `DATA` | `uart.v:128-145` | `16` tick마다 1비트씩 샘플링해 `data_reg`에 넣는다 |
| `STOP` | `uart.v:147-159` | stop bit 안쪽까지 본 뒤 `rx_done` 펄스를 낸다 |

## 코드에서 꼭 볼 줄

| 위치 | 포인트 |
| --- | --- |
| `uart.v:69-72` | RX 출력은 `data_reg`, 완료 신호는 `rx_done_reg`로 분리된다 |
| `uart.v:81-90` | `rx` 입력은 두 단계 동기화 후 `rx_sync_reg`로 사용한다 |
| `uart.v:134-139` | 받은 비트는 `LSB first` 순서에 맞게 쉬프트 저장한다 |
| `uart_loopback.v:13-23` | 받은 바이트를 다시 같은 UART TX에 바로 넣는다 |
| `tb_uart_loopback.v:68-74` | 테스트벤치도 bit 중앙에서 샘플링한다 |

## 주의점

| 오해 | 정리 |
| --- | --- |
| RX는 TX 코드를 뒤집으면 된다 | RX는 샘플링 시점이 핵심이라 timing 관리가 더 중요하다 |
| `rx_done`는 level 신호다 | 여기서는 프레임이 끝날 때 잠깐 올라가는 pulse에 가깝다 |
| stop bit는 마지막 `1` 하나만 보면 된다 | 실제로는 stop 구간까지 기다린 뒤 프레임 종료를 확정한다 |

## 연결 노트

- [[260428-uart-button-tx]]
- [[260429-shift-register-rx-fifo]]
