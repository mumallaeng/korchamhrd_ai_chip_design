# 26-06-24 - SoC Application, AXI Peripheral 발표 방향, GPIO HAL/LED/FND Driver

## 수업 흐름

0623 수업에서 만든 MicroBlaze 기반 GPIO system을 이어서, SoC에서 hardware peripheral만 만드는 것으로는 실제 동작이 완성되지 않는다는 점을 정리했다. CPU와 peripheral이 들어간 SoC는 firmware가 올라가야 동작하며, MicroBlaze도 C application이 어떤 register를 읽고 쓰느냐에 따라 board 동작이 결정된다.

따라서 이번 프로젝트의 핵심은 AXI로 연결되는 peripheral 설계, register map, system architecture, firmware 제어 흐름을 함께 설명하는 것이다. 발표 요구사항은 별도 project note로 분리하고, 이 노트에서는 수업 흐름과 firmware 계층화 내용을 중심으로 남긴다.

이후에는 GPIO 접근 코드를 계층화하는 방향으로 진행했다. 직접 `GPIOC->ODR`에 값을 쓰는 방식에서 출발해, `GPIO_SetMode()`, `GPIO_WritePort()`, `GPIO_GetODR()` 같은 HAL 함수를 만들고, 그 위에 LED driver 함수를 두어 application code가 더 단순해지도록 정리했다.

오전 후반에는 LED driver와 같은 방식으로 FND driver를 분리했다. FND는 segment data GPIO와 digit common GPIO를 나누어 사용하며, 숫자 하나를 표시하려면 digit 선택과 segment font 출력이 함께 필요하다. 여러 자리 숫자는 한 번에 모두 켜는 것이 아니라 digit을 빠르게 바꿔가며 하나씩 표시하고, 사람 눈에는 잔상 때문에 전체가 동시에 켜진 것처럼 보이게 만든다.

오후에는 FND 표시를 계속 유지하면서 stopwatch처럼 일정 시간마다 값만 갱신하는 구조로 넘어갔다. `sleep()`처럼 한 위치에서 오래 멈추는 코드는 FND refresh를 끊기게 만들기 때문에, main loop 안에서 `FND_Excute()`, `incTick()`, `delay_ms(1)`을 계속 돌리고, 시간 조건이 맞을 때만 counter 값을 바꾸는 polling 구조를 사용한다.

마지막으로 button 입력을 추가했다. 처음에는 하나의 button만 읽는 함수로 출발했지만, button이 여러 개가 되면 GPIO port, pin mask, 이전 상태를 button별로 따로 보관해야 한다. 그래서 `hbutton` 구조체를 만들고, run/stop button과 clear button을 같은 `Button_GetState()` 함수로 처리하는 방향으로 정리했다.

이후에는 LED, FND, button driver를 재료로 보고 `StopWatch` application 계층을 만들었다. `STOP`, `RUN`, `CLEAR` 상태를 두고, run/stop button으로 counter 동작을 제어하며, clear button으로 counter와 LED 표시를 초기화하는 흐름이다. RUN 상태에서는 하위 8개 LED 중 한 개만 켜진 채 0.1초마다 left shift하고, STOP 상태에서는 LED가 현재 위치에서 멈추도록 요구사항을 정리했다.

## 현재 소스 위치

