# Cortex-M4 Firmware 전체 지도 - 1~15과

관련 노트:

- [ARM GCC·전자소자·컴퓨터·임베디드 시스템](260713-arm-gcc-electronics-embedded-systems.md)
- [GPIO·CMSIS·Bit 연산](260714-gpio-volatile-cmsis-bit-operations.md)
- [LED Driver·System Clock·Key](260715-led-driver-system-clock.md)
- [UART·Timer](260716-arm-cortex-m4-device-programming.md)
- [Timer 제어](260720-timer-control.md)
- [Startup·Interrupt·Event-Driven Firmware](260721-interrupt-event-driven.md)
- [13~14과 I2C·SPI](260722-i2c-spi-interface.md)
- [15과 ADC·sensor interface](260723-adc-sensor-interface.md)

## 한 줄 큰 그림

이 과정은 `NUCLEO-F411RE` 보드 위의 `STM32F411RET6` MCU를 C firmware로 제어하는 과정이다. C code가 MCU 안에 이미 들어 있는 GPIO, UART, timer, I2C, SPI, ADC hardware block의 register를 설정하고, pin·통신선·LED·sensor와 연결한다.

```text
Arm architecture
  └─ Cortex-M4 core IP
       └─ STM32F411RET6 MCU
            ├─ Cortex-M4 CPU + Flash + SRAM
            ├─ RCC + GPIO + USART + TIM + I2C + SPI + ADC
            └─ internal bus와 memory-mapped register
                 └─ NUCLEO-F411RE board
                      ├─ ST-LINK·USB·전원
                      ├─ PA5 User LED, PC13 User Key
                      └─ header를 통한 외부 LED·switch·sensor·통신 IC
```

그동안 했던 Basys3 FPGA의 Verilog/Vivado 실습처럼 CPU·UART·timer 회로 자체를 새로 합성하는 작업이 아닌, 이미 제조된 MCU hardware를 C code로 설정하고 사용한다.

## Firmware가 실제 동작하기까지

```text
C source
  → ARM GCC compile·assemble
  → object file·linker script
  → ELF / Flash image
  → ST-LINK가 internal Flash `0x08000000`에 기록
  → reset, BOOT0=0
  → `0x00000000` boot alias가 Flash vector table을 가리킴
  → `crt0.s`: stack 설정, `.data` copy, `.bss` clear
  → `Main()`
  → CMSIS struct pointer를 통한 MMIO register access
  → AHB/APB bus
  → STM32 peripheral hardware
  → physical pin·LED·button·UART·I2C·SPI·ADC signal
```

`Main()`이라는 이름은 C 언어가 특별 취급해서 정한 이름이 아니다. `crt0.s`가 `BL Main`으로 호출하도록 작성했기 때문에 firmware entry가 된다.

| image·runtime 영역 | 주된 내용 | 실행 중 위치 |
| :--- | :--- | :--- |
| vector table | initial MSP, reset·IRQ handler 주소 | Flash image 시작부 |
| `.text`, `.rodata` | instruction, 문자열, 상수 table | Flash |
| `.data` | 초기값이 있는 global·static state | Flash image → reset 뒤 SRAM copy |
| `.bss` | 초기값 없는 global·static state | SRAM zero clear |
| heap | `malloc()` 등 dynamic allocation | `.bss` 뒤 SRAM, 사용량만 위 방향으로 확장 |
| stack | call frame, local state, exception context | SRAM 상단 |

이 수업 template의 heap 시작점은 `__ZI_LIMIT__` 뒤를 8-byte align한 주소이며, `runtime.c`의 `_sbrk()`가 `malloc()` 요청에 따라 heap 끝을 이동시킨다. heap은 Flash image의 별도 section이 아니라 실행 중 사용하는 SRAM 영역이다. stack은 initial MSP `0x20020000`에서 낮은 주소 방향으로 자란다.

## 구조체 접근의 공통 문법

CMSIS device header는 peripheral register의 물리 주소와 offset을 C 구조체로 표현한다. 예를 들어 `RCC`, `GPIOA`, `USART2`, `TIM4`는 일반 변수로 새로 생성한 대상이 아니라, 각 hardware block의 base address를 해당 구조체 pointer로 cast한 이름이다.

```c
/* stm32f411xe.h의 개념적 형태 */
typedef struct {
    /* ... */
    __IO uint32_t AHB1ENR;  /* RCC base + 0x30 */
    /* ... */
    __IO uint32_t APB1ENR;  /* RCC base + 0x40 */
    __IO uint32_t APB2ENR;  /* RCC base + 0x44 */
} RCC_TypeDef;

#define RCC ((RCC_TypeDef *)RCC_BASE)

RCC->AHB1ENR
/* == (*RCC).AHB1ENR
 * == RCC base address + AHB1ENR member offset의 실제 register */
```

`__IO`는 software가 읽고 쓸 수 있으며 hardware가 비동기적으로 바꿀 수도 있는 MMIO register를 나타내는 `volatile` 계열 qualifier다. 따라서 compiler는 register read/write를 임의로 생략하거나 일반 RAM 값처럼 고정해 두면 안 된다.

| C 이름 | 구조체 type | 대표 member | 이 과정에서 맡는 역할 |
| :--- | :--- | :--- | :--- |
| `RCC` | `RCC_TypeDef` | `CR`, `PLLCFGR`, `CFGR`, `AHB1ENR`, `APB1ENR`, `APB2ENR` | clock source·bus clock·peripheral clock gate |
| `GPIOA`~`GPIOH` | `GPIO_TypeDef` | `MODER`, `OTYPER`, `PUPDR`, `IDR`, `ODR`, `AFR[]` | pin mode·전기 방식·입출력·alternate function |
| `USART1`, `USART2` | `USART_TypeDef` | `BRR`, `CR1`, `SR`, `DR` | baud rate·TX/RX enable·data/status |
| `TIM2`~`TIM4` | `TIM_TypeDef` | `CR1`, `PSC`, `ARR`, `EGR`, `SR`, `DIER`, `CCR3` | counter·period·update event·interrupt·PWM/output compare |
| `SysTick` | `SysTick_Type` | `CTRL`, `LOAD`, `VAL` | Cortex-M4 core timer |
| `SYSCFG`, `EXTI` | `SYSCFG_TypeDef`, `EXTI_TypeDef` | `EXTICR[]`, `FTSR`, `IMR`, `PR` | GPIO pin을 external interrupt line에 연결 |
| `I2C1` | `I2C_TypeDef` | `CR1`, `CR2`, `CCR`, `TRISE`, `SR1`, `SR2`, `DR` | open-drain serial bus state machine |
| `SPI1` | `SPI_TypeDef` | `CR1`, `CR2`, `SR`, `DR` | synchronous full-duplex serial transfer |
| `ADC1`, `ADC` | `ADC_TypeDef`, `ADC_Common_TypeDef` | `SMPR2`, `SQR1`, `SQR3`, `CR2`, `SR`, `DR`, `CCR` | analog sample·conversion·digital result |
| `NVIC`, `SCB` | CMSIS core type | CMSIS helper API, `ICSR`, `CPACR` | IRQ enable·pending·core system control |

