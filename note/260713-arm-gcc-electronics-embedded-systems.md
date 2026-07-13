# 26-07-13 - ARM GCC Toolchain, 전자 소자, 컴퓨터·임베디드 시스템

관련 노트:

- [PC GNU 컴파일 환경 설치 가이드](pc-gnu-compiler-environment.md)
- [ARM Cortex-M4 디바이스 프로그래밍 과목 지도](arm-cortex-m4-device-programming.md)

## 수업 흐름

정리 범위는 ARM 대상 toolchain, 2과 `능동 소자와 집적 회로`, 3과 `컴퓨터와 임베디드 시스템`, 4과 `STM32F411xE MCU와 실습보드`다.
4과에서 STM32F411xE MCU, Nucleo-64 보드, memory map과 주변장치 register의 연결을 확인함.

```text
C source
  -> ARM compiler toolchain
  -> firmware image
  -> STM32F411 Flash
  -> memory map
  -> peripheral register
```

## ARM GCC Toolchain과 Cross Compilation

### PC용 compiler와 ARM용 compiler

PC에서 실행할 프로그램과 ARM MCU에서 실행할 firmware는 대상 CPU의 명령어가 다르다.
ARM 대상 code를 만드는 별도 compiler toolchain이 필요하다.

| 구분 | PC C 실습 | ARM MCU 실습 |
| :--- | :--- | :--- |
| host | Windows PC | Windows PC |
| target | PC CPU와 운영체제 | ARM Cortex-M MCU |
| 필요한 compiler | PC 대상 GCC | ARM 대상 GCC toolchain |
| 산출물 용도 | PC에서 직접 실행 | MCU Flash에 기록할 firmware 생성 |

`cross compilation`은 host와 target이 다른 build 방식이다.
compiler는 PC에서 실행되지만, 결과물은 ARM MCU의 instruction set과 memory layout에 맞춰 생성한다.

### C source가 실행 결과물로 바뀌는 흐름

```text
C source
  -> compiler
  -> object file
  -> linker
  -> executable 또는 firmware image
```

compiler는 C 문법과 type 규칙을 검사하고 source를 target CPU용 object code로 변환한다.
syntax error처럼 결과물을 만들 수 없는 문제는 build 단계에서 확인된다.
compiler optimization은 같은 의미를 유지하면서 불필요한 연산을 줄일 기회를 제공한다.

### Assembly와 CPU architecture

machine code는 CPU가 직접 해석하는 binary instruction이다.
assembly language는 machine code를 mnemonic으로 표현한 낮은 수준의 언어다.
assembly instruction은 target CPU architecture에 따라 달라진다.

| 단계 | 표현 | 역할 |
| :--- | :--- | :--- |
| machine code | binary bit pattern | CPU가 직접 실행하는 instruction |
| assembly | `add`, `sub` 같은 mnemonic | machine code와 가까운 사람이 읽을 수 있는 표현 |
| C | 함수, 조건문, 변수 | hardware 독립적인 의도를 표현하는 source |
| compiler | C를 target instruction으로 변환 | target architecture별 결과물 생성 |

PC용 GCC로 만든 executable은 ARM MCU에서 그대로 실행할 수 없다.
PC CPU와 ARM MCU의 instruction set이 다르다.
ARM 대상 compiler가 같은 C source를 ARM instruction으로 다시 변환해야 한다.

### ARM toolchain 설치와 환경 변수

ARM toolchain을 설치한 뒤에는 compiler 실행 파일이 들어 있는 directory를 Windows `Path`에 추가한다.
새 terminal 또는 개발 도구를 다시 열면 환경 변수 변경이 반영된다.
그 뒤 project directory에서 build command를 실행할 수 있다.

| 점검 순서 | 확인 내용 |
| :--- | :--- |
| 1 | ARM 대상 compiler toolchain 설치 |
| 2 | 제공된 설치 경로와 `bin` directory 확인 |
| 3 | Windows `Path`에 compiler 실행 경로 추가 |
| 4 | terminal 또는 개발 도구 재실행 |
| 5 | compiler command 인식 여부 확인 |

설치 패키지의 정확한 이름, version, `Path`에 넣을 전체 경로는 제공된 실습 자료와
현재 PC의 실제 설치 위치를 기준으로 확인한다.

### Compile Test 실행

compile test는 toolchain과 `Makefile`이 연결되어 ARM 대상 build가 가능한지 확인하는 최소 실습이다.
terminal은 반드시 `Makefile`이 있는 project root에서 연다.

```sh
cd <compile-test-project>
make all
make run
```

| 증상 | 우선 점검 |
| :--- | :--- |
| compiler command를 찾지 못함 | `Path` 등록 경로와 terminal 재실행 |
| `make` 실행 실패 | 현재 directory와 `Makefile` 존재 여부 |
| build 결과가 기대와 다름 | target 설정과 build target 확인 |
| 한글 출력이 깨짐 | terminal encoding과 개발 도구 재시작 |

`make all`, `make run`의 실제 target 동작과 최종 산출물은 해당 project의 `Makefile`을 열어 확인한다.

`Makefile`의 compiler option에는 target CPU 정보가 담긴다. 실습 project 기준으로 핵심 flag는 다음과 같다.

| flag | 의미 |
| :--- | :--- |
| `-mcpu=cortex-m4` | target core 지정 |
| `-mthumb` | Thumb instruction encoding 사용 |
| `-mfpu=fpv4-sp-d16 -mfloat-abi=hard` | single-precision FPU 사용과 hardware float 호출 규약 |
| `-DSTM32F411xE` | device header의 target macro를 build 옵션으로 정의 |
| `-O3` | optimization level, `volatile` 실습에서 `-O0`과 비교 대상 |

optimization level 같은 flag만 바꾸면 source가 그대로라 `make`가 다시 compile하지 않을 수 있으므로, 옵션 변경 후에는 clean 후 다시 build한다.

## 수업 범위

| 과 | 주제 |
| :--- | :--- |
| 2과 | 능동 소자와 집적 회로 |
| 3과 | 컴퓨터와 임베디드 시스템 |
| 4과 | STM32F411xE MCU와 실습보드 |

## 능동 소자와 집적 회로

### 수동 소자와 능동 소자

소자는 재료를 가공해 만든 회로 부품이다. 소자에 붙은 리드, 다리, 핀 같은 금속 연결점을 `terminal`(단자)이라 하며, 소자는 terminal을 통해 회로와 연결됨.

저항을 예로 들면 저항막, 세라믹, 금속은 재료이고 저항 하나가 소자다. 양쪽 금속 다리는 terminal이며, `V = I R`은 두 terminal 사이 전압과 전류로 저항의 동작을 설명하는 식이다.

| 식의 기호 | 물리량 | 영문 | 단위 | 의미 |
| :--- | :--- | :--- | :--- | :--- |
| `V` | 전압 | voltage | volt (`V`) | 두 terminal 사이 전위 차이 |
| `I` | 전류 | current | ampere (`A`) | 흐르는 전하의 양/시간 |
| `R` | 저항 | resistance | ohm (`Ω`) | 전류 흐름 제한 정도 |
| `P` | 전력 | power | watt (`W`) | `P = V I`로 계산하는 에너지 전달률 |

물리량은 회로에서 재거나 계산할 대상이다. 식의 기호는 그 물리량을 식 안에서 가리키는 문자이고, 단위는 숫자에 붙여 크기를 나타내는 기준이다. 역할이 달라 기호와 단위는 보통 다르다. `V`는 전압 기호와 volt 단위 기호가 같은 관례적 예로, `V = I R`의 `V`는 기호이고 `5 V`의 뒤 `V`는 단위다. 전력의 기호는 `P`이며, 전력은 `P = V I`로 계산함.

| 항목 | 수동 소자 | 능동 소자 |
| :--- | :--- | :--- |
| 동작 기준 | 저항, 용량, 인덕턴스 같은 소자값 | 제어 신호 또는 bias 조건 |
| 전류 변화 | 회로에 걸린 전압·전류 조건에 따른 응답 | 제어 단자로 전류 경로와 양 조절 |
| 에너지 | 에너지 저장·소비, 전력 이득 없음 | 전원 에너지 흐름 제어, 증폭·스위칭 가능 |
| 대표 예 | 저항, 콘덴서, 인덕터, 퓨즈, 스위치 | BJT, MOSFET |
| 간단한 예 | `V = I R`에 따른 저항 전류 변화 | 작은 제어 신호가 다른 단자 사이 전류에 영향 |

현재 수업에서 다루는 능동 소자의 주재료는 반도체다. 더 정확히는 전류를 제어하는 핵심부가 반도체이며, 소자 전체에는 금속 단자와 배선, 절연층, 패키지 재료도 함께 사용됨. 진공관처럼 반도체가 아닌 능동 소자도 존재함.

반도체는 도체와 절연체 사이 범위의 도전율을 가진 재료다. 도핑, 전압이나 전기장, 온도, 빛 등에 따라 전하 운반자인 전자와 정공의 수나 움직임이 달라져 전류가 매우 작게 흐르는 상태와 잘 흐르는 상태를 만들 수 있다. 이 성질이 다이오드, 트랜지스터, IC의 기반이 됨.

### 다이오드와 LED

다이오드는 한쪽 방향의 전류 흐름을 허용하고 반대 방향은 제한하는 2 terminal 반도체 소자다. 이 노트의 수동/능동 기준에서는 별도 제어 terminal과 전력 이득이 없는 비선형 수동 소자로 이해한다. 교재와 분야에 따라 분류가 달라질 수 있으므로, 능동 소자의 대표는 BJT와 MOSFET으로 두고 구분함.

`P`와 `N`은 물질 전체가 순전하를 띠어 각각 양·음이라는 뜻이 아니다. silicon에 acceptor 또는 donor impurity를 doping한 뒤, P-type에서는 정공이, N-type에서는 전자가 다수 carrier가 된 영역을 가리킨다. 두 영역을 붙이면 PN junction과 depletion region이 생기며, P/N 물질 전체는 각각 전기적으로 거의 중성을 유지함.

| 영역 | 다수 carrier | 단자 이름 |
| :--- | :--- | :--- |
| P-type | hole, 정공 | anode |
| N-type | electron, 전자 | cathode |

P 쪽에 더 높은 전압, N 쪽에 더 낮은 전압을 걸면 정방향 bias가 되어 장벽이 낮아지고 전류가 흐를 수 있다. 반대로 걸면 역방향 bias가 되어 장벽이 커지고 전류가 크게 제한됨.

다이오드의 방향성은 다음처럼 생각하면 된다.

```text
정방향 바이어스

  + --- P(anode) ---->|---- N(cathode) --- -

  conventional current: P → N
  전류 흐름 허용, ON 근사

역방향 바이어스

  - --- P(anode) ---->|---- N(cathode) --- +

  전류 흐름 제한, OFF 근사
```