| 위치 | 내용 |
| :--- | :--- |
| [260624_MicroBlaze_GPIO](../helloHDL/260624_MicroBlaze_GPIO) | 0624 작업본으로 분리한 MicroBlaze GPIO/StopWatch project |
| [StopWatch/src/main.c](../helloHDL/260624_MicroBlaze_GPIO/vitis_repo/StopWatch/src/main.c) | `StopWatch_Execute()`, `FND_Excute()`, `incTick()` polling loop |
| [StopWatch.c](../helloHDL/260624_MicroBlaze_GPIO/vitis_repo/StopWatch/src/ap/StopWatch.c) | stopwatch state, counter, LED 이동, button 제어 |
| [StopWatch.h](../helloHDL/260624_MicroBlaze_GPIO/vitis_repo/StopWatch/src/ap/StopWatch.h) | stopwatch state enum과 application API |
| [GPIO.c](../helloHDL/260624_MicroBlaze_GPIO/vitis_repo/StopWatch/src/HAL/GPIO/GPIO.c) | GPIO HAL 함수 구현 |
| [GPIO.h](../helloHDL/260624_MicroBlaze_GPIO/vitis_repo/StopWatch/src/HAL/GPIO/GPIO.h) | GPIO register 구조체, base address, pin mask, HAL prototype |
| [LED.c](../helloHDL/260624_MicroBlaze_GPIO/vitis_repo/StopWatch/src/driver/LED/LED.c) | 16bit LED port 출력과 pin 제어 |
| [LED.h](../helloHDL/260624_MicroBlaze_GPIO/vitis_repo/StopWatch/src/driver/LED/LED.h) | LED low/high GPIO 연결과 API 선언 |
| [FND.c](../helloHDL/260624_MicroBlaze_GPIO/vitis_repo/StopWatch/src/driver/FND/FND.c) | FND digit 선택, font 출력, 자리 순환 |
| [FND.h](../helloHDL/260624_MicroBlaze_GPIO/vitis_repo/StopWatch/src/driver/FND/FND.h) | FND data/common GPIO 연결과 digit define |
| [button.c](../helloHDL/260624_MicroBlaze_GPIO/vitis_repo/StopWatch/src/driver/button/button.c) | button handler 초기화, edge 상태 판단, debounce |
| [button.h](../helloHDL/260624_MicroBlaze_GPIO/vitis_repo/StopWatch/src/driver/button/button.h) | button 상태 enum, `hbutton` 구조체, run/stop 및 clear handle |
| [delay.c](../helloHDL/260624_MicroBlaze_GPIO/vitis_repo/StopWatch/src/common/delay/delay.c) | `millis()`, `incTick()`, `delay_ms/us/sec()` 공통 시간 함수 |
| [delay.h](../helloHDL/260624_MicroBlaze_GPIO/vitis_repo/StopWatch/src/common/delay/delay.h) | common delay API 선언 |
| [ip_repo/gpio_1.0](../helloHDL/ip_repo/gpio_1.0) | 직접 만든 AXI4-Lite GPIO custom IP |

0624 내용은 0623 `260623_MicroBlaze_GPIO` project에서 이어진 firmware 계층화 작업이다. 현재 작업본은 [260624_MicroBlaze_GPIO](../helloHDL/260624_MicroBlaze_GPIO)로 복제해 분리했으므로, 이후 노트의 소스 연결은 260624 project를 기준으로 둔다.

## SoC에서 C Application이 필요한 이유

SoC에서 CPU와 peripheral hardware만 만들어 두면 그 자체로는 의미 있는 동작이 나오지 않는다. CPU는 program을 실행하는 장치이고, peripheral은 CPU가 register를 읽고 쓰면서 기능이 드러나는 장치다. 따라서 custom IP를 만들었다면 그 IP를 제어하는 firmware까지 함께 준비해야 한다.

| 항목 | 의미 |
| :--- | :--- |
| CPU | program이 올라가야 동작 |
| Peripheral | register 접근으로 기능 제어 |
| C application | peripheral 동작 순서와 정책 작성 |
| AXI | CPU와 peripheral register 사이의 접근 경로 |
| Register map | software가 접근할 주소와 bit 의미 |

이 관점에서 C는 SoC 실습에서 부가 요소가 아니라 필수 요소다. MicroBlaze가 custom GPIO, UART, SPI, I2C 같은 peripheral을 제어하려면 C code에서 base address와 offset을 기준으로 register를 읽고 써야 한다.

## 발표 요구사항 연결

