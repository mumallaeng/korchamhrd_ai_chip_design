# 26-07-15 - LED Driver 과제와 System Clock 설정

관련 노트:

- [26-07-14 - GPIO, Type Qualifier, CMSIS, Bit 연산](260714-gpio-volatile-cmsis-bit-operations.md)
- [26-07-14 ARM Cortex-M4 디바이스 프로그래밍 실습 과제](../assignment/260714-arm-cortex-m4-device-programming-homework.md)

## 실습 과제

0714에 확인한 GPIO register·bit mask·macro를 사용하여 LED 제어를 구현한다. PA5 macro Toggle은 수업 예제이고, 이번 과제 범위는 아래 세 항목이다.

| 과제 | 대상 | 구현 목표 |
| :--- | :--- | :--- |
| LED 3개 count | `0701.BIT_OP_LAB/main.c` | `000`부터 `111`까지 3bit binary count |
| LED 왕복 shift | `0701.BIT_OP_LAB/main.c` | `001 -> 010 -> 100 -> 010 -> 001` 반복 |
| LED driver | `0702.LED_DRIVER_LAB/led.c` | `LED_Init`·`LED_On`·`LED_Off` 구현 |

### LED 3개 `0`~`7` count

외부 LED 세 개는 PA5~PA7에 연결한다. 세 LED의 logical value를 `value`의 하위 3bit로 표현하고, `0x7u` mask를 사용해 범위를 항상 `0`~`7`로 제한한다.

```c
LED3_Control(value);
Delay();
value = (value + 1u) & 0x7u;
```

`value = (value + 1u) & 0x7u`는 `7 + 1`의 결과에서 하위 3bit만 남겨 `0`으로 되돌린다. count 값은 delay가 끝난 뒤 한 번만 증가해야 한다. delay loop 안에서 증가시키면 사람 눈으로 보기 전에 값이 여러 번 바뀐다.

외부 LED는 active-low open-drain 연결이므로 logical `1`을 LED on으로 표시하려면 실제 `ODR`에는 `0`을 기록해야 한다.

```c
value = (~value) & 0x7u;
Macro_Write_Block(GPIOA->ODR, 0x7u, value, 5u);
```

첫 줄은 logical 표시값의 하위 3bit만 반전한다. 둘째 줄은 `ODR[7:5]`만 갱신하므로 다른 GPIO pin의 output level은 유지한다.

### LED 왕복 shift

왕복 shift는 하나만 켜진 pattern을 이동시킨다. 시작 pattern은 `001`이고, 오른쪽 끝에 해당하는 `100`까지 두 번 left shift한 뒤 방향을 바꾼다.

```c
if (direction == 0u)
    value <<= 1;
else
    value >>= 1;

steps++;
if (steps == 2u)
{
    direction ^= 1u;
    steps = 0u;
}
```

`direction`은 shift 방향을 나타내며 `0`일 때 `<<= 1`, `1`일 때 `>>= 1`을 수행한다. LED가 세 개이므로 끝까지 이동하는 데 두 번의 shift가 필요하다. `steps == 2u`에서 `direction ^= 1u`로 방향을 반전하면 `001 -> 010 -> 100 -> 010 -> 001` 순서가 반복된다.

count와 shift 함수는 모두 무한 loop를 가진다. 따라서 `Main()`에서는 한 번에 하나만 호출한다.

```c
void Main(void)
{
    Sys_Init(115200);
    LED3_Init();

    Count_0_to_7();
    /* Shift_Bounce(); */
}
```

왕복 shift를 확인할 때는 `Count_0_to_7()` 호출을 주석 처리하고 `Shift_Bounce()`를 활성화한다.

### LED Driver code 작성

driver 과제는 [`0702.LED_DRIVER_LAB/led.c`](../helloEmbedded/0702.LED_DRIVER_LAB/led.c)에 구현한다. PA5 User LED는 active-high push-pull 연결이므로 외부 LED의 active-low 반전과 open-drain 설정을 사용하지 않는다.

```c
void LED_Init(void)
{
    Macro_Set_Bit(RCC->AHB1ENR, 0);
    Macro_Write_Block(GPIOA->MODER, 0x3u, 0x1u, 10);
    Macro_Clear_Bit(GPIOA->OTYPER, 5);
    Macro_Clear_Bit(GPIOA->ODR, 5);
}

void LED_On(void)
{
    Macro_Set_Bit(GPIOA->ODR, 5);
}

void LED_Off(void)
{
    Macro_Clear_Bit(GPIOA->ODR, 5);
}
```

| 함수 | register 동작 | 결과 |
| :--- | :--- | :--- |
| `LED_Init()` | GPIOA clock enable, `MODER[11:10] = 01`, `OTYPER[5] = 0`, `ODR[5] = 0` | PA5 push-pull output, LED off |
| `LED_On()` | `ODR[5]` set | PA5 high, User LED on |
| `LED_Off()` | `ODR[5]` clear | PA5 low, User LED off |

application `main.c`는 LED를 켜고 끄는 순서만 결정한다. `led.c`는 PA5의 clock·mode·output type·level을 제어한다. 함수 선언은 `device_driver.h`에 두고, `main.c`와 `led.c`를 함께 build하여 linker가 하나의 firmware로 결합한다.

## 확인 기준

| 항목 | 확인할 동작 |
| :--- | :--- |
| count | LED 3개가 `000`부터 `111`까지 반복 표시 |
| shift | LED 하나가 양 끝에서 방향을 바꾸며 왕복 |
| driver | `LED_On()`·`LED_Off()` 호출에 따라 PA5 User LED on/off |

## 8과 - System Clock 설정

### 여러 C file을 하나의 firmware로 만들기

임베디드 project는 `main.c` 하나로만 구성되지 않는다. `main.c`, `led.c` 같은 여러 source file과 library를 각각 compile하여 object file로 만들고, linker가 이들을 결합하여 하나의 executable 또는 firmware image를 만든다.

```text
main.c ── compile ──> main.o ──┐
led.c  ── compile ──> led.o  ──┼── link ──> firmware
library ────────────> library ─┘
```

| 단계 | 확인 대상 | 대표 오류 |
| :--- | :--- | :--- |
| compile | 각 source file의 C 문법·type·선언 | syntax error, 선언되지 않은 이름 |
| link | 여러 object file·library 사이의 symbol 연결 | 정의되지 않은 함수·변수, 중복 정의 |
| build | compile과 link를 묶은 전체 작업 | 위 두 종류의 오류 |

같은 이름의 global variable을 여러 `.c` file에서 각각 정의하면 linker가 중복 정의 오류를 낸다. 공용 global variable은 한 source file에서만 정의하고, 다른 file은 `extern` 선언으로 그 정의를 참조한다.

