# 26-07-20 - 11과 Timer 제어

관련 노트:

- [26-07-16 - UART와 Timer 제어 선행 정리](260716-arm-cortex-m4-device-programming.md)
- [1102.TIMER_DRIVER_LAB](../helloEmbedded/1102.TIMER_DRIVER_LAB/)
- [1103.TIMER_OUTPUT_LAB](../helloEmbedded/1103.TIMER_OUTPUT_LAB/)

## 11과 - Timer 제어

timer는 정해진 clock pulse를 세는 hardware counter peripheral이다. firmware는 register를 설정해 counter가 어떤 속도·방향·주기로 셀지 정하고, hardware가 만든 timeout event와 flag를 읽어 다음 동작을 결정한다.

`SysTick`은 Cortex-M4 core 안의 system timer이고, `TIM2`, `TIM3`, `TIM4` 같은 `TIMx`는 STM32 peripheral timer다. 둘 다 clock을 세지만, register 구성과 쓰임이 다르다.

## SysTick: Cortex-M4 안의 기본 timer

`SysTick`은 Cortex-M4 core에 포함된 24-bit down counter다. `LOAD`에 reload 값을 쓰고 `VAL`을 초기화한 뒤 `CTRL.ENABLE`을 set하면 `LOAD`에서 `0`까지 감소한다. `0`에 도달하면 다시 reload되며, `COUNTFLAG`가 set된다.

| Register·bit | 역할 |
| :--- | :--- |
| `LOAD` | 한 주기의 reload 값 |
| `VAL` | 현재 down counter 값. 값을 쓰면 counter를 초기화한다. |
| `CTRL.ENABLE` | SysTick counter 시작·정지 |
| `CTRL.TICKINT` | timeout 때 SysTick exception 발생 허용 |
| `CTRL.CLKSOURCE` | core clock 또는 core clock의 분주 clock 선택 |
| `CTRL.COUNTFLAG` | 마지막 확인 뒤 counter가 `0`에 도달했음을 알리는 flag. `CTRL` read로 clear된다. |

수업 clock 설정에서 `HCLK = 96 MHz`, SysTick clock이 `HCLK / 8 = 12 MHz`이면 `1 ms`에는 `12,000` tick이 필요하다. counter가 `LOAD`부터 `0`까지 세므로, 정확히 `msec` 동안 기다릴 reload 값은 다음처럼 계산한다.

```text
LOAD = 12,000 × msec - 1
```

수업의 `SysTick_Run()`은 `LOAD = round(HCLK / (8 × 1000) × msec)` 형태로 값을 쓴다. 이 값과 위 식의 `-1` 차이는 counter가 `0`도 한 count로 포함한다는 zero-origin 규칙에서 생긴다. timer 값을 설계할 때는 source code의 상수만 보지 않고 `LOAD + 1` count 규칙으로 원하는 주기를 다시 계산한다.

`SysTick_Run()`은 `LOAD`·`VAL`·`CTRL`을 설정해 시간 측정을 시작하고, `SysTick_Check_Timeout()`은 `COUNTFLAG`를 확인한다. stopwatch는 초기 counter 값과 현재 `VAL`의 차이에 tick 시간을 곱해 경과 시간을 구한다.

## TIMx: STM32 peripheral timer의 시간 경로

`TIMx`를 사용하려면 먼저 RCC에서 해당 timer peripheral의 clock을 켠다. 예를 들어 `TIM2`, `TIM4`는 APB1에 있으므로 `RCC->APB1ENR`의 각 enable bit를 set한다. clock이 공급된 뒤 다음 순서로 timer를 구성한다.

```text
RCC clock enable
→ CR1 동작 mode 설정
→ PSC·ARR 설정
→ EGR.UG로 update event 발생
→ SR.UIF clear
→ CR1.CEN set으로 counter 시작
→ UIF 확인 또는 interrupt 처리
```