260630 AXI project 발표 요구사항은 [26-06-24 - AXI Project 발표 요구사항](../assignment/_project/260630-axi-peripherial/10-presentation-requirements-260624.md)에 따로 정리했다. 발표 쪽 문서는 AXI peripheral을 메인으로 두고, system architecture, Xilinx AXI template와 custom IP 연동, register map, firmware, UVM 검증 범위, UART/SPI/I2C demo 방향을 구체적으로 다룬다.

## Firmware 계층 구조

오늘 코드 정리는 Application, Driver, HAL, Hardware를 나누는 방향으로 진행했다. Application에서 직접 GPIO register를 만지면 빠르게 동작 확인은 가능하지만, LED 연결 방식이나 GPIO port 배치가 바뀔 때 application 전체가 흔들린다. 그래서 application은 LED driver를 호출하고, LED driver는 GPIO HAL을 호출하며, GPIO HAL만 실제 register 접근을 담당하도록 계층을 나눈다.

| 계층 | 현재 코드 기준 역할 |
| :--- | :--- |
| Application | `main()` polling loop와 `StopWatch` state/counter 정책 |
| LED driver | `LED_Init()`, `LED_WritePort16()`, `LED_PinToggle()` 등 LED 기능 API |
| FND driver | `FND_Init()`, `FND_SelDigit()`, `FND_DispDigit()`, `FND_DispNum()` 등 FND 표시 API |
| Button driver | `Button_Init()`, `Button_SetInit()`, `Button_GetState()` 등 button edge 처리 API |
| GPIO HAL | `GPIO_SetMode()`, `GPIO_WritePort()`, `GPIO_GetODR()` 등 register 접근 함수 |
| Common | `millis()`, `incTick()`, `delay_ms()` 등 공통 시간 함수 |
| Custom GPIO IP | AXI4-Lite register와 `io_port` 방향/출력 제어 |
| Board hardware | 실제 LED, FND, button, switch pin 동작 |

이 구조에서 BSP나 driver 개발자는 peripheral을 동작시키기 위한 HAL/driver 코드를 작성한다. Application 개발자는 LED가 GPIOC/GPIOD 중 어디에 연결되었는지보다 `LED_PinToggle(2)`처럼 의도가 드러나는 API를 사용하게 된다.

## GPIO HAL 변경점

`GPIO.c`에는 기존 port write/read 함수에 더해 `GPIO_GetODR()`이 추가되어 있다. `GPIO_ReadPort()`는 `IDR`을 읽는 함수이므로 현재 output register 상태를 확인하는 용도로는 맞지 않다. LED pin을 toggle하려면 현재 출력 상태를 알아야 하므로, `ODR`을 읽는 별도 함수가 필요하다.

| 함수 | 현재 역할 |
| :--- | :--- |
| `GPIO_SetMode(GPIOx, mode)` | `CR`에 direction 설정값 write |
| `GPIO_WritePort(GPIOx, data)` | `ODR` 전체 출력값 write |
| `GPIO_WritePin(GPIOx, gpio_pin, state)` | `ODR` 특정 bit set/reset |
| `GPIO_ReadPort(GPIOx)` | `IDR` 전체 입력값 read |
| `GPIO_ReadPin(GPIOx, gpio_pin)` | `IDR` 특정 bit read |
| `GPIO_GetODR(GPIOx)` | 현재 `ODR` 출력 latch 값 read |

`GPIO.h`에는 `GPIOA~GPIOD` base address, `GPIO_PIN_0~GPIO_PIN_7`, `GPIO_SET/GPIO_RESET` define, 그리고 HAL 함수 prototype이 정리되어 있다. `GPIO_TypeDef` 구조체는 `CR`, `IDR`, `ODR` register layout을 C 구조체로 표현한다.

## Bit Manipulation