| 항목 | 설명 |
| :--- | :--- |
| 회로 표기 | 약어 `D` 사용 |
| 정방향 | P/anode 전압이 N/cathode보다 높음, 전류 흐름 허용 |
| 역방향 | P/anode 전압이 N/cathode보다 낮음, 작은 leakage current |
| zero bias | 두 terminal 전압이 같음, net current `0` |
| open circuit | 닫힌 전류 경로 없음, current `0` |
| 활용 | 정류, 과전압 방지, 정전압 유지, 방향 제한 |

전류가 흐르지 않는 이유는 하나가 아니다. `V_AK = 0`이면 PN junction은 외부 bias가 없는 zero bias 상태이고 net current가 `0`이다. 회로가 끊어져도 current는 `0`이며, 이때 정방향 또는 역방향 전압 조건과 닫힌 회로 여부를 함께 확인해야 함. 역방향 breakdown 전압을 넘기면 OFF 근사와 달리 큰 전류가 흐를 수 있다.

LED는 `Light Emitting Diode`로, 빛을 내는 다이오드다. LED에는 최대 정격 전류가 있으며, 보통 20mA 정도를 넘기면 손상될 수 있다. LED의 순방향 전압은 색상에 따라 달라지며, 자료에서는 Red 약 1.8V, Green 약 2V, Blue 약 3.4V 정도로 설명함.

LED 밝기는 정격 범위 안의 순방향 전류에 따라 달라진다. 전원에 직접 연결하지 않고 직렬 저항으로 전류를 제한해야 LED와 GPIO output driver를 보호할 수 있다.

다이오드 종류별 예시는 다음과 같이 정리할 수 있음.

| 종류 | 용도 |
| :--- | :--- |
| 일반 다이오드 | 정류, 전류 방향 제한 |
| Zener 다이오드 | 기준 전압 유지, 과전압 보호 |
| Schottky 다이오드 | 낮은 순방향 전압, 빠른 스위칭 |
| LED | 전류가 흐를 때 빛 출력 |

Red LED에 5V 전원을 사용하고 10mA를 흘리려면 저항은 다음과 같이 계산함.

```text
5V ---- R ---->| ---- GND
              LED

R = (5V - 1.8V) / 0.01A
  = 320 ohm
```

실제 회로에서는 근접한 표준값인 `330 ohm`을 사용할 수 있음.

#### 처음 보는 회로를 읽는 순서: 전압·경로·제어

회로 그림을 볼 때는 부품 이름을 모두 외우기 전에 다음 세 질문을 순서대로 답한다.

| 순서 | 확인할 질문 | LED 예시 |
| :---: | :--- | :--- |
| 1 | 전원과 기준점은 어디인가 | `3.3V`와 `GND` |
| 2 | 전류가 돌아오는 닫힌 경로가 있는가 | `3.3V → resistor → LED → GND` |
| 3 | 경로를 열고 닫거나 양을 바꾸는 소자는 무엇인가 | GPIO output driver 또는 transistor |

전압은 한 점에 붙은 양이 아니라 두 점의 차이다. 따라서 `PA5 = 3.3V`라는 말은 보통 `GND`를 `0V` 기준으로 할 때 PA5가 GND보다 `3.3V` 높다는 뜻이다. conventional current는 높은 전위에서 낮은 전위 쪽으로 그리며, 전자의 실제 이동 방향은 그 반대다. 회로 계산과 GPIO 자료의 전류 방향 표기는 conventional current 기준으로 읽으면 됨.

LED가 켜지려면 단순히 PA5가 high인 것만으로는 부족하다. LED 양단에 순방향 전압이 걸리고, 전류 제한 resistor를 포함한 닫힌 경로가 있어야 한다. 이 관점은 이후 `push-pull`, `open-drain`, pull-up resistor, I2C bus를 읽을 때도 그대로 사용한다.

### 전압 분배와 전류 분배

전압 분배와 전류 분배는 먼저 회로가 직렬인지 병렬인지 판별한 뒤, 등가 저항 `R_t`부터 구하는 방식으로 계산한다. 아래 기호를 통일해서 사용함.

| 기호 | 의미 |
| :--- | :--- |
| `R_t` | 전원에서 본 전체 등가 저항 |
| `V_s` | 회로에 인가한 공급 전압 |
| `I_t` | 전원이 공급한 전체 전류 |
| `V_i`, `I_i`, `P_i` | i번째 저항의 전압·전류·소비 전력 |

저항의 전력은 같은 값을 세 방식으로 계산할 수 있다. 문제에서 이미 알고 있는 두 물리량을 고르면 됨.

```text
P = V I = I^2 R = V^2 / R
```

#### 직렬 회로: 전류는 같고 전압이 나뉨

직렬 회로에서는 모든 저항에 같은 전류 `I_t`가 흐른다. 따라서 저항이 큰 소자에 더 큰 전압이 걸림.

```text
R_t = R_1 + R_2 + ... + R_n
I_t = V_s / R_t
V_i = I_t R_i
P_i = I_t^2 R_i
```

저항 두 개의 전압 분배식은 전체 전류를 중간에 쓰지 않고 바로 계산할 수도 있다.

```text
V_R1 = V_s R_1 / (R_1 + R_2)
V_R2 = V_s R_2 / (R_1 + R_2)
```

`R1 = 100 ohm`, `R2 = 200 ohm`, `V_s = 5V`인 직렬 회로를 계산하면 다음과 같음.

```text
R_t = 100 ohm + 200 ohm = 300 ohm
I_t = 5V / 300 ohm = 16.67mA

V_R1 = 16.67mA * 100 ohm = 1.67V
V_R2 = 16.67mA * 200 ohm = 3.33V
```

| 항목 | 계산 | 값 |
| :--- | :--- | :--- |
| 전체 저항 | `R_t = R1 + R2` | `300 ohm` |
| 전체 전류 | `I_t = V_s / R_t` | `16.67mA` |
| `R1` 전압 | `V_R1 = I_t R1` | `1.67V` |
| `R2` 전압 | `V_R2 = I_t R2` | `3.33V` |
| 전체 전력 | `P_t = V_s I_t` | `83.3mW` |
| `R1` 전력 | `P_R1 = I_t^2 R1` | `27.8mW` |
| `R2` 전력 | `P_R2 = I_t^2 R2` | `55.6mW` |

검산은 `V_s = V_R1 + V_R2`와 `P_t = P_R1 + P_R2`로 한다. 이 예제에서는 `5V = 1.67V + 3.33V`가 됨.

직렬 저항 두 개로 만든 전압 분배기에서 GND 기준 `V_out`은 아래쪽 저항 양단 전압이다.

```text
V_s --- R1 ---+--- R2 --- GND
              |
            V_out

V_out = V_s R2 / (R1 + R2)
```

위 예제에서는 `V_out = 3.33V`다. 단, `V_out`에 다른 회로를 연결하면 그 회로가 `R2`와 병렬이 되어 실제 분배 전압이 바뀔 수 있음.

#### 병렬 회로: 전압은 같고 전류가 나뉨

병렬 회로에서는 모든 가지에 같은 전압 `V_s`가 걸린다. 저항이 작은 가지에 더 큰 전류가 흐름.

```text
1 / R_t = 1 / R_1 + 1 / R_2 + 1 / R_3 + ... + 1 / R_n
I_t = V_s / R_t
V_1 = V_2 = ... = V_s
I_i = V_s / R_i
P_i = V_s^2 / R_i
```

저항 두 개만 병렬이면 역수 계산을 다음 식으로 줄일 수 있다.

```text
R_t = (R_1 R_2) / (R_1 + R_2)
```

두 병렬 가지의 전체 전류 `I_t`가 이미 주어졌을 때에는 전류 분배식으로 가지 전류를 바로 구할 수 있다.

```text
I_R1 = I_t R_2 / (R_1 + R_2)
I_R2 = I_t R_1 / (R_1 + R_2)
```

분자에 반대편 저항이 들어가므로, 저항이 작은 가지가 더 큰 전류를 받는 결과가 나온다. 가지가 세 개 이상이면 저항의 역수인 conductance(전도도) 비율식을 쓰면 됨.

```text
I_k = I_t (1 / R_k) / (1 / R_1 + 1 / R_2 + ... + 1 / R_n)
```

`R1 = 100 ohm`, `R2 = 200 ohm`, `V_s = 6V`인 병렬 회로를 계산하면 다음과 같음.

```text
R_t = (100 ohm * 200 ohm) / (100 ohm + 200 ohm)
    = 66.67 ohm

I_t  = 6V / 66.67 ohm = 90mA
I_R1 = 6V / 100 ohm = 60mA
I_R2 = 6V / 200 ohm = 30mA
```

| 항목 | 계산 | 값 |
| :--- | :--- | :--- |
| 전체 저항 | `R_t = (R1 R2) / (R1 + R2)` | `66.67 ohm` |
| 각 가지 전압 | `V_R1 = V_R2 = V_s` | `6V` |
| `R1` 가지 전류 | `I_R1 = V_s / R1` | `60mA` |
| `R2` 가지 전류 | `I_R2 = V_s / R2` | `30mA` |
| 전체 전류 | `I_t = I_R1 + I_R2` | `90mA` |
| 전체 전력 | `P_t = V_s I_t` | `540mW` |
| `R1` 전력 | `P_R1 = V_s I_R1` | `360mW` |
| `R2` 전력 | `P_R2 = V_s I_R2` | `180mW` |

검산은 `I_t = I_R1 + I_R2`와 `P_t = P_R1 + P_R2`로 한다. 이 예제에서는 `90mA = 60mA + 30mA`가 됨.

#### 직렬·병렬 혼합 회로 계산 예제

혼합 회로는 안쪽 병렬 또는 직렬 묶음을 먼저 하나의 `R_t`로 바꾸고, 바깥 회로를 다시 계산한다. 다음 회로에서 `R1`은 병렬 묶음과 직렬이다.

```text
12V --- R1 = 100 ohm ---+--- R2 = 300 ohm ---+
                         |                     |
                         +--- R3 = 600 ohm ---+--- GND
```

계산 순서는 다음과 같다.

1. 병렬인 `R2`, `R3`을 하나의 등가 저항으로 계산
2. `R1`과 병렬 묶음의 등가 저항을 직렬 합으로 계산
3. 전체 전류 `I_t` 계산
4. `R1` 전압과 병렬 묶음 전압 계산
5. 병렬 가지 `R2`, `R3`의 전류와 각 저항 전력 계산
6. 전압·전류·전력 합으로 검산

```text
R_23 = (300 ohm * 600 ohm) / (300 ohm + 600 ohm)
     = 200 ohm

R_t = R1 + R_23
    = 100 ohm + 200 ohm
    = 300 ohm

I_t = 12V / 300 ohm
    = 40mA
```