`RCC`, `GPIO`, `USART`, `TIM`, `I2C`, `SPI`, `ADC`는 STM32F411 vendor peripheral이다. `SysTick`, `NVIC`, `SCB`는 Cortex-M4 core peripheral이므로 `core_cm4.h`에서 정의한다.

## 매크로 호출의 공통 문법

`macro.h`는 register의 주소나 구조체를 새로 정의하지 않는다. 이미 구조체 pointer로 얻은 `GPIOC->MODER`, `RCC->AHB1ENR`, `GPIOC->IDR` 같은 register lvalue에 bit·field update 식을 재사용하는 preprocessor helper다.

| macro | 핵심 연산 | register에서 하는 일 | 수업 연결 |
| :--- | :--- | :--- | :--- |
| `Macro_Set_Bit(dest, pos)` | `dest |= 1u << pos` | 한 bit를 `1`로 set | peripheral clock enable, LED on |
| `Macro_Clear_Bit(dest, pos)` | `dest &= ~(1u << pos)` | 한 bit를 `0`으로 clear | output type·enable bit 해제 |
| `Macro_Invert_Bit(dest, pos)` | `dest ^= 1u << pos` | 한 bit를 toggle | LED toggle |
| `Macro_Clear_Area(dest, bits, pos)` | `dest &= ~(bits << pos)` | 연속 field를 모두 `0`으로 clear | `MODER[2n+1:2n]` 준비 |
| `Macro_Set_Area(dest, bits, pos)` | `dest |= bits << pos` | field의 지정 bit를 set | 여러 enable bit 설정 |
| `Macro_Invert_Area(dest, bits, pos)` | `dest ^= bits << pos` | field의 지정 bit를 toggle | mask 범위 상태 반전 |
| `Macro_Write_Block(dest, bits, data, pos)` | clear 뒤 `data << pos` | 고정 폭 field에 새 값을 기록 | `MODER`, `PUPDR`, `AFR`, prescaler field |
| `Macro_Extract_Area(dest, bits, pos)` | `(dest >> pos) & bits` | field 값을 LSB 위치로 꺼냄 | `SWS`, status field 확인 |
| `Macro_Check_Bit_Set/Clear(dest, pos)` | shift·mask 후 `1/0` 판정 | 한 bit의 현재 상태 확인 | key input, status flag polling |

`bits`는 field 폭을 나타내는 mask다. 예를 들어 GPIO mode는 pin 하나당 2bit이므로 `0x3u`를 사용한다. `Macro_Write_Block()`은 `data`가 `bits` 폭 안에 들어간다는 전제에서 사용한다.

```c
/* PC13의 MODER[27:26]을 input 00으로 기록 */
Macro_Write_Block(GPIOC->MODER, 0x3u, 0x0u, 26);

/* 같은 field write를 풀어 쓴 형태 */
GPIOC->MODER = (GPIOC->MODER & ~(0x3u << 26)) | (0x0u << 26);
```

매크로 argument에는 `GPIOC->MODER`처럼 단순한 register lvalue를 넣는다. 이 macro들은 `dest`를 여러 번 평가하므로 `array[index++]`처럼 side effect가 있는 expression에는 사용하지 않는다.

## 모든 peripheral code에 반복되는 여섯 단계

```text
1. peripheral이 연결된 AHB/APB clock gate를 RCC에서 enable
2. 필요한 GPIO pin을 input/output/analog/alternate function으로 설정
3. peripheral의 mode·clock·format·period 등 설정값 기록
4. 이전 status/pending flag를 clear
5. peripheral start 또는 interrupt enable
6. polling으로 status 확인하거나 ISR에서 event를 받아 main loop가 처리
```

| 공통 질문 | code에서 찾는 위치 |
| :--- | :--- |
| 이 block의 clock은 어디서 켜는가 | `RCC->AHB1ENR`, `APB1ENR`, `APB2ENR` |
| 이 pin은 누가 쓰는가 | `GPIOx->MODER`, `GPIOx->AFR[]` |
| 어떤 전기 방식인가 | `GPIOx->OTYPER`, `PUPDR`, `OSPEEDR` |
| data 또는 설정값은 어디에 쓰는가 | `DR`, `ODR`, `ARR`, `BRR`, `CCR`, `SQR` |
| hardware가 준비·완료를 어디에 알리는가 | `SR`, `IDR`, `PR`, `COUNTFLAG` |
| 완료 뒤 CPU가 무엇을 하는가 | polling loop 또는 `*_IRQHandler()` → `volatile` event flag |

## 과목 흐름: 1~15과

### 1~4과: firmware가 hardware에 닿는 기반

| 과 | 핵심 질문 | 확보할 모델 | 다음 과 연결 |
| :---: | :--- | :--- | :--- |
| 1 | PC에서 작성한 C가 STM32에서 어떻게 실행되는가 | cross compiler, assembler, linker, Flash image | startup·debug·build 오류 해석 |
| 2 | MCU pin과 LED 뒤에는 어떤 전기 회로가 있는가 | passive/active component, diode, BJT, MOSFET, CMOS, IC | GPIO high/low·push-pull·open-drain |
| 3 | CPU·memory·bus·register는 무엇을 맡는가 | fetch/decode/execute, ALU, register, address decoder, peripheral | MMIO와 bus access |
| 4 | reset 직후 어디서 code가 시작되는가 | Cortex-M memory map, Flash/SRAM, BOOT0 alias, vector table, linker/startup | `crt0.s`, `.lds`, `Main()` |

1~4과의 핵심은 '`C가 실행된다`'를 아래처럼 구체화하는 것이다.

```text
C expression
→ ARM instruction
→ Cortex-M4 bus transaction
→ address decoder
→ Flash / SRAM / peripheral register
→ hardware state 변화 또는 hardware state read
```

