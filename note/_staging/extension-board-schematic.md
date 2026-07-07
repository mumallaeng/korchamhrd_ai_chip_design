# Extension Board Schematic

원본 위치: `Google Drive/My Drive/Classroom/대한상공회의소_반도체설계/김-/참고자료(Cortex-M4)/4.Extension_Board_Schematic.pdf`

## 핵심 용도

`BUS EXT B'd V1.0` 확장 보드의 UART 브리지, GPIO LED, RGB LED 체인, 커넥터, 풀업, 오실레이터 연결을 확인하는 회로도다. SPI/I2C 기반 UART 확장과 LED 제어 실습의 보드 배선을 파악하는 데 유용하다.

## 주요 블록

| 블록 | 내용 | 관련 신호 |
|---|---|---|
| `UART_GPIO_EXT` | `SC16IS752/762` 기반 dual UART/GPIO 확장 | `SPI_CS/A0`, `SPI_MOSI/A1`, `SPI_MISO/N.C`, `SPI_SCLK/I2C_SCL`, `VSS/I2C_SDA` |
| 인터럽트/리셋 | UART 브리지 제어 신호 | `/IRQ`, `/RST` |
| UART 채널 | 외부 UART 흐름 제어와 송수신 | `/RTS1`, `/CTS1`, `TX1`, `RX1` |
| LED 블록 | 8개 단일 LED 출력 | `OUT00` to `OUT07`, 각 `1K` 저항 |
| RGB LED 블록 | `WS2812B` 계열 직렬 RGB LED 체인 | `LED_DIN`, `LED_DOUT` |
| I2C 풀업 | I2C 라인 풀업 구성 | `I2C_SCL`, `I2C_SDA` |
| 클록 | UART 브리지용 오실레이터 | `7.3728 MHz` |
| 커넥터 | Nucleo 또는 외부 보드 연결 | `J1` 24-pin |

## 수업 연결

- `SC16IS752/762`은 SPI 또는 I2C로 접근하고, 내부에서 UART 두 채널과 GPIO를 제공한다.
- 보드 회로에서는 SPI 핀명과 I2C 핀명이 같은 핀에 병기되어 있어, 사용 모드 선택을 먼저 확인해야 한다.
- `/IRQ`는 수신 데이터나 상태 변화 인터럽트 처리 실습과 연결된다.
- `OUT00` to `OUT07` LED는 UART 브리지의 GPIO 제어 실습 대상으로 사용 가능하다.
- `WS2812B` 체인은 단순 GPIO 토글이 아니라 정확한 단선식 타이밍이 필요하다.