`R1`에는 전체 전류가 흐르고, 병렬 묶음에는 남은 전압이 걸린다.

```text
V_R1 = 40mA * 100 ohm = 4V
V_R23 = 12V - 4V = 8V

V_R2 = V_R3 = 8V
I_R2 = 8V / 300 ohm = 26.67mA
I_R3 = 8V / 600 ohm = 13.33mA
```

| 저항 | 전압 | 전류 | 전력 |
| :--- | :--- | :--- | :--- |
| `R1 = 100 ohm` | `4V` | `40mA` | `160mW` |
| `R2 = 300 ohm` | `8V` | `26.67mA` | `213.3mW` |
| `R3 = 600 ohm` | `8V` | `13.33mA` | `106.7mW` |
| 전체 | `12V` | `40mA` | `480mW` |

검산하면 병렬 묶음 전류는 `26.67mA + 13.33mA = 40mA`이고, 총 소비 전력도 `160mW + 213.3mW + 106.7mW = 480mW`다. 저항의 정격 전력은 계산값보다 여유 있게 골라야 하므로, 이 예제의 `R2`에는 `1/4W`보다 큰 `1/2W`급을 선택하는 편이 안전함.

### 트랜지스터와 FET

트랜지스터는 증폭과 스위칭을 목적으로 만들어진 소자다. `Transfer Resistor`에서 온 이름이며, 회로에서는 보통 `Q`로 표기함.

| 구분 | 제어 단자 | 전류 경로 | 개념 |
| :--- | :--- | :--- | :--- |
| BJT | Base | Collector-Emitter | Base-Emitter 접합의 전압·전류로 C-E 전류를 제어 |
| PNP | Base를 낮게 제어 | E에서 C 방향 | +V 측 스위칭에 자주 사용 |
| NPN | Base를 높게 제어 | C에서 E 방향 | 0V 측 스위칭에 자주 사용 |
| FET | Gate | Drain-Source | `V_GS`가 만드는 전계로 D-S 채널의 도통 정도를 제어 |

FET는 BJT와 동작 원리는 다르지만, 소프트웨어 개발자 관점에서는 스위칭 소자로 이해해도 충분하다. P-Channel FET는 PNP와 유사하게, N-Channel FET는 NPN과 유사하게 이해할 수 있음.

#### BJT 기호 판별

BJT의 세 단자는 `Emitter`, `Base`, `Collector`다. `NPN`은 Emitter 화살표가 바깥쪽을 향하고, `PNP`는 안쪽을 향한다.

| 종류 | Emitter 화살표 | 기억법 | 기본 스위칭 제어 |
| :--- | :--- | :--- | :--- |
| NPN | 바깥쪽 | `Not Pointing iN` | Base를 Emitter보다 높게 하면 ON |
| PNP | 안쪽 | `Pointing iN` | Base를 Emitter보다 낮게 하면 ON |

FET의 세 단자는 `Source`, `Gate`, `Drain`이다. MOSFET의 ON/OFF 조건은 Gate의 절대 전압이 아니라 `V_GS = V_G - V_S`로 결정한다. enhancement-mode N-channel MOSFET은 `V_GS`가 양의 threshold voltage보다 충분히 커질 때 도통하고, P-channel MOSFET은 `V_GS`가 음의 threshold voltage보다 충분히 작아질 때 도통한다. 따라서 '`N-Ch는 High면 ON`, `P-Ch는 Low면 ON`'은 Source가 각각 GND와 `VCC`에 고정된 대표적인 low-side/high-side 스위치에서만 성립하는 축약 표현이다.

MCU GPIO로 MOSFET을 제어할 때는 `V_GS`뿐 아니라 GPIO 전압 범위, 해당 Gate 전압에서 보장되는 `R_DS(on)`, Gate pull 저항, 부하 전류, body diode 방향을 함께 확인한다. 특히 P-channel high-side switch는 Source가 `VCC`에 있으므로 GPIO가 Low일 때 Gate를 Source보다 낮게 만들어 켤 수 있다. GPIO가 High일 때 Gate를 Source와 같은 전압까지 실제로 올릴 수 있는지와 MCU 핀의 절대정격도 확인해야 한다.

스위칭 회로의 방향은 다음처럼 구분해두면 GPIO 출력과 연결하기 쉽다.

```text
NPN 또는 N-Ch low-side switch

  VCC ---- LOAD ---- C/D
                     |
                  [NPN/N-Ch]
                     |
                    GND

  NPN: `V_BE` 순방향 바이어스
  N-Ch: `V_GS > V_TH` -> ON
  LOAD 전류가 GND로 흐름


PNP 또는 P-Ch high-side switch

  VCC ---- [PNP/P-Ch] ---- LOAD ---- GND
             |
          Base/Gate

  PNP: Base가 Emitter보다 낮음
  P-Ch: `V_GS < V_TH` (음수) -> ON
  VCC 쪽 전원을 LOAD에 공급
```

### 디지털 논리와 CMOS

디지털 회로는 전압 레벨로 이진 값을 표현한다.

| 표현 | 의미 |
| :--- | :--- |
| `GND`, `VSS`, `0V`, `LOW`, `L`, `0` | 논리 0 |
| `VCC`, `VDD`, `3.3V`, `5V`, `HIGH`, `H`, `1` | 논리 1 |

논리 게이트는 NOT, OR, AND, XOR, NOR, NAND 등이 기본이다. 실제 게이트는 트랜지스터나 FET를 조합하여 구현되며, DTL, ECL, TTL, CMOS 같은 구현 방식이 있다. 현재 디지털 IC에서는 전력 소모와 집적도 측면에서 CMOS 방식이 널리 쓰인다.

자료에서 다룬 기본 논리 게이트의 진리표는 다음과 같음.

| `X` | `Y` | `NOT X` | `OR` | `AND` | `XOR` | `NOR` | `NAND` |
| :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| `0` | `0` | `1` | `0` | `0` | `0` | `1` | `1` |
| `0` | `1` | `1` | `1` | `0` | `1` | `0` | `1` |
| `1` | `0` | `0` | `1` | `0` | `1` | `0` | `1` |
| `1` | `1` | `0` | `1` | `1` | `0` | `0` | `0` |

CMOS에서는 P-Channel과 N-Channel MOSFET을 상보적으로 사용한다. P-Channel은 입력이 0일 때 ON, N-Channel은 입력이 1일 때 ON 되는 특성을 이용해 NOT, NAND, NOR 같은 논리 회로를 구성함.

CMOS inverter는 다음처럼 위쪽 P-Ch과 아래쪽 N-Ch이 반대로 동작한다.

```text
             VDD
              |
           [P-Ch]
Vin --------|      P-Ch: Vin=0 -> ON
              |
             Vout
              |
           [N-Ch]
Vin --------|      N-Ch: Vin=1 -> ON
              |
             GND

Vin = 0 -> P-Ch ON,  N-Ch OFF -> Vout = 1
Vin = 1 -> P-Ch OFF, N-Ch ON  -> Vout = 0
```

### IC, ASIC, SoC

IC는 여러 트랜지스터와 다이오드 등을 하나의 패키지 안에 집적한 회로다. SSI, MSI, LSI, VLSI 같은 집적 규모 분류가 있었지만, 현재는 그 구분 자체보다 용도와 구조가 중요함.

| 용어 | 의미 |
| :--- | :--- |
| `IC` | 특정 기능을 수행하도록 집적한 회로 |
| `ASIC` | 특정 목적을 위해 설계된 IC |
| `SoC` | CPU와 주변장치 등을 하나의 칩에 통합한 시스템 수준 IC |

자료에서는 IC를 C언어의 함수에, ASIC을 프로그램에 비유했다. IC는 특정 기능 블록이고, ASIC은 특정 목적을 위해 조합된 큰 기능 단위로 이해할 수 있음.

#### IC 패키지

집적 회로는 기능뿐 아니라 기판에 연결하는 방식에 따라 여러 패키지 형태를 가진다.

| 패키지 또는 실장 방식 | 특징 |
| :--- | :--- |
| `DIP` | 두 줄 핀을 가진 through-hole 방식, 기판의 구멍에 삽입 후 납땜 |
| `SMD` | 기판 표면에 실장하는 방식, 소형화와 자동 실장에 적합 |
| `SOP` | 양쪽에 핀이 나오는 SMD 패키지 |
| `QFP` | 네 변에 핀이 배치된 SMD 패키지 |
| `QFN` | 단자가 패키지 아래쪽에 배치된 소형 SMD 패키지 |
| `BGA` | 아래쪽 ball grid로 연결, 작은 면적에 많은 핀 배치 |

## 컴퓨터와 임베디드 시스템

### 컴퓨터와 폰 노이만 구조

초기 컴퓨터는 계산을 수행하기 위한 대형 하드웨어 장치였다. ENIAC(1945)처럼 외부 스위치와 케이블 결선으로 계산식을 입력했고, 프로그램을 저장한다는 개념이 없었다. 이후 프로그램을 메모리에 저장하고 CPU가 명령을 읽어 실행하는 stored-program 구조가 확립되었다. 이것이 폰 노이만 구조이며, 1945년 제안되어 EDVAC에 처음 적용됨.

폰 노이만 구조의 기본 실행 흐름은 다음과 같다.

```text
Fetch  ->  Decode  ->  Execute
명령 읽기  명령 해석   명령 실행
```

리셋 후 CPU는 정해진 초기 PC 값, 즉 리셋 벡터 주소에서 명령어를 읽고 실행을 시작한다. 명령이 메모리 읽기나 쓰기라면, CPU는 주소를 내보내고 메모리 또는 주변장치에 접근함.

폰 노이만 구조에서 중요한 점은 명령과 데이터가 모두 memory에 저장된다는 점이다.

#### 폰 노이만과 하버드 구조

폰 노이만 구조는 명령과 데이터가 같은 memory와 bus를 공유한다. 명령 fetch와 데이터 read/write가 같은 경로를 사용하므로 한 순간에는 한 종류의 접근을 처리한다.

하버드 구조는 명령과 데이터의 memory 또는 bus를 분리한다. 명령 fetch와 데이터 접근을 병렬로 처리할 수 있어 memory 접근 병목을 줄이는 데 유리함.

| 구조 | 명령과 데이터 | 접근 경로 | 핵심 특징 |
| :--- | :--- | :--- | :--- |
| 폰 노이만 | 같은 memory 공간 | 공유 bus | 단순한 저장 프로그램 구조 |
| 하버드 | 분리된 memory 또는 공간 | 분리 bus | 명령 fetch와 data access 병렬화 |

