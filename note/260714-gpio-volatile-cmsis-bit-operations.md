# 26-07-14 - GPIO, Type Qualifier, CMSIS, Bit 연산

관련 노트:

- [26-07-13 - ARM GCC Toolchain, 전자 소자, 컴퓨터·임베디드 시스템](260713-arm-gcc-electronics-embedded-systems.md)

## 수업 흐름

5과에서는 GPIO register로 PA5 User LED와 PA7 외부 LED를 제어하며, memory-mapped I/O와 C pointer 기반 register 접근을 연결한다.
6과에서는 C의 type qualifier와 CMSIS 구조체 기반 register 정의를 다룬다. timer·interrupt·DMA처럼 CPU code 밖에서 memory 값을 바꾸는 상황을 통해 `volatile`의 의미를 정확히 구분하고, DMA가 CPU 대신 data를 옮기는 방식도 연결한다.
7과에서는 register 전체를 대입하는 방식의 한계를 확인하고, bit mask와 OR·XOR·AND 연산으로 원하는 bit만 set·invert·clear하는 원리를 다룬다. 이어서 PA5 LED의 `MODER` field를 세 방식으로 분석하고, 반복되는 bit 처리식을 `macro.h`의 macro로 묶는다. 이 macro를 이용해 LED를 toggle하고, register 제어를 `LED_Init`·`LED_On`·`LED_Off` driver 함수 뒤로 감추는 실습까지 연결한다.

```text
C code
  -> compiler optimization
  -> volatile read/write 유지
  -> memory-mapped register 또는 DMA 공유 memory
  -> STM32 peripheral 동작
```

## 수업 범위

| 과 | 주제 |
| :--- | :--- |
| 5과 | GPIO 출력 |
| 6과 | Type Qualifier와 `volatile` |
| 7과 | bit mask, field write, bit 처리 macro, macro 기반 LED toggle, LED driver |

## GPIO 출력

### GPIO 핀의 역할

GPIO는 `General Purpose Input & Output`의 약어다. 출력으로 사용할 때는 0V 또는 3.3V를 내보내고, 입력으로 사용할 때는 외부 핀 상태가 low인지 high인지 읽는다.

STM32F411에는 Port A~E, H가 있으며, 각 port는 최대 16개 pin을 가진다. F와 G port는 해당 실습 대상에는 없음.

GPIO는 C code가 물리 pin을 직접 만지는 것이 아니라, register 값을 바꾸면 내부 회로가 pin 전압을 바꾸는 구조다.

```text
C code
  GPIOA->ODR bit write
        |
        v
GPIO output data register
        |
        v
Output driver
        |
        v
PA5 pin voltage
        |
        v
LED ON/OFF
```

Nucleo-64 board의 `LD2` User LED는 `PA5`에 연결되어 있다. `PA5`는 `GPIOA` port의 5번 pin이라는 뜻이며, 해당 pin에 3.3V high를 출력하면 LED가 켜지는 active-high 연결이다.

### GPIO pin 내부 신호 경로

GPIO pin 하나에는 output 경로와 input 경로가 함께 있다. software가 register에 값을 쓰면 output control이 driver transistor를 제어하고, 외부 pin voltage는 input buffer를 거쳐 CPU가 읽을 수 있는 값이 된다.

```text
CPU register write
  -> GPIO output control
  -> P-channel switch 또는 N-channel switch
  -> GPIO pin

외부 pin voltage
  -> Schmitt trigger
  -> IDR input data register
  -> CPU read
```

| 경로 | 핵심 동작 | 연결 register 또는 회로 |
| :--- | :--- | :--- |
| output | pin을 `3.3V` 또는 `0V`로 구동 | output driver, `OTYPER`, `ODR` |
| digital input | 외부 voltage를 logic `0`·`1`로 판정 | Schmitt trigger, `IDR` |
| alternate function | UART·timer 같은 peripheral signal에 pin 연결 | `MODER`, `AFR` |
| analog | digital input 판정 없이 analog peripheral로 전달 | analog mode |

Schmitt trigger는 input threshold에 hysteresis를 두어 천천히 변하거나 noise가 섞인 신호를 여러 번 전환된 것처럼 읽는 현상을 줄인다. ADC처럼 analog voltage 자체를 읽을 때는 digital input 판정 경로를 거치지 않는 analog mode를 사용함.

### Port, pin, alternate function

MCU는 pin을 하나씩 흩어 놓지 않고, 최대 16개 pin을 `GPIO port` 단위로 묶어 관리한다. `PA5`는 Port A의 5번 GPIO pin이고, package의 물리 pin 번호와는 별개다.

| 표기 | 의미 |
| :--- | :--- |
| `PA5` | GPIOA port의 5번 pin |
| `PB3` | GPIOB port의 3번 pin |
| `GPIOA_MODER` | GPIOA에 속한 16개 pin의 mode 설정 register |

한 physical pin은 GPIO input/output뿐 아니라 UART, SPI, timer 같은 peripheral signal의 `alternate function`으로도 쓸 수 있다. `MODER`에서 alternate function mode를 고르고, `AFRL` 또는 `AFRH`에서 해당 pin의 AF 번호를 선택한다. 사용할 수 있는 AF는 MCU와 pin마다 다르므로 datasheet의 alternate function mapping을 확인함.

pin을 port 단위로 묶으면 software는 package pin 번호를 일일이 기억하지 않고 `GPIOA`의 bit 5처럼 register와 bit 위치로 제어할 수 있다.

### 하드웨어와 소프트웨어의 공유 지점

하드웨어와 소프트웨어는 register를 통해 소통한다. register는 기능이 미리 약속된 memory이며, 소프트웨어가 값을 쓰면 하드웨어 동작이 바뀌고, 하드웨어가 상태를 저장하면 소프트웨어가 그 값을 읽는다.

GPIO 출력 제어에서 기본적으로 확인한 register는 다음과 같음.

| register | 주소 또는 offset | 역할 |
| :--- | :--- | :--- |
| `RCC_AHB1ENR` | `0x40023830`, offset `0x30` | GPIOA peripheral clock enable |
| `GPIOA_MODER` | `0x40020000`, offset `0x00` | pin mode 설정 |
| `GPIOA_OTYPER` | `0x40020004`, offset `0x04` | output type 설정 |
| `GPIOA_ODR` | `0x40020014`, offset `0x14` | output data 설정 |

`RCC_AHB1ENR`의 `GPIOAEN` bit를 먼저 켜야 GPIOA register가 clock을 받아 동작한다. 실제 register address, offset, bit field는 `RM0383` reference manual을 기준으로 확인함.

