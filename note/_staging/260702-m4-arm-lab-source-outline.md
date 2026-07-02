# 26-07-02 - M4 ARM Lab 예제 정리

원본 위치:

`/Users/mumallaeng/Library/CloudStorage/GoogleDrive-yonnmilk@gmail.com/My Drive/Classroom/대한상공회의소_반도체설계/김은경/상공회의소_KDT_실습자료(C_Python_M4)/3.ARM_Lab`

M4 실습자료는 STM32F411RE/Nucleo 기반 bare-metal 예제 묶음이다. 각 폴더는 `main.c`, `Makefile`, startup/linker/runtime 파일, CMSIS header, 주변장치 driver 파일을 조합해 하나의 보드 실습 단위로 구성된다.

## 수업 흐름

| 단계 | 폴더 | 주제 |
| :--- | :--- | :--- |
| build/startup | `0001.COMPILE_TEST` | 컴파일, link, download, UART echo 확인 |
| GPIO 직접 제어 | `0501.LED_ON_LAB`~`0701.BIT_OP_LAB` | register 주소, qualifier, CMSIS, bit operation |
| driver 분리 | `0702.LED_DRIVER_LAB`~`0902.KEY_DRIVER_LAB` | LED/KEY driver API와 polling |
| serial/time | `1001.UART_LOCAL ECHOBACK_LAB`~`1103.TIMER_OUTPUT_LAB` | UART, SysTick, TIM2/TIM4, timer output |
| interrupt/event | `1201.EXTI_IRQ_LAB`~`1204.TIMER_EVENT_LAB` | EXTI, UART event, timer event, ISR 연결 |
| peripheral interface | `1301.I2C_IF_EX`~`1501.ADC_EX` | I2C, SPI, ADC interface |

## 공통 프로젝트 구조

| 파일 | 역할 |
| :--- | :--- |
| `main.c` | 해당 실습의 application 흐름 |
| `Makefile` | compile, link, image 생성, download 명령 |
| `crt0.s` | reset entry와 startup assembly |
| `runtime.c` | C runtime 초기화 보조 |
| `rom_0x08000000.lds` | flash 기준 linker script |
| `stm32f411xe.h`, `stm32f4xx.h` | STM32 register/CMSIS device 정의 |
| `core_cm4.h`, `cmsis_*.h` | Cortex-M4 core/CMSIS 공통 정의 |
| `system_stm32f4xx.c/h` | system clock/core 초기화 흐름 |
| `device_driver.h` | 수업 driver API 선언 |
| `macro.h`, `option.h` | 공통 macro와 build option |

bare-metal 실습에서는 운영체제 없이 reset 직후 startup code가 실행되고, C runtime 초기화 이후 `Main()` 또는 main 흐름으로 들어간다. `Makefile`은 cross compiler, linker script, object 파일, download 절차를 한 곳에서 관리한다.

## 0001. 컴파일과 기본 입출력 확인

`0001.COMPILE_TEST`는 전체 M4 실습의 smoke test 역할이다. `Sys_Init(115200)`에서 FPU 접근 허용, clock 초기화, UART2 초기화, stdout buffering 해제, LED 초기화를 수행한다.

```c
static void Sys_Init(int baud)
{
    SCB->CPACR |= (0x3 << 10*2)|(0x3 << 11*2);
    Clock_Init();
    Uart2_Init(baud);
    setvbuf(stdout, NULL, _IONBF, 0);
    LED_Init();
}
```

`Main()`은 UART terminal에서 입력한 key를 다시 송신하는 echo-back 구조다. `USART2->SR`의 RX/TX 상태 bit를 polling하고, `USART2->DR`에 읽고 쓴다.

| 확인 항목 | 의미 |
| :--- | :--- |
| compile 성공 | toolchain, include, linker script 정상 |
| download 성공 | flash write/debug 연결 정상 |
| terminal echo | UART2 입출력과 board 연결 정상 |

## 0501~0602. Register 직접 제어와 CMSIS

### 0501 LED ON