```text
           address/data/control bus
      +-------------------------------+
      |                               |
      v                               v
+-----------+                   +------------+
|    CPU    |                   |   Memory   |
|           |                   |------------|
| PC        | -- fetch -------> | instruction|
| Register  | <-> read/write -> | data       |
| ALU       |                   | stack      |
+-----------+                   +------------+
```

### ALU, 레지스터, 제어 로직

CPU의 핵심은 `ALU`, 레지스터, 제어 로직이다.

| 구성 | 역할 |
| :--- | :--- |
| `ALU` | 산술 연산, 논리 연산, shift, rotate, bit 연산 수행 |
| Register | 연산 대상, 결과, 상태를 임시 저장 |
| Control Logic | 명령 fetch/read/write, decode, ALU 제어 |
| Status Register | zero, negative, carry, overflow 등 연산 상태 저장 |

CPU 안의 레지스터는 메모리처럼 값을 저장하지만, 일반 메모리 주소로 접근하지 않고 이름으로 식별된다.

명령과 데이터가 메모리에 함께 저장되는 구조는 다음 예시로 확인한다.

| 주소 | 저장값 | 의미 예시 |
| :--- | :--- | :--- |
| `0x00` | `0x12` | 명령 또는 데이터 |
| `0x04` | `0x6B` | 명령 또는 데이터 |
| `0x08` | `0x73` | 명령 또는 데이터 |
| `0x10` | `0x30` | 명령 또는 데이터 |
| `0x14` | `0x7D` | 명령 또는 데이터 |

CPU는 PC가 가리키는 주소에서 명령을 fetch하고, 필요한 경우 같은 메모리 공간에서 operand 데이터를 read/write한다.

### 메모리 셀과 주변장치

D Flip-Flop 1개는 1bit를 저장할 수 있고, 8개를 모으면 1Byte 메모리 셀이 된다. 입력 데이터가 바뀌더라도 clock pulse가 들어오지 않으면 저장값은 유지됨.

CPU는 단독으로는 외부 세계와 상호작용할 수 없으므로 ROM, RAM, GPIO, UART, Timer, ADC, LCD, Touch, Network 같은 주변장치가 필요하다. CPU 주변에 연결되어 특정 목적을 수행하는 회로 장치를 주변장치, 즉 `Peripheral`이라고 함.

초기에는 자주 쓰이는 주변장치를 CPU와 결합하기 쉬운 별도의 family IC로 판매했다. Intel의 `i8255`(GPIO), `i8251`(UART), `i8237`(DMA controller), `i8259`(interrupt controller)가 대표적이며, 이런 범용 주변장치 IC들이 CPU와 함께 board 위에서 컴퓨터를 구성했다. 반도체 집적도가 오르면서 이 구성이 한 칩 안으로 들어온 것이 MCU다.

주변장치 내부에도 하드웨어가 사용하는 기능별 레지스터가 존재한다. 소프트웨어는 이 레지스터를 읽고 쓰면서 하드웨어 상태를 확인하거나 동작을 제어함.

CPU 내부 레지스터와 주변장치 레지스터는 CPU가 접근하는 방식이 다르다. CPU 내부 레지스터는 명령어가 직접 지정하는 코어 안의 저장소이고, GPIO나 UART 같은 주변장치 레지스터는 memory bus의 주소에 연결된 memory-mapped register다. CPU는 주변장치를 버스에 연결된 memory로 보고 주소를 내보낸 뒤 read/write 동작으로 접근함.

| 구분 | CPU 관점 | 접근 방식 |
| :--- | :--- | :--- |
| CPU 내부 register | 코어 안의 이름 있는 저장소 | 명령어가 register 번호 지정 |
| 주변장치 register | memory bus에 연결된 주소 공간 | load/store 또는 memory read/write |

예시로 `62256 SRAM`은 일반적인 SRAM 핀 구성을 이해하기 위해 사용되었다.

| 항목 | 값 |
| :--- | :--- |
| 주소선 | `A0`~`A14`, 15개 |
| 데이터선 | `D0`~`D7`, 8bit |
| 저장 용량 | `2^15 * 8bit = 32768Byte = 32KB` |
| 주요 제어 신호 | `CE`, `OE`, `WE` |

#### 주소선과 저장 용량

주소선이 `n`개면 `2^n`개의 memory location을 선택할 수 있다. 각 location의 data width가 `m`bit이면 전체 용량은 `2^n * m`bit다.

`62256 SRAM`은 주소선 15개와 data line 8개를 사용하므로 `2^15 * 8bit = 32768Byte = 32KB`를 저장한다. address `0`부터 연결하면 범위는 `0x0000`부터 `0x7FFF`까지다.

#### 62256 SRAM 주소 범위 계산

메모리의 마지막 주소는 `시작 주소 + 용량 - 1`로 계산한다. `32KB = 32768Byte = 0x8000Byte`이므로, 주소 범위를 구할 때는 시작 주소에 `0x8000`을 더한 뒤 `1`을 빼면 됨.

| 조건 | 계산 | 주소 범위 |
| :--- | :--- | :--- |
| 62256 하나를 `0x0000`에 연결 | `0x0000 + 0x8000 - 1` | `0x0000` ~ `0x7FFF` |
| 62256 하나를 `0x1000`에 연결 | `0x1000 + 0x8000 - 1` | `0x1000` ~ `0x8FFF` |
| 같은 칩 하나를 바로 뒤에 추가 | 다음 시작 `0x8FFF + 1 = 0x9000` | `0x9000` ~ `0xFFFF` |

#### 슬기로운 탐구 생활 풀이: 64Byte 메모리와 alignment

문제는 `64Byte` 메모리가 `0x0`부터 차지하는 주소 범위와, `64Byte aligned` 주소에서 항상 `0`이어야 하는 부분을 묻는다. 먼저 용량을 주소 개수와 hexadecimal 크기로 바꾼 뒤, 끝 주소와 alignment 조건을 차례로 구함.

| 풀이 단계 | 계산 | 결과 |
| :--- | :--- | :--- |
| 1. 용량을 2의 거듭제곱으로 표현 | `64Byte = 2^6Byte = 0x40Byte` | 주소 64개 |
| 2. 마지막 주소 계산 | `0x00 + 0x40 - 1` | `0x3F` |
| 3. 주소 범위 작성 | 시작 `0x00`, 끝 `0x3F` | `0x00` ~ `0x3F` |
| 4. alignment 크기 해석 | `64Byte = 2^6` | 하위 6bit가 `0` |
| 5. aligned 주소 나열 | `0x00`, `0x40`, `0x80`, `0xC0`, `0x100`, … | `0x40` 간격 |

정렬 주소는 `64`의 배수여야 하므로 `address % 64 = 0`이다. bit 연산으로는 `address & 0x3F = 0`으로 확인할 수 있다. hexadecimal의 마지막 두 자리는 `00`, `40`, `80`, `C0`가 반복되며, 이 네 값은 모두 하위 6bit가 `0`인 경우다.

```text
0x00 ~ 0x3F
```

`4Byte = 2^2` aligned 주소가 하위 2bit를 `0`으로 만드는 것과 같은 규칙이다. 정렬 단위가 `2^kByte`이면 주소의 하위 `k`bit가 `0`이며, 그 주소는 해당 크기 block의 시작 위치가 됨.

### 메모리 버스와 타이밍

일반적인 메모리는 주소선, 데이터선, 제어선을 가진다.

| 신호 | 역할 |
| :--- | :--- |
| `A[n:0]` | 주소 선택 |
| `D[n:0]` | 데이터 읽기/쓰기 |
| `WE` 또는 `WR` | 쓰기 제어 |
| `OE` 또는 `RD` | 읽기 제어 |
| `CE` 또는 `CS` | 칩 선택 |

CPU 쪽 제어 신호와 memory 쪽 신호는 이름이 달라도 같은 동작을 연결한다. 실제 chip의 active-low 표기와 세부 이름은 다를 수 있지만, 주소와 제어를 내보내고 data bus를 읽거나 쓰는 역할은 같음.

| CPU 쪽 | Memory 쪽 | 연결 역할 |
| :--- | :--- | :--- |
| Address | `A[n:0]` | 접근할 memory location 선택 |
| Data | `D[n:0]` | read/write 공용 data bus |
| `CS` | `CE` | 대상 chip 선택 |
| `RD` | `OE` | memory data output 허용 |
| `WR` | `WE` | memory write 동작 허용 |

타이밍 차트에서는 low, high, floating, stable, invalid, rising, falling, pulse width, setup time, hold time, delay time 같은 기호를 사용한다. 자료에서 제시된 타이밍 기호는 다음처럼 정리할 수 있음.

| 표현 | 의미 |
| :--- | :--- |
| Low | 논리 0 |
| High | 논리 1 |
| Floating, 3-state | 구동하지 않는 high impedance 상태 |
| Low or High Stable | 유효한 안정 상태 |
| Invalid State or Astable | 유효하지 않거나 불안정한 상태 |
| Rising | 상승 전이 |
| Falling | 하강 전이 |
| Bus, Valid State | 버스 값이 유효한 상태 |
| Pulse Width | pulse 유지 시간 |
| Setup Time | 기준 edge 전에 데이터가 안정되어야 하는 시간 |
| Hold Time | 기준 edge 후에도 데이터가 유지되어야 하는 시간 |
| Delay Time | 원인 신호 이후 결과 신호가 나타나기까지의 지연 |

CPU가 빠르고 메모리가 느리면, 주소와 제어 신호가 유효해진 뒤 데이터가 안정되기 전에 CPU가 값을 읽는 문제가 생길 수 있다. 이런 경우 wait, ready, bus timing 조정이 필요함.

#### 한 줄의 C 코드가 LED까지 가는 경로

관련 노트: [[domains/semiconductor/ai-npu-system-integration/gpio-register-mmio-cr-idr-odr]], [[domains/semiconductor/ai-npu-system-integration/c-pointer-struct-mmio-gpio-register-access]]

`GPIOA->ODR |= (1u << 5);`는 화면에 그림을 그리는 코드가 아니라 `GPIOA`의 output data register 5번 bit를 `1`로 만드는 memory write다. 이 한 줄을 아래 순서로 추적할 수 있으면 이후 peripheral code를 읽는 기준이 생긴다.

```text
C expression
  -> compiler가 GPIOA ODR 주소에 store instruction 생성
  -> Cortex-M4가 AHB bus에 address와 write data를 제시
  -> address decoder가 GPIOA peripheral 선택
  -> GPIOA ODR bit 5 latch가 1 저장
  -> output driver가 PA5를 high로 구동
  -> board의 resistor와 LED 전류 경로가 닫힘
  -> LED 점등
```

여기서 CPU는 LED의 색이나 밝기를 직접 이해하지 않는다. CPU는 주소와 bit pattern만 다루고, GPIO·회로·소자가 그 bit pattern을 전압·전류·빛으로 바꾼다. `memory-mapped I/O`는 이 소프트웨어와 물리 회로의 경계에 있는 약속이다.

