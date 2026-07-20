# 26-07-21 - Startup·Interrupt·Event-Driven Firmware

관련 노트:

- [26-07-20 - Timer 제어](260720-timer-control.md)
- [26-07-16 - UART와 Timer 제어 선행 정리](260716-arm-cortex-m4-device-programming.md)
- [1201.EXTI_IRQ_LAB](../helloEmbedded/1201.EXTI_IRQ_LAB/)
- [1202.EXTI_EVENT_EX](../helloEmbedded/1202.EXTI_EVENT_EX/)
- [1203.UART_EVENT_LAB](../helloEmbedded/1203.UART_EVENT_LAB/)
- [1204.TIMER_EVENT_LAB](../helloEmbedded/1204.TIMER_EVENT_LAB/)

## 실습 코드 연결

현재 작성한 `1201 → 1203 → 1204`는 startup·clock·UART·LED 초기화 틀을 유지한 채 interrupt source를 하나씩 늘리는 흐름이다. `Main()`은 application loop, `key.c`·`uart.c`·`timer.c`는 peripheral 설정, `exception.c`는 vector table이 호출하는 ISR을 맡는다.

| 실습 | 실제 source | hardware event → ISR | main loop가 맡는 일 |
| :--- | :--- | :--- | :--- |
| `1201 EXTI` | [main.c](../helloEmbedded/1201.EXTI_IRQ_LAB/main.c) · [key.c](../helloEmbedded/1201.EXTI_IRQ_LAB/key.c) · [exception.c](../helloEmbedded/1201.EXTI_IRQ_LAB/exception.c) | `PC13` falling edge → `EXTI13` → IRQ `40` → `EXTI15_10_IRQHandler()` | ISR route 확인용 주기 출력 |
| `1203 UART` | [main.c](../helloEmbedded/1203.UART_EVENT_LAB/main.c) · [uart.c](../helloEmbedded/1203.UART_EVENT_LAB/uart.c) · [exception.c](../helloEmbedded/1203.UART_EVENT_LAB/exception.c) | USART2 receive → IRQ `38` → `USART2_IRQHandler()` | `Uart_Data`를 출력하고 event flag 해제 |
| `1204 Timer` | [main.c](../helloEmbedded/1204.TIMER_EVENT_LAB/main.c) · [timer.c](../helloEmbedded/1204.TIMER_EVENT_LAB/timer.c) · [exception.c](../helloEmbedded/1204.TIMER_EVENT_LAB/exception.c) | TIM4 update → IRQ `30` → `TIM4_IRQHandler()` | `TIM4_Expired`를 소비해 LED 상태 변경 |

### `1201`: PC13 EXTI가 ISR에 도달하는 최소 경로

[1201 `main.c`](../helloEmbedded/1201.EXTI_IRQ_LAB/main.c)는 `Sys_Init(115200)` 뒤 `Key_ISR_Enable(1)`을 호출하고, main loop에서는 `.`를 출력하면서 `TIM2_Delay(300)`으로 반복한다. 따라서 key를 누르지 않아도 main loop가 계속 실행되는 상태에서 EXTI가 CPU 실행을 잠시 끼어드는지 확인한다.

[1201 `key.c`](../helloEmbedded/1201.EXTI_IRQ_LAB/key.c)의 `Key_ISR_Enable(1)`은 다음 register 설정을 실제로 수행한다.

```text
GPIOC clock enable·PC13 input
→ SYSCFG clock enable
→ `SYSCFG->EXTICR[3]`에서 EXTI13 source = GPIOC
→ `EXTI->FTSR` bit 13으로 falling edge 선택
→ `EXTI->PR` bit 13과 NVIC IRQ 40의 stale pending clear
→ `EXTI->IMR` bit 13 unmask
→ `NVIC_EnableIRQ(40)`
```

[1201 `exception.c`](../helloEmbedded/1201.EXTI_IRQ_LAB/exception.c)의 `EXTI15_10_IRQHandler()`는 key message 출력 호출 뒤 `EXTI->PR = 1 << 13`으로 peripheral 원인을 clear하고, `NVIC_ClearPendingIRQ(40)`으로 controller pending 상태도 정리한다. 여기서 재진입을 막는 핵심은 `EXTI->PR`의 EXTI13 pending clear다. `40`은 `EXTI15_10_IRQn`이므로 source 주석에 남아 있는 `EXTI15_9` 표기와 분리해 IRQ group을 읽는다.