`0501.LED_ON_LAB`는 LED가 연결된 GPIOA pin 5를 직접 register로 제어하는 실습이다. `GPIOA_MODER`, `GPIOA_OTYPER`, `GPIOA_ODR` 같은 register를 직접 define하고, pin mode를 general output push-pull로 설정한 뒤 output data를 변경한다.

| register | 역할 |
| :--- | :--- |
| `GPIOA_MODER` | pin mode 선택 |
| `GPIOA_OTYPER` | output type 선택 |
| `GPIOA_ODR` | output data 설정 |

이 단계의 목적은 driver 없이 register address와 bit field를 직접 만지는 구조를 이해하는 데 있다.

### 0601 type qualifier

`0601.TYPE_QUALIFIER_EX`는 hardware register 접근에서 `volatile` 같은 type qualifier가 왜 필요한지 연결된다. compiler는 일반 memory 접근을 최적화할 수 있지만, peripheral register는 프로그램 외부의 hardware가 값을 바꾸거나, 같은 값을 다시 쓰는 것 자체가 의미를 가질 수 있다.

MMIO register pointer에는 `volatile`을 붙여 compiler가 접근을 제거하거나 재사용하지 않도록 해야 한다.

### 0602 CMSIS

`0602.CMSIS_LAB`는 직접 숫자 주소를 define하는 방식에서 CMSIS device header를 사용하는 방식으로 이동한다. `stm32f411xe.h`, `core_cm4.h`는 peripheral base address, register 구조체, core register 정의를 제공한다.

```c
GPIOA->MODER
GPIOA->ODR
USART2->SR
```

CMSIS 방식은 주소 계산을 header에 맡기고, code에서는 peripheral 이름과 register 이름으로 접근하게 만든다.

## 0701~0702. Bit operation과 LED driver

`0701.BIT_OP_LAB`는 특정 bit만 set/reset/toggle/check하는 macro와 연산을 정리한다.

| 연산 | pattern |
| :--- | :--- |
| bit set | `reg |= mask` |
| bit reset | `reg &= ~mask` |
| bit toggle | `reg ^= mask` |
| bit check | `(reg & mask) != 0` |

`0702.LED_DRIVER_LAB`는 LED register 제어를 `led.c`로 분리한다. `device_driver.h`에는 `LED_Init()`, `LED_On()`, `LED_Off()`가 선언된다.

```c
LED_Init();

for (;;)
{
    (led ^= 1) ? LED_Off() : LED_On();
}
```

이 단계부터 application은 GPIO register를 직접 몰라도 `LED_On()` 같은 driver API로 동작을 표현할 수 있다. 이후 KEY, UART, Timer driver도 같은 방식으로 확장된다.

## 0801. Clock 설정

`0801.CLOCK_CONFIG_EX`는 system clock 설정을 별도 `clock.c`로 분리한다. STM32에서는 peripheral clock enable, PLL 설정, bus prescaler, flash latency 같은 설정이 peripheral 동작 속도에 영향을 준다.

clock 설정은 UART baud rate, timer tick, SysTick delay의 기준이 되므로, 뒤쪽 실습에서 시간 계산이 맞으려면 먼저 안정적으로 잡혀 있어야 한다.

## 0901~0902. Key 입력과 polling driver

`0901.KEY_IN_LAB`는 key 입력을 GPIO input으로 polling하는 기본 구조다. `0902.KEY_DRIVER_LAB`에서는 이를 `key.c` driver로 분리한다.

`device_driver.h`의 주요 API는 다음 역할로 나뉜다.

| API | 역할 |
| :--- | :--- |
| `Key_Poll_Init()` | key 입력 pin 초기화 |
| `Key_Get_Pressed()` | 현재 key 눌림 여부 확인 |
| `Key_Wait_Key_Pressed()` | key가 눌릴 때까지 대기 |
| `Key_Wait_Key_Released()` | key가 떼질 때까지 대기 |