메모리 쓰기와 읽기 타이밍은 다음 순서로 이해한다.

| 동작 | 순서 |
| :--- | :--- |
| Memory Write | 주소 출력 → write data 출력 → `CS` 활성화 → `WR` 활성화 → memory가 data 저장 |
| Memory Read | 주소 출력 → `CS` 활성화 → `RD` 활성화 → access delay 뒤 valid data 출력 → CPU가 data read |

read에서는 address, `CS`, `RD`가 먼저 안정되어야 하고, memory access delay가 지난 뒤 data bus 값이 valid가 된다. CPU가 이보다 먼저 읽으면 이전 값이나 invalid 값을 읽을 수 있으므로 wait/ready 신호 또는 bus timing 조정으로 sample 시점을 늦춤.

#### Timing chart를 실제 read 동작으로 풀어 읽기

타이밍 차트의 가로축은 시간이지만, 핵심은 '어느 신호가 먼저 안정되어야 다음 동작이 안전한가'다. SRAM read를 한 번 수행한다고 생각하면 다음 순서가 된다.

```text
1. CPU가 address bus에 읽을 위치를 낸다.
2. `CE`와 `OE`를 활성화하여 해당 SRAM의 출력을 요청한다.
3. SRAM 내부 decoder와 memory cell이 선택되고, access time이 지난다.
4. data bus 값이 valid 구간에 들어온다.
5. CPU가 clock edge에서 그 값을 sample한다.
6. CPU가 읽기를 끝낼 때까지 address·control을 필요한 hold time만큼 유지한다.
```

`setup time`은 5번의 sample edge **전**에 data가 이미 안정되어 있어야 하는 최소 시간이고, `hold time`은 sample edge **후**에도 data가 유지되어야 하는 최소 시간이다. 둘 중 하나라도 부족하면 회로가 논리 `0` 또는 `1` 중 무엇을 읽을지 보장할 수 없다. 즉 타이밍 조건은 성능을 높이기 위한 선택 사항이 아니라, register·memory·bus가 같은 값을 공유하기 위한 약속이다.

| 문제가 생긴 원인 | 눈에 보이는 결과 | 설계에서 취하는 방법 |
| :--- | :--- | :--- |
| memory access time이 CPU clock보다 김 | valid data 전에 read | wait state를 넣거나 bus clock을 낮춤 |
| address/control이 너무 일찍 바뀜 | 다른 주소 또는 잘못된 chip이 선택될 수 있음 | setup·hold time 보장 |
| 여러 장치가 data bus를 동시에 구동 | bus contention, 과전류 또는 잘못된 data | `CE`·`OE`와 high-impedance 구간으로 한 장치만 구동 |

GPIO register와 UART status register도 CPU에는 같은 load/store access로 보인다. 다만 peripheral은 memory cell 대신 외부 pin·timer·serial 회로와 연결되어 있으므로, 해당 register의 read/write timing과 side effect는 peripheral 문서가 정한 규칙을 따라야 함.

### MCU, Embedded Processor, SoC

초기에는 CPU 외부에 메모리와 주변장치를 별도로 연결했다. 반도체 공정이 발전하면서 CPU, 메모리, UART, Timer, GPIO, ADC 같은 주변장치를 하나의 칩에 넣은 MCU가 등장함.

| 용어 | 설명 |
| :--- | :--- |
| CPU 또는 MPU | 연산과 명령 실행 중심의 프로세서 |
| MCU 또는 Micom | CPU, 메모리, 기본 주변장치를 하나의 칩에 통합한 제어용 프로세서 |
| Embedded Processor | 더 높은 성능과 많은 주변장치를 통합한 프로세서 |
| SoC | CPU, 메모리 인터페이스, 주변장치, 가속기 등을 시스템 수준으로 통합한 칩 |

임베디드 시스템은 특정 기능을 수행하는 장치 안에 CPU와 소프트웨어가 내장된 시스템이다. 가전, 자동차 전장, 자동화 장비, 반도체 장비, 센서 장치, 통신 장치 등에서 사용된다.

### MCU 내부 구성과 firmware

STM32F0 같은 저가·저성능 MCU도 CPU만 들어 있는 칩이 아니다. CPU core, memory, clock과 power 제어, interrupt, timer, 통신, analog interface를 한 칩에 넣어 입출력 제어를 수행함.

| 내부 block | 역할 |
| :--- | :--- |
| CPU core, NVIC | 명령 실행과 interrupt 처리 |
| Flash, SRAM | program 저장과 실행 중 data 저장 |
| Clock, power, reset | 동작 timing, 전원 상태, 시작 조건 제어 |
| Timer, PWM | 시간 측정, 주기 생성, pulse 출력 |
| GPIO, SPI, I2C, USART | digital input/output와 serial 통신 |
| ADC, DAC, comparator | analog signal 입력·출력과 비교 |
| DMA | CPU의 매 전송 처리 없이 memory와 peripheral 사이 data 이동 |

임베디드 시스템에서 장치의 고유 기능을 제어하는 software를 `firmware`라고 한다. firmware는 버튼, sensor, timer, communication 같은 hardware 동작을 정해진 순서로 제어함.

### 반도체 제품과 software

반도체 제품의 가치는 chip 자체에서 끝나지 않는다. 메모리 제품에는 controller와 firmware가, system semiconductor에는 board에서 동작을 확인할 `BSP`와 demo program이 함께 필요함.

| 용어 | 역할 |
| :--- | :--- |
| `BSP` | Board Support Package, 특정 board에서 OS 또는 firmware가 동작하도록 묶은 초기화·driver·설정 software |
| On-device AI | data center로 보내지 않고 device 내부에서 AI 연산을 수행하는 방식 |
| NPU IP | `NPU`(Neural Processing Unit) 설계를 chip에 넣기 위한 `IP`(Intellectual Property) reusable design block |

#### AI 반도체의 응용별 분야

AI 반도체는 AI 연산을 빠르고 효율적으로 실행하도록 설계한 processor, accelerator, 또는 이를 포함한 `SoC`(System on Chip)를 넓게 부르는 말이다. 다만 회사 이름, 실행 환경, 칩의 제품 형태, CPU architecture는 서로 다른 기준임. 따라서 같은 회사가 data center와 Edge AI에 함께 들어갈 수 있고, AI service 회사가 표에 함께 놓일 수도 있음.

| 구분 기준 | 확인할 질문 | 예시 |
| :--- | :--- | :--- |
| 실행 환경 | AI 연산을 어디에서 하는가 | data center, PC, edge device |
| 제품 형태 | 어떤 chip을 파는가 | GPU/NPU accelerator, AI SoC, AI MCU |
| 제품 시장 | 어떤 제품의 문제를 푸는가 | 범용 AI, camera vision, automotive ADAS |
| 회사 역할 | chip, IP, software stack, cloud 중 무엇을 담당하는가 | chip vendor, IP vendor, cloud operator |
| CPU architecture | CPU가 어떤 instruction set을 사용하는가 | ARM, RISC-V |

`응용지향 AI`는 실행 장소를 나누는 항목보다 자동차·camera·factory처럼 특정 제품의 요구에 맞춰 AI 기능과 주변 hardware를 통합하는 제품 관점이다. 예를 들어 자동차 vision SoC는 Edge AI이면서 동시에 automotive application-oriented AI가 될 수 있음.

`AI processor`는 GPU, NPU, AI-가속 MCU, vision SoC처럼 AI 연산을 처리하는 processor 계열을 넓게 부르는 기술명이다. 따라서 data center, PC, edge처럼 실행 위치를 나눈 분류와 같은 층위로 놓지 않음.

### 실행 위치와 제품 형태

| 구분 | 실행 환경과 제품 | 중요 조건 | 대표적인 수업 예시 |
| :--- | :--- | :--- | :--- |
| Data center AI | server의 GPU/NPU accelerator와 대규모 AI system | 높은 throughput, 큰 memory bandwidth, 여러 accelerator 확장, network·power·cooling | NVIDIA data center GPU, 퓨리오사AI `RNGD`, Rebellions NPU |
| PC(+GPU) 기반 AI | PC의 CPU, GPU, client NPU | local inference, battery·heat, OS·driver·application 연결 | GPU acceleration, local AI application |
| Edge AI | sensor 가까운 camera, robot, factory, IoT, embedded device | 낮은 power, 낮은 latency, real-time response, privacy, model quantization | NVIDIA Jetson, Hailo, DEEPX |
| 응용지향 AI SoC | 특정 제품용 AI SoC | AI accelerator와 `ISP`(Image Signal Processor), sensor I/O, codec, communication, safety/security 기능 통합 | Nextchip automotive ADAS/vision SoC, DEEPX AI Vision SoC |
| AI MCU·AIoT processor | 작은 edge product의 CPU + NPU/DSP + peripheral | firmware, `RTOS`(Real-Time Operating System), board bring-up, memory·I/O 제어 | ST `STM32N6`, Kendryte `K230` |

Data center는 대형 model의 training·serving과 많은 request를 동시에 처리하는 방향에 가깝다. Edge AI는 이미 학습한 model을 제품 가까이에서 inference하는 방향에 가깝다. 두 분야 모두 AI를 실행하지만, data center는 scale-out system과 memory/network가, edge는 전력·발열·sensor·실시간성이 더 큰 설계 제약이 됨.

### 회사 이름을 분류할 때의 주의점

회사와 제품의 현재 위치는 변하므로, 아래 표는 `2026-07` 공식 제품·회사 정보 기준의 읽는 방법이다. 자세한 근거와 직군 지도는 [[domains/semiconductor/ai-npu-system-integration/ai-semiconductor-product-and-career-map]]에서 관리함.