GPIO와 LED 제어는 port 전체 값을 한 번에 덮어쓰는 방식과 특정 bit만 바꾸는 방식으로 나눌 수 있다. LED나 button처럼 여러 신호가 하나의 8-bit port에 함께 묶이면, 현재 port 상태를 유지하면서 필요한 bit만 set/reset/toggle하는 연산이 중요하다.

| 동작 | 연산 | 의미 |
| :--- | :--- | :--- |
| Bit set | `value |= (1 << bit)` | 특정 bit만 `1`로 설정 |
| Bit reset | `value &= ~(1 << bit)` | 특정 bit만 `0`으로 설정 |
| Bit toggle | `value ^= (1 << bit)` | 특정 bit만 반전 |

예를 들어 `ledState |= (1 << 2)`는 2번 bit만 `1`로 만들고, 다른 bit 값은 유지한다. `ledState &= ~(1 << 4)`는 4번 bit만 `0`으로 만들며, `ledState ^= (1 << 3)`은 3번 bit가 `0`이면 `1`, `1`이면 `0`으로 바꾼다.

XOR toggle은 LED 상태 표시에서 자주 사용된다. 같은 bit mask와 XOR하면 해당 bit만 바뀌고, mask에 `0`인 bit는 원래 상태가 유지된다. 이 원리 때문에 `LED_PinToggle()` 같은 함수는 기존 `ODR` 값을 읽고 특정 LED bit만 XOR한 뒤 다시 write하는 구조로 구현할 수 있다.

## LED Driver 구조

현재 `main.c`에서는 LED 하위 8bit를 `GPIOC`, 상위 8bit를 `GPIOD`에 연결한 16bit LED port처럼 사용한다.

| Symbol | 의미 |
| :--- | :--- |
| `LED_LOW_GPIO` | LED 0~7, `GPIOC` |
| `LED_HI_GPIO` | LED 8~15, `GPIOD` |
| `LED_Init()` | 두 GPIO port를 output mode로 설정 |
| `LED_WritePort8()` | 선택한 8bit GPIO port 전체 출력 |
| `LED_WritePort16()` | 16bit LED 값을 low/high 8bit로 분리해 출력 |
| `LED_PinOn()` | 특정 LED bit set |
| `LED_PinOff()` | 특정 LED bit reset |
| `LED_PinToggle()` | 특정 LED bit XOR toggle |

초기 확인 단계에서는 `main()`에서 `LED_Init()` 후 `LED_PinToggle()`과 지연 함수를 직접 호출해 LED driver 동작을 확인했다. 현재 `StopWatch` 구조에서는 `main()`이 LED를 직접 제어하지 않고, `StopWatch_RunLED()`, `StopWatch_StopLED()`, `StopWatch_ClearLED()`가 LED driver API를 호출한다. 이 형태에서는 application이 `GPIOC->ODR`나 `GPIOD->ODR`를 직접 쓰지 않고, 상태에 맞는 LED 동작만 요청한다.

## FND Driver 구조

FND는 data GPIO와 common GPIO를 분리해서 다룬다. `FND_DATA_GPIO`는 segment pattern을 출력하는 GPIOA이고, `FND_COM_GPIO`는 어떤 digit을 켤지 선택하는 GPIOB다. `FND_Init()`에서는 common 하위 4bit와 data 8bit를 output으로 설정한다.

| Symbol | 의미 |
| :--- | :--- |
| `FND_DATA_GPIO` | segment data 출력, `GPIOA` |
| `FND_COM_GPIO` | digit common 선택, `GPIOB` |
| `FND_DIGIT_0~3` | 4자리 FND 위치 번호 |
| `FND_Init()` | common 하위 4bit와 segment 8bit output 설정 |
| `FND_SelDigit()` | 표시할 digit 위치 선택 |
| `FND_DispDigit()` | 숫자 0~9를 segment font 값으로 변환해 출력 |
| `FND_DispAllOff()` | digit common 하위 4bit를 모두 비활성 상태로 설정 |
| `FND_DispNum()` | 1/10/100/1000 자리 순환 표시 |