`0902.KEY_DRIVER_LAB/main.c`는 key가 눌렸는지 확인하며 `#`를 출력하다가 눌리면 message를 출력하고, key press/release에 맞춰 LED를 켜고 끄는 구조다.

polling은 CPU가 계속 상태를 확인하는 방식이다. 구현이 단순하지만, main loop가 다른 일을 하는 동안 event를 놓치거나 CPU 시간을 계속 사용할 수 있다. 이 한계가 뒤쪽 EXTI interrupt 실습으로 이어진다.

## 1001. UART local echo-back

`1001.UART_LOCAL ECHOBACK_LAB`는 UART1을 별도로 초기화하고 송수신 상태를 확인하는 실습이다. UART2는 terminal 출력용으로 사용하고, UART1은 local echo-back 대상이 된다.

주요 API는 다음과 같다.

| API | 역할 |
| :--- | :--- |
| `Uart1_Init(baud)` | UART1 초기화 |
| `Uart1_Send_Byte(data)` | 1byte 송신 |
| `Uart1_Get_Char()` | 1byte 수신 |
| `Uart1_Get_Pressed()` | 수신 data 존재 여부 확인 |

`main.c`는 `'A'`부터 `'Z'`까지 송신하고 수신된 문자를 출력하는 흐름을 의도한다. 송신 buffer ready와 수신 buffer valid 상태를 register 또는 driver API로 확인해야 한다.

## 1101~1103. SysTick과 Timer

### SysTick

`1101.SYSTICK_TIMER_LAB`는 Cortex-M core의 SysTick을 이용해 시간 기준을 만든다. `SysTick_Run(msec)`, `SysTick_Check_Timeout()`, `SysTick_Stop()` 같은 API는 지정 시간 경과 여부를 확인하는 방식으로 사용된다.

### TIM2 stopwatch와 delay

`1102.TIMER_DRIVER_LAB`는 TIM2/TIM4 driver를 활용한다. `main.c`에는 여러 test block이 있고, 현재 활성 block은 TIM2 stopwatch test다.

```c
TIM2_Stopwatch_Start();
SysTick_Run(100 * i);
while (!SysTick_Check_Timeout());
SysTick_Stop();

unsigned int r = TIM2_Stopwatch_Stop();
printf("[%d] Elapsed Time = %f msec\n", i, r / 1000.);
```

TIM2는 경과 시간을 측정하고, SysTick은 일정 시간 대기를 만든다. 두 timer를 비교하면서 시간 측정과 timeout 처리의 차이를 확인할 수 있다.

### TIM4 반복 timeout과 output

`TIM4_Repeat(time)`, `TIM4_Check_Timeout()`, `TIM4_Change_Value(time)`는 주기 event 생성, timeout 확인, 주기 변경을 담당한다. `1103.TIMER_OUTPUT_LAB`는 timer output 기능으로 특정 frequency 출력을 만드는 실습으로 이어진다.

## 1201~1204. Interrupt와 event

### EXTI IRQ

`1201.EXTI_IRQ_LAB`는 key 입력을 polling 대신 external interrupt로 처리한다.

```c
Key_ISR_Enable(1);

for (;;)
{
    printf(".");
    TIM2_Delay(300);
}
```

main loop는 계속 `.`를 출력하지만, key event가 발생하면 ISR이 끼어들어 처리된다. interrupt는 main 흐름을 잠시 중단하고 정해진 handler를 실행한 뒤 원래 흐름으로 돌아오는 구조다.

### exception.c와 ISR 연결

`exception.c`는 interrupt vector와 handler 구현을 담당한다. button, UART RX, timer timeout 같은 event가 발생하면 해당 ISR에서 flag를 세우거나 driver callback을 실행하는 방식으로 main 흐름과 연결한다.

| 폴더 | event 종류 |
| :--- | :--- |
| `1201.EXTI_IRQ_LAB` | key external interrupt |
| `1202.EXTI_EVENT_EX` | EXTI event 흐름 |
| `1203.UART_EVENT_LAB` | UART RX event |
| `1204.TIMER_EVENT_LAB` | timer repeat event |