| 이름 | 현재 위치를 읽는 방법 | 왜 같은 표에서 겹쳐 보이는가 |
| :--- | :--- | :--- |
| NVIDIA | data center GPU와 Jetson edge platform을 모두 제공하는 AI computing hardware·software 회사 | data center와 edge가 모두 제품 범위에 포함됨 |
| 퓨리오사AI | 현재 대표 제품 `RNGD`는 data center inference NPU로 보는 것이 적절함 | 수업 자료의 회사 단위 예시와 현재 대표 제품의 위치를 나눠 읽어야 함 |
| SAPEON, Rebellions | SAPEON은 `2024-12` Rebellions와 통합됨. 현재는 Rebellions를 하나의 AI accelerator 회사로 봄 | 과거 자료에는 두 회사 이름이 각각 남아 있을 수 있음 |
| NAVER | 독립 AI chip vendor보다 cloud, AI service, data center infrastructure와 chip co-design 수요자에 가까움 | AI 반도체 생태계에서는 chip을 만드는 회사뿐 아니라 이를 대규모로 쓰고 system을 설계하는 회사도 중요함 |
| Hailo | edge AI processor와 compiler·runtime software를 함께 제공 | chip과 SDK가 함께 있어 제품 탑재 단계까지 연결됨 |
| DEEPX | edge NPU와 AI vision SoC를 함께 다룸 | Edge AI와 응용지향 AI에 함께 해당함 |
| Nextchip | automotive ADAS와 vision 중심 semiconductor 회사 | 범용 NPU보다 자동차 camera/vision system 요구에 맞춘 application-oriented SoC에 가까움 |
| STMicroelectronics | MCU, MPU, sensor 등 넓은 semiconductor 회사이며 edge AI MCU 제품도 제공 | `ARM`은 ST의 회사 분류가 아니라 해당 제품 CPU core의 architecture를 뜻함 |
| Kendryte `K230` | RISC-V CPU와 `KPU`(Kendryte Processing Unit)를 통합한 AIoT SoC 사례 | `RISC-V`는 CPU instruction set이고 KPU는 AI 연산 accelerator임 |

### CPU architecture와 NPU의 역할 구분

| 용어 | 놓이는 층 | 의미 |
| :--- | :--- | :--- |
| `ARM` | CPU architecture·core IP | CPU가 실행할 instruction set과 core 설계 계열. 반도체 회사는 Arm core를 license해 자기 SoC나 MCU에 통합할 수 있음 |
| `RISC-V` | CPU instruction set architecture | 공개 ISA를 기준으로 만든 CPU core 계열. RISC-V CPU를 넣은 chip에도 별도 NPU가 함께 들어갈 수 있음 |
| `NPU` | AI accelerator | tensor, convolution, matrix multiplication 같은 neural-network 연산을 효율적으로 처리하는 hardware block |
| `NPU IP` | reusable design block | SoC 회사가 license 또는 자체 설계로 확보해 CPU, memory, bus, peripheral과 통합하는 NPU 설계물 |
| `SoC` | 완성 chip의 system 통합 | CPU, NPU, memory controller, bus, I/O, security, multimedia 등을 한 chip에 묶은 제품 |

따라서 `STMicro(ARM)`은 ST 제품의 CPU가 Arm 계열일 수 있다는 뜻이고, `Kendryte(RISC-V)`는 CPU가 RISC-V instruction set을 사용한다는 뜻이다. 둘 다 NPU를 포함할 수 있지만, ARM이나 RISC-V 자체가 NPU의 종류는 아님.

### AI 반도체를 만드는 기술과 언어

`AI 반도체 설계`는 한 언어로 끝나는 일이 아니다. architecture, RTL, verification, compiler, firmware, model deployment가 서로 다른 결과물을 만듦.

| 직무 층 | 만드는 것 | 중심 언어·기술 |
| :--- | :--- | :--- |
| SoC architecture | NPU dataflow, memory hierarchy, bus, performance·power 목표 | C++/SystemC/Python model, memory·bandwidth 분석, AMBA/PCIe/CXL 이해 |
| RTL/SoC 설계 | CPU/NPU block, bus, register, clock/reset, top-level integration | Verilog, SystemVerilog, AMBA AXI/AHB, EDA tool, Python/Tcl automation |
| design verification | testbench, assertion, coverage, regression | SystemVerilog, UVM, assertion, Python automation |
| physical implementation | RTL을 실제 silicon layout과 timing·power 조건으로 구현 | EDA flow, timing·power analysis, Tcl/Python scripting |
| NPU compiler·runtime | model graph를 hardware command와 memory schedule로 바꾸고 실행 API 제공 | C++, Python, ONNX, PyTorch, MLIR/LLVM 계열, profiling |
| firmware·BSP·driver | boot, RTOS/Linux, board 초기화, NPU/GPU driver, memory·interrupt 제어 | C, C++, ARM/RISC-V assembly, Linux/RTOS, JTAG/debug |
| model deployment·application | model training, conversion, quantization, accuracy·latency 측정, 제품 기능 연결 | Python, PyTorch/TensorFlow, ONNX, C++/Python runtime API |
| silicon validation·FAE | 실제 chip·board·camera·sensor를 연결해 성능·전력·열·호환성 확인 | embedded C/C++, Python, Linux/RTOS, lab/debug, domain interface |

Data center 쪽은 `HBM`(High Bandwidth Memory)·DDR memory, `PCIe`(Peripheral Component Interconnect Express)·`CXL`(Compute Express Link), Ethernet·`RDMA`(Remote Direct Memory Access), multi-accelerator scaling, LLM serving, compiler/runtime 최적화가 중요한 축이다. Edge·응용지향 쪽은 PPA(power, performance, area), quantization, camera ISP, sensor interface, Linux/RTOS, board support, real-time response가 중요한 축임.

현재 Cortex-M4 수업은 이 중 firmware·BSP·driver·edge product 쪽의 입구와 가장 가깝다. `C`로 memory-mapped I/O를 다루고, CPU·memory map·interrupt·GPIO를 이해하는 경험은 이후 AI MCU, edge AI board, NPU runtime integration으로 이어진다. 반대로 Verilog/SystemVerilog와 UVM을 이어가면 RTL/SoC 설계와 DV 쪽으로 갈 수 있고, Python/C++와 model compiler를 이어가면 NPU compiler·runtime 및 AI system software 쪽으로 확장할 수 있음.

AI 기술이 보편화되면 AI 기반 제품과 AI 반도체 개발 기업이 늘어날 수 있다. 반도체 부가가치를 제품 기능으로 연결하려면 embedded, AI, `OS`(Operating System) 관련 software 기술이 중요함.

특히 AI 반도체에서는 NPU IP를 license해 자체 semiconductor에 통합하는 경우가 늘어난다. NPU hardware를 실제 제품 기능으로 연결하려면 system programming과 on-device AI programming이 필요하며, Linux 또는 firmware가 hardware와 application 사이의 실행 환경을 제공함.

임베디드 소프트웨어 개발자는 일반 PC/Web/App 개발자보다 하드웨어 지식이 더 많이 필요하다. 반도체 장비 제어, 시스템 반도체 BSP, 온디바이스 AI, MCU 플랫폼 개발, 임베디드 리눅스, RISC-V/ARM 시스템 프로그래밍 같은 분야로 연결됨.

## STM32F411xE MCU와 실습보드

### ARM과 Cortex-M4

ARM은 회사명이자 프로세서 제품군 이름이다. 영국 Acorn이 1983년 자체 컴퓨터용 processor project로 시작했고(Berkeley의 RISC 연구에 기반), 1990년 Advanced RISC Machines로 분사하며 지금의 회사가 되었다. ARM은 칩을 직접 생산하기보다 core 설계물을 라이선스로 제공하고, 반도체 회사가 이를 기반으로 제품을 만든다. 저전력·간결한 구조와 license 사업 모델 덕분에 non-PC embedded RISC 시장의 대부분을 차지하는 지배적 architecture가 되었다.

`Architecture`는 프로세서의 구조, 명령어 체계, 레지스터 체계를 뜻한다. Cortex 계열은 용도에 따라 A, R, M profile로 나뉨.

| Profile | 목적 |
| :--- | :--- |
| Cortex-A | Application Processor, MMU 보유, OS 기반 고성능 시스템 |
| Cortex-R | Real-Time target, 실시간 임베디드 시스템 |
| Cortex-M | Micro Controller 대상, MCU 제어용 |

Cortex-M4 processor는 Cortex-M4 core에 `NVIC`(Nested Vectored Interrupt Controller), SysTick, debug·trace, bus interface 같은 core 기능이 결합된 형태로 이해할 수 있다. `MPU`(Memory Protection Unit)와 single-precision `FPU`(Floating-Point Unit)는 core 구현에 따라 선택될 수 있으며, STM32F411은 FPU를 탑재함.

#### Architecture version과 Thumb-2

`Architecture`는 CPU의 `ISA`(Instruction Set Architecture), register, exception, memory 접근 규칙을 정한 설계 기준이다. 같은 Cortex-M 계열도 architecture version과 확장 기능이 다름.

| Core 예시 | Architecture | 핵심 특징 |
| :--- | :--- | :--- |
| Cortex-M0/M0+ | Armv6-M | 작은 MCU를 위한 저전력·저비용 구성 |
| Cortex-M3 | Armv7-M | 범용 MCU control |
| Cortex-M4 | Armv7E-M | Armv7-M에 DSP extension을 더한 MCU·digital signal control 구성 |
| Cortex-M7 | Armv7E-M | 더 높은 performance와 DSP 기능을 갖는 MCU 구성 |

Cortex-M4는 Thumb/Thumb-2 instruction encoding을 사용한다. Thumb-2는 16-bit와 32-bit instruction을 함께 사용해 code size와 표현력을 조절하는 방식이다. 따라서 Cortex-M4를 설명할 때 과거 ARM state의 32-bit instruction과 Thumb-2를 같은 것으로 보지 않음.

`DSP`(Digital Signal Processing) extension은 multiply-accumulate와 packed arithmetic 같은 signal-processing 연산을 빠르게 처리하도록 돕는다. `SIMD`(Single Instruction, Multiple Data)는 한 instruction으로 여러 작은 data element를 병렬 처리하는 방식이며, Cortex-M4의 DSP extension에는 일부 packed SIMD arithmetic이 포함됨. `NEON`은 Cortex-M4의 기능명이 아니라 주로 Cortex-A 계열에 쓰이는 Advanced SIMD extension이므로 Cortex-M4의 DSP extension과 구분함.

공식 기준: [Arm Cortex-M4 Processor Datasheet](https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/Processor%20Datasheets/Arm%20Cortex-M4%20Processor%20Datasheet.pdf?hash=A2E52C6191D2F8DBF16DEDA88FF8E4A0CC9CA151&revision=904a9fc1-9c66-4816-80bf-ff8c76420e5a)

### STM32F411 MCU와 Nucleo-64 보드

STM32F411은 Cortex-M4 core를 탑재하고 메모리와 주변장치를 내장한 MCU다. Nucleo-64 보드는 STM32F411을 실습할 수 있도록 만든 평가보드이며, ST-LINK가 내장되어 별도 장비 없이 프로그램 writing과 debugging이 가능함.

Nucleo-64 보드에는 User Key, Reset Key, User LED, ST-LINK, Arduino extension connector 등이 포함된다.

### MCU·보드 문서를 고르는 기준

CPU core, MCU chip, evaluation board는 서로 다른 사람이 설계하므로 필요한 문서도 나뉜다. 어떤 주소를 읽고 어느 bit를 설정할지 확인할 때에는 MCU reference manual을 우선으로 봄.

