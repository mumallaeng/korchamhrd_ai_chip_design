# STM32F411RE Reference Manual

원본 위치: `/Users/mumallaeng/Library/CloudStorage/GoogleDrive-yonnmilk@gmail.com/My Drive/Classroom/대한상공회의소_반도체설계/김-/참고자료(Cortex-M4)/2.Reference_Manual_stm32f411re.pdf`

## 핵심 용도

`STM32F411xC/E` 계열의 메모리 구조, 클록, 인터럽트, GPIO, DMA, 타이머, ADC, I2C, USART, SPI, SDIO, USB 등 주변장치 동작을 레지스터 수준에서 확인하는 자료다. 실습 중에는 처음부터 순서대로 읽기보다 사용 중인 주변장치 장으로 바로 이동하는 방식이 적합하다.

## 빠른 탐색표

| 주제 | 위치 감각 | 실습에서 보는 이유 |
|---|---|---|
| Documentation conventions | 앞부분 | 레지스터 표기, reserved bit 해석 |
| Memory and bus architecture | 앞부분 | 주소 공간, 버스 구조 이해 |
| Flash memory interface | 앞부분 | Flash wait state, 프로그램 메모리 조건 |
| Power controller `PWR` | 앞부분 | 전원 모드, 저전력 동작 |
| Reset and clock control `RCC` | 초반 | 클록 enable, PLL, peripheral clock |
| System configuration `SYSCFG` | 초반 | EXTI 매핑, 시스템 설정 |
| GPIO | 초반 | 모드, 출력 타입, Pull-up/down, AF 설정 |
| DMA | 중반 | 주변장치와 메모리 전송 |
| NVIC/EXTI | 중반 | 인터럽트와 외부 입력 |
| ADC | 중반 | 변환 채널, 샘플링, 트리거 |
| TIM1, TIM2-TIM5, TIM9-TIM11 | 중반 | PWM, 주기 타이머, 입력 캡처 |
| I2C | 후반 | I2C master/slave, address, status flag |
| USART | 후반 | baud rate, TX/RX, interrupt, DMA |
| SPI/I2S | 후반 | SPI master/slave, CPOL/CPHA, data frame |
| SDIO | 후반 | SD 카드 인터페이스 |
| USB OTG FS | 후반 | USB device/host 관련 |
| Debug support | 마지막 | 디버그 인터페이스와 추적 |
| Device electronic signature | 마지막 | unique ID, Flash size 등 |

## 읽는 순서

| 실습 상황 | 먼저 볼 장 |
|---|---|
| LED GPIO 출력 | `RCC` -> `GPIO` |
| 버튼 인터럽트 | `RCC` -> `GPIO` -> `SYSCFG` -> `EXTI/NVIC` |
| UART 출력 | `RCC` -> `GPIO AF` -> `USART` |
| SPI 소자 제어 | `RCC` -> `GPIO AF` -> `SPI/I2S` |
| I2C 소자 제어 | `RCC` -> `GPIO AF` -> `I2C` |
| PWM 출력 | `RCC` -> `GPIO AF` -> `TIM` |
| ADC 입력 | `RCC` -> `GPIO analog mode` -> `ADC` |

## 수업 연결

- `Datasheet`는 핀과 전기적 조건 확인용, `Reference Manual`은 레지스터와 동작 순서 확인용으로 나눈다.
- 모든 주변장치 실습은 대체로 `RCC` 클록 enable이 출발점이다.
- 핀을 주변장치로 쓰려면 GPIO의 Alternate Function 설정과 주변장치 설정이 같이 맞아야 한다.
- 인터럽트가 들어가는 실습은 주변장치 내부 enable, EXTI/SYSCFG, NVIC 설정을 분리해서 점검한다.
