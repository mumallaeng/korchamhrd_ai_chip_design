# 26-06-25 - StopWatch FND DP 제어와 표시 보강

## 수업 흐름

0624 수업에서 만든 MicroBlaze 기반 StopWatch application을 이어서, FND의 decimal point(DP)를 digit별로 켜고 끄는 구조를 정리했다. 0624까지는 FND 숫자 표시, digit multiplexing, run/stop/clear button, LED 상태 표시가 중심이었다면, 0625에는 FND driver에 DP 제어 기능을 추가하고 application 계층에서 원하는 timing에 맞게 DP를 깜빡이게 하는 흐름을 다뤘다.

FND의 segment data는 active-low 구조이므로, 특정 segment를 켜려면 해당 bit를 `0`으로 만들고 끄려면 `1`로 만든다. DP도 segment data의 한 bit이기 때문에 숫자 font를 그대로 출력하는 것만으로는 제어할 수 없고, 현재 표시 중인 digit에 대해 DP bit를 따로 set/reset해야 한다.

수업의 핵심은 DP를 단순히 전체 FND에 한 번에 적용하는 것이 아니라, 1의 자리, 10의 자리, 100의 자리, 1000의 자리 중 어느 digit의 DP를 켤지 별도 상태값으로 관리하는 것이다. 이를 위해 FND driver 내부에 `fndDPData`를 두고, 각 bit를 각 digit의 DP 상태와 1:1로 대응시켰다.

## 현재 소스 위치

| 위치 | 내용 |
| :--- | :--- |
| [260625_MicroBlaze_GPIO](../helloHDL/260625_MicroBlaze_GPIO) | 0624 project를 복제해 만든 0625 MicroBlaze GPIO/StopWatch 작업본 |
| [StopWatch/src/main.c](../helloHDL/260625_MicroBlaze_GPIO/vitis_repo/StopWatch/src/main.c) | `StopWatch_Execute()`, `FND_Excute()`, `incTick()`, `delay_ms(1)` polling loop |
| [StopWatch.c](../helloHDL/260625_MicroBlaze_GPIO/vitis_repo/StopWatch/src/ap/StopWatch.c) | stopwatch time 구조체, DP 점멸, clear 처리, LED 상태 제어 |
| [StopWatch.h](../helloHDL/260625_MicroBlaze_GPIO/vitis_repo/StopWatch/src/ap/StopWatch.h) | stopwatch state enum, time 구조체, application API |
| [FND.c](../helloHDL/260625_MicroBlaze_GPIO/vitis_repo/StopWatch/src/driver/FND/FND.c) | FND digit multiplexing, DP state 저장, DP bit 반영 |
| [FND.h](../helloHDL/260625_MicroBlaze_GPIO/vitis_repo/StopWatch/src/driver/FND/FND.h) | FND digit define, `FND_DP_ON/OFF`, DP API 선언 |
| [button.c](../helloHDL/260625_MicroBlaze_GPIO/vitis_repo/StopWatch/src/driver/button/button.c) | run/stop, clear button 입력 처리 |
| [GPIO.c](../helloHDL/260625_MicroBlaze_GPIO/vitis_repo/StopWatch/src/HAL/GPIO/GPIO.c) | GPIO register 접근 HAL |
| [delay.c](../helloHDL/260625_MicroBlaze_GPIO/vitis_repo/StopWatch/src/common/delay/delay.c) | software tick과 delay 함수 |

## FND 제어 구조

FND는 3.3V GPIO로 제어하는 4자리 7-segment display를 한 자리씩 빠르게 선택해 표시한다. 실제로는 한 순간에 한 digit만 켜지만, `FND_DispNum()`이 `fndDigitState`를 계속 바꾸며 1의 자리, 10의 자리, 100의 자리, 1000의 자리를 순환하므로 사람 눈에는 4자리가 동시에 켜진 것처럼 보인다.

`FND.c`의 `fndFont[16]` 배열은 숫자 `0`부터 `9`, 16진수 표시용 `A`부터 `F`까지의 segment pattern을 담는다. 현재 회로는 active-low이므로 `0`을 표시하는 font 값은 `0xc0`, `1`을 표시하는 font 값은 `0xf9`처럼 꺼야 하는 segment bit가 `1`로 남는 형태다.