| 확인할 대상 | 우선 문서 | 확인 내용 |
| :--- | :--- | :--- |
| Cortex-M4 core의 ISA·exception·core feature | Arm datasheet·technical reference manual | Armv7E-M, Thumb-2, NVIC, FPU/MPU, debug·trace |
| STM32F411의 register와 peripheral | `RM0383` reference manual | RCC, GPIO, timer, UART, SPI, memory map, register bit |
| STM32F411의 package·pin·전기 특성 | `DS10314` datasheet | pinout, package, voltage/current, memory 용량, peripheral 수 |
| Nucleo-64의 header·button·LED·ST-LINK 연결 | `UM1724` user manual과 board schematic | connector mapping, board-level wiring, programmer/debugger 연결 |

공식 문서: [STM32F411 documentation](https://www.st.com/en/microcontrollers-microprocessors/stm32f411/documentation.html), [STM32 Nucleo-64 UM1724](https://www.st.com/resource/en/user_manual/um1724-stlinkv21-in-circuit-debuggerprogrammer-for-stm8-and-stm32-stmicroelectronics.pdf)

### CMSIS header에서 core와 STM32 peripheral을 나누어 보기

STM32F411 MCU는 Arm의 Cortex-M4 core 위에 ST가 만든 memory, GPIO, timer, UART 같은 주변장치를 붙인 chip이다. 따라서 'MCU를 공부한다'는 말 안에는 서로 다른 두 범위가 들어 있음. Cortex-M4 core 자체의 동작은 Arm 문서를 기준으로 확인하고, STM32 주변장치의 주소·register·bit 동작은 ST의 reference manual과 ST device header를 기준으로 확인함.

| 확인 범위 | 주된 기준 | 실습 소스의 header | 예시 |
| :--- | :--- | :--- | :--- |
| Cortex-M4 core | Arm Cortex-M4 문서와 CMSIS-Core | [`core_cm4.h`](../helloEmbedded/0601.TYPE_QUALIFIER_EX/core_cm4.h) | `NVIC`, `SysTick`, `SCB`, core register, exception |
| STM32F411 peripheral | ST `RM0383`과 CMSIS-Device header | [`stm32f411xe.h`](../helloEmbedded/0601.TYPE_QUALIFIER_EX/stm32f411xe.h) | `GPIO`, `RCC`, `USART`, timer, DMA, base address |
| STM32F4 family의 진입 header | ST CMSIS-Device package | [`stm32f4xx.h`](../helloEmbedded/0601.TYPE_QUALIFIER_EX/stm32f4xx.h) | target device 선택과 해당 device header include |

`CMSIS`는 Cortex-M software interface와 header 작성 방식의 공통 규약이다. GPIO, RCC, USART의 실제 register 배치까지 Arm이 정하는 것은 아니다. ST는 이 규약을 따라 STM32F411의 register map을 C 구조체·base address·pointer macro로 옮긴 device header를 제공한다. 따라서 `GPIOA->MODER` 같은 code를 쓸 수 있지만, `MODER`의 bit 의미와 read/write 규칙은 여전히 ST reference manual에서 확인해야 함.

#### `stm32f4xx.h`에서 target device 선택하기

`stm32f4xx.h`는 STM32F4 family의 여러 MCU가 함께 사용하는 공통 진입 header다. 이 실습 소스는 다음처럼 한 device macro를 선택하는 방식임.

```c
/* stm32f4xx.h의 현재 선택 */
#define STM32F411xE

/* 선택 결과 */
#elif defined(STM32F411xE)
#include "stm32f411xe.h"
```

`STM32F411xE`는 STM32F411의 여러 package·memory variant를 묶는 device selector이며, 목록에는 `STM32F411RE`도 포함된다. 이 header에서는 다른 device macro가 아직 정의되지 않았을 때만 주석 처리된 선택 목록을 사용한다. 따라서 실습 source처럼 대상 줄 하나의 주석을 해제하거나, build 설정에서 `STM32F411xE` macro를 정의한다. 여러 device macro를 동시에 정의하지 않고 target 하나만 선택해야 함. 아무 device도 선택하지 않으면 header는 compile 중에 target을 먼저 선택하라는 error를 냄.

ST header 자체도 device를 바꿀 때마다 file을 고치지 않으려면 compiler preprocessor에서 target macro를 정의할 수 있다고 안내한다. 즉, 수업의 '주석 해제'는 이 소스에 보이는 선택 방법이고, generated project에서는 build option이 같은 선택을 대신할 수 있음.

```text
application C source
  -> #include "stm32f4xx.h"              : STM32F4 family entry header
  -> STM32F411xE 선택
  -> #include "stm32f411xe.h"            : STM32F411 peripheral register map
       -> #include "core_cm4.h"          : Cortex-M4 core register interface
  -> GPIO_TypeDef, GPIOA_BASE, GPIOA 등이 정의됨
  -> GPIOA->MODER처럼 장치명 -> register 형식으로 접근
```

이 흐름은 header를 내려받는 이유도 보여 준다. 같은 Cortex-M4를 사용해도 제조사와 MCU model이 달라지면 GPIO base address, 존재하는 timer·UART, register field가 달라질 수 있다. core code의 공통 부분은 CMSIS-Core로 재사용하고, 실제 board의 peripheral 제어 부분은 선택한 ST device header와 해당 ST reference manual에 맞춰 작성함.

#### `GPIO_TypeDef`와 GPIO register map의 대응

[`stm32f411xe.h`](../helloEmbedded/0601.TYPE_QUALIFIER_EX/stm32f411xe.h)의 `GPIO_TypeDef`는 GPIO port 하나의 register map을 C 구조체로 옮긴 type이다. 수업 참조본 `2.Reference_Manual_stm32f411re.pdf`는 `RM0383 Rev 4`이며, 8.4절은 같은 register를 `MODER`부터 `AFRH`까지 같은 순서로 설명한다. 8.4.11 Table 26의 `164/842`~`165/842`는 각 offset을 정한다. header의 구조체 멤버 순서와 `uint32_t` 크기 4byte를 이용하면 C member가 어느 hardware 주소를 가리키는지 바로 알 수 있음.

| `GPIO_TypeDef` member | `RM0383` 8.4 register 이름 | GPIO port base 기준 offset | `GPIOA` 실제 주소 |
| :--- | :--- | :--- | :--- |
| `MODER` | `GPIOx_MODER` | `0x00` | `0x40020000` |
| `OTYPER` | `GPIOx_OTYPER` | `0x04` | `0x40020004` |
| `OSPEEDR` | `GPIOx_OSPEEDR` | `0x08` | `0x40020008` |
| `PUPDR` | `GPIOx_PUPDR` | `0x0C` | `0x4002000C` |
| `IDR` | `GPIOx_IDR` | `0x10` | `0x40020010` |
| `ODR` | `GPIOx_ODR` | `0x14` | `0x40020014` |
| `BSRR` | `GPIOx_BSRR` | `0x18` | `0x40020018` |
| `LCKR` | `GPIOx_LCKR` | `0x1C` | `0x4002001C` |
| `AFR[0]` | `GPIOx_AFRL` | `0x20` | `0x40020020` |
| `AFR[1]` | `GPIOx_AFRH` | `0x24` | `0x40020024` |

`GPIO_TypeDef`는 RAM에 GPIO data를 새로 만드는 선언이 아니라, register의 모양과 offset을 compiler에 알려 주는 type이다. 실제 GPIOA의 시작점은 header의 `GPIOA_BASE`인 `0x40020000`이고, `GPIOA` macro는 이를 `GPIO_TypeDef *` pointer로 해석한다.

```c
#define GPIOA ((GPIO_TypeDef *) GPIOA_BASE)

GPIOA->ODR |= (1U << 5);
```

위 code에서 `GPIOA->ODR`은 개념적으로 `GPIOA_BASE + offsetof(GPIO_TypeDef, ODR)`인 `0x40020000 + 0x14`, 즉 `0x40020014`의 memory-mapped register를 뜻한다. `AFR[2]`는 manual의 low·high alternate-function register 두 개를 배열 하나로 표현한 것으로, `GPIOA->AFR[0]`은 `AFRL`, `GPIOA->AFR[1]`은 `AFRH`에 대응함.

### Nucleo-64 보드와 회로도 읽기

Nucleo-64는 MCU chip만 제공하는 대신, 실험과 prototype에 필요한 download/debug·button·LED·header를 함께 제공하는 evaluation board다. 보드 상단의 `ST-LINK/V2-1`은 USB로 받은 program을 target MCU Flash에 writing하고 debugging을 지원한다. target MCU 부분이 실제 사용자 회로가 되는 영역임.

보드의 `schematic`은 connector, user button, user LED, ST-LINK, MCU pin이 회로상 어떻게 연결되는지 보여 주는 board-level map이다. LED나 external module을 연결할 때에는 connector에 적힌 label만 보지 않고 schematic과 MCU pin mapping을 함께 확인함.

| 보드 요소 | 역할 |
| :--- | :--- |
| User Button | program이 읽어 볼 수 있는 input source |
| Reset Button | MCU reset 발생 |
| User LED | program이 제어해 볼 수 있는 output source |
| ST-LINK/V2-1 | Flash writing, debug, target reset 제어 |
| Arduino Uno V3 connector·Morpho header | shield와 external circuit 확장 |

Flash에 writing된 program은 전원을 다시 넣어도 남는다. reset은 Flash 내용을 지우지 않고 MCU가 boot sequence를 다시 시작하게 함.

### HAL과 직접 register 제어

관련 노트: [[domains/semiconductor/ai-npu-system-integration/embedded-layered-architecture-hal-driver]]

`HAL`(Hardware Abstraction Layer)은 ST가 제공하는 function 중심 peripheral library다. HAL은 빠른 초기 구현과 example 활용에 적합하며, 내부에서는 결국 해당 MCU의 register를 설정함.

직접 register 제어는 reference manual의 address, offset, bit field를 기준으로 clock, GPIO, timer, communication peripheral을 설정하는 방식이다. 이 방식으로 학습하면 vendor library가 달라져도 `clock enable -> peripheral mode 설정 -> data/status register 접근`이라는 hardware 제어 흐름을 이해할 수 있음.

HAL code와 register code는 역할이 다르다. HAL은 product 개발에서 시간을 줄이는 도구이고, register 수준 제어는 hardware의 실제 동작과 다른 MCU로 옮길 때 필요한 판단 기준을 만든다.

### Bus Address Decoder와 Memory Map

Cortex-M4 CPU는 32비트 주소선을 가지므로 이론적으로 4GB 주소 공간에 접근할 수 있다. CPU가 어떤 주소에 접근할 때 해당 메모리나 주변장치가 선택되도록 chip select를 만들어주는 역할이 bus decoder임.

같은 Cortex-M4 core를 사용해도 제조사와 제품마다 내장 메모리, 주변장치, 주소 범위는 다를 수 있다. 따라서 실제 레지스터 주소는 반드시 해당 MCU의 reference manual을 기준으로 확인해야 함.

#### Cortex-M이 공통 주소 구획을 강제하는 이유

Arm은 Cortex-M core가 보는 4GB 주소 공간을 code, SRAM, peripheral, external memory, private peripheral 영역으로 나누는 공통 memory map을 architecture 수준에서 정한다. 이 규칙 덕분에 제조사와 제품이 달라도 core의 `NVIC`, `SysTick`, `SCB` 같은 system block은 같은 PPB 영역을 사용하고, firmware의 core-level code와 CMSIS-Core interface를 재사용할 수 있다.

제조사는 이 공통 구획 안에서 자기 MCU의 Flash 용량, SRAM 용량, GPIO·timer·UART 같은 peripheral instance와 세부 base address를 배치한다. 즉 Cortex-M은 '주변장치 register까지 전부 같은 주소로 만들라'는 규칙이 아니라, 제품이 달라도 software가 공통 구조를 전제로 동작하도록 memory map의 큰 틀을 통일한다.

Cortex-M 표준 memory map과 STM32F411xE의 주요 영역은 다음과 같이 정리된다.

`RM0383` reference manual 38쪽의 memory map 표는 STM32F411xE에서 이 공통 주소 구획이 실제 Flash, SRAM, peripheral bus로 배치된 기준이다. 개별 peripheral의 base address와 register offset은 이 표와 해당 peripheral 장을 함께 확인함.

| 영역 | 주소 범위 | 의미 |
| :--- | :--- | :--- |
| Code | `0x00000000` 부근 | 부팅 시 보이는 코드 영역 |
| Flash ROM | `0x08000000` ~ `0x0807FFFF` | 512KB Flash |
| SRAM | `0x20000000` ~ `0x2001FFFF` | 128KB SRAM |
| Peripheral | `0x40000000` ~ `0x5FFFFFFF` | 제조사 주변장치 영역 |
| External RAM | `0x60000000` 부근 | 외부 RAM 영역 |
| External Device | `0xA0000000` 부근 | 외부 장치 영역 |
| Private Peripheral Bus | `0xE0000000` 이후 | Cortex-M 내부 peripheral |

주소 공간을 위에서 아래로 세워보면 다음처럼 보인다.

```text
0xFFFFFFFF  +-------------------------------+
            | Reserved / System area        |
0xE0000000  +-------------------------------+
            | Private Peripheral Bus        |
            | SysTick, NVIC, debug block    |
0xA0000000  +-------------------------------+
            | External Device               |
0x60000000  +-------------------------------+
            | External RAM                  |
0x40000000  +-------------------------------+
            | Peripheral                    |
            | GPIO, RCC, UART, Timer ...    |
0x20000000  +-------------------------------+
            | SRAM                          |
0x08000000  +-------------------------------+
            | Flash ROM                     |
0x00000000  +-------------------------------+
            | Boot mirror / Code area       |
```

리셋 직후 Cortex-M은 vector table의 첫 두 word를 `0x00000000`에서 읽어 initial stack pointer와 `Reset_Handler` 주소를 얻는다. STM32F411은 `BOOT0` 핀 상태에 따라 이 `0x00000000` alias에 mirror 되는 실제 memory 영역을 선택한다.

| `BOOT0` | mirror 대상 |
| :--- | :--- |
| `0` | Flash ROM, `0x08000000` |
| `1` | System Memory, `0x1FFFF000` |

Nucleo 보드에서는 `BOOT0`이 GND에 연결되어 Flash ROM 부팅이 기본임.

```text
BOOT0 = 0, GND
  -> Flash ROM 0x08000000이 0x00000000에 mirror
  -> user firmware의 vector table 참조
  -> Reset_Handler 실행

BOOT0 = 1, VCC
  -> System Memory 0x1FFFF000이 0x00000000에 mirror
  -> ST system bootloader의 vector table 참조
```

따라서 `0x00000000`은 항상 독립된 physical Flash 주소가 아니라, boot mode가 고른 memory를 CPU가 처음 보는 alias 주소다. Nucleo의 기본 `BOOT0=0` 연결에서는 Flash ROM의 사용자 firmware가 reset 직후 실행됨.

### 64-byte memory 예제와 3-to-8 decoder

64 byte memory 하나에는 `2^6 = 64`개의 byte 위치가 있으므로, 선택된 memory 내부 위치를 고르는 데 address 하위 6bit가 쓰인다. 64 byte 단위로 memory block을 배치하면 각 block base address는 `0x40`의 배수가 됨.

| memory block 예시 | 주소 범위 | 선택 뒤 내부 offset |
| :--- | :--- | :--- |
| Memory 0 | `0x00` ~ `0x3F` | `A[5:0]` |
| Memory 1 | `0x40` ~ `0x7F` | `A[5:0]` |
| Memory 2 | `0x80` ~ `0xBF` | `A[5:0]` |

CPU address의 상위 bit는 어느 memory·peripheral 영역인지 판별하는 decoder 입력으로 쓰고, 하위 bit는 선택된 장치 안의 register 또는 byte offset으로 전달한다.

```text
CPU address
  ├─ upper address bits ─> address decoder ─> CS0 / CS1 / CS2 ...
  └─ A[5:0] ───────────────────────────────> selected device offset
```

`3-to-8 decoder`는 입력 3bit 조합을 8개 출력 중 하나의 select signal로 바꾼다. 예를 들어 `000`이면 `Y0`, `001`이면 `Y1`을 선택한다. 실제 chip select의 active polarity는 회로에 따라 active-high 또는 active-low가 될 수 있음.

### STM32F411 주변장치 주소

STM32F411xE의 GPIO는 AHB1 영역에 배치된다. 자료에 나온 GPIO base 주소는 다음과 같음.

#### Peripheral block 주소도 base + offset으로 조합

수업 참조본 `RM0383 Rev 4`의 Table 1은 각 peripheral block의 실제 boundary address를 제시한다. [`stm32f411xe.h`](../helloEmbedded/0601.TYPE_QUALIFIER_EX/stm32f411xe.h)는 그 주소를 모두 숫자로 반복하지 않고, `PERIPH_BASE`와 bus별 offset을 먼저 정의한 뒤 각 device의 offset을 더하는 형태로 작성함.

| bus 영역 | header 정의 | 계산된 bus base | Table 1의 대표 peripheral |
| :--- | :--- | :--- | :--- |
| APB1 | `PERIPH_BASE + 0x00000000` | `0x40000000` | `TIM2`, `USART2`, `I2C1` |
| APB2 | `PERIPH_BASE + 0x00010000` | `0x40010000` | `TIM1`, `USART1`, `ADC1` |
| AHB1 | `PERIPH_BASE + 0x00020000` | `0x40020000` | `GPIOA`, `RCC`, `DMA1` |
| AHB2 | `PERIPH_BASE + 0x10000000` | `0x50000000` | `USB OTG FS` |

각 peripheral block은 다시 자기 bus base에서의 offset으로 정의된다. 예를 들어 header의 `TIM3_BASE`는 `APB1PERIPH_BASE + 0x0400`, `USART2_BASE`는 `APB1PERIPH_BASE + 0x4400`, `GPIOB_BASE`는 `AHB1PERIPH_BASE + 0x0400`이다. 이는 Table 1의 `TIM3 = 0x40000400`, `USART2 = 0x40004400`, `GPIOB = 0x40020400`과 각각 일치함.

```text
최종 register 주소
  = PERIPH_BASE
  + bus 영역 offset
  + peripheral block offset
  + register offset

GPIOA->ODR
  = 0x40000000 + 0x00020000 + 0x0000 + 0x14
  = 0x40020014

GPIOB->MODER
  = 0x40000000 + 0x00020000 + 0x0400 + 0x00
  = 0x40020400
```

여기서 '자동 계산'은 `#define`으로 만든 상수 표현식을 preprocessor와 compiler가 전개해 주소를 정하는 것을 뜻한다. compiler는 absolute address를 쓰거나 base register와 constant offset을 쓰는 instruction을 만들 수 있다. 어느 경우든 CPU가 실행 중에 peripheral을 탐색하거나 C macro를 해석하는 방식은 아니며, source에서는 `GPIOA->ODR`처럼 읽기 쉽게 쓰고 compiled code는 해당 memory-mapped address에 직접 접근함.

| Peripheral | Base address |
| :--- | :--- |
| `GPIOA` | `0x40020000` |
| `GPIOB` | `0x40020400` |
| `GPIOC` | `0x40020800` |
| `GPIOD` | `0x40020C00` |
| `GPIOE` | `0x40021000` |
| `GPIOH` | `0x40021C00` |

주변장치의 각 레지스터 실제 주소는 `Base address + offset`으로 계산한다.

자료에 나온 주요 peripheral mapping 예시는 다음과 같음.

| Peripheral | Bus | Boundary address |
| :--- | :--- | :--- |
| `TIM2` | APB1 | `0x40000000` ~ `0x400003FF` |
| `TIM3` | APB1 | `0x40000400` ~ `0x400007FF` |
| `TIM4` | APB1 | `0x40000800` ~ `0x40000BFF` |
| `TIM5` | APB1 | `0x40000C00` ~ `0x40000FFF` |
| `SPI2/I2S2` | APB1 | `0x40003800` ~ `0x40003BFF` |
| `SPI3/I2S3` | APB1 | `0x40003C00` ~ `0x40003FFF` |
| `USART2` | APB1 | `0x40004400` ~ `0x400047FF` |
| `I2C1` | APB1 | `0x40005400` ~ `0x400057FF` |
| `I2C2` | APB1 | `0x40005800` ~ `0x40005BFF` |
| `I2C3` | APB1 | `0x40005C00` ~ `0x40005FFF` |
| `USART1` | APB2 | `0x40011000` ~ `0x400113FF` |
| `USART6` | APB2 | `0x40011400` ~ `0x400117FF` |
| `SPI1/I2S1` | APB2 | `0x40013000` ~ `0x400133FF` |
| `SPI4/I2S4` | APB2 | `0x40013400` ~ `0x400137FF` |
| `SYSCFG` | APB2 | `0x40013800` ~ `0x40013BFF` |
| `EXTI` | APB2 | `0x40013C00` ~ `0x40013FFF` |
| `GPIOA` | AHB1 | `0x40020000` ~ `0x400203FF` |
| `GPIOB` | AHB1 | `0x40020400` ~ `0x400207FF` |
| `GPIOC` | AHB1 | `0x40020800` ~ `0x40020BFF` |
| `DMA1` | AHB1 | `0x40026000` ~ `0x400263FF` |
| `DMA2` | AHB1 | `0x40026400` ~ `0x400267FF` |