`FND_DispDigit()`에는 7-segment font table이 들어 있다. 숫자 `0`은 `0xc0`, `1`은 `0xf9`처럼 segment on/off pattern으로 변환된다. 현재 FND 회로는 segment가 active-low로 동작하므로, bit가 `0`인 segment가 켜지는 방식으로 해석해야 한다.

여러 자리 숫자를 표시할 때는 4개 digit을 동시에 제어하는 것이 아니라 한 번에 한 digit만 선택한다. `FND_DispNum()`은 `static` 변수 `fndDigitState`를 사용해 함수 호출마다 `0 -> 1 -> 2 -> 3` 순서로 digit을 바꾸고, `switch-case`에서 각 자리값을 선택한다.

digit을 바꾸기 전에 `FND_DispAllOff()`로 common 하위 4bit를 모두 비활성 상태로 만든다. 이전 digit이 켜진 상태에서 segment data만 먼저 바뀌면 순간적으로 다른 digit에 잘못된 segment pattern이 보일 수 있다. 따라서 전체 off, segment data 출력, digit 선택 순서로 정리하면 표시 전환이 더 깔끔해진다.

| `fndDigitState` | 선택 digit | 표시 값 |
| :---: | :---: | :--- |
| `0` | `FND_DIGIT_0` | `num % 10` |
| `1` | `FND_DIGIT_1` | `(num / 10) % 10` |
| `2` | `FND_DIGIT_2` | `(num / 100) % 10` |
| `3` | `FND_DIGIT_3` | `(num / 1000) % 10` |

이 방식은 각 digit을 매우 빠르게 반복 표시하는 multiplexing 방식이다. 한 순간에는 한 자리만 켜지지만, 반복 주기가 충분히 빠르면 사람 눈에는 네 자리 숫자가 동시에 표시되는 것처럼 보인다.

과제 형태로 확장할 때는 단순 counter 값을 `0000~9999`로 출력하는 데서 끝나지 않고, stopwatch 시간 형식에 맞게 자리 의미를 다시 잡아야 한다. 하위 한 자리는 0.1초 단위, 가운데 두 자리는 초 단위, 상위 한 자리는 분 단위 표시로 사용할 수 있다. 이때 내부 시간 변수는 분/초/0.1초 값을 따로 유지하고, FND driver는 표시할 자리마다 어떤 값을 내보낼지 선택하는 방식으로 확장한다.

| 표시 자리 | 의미 | 값 범위 |
| :--- | :--- | :--- |
| 하위 1자리 | 0.1초 단위 | `0~9` |
| 가운데 2자리 | 초 단위 | `00~59` |
| 상위 1자리 | 분 단위 | 표시 범위 내 분 값 |

추가로 FND dot을 사용할 수 있으면 시간 구분 표시로 활용할 수 있다. 예를 들어 0.1초 자리의 dot은 0.05초 on, 0.05초 off로 빠르게 깜빡이게 만들고, 초/분 구분 dot은 0.5초 on, 0.5초 off로 1초 주기 표시를 만들 수 있다. 이 부분은 기본 stopwatch 표시가 먼저 동작한 뒤 FND driver를 확장하는 항목으로 두면 된다.

## Common Delay와 Polling Tick

`common/delay`는 특정 장치 driver라기보다 여러 application과 driver에서 같이 쓰는 공통 함수 묶음이다. `delay_sec()`, `delay_ms()`, `delay_us()`는 Xilinx bare-metal 환경의 `sleep()`과 `usleep()`을 감싸서 이름을 맞춘 함수이고, `millis()`와 `incTick()`은 main loop에서 software tick을 누적하기 위한 함수다.

| 함수 | 현재 역할 |
| :--- | :--- |
| `delay_sec(sec)` | 초 단위 대기 |
| `delay_ms(ms)` | millisecond 단위 대기 |
| `delay_us(us)` | microsecond 단위 대기 |
| `incTick()` | `m_tick` 1 증가 |
| `millis()` | 현재 누적 tick 값 반환 |