| 함수 | 역할 |
| :--- | :--- |
| `FND_Init()` | FND data GPIO 출력 설정, digit common GPIO 하위 4bit 출력 설정 |
| `FND_SetNum()` | 표시할 4자리 숫자 상태 저장 |
| `FND_Excute()` | 현재 숫자를 multiplexing 흐름으로 출력 |
| `FND_SelDigit()` | 4개 digit 중 하나만 선택 |
| `FND_DispDigit()` | 숫자 font와 DP bit를 합쳐 segment data 출력 |
| `FND_DispNum()` | digit state 순환, 자리값 계산, DP mask 반영 |

자리 선택은 `FND_SelDigit()`에서 공통선 GPIO의 하위 4bit를 먼저 모두 비활성화한 뒤, 선택할 digit bit만 active-low로 내리는 방식이다. 이 순서를 지키면 digit이 바뀌는 순간 이전 자리 segment와 다음 자리 선택 신호가 겹쳐 보이는 ghosting을 줄일 수 있다.

## FND Segment와 DP Bit

FND segment font table은 숫자 하나를 표시하기 위한 8-bit pattern이다. 현재 회로에서는 segment가 active-low로 동작하므로 bit가 `0`이면 해당 segment가 켜지고, bit가 `1`이면 꺼진다. 숫자 `1`처럼 특정 segment만 켜야 하는 경우에도 font 값은 segment 위치에 맞춰 active-low 값으로 만들어진다.

DP는 segment data 중 하나의 bit로 포함된다. 현재 코드에서는 `0x80`이 DP bit에 해당하며, DP를 켜려면 font 값에서 `0x80` bit를 `0`으로 만들고, DP를 끄려면 `0x80` bit를 `1`로 만든다.

```c
if (fndDP)
{
    fndData = fndFont[num] & ~(0x80);
}
else
{
    fndData = fndFont[num] | 0x80;
}
```

위 코드에서 `fndDP`는 실제 segment 출력값이 아니라, 현재 digit의 DP를 켤지 말지를 나타내는 조건값이다. C에서 조건식은 `0`이면 거짓이고, `0`이 아닌 값은 모두 참이다. 따라서 `1`, `2`, `4`, `8`, `-1` 같은 값은 조건문에서 모두 참으로 평가된다.

## DP 상태 저장 방식

digit별 DP 상태는 `fndDPData` 변수의 bit에 저장한다. 이 변수는 실제 FND segment 출력값이 아니라, 각 digit의 DP on/off 상태를 기억하기 위한 상태 저장 변수다.

| `fndDPData` bit | 대응 digit | 의미 |
| :---: | :---: | :--- |
| bit 0 | `FND_DIGIT_0` | 1의 자리 DP 상태 |
| bit 1 | `FND_DIGIT_1` | 10의 자리 DP 상태 |
| bit 2 | `FND_DIGIT_2` | 100의 자리 DP 상태 |
| bit 3 | `FND_DIGIT_3` | 1000의 자리 DP 상태 |

`FND_SetDP()`는 digit 번호와 DP 상태를 받아 해당 bit만 set/reset한다.

```c
void FND_SetDP(uint32_t fndDigitSel, uint32_t fndDpState)
{
    if (fndDpState == FND_DP_ON)
    {
        fndDPData |= 1 << fndDigitSel;
    }
    else
    {
        fndDPData &= ~(1 << fndDigitSel);
    }
}
```

이 방식은 bit mask를 이용해 특정 digit의 DP 상태만 바꾸고, 다른 digit의 DP 상태는 유지한다. 예를 들어 `FND_DIGIT_1`을 켜면 bit 1만 `1`이 되고, `FND_DIGIT_3`을 끄면 bit 3만 `0`으로 바뀐다.

## Digit Multiplexing과 DP 반영

`FND_DispNum()`은 호출될 때마다 `fndDigitState`를 `0 -> 1 -> 2 -> 3` 순서로 바꾸며 한 자리씩 표시한다. 각 자리 숫자를 출력할 때 `fndDPData`의 해당 bit를 함께 확인해 `FND_DispDigit()`에 넘긴다.