| Register·bit | 역할 |
| :--- | :--- |
| `CR1.CEN` | counter enable. `1`이면 시작, `0`이면 정지 |
| `CR1.DIR` | up/down count 방향 |
| `CR1.OPM` | one-pulse 또는 repeat 동작 선택 |
| `PSC` | timer input clock 분주 값 |
| `ARR` | auto-reload 값. 한 주기의 count 길이 기준 |
| `CNT` | 현재 counter 값 |
| `EGR.UG` | update event를 강제로 발생시킨다. 설정한 분주·reload 상태를 counter 동작에 반영하고 count를 초기화하는 시작 경계다. |
| `SR.UIF` | update event·timeout 발생 flag. `0`을 써서 clear한다. |
| `DIER.UIE` | update interrupt 허용 bit |

timer clock과 period는 다음 식으로 계산한다.

```text
fCNT    = fTIM / (PSC + 1)
Tperiod = (PSC + 1) × (ARR + 1) / fTIM
```

`PSC = N`은 `N + 1`분주이고, `ARR = N`은 `N + 1`개의 count를 뜻한다. 원하는 분주·주기보다 register에 `1` 작은 값을 쓰는 이유다.

수업 코드의 clock 설정은 `HCLK = 96 MHz`, `PCLK1 = 48 MHz`다. APB1 prescaler가 `1`이 아니므로 APB1 timer input clock은 두 배가 되어 `TIMXCLK = 96 MHz`로 계산한다.

### Update event와 flag

`PSC`와 `ARR`을 써도 timer 내부가 새 설정을 즉시 사용하는 시점은 update event와 연결된다. `EGR.UG`를 set하면 firmware가 수동으로 update event를 만들 수 있고, one-pulse·repeat mode에서 timeout이 나면 hardware가 update event를 만든다.

timeout이 발생하면 `SR.UIF`가 `1`이 된다. `UIF`는 읽기만 해서는 clear되지 않는다. 새 delay나 반복 주기를 시작하기 전에 `SR.UIF`에 `0`을 써서 이전 event를 지워야 한다. 남아 있는 `UIF`를 지우지 않으면 새 timeout을 기다리지 않고 즉시 끝난 것처럼 판단할 수 있다.

## TIM2 stopwatch

`TIM2_Stopwatch_Start()`는 down count와 one-pulse mode를 설정하고, `20 µs`마다 counter가 한 번 변하도록 `PSC`를 정한다.

```c
TIM2->CR1 = (1 << 4) | (1 << 3);  // DIR=down, OPM=one-pulse
TIM2->PSC = TIMXCLK / 50000 - 1; // 20 us tick
TIM2->ARR = 0xFFFF;
TIM2->EGR |= 1 << 0;             // UG
TIM2->CR1 |= 1 << 0;             // CEN
```

정지할 때 `CR1.CEN`을 clear하고 `CNT`를 읽는다. 초기값 `0xFFFF`와 현재값의 차이는 지난 tick 수이므로, 다음 식으로 microsecond 단위 경과 시간을 얻는다.

```text
elapsed_us = (0xFFFF - CNT) × 20
```

여기서 stopwatch가 하는 일은 hardware counter가 실제 시간을 세고, firmware가 시작·정지·읽기만 제어하는 구조다. `SysTick`으로 만든 delay를 기준 시간으로 두고 `TIM2` stopwatch 결과를 출력해 두 timer를 비교할 수 있다.

## TIM2 polling delay

`TIM2_Delay(time_ms)`는 요청한 시간에 맞는 `ARR` 값을 정한 뒤 timeout flag를 polling하는 함수다.

```text
CR1·PSC·ARR 설정
→ UG 발생
→ UIF clear
→ CEN set
→ while (UIF == 0) 대기
→ CEN clear
→ return
```

수업 설정의 `20 µs` tick에서는 `1 ms`가 `50` tick이다. 따라서 요청 시간에 맞춰 `ARR` 값을 계산한다. 정확한 period는 항상 `(PSC + 1)`과 `(ARR + 1)`을 포함한 식으로 다시 확인한다.

이 함수는 polling 기반의 blocking delay다. `while`이 끝날 때까지 CPU가 같은 flag만 확인하므로, 그동안 main loop의 다른 일을 수행하지 않는다. LED를 켠 뒤 `TIM2_Delay(1000)`, LED를 끈 뒤 다시 `TIM2_Delay(1000)`을 호출하면 1초 간격으로 깜빡이는 이유다.

### 긴 delay의 분할