현재 main loop는 `delay_ms(1)`을 한 번 호출하고 `incTick()`으로 tick을 증가시킨다. 이 구조에서는 loop가 계속 돌면서 FND refresh를 수행하고, 별도의 조건식으로 `millis()` 또는 누적 tick 차이를 비교해 0.1초 단위 counter update를 만들 수 있다.

중요한 점은 FND 표시와 stopwatch 시간 갱신을 같은 지연 함수 안에 묶어 오래 멈추지 않는 것이다. 예를 들어 0.1초마다 counter를 증가시키고 싶다고 해서 `delay_ms(100)`을 loop 중간에 넣으면, 그동안 FND refresh도 멈추어 깜빡임이 커진다. 대신 loop는 1ms 단위로 계속 돌고, `curTime - prevTime >= 100` 같은 조건이 참일 때만 counter를 갱신하는 polling 흐름이 더 적합하다.

이 방식은 RTL의 `posedge clk`에 맞춰 동작하는 동기 회로가 아니다. 그렇다고 입력 변화가 생기는 즉시 interrupt handler가 실행되는 완전한 비동기 구조도 아니다. C firmware 관점에서는 `millis()`가 제공하는 software tick을 기준으로 main loop가 주기적으로 상태를 확인하는 방식이다.

```c
if (curTime - prevTime < 100)
    return;
prevTime = curTime;
```

위 조건은 hardware clock edge가 아니라 `incTick()`으로 누적한 software time을 기준으로 한다. 따라서 현재 구조의 핵심은 `FND_Excute()`처럼 자주 호출되어야 하는 routine은 매 loop 실행하고, stopwatch counter나 LED 이동처럼 느리게 바뀌어야 하는 동작은 tick 차이가 일정 기준을 넘을 때만 실행하는 것이다.

## StopWatch Application 구조

`StopWatch` application 계층은 button 입력, counter 값, FND 표시값, LED 상태 표시를 하나의 상태 흐름으로 묶는다. `main()`은 직접 LED/FND/button 세부 동작을 처리하지 않고, loop마다 `StopWatch_Execute()`를 호출한다. 이후 FND 표시 유지를 위해 `FND_Excute()`, `incTick()`, `delay_ms(1)`을 계속 실행한다.

| 함수 | 역할 |
| :--- | :--- |
| `StopWatch_Init()` | LED/FND/Button 초기화와 초기 상태 설정 |
| `StopWatch_Execute()` | runtime, state control, FND value, LED state 제어 호출 |
| `StopWatch_ControlState()` | run/stop button과 clear button event 처리 |
| `StopWatch_RunTime()` | `millis()` 기준 100ms counter update |
| `StopWatch_ControlLED()` | state에 따른 LED 표시 분기 |
| `StopWatch_RunLED()` | RUN 상태 LED left shift |
| `StopWatch_StopLED()` | STOP 상태 LED 표시 |
| `StopWatch_ClearLED()` | LED 초기 위치 복귀 |

현재 상태는 `STOP`, `RUN`, `CLEAR` 세 가지로 나눈다. `STOP`에서 run/stop button이 눌리면 `RUN`으로 바뀌고, `RUN`에서 다시 run/stop button이 눌리면 `STOP`으로 돌아간다. 현재 코드 기준 clear button은 `STOP` 상태에서 `CLEAR`로 들어가는 입력이며, `CLEAR`에서는 counter를 `0`으로 초기화한 뒤 다시 `STOP` 상태로 복귀한다.

| 상태 | button 입력 | 처리 |
| :---: | :--- | :--- |
| `STOP` | run/stop push | `RUN` 전환 |
| `STOP` | clear push | `CLEAR` 전환 |
| `RUN` | run/stop push | `STOP` 전환 |
| `CLEAR` | 내부 처리 | counter/FND 초기화 후 `STOP` 복귀 |