### `1203`: UART byte를 ISR에서 받아 main으로 넘기기

[1203 `main.c`](../helloEmbedded/1203.UART_EVENT_LAB/main.c)는 `volatile unsigned char Uart_Data`와 `volatile int Uart_Data_In`을 ISR-main 공유 state로 둔다. `Uart2_RX_Interrupt_Enable(1)` 뒤 main loop는 `Uart_Data_In`이 set됐을 때만 `RX Data = ...`를 출력하고 flag를 `0`으로 돌린다.

[1203 `uart.c`](../helloEmbedded/1203.UART_EVENT_LAB/uart.c)의 `Uart2_RX_Interrupt_Enable(1)`은 `USART2->CR1` bit `5`의 RXNE interrupt enable을 set하고, IRQ `38` pending clear와 `NVIC_EnableIRQ(38)`을 수행한다. byte가 도착하면 [1203 `exception.c`](../helloEmbedded/1203.UART_EVENT_LAB/exception.c)의 `USART2_IRQHandler()`가 `USART2->DR`을 `Uart_Data`에 저장한 뒤 `Uart_Data_In = 1`만 남기고 return한다.

```text
terminal byte arrival
→ USART2 receive event
→ `USART2_IRQHandler()`
→ `Uart_Data = USART2->DR`, `Uart_Data_In = 1`
→ main loop가 byte 출력·flag clear
```

이 lab부터 ISR은 data 수신과 event 기록을 맡고, `printf()` 같은 상대적으로 긴 application 처리는 main loop가 맡는다.

### `1204`: TIM4 주기 event로 LED를 바꾸기

[1204 `timer.c`](../helloEmbedded/1204.TIMER_EVENT_LAB/timer.c)의 `TIM4_Repeat_Interrupt_Enable(1, 200)`은 TIM4 clock, `PSC`, `ARR`, `EGR.UG`, `SR.UIF` clear, `DIER.UIE`, NVIC IRQ `30`, `CR1.CEN`을 순서대로 설정한다. 이 함수가 `TIM4` hardware에 200 ms 주기의 update event 생성을 요청한다.

[1204 `exception.c`](../helloEmbedded/1204.TIMER_EVENT_LAB/exception.c)의 `TIM4_IRQHandler()`는 먼저 `TIM4->SR` bit `0`인 `UIF`를 clear하고 `TIM4_Expired = 1`을 기록한다. 이어 [1204 `main.c`](../helloEmbedded/1204.TIMER_EVENT_LAB/main.c)가 이 flag를 소비해 `(d ^= 1)`로 LED를 on/off 한다.

```text
TIM4 update event
→ `TIM4_IRQHandler()`
→ `UIF` clear·`TIM4_Expired = 1`
→ main loop가 LED toggle·flag clear
```

이 code는 `1203`의 UART event와 같은 ISR-main 분리를 timer에도 적용한 예다. ISR 안의 `NVIC_ClearPendingIRQ(30)`과 별도로 `TIM4->SR.UIF`를 clear하는 이유도 여기에 있다. `TIM4` peripheral의 발생 원인은 `SR.UIF`이고, NVIC는 그 request를 CPU에 전달하는 controller다.

### code 기준 확인 지점

- [1204 `TIM4_Repeat_Interrupt_Enable()`](../helloEmbedded/1204.TIMER_EVENT_LAB/timer.c)의 `ARR` 계산은 같은 file의 polling `TIM4_Repeat()`와 달리 `- 1`이 없다. `ARR + 1` count 규칙과 실제 요청 period를 비교하는 timer 검증 지점이다.

## Build image와 reset startup

`1201`~`1204`는 운영체제 없이 Flash image에서 바로 시작하는 bare-metal project다. `main.c`만 compile해서 실행하는 구조가 아니라, linker script가 memory 배치를 정하고 `crt0.s`가 reset 직후 C runtime 상태를 만든 뒤 `Main()`으로 넘기는 구조다.