수업 실습은 `TIM2_MAX = 0xFFFF`를 한 번의 count 범위로 사용한다. `20 µs` tick에서 최대 한 주기는 약 `65536 × 20 µs = 1.31 s`이므로, 더 긴 delay를 한 번의 `ARR` 값에 넣을 수 없다.

긴 delay는 tick 수를 최대 count 구간과 나머지 구간으로 나눈다.

```text
total_ticks = requested_ms × 50
full_cycles = total_ticks / max_count
remainder   = total_ticks % max_count

max_count 구간을 full_cycles번 one-pulse로 실행
→ remainder가 있으면 마지막 한 번을 해당 값으로 실행
```

즉 `10 s`를 요청해도 `PSC`와 timer mode를 매번 바꿀 필요가 없다. 같은 `20 µs` tick을 유지한 채 timeout을 여러 번 확인한다. 경계값을 구현할 때는 `ARR` register 값과 실제 count 수가 `ARR + 1` 관계라는 점을 다시 확인한다.

## TIM4 repeat timer

`TIM4_Repeat(time_ms)`는 one-pulse 대신 repeat mode로 시작한다. timeout마다 hardware가 reload·update를 반복하고 `SR.UIF`를 set한다. `TIM4_Check_Timeout()`은 `UIF`가 set되었을 때 이를 clear하고 `1`을 반환한다.

```c
if (TIM4_Check_Timeout()) {
    // 주기마다 한 번 실행할 작업
}
```

이 방식도 polling이지만, main loop가 flag를 한 번 확인하고 바로 다른 작업으로 돌아갈 수 있다. blocking delay보다 UART 처리, key 확인, LED 제어 같은 여러 작업을 한 loop에서 섞기 쉽다. loop 자체가 오래 막히면 timeout 확인 시점도 늦어진다.

예를 들어 `TIM4_Repeat(500)`과 `SysTick_Run(500)`을 함께 시작하면 main loop는 두 timer의 timeout을 각각 확인할 수 있다. 각 timer가 끝났을 때만 출력·LED 동작을 수행하고, 그 외에는 다른 작업을 계속한다. `TIM4`는 `OPM=0`인 repeat mode라서 firmware가 `TIM4_Stop()`을 호출하기 전까지 다음 주기를 자동으로 다시 시작한다.

### repeat period의 `ARR - 1`

`20 µs` tick으로 `500 ms` period를 만들려면 필요한 count 수는 `500,000 / 20 = 25,000`이다. down counter는 `ARR` 값부터 `0`까지 세므로 `ARR`에는 `25,000 - 1`을 쓴다.

```text
ARR = (tick_per_ms × requested_ms) - 1
```

예를 들어 `ARR = 5`이면 counter 값은 `5 → 4 → 3 → 2 → 1 → 0`으로 여섯 번 변한다. `-1`을 빼지 않으면 요청한 period보다 한 tick 길어진다.

### `CEN` 정지와 `UIF` clear는 별개

`TIM4_Stop()`이 `CR1.CEN`을 clear하면 counter는 멈춘다. 이미 발생한 update event의 `SR.UIF`는 그대로 남는다. 따라서 timeout을 확인한 뒤 `UIF`를 clear하지 않으면 main loop는 매번 이미 set된 flag를 읽어 timeout이 계속 발생한 것처럼 처리한다.

이 규칙은 timer를 정지한 뒤에도 같다. `CEN`은 counter 동작을 제어하고, `UIF`는 과거 event가 발생했다는 상태를 보존한다. timer polling 함수는 두 상태를 각각 정리해야 한다.

### 동작 중인 repeat period 변경

`TIM4_Change_Value(time_ms)`처럼 repeat timer가 실행 중일 때 `ARR`을 바꾸면 timer를 stop·재설정·start하는 대신 다음 period를 바꿀 수 있다. `ARR`을 작게 하면 다음 주기가 짧아지고, 크게 하면 다음 주기가 길어진다.

`PSC`와 preload를 사용하는 `ARR`·`CCR`의 적용 경계는 update event와 연결된다. 특히 `ARR`의 정확한 반영 시점은 `CR1.ARPE` 설정까지 함께 확인한다. 수업의 가변 주기 실습은 main loop에서 timeout을 확인한 뒤 `ARR`만 갱신해 반복 간격을 점차 바꾸는 구조다.