LED 이동은 8-bit 값을 bit mask처럼 사용한다. 초기값을 `0x01`로 두고, RUN 상태에서 0.1초마다 왼쪽으로 한 칸 이동시킨다. STOP 상태가 되면 `stopWatchLED` 값을 바꾸지 않으므로 LED가 현재 위치에 멈춰 있고, 다시 RUN 상태가 되면 그 위치에서 이어서 이동한다. 최상위 bit가 넘어가면 다시 bit 0으로 돌아와야 하므로, 순환 left shift는 아래처럼 표현한다.

```c
stopWatchLED = (stopWatchLED << 1) | (stopWatchLED >> 7);
```

상태 표시 LED는 상위 8bit LED 쪽을 사용한다. 현재 코드에서는 STOP 표시를 5번 bit, RUN 표시를 7번 bit로 두고, 상태가 바뀔 때 `stopWatchStateLED` 값을 set/reset한 뒤 `LED_HI_GPIO`에 출력한다. 하위 8bit LED는 stopwatch 진행 위치 표시, 상위 8bit LED는 state 표시로 역할을 나눈 구조다.

| LED 용도 | GPIO | bit | 의미 |
| :--- | :--- | :--- | :--- |
| 진행 위치 | `LED_LOW_GPIO` | `0~7` | RUN 중 한 개 LED left shift |
| STOP 상태 | `LED_HI_GPIO` | `5` | STOP 상태 표시 |
| RUN 상태 | `LED_HI_GPIO` | `7` | RUN 상태 표시 |

스톱워치 요구 기능은 run/stop button으로 counter 진행을 제어하고, clear button으로 counter를 초기화하며, FND에는 현재 시간을 표시하는 것이다. 최종 형태에서는 0.1초/초/분처럼 읽을 수 있는 형식으로 변환하고, LED는 RUN 상태를 눈으로 확인할 수 있도록 한 개의 LED가 순차적으로 이동하는 형태로 연결한다.

## Button Driver 구조

button 입력은 `GPIOB`의 4번, 5번 pin을 사용한다. FND common은 `GPIOB` 하위 4bit를 출력으로 사용하므로, button 초기화에서는 기존 `GPIOB` control register 값을 읽고 4번, 5번 bit만 input mode가 되도록 0으로 만든다. 이렇게 해야 FND common 설정을 유지하면서 button pin만 입력으로 바꿀 수 있다.

| 항목 | 현재 코드 기준 |
| :--- | :--- |
| Run/Stop button | `GPIOB`, `GPIO_PIN_4` |
| Clear button | `GPIOB`, `GPIO_PIN_5` |
| Input 설정 | `GPIO_GetCR(GPIOB)` 후 4번, 5번 bit clear |
| 상태 저장 | `hbutton.prevState` |
| 이벤트 반환 | `NO_ACT`, `ACT_PUSHED`, `ACT_RELEASED` |
| Debounce | 상태 변화 감지 후 `delay_ms(5)` |

`Button_GetState()`는 현재 pin 값을 읽어 `PUSHED` 또는 `RELEASED`로 변환하고, 이전 상태와 비교해 edge를 판단한다. 현재 상태가 `PUSHED`이고 이전 상태가 `RELEASED`이면 `ACT_PUSHED`, 현재 상태가 `RELEASED`이고 이전 상태가 `PUSHED`이면 `ACT_RELEASED`를 반환한다. 상태 변화가 없으면 `NO_ACT`를 반환한다.

button이 하나일 때는 함수 내부의 `static prevState`만으로도 동작할 수 있다. 하지만 button이 여러 개가 되면 button마다 GPIO port, pin, 이전 상태가 달라진다. 그래서 현재 코드는 `hbutton` 구조체에 `GPIOx`, `gpio_pin`, `prevState`를 묶고, `hbtnRunStop`, `hbtnClear`를 각각 초기화한다.