공식 기준: [ST RM0383 STM32F411xC/E Reference Manual](https://www.st.com/resource/en/reference_manual/rm0383-stm32f411xce-advanced-armbased-32bit-mcus-stmicroelectronics.pdf)

### `GPIOx_MODER`

`GPIOx_MODER`는 각 pin의 mode를 2bit씩 설정한다.

| 값 | mode |
| :--- | :--- |
| `00` | Input |
| `01` | General purpose output |
| `10` | Alternate function |
| `11` | Analog |

PA5는 5번 pin이므로 `GPIOA_MODER[11:10]`에 해당한다. PA5를 GPIO output으로 쓰려면 해당 2bit에 `01`을 기록함.

`MODER`는 pin 하나당 2bit를 사용하므로 pin 번호와 bit 위치가 다음처럼 대응된다.

```text
GPIOA_MODER bit field

bit 31                                      bit 0
  |                                          |
  v                                          v
+------+------+-----+------+------+------+------+
| PA15 | PA14 | ... | PA7  | PA6  | PA5  | ...  |
|31:30 |29:28 |     |15:14 |13:12 |11:10 |      |
+------+------+-----+------+------+------+------+

PA5 output mode:
  GPIOA_MODER[11:10] = 01
```

### `GPIOx_OTYPER`

`GPIOx_OTYPER`는 출력으로 설정된 pin의 출력 type을 1bit씩 설정한다.

| 값 | output type |
| :--- | :--- |
| `0` | Push-Pull |
| `1` | Open-Drain |

PA5를 push-pull로 쓰려면 `GPIOA_OTYPER[5] = 0`으로 설정한다.

Push-Pull은 0 또는 1을 적극적으로 출력하는 방식이고, Open-Drain은 0 또는 floating 상태를 만드는 방식이다. 일반적인 digital output은 push-pull이 편하고, active-low LED처럼 0V를 on/off하는 목적에서는 open-drain이 유리할 수 있음.

### `GPIOx_ODR`

`GPIOx_ODR`는 output pin의 output value를 설정한다. PA5를 high로 만들려면 `GPIOA_ODR[5] = 1`을 기록한다.

Nucleo-64 board의 User LED는 PA5에 연결되어 있고, PA5가 high가 되면 LED가 켜지는 구조다.

```text
PA5 MODER[11:10] = 01  -> GPIO output
PA5 OTYPER[5]    = 0   -> push-pull
PA5 ODR[5]       = 1   -> high output, LED ON
```

PA5 User LED는 active-high 구조로 이해하면 된다.

```text
GPIOA_ODR[5] = 1
        |
        v
PA5 = 3.3V ---- R ---->| ---- GND
                       LED

결과: LED ON

GPIOA_ODR[5] = 0
        |
        v
PA5 = 0V

결과: LED OFF
```

### 출력 설정 순서와 외부 LED 비교

GPIO output은 `MODER`로 역할을 선택하고, `OTYPER`로 driver 방식을 선택한 뒤, `ODR`에 실제 output level을 기록하는 순서로 준비한다.

```text
1. MODER: general-purpose output 선택
2. OTYPER: push-pull 또는 open-drain 선택
3. ODR: output level을 0 또는 1로 기록
```

| 회로 | `MODER` | `OTYPER` | LED on일 때 ODR | 핵심 |
| :--- | :--- | :--- | :--- | :--- |
| PA5 User LED | output `01` | push-pull `0` | `1` | active-high |
| PA5~PA7 외부 LED | output `01` | open-drain `1` | `0` | active-low |

Open-drain에서 `ODR = 0`이면 N-channel switch가 동작하여 low를 만든다. `ODR = 1`이면 high를 직접 출력하지 않고 pin을 release한다. 따라서 external LED를 active-low로 연결한 경우 논리 LED 값과 실제 ODR 값은 반대가 된다. PA5부터 세 pin을 연속으로 사용할 때 PA5·PA6·PA7의 mode field는 각각 `MODER[11:10]`·`[13:12]`·`[15:14]`임.

#### GPIO output을 회로로 읽기

GPIO output driver 안에는 위쪽 전원 쪽으로 연결하는 P-channel MOSFET과 아래쪽 GND 쪽으로 연결하는 N-channel MOSFET이 있다. software가 `ODR`에 쓴 값은 이 driver가 어느 쪽을 연결할지 결정하는 입력이다.

```text
push-pull, ODR = 1                 push-pull, ODR = 0

VDD -- P-channel ON -- pin         VDD -- P-channel OFF -- pin
                         |                                  |
                      external load                       N-channel ON
                         |                                  |
                        GND                                GND

pin을 high로 source                   pin을 low로 sink
```

| output mode | GPIO가 직접 하는 일 | 외부 회로에 필요한 것 | 대표 용도 |
| :--- | :--- | :--- | :--- |
| push-pull high | VDD 쪽으로 전류 공급 | load의 GND return path | 일반 LED, digital output |
| push-pull low | GND 쪽으로 전류 흡수 | load의 VDD source path | 일반 LED, digital output |
| open-drain low | GND 쪽으로만 전류 흡수 | pull-up 또는 VDD 쪽 load | active-low LED, I2C |
| open-drain release | 두 switch를 끔 | external pull-up이 high 결정 | 여러 장치 공유 bus |

`source`와 `sink`는 전류 관점의 말이다. GPIO가 high일 때 load 쪽으로 전류를 내보내면 source, GPIO가 low일 때 load에서 온 전류를 GND로 받아들이면 sink다. datasheet의 pin 최대 source/sink current와 port 전체 전류 제한을 넘기지 않도록 LED에는 resistor를 둔다.

### Memory-Mapped I/O와 직접 주소 접근

GPIO는 ARM CPU core의 memory bus에 연결된 주변장치다. 주변장치 내부 register는 CPU 입장에서 memory처럼 주소를 가진다. 이런 구조를 `Memory-Mapped I/O`라고 한다.

C code에서는 pointer와 casting을 이용해 특정 주소의 register를 직접 접근할 수 있다.

설명용 예시는 `0x1000` 주소에 `100`을 기록하는 과정이었다.

```c
int *p = (int *)0x1000;
*p = 100;
```

위 code는 같은 주소를 바로 역참조하는 다음 한 줄로 줄여 쓸 수 있다.

```c
*(int *)0x1000 = 100;
```

`#define`으로 주소 접근 표현을 감추면 이후 code의 의미가 조금 더 분명해진다.

```c
#define TEMP (*(int *)0x1000)

TEMP = TEMP + 100;
```

하드웨어 register 접근에서는 실제로는 `volatile`을 붙여야 한다.

```c
#define RCC_AHB1ENR (*(volatile unsigned int *)0x40023830)
#define GPIOA_MODER (*(volatile unsigned int *)0x40020000)
#define GPIOA_OTYPER (*(volatile unsigned int *)0x40020004)
#define GPIOA_ODR (*(volatile unsigned int *)0x40020014)
```

`volatile`은 하드웨어 register처럼 프로그램 외부에서 값이 바뀌거나 접근 자체가 의미를 가지는 대상에 필요하다. compiler가 register 접근을 임의로 제거하거나 합치지 않도록 막는 역할을 함.

register 접근에서는 `volatile`만으로 모든 문제가 해결되지는 않는다. 접근 폭은 register 정의와 맞아야 하고, clock enable이 꺼진 peripheral에 접근하면 기대한 동작이 나오지 않을 수 있다. 또한 read-to-clear, write-one-to-clear처럼 읽기나 쓰기 자체가 side effect를 가지는 bit가 있으므로 reference manual의 bit 설명을 기준으로 code를 작성해야 한다.

### C로 register를 제어할 때 필요한 기초

이 수업의 bare-metal register 실습은 C를 기준으로 한다. C와 C++는 vendor header, compiler, debugger 지원이 널리 갖춰져 있어 MCU firmware에 많이 사용되며, pointer와 casting으로 고정된 hardware address를 표현할 수 있다. Rust 같은 언어도 적절한 toolchain과 HAL 또는 `unsafe` 접근을 통해 MMIO를 다룰 수 있음.

| C 개념 | register 제어에서 하는 일 |
| :--- | :--- |
| pointer와 casting | 고정 peripheral address를 pointer로 표현 |
| dereference `*` | 그 주소의 register를 읽거나 쓰는 lvalue 생성 |
| `volatile` | compiler가 hardware 접근을 생략·합치지 않도록 제어 |
| shift·bitwise 연산 | register 안의 필요한 bit field만 변경 |
| macro | address와 bit mask의 의미 있는 이름 부여 |

예를 들어 `*(volatile unsigned int *)0x40020000`은 `0x40020000`을 GPIOA register address로 해석하고, 그 위치를 읽거나 쓸 수 있는 C expression을 만든다. 실제 hardware 제어에서는 address, register 폭, bit field를 해당 MCU reference manual과 일치시켜야 함.

### PA5 User LED ON code 흐름

PA5 User LED를 켜기 위한 최소 흐름은 다음과 같다.

```text
1. `RCC_AHB1ENR`에서 GPIOA clock을 enable
2. `GPIOA_MODER`에서 PA5 mode를 output으로 설정
3. `GPIOA_OTYPER`에서 PA5 output type을 push-pull로 설정
4. `GPIOA_ODR`에서 PA5 output data를 high로 설정
```

bit 위치는 다음과 같다.

```text
GPIOA clock  -> RCC_AHB1ENR[0]
PA5 mode     -> GPIOA_MODER[11:10]
PA5 type     -> GPIOA_OTYPER[5]
PA5 output   -> GPIOA_ODR[5]
```

자료의 빈칸 채우기 형태를 완성하면 다음과 같은 code가 된다.

```c
#define RCC_AHB1ENR (*(volatile unsigned int *)0x40023830)
#define GPIOA_MODER (*(volatile unsigned int *)0x40020000)
#define GPIOA_OTYPER (*(volatile unsigned int *)0x40020004)
#define GPIOA_ODR (*(volatile unsigned int *)0x40020014)

void Main(void)
{
    /* GPIOA peripheral clock enable */
    RCC_AHB1ENR |= (0x1u << 0);

    /* PA5를 GPIO output mode로 설정 */
    GPIOA_MODER &= ~(0x3u << 10);
    GPIOA_MODER |= (0x1u << 10);

    /* PA5를 push-pull output으로 설정 */
    GPIOA_OTYPER &= ~(0x1u << 5);

    /* PA5에 high 출력, Nucleo User LED ON */
    GPIOA_ODR |= (0x1u << 5);
}
```

### PA7 외부 LED 과제

과제는 외부 LED를 PA7에 연결하고 ON/OFF를 제어하는 내용이다. 회로 조건은 LED가 active-low가 되도록 구성하는 방식이다.

| 항목 | 내용 |
| :--- | :--- |
| 연결 pin | `PA7` |
| LED ON 조건 | PA7에서 `0` 출력 |
| LED OFF 조건 | PA7을 floating 또는 high 상태로 둠 |
| 구현 출력 타입 | Open-Drain |

이 외부 LED는 push-pull이 아니라 open-drain 방식으로 구현한다. Active-low 구조에서는 LED를 켤 때 `0`을 출력한다. LED를 끌 때 반드시 `1`을 적극적으로 출력할 필요는 없고, open-drain으로 floating 상태를 만들면 연결을 끊는 효과를 낼 수 있다.

| 대상 | 연결 논리 | `OTYPER` 설정 | `ODR = 0` | `ODR = 1` |
| :--- | :--- | :--- | :--- | :--- |
| PA5 User LED | Active-High | `0`, Push-Pull | Low 출력, LED OFF | High 출력, LED ON |
| PA7 외부 LED | Active-Low | `1`, Open-Drain | Low로 끌어내림, LED ON | High impedance로 release, LED OFF |

`OTYPER = 1`인 open-drain pin은 `ODR = 1`이어도 high 전압을 직접 출력하지 않는다. 출력 transistor를 끄고 pin을 release하며, 회로의 저항과 LED 연결이 off 상태를 만든다.

PA7 설정 방향은 다음과 같다.

```text
PA7 MODER[15:14] = 01  -> GPIO output
PA7 OTYPER[7]    = 1   -> open-drain
PA7 ODR[7]       = 0   -> active-low LED ON
PA7 ODR[7]       = 1   -> open-drain floating, LED OFF
```

과제 조건을 코드로 옮기면 다음과 같은 형태가 된다.

```c
#define GPIOA_MODER (*(volatile unsigned int *)0x40020000)
#define GPIOA_OTYPER (*(volatile unsigned int *)0x40020004)
#define GPIOA_ODR (*(volatile unsigned int *)0x40020014)

void Main(void)
{
    /* PA7을 GPIO output mode로 설정 */
    GPIOA_MODER &= ~(0x3u << 14);
    GPIOA_MODER |= (0x1u << 14);

    /* PA7을 open-drain output으로 설정 */
    GPIOA_OTYPER |= (0x1u << 7);

    /* active-low 외부 LED ON */
    GPIOA_ODR &= ~(0x1u << 7);

    /* active-low 외부 LED OFF: open-drain에서는 floating 효과 */
    GPIOA_ODR |= (0x1u << 7);
}
```

## Type Qualifier와 `volatile`

### LED Toggling과 최적화 문제

LED를 일정 시간마다 켰다 끄는 단순한 코드도 컴파일러 최적화의 영향을 받을 수 있다. 아래 코드는 delay를 위해 `for` loop를 사용하지만, loop 내부에 의미 있는 작업이 없으면 최적화 단계에서 제거되거나 축약될 수 있음.

```c
#define GPIOA_MODER (*(unsigned long *)0x40020000)
#define GPIOA_OTYPER (*(unsigned long *)0x40020004)
#define GPIOA_ODR (*(unsigned long *)0x40020014)

void Main(void)
{
    int i;

    GPIOA_MODER = 0x1u << 10;
    GPIOA_OTYPER = 0x0u << 5;

    for (;;)
    {
        GPIOA_ODR = 0x1u << 5;
        for (i = 0; i < 0x40000; i++)
            ;

        GPIOA_ODR = 0x0u << 5;
        for (i = 0; i < 0x40000; i++)
            ;
    }
}
```

컴파일러는 `i` 증가 loop가 최종 결과에 영향을 주지 않는다고 판단하면 delay loop를 제거할 수 있다. 최적화 레벨을 낮추는 방법도 있지만, 프로그램 전체 성능에 영향을 줄 수 있으므로 delay loop 변수에 `volatile`을 적용하는 방식으로 설명되었다.

### 최적화 레벨을 바꾸는 방법과 한계

compiler는 C source에서 관측 가능한 동작을 유지하는 범위에서 code를 변환한다. 빈 delay loop는 외부에 보이는 결과가 없으므로, optimization level이 높을 때 제거하거나 크게 축약할 수 있다. 이 경우 LED의 깜박임 간격처럼 사람이 기대한 timing 결과가 달라질 수 있음.

이는 compiler가 C 언어의 약속을 임의로 어긴 것이 아니다. delay라는 의도가 빈 loop 자체에는 충분히 표현되지 않았기 때문에 생기는 차이다.

| 방법 | 기대 효과 | 한계 |
| :--- | :--- | :--- |
| optimization level 낮춤 또는 OFF | loop 변형 가능성 감소 | 프로그램 전체 speed·code size·전력 효율 저하 가능 |
| 필요한 객체에 `volatile` 적용 | 해당 read/write를 생략·재사용하지 않도록 제한 | 일반적인 시간 지연 기능은 아님 |
| hardware timer 또는 SysTick 사용 | hardware 기준의 시간 간격 생성 | timer 설정과 interrupt·polling 구조 필요 |

`volatile` delay loop는 compiler optimization과 hardware access의 관계를 이해하기 위한 예시다. 실제 firmware에서 일정 시간 대기가 필요하면, 빈 loop의 반복 횟수보다 timer 또는 SysTick을 기준으로 구현하는 편이 안정적임.

```c
volatile int i;

for (;;)
{
    GPIOA_ODR = 0x1u << 5;
    for (i = 0; i < 0x40000; i++)
        ;

    GPIOA_ODR = 0x0u << 5;
    for (i = 0; i < 0x40000; i++)
        ;
}
```

### `volatile`

`volatile`은 해당 객체가 프로그램 코드 밖의 요인으로 바뀔 수 있음을 컴파일러에게 알려주는 type qualifier다. 하드웨어 레지스터, DMA, interrupt service routine, 멀티 프로세스 공유 메모리처럼 컴파일러가 값 변화를 직접 추적할 수 없는 대상에 사용함.

#### Compiler가 모르는 외부 변경

`volatile`은 특정 code 줄의 optimization을 전부 끄는 선언이 아니다. `volatile`이 붙은 객체를 읽거나 쓰는 access에만 적용되며, compiler는 그 access를 생략하거나 이전에 읽은 값으로 대체하지 않아야 한다. 같은 함수의 다른 계산은 계속 최적화할 수 있음.

일반 RAM 변수는 compiler가 source code 안의 write를 따라가며 값 변화를 추론한다. 하지만 timer·ADC 같은 peripheral register는 CPU code와 무관하게 hardware가 바꾸고, DMA·ISR·다른 CPU나 process도 memory를 바꿀 수 있다. compiler는 그런 외부 변경을 source만 보고 알 수 없으므로, 같은 주소를 한 번 읽은 뒤 그 값을 재사용해도 된다고 판단할 수 있음.

영어 단어 `volatile`은 '휘발성의'와 '쉽게 변하는·불안정한'을 뜻한다. C의 `volatile`은 두 번째 뉘앙스를 가져와, compiler가 값이 계속 유지된다고 가정하면 안 되는 객체를 표시한다.

| 표현 | 이 수업에서의 연결 |
| :--- | :--- |
| '휘발성의' | 액체 등이 쉽게 증발하는 성질 |
| '변하기 쉬운·불안정한' | 상태가 외부 요인에 따라 달라질 수 있음 |
| C `volatile` | compiler가 이전에 읽은 값을 그대로 믿으면 안 되는 객체 |

'잘 바뀌는 값'이라고 외우는 것은 출발점으로 괜찮다. 정확한 C 해석은 '값이 바뀔 수 있으므로 compiler가 접근을 생략하거나 이전 값으로 대체하면 안 되는 객체'다. 따라서 `volatile` access는 source code에 쓴 read/write가 실제 hardware access로 평가되도록 유지해야 함.

`volatile`은 값이 반드시 계속 바뀐다는 선언도 아니고, atomic operation·lock·thread 동기화를 보장하는 기능도 아니다. 하드웨어 register의 값 변화를 놓치지 않도록 compiler 최적화의 가정을 제한하는 qualifier다.

`volatile`이 필요한 상황을 그림으로 보면 다음과 같다.

```text
일반 변수

C 코드 ---- read/write ---- RAM
  |
  +-- 컴파일러가 값 변화 흐름을 대부분 추적 가능


하드웨어 레지스터

C 코드 ---- read/write ---- TIMER register
                         ^
                         |
                  hardware가 계속 값 변경

컴파일러는 hardware 변경을 모르므로 volatile 필요
```

compiler와 target hardware에 따라 세부 동작은 다르지만, 일반적으로 다음 경우에 `volatile`을 사용한다.

| 경우 | CPU 밖의 변경 주체 | `volatile`의 역할과 추가 고려 |
| :--- | :--- | :--- |
| Memory-Mapped I/O | timer·ADC·GPIO 등 peripheral hardware | register access 유지, register 폭은 reference manual과 일치 |
| DMA 전송 buffer | DMA controller | CPU가 보지 못한 memory 변경을 다시 읽음, cache 관리가 필요한 system도 있음 |
| ISR 공유 변수 | interrupt handler | main과 ISR의 access 유지, 복합 연산은 atomicity 또는 interrupt 제어 검토 |
| multi-process·multi-CPU 공유 memory | 다른 process·CPU·장치 | access 유지만 담당, memory barrier·atomic·cache coherency도 필요 가능 |

peripheral register는 `volatile unsigned`처럼 `volatile`이 붙은 type으로 정의하되, 실제 type의 폭은 register 폭과 맞춰야 한다. 예를 들어 16bit register라면 `volatile unsigned short`, 32bit register라면 `volatile unsigned int` 또는 `volatile uint32_t`처럼 선언함.

다음은 timer register가 CPU code 밖에서 증가할 수 있음을 보여 주는 설명용 예시다.

```c
#define TMR0 (*(volatile unsigned short *)0x1000u)

TMR0 = 0u;
if (TMR0 > 50u)
{
    report();
}
```

`volatile`이 없다면 compiler는 `TMR0 = 0u` 뒤에 같은 주소를 다시 읽을 필요가 없다고 판단할 수 있다. 실제 timer는 그 사이에도 증가할 수 있으므로, `if` 조건에서 register를 다시 읽도록 `volatile` 선언이 필요함.

System Timer 현재값 레지스터 예시는 다음과 같다. `0xE000E018` 주소의 값은 timer가 구동되는 동안 계속 바뀌므로 `volatile`이 없으면 컴파일러가 값을 한 번만 읽고 재사용할 수 있다.

```c
#define TIMER (*(volatile unsigned long *)0xE000E018)

void Main(void)
{
    unsigned long a[10];
    int i;

    SysTick_Run();

    for (i = 0; i < 10; i++)
    {
        a[i] = TIMER;
    }

    for (i = 0; i < 10; i++)
    {
        Uart_Printf("%d => %#.8x\n", i, a[i]);
    }
}
```

#### Timer Access 실습: 출력문을 빼면 왜 값이 같아질까

[`0601.TYPE_QUALIFIER_EX/main.c`](../helloEmbedded/0601.TYPE_QUALIFIER_EX/main.c)의 Timer Access 실습은 같은 System Timer 주소를 열 번 읽는 code를 세 가지로 비교한다. System Timer가 동작하는 동안 `0xE000E018`의 현재값은 계속 감소하지만, compiler는 그 주소가 hardware register라는 사실을 source만 보고 알 수 없음.

| 실습 | code 형태 | 관찰할 핵심 |
| :--- | :--- | :--- |
| Timer Access #1 | `a[i] = TIMER` 직후 매번 `printf` | 함수 호출 사이에서 값이 달라져 보일 수 있음. 이 결과만으로 매 read가 보장된 것은 아님 |
| Timer Access #2 | 열 번 읽어 array에 넣은 뒤 나중에 한꺼번에 출력 | compiler가 한 번 읽은 값을 재사용하면 array의 값이 모두 같아질 수 있음 |
| Timer Access #3 | `TIMER`를 `volatile unsigned long`으로 선언 | 각 source-level read를 유지해야 하므로 timer의 변화가 array에 반영됨 |

`printf`를 넣었을 때 증상이 사라지는 이유를 단순한 delay 효과로 해석하면 안 된다. 외부 함수를 호출하면 compiler가 그 사이의 memory 상태를 완전히 추론하기 어려워져 최적화 결과가 달라질 수 있다. 출력문을 지우면 다시 실패하는 code는 timing을 늘려 고칠 문제가 아니라, hardware register access에 `volatile`을 빠뜨린 문제로 먼저 점검해야 함.

GPIO 레지스터 정의도 `volatile unsigned long`으로 작성해야 한다.

```c
#define GPIOA_MODER (*(volatile unsigned long *)0x40020000)
#define GPIOA_OTYPER (*(volatile unsigned long *)0x40020004)
#define GPIOA_ODR (*(volatile unsigned long *)0x40020014)
```

### DMA와 `volatile`

DMA는 `Direct Memory Access`의 약어다. CPU가 배열 복사 loop를 직접 실행하는 대신, DMA controller에 data 이동 작업을 맡기면 CPU는 전송이 끝나는 동안 다른 일을 할 수 있음.

```text
CPU
  -> source 주소, destination 주소, 전송 단위, 전송 횟수, 주소 mode 설정
  -> DMA 시작

DMA controller
  -> memory bus를 얻어 data 이동
  -> 완료 interrupt 또는 상태 bit 갱신

CPU
  -> 완료를 확인한 뒤 다음 처리
```

DMA는 개별 data를 무조건 더 빨리 옮기는 장치라는 뜻은 아니다. DMA와 CPU는 memory bus를 함께 사용하므로 bus arbitration과 전송 단위에 따라 기다림이 생긴다. 핵심 이점은 긴 data 이동 동안 CPU가 복사 loop에 묶이지 않고 다른 작업을 할 수 있어 system 전체 효율이 높아진다는 점이다.

DMA 설정에는 source와 destination의 주소, 한 번에 옮길 data 폭, 전송 횟수, 각 주소를 고정할지 증가시킬지를 지정한다.

| 전송 예 | source 주소 mode | destination 주소 mode | 이유 |
| :--- | :--- | :--- | :--- |
| memory buffer → UART TX data register | increment | fixed | buffer의 다음 byte를 읽되, UART 송신 register는 같은 주소에 계속 씀 |
| UART RX data register → memory buffer | fixed | increment | 같은 UART 수신 register를 읽어 buffer의 다음 위치에 저장 |
| camera buffer → LCD frame buffer | increment | increment | source와 destination 모두 연속된 frame data를 순서대로 사용 |

DMA가 memory를 바꾸는 동안 CPU source code에는 그 write가 나타나지 않는다. 따라서 CPU가 DMA buffer나 완료 flag를 polling한다면 compiler가 이전 값을 계속 재사용하지 않도록 `volatile`을 검토해야 한다. 완료 interrupt와 main loop가 공유하는 flag의 개념 예시는 다음과 같다.

```c
static volatile unsigned int dma_done;

void DMA_IRQHandler(void)
{
    /* DMA 완료 상태를 정리한 뒤 */
    dma_done = 1u;
}

void WaitForDma(void)
{
    while (dma_done == 0u)
        ;
}
```

여기서 `volatile`은 `dma_done`이 계속 0이라고 compiler가 가정하지 못하게 한다. 전송 buffer의 atomicity, CPU와 DMA의 접근 순서, cache가 있는 system의 cache coherency까지 자동으로 해결하는 기능은 아니므로, 대상 MCU와 driver 구조에 맞는 동기화도 함께 확인해야 함.

### `const`

`const`는 변수나 포인터가 가리키는 값을 read-only로 취급하도록 제한한다. 특히 call by address에서 호출된 함수가 원본 데이터를 바꾸지 못하도록 할 때 유용함.

```c
const int a = 10;
/* a = 100; */  /* error */
```

포인터와 함께 사용할 때는 `const`가 붙는 위치에 따라 의미가 달라진다.

| 선언 | 의미 | 금지되는 대표 동작 |
| :--- | :--- | :--- |
| `int const *p` | `p`가 가리키는 값 변경 금지 | `*p = 100` |
| `const int *p` | `int const *p`와 동일 | `*p = 100` |
| `int *const p` | 포인터 변수 `p` 자체 변경 금지 | `p = address`, `p++` |
| `int const *const p` | 포인터와 대상 값 모두 변경 금지 | `p = address`, `p++`, `*p = 100` |

#### 포인터 `const` 연산 판정

다음 표는 `int a;`가 선언되어 있고 각 문장을 qualifier 규칙만 기준으로 따로 판정한 결과다. `const int *p`와 `int const *p`는 완전히 같은 선언임.

| 선언 | `p = (int *)0x1000;` | `p++;` | `*p = 100;` | `a = *p;` |
| :--- | :--- | :--- | :--- | :--- |
| `int const *p` | 가능 | 가능 | error: 가리킨 `int`가 `const` | 가능 |
| `int *const p` | error: `p` 자체가 `const` | error: `p` 자체가 `const` | 가능 | 가능 |
| `int const *const p` | error: `p`와 가리킨 `int` 모두 `const` | error: `p` 자체가 `const` | error: 가리킨 `int`가 `const` | 가능 |
| `const int *p` | 가능 | 가능 | error: 가리킨 `int`가 `const` | 가능 |

`const` pointer는 주소를 나중에 대입할 수 없으므로 보통 선언과 동시에 초기화한다.

```c
int *const writable_address = (int *)0x1000;
int const *const read_only_address = (int *)0x1000;
```

`a = *p`는 값을 읽기만 하므로 네 경우 모두 허용된다. 반면 `0x1000` 같은 임의 address가 실제로 읽기·쓰기 가능한지는 별도 문제다. MCU에서는 해당 address가 유효한 memory-mapped register 또는 RAM이어야 하며, register라면 access 폭과 `volatile` 여부도 맞춰야 함.

#### 포인터 type을 단계적으로 추적하기

포인터 식의 type은 선언에서 `*`를 한 단계씩 적용해 확인할 수 있다. 예를 들어 `int **p`는 `int`를 가리키는 pointer를 다시 가리키는 pointer다.

| 식 | type | 이유 |
| :--- | :--- | :--- |
| `p` | `int **` | `p`는 `int *`를 가리킴 |
| `*p` | `int *` | pointer 한 겹을 벗김 |
| `**p` | `int` | pointer 두 겹을 벗김 |
| `***p` | compiler error | `**p`는 이미 `int`이므로 다시 역참조할 pointer가 없음 |

배열 선언은 `[]`가 `*`보다 먼저 결합하므로 괄호를 함께 봐야 한다.

| 선언 | 의미 | `*p`의 type | element 접근 |
| :--- | :--- | :--- |
| `int *p[4]` | `int *` 4개로 이루어진 array | `int *` | `*p`는 `p[0]`, `*p[0]`은 `*(p[0])`이므로 `int` |
| `int (*p)[4]` | `int` 4개로 이루어진 array를 가리키는 pointer | `int [4]` | `(*p)[0]`은 `int` |

따라서 `*p`가 `int [4]`가 되는 정확한 선언은 `int (*p)[4]`다. `int *p[4]`에서 `p`의 선언 type은 `int *[4]`이며, 일반 expression 안에서는 첫 element를 가리키는 `int **`로 변환되어 사용됨.

#### Call by address에서 원본 배열이 바뀌는 이유

C의 함수 인자는 항상 값으로 전달된다. call by address는 '주소값을 값으로 복사해 전달한다'는 뜻으로 이해하면 정확하다. `sum(a)`를 호출하면 array 이름 `a`는 첫 element의 주소로 변환되고, 그 주소값이 함수의 parameter `p`에 복사됨.

```text
main                                      sum 함수

a[0], a[1], a[2], ...                     p
  ^                                        |
  +------------- 같은 주소 ---------------+
```

`p`라는 pointer 변수는 함수 안에 새로 생긴 복사본이지만, `p[i]`가 가리키는 memory는 호출한 쪽의 `a[i]`다. 따라서 일반 `int *p` parameter로 write하면 원본 array도 바뀜.

```c
int sum_and_clear(int *p)
{
    int i;
    int s = 0;

    for (i = 0; i < 5; i++)
    {
        s += p[i];
        p[i] = 0;      /* 호출한 쪽 array도 0으로 바뀜 */
    }

    return s;
}

int main(void)
{
    int a[5] = { 1, 2, 3, 4, 5 };
    int s = sum_and_clear(a);

    /* s는 15, a는 { 0, 0, 0, 0, 0 } */
}
```

#### 읽기 전용 input에는 `const int *`

합계처럼 input을 읽기만 하는 함수는 `int *p`보다 `const int *p`로 parameter를 선언한다. 이는 '주소는 받지만 이 함수는 그 주소를 통해 원본 data를 바꾸지 않는다'는 interface 약속이다.

```c
int sum(const int *p)
{
    int i;
    int s = 0;

    for (i = 0; i < 5; i++)
    {
        s += p[i];
        /* p[i] = 0; */  /* const 때문에 원본 변경 불가 */
    }

    return s;
}
```

`const int *p`에서는 `p[i]`를 읽을 수 있고 `p++`처럼 함수 안의 pointer 위치를 옮길 수도 있다. 반면 `p[i] = 0`과 `*p = 0`은 compiler diagnostic이 발생한다. pointer 자체를 고정하는 `int *const p`와 목적이 다르므로, 읽기 전용 input parameter에는 보통 `const int *p`를 사용함.

| 함수의 역할 | parameter 예 | 호출한 쪽 data에 대한 약속 |
| :--- | :--- | :--- |
| 합계·비교·출력처럼 읽기만 함 | `const int *p` | `p`를 통한 원본 변경 금지 |
| buffer를 채우거나 값을 수정함 | `int *p` | 원본 변경 가능 |
| 한 buffer에서 다른 buffer로 복사 | `int *dst`, `const int *src` | destination 수정, source 읽기 전용 |

`const int *p`는 원본 object를 전 세계적으로 얼리는 선언은 아니다. 호출한 쪽은 여전히 자기 `int a[]`를 직접 바꿀 수 있고, 다른 writable pointer도 같은 object를 바꿀 수 있다. 제한되는 것은 이 함수 안에서 `p`를 통한 write다.

#### 전달받은 `const` 주소를 writable pointer로 바꾸지 않기

`const int *`를 `int *`에 대입하면 const qualifier를 버리는 것이므로 compiler가 warning 또는 error를 낸다. 강제 casting으로 diagnostic을 숨길 수는 있지만, 읽기 전용이라는 interface 약속을 깨므로 수정 방법으로 사용하면 안 됨.

```c
void inspect(const int *src)
{
    /* int *p = src; */        /* const qualifier를 버려 diagnostic */
    /* int *p = (int *)src; */ /* 강제 cast는 약속을 깨므로 사용하지 않음 */
}
```

특히 실제 object가 `const int value`처럼 선언된 대상이라면, cast 뒤 write는 undefined behavior다. `const`가 붙은 input은 읽기 전용으로 유지하는 것이 기준임.

#### `const`와 compiler optimization

`const int *p`는 compiler에게 '이 함수는 `p`를 통해 값을 쓰지 못한다'는 제약을 알려 준다. write 가능한 경로가 줄어들어 compiler의 code 분석과 inlining·최적화에 도움이 될 수 있고, 무엇보다 실수로 원본을 훼손하는 code를 compile 단계에서 막을 수 있음.

| 구분 | `const int *p`가 말하는 것 | 말하지 않는 것 |
| :--- | :--- | :--- |
| 수정 권한 | 이 함수는 `p`를 통해 write하지 않음 | 다른 pointer나 다른 함수의 write까지 금지하지 않음 |
| optimization | 분석할 write 경로 감소 가능 | 실행 speed 향상 보장 아님 |
| 값 변화 | 이 함수의 `p` write 금지 | 다른 alias·DMA·hardware에 의한 변화 부정 아님 |

따라서 `const`는 성능을 얻기 위해 임의로 붙이는 keyword가 아니라, 함수가 실제로 지킬 data access 약속을 type에 적는 방법이다. 성능 향상은 그 약속이 compiler 분석에 도움이 될 때 따라올 수 있는 부가 효과다.

`volatile`과도 역할이 다르다. `const`는 CPU code의 write를 금지하고, `volatile`은 hardware나 다른 실행 흐름 때문에 값이 바뀔 수 있으므로 read를 생략하지 못하게 한다. CPU가 쓰지 못하지만 hardware가 바꿀 수 있는 status register는 `const volatile`처럼 두 qualifier를 함께 가질 수 있음.

### CMSIS 방식의 레지스터 정의

CMSIS는 `Cortex Microcontroller Software Interface Standard`의 약어다. Arm이 Cortex-M core register의 공통 interface와 header 작성 규칙을 정의하고, MCU 제조사는 그 CMSIS 방식에 맞춘 target별 device header로 자기 peripheral register map을 제공한다. 물리 address를 없애는 규정이 아니라, 같은 register map을 구조체와 access qualifier로 표현해 code가 address 계산을 직접 반복하지 않도록 만드는 규정임.

#### 개별 주소 macro와 peripheral group

초기 direct access 방식은 각 register마다 address와 type을 따로 적는다.

```c
#define GPIOA_MODER (*(volatile unsigned long *)0x40020000)
#define GPIOA_OTYPER (*(volatile unsigned long *)0x40020004)
#define GPIOA_ODR (*(volatile unsigned long *)0x40020014)
```

이 방식도 실제 hardware를 정확히 제어할 수 있다. 다만 `GPIOA`라는 한 peripheral의 register가 여러 macro로 흩어지고, address offset·access type·register 순서를 사람이 계속 맞춰야 함.

CMSIS device header는 register 순서와 offset을 구조체 member로 묶고, peripheral base address에 그 구조체 pointer를 연결한다.

따라서 C code에서는 header가 정의한 `장치명->레지스터명` 형식으로 접근할 수 있다. `GPIOA`는 GPIOA peripheral을 가리키는 pointer이고, `MODER`는 그 구조체 안의 mode register member이므로 `GPIOA->MODER`는 'GPIOA 장치의 MODER register'를 뜻함.

| 접근 방식 | code 형태 | 관리 기준 |
| :--- | :--- | :--- |
| 개별 macro | `GPIOA_MODER = value;` | register마다 address와 type 작성 |
| CMSIS 구조체 | `GPIOA->MODER = value;` | `GPIOA` group과 member 이름·offset 정의 |

두 표현은 결국 같은 memory-mapped address에 접근한다. CMSIS 방식은 `GPIOA->MODER`라는 이름만 보고도 'GPIOA block의 mode register'임을 알 수 있어 code review와 header 교체가 쉬움.

#### Register abstraction의 네 단계

CMSIS device header가 `장치명->레지스터명` 접근을 가능하게 만드는 핵심은 다음 네 단계를 분리한 데 있다. `typedef struct`는 hardware register의 순서·폭·access qualifier를 표현하는 type일 뿐, GPIOA의 복사본을 RAM에 만드는 선언은 아님.

| 단계 | header에 정의하는 것 | 역할 |
| :--- | :--- | :--- |
| 1. register layout | `GPIO_TypeDef` | member 순서와 각 register의 offset·access qualifier 표현 |
| 2. 물리 base address | `GPIOA_BASE` | GPIOA block이 시작하는 memory-mapped address 정의 |
| 3. typed pointer | `GPIOA` | `GPIOA_BASE`를 `GPIO_TypeDef *`로 해석 |
| 4. member access | `GPIOA->ODR` | pointer가 가리킨 block 안에서 `ODR` member offset만큼 접근 |

```c
#define GPIOA ((GPIO_TypeDef *)GPIOA_BASE)

GPIOA->ODR = value;
```

위 식은 개념적으로 다음 direct access와 같은 hardware 주소를 가리킨다. `ODR` member는 `GPIO_TypeDef`에서 base 기준 `0x14` offset에 있고 `__IO`로 선언되어 있으므로, `GPIOA->ODR`은 `GPIOA_BASE + 0x14`의 `volatile uint32_t` register access가 됨.

```c
/* 개념적으로 같은 대상 */
*(volatile uint32_t *)(GPIOA_BASE + 0x14u) = value;
```

이 구조는 header를 읽기 쉽게 만들고, 같은 역할의 peripheral을 다른 MCU로 옮길 때 바꿔야 할 address 정의를 한 곳으로 모은다. 다만 CMSIS가 서로 다른 제조사의 GPIO register bit와 기능까지 같게 만들지는 않는다. MCU를 바꿀 때에는 target device header, reference manual, clock·pin·alternate-function 설정을 함께 확인해야 함.

#### CMSIS access qualifier: `__I`, `__O`, `__IO`

현재 실습 source의 [`core_cm4.h`](../helloEmbedded/0601.TYPE_QUALIFIER_EX/core_cm4.h)는 peripheral register access를 다음처럼 정의한다. C source에서는 `__I`가 `volatile const`로 확장된다.

```c
#define __I   volatile const  /* software read only */
#define __O   volatile        /* software write only */
#define __IO  volatile        /* software read/write */

#define __IM  volatile const  /* structure member: read only */
#define __OM  volatile        /* structure member: write only */
#define __IOM volatile        /* structure member: read/write */
```

여기서 `I`, `O`, `IO`는 GPIO pin의 input·output mode가 아니라 CPU code가 register에 수행하는 access 방향이다.

| qualifier | C type 효과 | CPU code 관점 | 주의점 |
| :--- | :--- | :--- | :--- |
| `__I`, `__IM` | `volatile const` | read only | write는 compiler diagnostic, hardware가 값 변경 가능 |
| `__O`, `__OM` | `volatile` | write only | C type만으로 read를 막지는 못함 |
| `__IO`, `__IOM` | `volatile` | read/write | register bit의 실제 side effect는 reference manual 기준 |

`volatile`은 모든 경우에 hardware access를 유지하게 하고, `const`는 CPU code의 write만 금지한다. 예를 들어 CPU는 쓰지 못하지만 hardware가 갱신하는 status register는 `volatile const`가 적합함.

`__O`와 `__IO`는 현재 C type이 모두 `volatile`이므로, compiler가 write-only register read를 자동으로 막지는 않는다. register가 read-only·write-only·read-to-clear·write-one-to-clear 중 무엇인지는 header qualifier와 함께 MCU reference manual의 register 설명을 확인해야 함.

#### Core header와 STM32 device header의 역할

| header | 역할 | 현재 source의 예 |
| :--- | :--- | :--- |
| [`core_cm4.h`](../helloEmbedded/0601.TYPE_QUALIFIER_EX/core_cm4.h) | Cortex-M4 core register와 CMSIS qualifier | `SysTick_Type`, `__IM`, `__IOM` |
| [`stm32f411xe.h`](../helloEmbedded/0601.TYPE_QUALIFIER_EX/stm32f411xe.h) | STM32F411 peripheral 구조체·base address | `GPIO_TypeDef`, `GPIOA_BASE`, `GPIOA` |

보통 toolchain 또는 제조사 CMSIS device package가 이 두 header를 함께 제공한다. `core_cm4.h`만으로 STM32 GPIO register를 알 수 있는 것은 아니며, target MCU에 맞는 device header가 함께 필요함.

#### STM32F4 family header에서 target을 고르는 흐름

ST의 [`stm32f4xx.h`](../helloEmbedded/0601.TYPE_QUALIFIER_EX/stm32f4xx.h)는 여러 STM32F4 model이 공통으로 include하는 family header다. 이 실습 source에서는 `STM32F411xE` macro가 선택되어 있고, conditional compilation이 그 결과로 `stm32f411xe.h`를 include한다. 그러므로 `GPIO_TypeDef`, `GPIOA_BASE`, `GPIOA`는 Cortex-M4 공통 header가 아니라 선택된 STM32F411 device header에서 오는 정의임.

```text
#include "stm32f4xx.h"
  -> STM32F411xE 선택
  -> #include "stm32f411xe.h"
       -> #include "core_cm4.h"
```

project에서는 대상 device macro 하나만 선택해야 한다. 이 실습처럼 header 안의 해당 줄을 활성화할 수도 있고, build 설정의 preprocessor macro로 `STM32F411xE`를 지정할 수도 있음.

System Timer의 구조체 정의 예시는 다음과 같다. 실제 CMSIS header는 register access 권한을 `__IOM`과 `__IM`으로 member에 표시함.

```c
typedef struct
{
    __IOM uint32_t CTRL;
    __IOM uint32_t LOAD;
    __IOM uint32_t VAL;
    __IM  uint32_t CALIB;
} SysTick_Type;

#define SCS_BASE (0xE000E000UL)
#define SysTick_BASE (SCS_BASE + 0x0010UL)
#define SysTick ((SysTick_Type *)SysTick_BASE)
```

#### `SysTick_Type`로 주소와 member offset 읽기

`SysTick_Type`도 같은 네 단계를 그대로 보여 준다. `SCS_BASE`는 `0xE000E000`, `SysTick_BASE`는 그 기준에서 `0x10` 떨어진 `0xE000E010`이다. 네 member가 모두 32bit이므로 다음 member마다 4byte씩 offset이 증가함.

| `SysTick_Type` member | qualifier | base 기준 offset | 실제 주소 |
| :--- | :--- | :--- | :--- |
| `CTRL` | `__IOM` | `0x00` | `0xE000E010` |
| `LOAD` | `__IOM` | `0x04` | `0xE000E014` |
| `VAL` | `__IOM` | `0x08` | `0xE000E018` |
| `CALIB` | `__IM` | `0x0C` | `0xE000E01C` |

따라서 `SysTick->VAL`은 다음 순서로 해석할 수 있다. 실제 register의 bit 의미와 write side effect는 Cortex-M4 core 문서를 기준으로 확인함.

```text
SysTick->VAL
  = ((SysTick_Type *)0xE000E010)->VAL
  = SysTick base + VAL member offset
  = 0xE000E010 + 0x08
  = 0xE000E018
```

`CALIB`에는 `__IM`, 즉 `volatile const`가 붙어 CPU code의 write를 막는다. 반대로 `CTRL`, `LOAD`, `VAL`은 `__IOM`으로 정의되어 구조체 member를 통해 read/write할 수 있다. 이처럼 qualifier와 member offset을 type 안에 함께 적어 두면 각 register의 주소와 software access 권한을 개별 macro마다 반복하지 않아도 됨.

사용 예시는 다음과 같다.

```c
SysTick->VAL = 0x1000;
```

STM32F411의 GPIO도 `GPIO_TypeDef` 구조체와 base address macro로 정의되어 있다. 현재 source의 GPIO 구조체는 각 member를 `__IO`로 선언한다.

```c
typedef struct
{
    __IO uint32_t MODER;
    __IO uint32_t OTYPER;
    __IO uint32_t OSPEEDR;
    __IO uint32_t PUPDR;
    __IO uint32_t IDR;
    __IO uint32_t ODR;
    __IO uint32_t BSRR;
    __IO uint32_t LCKR;
    __IO uint32_t AFR[2];
} GPIO_TypeDef;

#define PERIPH_BASE (0x40000000UL)
#define AHB1PERIPH_BASE (PERIPH_BASE + 0x00020000UL)

#define GPIOA_BASE (AHB1PERIPH_BASE + 0x0000UL)
#define GPIOB_BASE (AHB1PERIPH_BASE + 0x0400UL)

#define GPIOA ((GPIO_TypeDef *)GPIOA_BASE)
#define GPIOB ((GPIO_TypeDef *)GPIOB_BASE)
```

`AFR[2]`는 alternate-function register 두 개를 배열로 묶은 표현이다. `AFR[0]`은 pin 0~7의 `AFRL`, `AFR[1]`은 pin 8~15의 `AFRH`에 대응함.

현재 `GPIO_TypeDef`는 `IDR`도 `__IO`로 선언한다. 따라서 `GPIOA->IDR = value;`처럼 type상 허용되는 code가 hardware에서 의미 있는 write인지는 별도로 판단해야 한다. GPIO input data register의 실제 access 규칙은 STM32F411 reference manual이 최종 기준임.

CMSIS는 Cortex-M core와 header 표현 방식의 이식성을 높인다. GPIO·UART·DMA의 실제 register 구성과 기능은 MCU마다 다르므로, peripheral code는 해당 device header와 reference manual을 기준으로 맞춘다.

이 방식을 쓰면 LED 제어 코드가 다음처럼 바뀐다.

```c
void Main(void)
{
    volatile int i;

    GPIOA->MODER = 0x1u << 10;
    GPIOA->OTYPER = 0x0u << 5;

    for (;;)
    {
        GPIOA->ODR = 0x1u << 5;
        for (i = 0; i < 0x40000; i++)
            ;

        GPIOA->ODR = 0x0u << 5;
        for (i = 0; i < 0x40000; i++)
            ;
    }
}
```

#### `Main`이라는 이름과 firmware의 시작 함수

이 실습 code는 소문자 `main` 대신 `void Main(void)`를 사용한다. `Main`이 C 언어에 미리 정해진 특별한 함수명인 것은 아니다. 이 project의 startup source인 [`crt0.s`](../helloEmbedded/0602.CMSIS_LAB/crt0.s)가 reset 뒤 `__start`에서 초기화 작업을 수행하고, 마지막에 `Main` symbol로 branch하도록 작성되어 있기 때문에 `Main`이 application code의 시작 함수가 됨.

```asm
.extern Main
BL     Main
```

따라서 bare-metal firmware에서 application 시작 함수의 이름은 startup code가 호출하도록 연결한 symbol로 정해진다. `App_Main`처럼 다른 이름을 쓰려면 startup code의 선언과 branch 대상도 같은 이름으로 맞춰야 한다. 일반적인 hosted C 실행 환경에서 runtime이 소문자 `main`을 호출하는 관례와, 이 실습의 bare-metal startup 방식은 구분해 둔다.

나중에 vector table의 reset vector, `__start` 또는 `Reset_Handler`, stack 설정, `.data` 복사, `.bss` 초기화, linker script가 이 시작 경로를 어떻게 연결하는지 이어서 확인한다.

## 7과 - 비트 mask로 원하는 register bit만 바꾸기

### 전체 register 대입이 만드는 문제

현재 실습 source의 [`0701.BIT_OP_LAB/main.c`](../helloEmbedded/0701.BIT_OP_LAB/main.c)는 먼저 PA5 LED를 켜는 가장 단순한 출발 code를 둔다.

```c
GPIOA->MODER = 0x1u << 10;
GPIOA->OTYPER = 0x0u << 5;
GPIOA->ODR = 0x1u << 5;
```

각 식의 오른쪽 값은 PA5만 선택하려는 모양이지만, `=`는 32-bit register 전체를 그 값으로 대입한다. 결과적으로 PA5 이외의 bit도 `0`으로 기록될 수 있음.

| 대입 code | 실제로 쓰는 값 | PA5에 대한 의도 | 함께 바뀔 수 있는 부분 |
| :--- | :--- | :--- | :--- |
| `GPIOA->MODER = 0x1u << 10` | `0x00000400` | `MODER[11:10] = 01`, PA5 output mode | 나머지 pin의 mode field가 모두 `00`으로 기록 |
| `GPIOA->OTYPER = 0x0u << 5` | `0x00000000` | PA5 output type을 `0`으로 설정 | 모든 output-type bit가 `0`으로 기록 |
| `GPIOA->ODR = 0x1u << 5` | `0x00000020` | PA5를 high로 출력 | 다른 pin의 output data bit가 `0`으로 기록 |

즉, 다른 pin이 이미 high output이거나 alternate function·통신·debug 용도로 설정돼 있으면, 단순 대입 하나가 그 상태를 덮어쓸 수 있다. 이후의 register 제어에서는 '원하는 bit만 바꾸고 나머지는 그대로 둔다'가 기본 원칙임.

### Mask는 바꿀 bit를 표시하는 선택 패턴

예를 들어 bit `25`, `24`, `6`, `0`만 선택하려면 `1`을 그 위치에 놓은 mask를 만든다.

```c
uint32_t a = 0x33CC33CCu;
uint32_t mask = (0x3u << 24) | (0x1u << 6) | (0x1u << 0);
/* mask = 0x03000041 */
```

`0x3u`는 binary `11`이므로 `0x3u << 24`는 bit `25:24` 두 곳을 함께 선택한다. `1u << 6`은 bit `6`, `1u << 0`은 bit `0`을 고른다.

```text
bit index
31        24        16         8         0
|---------|---------|----------|---------|

a    = 0011 0011 1100 1100 0011 0011 1100 1100
mask = 0000 0011 0000 0000 0000 0000 0100 0001
          ^^                          ^        ^
        25,24                         6        0
```

`uint32_t`와 `1u`, `0x3u`처럼 unsigned literal을 쓰면 STM32의 32-bit register 폭과 shift 의도가 code에 분명히 드러난다.

### Shift로 n번 bit mask 만들기

bit 번호는 오른쪽 끝의 least significant bit부터 `0`, `1`, `2` 순서로 센다. `1u << n`은 bit `0`에 있던 `1` 하나를 왼쪽으로 n칸 옮겨 n번 bit만 `1`인 mask를 만드는 left-shift 식이다.

```text
bit index  7 6 5 4 3 2 1 0
a        = 0 1 0 0 1 0 1 0

1u       = 0 0 0 0 0 0 0 1
1u << 2  = 0 0 0 0 0 1 0 0   /* bit 2 선택 */
1u << 1  = 0 0 0 0 0 0 1 0   /* bit 1 선택 */
```

따라서 n번 bit를 다룰 때의 기본식은 다음 세 줄이다. 괄호는 shift 결과 전체를 하나의 mask로 읽게 해 준다.

```c
a |= (1u << n);      /* n번 bit set */
a ^= (1u << n);      /* n번 bit invert */
a &= ~(1u << n);     /* n번 bit clear */
```

`a = 0100 1010`에서 `n = 2`는 원래 bit가 `0`인 경우이고, `n = 1`은 원래 bit가 `1`인 경우다.

| 선택 bit | mask | Set `a \|= (1u << n)` | Invert `a ^= (1u << n)` | Clear `a &= ~(1u << n)` |
| :--- | :--- | :--- | :--- | :--- |
| `n = 2`, 원래 `0` | `0000 0100` | `0100 1110` | `0100 1110` | `0100 1010` |
| `n = 1`, 원래 `1` | `0000 0010` | `0100 1010` | `0100 1000` | `0100 1000` |

Set은 원래 값이 무엇이든 선택 bit를 `1`로 만들고, clear는 `0`으로 만든다. Invert는 원래 `0`이면 `1`, 원래 `1`이면 `0`으로 뒤집는다. mask의 나머지 bit는 `0`이므로 OR·XOR에서는 유지되고, clear 식에서는 `~` 뒤집기 결과가 `1`이 되어 AND에서 유지됨.

STM32의 32-bit register에서는 `n`을 `0` 이상 `32` 미만으로 사용한다. type 폭 이상으로 shift하면 C에서 정의되지 않은 동작이 될 수 있으므로, pin 번호나 bit position이 register 폭 안에 있는지 확인해야 함.

### Shift 방향, `MSB`·`LSB`, unsigned type

Shift는 mask를 만드는 방법인 동시에 값의 bit를 실제로 옮기는 연산이다. 아래는 `8-bit` 폭으로 볼 때의 예시다.

```text
a        = 0 1 0 0 1 0 1 1
a >> 2   = 0 0 0 1 0 0 1 0   /* 오른쪽으로 두 칸, 오른쪽 밖 bit는 사라짐 */
a << 2   = 0 0 1 0 1 1 0 0   /* 왼쪽으로 두 칸, 왼쪽 밖 bit는 사라짐 */
```

`MSB`(Most Significant Bit)는 숫자값에 가장 큰 가중치를 주는 최상위 bit이고, `LSB`(Least Significant Bit)는 가장 작은 가중치를 주는 최하위 bit다. 위 `8-bit` 값에서는 bit `7`이 MSB, bit `0`이 LSB다. 이 이름은 값 안의 자리 가치 기준이며, byte를 memory에 저장하는 endian 순서와는 별개의 개념임.

| 연산 대상 | 오른쪽 shift에서 새로 들어오는 상위 bit | register code에서의 사용 |
| :--- | :--- | :--- |
| unsigned 값 | `0` | logical right shift, bit pattern 처리 |
| 음수 signed 값 | compiler·언어 규칙에 따라 차이 가능 | hardware register 조작에는 사용하지 않음 |

GPIO register는 부호 있는 정수가 아니라 32개의 bit pattern으로 다룬다. 따라서 `uint32_t`, `1u`, `0x3u`처럼 unsigned type을 사용하고, 특히 negative signed value의 `>>` 결과에 의존하지 않는다. `<<`도 register 폭 밖으로 밀려나는 bit가 있는 경우를 의도적으로 확인해야 함.

### OR·XOR·AND를 mask의 제어 규칙으로 읽기

논리 gate의 truth table을 외우는 데서 끝내지 않고, `x`를 원래 bit, `m`을 mask bit로 놓고 'mask의 `0`과 `1`이 무엇을 지시하는가'로 읽는다.

| 목적 | code | `m = 0`일 때 | `m = 1`일 때 |
| :--- | :--- | :--- | :--- |
| Set | `a \|= m` | `x \| 0 = x`, 기존값 유지 | `x \| 1 = 1`, 해당 bit를 `1`로 설정 |
| Invert | `a ^= m` | `x ^ 0 = x`, 기존값 유지 | `x ^ 1 = !x`, 해당 bit 반전 |
| Clear | `a &= ~m` | `x & 1 = x`, 기존값 유지 | `x & 0 = 0`, 해당 bit를 `0`으로 clear |

Clear에서만 `~m`을 쓰는 이유는 AND의 규칙 때문이다. `m`에는 clear하고 싶은 위치를 `1`로 표시하고, `~m`으로 뒤집어 그 위치를 `0`으로 만든다. 그러면 `a & ~m`은 목표 bit를 `0`으로 만들고, 나머지는 `1`과 AND되어 원래 값을 유지함.

32-bit 기준으로 위 예시의 `mask`와 보수는 다음과 같다.

```text
mask  = 0x03000041
~mask = 0xFCFFFFBE
```

### 여러 bit와 연속 field의 mask 만들기

서로 떨어진 bit는 각 one-hot mask를 `|`로 합친다. 연속된 bit field는 필요한 `1`의 개수를 먼저 만든 뒤, field의 가장 낮은 bit 위치까지 shift한다.

| 선택할 위치 | mask 만드는 식 | 결과 bit pattern의 뜻 |
| :--- | :--- | :--- |
| bit `5`, `2` | `(1u << 5) \| (1u << 2)` | 떨어진 두 bit 선택 |
| bit `1:0` | `0x3u << 0` | `11` 두 bit 선택 |
| bit `2:1` | `0x3u << 1` | `11`을 bit `1`부터 배치 |
| bit `26:25` | `0x3u << 25` | 연속 두 bit 선택 |
| bit `17:15` | `0x7u << 15` | `111` 세 bit 선택 |

`0x3u`는 `11`, `0x7u`는 `111`이다. 그러므로 연속된 field의 폭이 `w` bit이면 기본 mask는 `(1u << w) - 1u`이고, 실제 위치가 `p`라면 `((1u << w) - 1u) << p`로 생각할 수 있다. 다만 `w`가 type 폭과 같아지는 식은 별도 처리가 필요하므로, STM32 GPIO의 작은 field에서는 `0x3u`, `0x7u`처럼 폭이 분명한 literal을 쓰는 편이 읽기 쉬움.

mask 조각을 합칠 때 `+`도 각 bit가 절대로 겹치지 않는 경우에는 같은 수치를 만들 수 있다. 하지만 `|`는 '선택 bit를 합친다'는 의도를 직접 표현하고 carry가 없으므로 register mask에는 `|`를 우선 사용한다. `+`를 쓸 경우 shift보다 precedence가 높으므로 각 shift 식을 반드시 괄호로 묶어야 함.

```c
uint32_t mask = (1u << 0) | (1u << 6) | (0x3u << 24);
```

위 식은 compile-time constant만 사용한다. compiler는 보통 이를 `0x03000041u` 같은 상수로 미리 계산하므로, 실행 성능을 걱정해 bit 위치가 보이지 않는 magic number로 바꿀 필요가 없다. 반대로 `n`이 실행 중에 정해지면 `1u << n`도 실행 중 shift가 됨.

### 같은 mask로 set·invert·clear 비교

`|=`, `^=`, `&=`는 모두 복합 대입 연산자다. 예를 들어 `a |= mask`는 `a = a | mask`와 같으며, `a = mask`처럼 원래 `a` 전체를 mask 값으로 바꾸는 식이 아님.

아래 결과는 매번 같은 초기값 `a = 0x33CC33CCu`에서 각각 따로 실행한 값이다.

| 동작 | code | 선택된 bit에서 일어나는 일 | 결과 |
| :--- | :--- | :--- | :--- |
| Set | `a \|= mask` | bit `0`: `0 → 1`; 이미 `1`인 bit `25:24`, `6`은 유지 | `0x33CC33CD` |
| Invert | `a ^= mask` | bit `25:24`: `11 → 00`, bit `6`: `1 → 0`, bit `0`: `0 → 1` | `0x30CC338D` |
| Clear | `a &= ~mask` | bit `25:24`, `6`을 `0`으로 clear; bit `0`은 이미 `0`이므로 유지 | `0x30CC338C` |

register에 적용하면 이 흐름은 '현재 register 값 read → mask 연산 → 결과 write'가 된다. 그래서 `GPIOA->ODR |= (1u << 5)`는 PA5만 high로 set하면서 다른 ODR bit를 보존하려는 표현이다.

### PA5 LED 실습에서 field 폭부터 읽기

PA5 LED를 위한 세 register는 모두 '5번 pin'과 관계가 있지만, 각 field의 폭과 목표 값이 다르다. 이 차이를 먼저 읽으면 mask 식을 외우지 않고 만들 수 있음.

| register | PA5 관련 field | 목표 | field mask | 필요한 연산 방향 |
| :--- | :--- | :--- | :--- | :--- |
| `GPIOA->MODER` | `MODER[11:10]` | `01`, general-purpose output mode | `0x3u << 10` | 두 bit clear 뒤 `0x1u << 10` write |
| `GPIOA->OTYPER` | `OT5` | `0`, push-pull | `1u << 5` | bit `5` clear |
| `GPIOA->ODR` | `OD5` | `1`, output high | `1u << 5` | bit `5` set |

`MODER`처럼 여러 bit인 field는 원하는 값을 쓰기 전에 field 전체를 clear해야 한다. 예를 들어 이전 값이 `10` 또는 `11`일 수 있으므로, 단순히 `|= (0x1u << 10)`만 하면 항상 `01`이 되지 않는다. 반면 `OTYPER[5]`, `ODR[5]`는 한 bit이므로 각각 clear·set 규칙을 바로 적용할 수 있음.

### `GPIOx_BSRR`: ODR을 읽지 않고 bit set/reset하기

`BSRR`는 Bit Set/Reset Register다. STM32F411에서는 `GPIOx_BSRR`이 GPIO base에서 `0x18` offset에 있으며, ODR의 특정 output bit를 한 번의 write로 set 또는 reset하는 전용 register다. ST의 `RM0383`은 이 register가 interrupt 사이의 read-modify-write 경쟁을 피하도록 설계됐다고 설명함.

| `BSRR` 범위 | 이름 | `1`을 write했을 때 | `0`을 write했을 때 |
| :--- | :--- | :--- | :--- |
| bit `15:0` | `BS0`~`BS15` | 대응 `ODR0`~`ODR15` set | 해당 pin에 변화 없음 |
| bit `31:16` | `BR0`~`BR15` | 대응 `ODR0`~`ODR15` reset | 해당 pin에 변화 없음 |

```c
GPIOA->BSRR = (1u << 5);          /* BS5: ODR5를 1로 set */
GPIOA->BSRR = (1u << (5u + 16u)); /* BR5: ODR5를 0으로 reset */
```

한 번의 BSRR write에서 같은 pin의 `BSy`와 `BRy`를 모두 `1`로 쓰면 STM32F411은 set 동작을 우선한다. 여러 pin의 set/reset 명령도 한 32-bit write에 함께 넣을 수 있음.

`GPIOA->ODR |= (1u << 5)`는 ODR 전체를 read한 뒤 OR 결과를 다시 write하는 read-modify-write다. `GPIOA->BSRR = (1u << 5)`는 BSRR에 직접 write하여 ODR5만 set한다. 따라서 interrupt handler 등이 같은 ODR의 다른 bit를 바꾸는 상황에서, CPU가 읽어 둔 오래된 ODR 값으로 다른 bit를 되돌려 쓰는 위험을 줄임.

`BSRR`의 bit는 write-only control bit이므로 `|=`나 `&=` 대신 `=`로 write한다. `BSRR`은 `MODER`·`OTYPER`를 설정하는 register가 아니며, output bit의 toggle 기능도 직접 제공하지 않는다. output mode/type은 해당 configuration register에서 field mask로 설정하고, output level의 set/reset에만 BSRR를 사용함. 세부 field 정의와 같은 pin의 set/reset을 동시에 write했을 때의 우선순위는 ST의 [RM0383 GPIO reference manual](https://www.st.com/resource/en/reference_manual/dm00119316-stm32f411xce-advanced-armbased-32bit-mcus-stmicroelectronics.pdf)을 최종 기준으로 확인한다.

#### 상태를 저장하는 `ODR`, 동작을 요청하는 `BSRR`

둘 다 output과 관련 있지만 읽는 방법이 다르다. `ODR`은 현재 output latch의 **상태**를 담고 있어 field 값을 새로 만들 때 read-modify-write 대상이 된다. `BSRR`은 해당 latch에 전달할 **명령 bit**를 담은 write-only 창구다. `BSRR`에 쓴 `1`은 한 번의 set 또는 reset 요청이고, `0`은 아무 요청도 하지 않는다.

```text
GPIOA->ODR  = 0b...00100000    -> PA5의 저장된 output 상태를 포함
GPIOA->BSRR = 0b...00100000    -> 'PA5를 set하라'는 명령
GPIOA->BSRR = 1u << 21         -> 'PA5를 reset하라'는 명령 (5 + 16)
```

그래서 다음처럼 `BSRR`에 OR 대입을 하면 안 된다. `|=`는 먼저 write-only register를 읽으려 하므로, 읽은 값이 의미 없거나 device별 side effect를 만들 수 있다. set/reset mask를 계산한 뒤 대입 한 번으로 쓴다.

```c
uint32_t set_mask = (1u << 5) | (1u << 7);
uint32_t reset_mask = (1u << (6u + 16u));

GPIOA->BSRR = set_mask | reset_mask; /* PA5·PA7 set, PA6 reset */
```

한 pin의 level을 반전하려면 현재 상태를 알아야 하므로, `BSRR` 하나만으로는 toggle을 표현할 수 없다. 단순한 실습에서는 `ODR`의 해당 bit를 XOR로 바꾸거나, 동시 접근이 있는 firmware에서는 software가 상태를 따로 관리한 뒤 그 결과를 BSRR set/reset 명령으로 내보내는 방식을 선택함.

### PA5 LED ON 문제 풀이: 세 가지 `MODER` 표현

PA5의 `MODER[11:10]` 목표값은 `01`이다. 즉 bit `11`은 `0`, bit `10`은 `1`이어야 한다. `OTYPER[5]`는 `0`으로 clear하고, `ODR[5]`는 `1`로 set한다.

#### 1. 목표 bit를 각각 clear·set

```c
GPIOA->MODER &= ~(1u << 11); /* MODER[11] = 0 */
GPIOA->MODER |=  (1u << 10); /* MODER[10] = 1 */
GPIOA->OTYPER &= ~(1u << 5); /* OT5 = 0, push-pull */
GPIOA->ODR |=     (1u << 5); /* OD5 = 1, output high */
```

첫 두 줄은 최종적으로 `MODER[11:10] = 01`을 만든다. 읽기에는 가장 직관적이지만, `MODER`에 대해 clear와 set이 각각 read-modify-write가 되어 두 번의 register 갱신 흐름이 생김.

#### 2. clear와 set을 하나의 식으로 합치기

```c
GPIOA->MODER = (GPIOA->MODER & ~(1u << 11)) | (1u << 10);
```

위 식은 `MODER`를 한 번 읽고, bit `11`만 clear한 뒤 bit `10`을 set하여 한 번 write한다. PA5의 목표가 항상 `01`일 때는 1번과 같은 결과를 더 적은 register 갱신으로 만들 수 있음.

여기서 `~(0x3u << 11)`로 바꾸면 안 된다. `0x3u << 11`은 bit `12:11`을 선택하므로 PA5 field의 bit `10`은 포함하지 않고, PA6 field의 bit `12`를 잘못 건드릴 수 있다. 두 bit mask `0x3u`를 쓰려면 PA5 field의 시작 위치인 bit `10`으로 shift해야 함.

#### 3. field 전체를 지운 뒤 원하는 data를 쓰기

```c
GPIOA->MODER = (GPIOA->MODER & ~(0x3u << 10)) | (0x1u << 10);
```

`0x3u << 10`은 `MODER[11:10]` 전체를 선택한다. 먼저 `00`으로 clear하고, 그 자리에 `01`인 `0x1u << 10`을 넣는다. 이것이 field write다. 새 field 값이 `00`, `01`, `10`, `11` 중 무엇으로 바뀌어도 같은 구조를 사용할 수 있어 여러 bit 설정에 가장 일반적임.

```c
/* field mask = bits, field 시작 위치 = position */
dest = (dest & ~(bits << position)) | ((data & bits) << position);
```

`data & bits`는 data가 field 폭보다 클 때 옆 field까지 침범하지 않게 하는 보호식이다. 수업의 `Macro_Write_Block`은 `data`가 이미 `bits` 폭 안이라는 전제로 사용하므로, 호출할 때 그 범위를 지켜야 함.

| 표현 | `MODER`에서 하는 일 | 적합한 상황 |
| :--- | :--- | :--- |
| 각각 clear·set | bit `11` clear 후 bit `10` set | bit별 동작을 처음 읽을 때 |
| 한 식으로 합침 | bit `11` clear와 bit `10` set을 한 결과값으로 write | 목표값이 고정된 `01` |
| field write | `MODER[11:10]` 전체 clear 후 `data` write | 여러 bit field를 다양한 값으로 설정 |

`ODR |= (1u << 5)`는 이 실습의 bit 연산 예시다. interrupt와 ODR 공유 가능성까지 고려하는 code에서는 앞 절의 `GPIOA->BSRR = (1u << 5)`가 output bit set에 더 적합함.

### `macro.h`: 반복되는 bit 처리식을 이름으로 묶기

현재 실습 source의 [`macro.h`](../helloEmbedded/0701.BIT_OP_LAB/macro.h)는 반복되는 bit 식을 function처럼 보이는 macro 호출로 바꾼다. macro는 function 호출이 아니라 preprocessing 단계의 text substitution이다. 호출 위치에 식이 그대로 펼쳐지므로 call/return 구조가 없고, 호출할 때마다 code 크기가 늘 수 있으며 type 검사도 function만큼 엄격하지 않음.

macro의 핵심 안전 규칙은 parameter와 결과 식 전체를 괄호로 감싸는 것이다.

```c
#define SQR_BAD(x) x * x
#define SQR(x)     ((x) * (x))

SQR_BAD(2 + 3) /* 2 + 3 * 2 + 3, 결과 11 */
SQR(2 + 3)     /* ((2 + 3) * (2 + 3)), 결과 25 */
```

`SQR` 예시는 macro가 argument를 계산한 뒤 받는 것이 아니라 argument text를 식 안에 대입한다는 점을 보여 준다. `i++`처럼 side effect가 있는 expression을 여러 번 쓰는 macro argument로 넘기지 않는 것도 같은 이유임.

#### 한 bit 처리 macro

```c
#define Macro_Set_Bit(dest, pos) \
    ((dest) |= ((unsigned)0x1u << (pos)))

#define Macro_Clear_Bit(dest, pos) \
    ((dest) &= ~((unsigned)0x1u << (pos)))

#define Macro_Invert_Bit(dest, pos) \
    ((dest) ^= ((unsigned)0x1u << (pos)))
```

| macro | 펼친 핵심 식 | 선택 bit에서의 결과 |
| :--- | :--- | :--- |
| `Macro_Set_Bit(a, n)` | `a \|= 1u << n` | `1`로 set |
| `Macro_Clear_Bit(a, n)` | `a &= ~(1u << n)` | `0`으로 clear |
| `Macro_Invert_Bit(a, n)` | `a ^= 1u << n` | 기존값 반전 |

예를 들어 `a = 0xCC3355AAu`에서 `Macro_Set_Bit(a, 0)`, `Macro_Clear_Bit(a, 3)`, `Macro_Invert_Bit(a, 6)`을 순서대로 실행하면 `0xCC3355AB → 0xCC3355A3 → 0xCC3355E3`이 된다.

#### 여러 bit field 처리 macro

```c
#define Macro_Clear_Area(dest, bits, pos) \
    ((dest) &= ~((unsigned)(bits) << (pos)))

#define Macro_Set_Area(dest, bits, pos) \
    ((dest) |= ((unsigned)(bits) << (pos)))

#define Macro_Invert_Area(dest, bits, pos) \
    ((dest) ^= ((unsigned)(bits) << (pos)))

#define Macro_Write_Block(dest, bits, data, pos) \
    ((dest) = ((dest) & ~((unsigned)(bits) << (pos))) | \
              ((unsigned)(data) << (pos)))

#define Macro_Extract_Area(dest, bits, pos) \
    ((((unsigned)(dest) >> (pos)) & (bits)))
```

`bits`는 실제 data가 아니라 field 폭을 나타내는 `1` pattern이다. 예를 들어 `0x3`은 2bit, `0x7`은 3bit, `0x1F`는 5bit field를 뜻한다. 따라서 `Macro_Write_Block(a, 0x7, 0x5, 2)`는 `a[4:2]` 세 bit를 지운 뒤 `101`, 즉 `0x5`를 기록한다. `Macro_Extract_Area(a, 0x7, 2)`는 같은 `a[4:2]`를 오른쪽 끝으로 옮겨 `0`~`7` 범위의 값으로 읽어 냄.

PA5부터 PA7까지 외부 LED 세 개를 제어할 때도 같은 field write를 사용한다. `0x7u`는 3bit mask `111`이고, `Macro_Write_Block(GPIOA->ODR, 0x7u, data, 5)`는 `ODR[7:5]`만 바꾼다. 외부 LED가 active-low open-drain 연결이면 write 전에 `(~data) & 0x7u`로 논리 표시값의 하위 3bit를 반전해야 한다.

`macro.h`에는 원하는 bit가 set인지 clear인지 검사하는 macro도 있다.

```c
#define Macro_Check_Bit_Set(dest, pos) \
    (((unsigned)(dest) >> (pos)) & 0x1u)

#define Macro_Check_Bit_Clear(dest, pos) \
    (!(((unsigned)(dest) >> (pos)) & 0x1u))
```

먼저 `(dest >> pos)`로 목표 bit를 bit `0` 자리까지 가져오고, `& 0x1u`로 그 bit만 남긴다. 이 흐름은 register status field를 읽을 때도 그대로 사용됨.

### 매크로를 이용한 LED Toggle

이 실습은 [`0701.BIT_OP_LAB`의 `main.c`](../helloEmbedded/0701.BIT_OP_LAB/main.c)에서 PA5 User LED를 macro만으로 제어하는 문제다. 목표는 PA5를 output으로 설정하고 처음에는 LED를 off로 만든 뒤, 무한 loop에서 PA5의 output level을 반전하여 LED가 반복해서 on/off되게 만드는 것이다.

| 단계 | 대상 | 필요한 상태 |
| :--- | :--- | :--- |
| GPIOA clock | `RCC->AHB1ENR[0]` | GPIOA peripheral clock enable |
| output mode | `GPIOA->MODER[11:10]` | `01`, PA5 general-purpose output |
| output type | `GPIOA->OTYPER[5]` | `0`, push-pull |
| initial level | `GPIOA->ODR[5]` | `0`, LED off |
| loop 동작 | `GPIOA->ODR[5]` | `Macro_Invert_Bit`로 level 반전 |

`RCC->AHB1ENR[0]`은 GPIOA peripheral의 clock gate다. GPIOA register를 쓸 때는 먼저 이 bit가 set되어 있어야 한다. 현재 실습 환경에서는 `Sys_Init() → Uart2_Init()` 흐름이 PA2·PA3 초기화 과정에서 GPIOA clock을 이미 켤 수 있지만, LED만 독립적으로 초기화하는 code에서는 이 의존성을 숨기지 않고 `LED_Init` 안에서 직접 보장하는 편이 안전함.

```c
void Main(void)
{
    volatile int i;

    Macro_Set_Bit(RCC->AHB1ENR, 0);
    Macro_Write_Block(GPIOA->MODER, 0x3u, 0x1u, 10);
    Macro_Clear_Bit(GPIOA->OTYPER, 5);
    Macro_Clear_Bit(GPIOA->ODR, 5);

    for (;;)
    {
        Macro_Invert_Bit(GPIOA->ODR, 5);

        for (i = 0; i < 0x80000; i++)
            ;
    }
}
```

`Macro_Write_Block(GPIOA->MODER, 0x3u, 0x1u, 10)`은 PA5의 2bit field인 `MODER[11:10]`을 clear한 뒤 `01`을 기록한다. `Macro_Invert_Bit(GPIOA->ODR, 5)`은 `ODR[5]`만 XOR하여 LED의 현재 상태를 반대로 만든다. delay loop의 `0x80000`은 사람이 LED 깜빡임을 볼 수 있게 하는 단순 software delay 값이다. 실제 시간은 CPU clock과 compiler optimization에 따라 달라질 수 있으므로, 정확한 시간 기준이 필요하면 timer를 사용해야 함.

### LED Driver 함수 설계

[`0702.LED_DRIVER_LAB`의 `led.c`](../helloEmbedded/0702.LED_DRIVER_LAB/led.c)는 application code에서 GPIO register와 PA5 field 위치를 직접 다루지 않도록 LED 제어를 driver 함수로 분리하는 문제다. 상위 code는 `LED_Init()`·`LED_On()`·`LED_Off()`만 호출하고, PA5의 mode·type·output level은 `led.c`가 책임진다.

| 함수 | 역할 | register 동작 |
| :--- | :--- | :--- |
| `LED_Init()` | GPIOA clock 준비, PA5 output 설정, LED off | `AHB1ENR[0]` set, `MODER[11:10]`에 `01` write, `OT5`·`OD5` clear |
| `LED_On()` | PA5 high 출력 | `ODR[5]` set |
| `LED_Off()` | PA5 low 출력 | `ODR[5]` clear |

```c
void LED_Init(void)
{
    /* 아래 code 수정 금지: Port-A clock enable */
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

lab skeleton의 `Macro_Set_Bit(RCC->AHB1ENR, 0)`은 Port-A clock enable을 담당하므로 수정하지 않는다. `LED_Init`은 초기 상태를 off로 확정하고, `LED_On`·`LED_Off`은 output level만 바꾼다. mode나 output type을 on/off 함수마다 다시 설정하지 않는 이유는 initialization과 동작 제어의 역할을 분리하기 위함임.

[`0702.LED_DRIVER_LAB`의 `main.c`](../helloEmbedded/0702.LED_DRIVER_LAB/main.c)처럼 application code는 다음 수준으로 단순해진다.

```c
LED_Init();

for (;;)
{
    (led ^= 1) ? LED_Off() : LED_On();

    for (i = 0; i < 0x20000; i++)
        ;
}
```

`led ^= 1`은 `led`를 `0`과 `1` 사이에서 반전한다. 조건식이 참일 때 `LED_Off()`, 거짓일 때 `LED_On()`을 호출하므로 application은 register bit 위치를 알 필요 없이 LED 상태 전환만 표현하면 된다. 이후 `LED_Toggle()`이나 `LED_Control(int on)` 같은 API를 추가할 수 있지만, 현재 실습의 필수 함수는 `LED_Init`·`LED_On`·`LED_Off` 세 개다.

`main.c`와 `led.c`는 각각 compile된 뒤 linker가 하나의 firmware로 묶는다. application 쪽은 `device_driver.h`에서 함수 선언을 포함하고, `led.c`는 build 대상에 포함되어야 한다. 이렇게 분리하면 application은 LED를 언제 제어할지만 결정하고, driver는 GPIO register 설정 방법을 맡는다. LED·key·UART·timer·ADC 같은 device driver를 다른 project에 재사용하기도 쉬워짐.

### 실습 과제

앞 절의 PA5 macro Toggle은 수업 중 예제다. 실제 과제는 LED 3개를 이용한 binary count와 왕복 shift, LED driver code 작성의 세 항목으로 구성됨.

| 과제 | 구현 목표 | 확인 결과 |
| :--- | :--- | :--- |
| LED 3개 `0`~`7` count | 3bit binary value를 LED 3개로 표시 | `000`부터 `111`까지 반복 |
| LED 왕복 shift | 끝에서 방향을 바꾸는 LED 이동 | `001 → 010 → 100 → 010 → 001` 반복 |
| LED driver | `LED_Init`·`LED_On`·`LED_Off` 작성 | application이 register 대신 함수 호출로 LED 제어 |

세 과제의 구현 조건과 확인 항목은 [26-07-14 ARM Cortex-M4 디바이스 프로그래밍 실습 과제 공지](../assignment/260714-arm-cortex-m4-device-programming-homework.md)에 정리했다.