| 파일 | 맡는 역할 |
| :--- | :--- |
| `main.c` | application loop와 event 소비 |
| `exception.c` | 실제 `*_IRQHandler()` 구현 |
| `key.c`, `uart.c`, `timer.c` | peripheral 설정과 driver API |
| `crt0.s` | vector table, reset entry, `.data` copy, `.bss` clear |
| `rom_0x08000000.lds` | Flash·SRAM 영역과 section 배치 |
| `runtime.c` | `printf` UART retarget, heap용 `_sbrk()` |
| `core_cm4.h`, `stm32f411xe.h` | Cortex-M4·STM32F411 CMSIS register 정의 |
| `Makefile` | ARM GCC compile·link·image·download 흐름 |

`rom_0x08000000.lds`는 이 board image의 memory 계약을 다음처럼 둔다.

```text
ROM (rx) : 0x08000000, 512 KiB    // STM32F411 Flash
RAM (rwx): 0x20000000, 128 KiB    // STM32F411 SRAM

.text / .rodata  → ROM
.data             → RAM, 초기값 image는 ROM의 __RO_LIMIT__ 뒤
.bss              → RAM, 초기값 image 없음
```

`.data : AT(__RO_LIMIT__)`는 실행 중 주소와 image 안의 load 주소를 분리한다. initialized global·static variable의 초기값은 Flash image에 들어가고, reset 뒤 `crt0.s`가 `__RO_LIMIT__ → __RW_BASE__`로 word 단위 copy한다. `.bss`는 Flash에 초기값을 저장하지 않고 `__ZI_BASE__ → __ZI_LIMIT__` 범위를 `0`으로 clear한다.

```text
linker script
  → vector table·.text·.rodata를 Flash에 배치
  → .data의 초기값 image를 Flash에 배치하고 실행 영역은 SRAM으로 지정
  → .bss를 SRAM에 배치하고, 그 끝과 RAM top을 heap·stack 경계로 사용

reset
  → vector[0]에서 initial MSP load
  → vector[1]의 __start로 branch
  → .data copy·.bss clear
  → BL Main
```

이 project는 `.text`와 `.rodata`를 Flash에서 직접 실행·read하고, 쓰기 가능한 `.data`, `.bss`, stack, heap만 SRAM에 둔다. 따라서 'program 전체가 ROM에 있다'가 아니라, code·read-only data는 Flash에 두고 writable state는 SRAM에 두는 MCU형 XIP layout이다.

`option.h`는 `__ZI_LIMIT__` 뒤를 8 byte align해 `HEAP_BASE`로 잡고 4 KiB heap을 둔다. initial MSP는 `0x20020000`에서 시작하므로 stack은 남은 SRAM 상단을 사용한다. `runtime.c`의 `_write()`는 standard output byte를 `Uart2_Send_Byte()`로 전달한다. `printf()`가 terminal에 보이는 경로는 `printf → _write → Uart2_Send_Byte → USART2`다. `_sbrk()`는 heap의 현재 끝을 옮기되 `HEAP_LIMIT`를 넘지 않게 한다.

## 12과 - Interrupt 제어

`interrupt`는 CPU가 main loop를 실행하는 중 peripheral event를 받으면, hardware가 정해진 handler로 잠시 분기시키는 실행 경로다. handler가 끝나면 CPU는 저장해 둔 main loop 위치로 돌아온다.

이번 범위의 핵심은 `interrupt`라는 단어 하나가 아니라 다음 연결이다.

```text
peripheral event
→ peripheral status·pending flag
→ NVIC request·priority 판단
→ vector table의 handler 주소
→ ISR
→ 원인 flag clear·최소 상태 기록
→ main loop의 application 처리
```

`26-07-20`의 `TIM4_Check_Timeout()`은 main loop가 `SR.UIF`를 직접 polling했다. 같은 `TIM4` update event에 `DIER.UIE`와 NVIC 설정을 더하면 hardware가 `TIM4_IRQHandler()`로 분기시키는 interrupt 방식이 된다. timer hardware 자체가 바뀌는 것이 아니라, event를 CPU가 받는 경로가 polling에서 ISR로 바뀐다.

## Exception, IRQ, `IRQn`

`exception`은 Cortex-M의 비정상·제어 전환 전체를 부르는 상위 범주다. reset, fault, `SysTick`, `SVC`, `PendSV`, 외부 peripheral interrupt가 모두 이 체계 안에 있다. `interrupt`는 그중 timer, UART, EXTI 같은 외부 event가 CPU 실행을 전환시키는 경우다.

CMSIS의 `IRQn_Type`는 core exception에는 음수, STM32 peripheral IRQ에는 `0` 이상을 사용한다. vector table index는 `IRQn + 16`으로 연결된다.