```c
typedef struct
{
    GPIO_TypeDef *GPIOx;
    uint32_t gpio_pin;
    button_state_e prevState;
} hbutton;
```

button driver 확인 단계에서는 두 button을 같은 함수로 읽고 각각 다른 LED를 toggle하는 방식으로 edge 검출을 확인했다. 현재 `StopWatch` application에서는 `StopWatch_ControlState()`가 `ACT_PUSHED` event를 받아 run/stop 상태 전환과 clear 상태 진입을 처리한다.

## 과제 연결

이번 과제 제목은 `20260624_StopWatch FND Display 수정`이다. 기존 StopWatch 수업 코드를 보존한 뒤, 별도 과제 작업에서 FND 표시 부분을 시간 형태로 바꾸는 것이 핵심이다.

요구사항은 FND에 분:초:0.1초가 보이도록 표시 로직을 수정하는 것이다. 내부적으로는 run/stop/clear 버튼 흐름을 유지하면서 mode 전환을 추가해, `시:분` 표시와 `초:밀리초` 표시를 오갈 수 있게 구성하면 된다. 제출물은 수정한 code와 실제 board 동작 영상이다.

| 항목 | 요구사항 |
| :--- | :--- |
| 과제명 | `20260624_StopWatch FND Display 수정` |
| FND 표시 | 분:초:0.1초 형태 |
| Mode 전환 | `시:분` / `초:밀리초` 표시 전환 |
| 기본 동작 | run-stop-clear 흐름 유지 |
| 제출물 | 수정 code, board 동작 영상 |

## 다음에 확인할 것

현재 LED driver는 16bit LED를 `GPIOC/GPIOD` 두 8bit port로 나누어 다룬다. 상위 8bit를 `GPIOD`에 쓸 때는 16bit mask를 8bit port 값으로 맞추는 처리가 정확해야 한다. `LED_PinOn()`, `LED_PinOff()`, `LED_PinToggle()`에서 high byte 처리 방식이 서로 같은 기준인지 확인하고, board에서 LED 0~15 각각이 의도한 위치에서 toggle되는지 확인해야 한다.

FND 쪽은 `FND_SelDigit()`의 lower nibble 선택식과 common active polarity를 board에서 확인해야 한다. 기존 상위 bit는 유지하고 하위 4bit만 digit 선택에 사용한다는 의도와 실제 mask 연산이 일치하는지 확인이 필요하다.

과제에서는 FND 표시를 stopwatch 시간 형식으로 바꾸어야 한다. 현재 `FND_DispNum()`은 입력 숫자를 1/10/100/1000 자리로 나누어 표시하므로, 0.1초/초/분 표시를 위해서는 `FND_SetNum()`에 넘길 값을 단순 counter가 아니라 표시용 시간 값으로 변환하거나, FND driver 안에서 자리별 값 선택 방식을 확장해야 한다.

Button 쪽은 software 구조만으로는 충분하지 않고, custom GPIO IP의 `IDR` 값이 AXI read path로 실제 노출되어야 한다. `GPIO_ReadPin()`은 C 구조체의 `IDR` offset을 읽으므로, AXI slave read mux에서 `2'h1` 주소가 저장용 `slv_reg1`이 아니라 실제 input `idr`을 반환해야 button 상태가 software에 전달된다.

다음 수업에서는 timer peripheral과 interrupt를 추가하는 흐름으로 이어질 예정이다. 현재 구조는 software polling tick으로 시간을 만들고 있으므로, timer peripheral이 들어오면 `millis()`/`incTick()`의 기준을 hardware timer 또는 interrupt service routine과 연결하는 방향으로 확장할 수 있다.

발표 자료에 넣을 상세 요구사항은 project note에서 관리한다. 수업 노트에서는 `Register map -> GPIO HAL -> LED/FND driver -> Application` 흐름이 오늘 firmware 구조의 핵심이라는 점만 남긴다.