### 5~7과: GPIO와 register를 안전하게 다루는 최소 문법

| 과 | hardware 대상 | 주된 register·C 개념 | 실습 결과 |
| :---: | :--- | :--- | :--- |
| 5 | GPIO pin, LED, switch | `MODER`, `OTYPER`, `PUPDR`, `IDR`, `ODR` | PA5 LED on/off, input level read |
| 6 | MMIO register와 compiler | `volatile`, `const`, pointer, CMSIS header, `struct` | hardware register를 C type으로 접근 |
| 7 | 32bit register의 bit field | `<<`, `&`, `|`,`^`,`&= ~`, field write,`BSRR` | 다른 pin 설정을 보존하며 PA5 field 변경 |

GPIO의 pin 하나는 다음 네 경로 중 하나로 사용한다.

```text
input              : external voltage → input buffer → `IDR`
general output     : `ODR`/`BSRR` → output driver → physical pin
alternate function : UART/timer/SPI/I2C hardware → pin mux → physical pin
analog             : pin voltage → ADC analog path
```

`MODER`는 pin의 주인을 고르고, `PUPDR`는 외부가 pin을 구동하지 않을 때 기본 level을 정한다. `OTYPER`는 output일 때 push-pull 또는 open-drain 전기 방식을 정한다.

#### GPIO pin mode와 전기 상태

| `MODER` 값 | pin의 주인·경로 | 대표 사용 |
| :---: | :--- | :--- |
| `00` input | physical pin → digital input buffer → `IDR` | button, digital sensor |
| `01` general-purpose output | `ODR`/`BSRR` → GPIO output driver → pin | LED, enable signal |
| `10` alternate function | UART·timer·SPI·I2C peripheral → pin mux → pin | UART TX/RX, PWM, I2C |
| `11` analog | physical pin → analog path → ADC | analog sensor voltage sample |

`analog` mode는 general-purpose analog input/output mode가 아니다. STM32F411에서는 ADC input path에 사용하며, DAC peripheral이 없으므로 임의의 analog voltage를 직접 출력하는 기능은 제공하지 않는다. PWM은 high/low pulse를 만드는 digital output이다.

| output driver 방식 | logical `0` | logical `1` | 주된 용도 |
| :--- | :--- | :--- | :--- |
| push-pull | GPIO가 GND로 직접 구동 | GPIO가 3.3 V로 직접 구동 | LED, chip select, 일반 digital output |
| open-drain | GPIO가 GND로 직접 구동 | GPIO가 `High-Z`로 release, pull-up이 high 형성 | I2C shared bus |

`open-drain`은 output driver 방식이다. input mode에서는 output driver가 꺼져 있으므로 `OTYPER` 설정이 pin을 구동하지 않는다. alternate function I2C에서는 I2C peripheral이 output driver를 제어하고, 그 electrical type은 open-drain이다.

| 용어 | 정확한 의미 |
| :--- | :--- |
| 3-state output | `0`, `1`, `Z`를 낼 수 있는 output driver 구조 |
| High-Impedance / High-Z | GPIO driver가 high·low 어느 쪽도 적극적으로 구동하지 않는 `Z` 상태 |
| floating | pull-up/down·다른 driver가 없어 line voltage가 정해지지 않은 net 상태 |
| pull-up / pull-down | external driver가 없을 때 line을 약하게 high / low로 bias하는 저항 |

따라서 `High-Z`는 GPIO driver의 상태이고, floating은 line의 전압 상태다. `High-Z + pull-up`은 안정된 high이며 floating이 아니다.

```c
/* PA5의 2bit MODER field를 output `01`로 쓰는 일반식 */
GPIOA->MODER = (GPIOA->MODER & ~(0x3u << 10)) | (0x1u << 10);
```

이 식은 `PA5`의 두 bit `MODER[11:10]`만 먼저 `00`으로 clear하고, 원하는 값 `01`만 넣는다. 다른 pin의 mode bit는 유지한다.

### 8과: system clock을 peripheral time으로 나누기

| 항목 | 역할 |
| :--- | :--- |
| HSI | STM32 내부 RC oscillator, 기본 16 MHz source |
| HSE | external high-speed clock input 경로, X-TAL 또는 ST-LINK MCO source |
| PLL | 입력 clock을 `PLLM`, `PLLN`, `PLLP`, `PLLQ`로 변환·분주 |
| SYSCLK | CPU와 system clock tree의 source |
| HCLK | AHB bus clock |
| PCLK1, PCLK2 | APB1·APB2 peripheral clock |
| Flash `ACR` | 높은 HCLK에서 Flash read latency·cache·prefetch 설정 |

수업의 대표 설정은 다음 clock tree다.

```text
HSI 16 MHz
  → PLLM = 8
  → PLLN = 192
  → VCO = 384 MHz
  ├─ PLLP = 4 → SYSCLK/HCLK = 96 MHz
  └─ PLLQ = 8 → USB/SDIO = 48 MHz

HCLK 96 MHz
  ├─ APB2 /1 → PCLK2 = 96 MHz
  └─ APB1 /2 → PCLK1 = 48 MHz
```

`RCC->PLLCFGR`는 PLL 계산값을 설정하고, `RCC->CFGR`는 PLLP output을 SYSCLK source로 선택하며 AHB/APB prescaler를 나눈다. `RCC->AHB1ENR`, `APB1ENR`, `APB2ENR`는 각 peripheral에 clock을 실제로 공급하는 gate다.

### 9과: GPIO input과 key driver

| code 흐름 | 핵심 의미 |
| :--- | :--- |
| `RCC->AHB1ENR`에서 GPIOC enable | PC13 또는 외부 PC7 port clock 공급 |
| `GPIOC->MODER`를 input으로 설정 | pin을 input buffer 경로로 연결 |
| `GPIOC->PUPDR` pull-up | release 상태 high, switch가 GND로 당기면 low |
| `GPIOC->IDR` read | 실제 pin level 확인 |
| `GPIOA->ODR` write | 읽은 key 상태에 따라 PA5 LED 변경 |

Nucleo User Key `PC13`은 active-low다. 즉 눌린 상태가 `0`이며, `Macro_Check_Bit_Clear(GPIOC->IDR, 13)`이 pressed 판단이 된다.