## Timer channel과 compare/PWM 출력

timer 하나는 `PSC`·`ARR`·`CNT`로 만드는 공통 time base를 가지고, 각 channel은 이 counter를 입력·출력 기능에 연결한다. 수업에서 다루는 general-purpose timer는 channel `1`~`4`를 통해 capture, compare, PWM을 제공한다.

| 기능 | hardware가 하는 일 | firmware가 정하는 값 |
| :--- | :--- | :--- |
| input capture | 외부 edge 순간의 `CNT` 값 저장 | 입력 pin·edge·capture enable |
| output compare | `CNT == CCRn`에서 event 또는 pin 상태 변화 | `CCRn`, 출력 mode·극성 |
| PWM | period 안의 compare 위치로 high/low 폭 생성 | `PSC`, `ARR`, `CCRn`, PWM mode |

`ARR`은 한 주기의 길이, `CCRn`은 그 주기 안에서 출력 상태가 바뀌는 위치다. timer output은 register 설정 뒤 hardware가 pin을 직접 전환하므로, C code가 매 edge마다 GPIO를 쓰지 않아도 일정한 파형을 낸다.

```text
fPWM ≈ fTIM / ((PSC + 1) × (ARR + 1))
duty ≈ CCRn / (ARR + 1)
```

정확한 active 구간은 count 방향·PWM mode·output polarity에 따라 달라진다. 수업의 50% duty 예에서는 `CCRn`을 `ARR`의 절반 근처로 둔다. `ARR`을 바꾸면 frequency가 변하고, `ARR`을 고정한 채 `CCRn`을 바꾸면 duty가 변한다.

### output channel을 pin에 연결하는 register

| 설정 위치 | 역할 |
| :--- | :--- |
| GPIO `MODER`, `AFR` | pin을 alternate function으로 전환하고 timer channel 연결 |
| `CCMR1`, `CCMR2` | channel input/output 선택, compare·PWM mode, preload 설정 |
| `CCER` | channel output enable, active high/low polarity |
| `CCR1`~`CCR4` | channel별 compare 값 |

`CCR` preload를 사용하면 새 duty 값도 update event 경계에서 적용할 수 있다. 이 방식은 파형 중간에 compare 값이 바뀌어 생길 수 있는 불연속을 줄인다.

### TIM3 channel 3와 PB0 부저 실습

`TIM3_Out_Init()`은 GPIOB와 TIM3 clock을 켜고, `PB0`을 alternate function `AF2`로 설정한다. 이어 `TIM3` channel 3의 compare/PWM mode와 output enable을 설정한다. 즉 `PB0`은 일반 GPIO가 아니라 TIM3 hardware가 구동하는 `TIM3_CH3` 출력이 된다.

`TIM3_Out_Freq_Generation(freq)`의 구현 목표는 다음 흐름이다.

```text
TIM3 clock 기준 PSC 설정
→ 원하는 tone frequency에 맞춰 ARR 설정
→ 50% duty가 되도록 CCR3 설정
→ EGR.UG
→ down count·repeat mode·CEN set
```

`Buzzer_Beep()`은 tone frequency를 TIM3 output으로 만들고, `TIM2_Delay(duration)`으로 지속 시간을 기다린 뒤 TIM3을 정지한다. tone의 높이는 output frequency가 결정하고, 음의 길이는 TIM2 delay가 결정한다.

passive buzzer는 외부 square wave가 있어야 진동판이 움직이므로 timer output의 frequency로 음높이를 바꿀 수 있다. active buzzer는 내부 oscillator가 있어 DC 전원만으로 정해진 tone을 낸다. 이 차이 때문에 이번 실습은 software가 빠르게 GPIO를 toggle하는 방식 대신 timer PWM/compare output을 사용한다.

### 부저 주파수용 `PSC`·`ARR`·`CCR3` 선택

`TIM3`의 input clock이 `96 MHz`일 때 수업 코드는 `PSC = 11`로 `8 MHz` timer counter clock을 만든다. `PSC` register는 `PSC + 1`분주이므로 실제 계산은 다음과 같다.

```text
fCNT = 96 MHz / (11 + 1) = 8 MHz
ARR  = round_down(fCNT / requested_frequency) - 1
CCR3 ≈ (ARR + 1) / 2
```