| 구분 | CMSIS `IRQn` 예 | Vector table index | 의미 |
| :--- | :--- | :--- | :--- |
| core exception | `SysTick_IRQn = -1` | `15` | Cortex-M system timer exception |
| external IRQ 시작 | `WWDG_IRQn = 0` | `16` | STM32 peripheral IRQ 첫 entry |
| timer | `TIM4_IRQn = 30` | `46` | TIM4 update 등 timer event |
| UART | `USART2_IRQn = 38` | `54` | USART2 event |
| EXTI group | `EXTI15_10_IRQn = 40` | `56` | EXTI line 10~15 group |

`IRQn`의 음수 표기는 priority의 높낮이를 뜻하지 않는다. core exception과 external peripheral IRQ를 하나의 signed enum으로 표현하기 위한 번호 체계다. interrupt priority는 NVIC priority register가 별도로 결정한다.

## Vector table과 reset startup

vector table은 예외·interrupt마다 CPU가 갈 handler 주소를 순서대로 둔 table이다. entry 하나는 `4 byte`이고, 시작 두 entry는 일반 handler가 아니다.

| Vector index | 값 | 역할 |
| :---: | :--- | :--- |
| `0` | initial MSP | reset 직후 stack pointer에 넣을 SRAM top 값 |
| `1` | `Reset_Handler` 또는 `__start` | C runtime 초기화 시작 주소 |
| `2`~`15` | NMI·fault·SVC·PendSV·SysTick handler | Cortex-M core exception |
| `16+` | `*_IRQHandler` | STM32 peripheral IRQ handler |

[1201 `crt0.s`](../helloEmbedded/1201.EXTI_IRQ_LAB/crt0.s)는 첫 word에 `0x20020000`, 두 번째 word에 `__start`를 둔다. 즉 reset 직후 CPU는 첫 word를 MSP로 읽고, 두 번째 word가 가리키는 startup code를 실행한다. vector table의 handler 주소가 홀수로 보이면 마지막 bit는 Cortex-M의 Thumb state 표시다. 실제 instruction address는 alignment를 유지한다.

이 startup code는 ST-LINK 관련 pin 준비 뒤 다음 runtime 초기화를 수행한다.

```text
Flash의 initialized data image
→ SRAM의 `.data` 영역으로 copy

SRAM의 `.bss` 영역
→ 0으로 clear

`BL Main`
→ 사용자가 작성한 firmware 진입점
```

따라서 이 수업 project에서 `Main()`이 대문자인 이유는 C 언어 자체가 대문자 `Main`을 특별 취급해서가 아니다. `crt0.s`가 `BL Main`으로 그 symbol을 호출하도록 작성되어 있기 때문이다. startup code가 `BL main`을 사용하면 일반적인 `main()`을 호출하게 된다.

| 영역 | 담는 내용 | reset 뒤 위치·상태 |
| :--- | :--- | :--- |
| vector table | initial MSP·handler 주소 | image 시작부, CPU 분기 기준 |
| `.text` | 실행 instruction | Flash 실행 영역 |
| `.rodata` | 문자열·상수 table | Flash read-only 영역 |
| `.data` | 초기값이 있는 global·static 변수 | Flash image에서 SRAM으로 copy |
| `.bss` | 초기값 없는 global·static 변수 | SRAM에서 zero clear |
| stack | 함수 call·local state·exception context | SRAM, initial MSP 기준 |

## Weak default handler와 실제 ISR override

`crt0.s`는 모든 vector entry를 직접 구현하지 않는다. 각 `*_IRQHandler`를 `.weak` symbol로 선언하고 기본적으로 `Invalid_ISR`에 연결한다. `exception.c`가 같은 이름의 함수, 예를 들어 `EXTI15_10_IRQHandler()`를 strong symbol로 정의하면 linker가 그 함수 주소를 사용한다.

```text
vector table entry: EXTI15_10_IRQHandler
        │
        ├─ application이 handler를 정의함 → 그 handler 실행
        └─ 정의하지 않음                → weak alias인 Invalid_ISR 실행
```