`0902.KEY_DRIVER_LAB/key.c`는 raw register access를 아래 API로 감싼다. main loop는 key의 electrical level 대신 '`눌렸는가`'라는 의미를 다룬다.

| key driver API | 내부 register·macro 동작 | application이 얻는 의미 |
| :--- | :--- | :--- |
| `Key_Poll_Init()` | GPIOC clock enable, `MODER[27:26] = 00` | PC13 input 준비 |
| `Key_Get_Pressed()` | `Macro_Check_Bit_Clear(GPIOC->IDR, 13)` | 눌렸으면 `1`, release면 `0` |
| `Key_Wait_Key_Pressed()` | IDR bit 13이 `0`이 될 때까지 polling | press event 대기 |
| `Key_Wait_Key_Released()` | IDR bit 13이 `1`이 될 때까지 polling | release event 대기 |

#### key bit 검사와 active-low 의미

`Macro_Check_Bit_Clear()`의 `clear`는 return value가 아니라 검사 대상 bit의 상태를 뜻한다. macro는 조건이 참이면 `1`을 반환한다.

| PC13 실제 level | `Macro_Check_Bit_Set(GPIOC->IDR, 13)` | `Macro_Check_Bit_Clear(GPIOC->IDR, 13)` | key 의미 |
| :---: | :---: | :---: | :--- |
| `1` | `1` | `0` | release |
| `0` | `0` | `1` | pressed, active-low |

#### polling, level, edge, interlock

polling은 CPU가 loop에서 `IDR` 같은 status register를 반복 read하는 event 확인 방식이다. level과 edge는 읽어 온 input을 해석하는 방식이다.

| polling 해석 | 판정 기준 | 사용 예 |
| :--- | :--- | :--- |
| level-based | 현재 key가 pressed `0`인가 | 누르는 동안 cursor 이동, motor enable 유지 |
| edge-based | 이전 상태와 현재 상태가 `1 → 0`으로 바뀌었는가 | button 한 번당 menu 선택·LED toggle |
| interlock | press 뒤 lock, release 뒤 unlock | polling으로 한 번 누름당 한 번 처리 |

`Key_Wait_Key_Pressed()`와 `Key_Wait_Key_Released()`처럼 `while`로 condition을 기다리면 blocking polling이다. interlock은 매 loop에서 상태만 짧게 검사하므로 UART·timer·sensor 같은 다른 작업을 계속 수행하는 non-blocking polling으로 만들 수 있다.

```c
/* active-low PC13: press에서 한 번 toggle, release에서 다음 press 허용 */
if ((lock == 0) && Macro_Check_Bit_Clear(GPIOC->IDR, 13)) {
    Macro_Invert_Bit(GPIOA->ODR, 5);
    lock = 1;
} else if ((lock == 1) && Macro_Check_Bit_Set(GPIOC->IDR, 13)) {
    lock = 0;
}
```

`lock`을 clear하는 조건은 release인 `PC13=1`이다. 계속 누르고 있는 stable `0`은 lock 상태를 유지하므로 LED가 여러 번 toggle되지 않는다.

#### interlock과 debounce의 역할 분리

| 문제 | 원인 | 대응 |
| :--- | :--- | :--- |
| 누르는 동안 여러 번 실행 | CPU가 stable pressed level을 여러 loop에서 반복 read | edge detect 또는 interlock |
| 한 번 눌렀는데 여러 press처럼 보임 | mechanical switch contact의 짧은 `0 ↔ 1` 흔들림, chattering | debounce |

debounce는 input level이 일정 시간 유지된 뒤에만 실제 press/release로 인정하는 처리다. 9과에서는 interlock으로 `'hold 중 중복 실행'`을 먼저 구분하고, debounce의 시간 기준은 이후 timer와 연결해 확장한다.

### 10과: UART와 polling serial I/O

UART는 별도 clock line 없이 TX/RX의 bit timing을 약속해 문자를 보내는 asynchronous serial peripheral이다. UART hardware는 pin waveform과 frame을 처리하고, firmware는 baud rate·enable·data register·status flag를 다룬다.

`PA2`, `D1`, `USART2_TX`, `AF7`, ST-LINK Virtual COM처럼 같은 signal path에 붙는 이름과 board route의 범용 해석은 [[domains/semiconductor/ai-npu-system-integration/mcu-pin-board-header-peripheral-signal-map]]에 정리한다.

| USART2 | USART1 |
| :--- | :--- |
| `PA2` TX, `PA3` RX, `AF7` | `PA9` TX, `PA10` RX, `AF7` |
| `RCC->APB1ENR` bit 17 | `RCC->APB2ENR` bit 4 |
| `PCLK1 = 48 MHz` | `PCLK2 = 96 MHz` |

```text
GPIO alternate function 설정
→ `USARTx->BRR`에 baud divider 기록
→ `CR1`: UE·TE·RE enable, 8bit·no parity
→ `CR2`: 1 stop bit
→ TX: `SR.TXE` set 대기 → `DR` write
→ RX: `SR.RXNE` set 대기 → `DR` read
```

`BRR`은 peripheral clock과 목표 baud rate의 관계를 mantissa·fraction field로 기록한다. `DR`은 byte를 주고받는 register이며, `SR`은 지금 송신 buffer가 비었는지 또는 수신 byte가 도착했는지 알려 준다.

### 11과: timer를 시간·주기 event·pin waveform으로 확장

11과는 같은 'clock을 세는 hardware counter'를 세 가지로 쓰는 과정이다. 먼저 SysTick과 TIMx로 시간을 재고, TIMx timeout을 반복 event로 쓰며, 마지막에는 counter와 compare channel을 연결해 GPIO pin에서 정밀한 waveform을 만든다.

```text
Cortex-M4 core clock
└─ SysTick: core 안의 기본 timer
   └─ LOAD → VAL down count → COUNTFLAG

STM32 APB timer clock
└─ TIMx: STM32 peripheral timer
   └─ PSC → CNT ↔ ARR → update event → SR.UIF
                      │
                      └─ CNT == CCRn → channel output → GPIO alternate function → buzzer
```