```c
/* globals.c: storage를 실제로 만드는 한 곳의 정의 */
int total;

/* app.c: 다른 file의 정의를 참조하는 선언 */
extern int total;
```

`static`을 file scope 함수 또는 global variable에 붙이면 internal linkage가 되어 해당 `.c` file 안에서만 이름을 사용할 수 있다. driver 내부 helper는 `static`으로 숨기고, 다른 file이 호출해야 하는 `LED_Init()`·`LED_On()`·`LED_Off()` 같은 API에는 `static`을 붙이지 않는다.

```c
/* led.c 내부에서만 쓰는 helper */
static void Delay(void);

/* main.c에서도 호출할 driver API */
void LED_On(void);
```

header file은 여러 source file이 공유하는 function declaration과 type definition을 한곳에 모은다. `#include <stdio.h>`가 `printf()`의 declaration을 제공하는 것처럼, `device_driver.h`는 LED driver API declaration을 `main.c`에 제공한다.

### Clock source와 PLL

CPU는 clock edge를 기준으로 instruction과 peripheral 동작을 진행하므로 안정된 clock이 필요하다. MCU에서 자주 사용하는 source와 주파수 합성 방식은 다음과 같다.

| 구분 | 특징 |
| :--- | :--- |
| Resonator | 저가, 저정밀, 저주파 source |
| X-TAL | crystal 기반, 고정밀 source |
| Oscillator | crystal과 필요한 부가 회로를 포함한 clock source |
| PLL | 기준 clock으로부터 더 높은 목표 주파수 합성 |

발진의 기본 개념은 inverter 출력을 지연시켜 다시 입력으로 되돌리는 되먹임 회로다. 출력이 뒤집혀 돌아오기를 반복하므로 신호가 스스로 진동하며, ring oscillator가 이 원리를 사용한다.

crystal은 얇게 가공할수록 높은 주파수를 내는데, 가공 한계 때문에 수십 MHz를 넘는 고주파 crystal은 수율이 떨어지고 비싸진다. 그래서 CPU가 요구하는 높은 clock은 낮은 기준 주파수를 PLL로 곱해 만든다. PLL은 본래 주파수의 틀어짐을 기준 신호에 맞춰 보정하는 장치이며, 이를 응용해 기준보다 높은 목표 주파수를 합성하는 데 쓴다.

#### PLL을 왜 계산하는가

CPU와 digital peripheral은 clock edge마다 다음 동작으로 넘어간다. 따라서 MCU에는 일정한 박자를 만드는 clock source가 필요하다. `HSI`는 `High-Speed Internal`의 약자로, STM32F411 칩 내부에 들어 있는 `16MHz` RC oscillator다. 외부 부품 없이 바로 사용할 수 있는 기본 clock source지만, CPU는 더 빠른 `96MHz`로 동작시키고 USB peripheral은 정확히 `48MHz`를 필요로 한다.

#### Frequency와 한 clock cycle을 숫자로 연결하기

frequency는 1초에 반복되는 clock edge의 횟수다. `f = 1 / T`에서 `f`는 frequency, `T`는 한 cycle의 시간이다. 숫자를 시간 감각으로 바꾸면 clock 설정이 왜 memory timing과 peripheral baud rate에 영향을 주는지 이해하기 쉽다.

| clock | 1초당 cycle 수 | 한 cycle 시간 |
| :--- | :--- | :--- |
| `1MHz` | 1,000,000회 | `1µs` |
| `16MHz` HSI | 16,000,000회 | `62.5ns` |
| `48MHz` | 48,000,000회 | 약 `20.83ns` |
| `96MHz` SYSCLK/HCLK | 96,000,000회 | 약 `10.42ns` |

CPU가 `96MHz`일 때 instruction 하나가 항상 정확히 한 cycle에 끝나는 것은 아니다. instruction 종류, Flash wait cycle, bus access, branch, interrupt에 따라 여러 cycle이 걸릴 수 있다. 다만 모든 동작의 시간 단위가 더 짧아지므로, Flash처럼 물리적으로 data 준비 시간이 필요한 장치는 wait cycle을 함께 설정해야 함.

PLL은 하나의 기준 clock을 받아 여러 목적에 맞는 안정된 clock을 만드는 주파수 변환 block이다. PLL 내부의 VCO(`Voltage-Controlled Oscillator`)는 먼저 높은 중간 주파수를 만들고, 그 출력을 나누어 CPU와 USB에 각각 필요한 clock을 보낸다.

```text
기준 박자: HSI 16MHz
        |
        v
PLL: 높은 중간 주파수 VCO 생성
        |
        +--> CPU용 96MHz
        |
        +--> USB용 48MHz
```

따라서 PLL 계산은 '`입력 16MHz를 어떤 비율로 나누고 곱해야 CPU 96MHz와 USB 48MHz를 동시에 만들 수 있는가`'를 찾는 작업이다. `PLLM`·`PLLN`·`PLLP`·`PLLQ`는 그 비율을 정하는 값이다.

#### Clock tree를 읽는 공식 기준

