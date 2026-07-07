# ARM Cortex-M4 디바이스 프로그래밍 메모

## 과목별 연결 노트

이 노트는 `ARM Cortex-M4 디바이스 프로그래밍` 과목의 디바이스 제어 범위를 정리한다. 전자 회로 기초에서 출발해 GPIO, UART, Timer, Interrupt, I2C, SPI, ADC 주변장치를 C 코드로 제어할 때 필요한 register 접근 모델까지 이어진다.

| 범위 | 파일 | 내용 |
| :--- | :--- | :--- |
| 1과 | [ARM Cortex-M4 디바이스 프로그래밍 1과](../../../domains/semiconductor/ai-npu-system-integration/arm-cortex-m4-device-programming-01.md) | 디바이스 프로그래밍 개요, 개발환경, compile test |
| 2과 | [26-07-13](260713-arm-gcc-electronics-embedded-systems.md) | 능동 소자와 집적 회로 |
| 3과 | [26-07-13](260713-arm-gcc-electronics-embedded-systems.md) | 컴퓨터와 임베디드 시스템 |
| 4과 | [26-07-13](260713-arm-gcc-electronics-embedded-systems.md) | STM32F411xE MCU와 실습보드 |
| 5과 | [26-07-14](260714-gpio-volatile-cmsis-bit-operations.md) | GPIO 출력 |
| 6과 | [26-07-14](260714-gpio-volatile-cmsis-bit-operations.md) | Type Qualifier와 `volatile` |
| 7과 | [26-07-14](260714-gpio-volatile-cmsis-bit-operations.md) | shift·bit mask, field write, bit 처리 macro, `BSRR`, macro 기반 LED toggle·driver |
| 8과 | [26-07-15](260715-led-driver-system-clock.md) | system clock 설정 |
| 9과 | [26-07-15](260715-led-driver-system-clock.md) | GPIO 입력 제어와 User Key |
| 10과 | [26-07-16](260716-arm-cortex-m4-device-programming.md) | UART와 RS232 통신 |
| 11과 | [26-07-20](260720-timer-control.md) | Timer 제어 |
| 12과 | [26-07-21](260721-interrupt-event-driven.md) | Interrupt·exception·event-driven firmware |
| 13~14과 | [26-07-22](260722-i2c-spi-interface.md) | I2C, SPI |
| 15과 | [26-07-23](260723-adc-sensor-interface.md) | ADC, sensor interface |

## 2~15과를 하나의 firmware로 연결하기

각 과의 이름은 달라도 MCU code가 hardware를 다루는 기본 구조는 같다. 2과의 전압·전류·소자가 실제 pin 전압을 만들고, 3~4과의 CPU·bus·address decoder가 그 소자를 제어하는 peripheral register까지 store를 전달한다. 5~15과는 그 공통 구조를 GPIO, clock, timer, serial bus, ADC에 각각 적용하는 과정이다.

```text
전원·저항·LED·switch·sensor
          |
          v
GPIO / ADC / I2C / SPI / UART peripheral 회로
          |
          v
memory-mapped register와 status flag
          |
          v
C의 mask·field write·volatile shared variable
          |
          v
main loop 또는 interrupt handler의 제품 동작
```

### 모든 peripheral을 읽는 공통 여섯 단계

| 단계 | 먼저 묻는 질문 | GPIO LED 예 | UART·Timer·ADC 예 |
| :---: | :--- | :--- | :--- |
| 1 | 회로에서 signal은 무엇이며 전기적 규칙은 무엇인가 | LED 전류 경로, push-pull 또는 open-drain | UART idle level, I2C pull-up, ADC 입력 범위 |
| 2 | 어느 pin·bus·clock에 연결되는가 | `PA5`, AHB1 GPIOA | `PA9/PA10`, APB USART1; `PA6`, ADC1 |
| 3 | peripheral clock gate는 어디인가 | `RCC->AHB1ENR` GPIOA enable | `APB1ENR`, `APB2ENR`의 해당 enable bit |
| 4 | pin과 peripheral mode를 무엇으로 설정하는가 | `MODER`, `OTYPER`, `ODR` | alternate function, analog mode, `CR`·`BRR`·`PSC` |
| 5 | data 또는 command를 어느 register에 쓰는가 | `ODR` 또는 `BSRR` | `DR`, `CNT`, `CCR`, `CR2.SWSTART` |
| 6 | 완료·오류·새 data를 어떻게 확인하고 처리하는가 | 입력 `IDR` read | `SR` flag polling 또는 NVIC → ISR |