| 흐름 단계 | 수업이 답하는 질문 | 핵심 hardware·register | 실습 결과 |
| :--- | :--- | :--- | :--- |
| 1. SysTick | Cortex-M4 core만으로 일정 시간을 어떻게 재는가 | `SysTick->LOAD`, `VAL`, `CTRL.COUNTFLAG` | timeout polling·경과 count 확인 |
| 2. TIMx time-base | STM32 timer의 tick과 한 주기를 어떻게 정하는가 | `RCC->APB1ENR`, `CR1`, `PSC`, `ARR`, `CNT` | TIM2·TIM4가 일정 속도로 count |
| 3. update event | 새 설정을 언제 적용하고 timeout을 어떻게 아는가 | `EGR.UG`, `SR.UIF` | manual update, timeout flag polling |
| 4. one-shot·repeat | 한 번 기다릴지, 주기 event를 계속 만들지 | `CR1.OPM`, `CR1.CEN`, `CR1.DIR` | TIM2 delay·TIM4 repeat |
| 5. channel·compare | 같은 counter로 pin 상태를 언제 바꿀지 | `CCRn`, `CCMRx`, `CCER` | compare·PWM output |
| 6. timer output 활용 | 원하는 주파수와 duty를 외부 장치에 어떻게 낼지 | `TIM3_CH3`, `PB0 AF2`, `PSC`, `ARR`, `CCR3` | buzzer 음계 재생 |

#### 1. SysTick과 TIMx의 역할 분리

| 구분 | SysTick | TIM2·TIM3·TIM4 같은 TIMx |
| :--- | :--- | :--- |
| 소속 | Cortex-M4 core 안의 system timer | STM32가 Cortex-M4 주변에 붙인 peripheral timer |
| clock 준비 | core에 이미 포함됨 | 먼저 RCC에서 해당 timer clock을 enable |
| 현재 수업의 쓰임 | timeout·기준 시간·간단한 polling | stopwatch, delay, repeat event, PWM·buzzer |
| 확장성 | RTOS tick·system timeout | channel, capture, compare, PWM, timer-to-timer 연동 |

수업의 `SysTick_Run()`은 `LOAD`에 시간에 맞는 reload 값을 쓰고 `VAL`을 초기화한 뒤 시작한다. 현재 실습은 `HCLK / 8`을 SysTick source로 선택하고 `COUNTFLAG`를 polling한다.

TIMx는 먼저 `RCC->APB1ENR`에서 clock gate를 연다. 이것은 'timer가 clock을 받을 수 있게 함'이며, 실제 counter 시작은 별도로 `CR1.CEN = 1`을 써서 한다. 현재 board clock 설정에서는 `PCLK1 = 48 MHz`, APB1 prescaler가 `2`이므로 TIM2·TIM3·TIM4의 timer input clock은 `96 MHz`다.

#### 2. TIMx time-base: tick 하나와 주기 하나를 정하는 구조

```text
TIMx input clock
→ PSC: (PSC + 1)분주
→ CNT: 매 tick마다 up 또는 down count
→ ARR: 한 period의 끝·reload 기준
→ update event
→ SR.UIF: '이번 timeout을 아직 firmware가 처리하지 않았다'는 상태
```

| register·bit | 첫 역할 |
| :--- | :--- |
| `CR1.DIR` | `0`은 up count, `1`은 down count |
| `CR1.OPM` | `1`은 one-shot, `0`은 repeat |
| `CR1.CEN` | counter start·stop |
| `PSC` | input clock을 `PSC + 1`로 나눠 timer tick을 결정 |
| `ARR` | auto-reload 값. 한 period의 count 길이 기준 |
| `CNT` | 지금 counter가 세고 있는 값 |
| `CR1.ARPE` | `ARR` preload 적용 방식을 고른다. 현재 기본 실습은 `0`으로 둔다. |
| `EGR.UG` | software가 update event를 강제로 발생시켜 counter를 reload하고 preloaded state를 반영 |
| `SR.UIF` | update event·timeout 발생 flag. firmware가 `0`을 써서 clear |

```text
f_tick   = f_TIM / (PSC + 1)
T_period = (ARR + 1) / f_tick
         = (PSC + 1) × (ARR + 1) / f_TIM
```

`PSC = N`은 `N + 1`분주이고, `ARR = N`은 `N + 1`개의 count를 뜻한다. 예를 들어 down counter에서 `ARR = 5`이면 `5 → 4 → 3 → 2 → 1 → 0`을 지나므로 여섯 tick 뒤 timeout이 난다.

#### 3. update event와 timeout flag: 설정 적용과 event 처리는 별개

```text
PSC·ARR·mode 설정
→ EGR.UG: 지금 software가 update event를 요청
→ SR.UIF clear: 이전 timeout 흔적 제거
→ CEN set: counter 시작
→ hardware timeout: update event·UIF set
→ firmware가 UIF 확인·clear
```

`EGR`은 command용 event generation register이고, `UG`는 update generation bit다. `UG = 1`은 manual update event를 요청한다. `SR.UIF`는 'timeout이 발생했다'는 status다. interrupt를 아직 쓰지 않아도 polling에서 그대로 사용한다.

새 delay나 repeat timer를 시작하기 전에 `UIF`를 clear하는 이유는 이전 event가 남아 있으면 새 timer가 끝나기도 전에 timeout으로 잘못 판단하기 때문이다. `CEN`을 clear해 counter를 멈추는 일과 `UIF`를 clear해 과거 event를 소비하는 일은 서로 다른 동작이다.

#### 4. TIM2와 TIM4: 같은 time-base의 서로 다른 firmware 사용법

| 실습 | timer mode·firmware 흐름 | 결과 |
| :--- | :--- | :--- |
| TIM2 stopwatch | down count·one-shot으로 `ARR = 0xFFFF`에서 시작 → stop 때 `CNT` read | `(0xFFFF - CNT) × tick`으로 경과 시간 계산 |
| TIM2 delay | `PSC`·`ARR` 설정 → `UG` → `UIF` clear → start → `while (UIF == 0)` | 정확한 기간 동안 main loop가 멈추는 blocking delay |
| TIM4 repeat | repeat mode로 start → timeout마다 hardware reload → main loop가 `UIF`을 확인·clear | 다른 loop 작업과 섞을 수 있는 periodic polling event |
| TIM4 period 변경 | 실행 중 `ARR` 변경 → preload를 쓰면 update boundary에서 다음 period에 반영 | timer를 매번 stop·start하지 않고 다음 주기 변경 |

현재 code는 TIM2·TIM4의 tick을 `50 kHz`, 즉 `20 µs`로 만든다. `TIM2_Delay()`는 busy-wait이므로 timeout까지 다른 일을 하지 못한다. `TIM4_Check_Timeout()`은 한 번만 flag를 확인하고 return하므로 main loop가 UART·key·LED 같은 다른 일을 계속 확인할 수 있다.