| `fndDigitState` | 표시 digit | 숫자 계산 | DP mask |
| :---: | :---: | :--- | :---: |
| `0` | `FND_DIGIT_0` | `num % 10` | `0x01` |
| `1` | `FND_DIGIT_1` | `(num / 10) % 10` | `0x02` |
| `2` | `FND_DIGIT_2` | `(num / 100) % 10` | `0x04` |
| `3` | `FND_DIGIT_3` | `(num / 1000) % 10` | `0x08` |

각 digit의 DP mask는 하나의 bit만 가져야 한다. 예를 들어 세 번째 digit은 `0x04`이고 네 번째 digit은 `0x08`이다. `0x03`처럼 여러 bit가 동시에 켜진 mask를 쓰면 의도하지 않은 DP 상태까지 참으로 해석될 수 있다.

## StopWatch 표시 보강

0625 코드에서는 기존 `counter` 중심 표시에서 `stopWatchTimeData` 구조체 중심 표시로 확장했다. `stopWatchTimeData`는 hour, min, sec, ms를 분리해서 저장하고, `StopWatch_IncTime()`에서 10 ms 단위로 증가한다.

```c
if (curTime - prevTime < 10)
    return;
prevTime = curTime;

if (stopWatchState == RUN)
{
    counter++;
    StopWatch_IncTime();
}
```

FND에 표시하는 값은 분, 초, 0.01초 단위를 조합해 만든다.

```c
FND_SetNum((stopWatchTimeData.min % 10 * 1000)
         + (stopWatchTimeData.sec * 10)
         + (stopWatchTimeData.ms / 10));
```

현재 표시 형식은 `분:초:0.1초` 방향으로 확장하기 위한 중간 구조다. `min`의 1자리, `sec`의 2자리, `ms / 10`의 1자리를 합쳐 4자리 FND에 표시한다.

## Stopwatch 함수 분리

표시 처리는 `StopWatch_Execute()` 내부에 모두 넣지 않고 `StopWatch_DispWatch()`로 분리했다. `StopWatch_Execute()`는 runtime 갱신, state 처리, display 처리를 순서대로 호출하는 상위 흐름만 담당하고, 실제 FND 숫자 조합과 DP 제어는 display 함수가 담당한다.

```c
void StopWatch_Execute()
{
    StopWatch_RunTime();
    StopWatch_ControlState();
    StopWatch_DispWatch();
}
```

함수를 새로 만들면 `.c` 파일 안에 구현을 추가하는 것만으로는 부족하다. 다른 파일에서 호출하거나 compile 단계에서 함수 prototype을 알아야 하는 경우 header에 선언을 추가해야 한다. 현재 작업본에서는 `StopWatch.h`에 `StopWatch_DispWatch()`와 `StopWatch_ClearTime()` 선언을 둔다.

| 함수 | 역할 |
| :--- | :--- |
| `StopWatch_DispWatch()` | `stopWatchTimeData`를 FND 4자리 값으로 변환하고 DP 상태 설정 |
| `StopWatch_ClearTime()` | hour, min, sec, ms를 모두 0으로 초기화 |
| `StopWatch_Execute()` | runtime, state, display 순서로 application 흐름 실행 |

## DP 점멸

`StopWatch_DispWatch()`에서는 DP를 두 위치에서 별도로 점멸시킨다. 하나는 0.1초 단위에 맞춘 빠른 점멸이고, 다른 하나는 0.5초 on/off 흐름이다.

| DP 위치 | 조건 | 의미 |
| :---: | :--- | :--- |
| `FND_DIGIT_1` | `stopWatchTimeData.ms % 10 < 5` | 0.05초 단위 on/off 후보 |
| `FND_DIGIT_3` | `stopWatchTimeData.ms < 50` | 0.5초 on/off 후보 |

DP는 숫자 자체와 별도 상태로 제어한다. 숫자는 `FND_SetNum()`으로 넘기고, DP는 `FND_SetDP()`로 개별 digit의 상태를 바꾸는 구조다. 따라서 특정 순간에 두 DP가 동시에 켜질 수 있으며, 이는 `StopWatch_DispWatch()`에서 두 위치를 동시에 on/off 조건으로 관리하기 때문이다.