`_Invalid_ISR()`는 `SCB->ICSR`의 active vector 번호를 읽어 예기치 않은 exception·IRQ를 확인한 뒤 정지한다. 사용하지 않는 peripheral IRQ까지 빈 함수를 모두 작성하지 않아도 되며, 예상하지 않은 interrupt가 들어온 경우에는 조용히 실행을 계속하지 않고 debug 가능한 상태로 멈춘다.

## NVIC와 ISR의 역할

`NVIC`는 여러 peripheral request의 enable, pending, priority를 관리하는 Cortex-M interrupt controller다. peripheral은 자기 status flag를 set하고, NVIC는 해당 request를 CPU의 handler 진입으로 연결한다.

| 작업 | CMSIS API | 의미 |
| :--- | :--- | :--- |
| 특정 IRQ 허용 | `NVIC_EnableIRQ()` | NVIC level enable |
| 특정 IRQ 차단 | `NVIC_DisableIRQ()` | NVIC level disable |
| pending 제거 | `NVIC_ClearPendingIRQ()` | 과거 request 제거 |
| priority 지정 | `NVIC_SetPriority()` | 동시 request 처리 순서 |
| 전역 mask 제어 | `__enable_irq()`, `__disable_irq()` | PRIMASK 기반 전체 IRQ gate |

interrupt가 실제 ISR로 들어가려면 peripheral 내부 enable bit, peripheral pending flag, NVIC enable 상태가 모두 맞아야 한다. 전역 IRQ mask를 사용했다면 그 상태도 함께 확인한다.

ISR은 원인을 빠르게 확인하고 원인 flag를 clear한 뒤, 필요한 최소 data 또는 event flag만 남기고 return한다. `printf`, 긴 delay, busy-wait, 복잡한 memory allocation처럼 오래 걸리는 작업은 main loop 쪽에 둔다.

```text
ISR
→ peripheral cause 확인
→ peripheral pending flag clear
→ data read 또는 `volatile` event flag set
→ return

main loop
→ event flag 확인
→ 긴 application 처리
```

`volatile`은 ISR이 바꾼 값을 main loop가 매번 memory에서 다시 읽도록 하는 qualifier다. 여러 byte state의 atomic update, counter overflow, event queue 유실까지 해결하지는 않는다. 그런 공유 상태는 critical section, atomic operation, single-producer/single-consumer 규칙을 추가로 설계한다.

## EXTI: User Key를 interrupt로 연결하는 경로

Nucleo User Key의 `PC13`은 EXTI13 line과 연결된다. EXTI line은 pin 번호를 기준으로 정해지고, `SYSCFG->EXTICR`가 그 line의 GPIO port source를 선택한다. line `10`~`15`는 하나의 `EXTI15_10_IRQn` group을 공유한다.

```text
PC13 falling edge
→ `SYSCFG->EXTICR[3]`: EXTI13 source = GPIOC
→ EXTI13 pending
→ `EXTI15_10_IRQn = 40`
→ `EXTI15_10_IRQHandler()`
```

[1202 `Key_ISR_Enable()`](../helloEmbedded/1202.EXTI_EVENT_EX/key.c)는 다음 순서로 `PC13` key interrupt를 구성한다.

```text
GPIOC clock·PC13 input 설정
→ SYSCFG clock enable
→ EXTICR에서 EXTI13 source를 GPIOC로 선택
→ `EXTI->FTSR` bit 13으로 falling edge 선택
→ `EXTI->PR` bit 13에 `1`을 써서 stale pending clear
→ NVIC IRQ 40 pending clear
→ `EXTI->IMR` bit 13 unmask
→ `NVIC_EnableIRQ(40)`
```

`EXTI->PR`는 `1` write로 해당 pending bit를 clear한다. ISR 안에서는 이 peripheral 원인 flag를 먼저 clear해야 같은 원인이 계속 ISR을 다시 요청하지 않는다. source code에 있는 NVIC pending clear는 enable 직전 stale request를 제거하는 데 특히 의미가 크다.

## Event-Driven 구조: ISR과 main을 나누는 이유

`1201.EXTI_IRQ_LAB`은 handler로 분기하는 기본 구조를 먼저 확인한다. `1202.EXTI_EVENT_EX`은 ISR에서 출력·긴 처리를 하지 않고 `Key_Pressed`만 set한 뒤, main loop가 실제 동작을 처리하는 event-driven 구조로 확장한다.