`ARR`의 새 값이 정확히 언제 active counter에 반영되는지는 `CR1.ARPE`에 따라 달라진다. 수업의 기본 TIM2·TIM4 source는 `ARPE = 0`을 사용한다. 주기 중간의 변화 없이 다음 period부터 안전하게 값을 바꾸는 설계는 preload를 enable하고 update event 경계에서 반영하는 방식으로 확장한다.

#### 5. channel·compare·PWM: counter를 pin waveform으로 바꾸기

TIMx 하나는 `PSC`·`ARR`·`CNT`로 만든 공통 time-base를 공유한다. 채널마다 `CCR1`~`CCR4`를 두고, counter가 그 compare 값에 도달했을 때 input을 기록하거나 output 상태를 바꾼다.

| 기능 | hardware가 하는 일 | 지금 수업에서의 위치 |
| :--- | :--- | :--- |
| capture | 외부 edge 순간의 `CNT`를 저장 | channel 구조의 확장 항목 |
| output compare | `CNT == CCRn`에서 event 또는 pin 상태 변화 | PWM을 이해하는 기반 |
| PWM | 한 period 안에서 compare 위치로 high·low 폭 생성 | TIM3 buzzer output |

```text
ARR  : 한 waveform period의 길이
CCRn : 그 period 안에서 출력 상태가 바뀌는 위치

f_output ≈ f_TIM / ((PSC + 1) × (ARR + 1))
duty     ≈ CCRn / (ARR + 1)
```

`ARR`을 바꾸면 output frequency가 바뀌고, `ARR`을 유지한 채 `CCRn`을 바꾸면 duty가 바뀐다. timer hardware가 `CNT`와 `CCRn`을 비교하고 pin을 전환하므로, C code가 매 edge마다 GPIO register를 쓰지 않아도 일정한 waveform이 나온다.

channel output을 실제 pin으로 보내려면 다음 네 층을 모두 설정한다.

```text
GPIO MODER = alternate
→ GPIO AFR = 해당 timer channel의 AF 번호
→ TIMx CCMRx = output compare·PWM mode
→ TIMx CCER = channel output enable·polarity
→ TIMx CCRn = compare 위치
```

#### 6. TIM3_CH3·PB0 부저: 수업의 최종 연결 예

```text
APB1 timer clock 96 MHz
→ TIM3 PSC = 11
→ timer tick = 8 MHz
→ ARR: 원하는 음 높이의 period
→ CCR3: 약 50% duty 위치
→ TIM3_CH3
→ PB0, GPIO alternate function AF2
→ passive buzzer
```

`TIM3_Out_Init()`은 GPIOB와 TIM3 clock을 enable하고, `PB0`을 alternate function `AF2`로 연결한 뒤 channel 3 output을 enable한다. `TIM3_Out_Freq_Generation(freq)`은 `PSC = 11`로 `96 MHz / 12 = 8 MHz`의 timer tick을 만들고, `ARR ≈ 8 MHz / freq - 1`로 음 높이를 정한다. `CCR3`를 `ARR`의 절반 근처에 두어 약 50% duty square wave를 만든다.

따라서 부저 실습은 아래처럼 역할이 분리된다.

| 조절 대상 | 누가 결정하는가 | register·함수 |
| :--- | :--- | :--- |
| 음높이 | TIM3 output frequency | `PSC`, `ARR`, `TIM3_Out_Freq_Generation()` |
| 파형의 high 비율 | TIM3 compare point | `CCR3` |
| 음의 지속 시간 | TIM2 timeout | `TIM2_Delay()` |
| pin 전기 신호 | TIM3 channel hardware | `TIM3_CH3 → PB0 AF2` |

#### 7. 11과에서 잡을 범위와 12과으로 이어지는 지점

11과 1차 pass에서는 `RCC clock enable → PSC·ARR·CNT → UG·UIF → one-shot/repeat → CCR·channel → GPIO AF → buzzer` 경로를 읽을 수 있으면 된다. `CCMR2`의 모든 mode bit encoding, input capture filter, timer master/slave, DMA, advanced timer, preload의 세부 타이밍은 실제 필요 시 심화한다.

12과에서는 timer hardware를 바꾸지 않는다. 11과의 `SR.UIF`를 main loop가 polling하던 경로에 `DIER.UIE`와 NVIC를 더해 ISR가 timeout event를 받게 만든다.

```text
11과: hardware timeout → SR.UIF → main loop polling
12과: hardware timeout → SR.UIF → DIER.UIE·NVIC → TIMx_IRQHandler() → event flag
```

실제 source를 따라 읽을 때는 [1101.SYSTICK_TIMER_LAB](../helloEmbedded/1101.SYSTICK_TIMER_LAB/), [1102.TIMER_DRIVER_LAB](../helloEmbedded/1102.TIMER_DRIVER_LAB/), [1103.TIMER_OUTPUT_LAB](../helloEmbedded/1103.TIMER_OUTPUT_LAB/) 순서가 자연스럽다. register별 상세와 code 흐름은 [26-07-20 Timer 제어](260720-timer-control.md)에 이어서 정리한다.

### 12과: interrupt와 event-driven firmware

11과까지 main loop가 직접 확인하던 status flag를 12과에서는 NVIC와 ISR로 받는다. peripheral hardware 자체는 그대로이며, CPU가 완료 event를 받는 경로가 polling에서 interrupt로 바뀐다.

| event source | polling 방식 | interrupt 설정 | ISR이 남기는 state |
| :--- | :--- | :--- | :--- |
| PC13 key | `GPIOC->IDR` read | `SYSCFG->EXTICR[3]`, `EXTI->FTSR/IMR`, IRQ 40 | `Key_Pressed` |
| USART2 RX | `USART2->SR.RXNE` read | `USART2->CR1.RXNEIE`, IRQ 38 | `Uart_Data`, `Uart_Data_In` |
| TIM4 update | `TIM4->SR.UIF` read | `TIM4->DIER.UIE`, IRQ 30 | `TIM4_Expired` |

```text
peripheral event
→ peripheral pending/status flag
→ NVIC enable·priority 판단
→ vector table의 `*_IRQHandler()`
→ peripheral cause clear
→ `volatile` event flag 또는 짧은 data 기록
→ return
→ main loop가 긴 application 처리
```