## Button과 Clear 동작

button mapping은 0624 구조를 유지한다. `GPIOB[4]`는 run/stop button, `GPIOB[5]`는 clear button이다. `Button_Init()`에서는 기존 GPIOB 설정을 읽은 뒤 4번, 5번 bit만 input으로 바꾼다. 이렇게 해야 `GPIOB[0]~GPIOB[3]`에 연결된 FND digit common 출력 설정을 유지하면서 button pin만 입력으로 사용할 수 있다.

| Button handle | GPIO pin | Board 역할 | 현재 동작 |
| :--- | :---: | :--- | :--- |
| `hbtnRunStop` | `GPIOB[4]` | BTNU | `STOP <-> RUN` 전환 |
| `hbtnClear` | `GPIOB[5]` | BTND | `STOP` 상태에서 clear |

현재 state machine 의도는 RUN 중 clear 불가, STOP 상태에서만 clear 가능이다. 따라서 `RUN` 상태에서는 run/stop button만 확인하고, clear button은 `STOP` 상태에서만 확인한다.

0625 코드에서는 표시값이 `counter`가 아니라 `stopWatchTimeData`에서 계산되므로, clear 시 `counter = 0`만 수행하면 FND 표시가 초기화되지 않는다. 그래서 `CLEAR` 상태에서는 `StopWatch_ClearTime()`까지 호출해 hour, min, sec, ms를 함께 0으로 만들어야 한다.

```c
case CLEAR:
    stopWatchState = STOP;
    counter = 0;
    StopWatch_ClearTime();
    break;
```

## Button Debounce

현재 button driver는 software debounce 방식이다. button 상태가 `RELEASED -> PUSHED`로 바뀌면 `ACT_PUSHED`를 반환하고, `PUSHED -> RELEASED`로 바뀌면 `ACT_RELEASED`를 반환한다. 상태 변화가 감지된 뒤 `delay_ms(5)`를 넣어 채터링 구간을 짧게 건너뛴다.

| 구분 | 현재 방식 |
| :--- | :--- |
| Debounce 위치 | `button.c`의 `Button_GetState()` |
| 감지 기준 | 현재 입력과 이전 상태 비교 |
| 지연 시간 | 상태 변화 후 `delay_ms(5)` |
| 성격 | software debounce |

이전에 Verilog로 작성했던 button debounce는 hardware debounce이고, 현재 MicroBlaze application에서 사용하는 방식은 software debounce다. hardware debounce는 RTL에서 입력 신호를 안정화하고, software debounce는 입력이 바뀐 뒤 짧은 지연을 넣어 반복 인식을 줄인다.

## Delay 기반 시간 측정의 한계

현재 `main.c`는 `while (1)` 안에서 `StopWatch_Execute()`, `FND_Excute()`, `incTick()`, `delay_ms(1)`을 반복한다. 이 구조에서는 `delay_ms(1)`을 기준으로 software tick을 증가시키지만, loop 내부에서 실행되는 코드량에 따라 실제 1 ms와 조금씩 차이가 생긴다.

```c
while (1)
{
    StopWatch_Execute();
    FND_Excute();
    incTick();
    delay_ms(1);
}
```

따라서 FND display refresh나 간단한 stopwatch 실습에는 사용할 수 있지만, 정확한 시간 기준으로 보기에는 한계가 있다. 코드가 늘어나면 loop 한 바퀴에 걸리는 시간이 달라지고, 그만큼 `millis()` 기반 시간도 실제 시간에서 밀릴 수 있다.

## 다음에 확인할 것

| 항목 | 확인 내용 |
| :--- | :--- |
| Vitis build | `StopWatch` ELF가 최신 source를 반영했는지 확인 |
| Bitstream/XSA | hardware 변경이 있을 경우 bitstream과 XSA 재생성 |
| Board 동작 | run/stop, stop 상태 clear, DP 점멸, FND 표시값 확인 |
| 과제 확장 | 최종 표시 형식을 `분:초:0.1초` 요구사항에 맞춰 정리 |