- [RM0383 Reference Manual, Figure 12. Clock tree, p. 94](https://www.st.com/resource/en/reference_manual/rm0383-stm32f411xce-advanced-armbased-32bit-mcus-stmicroelectronics.pdf): `HSI`·`HSE`·`PLLCLK` 선택, `PLLM/N/P/Q` 경로, `SYSCLK`·`HCLK`·`APB` prescaler, 48MHz clock 경로
- [DS10314 Datasheet, Figure 3. STM32F411xC/xE block diagram, p. 16](https://www.st.com/resource/en/datasheet/stm32f411re.pdf): Reset & clock control block, internal RC HS/LS, PLL, external crystal oscillator, AHB·APB bus와 peripheral 연결

Reference manual은 register와 clock path를 설정할 때 기준으로 사용하고, datasheet block diagram은 clock control이 CPU·memory·bus·peripheral에 연결되는 전체 위치를 확인할 때 사용한다.

PLL은 기준 clock과 설정값을 비교하며 목표 주파수에 맞춘다. enable 직후에는 출력이 안정되지 않을 수 있으므로 ready bit가 set될 때까지 기다린 뒤 system clock source로 선택해야 한다. 이 안정화에 필요한 시간을 lock time이라고 함.

STM32F411은 HSI 16MHz 또는 HSE를 PLL 입력으로 선택하여 SYSCLK, AHB, APB1, APB2, USB 48MHz clock을 구성한다.

현재 실습 board는 외부 HSE source를 사용하지 않고 internal HSI 16MHz를 PLL input으로 사용한다. STM32F411 core는 최대 100MHz까지 동작할 수 있지만, USB를 함께 사용하려면 PLLQ output을 정확히 48MHz로 만들어야 한다. PLL divider가 integer 값만 사용하므로, 실습 설정은 100MHz 대신 `96MHz / 2 = 48MHz`가 가능한 SYSCLK 96MHz를 선택함.

#### Board schematic으로 HSE 사용 가능 여부 확인

회로도에 외부 crystal footprint나 `X3 8MHz` 표기가 있다고 해서, 해당 HSE가 MCU에 실제로 연결됐다고 바로 판단하면 안 된다. 회로도와 실물 board에서 다음 세 가지를 함께 확인한다.

| 확인 대상 | 의미 | HSE 사용 판단 |
| :--- | :--- | :--- |
| crystal 또는 oscillator 부품 | 실제 외부 기준 clock 발생원 | 부품 실장 여부 확인 |
| `OSC_IN`·`OSC_OUT`까지의 연결 | HSE signal이 MCU oscillator pin에 도달하는 경로 | 회로도 net과 저항·jumper 연결 확인 |
| `NA` 표기, 저항 footprint, `SB` | 선택 조립 경로 또는 끊긴 경로 | `NA`·미실장·open 상태면 해당 경로 미사용 |

`SB`는 solder bridge의 약자다. 납으로 short하거나 open하여 board의 signal 경로를 바꾸는 선택 연결점이다. `0Ω` resistor도 전기적으로는 연결선 역할을 하며, 자동 실장 공정에서 일반 resistor와 같은 방식으로 배치할 수 있어 jumper처럼 사용한다. 따라서 HSE용 crystal이 보이더라도 `SB` 또는 `0Ω` resistor가 open이면 MCU는 그 source를 쓰지 못할 수 있다.

Software에서도 `RCC->CR.HSEON`을 set한 뒤 `HSERDY`가 `1`이 되는지 확인해야 한다. HSE 경로가 준비되지 않았으면 HSE를 SYSCLK 또는 PLL input으로 선택하지 않고, 이 실습처럼 확인된 `HSI 16MHz`를 기준으로 PLL을 구성한다.

```text
HSI 16MHz
    |
    v
  PLLM divide
    |
    v
  PLLN multiply
    |
    +--> PLLP divide --> SYSCLK 96MHz
    |                       |
    |                       +--> AHB HCLK 96MHz
    |                               |
    |                               +--> APB2 PCLK2 96MHz
    |                               |
    |                               +--> APB1 PCLK1 48MHz
    |
    +--> PLLQ divide --> USB/SDIO 48MHz
```

### AHB·APB prescaler가 필요한 이유

PLL로 높은 SYSCLK를 만들었다고 모든 block에 같은 주파수를 그대로 보낼 수 있는 것은 아니다. bus·memory·peripheral마다 허용 최대 clock이 다르므로, clock tree의 prescaler가 필요에 따라 주파수를 나눈다.

```text
PLLCLK
  -> SYSCLK
  -> AHB prescaler  -> HCLK  -> core, memory, DMA, AHB bus
  -> APB1 prescaler -> PCLK1 -> APB1 peripheral
  -> APB2 prescaler -> PCLK2 -> APB2 peripheral
```

| 경로 | STM32F411 최대 clock | 96MHz 실습 설정 | 역할 |
| :--- | :--- | :--- | :--- |
| `SYSCLK`·`HCLK` | 100MHz | 96MHz | core, AHB bus, memory, DMA 기준 |
| `PCLK1` | 50MHz | 48MHz, HCLK의 2분주 | APB1 peripheral 기준 |
| `PCLK2` | 100MHz | 96MHz, HCLK의 1분주 | APB2 peripheral 기준 |

clock tree를 설정할 때는 다음 순서로 읽는다.

1. `HSI`·`HSE`·`PLLCLK` 중 SYSCLK source를 선택한다.
2. PLL의 `M`, `N`, `P`, `Q`를 정해 core clock과 USB 48MHz 조건을 만족시킨다.
3. AHB·APB prescaler를 정해 HCLK·PCLK1·PCLK2가 각 bus의 최대 clock을 넘지 않게 한다.
4. timer처럼 APB prescaler 값에 따라 별도 timer clock 규칙을 갖는 peripheral은 reference manual의 clock tree를 추가로 확인한다.

`AHB1ENR`·`APB1ENR`·`APB2ENR`의 peripheral clock enable은 이 bus clock이 설정된 다음, 각 peripheral에 실제 clock을 공급하는 gate 역할을 한다. 따라서 PLL과 prescaler는 전체 clock 속도를 만들고, enable register는 필요한 device만 동작시키는 단계임.

### `RCC->CR`: source와 PLL ready 확인

`RCC->CR`은 clock source ON/OFF와 ready 상태를 제어한다.

| bit | 이름 | 의미 |
| :--- | :--- | :--- |
| `0` | `HSION` | HSI 16MHz clock enable |
| `1` | `HSIRDY` | HSI ready |
| `16` | `HSEON` | HSE clock enable |
| `17` | `HSERDY` | HSE ready |
| `24` | `PLLON` | PLL enable |
| `25` | `PLLRDY` | PLL ready |

`HSION`이나 `PLLON`을 set한 직후에는 source 또는 PLL output이 아직 안정되지 않았을 수 있다. 따라서 software는 대응하는 `HSIRDY`·`PLLRDY` status bit가 `1`이 될 때까지 기다린다. PLL을 켠 뒤 출력이 목표 주파수로 고정될 때까지 걸리는 이 시간을 lock time이라고 부르며, `PLLRDY` polling은 lock이 끝났음을 hardware로 확인하는 절차다. CMSIS header에서 이런 ready flag는 보통 `__I`로 선언된 read-only field다.

```c
Macro_Set_Bit(RCC->CR, 0);        /* HSION */
while (!Macro_Check_Bit_Set(RCC->CR, 1))
    ;                             /* HSIRDY 확인 */

Macro_Set_Bit(RCC->CR, 24);       /* PLLON */
while (!Macro_Check_Bit_Set(RCC->CR, 25))
    ;                             /* PLLRDY 확인 */
```

M3·M4 MCU는 사용하지 않는 peripheral에 clock을 공급하지 않아 dynamic power를 줄인다. `RCC->CR`은 clock source와 PLL을 제어하고, `RCC->AHB1ENR`·`APB1ENR`·`APB2ENR`은 각 peripheral의 clock gate를 제어한다. GPIOA를 쓸 때 `RCC->AHB1ENR[0]`을 먼저 set하는 이유도 이 구조 때문임.

### `RCC->PLLCFGR`: PLL 주파수 계산

PLL 계산식은 다음과 같다.

```text
fVCO = fPLL_input * (PLLN / PLLM)
fPLL_general_output = fVCO / PLLP
fUSB_OTG_FS_SDIO = fVCO / PLLQ
```

HSI 16MHz를 기준으로 `SYSCLK = 96MHz`, `USBCLK = 48MHz`를 만들기 위한 설정 예시는 다음과 같다.

```c
RCC->PLLCFGR = (8u << 24) | (0u << 22) | (1u << 16) | (192u << 6) | (8u << 0);
```

#### 예제: 식을 register 값으로 조립하기

위 식은 `PLLCFGR`의 field를 각각 제자리로 shift한 뒤 OR 연산으로 합친다. 최종 register 값은 주파수 `96MHz`가 아니라, PLL의 `M`·`N`·`P`·`Q` 비율과 source 선택을 담은 bit pattern이다.

```text
(8u   << 24) = 0x08000000  -> PLLQ = 8
(0u   << 22) = 0x00000000  -> PLLSRC = HSI
(1u   << 16) = 0x00010000  -> PLLP code 01, 실제 /4
(192u <<  6) = 0x00003000  -> PLLN = 192
(8u   <<  0) = 0x00000008  -> PLLM = 8
----------------------------------------------- OR
PLLCFGR value  = 0x08013008u
```

`0x08013008u`을 write하면 PLL은 `HSI 16MHz`를 input으로 받아 CPU용 `96MHz`와 USB용 `48MHz`를 만들도록 구성된다. 실제 clock 전환은 이후 `PLLON`·`PLLRDY`·`CFGR.SW` 설정까지 끝나야 함.

`RCC->PLLCFGR`은 PLL의 비율만 기록하는 configuration register다. 이 한 줄만으로 CPU clock이 바로 바뀌지는 않는다. `RCC->CR`에서 PLL을 enable하고 `PLLRDY`를 확인한 다음, `RCC->CFGR`에서 PLL output을 `SYSCLK` source로 선택해야 실제 clock 전환이 완료됨.

#### PLL parameter를 한 번에 읽기

`PLLM`과 `PLLN`이 VCO 주파수 `fVCO`를 만들고, `PLLP`와 `PLLQ`가 그 VCO 출력을 각각 SYSCLK와 USB/SDIO clock으로 나눈다.

| 순서 | field | 식에서의 역할 | 허용 값 또는 조건 | 현재 설정의 계산 |
| :---: | :--- | :--- | :--- | :--- |
| 입력 선택 | `PLLSRC` | `fPLL_input` 선택 | `0`: HSI, `1`: HSE | `0` → HSI `16MHz` |
| 1 | `PLLM` | `fVCO_input = fPLL_input / PLLM` | `2`~`63`, VCO input `1`~`2MHz` | `16MHz / 8 = 2MHz` |
| 2 | `PLLN` | `fVCO = fVCO_input * PLLN` | `50`~`432`, VCO output `100`~`432MHz` | `2MHz * 192 = 384MHz` |
| 3 | `PLLP` | `fPLL_general_output = fVCO / PLLP` | 실제 divider `/2`, `/4`, `/6`, `/8` | `384MHz / 4 = SYSCLK 96MHz` |
| 4 | `PLLQ` | `fUSB_OTG_FS_SDIO = fVCO / PLLQ` | `2`~`15`, USB OTG FS는 `48MHz` 필요 | `384MHz / 8 = 48MHz` |

즉 이 설정은 `HSI 16MHz`를 `PLLM = 8`로 먼저 `2MHz`로 만들고, `PLLN = 192`로 `VCO 384MHz`까지 올린 뒤, 필요한 clock마다 다른 divider를 적용한 것이다.

`PLLQ[27:24]`는 bit pattern이 divider 값과 직접 대응한다. 레퍼런스 매뉴얼에는 `0`과 `1`을 명시적으로 `wrong configuration`이라고 적어 두었다.

| `PLLQ[27:24]` bit pattern | `PLLQ` divider | 상태 |
| :---: | :---: | :--- |
| `0000` | `0` | `wrong configuration` |
| `0001` | `1` | `wrong configuration` |
| `0010`~`1111` | `2`~`15` | 유효한 divider |

따라서 사용 가능한 `PLLQ` 값은 `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9`, `10`, `11`, `12`, `13`, `14`, `15`다. 이 실습에서는 `PLLQ = 8`을 골라 `384MHz / 8 = 48MHz`를 만든다.

#### 목표 clock에서 PLL 후보를 좁히는 순서

`SYSCLK = 96MHz`와 USB clock `48MHz`를 동시에 만족시키려면, 먼저 `PLLP`의 허용 divider에서 가능한 `fVCO` 후보를 구한다.

| `PLLP` divider | 필요한 `fVCO = 96MHz * PLLP` | VCO `100`~`432MHz` 조건 | 판정 |
| :---: | :---: | :---: | :--- |
| `/2` | `192MHz` | 만족 | 후보 |
| `/4` | `384MHz` | 만족 | 후보 |
| `/6` | `576MHz` | 초과 | 제외 |
| `/8` | `768MHz` | 초과 | 제외 |

남은 각 후보를 USB 조건 `PLLQ = fVCO / 48MHz`에 넣으면 `192MHz / 48MHz = 4`, `384MHz / 48MHz = 8`이 된다. 둘 다 `PLLQ`의 허용 범위 `2`~`15` 안이다.

| `fVCO` | `PLLP` | SYSCLK | `PLLQ` | USB clock |
| :---: | :---: | :---: | :---: | :---: |
| `192MHz` | `/2` | `96MHz` | `/4` | `48MHz` |
| `384MHz` | `/4` | `96MHz` | `/8` | `48MHz` |

그다음 `HSI 16MHz / PLLM`으로 VCO input을 정한다. 매뉴얼은 VCO input `1`~`2MHz`를 허용하고 jitter를 줄이기 위해 `2MHz`를 권장한다. 따라서 `PLLM = 8`을 선택하면 `16MHz / 8 = 2MHz`가 되며, 각 후보의 `PLLN`은 `fVCO / 2MHz`로 계산한다. 현재 코드는 높은 VCO 후보인 `384MHz`를 택해 `PLLN = 192`, `PLLP = /4`, `PLLQ = 8`을 사용한다.

`PLLP`는 divider 값을 그대로 저장하지 않고 encoding 값을 사용한다. 따라서 `PLLP[17:16]`에 쓴 `1u`은 `/1`이 아니라 bit pattern `01`, 곧 실제 `/4`를 뜻한다.

| `PLLP[17:16]` code | 실제 divider |
| :---: | :---: |
| `00` | `/2` |
| `01` | `/4` |
| `10` | `/6` |
| `11` | `/8` |

계산 결과가 맞더라도 PLL parameter의 허용 범위를 지켜야 한다. STM32F411에서 VCO output은 `100MHz`~`432MHz` 범위여야 하며, `PLLQ`는 `2`~`15`의 정수다. 이 실습의 `VCO = 384MHz`는 범위 안이고, `PLLP = 4`로 SYSCLK 96MHz, `PLLQ = 8`로 USB용 48MHz를 동시에 만든다.

```text
HSI 16MHz
  -> / PLLM 8 = 2MHz
  -> * PLLN 192 = VCO 384MHz
  -> / PLLP 4 = SYSCLK 96MHz
  -> / PLLQ 8 = USB clock 48MHz
```

### `RCC->CFGR`와 Flash wait cycle

`RCC->CFGR`은 SYSCLK source와 AHB·APB prescaler를 설정한다. SYSCLK 96MHz 설정에서는 AHB와 APB2를 1분주, APB1을 2분주로 둔다.

```c
RCC->CFGR = (0u << 13) | (4u << 10) | (0u << 4);
Macro_Write_Block(RCC->CFGR, 0x3u, 0x2u, 0u);
while (Macro_Extract_Area(RCC->CFGR, 0x3u, 2u) != 0x2u)
    ;
```

| 설정 | 값 | 결과 |
| :--- | :--- | :--- |
| `SW` | `0x2` | PLL output을 SYSCLK로 선택 |
| `SWS` | `0x2` 확인 | PLL이 실제 SYSCLK source인지 확인 |
| `HPRE` | `0` | AHB 1분주 |
| `PPRE2` | `0` | APB2 1분주 |
| `PPRE1` | `4` | APB1 2분주 |

이 설정의 실제 clock 결과는 다음과 같다. `PCLK1`과 USB clock은 모두 `48MHz`지만, 하나는 AHB divider 결과이고 다른 하나는 PLLQ divider 결과라서 만들어지는 경로가 다르다.

| clock | 계산 | 결과 | 주된 대상 |
| :--- | :--- | :---: | :--- |
| `SYSCLK` | PLL general output | `96MHz` | Cortex-M4 core 기준 clock |
| `HCLK` | `SYSCLK / HPRE` | `96MHz` | AHB bus, core·memory bus |
| `PCLK2` | `HCLK / PPRE2` | `96MHz` | APB2 peripheral |
| `PCLK1` | `HCLK / PPRE1` | `48MHz` | APB1 peripheral |
| USB clock | `VCO / PLLQ` | `48MHz` | USB OTG FS |

#### Flash wait cycle이 필요한 이유

CPU는 clock에 맞춰 address를 내보내고, chip select·read signal을 준 뒤 memory data를 읽는다. CPU clock이 빨라질수록 이 한 cycle의 시간은 짧아지지만 Flash memory는 read request를 받은 뒤 data를 준비하는 데 일정한 access time이 필요하다.

```text
이상적:    address / read request  -> 같은 clock 안에 data 준비 -> CPU read
실제 Flash: address / read request  -> Flash access time 필요 -> data 준비가 늦음
```

wait cycle은 CPU가 Flash data를 읽기 전에 추가 clock cycle만큼 기다리게 하는 설정이다. 이를 생략하면 CPU가 data가 준비되기 전에 읽으려 하므로, 높은 clock에서 code fetch나 data read가 불안정해질 수 있다. 3.3V, HCLK `96MHz` 조건에서 실습 설정은 `3` wait cycle을 사용한다.

`FLASH->ACR`은 Flash access timing과 성능 보조 기능을 함께 설정한다.

| field | bit | 설정 | 역할 |
| :--- | :---: | :---: | :--- |
| `DCRST` | `12` | `1` 후 해제 | data cache reset |
| `ICRST` | `11` | `1` 후 해제 | instruction cache reset |
| `DCEN` | `10` | `1` | data cache enable |
| `ICEN` | `9` | `1` | instruction cache enable |
| `PRFTEN` | `8` | `1` | prefetch enable |
| `LATENCY` | `2:0` | `0x3` | Flash wait cycle `3` |

cache와 prefetch를 쓰면 Flash access의 체감 지연을 줄일 수 있다. cache reset을 먼저 수행한 뒤 cache·prefetch를 enable하고, `LATENCY`를 HCLK와 voltage 조건에 맞추어 설정한다.

```c
FLASH->ACR = (1u << 12) | (1u << 11);
FLASH->ACR = (1u << 10) | (1u << 9) | (1u << 8) | (0x3u << 0);
```

### Clock 초기화 순서

clock 초기화는 source enable, source ready 확인, Flash 설정, PLL 설정·ready 확인, SYSCLK 전환·전환 확인 순서로 진행한다.

이 순서는 단순한 관례가 아니라, clock을 바꾸는 순간에도 CPU가 안전하게 instruction을 fetch하도록 만드는 순서다. reset 직후에는 HSI가 SYSCLK로 선택된 상태를 기준으로 작업하고, 더 빠른 PLL clock으로 넘어가기 **전에** Flash access 조건을 맞춘다. PLL parameter는 PLL이 꺼져 있을 때 구성하고, output이 lock된 뒤에만 SYSCLK source로 선택한다.

| 단계 | 먼저 하는 일 | 이 순서가 필요한 이유 |
| :---: | :--- | :--- |
| 1 | HSI enable, `HSIRDY` 확인 | 이후 설정 code를 실행할 안정된 기준 clock 확보 |
| 2 | Flash latency·cache 설정 | 빠른 HCLK로 전환한 뒤에도 Flash code fetch가 timing 조건을 만족 |
| 3 | `PLLON = 0` 상태에서 `PLLCFGR` 구성 | 동작 중인 PLL의 ratio를 바꾸지 않고 입력·divider 조건을 확정 |
| 4 | `PLLON`, `PLLRDY` 확인 | PLL이 lock되기 전의 불안정한 output을 SYSCLK에 연결하지 않음 |
| 5 | `CFGR.SW`로 PLL 선택, `SWS` 확인 | 요청한 source가 실제 system clock으로 전환됐는지 확인 |

`SW`는 software가 원하는 source를 쓰는 control field이고, `SWS`는 hardware가 현재 실제로 쓰는 source를 알려 주는 status field다. 둘이 같아질 때까지 확인하는 이유는 clock mux 전환도 즉시 끝나는 조합 논리 동작이 아니라, hardware가 안전한 시점에 완료하는 상태 변화이기 때문이다.

```c
void Clock_Init(void)
{
    Macro_Set_Bit(RCC->CR, 0);
    while (!Macro_Check_Bit_Set(RCC->CR, 1))
        ;

    FLASH->ACR = (1u << 12) | (1u << 11);
    FLASH->ACR = (1u << 10) | (1u << 9) | (1u << 8) | (0x3u << 0);

    RCC->PLLCFGR = (8u << 24) | (0u << 22) | (1u << 16) | (192u << 6) | (8u << 0);
    Macro_Set_Bit(RCC->CR, 24);
    while (!Macro_Check_Bit_Set(RCC->CR, 25))
        ;

    RCC->CFGR = (0u << 13) | (4u << 10) | (0u << 4);
    Macro_Write_Block(RCC->CFGR, 0x3u, 0x2u, 0u);
    while (Macro_Extract_Area(RCC->CFGR, 0x3u, 2u) != 0x2u)
        ;
}
```

실제 product code에서는 ready bit를 무한히 기다리기보다 timeout과 error path를 둔다. 예를 들어 HSE를 선택했는데 board의 crystal·solder bridge·전원 조건 때문에 `HSERDY`가 올라오지 않으면, 무한 loop 대신 HSI로 되돌아가거나 오류를 기록해야 한다. 수업 예제의 빈 `while`은 register 상태를 관찰하는 핵심 구조를 보여 주기 위한 최소 형태임.

clock 값은 이후 peripheral 설정에서 공통 기준이 되므로 `SYSCLK`, `HCLK`, `PCLK1`, `PCLK2`를 macro로 정의해 둔다.

```c
#define SYSCLK 96000000u
#define HCLK   SYSCLK
#define PCLK2  HCLK
#define PCLK1  (HCLK / 2u)
```

### Peripheral clock enable

RCC의 system clock 설정과 별도로, 각 peripheral은 사용 전에 해당 bus clock gate를 enable해야 한다. GPIOA LED 제어에서 `RCC->AHB1ENR[0]`을 set했던 이유가 여기에 있다.

| Register | 대상 bus | 예시 bit |
| :--- | :--- | :--- |
| `RCC->AHB1ENR` | AHB1 peripheral | `GPIOAEN`, `GPIOBEN`, `GPIOCEN` |
| `RCC->APB1ENR` | APB1 peripheral | `TIM2EN`, `TIM3EN`, `USART2EN`, `I2C1EN`, `SPI2EN` |
| `RCC->APB2ENR` | APB2 peripheral | `TIM1EN`, `USART1EN`, `SPI1EN`, `SYSCFGEN` |

```c
Macro_Set_Bit(RCC->AHB1ENR, 0);
```

### Clock macro와 UART baud rate를 함께 맞춰야 하는 이유

`SYSCLK`, `HCLK`, `PCLK1`, `PCLK2` macro는 이름만 바꾸는 선언이 아니다. UART 초기화는 실제 peripheral clock을 기준으로 baud rate divider를 계산한다. 예를 들어 hardware가 reset 기본 HSI `16MHz`로 동작하는데 header의 `PCLK1`만 `48MHz` 또는 `96MHz`에 맞춘 값으로 바꾸면, UART는 잘못된 divider를 설정한다. 그 결과 PC terminal이 기대하는 bit 시간과 실제 송신 bit 시간이 달라져 문자가 깨져 보인다.

```text
실제 PCLK1: 16MHz, UART code가 가정한 PCLK1: 48MHz
    -> UART divider가 실제 조건과 다르게 계산됨
    -> 송신 baud rate 불일치
    -> terminal에서 frame을 잘못 해석하여 문자 깨짐
```

따라서 더 빠른 clock 값을 macro로 선언했다면, 같은 초기화 경로에서 실제 `Clock_Init()`도 호출해 PLL·bus prescaler·SYSCLK 전환을 완료해야 한다. 반대로 clock 초기화를 하지 않을 때는 UART가 계산에 사용할 macro도 reset 기본 clock과 일치시킨다.

clock source를 바꾼 뒤에는 LED delay 변화뿐 아니라 UART 출력도 함께 확인한다. LED는 delay loop의 실행 시간이 달라졌다는 빠른 시각적 확인이고, UART는 peripheral clock과 baud divider까지 일관되게 맞았는지 확인하는 신호다.

## 9과 - GPIO 입력 제어와 User Key

### 입력 pin은 '전압을 읽는 관찰점'

GPIO pin은 출력만 하는 선이 아니다. `MODER` 설정에 따라 같은 pin을 입력으로도 쓴다. 입력 mode에서는 MCU가 pin을 high 또는 low로 강하게 밀어내지 않고, 외부 회로가 만든 pin 전압을 digital input buffer가 읽어 `GPIOx->IDR`에 반영한다.

입력 회로 자체는 높은 input impedance를 가진다. 이는 pin에 전류를 거의 빼앗지 않고 전압을 읽기 위한 특성이다. 반면 pin node가 아무 전원·GND·저항에도 연결되지 않은 `floating` 상태는 전압의 기준이 없다는 회로 상태다. 이 상태를 3-state 또는 high-impedance(Hi-Z)라고도 부른다. floating pin은 잡음, 주변 신호, 정전 용량의 영향으로 `0`과 `1` 중 어느 값으로 읽힐지 보장할 수 없다.

```text
GPIO input ---- open

input buffer는 읽을 준비가 되었지만
pin 전압을 정하는 회로가 없음 -> floating -> read 값 불확실
```

따라서 switch 하나만 GPIO와 `3.3V` 또는 GND 사이에 연결하면 한 상태만 확실하다.

| 단순 연결 | switch pressed | switch released | 문제 |
| :--- | :--- | :--- | :--- |
| `3.3V -- SW -- GPIO` | high | floating | 눌림만 확실함 |
| `GND -- SW -- GPIO` | low | floating | 눌림만 확실함 |

### Pull-Up·Pull-Down: idle level을 회로로 정하기

pull resistor는 switch가 열려 있을 때 input을 정해진 전압으로 약하게 끌어 둔다. switch가 닫힐 때는 반대 전압이 input에 직접 전달되고, resistor는 전원과 GND가 직접 short 되는 일을 막으며 전류를 제한한다.

| 방식 | switch released, idle | switch pressed | application 관점 |
| :--- | :--- | :--- | :--- |
| pull-down | low, `0` | high, `1` | active-high |
| pull-up | high, `1` | low, `0` | active-low |

```text
Pull-up, active-low switch

3.3V -- [R] --+-- GPIO input
              |
             [SW]
              |
             GND

released: R이 GPIO를 3.3V로 끌어올림 -> 1
pressed : SW가 GPIO를 GND에 연결       -> 0
```

저항값은 전류 소모와 신호가 바뀌는 속도 사이의 절충이다. 너무 작으면 switch를 누른 동안 `3.3V → R → GND` 전류가 커진다. 너무 크면 input의 기생 capacitance를 충전·방전하는 시간이 길어져 변화가 느려지고 잡음에 약해질 수 있다. user button처럼 빠른 응답이 필요하지 않은 입력에는 보통 수 kΩ~수십 kΩ을 쓰며, 실습 board의 key 회로는 외부 `10kΩ` pull-up을 사용한다. 정확한 값은 전원, 속도, 소비 전류, noise 환경을 함께 보고 정한다.

STM32 GPIO는 외부 resistor가 없을 때 쓸 수 있도록 내부 pull-up·pull-down도 제공한다. `GPIOx->PUPDR`의 pin별 2bit field는 floating, pull-up, pull-down을 선택한다. 외부 pull-up이 이미 있는 `PC13` User Key에는 내부 pull 설정을 중복해서 넣을 필요가 없다.

### Nucleo User Key: `PC13`, active-low

실습 board의 파란 User Key는 `PC13`에 연결되고 외부 pull-up이 설치되어 있다. 따라서 key의 물리 상태와 `IDR[13]`의 논리는 다음처럼 반대가 된다.

| Key 상태 | `PC13` 전압 | `GPIOC->IDR[13]` | 의미 |
| :--- | :--- | :---: | :--- |
| released | 약 `3.3V` | `1` | key를 누르지 않음 |
| pressed | 약 `0V` | `0` | key를 누름 |

이처럼 low일 때 동작이 유효한 신호를 `active-low`라고 한다. code에서는 전기적 극성을 함수 안에 감추어 `Key_Is_Pressed()`가 참이면 실제로 눌린 상태가 되게 만들면, 호출하는 쪽이 `0`과 `1`의 반전을 매번 기억할 필요가 없다.

### 설정과 읽기: `MODER`, `IDR`, clock gate

GPIOC를 사용하기 전에 AHB1의 GPIOC clock gate를 열어야 한다. GPIO pin은 reset 뒤 input mode이므로 `PC13`만 읽는 최소 예제에서는 `MODER`를 다시 쓰지 않아도 된다. 다만 pin mode를 명확히 보여 주려면 `PC13`에 해당하는 `MODER[27:26]` field를 `00`으로 쓴다.

```c
/* GPIOC clock enable: AHB1ENR bit 2 = GPIOCEN */
Macro_Set_Bit(RCC->AHB1ENR, 2);

/* PC13 mode field [27:26] = 00: input */
Macro_Write_Block(GPIOC->MODER, 0x3u, 0x0u, 26u);
```

현재 pin의 논리값은 `IDR`에서 읽는다. 원하는 n번 bit만 남기는 mask는 `1u << n`이고, `&` 결과는 bit가 set면 `0`이 아닌 mask 값, clear면 `0`이다.

```c
if (GPIOC->IDR & (1u << 13))
{
    /* released: IDR[13] is 1 */
}
else
{
    /* pressed: IDR[13] is 0 */
}
```

bit 값을 반드시 `0` 또는 `1`로 정규화하려면 먼저 오른쪽으로 옮긴 뒤 `1u`와 AND한다.

```c
unsigned int key_level = (GPIOC->IDR >> 13) & 0x1u;
unsigned int pressed = !key_level;
```

### Key와 LED를 연결하는 최소 흐름

LED는 `PA5`, User Key는 `PC13`이므로 두 port의 clock이 모두 필요하다. key를 누르고 있는 동안 LED를 켜고, 떼면 끄는 동작은 매 loop에서 현재 input level을 읽어 LED output을 결정한다.

```c
void Main(void)
{
    Sys_Init(115200);
    LED_Init();

    Macro_Set_Bit(RCC->AHB1ENR, 2);              /* GPIOC clock */
    Macro_Write_Block(GPIOC->MODER, 0x3u, 0x0u, 26u);

    for (;;)
    {
        if ((GPIOC->IDR & (1u << 13)) == 0u)     /* pressed: active-low */
        {
            LED_On();
        }
        else
        {
            LED_Off();
        }
    }
}
```

이 예제는 level을 그대로 반영하는 동작이다. 한 번 눌렀을 때 LED를 한 번만 toggle하려면 pressed를 처리한 뒤 released가 될 때까지 다시 처리하지 않는 inter-lock과, 실제 switch 접점의 짧은 흔들림을 처리하는 debounce가 추가로 필요하다.

> 공식 확인 위치: `RM0383`, Figure 18 'GPIO input configuration', p. 153 및 §8.4 GPIO registers; 실제 User Key의 `PC13`·외부 pull-up 연결은 Nucleo board schematic에서 확인한다.

### Active-low input을 PA5 LED에 바로 연결하는 논리

현재 수업의 User Key는 active-low이고 PA5 User LED는 `ODR[5] = 1`일 때 켜진다. 따라서 raw input bit를 그대로 `ODR[5]`에 복사하면 논리가 반대가 된다. `IDR[13] = 0`인 pressed 상태에서 LED에는 `1`을 써야 하기 때문이다.

`Macro_Check_Bit_Clear(GPIOC->IDR, 13)`는 bit `13`이 `0`이면 `1`, bit가 `1`이면 `0`을 반환한다. 즉 active-low 전기 신호를 application이 쓰는 `pressed` Boolean으로 바꾸는 연산이다. 이 값을 PA5의 1bit field에 쓰면 `if` 없이 현재 key level을 LED 상태로 직접 반영할 수 있다.

```c
Macro_Write_Block(
    GPIOA->ODR, 0x1u,
    Macro_Check_Bit_Clear(GPIOC->IDR, 13), 5u);
```

| Key 전기 상태 | `IDR[13]` | `Macro_Check_Bit_Clear(...)` | 기록되는 `ODR[5]` | PA5 LED |
| :--- | :---: | :---: | :---: | :--- |
| released | `1` | `0` | `0` | off |
| pressed | `0` | `1` | `1` | on |

이 직접 연결은 PA5 User LED의 active-high 연결을 전제로 한다. 외부 LED처럼 active-low open-drain 회로라면 LED의 전기적 on 값이 반대이므로, 동일한 Boolean을 그대로 쓰기 전에 회로의 극성을 먼저 확인해야 한다.

### Level polling과 '한 번 누름' event는 다름

앞 절의 loop는 key가 눌린 동안 매번 `pressed`를 읽고 LED를 켠다. 이것은 현재 level을 계속 반영하는 polling이다. 반면 LED toggle은 `ODR[5]`를 매 실행마다 반전하므로, key를 누른 채 loop가 여러 번 돌면 한 번의 물리적 누름이 여러 번 toggle로 해석된다. CPU clock이 빠를수록 polling loop는 사람의 누름 시간 안에 훨씬 많이 실행된다.

| 원하는 의미 | 판단 기준 | 예 |
| :--- | :--- | :--- |
| level 동작 | 지금 key가 눌려 있는가 | 누르는 동안 LED on, 떼면 off |
| event 동작 | released에서 pressed로 바뀌었는가 | 누를 때마다 LED 한 번 toggle |

가장 단순한 event 처리 방법은 pressed를 처리한 다음 released가 될 때까지 기다리는 것이다.

```c
if (Key_GetPressed())
{
    LED_Toggle();
    while (Key_GetPressed())
    {
        /* key release를 기다림 */
    }
}
```

이 방식은 한 번 누르는 동안 toggle을 한 번으로 제한하지만, `while` 안에 있는 동안 main loop 전체가 멈춘다. 통신 처리, display 갱신, timer 기반 작업처럼 동시에 해야 할 일이 있다면 key를 계속 기다리는 busy wait가 그 일을 지연시킨다.

### Interlock: 누름과 뗌을 번갈아 기다리는 상태 기계

interlock은 lock 변수로 다음에 허용할 event를 기억하는 방법이다. `lock == 0`에서는 press만 처리하고, press를 처리한 직후 `lock = 1`로 바꾼다. `lock == 1`에서는 release만 기다리며, release가 확인되어야 다시 다음 press를 받을 수 있다.

```c
static unsigned int lock = 0u;

if (lock == 0u)
{
    if (Key_GetPressed())
    {
        LED_Toggle();
        lock = 1u;
    }
}
else if (!Key_GetPressed())
{
    lock = 0u;
}
```

```text
lock = 0: released -> press를 기다림
      press 검출 -> LED toggle, lock = 1

lock = 1: press 처리 금지, release를 기다림
      release 검출 -> lock = 0
```

이 구조는 main loop를 멈추지 않으므로 polling 안에서 다른 작업을 함께 수행할 수 있다. 다만 interlock은 '길게 누르는 동안의 중복 처리'를 막는 장치다. 접점이 튀어 press와 release가 짧게 반복되는 bounce까지 완전히 제거하려면 별도의 debounce 조건이 필요하다.

### Mechanical switch의 chatter와 debounce

tact switch contact는 한 번에 완전히 붙거나 떨어지지 않는다. 누르거나 뗄 때 금속 접점과 spring이 기계적으로 진동해 짧은 시간 동안 low/high가 여러 번 바뀐다. 이를 chatter 또는 bounce라고 하며, MCU는 각각을 별도의 edge로 읽을 수 있다.

```text
이상적인 press:  1 -----------+ 0
실제 접점 press:  1 -------+-+--+--+ 0
                         bounce
```

| 대책 | 원리 | 설계 시 주의점 |
| :--- | :--- | :--- |
| RC filter | resistor와 capacitor로 급격한 전압 변화를 완화 | 너무 큰 `RC`는 응답을 늦춤 |
| Schmitt trigger | 상승·하강에 서로 다른 threshold `V_T+`, `V_T-` 적용 | threshold 사이의 작은 noise에 출력 유지 |
| delay 후 재확인 | press 검출 뒤 일정 시간 후 다시 read | busy wait delay는 다른 task를 멈춤 |
| 연속 sample 확인 | N회 연속 같은 level일 때만 상태 변경 | sample period와 N으로 debounce 시간 결정 |
| timer 기반 debounce | timer tick에서 상태·시간을 관리 | main loop를 막지 않아 확장에 유리 |

일반 CMOS input은 threshold 하나 근처에서 noise가 오가면 high/low 판단이 반복될 수 있다. Schmitt trigger input은 low에서 high가 되려면 높은 `V_T+`를 넘어야 하고, high에서 low가 되려면 낮은 `V_T-` 아래로 내려와야 한다. 두 threshold 차이를 hysteresis라 하며, threshold 사이에서 흔들리는 신호가 출력 상태를 반복해서 바꾸지 않게 한다. STM32F411의 GPIO input configuration도 input buffer에 Schmitt trigger를 표시한다. 이것은 noise margin에 도움이 되지만 switch bounce 조건과 application 요구를 모두 자동으로 해결하는 debounce 기능은 아니다.

### Key driver API로 입력 의도를 분리하기

GPIO register를 application 곳곳에서 직접 읽으면 active-low 반전, port·pin 번호, wait 동작이 흩어진다. key driver는 전기적 세부 사항을 `key.c`에 모으고 application에는 '현재 눌렸는가'와 'event가 올 때까지 기다리는가'라는 의도만 남긴다.

| API | 반환·동작 | 사용 목적 |
| :--- | :--- | :--- |
| `Key_Poll_Init()` | GPIO clock·input mode·pull 설정 | key hardware 초기화 |
| `Key_Get_Pressed()` | pressed면 `1`, 아니면 `0` | 현재 level을 polling |
| `Key_Wait_Key_Pressed()` | press가 올 때까지 return하지 않음 | 다음 press event 대기 |
| `Key_Wait_Key_Released()` | release가 올 때까지 return하지 않음 | 한 press를 끝까지 소비 |

`Key_Get_Pressed()`는 즉시 return하는 level query다. 반대로 이름에 `Wait`가 있는 함수는 내부에서 loop를 돌며 CPU를 점유한다. 두 방식을 섞어 쓰면 아래처럼 'press를 발견하면 release까지 소비한 뒤 다음 press를 받는다'는 흐름을 만들 수 있다.

```c
for (unsigned int count = 0u; count < 10u; count++)
{
    Key_Wait_Key_Pressed();
    LED_Toggle();
    Key_Wait_Key_Released();
}
```

이 예제는 key를 열 번 눌렀다 뗄 때마다 한 번씩 LED를 반전한다. 동시에 UART 출력이나 animation을 계속해야 하면 `Wait` 함수 대신 앞의 interlock 또는 timer 기반 상태 기계를 사용한다.

### 확장 실습: 두 key로 LED animation 멈추기

내부 key와 외부 key를 각각 input으로 두고, 세 LED의 왕복 pattern을 빠르게 갱신하는 동안 한 key를 stop event로 사용할 수 있다. stop이 발생하면 현재 pattern에서 멈추고, 가운데 LED에서 멈췄을 때만 성공 효과를 표시하는 식으로 event 처리와 LED driver를 함께 확인한다.

중요한 점은 key check를 긴 delay loop 바깥에 한 번만 두지 않는 것이다. animation이 멈추지 않고 input 반응도 유지하려면, 짧은 주기로 pattern을 한 단계 갱신하고 같은 주기에서 key state도 확인해야 한다. 이 구조는 이후 timer tick·interrupt 기반 event 처리로 확장할 수 있다.