ISR은 `printf`, 긴 delay, 복잡한 allocation 같은 오래 걸리는 처리를 넣지 않는다. handler는 원인을 clear하고 필요한 data 또는 event flag만 남긴 뒤 return한다. main loop가 flag를 소비한 뒤 `0`으로 clear한다.

### 13과: I2C open-drain shared bus

I2C는 `SCL`과 `SDA` 두 선을 여러 device가 공유하는 synchronous serial bus다. high는 pull-up resistor가 만들고, device는 low만 능동적으로 만든다. 이 open-drain 구조가 wired-AND, ACK/NACK, clock stretching, multi-controller arbitration의 전기적 기반이다.

| 연결·설정 | 수업 실습 |
| :--- | :--- |
| pins | `PB6=I2C1_SCL`, `PB7=I2C1_SDA`, `AF4` |
| GPIO electrical mode | alternate function, open-drain, pull-up, fast speed |
| peripheral clock | `RCC->APB1ENR` I2C1 bit 21 |
| timing registers | `I2C1->CR2`, `CCR`, `TRISE` |
| transaction state | `CR1.START/STOP`, `SR1.SB/ADDR/TXE/BTF/RXNE`, `SR2.BUSY` |
| target | `SC16IS752` GPIO register control |

```text
idle 확인
→ START
→ slave address + W
→ ADDR 확인·정해진 read sequence로 clear
→ register address write
→ data write
→ BTF 확인
→ STOP
```

I2C의 `while`은 단순 지연이 아니다. bus state machine이 다음 protocol 단계로 이동했는지 기다리는 code다. `ADDR` 같은 flag는 reference manual이 요구하는 정확한 read/write sequence로 clear해야 한다.

### 14과: SPI full-duplex transfer와 chip select

SPI는 controller와 target이 `SCK`, `MOSI`, `MISO`, `CS`를 사용해 동시에 shift하는 synchronous serial bus다. I2C와 달리 data direction을 분리하므로 full-duplex 전송이 기본이다.

| 연결·설정 | 수업 실습 |
| :--- | :--- |
| pins | `PB3=SCK`, `PB4=MISO`, `PB5=MOSI`, `AF5` |
| chip select | `PA8` general-purpose push-pull output |
| peripheral clock | `RCC->APB2ENR` SPI1 bit 12 |
| key registers | `SPI1->CR1`, `CR2`, `SR`, `DR` |
| mode | `CPOL`, `CPHA`, `BR`, `MSTR`, `DFF`, `SPE` |
| target | `SC16IS752` GPIO register control |

```text
CS high: target not selected
→ CS low: transaction frame 시작
→ `SPI1->DR` write: SCK 8/16회와 MOSI/MISO shift 동시 진행
→ `SR.RXNE` 처리·`SR.BSY` clear 확인
→ CS high: transaction frame 종료
```

SPI에서 command byte만 쓰는 것처럼 보여도 MISO 쪽에서도 byte가 들어온다. 따라서 receive side의 `RXNE` 처리와 overrun 방지를 함께 고려한다. `CS`는 단순 enable이 아니라 command/address/data를 하나의 transaction으로 묶는 frame boundary다.

### 15과: ADC와 analog sensor input

ADC는 연속적인 pin voltage를 일정한 sample time에 읽어 digital code로 바꾸는 peripheral이다. GPIO는 digital `0/1` 판단을 하지만 ADC는 reference voltage 범위 안의 여러 level을 수치로 표현한다.

| 설정 | 수업 실습 |
| :--- | :--- |
| input pin | `PA6 = ADC1_IN6`, `GPIOA->MODER` analog mode |
| peripheral clock | `RCC->APB2ENR` ADC1 bit 8 |
| sample time | `ADC1->SMPR2` channel 6 field |
| conversion sequence | `ADC1->SQR1`, `SQR3` |
| ADC clock | `ADC->CCR` common prescaler |
| start/status/data | `ADC1->CR2.SWSTART`, `SR.EOC`, `DR[11:0]` |

```text
sensor or potentiometer voltage
→ PA6 analog path
→ ADC sample-and-convert
→ `SR.EOC` set
→ `ADC1->DR` 12bit value read
→ voltage·physical quantity로 환산
```

ADC code는 단순한 '`sensor 값`'이 아니라 reference voltage에 대한 sample 결과다. 예를 들어 12bit ADC의 ideal range는 `0`~`4095`이며, 전압 환산은 `V = code / 4095 × Vref` 형태로 시작한다. 실제 측정에서는 sensor 회로, Vref, noise, sample time도 함께 본다.

## Polling과 interrupt를 하나의 관점으로 보기

| 항목 | polling | interrupt/event-driven |
| :--- | :--- | :--- |
| CPU의 질문 | '지금 준비됐나?'를 반복 | hardware가 준비될 때 CPU에 알림 |
| code 위치 | main loop의 `while`·`if` | peripheral enable + NVIC + `*_IRQHandler()` |
| 장점 | 흐름이 단순, 첫 driver 학습에 적합 | CPU가 다른 일 수행 가능, event 반응 구조 |
| 주의점 | busy-wait 동안 다른 작업 지연 | ISR은 짧게, shared state는 `volatile`·동기화 고려 |
| 수업 예 | `SR.TXE`, `SR.RXNE`, `SR.UIF`, `IDR` | EXTI13, USART2 RX, TIM4 update |

`volatile`은 ISR이나 hardware가 바꾼 값을 compiler가 매번 memory에서 다시 읽도록 한다. 여러 byte state를 안전하게 갱신하거나 여러 event를 빠짐없이 보존하는 문제는 별도의 critical section, atomic operation, counter, queue 설계가 필요하다.

## `main.c`와 driver file을 함께 읽는 법

| file | 역할 |
| :--- | :--- |
| `main.c` | 제품 동작 흐름, driver API 호출, main loop |
| `clock.c` | HSI/HSE·PLL·bus prescaler 설정 |
| `led.c`, `key.c` | GPIO 기반 LED·button driver |
| `uart.c` | UART initialization, TX/RX polling·RX IRQ enable |
| `systick.c`, `timer.c` | time base, delay, periodic event, PWM/output |
| `i2c.c`, `spi.c`, `adc.c` | bus·conversion peripheral driver |
| `exception.c` | vector table이 호출하는 ISR |
| `device_driver.h` | driver function declaration과 shared interface |
| `crt0.s` | vector table, reset entry, C runtime 초기화 |
| `rom_0x08000000.lds` | Flash/SRAM section 배치 |
| `macro.h` | bit set/clear/write/extract helper |

