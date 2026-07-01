# SC16IS752 Datasheet

원본 위치: `/Users/mumallaeng/Library/CloudStorage/GoogleDrive-yonnmilk@gmail.com/My Drive/Classroom/대한상공회의소_반도체설계/김-/참고자료(Cortex-M4)/5.SC16IS752_Datasheet.pdf`

## 핵심 용도

`SC16IS752/SC16IS762`는 I2C-bus 또는 SPI 인터페이스를 dual UART로 변환하는 브리지 IC다. MCU가 I2C 또는 SPI로 이 칩의 레지스터를 접근하면, 칩 내부의 두 UART 채널과 GPIO를 사용할 수 있다.

## 주요 특징

| 항목 | 내용 |
|---|---|
| 기능 | I2C/SPI to dual UART bridge |
| FIFO | 송신/수신 각각 64-byte FIFO |
| UART 호환성 | 16C450 계열 레지스터 호환 |
| 전원 | `3.3 V`, `2.5 V` 동작 계열 |
| I2C | Fast-mode `400 kbit/s`, slave mode |
| SPI | slave mode, Mode 0 |
| SPI 속도 차이 | `SC16IS752` 최대 `4 Mbit/s`, `SC16IS762` 최대 `15 Mbit/s` |
| UART 속도 | 최대 약 `5 Mbit/s` |
| 흐름 제어 | `RTS/CTS`, software flow control `Xon/Xoff` |
| 부가 기능 | IrDA SIR, RS-485 자동 제어, 8 GPIO, software reset |

## 인터페이스 선택

| 핀/개념 | 의미 |
|---|---|
| `I2C/SPI` | HIGH면 I2C, LOW면 SPI |
| `A0`, `A1` | I2C 주소 선택 또는 SPI 관련 핀 병용 |
| `CS`, `SI`, `SO`, `SCLK` | SPI 접근 신호 |
| `SDA`, `SCL` | I2C 접근 신호 |
| `IRQ` | 인터럽트 출력 |
| `RESET` | 칩 리셋 |
| `GPIO0` to `GPIO7` | 범용 입출력 |

## 레지스터 관점

| 레지스터 계열 | 역할 |
|---|---|
| `RHR`, `THR` | 수신/송신 데이터 |
| `IER` | 인터럽트 enable |
| `IIR`, `FCR` | 인터럽트 식별, FIFO 제어 |
| `LCR` | word length, stop bit, parity |
| `MCR` | modem control |
| `LSR` | line status |
| `MSR` | modem status |
| `EFR` | enhanced feature |
| `TCR`, `TLR` | trigger level 관련 |

## 수업 연결

- SPI/I2C 통신 실습과 UART 실습이 한 부품에서 만나는 구조다.
- 먼저 인터페이스 모드 선택 핀과 주소/CS 연결을 회로도에서 확인한다.
- UART가 동작하지 않으면 클록, baud rate divisor, FIFO enable, `LCR` 설정을 순서대로 점검한다.
- 수신 인터럽트 기반 실습에서는 `IER`, `IIR`, `LSR`, `IRQ` 라인을 같이 봐야 한다.
- `GPIO0` to `GPIO7`은 확장 보드 LED 출력과 연결될 수 있다.