예를 들어 `fCNT = 8 MHz`에서 `440 Hz`를 만들면 `ARR`은 약 `18,180`이 되고, `CCR3`를 그 절반 근처에 두면 약 50% duty의 square wave가 나온다. 실제 출력 주파수는 integer `ARR` 값으로 정해지므로 목표 주파수와 아주 작은 오차가 생길 수 있다.

timer counter clock을 너무 낮게 잡으면 같은 음의 한 period에 들어가는 count 수가 줄어들어 `ARR`의 한 칸이 만드는 주파수 변화가 커진다. 따라서 `16-bit ARR` 범위와 목표 최저 주파수를 만족하는 선에서 높은 `fCNT`를 선택하면 음계 주파수를 더 촘촘하게 맞출 수 있다. 반대로 `fCNT`가 너무 높으면 낮은 주파수에서 필요한 `ARR`이 `0xFFFF`를 넘을 수 있으므로 두 조건을 함께 확인한다.

### 음계·박자·곡 배열

부저 함수는 음계의 실제 Hz 값을 직접 받기보다 `enum key`의 순번을 tone table의 index로 사용한다. C의 `enum`은 첫 항목을 기본적으로 `0`으로 두고 뒤 항목을 `1`씩 증가시킨다.

```c
enum key { C1, C1_, D1, /* ... */ B2 };
const unsigned short tone_value[] = {261, 277, 293, /* ... */ 987};
```

따라서 `C1`은 `0`, `D1`은 `2`가 되어 `tone_value[C1]`, `note_name[C1]`처럼 동일한 순서의 table을 함께 참조한다. `#define C1 0`을 여러 개 쓰는 방식보다 한 묶음의 순번을 선언·추가·확인하기 쉽다. C에서는 이 값들도 정수 상수이므로, index 범위 검사는 별도로 필요하다.

박자는 `BASE`를 기준으로 `N16 = BASE / 4`, `N8 = BASE / 2`, `N4 = BASE`, `N2 = BASE × 2`처럼 millisecond duration으로 만든다. 곡은 `{tone, duration}` 형태의 2차원 배열로 둔다.

```c
const int song[][2] = {
    {G1, N4},
    {A1, N8},
    {REST, N16},
};
```

반복문에서 `song[i][0]`은 음계 index, `song[i][1]`은 유지 시간이다. `REST`는 tone을 발생시키지 않고 TIM3 output을 정지해 쉼표를 만든다. 이 구조에서는 곡을 바꿀 때 timer driver를 고치지 않고 data array만 바꾸면 된다.

## polling에서 interrupt로 이어지는 경계

timer hardware가 만드는 update event와 `UIF`는 polling과 interrupt에서 공통이다.

| 방식 | firmware가 event를 받는 방법 | main loop 상태 |
| :--- | :--- | :--- |
| polling delay | `while`로 `SR.UIF`를 반복 확인 | timeout까지 멈춘다 |
| repeat polling | loop마다 `SR.UIF`를 확인·clear | 다른 일을 함께 수행할 수 있다 |
| timer interrupt | `DIER.UIE`, NVIC를 enable하고 handler가 event를 받는다 | event가 올 때 handler가 실행된다 |

현재 단계에서는 `UIF`를 main loop에서 직접 확인한다. 이후에는 같은 timer와 update event에 interrupt enable·NVIC 설정을 더해 handler가 처리하게 된다.

## 코드 읽기 체크 순서

timer driver를 읽을 때는 아래 순서로 register 한 줄씩 연결한다.

1. `RCC->APB1ENR` 또는 `RCC->APB2ENR`에서 peripheral clock을 켠다.
2. `CR1`에서 count 방향과 one-pulse/repeat mode를 정한다.
3. `PSC`, `ARR`로 tick과 period를 계산한다.
4. `EGR.UG`로 설정 적용 경계를 만든다.
5. `SR.UIF`를 clear해 이전 timeout 상태를 제거한다.
6. `CR1.CEN`으로 시작하고 `CNT` 또는 `SR.UIF`를 읽는다.
7. 끝난 뒤 `CEN`을 clear하거나 다음 주기에 맞춰 flag를 clear한다.