```c
volatile int Key_Pressed = 0;

void EXTI15_10_IRQHandler(void)
{
    Key_Pressed = 1;
    EXTI->PR = 1u << 13;
}

void Main(void)
{
    for (;;) {
        if (Key_Pressed) {
            Key_Pressed = 0;
            /* application work */
        }
    }
}
```

`Key_Pressed = 1`과 `Key_Pressed = 0` 사이에 button이 한 번 더 눌리면 단일 flag만으로는 두 번의 event를 구분할 수 없다. 다음 단계에서 event 수를 보존해야 하면 counter 또는 queue가 필요하다.

`1201.EXTI_IRQ_LAB`은 ISR로 직접 message를 출력해 vector route가 연결됐는지 먼저 보이는 예다. 그러나 `printf`는 UART TX ready를 기다릴 수 있어 ISR 안에서 오래 걸릴 수 있다. `1202.EXTI_EVENT_EX`은 ISR을 `Key_Pressed = 1`과 pending clear로 줄이고, terminal 출력·LED 동작은 main loop가 맡도록 바꾼다. 이 차이가 event-driven firmware의 기본 경계다.

## UART·Timer interrupt로 같은 구조 확장

| source lab | peripheral event | ISR이 최소로 하는 일 | main 전달 state |
| :--- | :--- | :--- | :--- |
| [1202 EXTI](../helloEmbedded/1202.EXTI_EVENT_EX/) | `PC13` falling edge·`EXTI->PR` | pending clear | `Key_Pressed` |
| [1203 UART](../helloEmbedded/1203.UART_EVENT_LAB/) | `USART2->SR.RXNE` | `DR` read | `Uart_Data`, `Uart_Data_In` |
| [1204 Timer](../helloEmbedded/1204.TIMER_EVENT_LAB/) | `TIM4->SR.UIF` | UIF clear | `TIM4_Expired` |

UART polling에서는 main loop가 늦으면 수신 register를 비우는 시점도 늦어진다. RX interrupt는 byte 도착 시점에 ISR이 `DR`을 읽고 data를 넘기는 경로다. timer polling에서는 main loop가 `UIF`를 확인해야 했지만, timer interrupt는 update event가 ISR을 호출하고 `TIM4_Expired` 같은 flag로 main에 전달한다.

## 0721 실습 순서

1. [1201 `crt0.s`](../helloEmbedded/1201.EXTI_IRQ_LAB/crt0.s)의 vector entry와 weak default handler를 확인한다.
2. `PC13 → EXTI13 → EXTI15_10_IRQn → EXTI15_10_IRQHandler()` 경로를 `1201`에서 완성한다.
3. `1202`에서 ISR을 짧게 만들고 `volatile` flag를 main loop에서 소비한다.
4. `1203`에서 USART2 RX event를 같은 구조로 연결한다.
5. `1204`에서 TIM4 update event를 같은 구조로 연결하고 polling timer와 비교한다.

이 순서는 `hardware event → register flag → CPU ISR → software event handling`을 하나의 흐름으로 보게 한다. 실제 구현을 마친 뒤에는 각 handler가 어떤 peripheral flag를 왜 clear하는지와 ISR-main 공유 상태가 안전한지를 code 기준으로 다시 확인한다.

## 다음 범위 연결: I2C bus 시작

interrupt 실습의 마지막 연결은 외부 IC 통신이다. `I2C`는 `SCL`과 `SDA` 두 선을 여러 device가 공유하는 serial bus이며, high를 직접 drive하지 않는 open-drain과 외부 pull-up resistor가 전기적 기반이다.

```text
device가 line을 release  → pull-up resistor가 high
device 하나가 low drive → shared line 전체가 low
```

이 구조는 wired-AND, multi-device sharing, clock stretching, arbitration의 출발점이다. STM32F411에서는 `PB6 = I2C1_SCL`, `PB7 = I2C1_SDA`를 `AF4`, open-drain, pull-up으로 설정한다.

I2C driver는 data register 하나에 값을 쓰고 끝나는 구조가 아니다. `START → SB → address → ADDR clear → TXE/BTF → STOP` 순서로 `SR1`, `SR2`, `DR`, `CR1`의 상태를 따라간다. 특히 `ADDR`는 reference manual이 정한 `SR1` 뒤 `SR2` read sequence로 clear해야 한다. 이 흐름은 다음 `13과 I2C BUS Interface`에서 외부 `SC16IS752` register 제어로 확장한다.