이 여섯 단계를 거치지 않고 register bit만 외우면 board가 바뀌거나 peripheral이 바뀔 때 code의 이유를 잃기 쉽다. 반대로 signal·clock·pin·configuration·data·status의 순서로 읽으면 새 peripheral도 같은 틀에서 분석할 수 있음.

### 사실 확인의 우선순위

수업 자료는 이 과목의 범위·실습 순서·문제 맥락을 정하는 기준으로 사용한다. register 주소·bit 의미·전기적 제한·clock 조건·interrupt 동작처럼 hardware 사실을 확인하거나 교재 표현을 고칠 때에는 아래 공식 문서를 우선한다.

| 확인 대상 | 우선 문서 | 쓰는 이유 |
| :--- | :--- | :--- |
| Cortex-M4 core, SysTick, NVIC, exception | [Arm Cortex-M4 Devices Generic User Guide](https://developer.arm.com/documentation/dui0553/latest) | Arm core의 공통 programming model |
| STM32F411 peripheral register·clock·GPIO·I2C·SPI·ADC | [ST RM0383 Reference Manual](https://www.st.com/resource/en/reference_manual/dm00119316-stm32f411xce-advanced-armbased-32bit-mcus-stmicroelectronics.pdf) | 이 MCU의 register bit와 동작 순서 |
| pin, 최대 clock, electrical characteristics, alternate function | [ST DS10314 Datasheet](https://www.st.com/resource/en/datasheet/stm32f411ce.pdf) | 제품별 package·pin·전기 조건 |
| Cortex-M4를 탑재한 STM32의 core programming 세부 | [ST PM0214 Programming Manual](https://www.st.com/resource/en/programming_manual/pm0214-stm32-cortexm4-mcus-and-mpus-programming-manual-stmicroelectronics.pdf) | exception, debug, memory·core 사용 관점 |
| I2C electrical·frame·arbitration 규칙 | [NXP UM10204 I2C-bus specification](https://www.nxp.com/docs/en/user-guide/UM10204.pdf) | bus 공통 protocol과 timing 기준 |
| SC16IS752의 I2C/SPI command와 GPIO 기능 | [NXP SC16IS752/SC16IS762 datasheet](https://www.nxp.com/products/interfaces/ic-spi-i3c-interface-devices/bridges/dual-uart-with-ic-bus-spi-interface-64-bs-of-transmit-and-receive-fifos-irda-sir-built-in-support%3ASC16IS752_SC16IS762) | 외부 bridge IC의 interface mode·frame·register 규칙 |

교재 code가 이 문서의 reset value, register access type, flag clear sequence, clock/pin 제약과 충돌하면 공식 문서의 표현을 노트 본문에 반영한다. 예제 code의 style은 수업 흐름으로 남기되, 실제 board에서 안전한지 판단할 때는 reference manual과 datasheet를 최종 기준으로 삼음.

### 공식 PDF 그림·표 찾아보기

아래 page와 figure/table 번호는 이 과목에서 실제로 쓰는 STM32F411xC/xE 문서를 기준으로 한다. 회로·register·pin의 사실을 확인할 때 노트 설명과 함께 이 위치를 연다. `RM0383`은 register 동작, `DS10314`는 제품 pin·전기 특성의 기준이다.

| 과 | 확인할 내용 | 공식 PDF 위치 |
| :---: | :--- | :--- |
| 2 | LED를 포함한 외부 부품이 MCU pin 전압·전류 조건을 넘지 않는지 | `DS10314` §6 Electrical characteristics, pp. 57~124 |
| 3 | CPU·memory·bus·peripheral의 chip 안 배치 | `DS10314`, Figure 3 'STM32F411xC/xE block diagram', p. 16 |
| 4 | memory-mapped peripheral address 범위와 available pin | `DS10314`, Table 10 'register boundary addresses', pp. 54~56; Figure 3, p. 16 |
| 5 | GPIO input/output/AF/analog 경로와 pin configuration | `RM0383`, Figures 16~21, pp. 147~156; Table 26, p. 164 |
| 6 | SysTick, NVIC, EXTI의 core·event 구조 | `RM0383`, §10, pp. 202~212; Table 37 'Vector table', pp. 203~205 |
| 7 | `MODER`·`ODR`·`BSRR` bit 의미와 atomic set/reset | `RM0383`, §8.4.1~§8.4.11, pp. 158~164; Table 26, p. 164 |
| 8 | HSI/HSE/PLL→AHB/APB의 clock path | `RM0383`, Figure 12 'Clock tree', p. 94; §6.3 RCC registers, pp. 103~133 |
| 9 | floating/pull-up/pull-down, EXTI 연결 | `RM0383`, Figure 18, p. 153; Figures 29~30, pp. 206~208 |
| 10 | USART pin alternate function, frame·baud·status register | `DS10314`, Table 9 'Alternate function mapping', pp. 48~53; `RM0383`, §19, pp. 506~548 |
| 11 | SysTick clock source와 general-purpose timer counter·prescaler·update event | `RM0383`, §10.1, p. 202; §13, pp. 313~371; Figures 40~49, pp. 246~253 |
| 12 | exception vector, EXTI route, pending flag 처리 | `RM0383`, Table 37, pp. 203~205; Figures 29~30, pp. 206~208 |
| 13 | I2C controller state/register와 line timing | `RM0383`, §18, pp. 470~501; `DS10314`, Table 58 'I2C characteristics', pp. 106~108; `UM10204` I2C specification |
| 14 | SPI1 pin alternate function, SPI register·frame rule | `DS10314`, Table 9, pp. 48~53; `RM0383`, §20, pp. 555~581; SC16IS752 datasheet Figures 1~2, pp. 5~7 |
| 15 | ADC channel, conversion timing, data alignment, electrical accuracy | `RM0383`, Figures 31~38 and Tables 39~47, pp. 214~238; `DS10314`, Table 65, pp. 114~116 |

`Nucleo64_Schematic.pdf`와 `Extension_Board_Schematic.pdf`는 실제 board의 LED, key, connector, pull-up, external device 결선을 확인하는 회로도다. 이 두 문서는 해당 board의 실제 net을 읽을 때 사용하고, MCU peripheral의 register 사실은 위 ST 공식 reference manual을 우선한다.

핵심 연결은 `소자 → 논리 회로 → IC/ASIC/SoC → CPU/메모리/주변장치 → MCU → Memory-Mapped I/O → GPIO 레지스터 제어 → 통신/타이머/인터럽트/센서 제어` 순서다. 뒤쪽 C 코드는 결국 특정 peripheral register address에 정해진 bit pattern을 쓰거나, 상태 bit를 읽어 분기하는 동작으로 환원된다.

```text
[전자 소자]
  저항, 다이오드, 트랜지스터, FET
        |
        v
[논리 회로]
  NOT, AND, OR, NAND, NOR, XOR
        |
        v
[집적 회로]
  IC, ASIC, SoC
        |
        v
[컴퓨터 구조]
  CPU <-> Memory <-> Peripheral
        |
        v
[MCU]
  CPU + Flash + SRAM + GPIO/UART/Timer/ADC
        |
        v
[C 코드 제어]
  register address + bit mask + memory-mapped I/O
```