source를 읽을 때는 `main.c`만 처음부터 끝까지 읽지 않는다. 먼저 main의 API 호출 하나를 잡고, 해당 driver 함수로 내려가며 다음 순서를 따른다.

```text
application intent
→ driver API
→ RCC clock gate
→ GPIO mode/AF·peripheral register 설정
→ status/pending flag
→ physical signal 또는 external device 결과
```

## 현재 code source 지도

| 범위 | lab source | 먼저 볼 file |
| :--- | :--- | :--- |
| GPIO output | [0501.LED_ON_LAB](../helloEmbedded/0501.LED_ON_LAB/) | `main.c`, `macro.h` |
| qualifier·CMSIS | [0601.TYPE_QUALIFIER_EX](../helloEmbedded/0601.TYPE_QUALIFIER_EX/) · [0602.CMSIS_LAB](../helloEmbedded/0602.CMSIS_LAB/) | `main.c`, `stm32f411xe.h`, `core_cm4.h` |
| bit operation·LED driver | [0701.BIT_OP_LAB](../helloEmbedded/0701.BIT_OP_LAB/) · [0702.LED_DRIVER_LAB](../helloEmbedded/0702.LED_DRIVER_LAB/) | `macro.h`, `led.c` |
| clock | [0801.CLOCK_CONFIG_EX](../helloEmbedded/0801.CLOCK_CONFIG_EX/) | `clock.c`, `main.c` |
| key input | [0901.KEY_IN_LAB](../helloEmbedded/0901.KEY_IN_LAB/) · [0902.KEY_DRIVER_LAB](../helloEmbedded/0902.KEY_DRIVER_LAB/) | `main.c`, `key.c` |
| UART | [1001.UART_LOCAL ECHOBACK_LAB](../helloEmbedded/1001.UART_LOCAL%20ECHOBACK_LAB/) | `uart.c`, `main.c` |
| timer·buzzer | [1101.SYSTICK_TIMER_LAB](../helloEmbedded/1101.SYSTICK_TIMER_LAB/) · [1102.TIMER_DRIVER_LAB](../helloEmbedded/1102.TIMER_DRIVER_LAB/) · [1103.TIMER_OUTPUT_LAB](../helloEmbedded/1103.TIMER_OUTPUT_LAB/) | `systick.c`, `timer.c`, `main.c` |
| interrupt·event | [1201.EXTI_IRQ_LAB](../helloEmbedded/1201.EXTI_IRQ_LAB/) · [1202.EXTI_EVENT_EX](../helloEmbedded/1202.EXTI_EVENT_EX/) · [1203.UART_EVENT_LAB](../helloEmbedded/1203.UART_EVENT_LAB/) · [1204.TIMER_EVENT_LAB](../helloEmbedded/1204.TIMER_EVENT_LAB/) | `key.c`, `uart.c`, `timer.c`, `exception.c` |
| I2C | [1301.I2C_IF_EX](../helloEmbedded/1301.I2C_IF_EX/) | `i2c.c`, `main.c` |
| SPI | [1401.SPI_IF_EX](../helloEmbedded/1401.SPI_IF_EX/) | `spi.c`, `main.c` |
| ADC | [1501.ADC_EX](../helloEmbedded/1501.ADC_EX/) | `adc.c`, `main.c` |

## 9~12과 code-first 읽기 순서

9~12과는 같은 firmware skeleton에 event source를 하나씩 추가하는 구간이다. 책 내용을 넓게 보기 전에 아래 순서로 code를 읽으면 register와 구조체의 반복이 보인다.

```text
9과  GPIO input
     `GPIOC->MODER/PUPDR/IDR` → `GPIOA->ODR`

10과 UART polling
     `GPIOA->MODER/AFR` → `USARTx->BRR/CR/SR/DR`

11과 Timer polling·output
     `SysTick->CTRL/LOAD/VAL`
     `TIMx->PSC/ARR/EGR/SR/CR1` → `GPIOB->AFR` → buzzer

12과 Interrupt/event
     `SYSCFG->EXTICR` + `EXTI->FTSR/IMR/PR` + NVIC
     `USART2->CR1.RXNEIE` + NVIC
     `TIM4->DIER.UIE` + NVIC
```

이 순서는 pin level을 main이 직접 읽는 방식에서 시작해, serial data와 time event를 polling으로 받고, 마지막에는 같은 event를 ISR과 main loop로 나누는 과정이다.

## FPGA RTL·상위 software와의 경계

| 현재 Cortex-M4 firmware | FPGA RTL/Vivado | Jetson·application software |
| :--- | :--- | :--- |
| 이미 존재하는 MCU peripheral의 register 설정 | Verilog/SystemVerilog로 hardware block 자체 기술·합성 | Linux 위 application·runtime·SDK 사용 |
| C/C++ cross compile 후 Cortex-M4가 instruction 실행 | bitstream을 FPGA fabric에 configuration | C++ 등이 CPU에서 실행, TensorRT 등이 GPU/NPU 사용 |
| GPIO·UART·timer·I2C·SPI·ADC를 직접 제어 | custom UART/timer/AXI/NPU datapath 구현 가능 | camera·model inference·robot control 같은 제품 기능 |

따라서 firmware는 hardware와 가장 가까운 software 계층이다. register를 쓰는 C code가 hardware circuit을 새로 만드는 것은 아니며, 이미 존재하는 hardware block의 mode·time·data·event 경로를 구성한다. 이 경험은 나중에 FPGA custom IP의 `control register`, `status flag`, `interrupt`, `AXI-Lite`를 읽을 때 직접 이어진다.

## 이후 회독의 기준

| pass | 목표 | 스스로 확인할 수 있는 상태 |
| :--- | :--- | :--- |
| 1차 지도 pass | 과목의 역할·code 위치·앞뒤 연결 파악 | '무엇을 왜 제어하는지'를 한 문장으로 설명 |
| 2차 동작 pass | 실제 code·배선·terminal/LED 결과 추적 | `pin/signal → clock gate → register field → 결과` trace |
| 3차 재구성 pass | 작은 요구사항을 driver 수준에서 변형·debug | reference를 보며 pin·period·protocol·event 구조 변경 |

각 peripheral을 다시 볼 때는 여섯 공통 질문과 해당 lab source를 먼저 확인한다. 그 뒤에 data sheet·reference manual의 register field와 전기적 timing을 깊게 읽는다.
