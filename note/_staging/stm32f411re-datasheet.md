# STM32F411RE Datasheet

원본 위치: `/Users/mumallaeng/Library/CloudStorage/GoogleDrive-yonnmilk@gmail.com/My Drive/Classroom/대한상공회의소_반도체설계/김-/참고자료(Cortex-M4)/1.DataSheet_stm32f411re.pdf`

## 핵심 용도

`STM32F411RE` MCU의 하드웨어 능력, 패키지 핀, 전기적 조건, 주변장치 보유 현황을 확인하는 자료다. 레지스터 동작을 자세히 볼 때는 `Reference Manual`을 보고, 이 자료는 부품 스펙과 보드 연결 전제 확인에 사용한다.

## MCU 개요

| 항목 | 내용 |
|---|---|
| 코어 | Arm Cortex-M4 32-bit MCU, FPU 포함 |
| 성능 | 최대 `100 MHz`, 약 `125 DMIPS` |
| 메모리 | 최대 `512 KB Flash`, `128 KB SRAM` |
| 전원 범위 | 약 `1.7 V` to `3.6 V` |
| 주요 기능 | ART Accelerator, DSP instruction, MPU, RTC, CRC |
| 통신 주변장치 | `I2C`, `USART`, `SPI/I2S`, `SDIO`, `USB OTG FS` |
| 아날로그/타이머 | `12-bit ADC`, general-purpose/advanced timers |
| 식별 정보 | 96-bit unique ID |

## 자주 볼 구간

| 구간 | 용도 |
|---|---|
| Functional overview | 내부 블록과 기능 구성 확인 |
| Pinouts and pin description | 보드 핀, Alternate Function 매핑 확인 |
| Memory mapping | 주소 공간과 주변장치 베이스 확인 |
| Electrical characteristics | 전압, 전류, 타이밍 조건 확인 |
| Package information | `LQFP64` 등 패키지 치수와 핀 배치 확인 |
| Peripheral characteristics | `I2C`, `SPI`, `USART`, `ADC` 등 전기/타이밍 조건 확인 |

## 수업 연결

- GPIO 실습 전에는 핀 번호와 Alternate Function을 먼저 확인한다.
- UART, SPI, I2C 실습에서는 보드 커넥터 핀과 MCU AF 매핑을 같이 봐야 한다.
- ADC나 외부 소자 연결에서는 입력 전압 범위와 전기적 제한을 먼저 확인한다.
- 부트로더와 디버그 연결은 `USART`, `USB DFU`, `I2C`, `SPI`, SWD 연결 가능성을 같이 본다.
- Nucleo 보드 회로와 함께 보면 실제 핀 연결을 더 빠르게 추적할 수 있다.