interrupt/event 구조는 polling보다 반응성이 좋지만, ISR 안에서는 오래 걸리는 작업을 피하고 필요한 상태만 짧게 처리하는 것이 중요하다.

## 1301. I2C interface

`1301.I2C_IF_EX`는 I2C1로 SC16IS752 같은 외부 장치의 register를 제어하는 실습이다.

```c
I2C1_SC16IS752_Init(400000);
I2C1_SC16IS752_Config_GPIO(0xFF);

data = ~(1u << i);
I2C1_SC16IS752_Write_GPIO(data);
```

`Config_GPIO(0xFF)`는 외부 장치의 GPIO 방향을 설정하고, `Write_GPIO(data)`는 LED pattern을 출력한다. `~(1u << i)`는 active-low LED처럼 특정 bit만 0으로 만들어 한 LED를 켜는 pattern이다.

I2C는 SCL/SDA 두 선을 공유하고 address 기반으로 slave를 선택한다. 이 실습에서는 register address와 data를 I2C transaction으로 전달하는 흐름이 핵심이다.

## 1401. SPI interface

`1401.SPI_IF_EX`는 SPI1으로 같은 외부 장치를 제어하는 예제다.

```c
SPI1_SC16IS752_Init(32);
SPI1_SC16IS752_Config_GPIO(0xFF);
SPI1_SC16IS752_Write_GPIO(data);
```

주석에 따르면 PCLK2 96MHz 기준 분주비를 전달하고, SC16IS752의 SPI 최대 속도 4MHz 조건 때문에 `32`를 사용해 약 3MHz로 동작하게 한다.

SPI는 SCLK, MOSI, MISO, CS 신호를 사용하고, master가 clock과 chip select를 제어한다. I2C와 달리 별도 chip select로 slave를 선택하는 흐름이 중요하다.

## 1501. ADC

`1501.ADC_EX`는 ADC1 channel 6을 초기화하고 변환 결과를 읽는 실습이다.

```c
ADC1_IN6_Init();

for (;;)
{
    ADC1_Start();
    while (!ADC1_Get_Status());
    printf("0x%.4X\n", ADC1_Get_Data());
}
```

ADC는 analog 입력 전압을 digital 값으로 변환한다. `ADC1_Start()`로 변환을 시작하고, `ADC1_Get_Status()`로 변환 완료를 기다린 뒤 `ADC1_Get_Data()`로 결과를 읽는다.

## Driver 확장 흐름

| 단계 | 추가 driver | 수업 의미 |
| :--- | :--- | :--- |
| LED | `led.c` | GPIO 출력 제어를 driver로 분리 |
| KEY | `key.c` | GPIO 입력과 switch/key 처리 |
| UART | `uart.c` | serial 송수신, echo-back, event 처리 |
| SysTick/Timer | `systick.c`, `timer.c` | time base, delay, timer event |
| EXTI/Exception | `exception.c` | interrupt vector와 ISR 연결 |
| I2C/SPI | `i2c.c`, `spi.c` | serial peripheral register access |
| ADC | `adc.c` | analog input 변환 |

이 흐름은 register 직접 제어에서 driver API로 추상화되는 과정이다. `main.c`는 점점 application 시나리오 중심으로 남고, peripheral 세부 설정은 `led.c`, `key.c`, `uart.c`, `timer.c` 같은 driver 파일로 이동한다.

## 날짜 노트 반영 기준

| 상황 | 처리 |
| :--- | :--- |
| M4 환경 설치 수업 | `m4-nucleo-tool-install.md`와 연결 |
| 실제 보드 코드 실습 | 해당 날짜 수업메모에 사용한 폴더와 핵심 `main.c` 흐름만 링크 |
| 주변장치 개념 정리 | `GPIO`, `UART`, `Timer`, `EXTI`, `I2C`, `SPI`, `ADC` 단위로 별도 domain 후보 |
| 발표/보고서 활용 | driver 구조, `main.c` 실습 시나리오, board 확인 방법 중심으로 재작성 |
