# ARM Cortex-M4 디바이스 프로그래밍 대기 메모

## 수업 범위

이 대기 메모는 `ARM Cortex-M4 디바이스 프로그래밍` 과목의 디바이스 제어 범위를 정리한다. 전자 회로 기초에서 출발해 GPIO, UART, Timer, Interrupt, I2C, SPI, ADC 주변장치를 C 코드로 제어할 때 필요한 register 접근 모델까지 이어진다.

| 구분 | 내용 |
| :--- | :--- |
| 2과 | 능동 소자와 집적 회로 |
| 3과 | 컴퓨터와 임베디드 시스템 |
| 4과 | STM32F411xE MCU와 실습보드 |
| 5과 | GPIO 출력 입문 |
| 6과 | Type Qualifier와 `volatile` |
| 7과 | 비트 연산과 매크로 |
| 8과 | System Clock 설정 |
| 9과 | GPIO 입력 제어 |
| 10과 | UART와 RS232 통신 |
| 11과 | Timer 제어 |
| 12과 | Interrupt 제어 |
| 13과 | I2C BUS Interface |
| 14과 | SPI BUS Interface |
| 15과 | ADC와 센서 인터페이스 회로 |

핵심 연결은 `소자 → 논리 회로 → IC/ASIC/SoC → CPU/메모리/주변장치 → MCU → Memory-Mapped I/O → GPIO 레지스터 제어 → 통신/타이머/인터럽트/센서 제어` 순서다. 뒤쪽 C 코드는 결국 특정 peripheral register address에 정해진 bit pattern을 쓰거나, 상태 bit를 읽어 분기하는 동작으로 환원된다.

처음 보는 분야이므로 전체 구조를 먼저 그림으로 잡아두면 뒤쪽 레지스터 코드가 덜 낯설다.

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

## 능동 소자와 집적 회로

### 수동 소자와 능동 소자

수동 소자는 에너지를 소비하거나 저장하는 역할이 중심인 소자다. 저항, 콘덴서, 인덕터, 퓨즈, 스위치 등이 여기에 해당함.

능동 소자는 외부 제어 신호에 따라 전하의 흐름을 조절할 수 있는 소자다. 실제로 에너지를 새로 만들어낸다는 의미보다는, 전류 흐름을 제어하여 회로 동작을 바꿀 수 있다는 의미로 이해하는 것이 맞음.

반도체는 조건에 따라 도전율을 조절할 수 있는 재료다. 전기가 흐르지 않게 하거나, 흐르는 양을 조절할 수 있으므로 다이오드, 트랜지스터, IC의 기반이 됨.

### 다이오드와 LED

다이오드는 한쪽 방향의 전류 흐름을 허용하고 반대 방향은 막는 소자로 이해할 수 있다. PN 접합에서 P 영역은 정공이 많은 쪽, N 영역은 전자가 많은 쪽이며, 두 영역을 붙이면 다이오드가 됨.

다이오드의 방향성은 다음처럼 생각하면 된다.

```text
정방향 바이어스

  + ----->|----- -
        Diode

  전류 흐름 허용, ON

역방향 바이어스

  - ----->|----- +
        Diode

  전류 흐름 차단, OFF
```

| 항목 | 설명 |
| :--- | :--- |
| 회로 표기 | 약어 `D` 사용 |
| 정방향 | 전류 흐름 허용, ON 상태 |
| 역방향 | 전류 흐름 제한, OFF 상태 |
| 활용 | 정류, 과전압 방지, 정전압 유지, 방향 제한 |

LED는 `Light Emitting Diode`로, 빛을 내는 다이오드다. LED에는 최대 정격 전류가 있으며, 보통 20mA 정도를 넘기면 손상될 수 있다. LED의 순방향 전압은 색상에 따라 달라지며, 자료에서는 Red 약 1.8V, Green 약 2V, Blue 약 3.4V 정도로 설명함.

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

### 전압 분배와 전류 분배

직렬 회로에서는 전류가 같고 전압이 저항값에 따라 분배된다. 저항이 큰 쪽에 더 큰 전압이 걸림.

병렬 회로에서는 각 가지의 전압이 같고 전류가 저항값에 따라 분배된다. 저항이 작은 쪽으로 더 큰 전류가 흐름.

예시로, `R1`과 `R2`가 직렬 연결된 경우 전체 전류와 각 저항 전압은 다음처럼 계산한다.

```text
I = V / (R1 + R2)
V_R1 = I * R1
V_R2 = I * R2
```

`R1 = 100 ohm`, `R2 = 200 ohm`, `V = 5V`라면 다음과 같음.

| 항목 | 값 |
| :--- | :--- |
| 전체 저항 | `300 ohm` |
| 회로 전류 | `5V / 300 ohm = 16.67mA` |
| `R1` 전압 | `1.67V` |
| `R2` 전압 | `3.33V` |

병렬 연결에서는 각 저항의 양단 전압이 같고, 가지 전류는 `I = V / R`로 각각 계산한다.

### 트랜지스터와 FET

트랜지스터는 증폭과 스위칭을 목적으로 만들어진 소자다. `Transfer Resistor`에서 온 이름이며, 회로에서는 보통 `Q`로 표기함.

| 구분 | 제어 단자 | 전류 경로 | 개념 |
| :--- | :--- | :--- | :--- |
| BJT | Base | Collector-Emitter | Base 상태로 C-E 사이 ON/OFF |
| PNP | Base를 낮게 제어 | E에서 C 방향 | +V 측 스위칭에 자주 사용 |
| NPN | Base를 높게 제어 | C에서 E 방향 | 0V 측 스위칭에 자주 사용 |
| FET | Gate | Drain-Source | Gate 상태로 D-S 사이 ON/OFF |

FET는 BJT와 동작 원리는 다르지만, 소프트웨어 개발자 관점에서는 스위칭 소자로 이해해도 충분하다. P-Channel FET는 PNP와 유사하게, N-Channel FET는 NPN과 유사하게 이해할 수 있음.

스위칭 회로의 방향은 다음처럼 구분해두면 GPIO 출력과 연결하기 쉽다.

```text
NPN 또는 N-Ch low-side switch

  VCC ---- LOAD ---- C/D
                     |
                  [NPN/N-Ch]
                     |
                    GND

  Base/Gate = High -> ON
  LOAD 전류가 GND로 흐름


PNP 또는 P-Ch high-side switch

  VCC ---- [PNP/P-Ch] ---- LOAD ---- GND
             |
          Base/Gate

  Base/Gate = Low -> ON
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

## 컴퓨터와 임베디드 시스템

### 컴퓨터와 폰 노이만 구조

초기 컴퓨터는 계산을 수행하기 위한 대형 하드웨어 장치였다. 이후 프로그램을 메모리에 저장하고, CPU가 명령을 읽어 실행하는 구조가 확립되었다. 이것이 폰 노이만 구조임.

폰 노이만 구조의 기본 실행 흐름은 다음과 같다.

```text
Fetch  ->  Decode  ->  Execute
명령 읽기  명령 해석   명령 실행
```

리셋 후 CPU는 정해진 초기 PC 값, 즉 리셋 벡터 주소에서 명령어를 읽고 실행을 시작한다. 명령이 메모리 읽기나 쓰기라면, CPU는 주소를 내보내고 메모리 또는 주변장치에 접근함.

폰 노이만 구조에서 중요한 점은 명령과 데이터가 모두 memory에 저장된다는 점이다.

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

주변장치 내부에도 하드웨어가 사용하는 기능별 레지스터가 존재한다. 소프트웨어는 이 레지스터를 읽고 쓰면서 하드웨어 상태를 확인하거나 동작을 제어함.

예시로 `62256 SRAM`은 일반적인 SRAM 핀 구성을 이해하기 위해 사용되었다.

| 항목 | 값 |
| :--- | :--- |
| 주소선 | `A0`~`A14`, 15개 |
| 데이터선 | `D0`~`D7`, 8bit |
| 저장 용량 | `2^15 * 8bit = 32768Byte = 32KB` |
| 주요 제어 신호 | `CE`, `OE`, `WE` |

64Byte 메모리의 주소 범위 예시는 다음과 같다.

```text
0x00 ~ 0x3F
```

64Byte aligned 주소는 하위 6bit가 `0`인 주소다.

### 메모리 버스와 타이밍

일반적인 메모리는 주소선, 데이터선, 제어선을 가진다.

| 신호 | 역할 |
| :--- | :--- |
| `A[n:0]` | 주소 선택 |
| `D[n:0]` | 데이터 읽기/쓰기 |
| `WE` 또는 `WR` | 쓰기 제어 |
| `OE` 또는 `RD` | 읽기 제어 |
| `CE` 또는 `CS` | 칩 선택 |

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

메모리 쓰기와 읽기 타이밍은 다음 순서로 이해한다.

| 동작 | 순서 |
| :--- | :--- |
| Memory Write | 주소 출력 → write data 출력 → `CS` 활성화 → `WR` 활성화 → memory가 data 저장 |
| Memory Read | 주소 출력 → `CS` 활성화 → `RD` 활성화 → memory가 data 출력 → CPU가 data read |

### MCU, Embedded Processor, SoC

초기에는 CPU 외부에 메모리와 주변장치를 별도로 연결했다. 반도체 공정이 발전하면서 CPU, 메모리, UART, Timer, GPIO, ADC 같은 주변장치를 하나의 칩에 넣은 MCU가 등장함.

| 용어 | 설명 |
| :--- | :--- |
| CPU 또는 MPU | 연산과 명령 실행 중심의 프로세서 |
| MCU 또는 Micom | CPU, 메모리, 기본 주변장치를 하나의 칩에 통합한 제어용 프로세서 |
| Embedded Processor | 더 높은 성능과 많은 주변장치를 통합한 프로세서 |
| SoC | CPU, 메모리 인터페이스, 주변장치, 가속기 등을 시스템 수준으로 통합한 칩 |

임베디드 시스템은 특정 기능을 수행하는 장치 안에 CPU와 소프트웨어가 내장된 시스템이다. 가전, 자동차 전장, 자동화 장비, 반도체 장비, 센서 장치, 통신 장치 등에서 사용된다.

임베디드 소프트웨어 개발자는 일반 PC/Web/App 개발자보다 하드웨어 지식이 더 많이 필요하다. 반도체 장비 제어, 시스템 반도체 BSP, 온디바이스 AI, MCU 플랫폼 개발, 임베디드 리눅스, RISC-V/ARM 시스템 프로그래밍 같은 분야로 연결됨.

## STM32F411xE MCU와 실습보드

### ARM과 Cortex-M4

ARM은 회사명이자 프로세서 제품군 이름이다. ARM은 칩을 직접 생산하기보다 core 설계물을 라이선스로 제공하고, 반도체 회사가 이를 기반으로 제품을 만든다.

`Architecture`는 프로세서의 구조, 명령어 체계, 레지스터 체계를 뜻한다. Cortex 계열은 용도에 따라 A, R, M profile로 나뉨.

| Profile | 목적 |
| :--- | :--- |
| Cortex-A | Application Processor, MMU 보유, OS 기반 고성능 시스템 |
| Cortex-R | Real-Time target, 실시간 임베디드 시스템 |
| Cortex-M | Micro Controller 대상, MCU 제어용 |

Cortex-M4 프로세서는 Cortex-M4 core에 NVIC, MPU, debug, bus matrix, memory/peripheral interface 같은 core peripheral이 결합된 형태로 이해할 수 있다.

### STM32F411 MCU와 Nucleo-64 보드

STM32F411은 Cortex-M4 core를 탑재하고 메모리와 주변장치를 내장한 MCU다. Nucleo-64 보드는 STM32F411을 실습할 수 있도록 만든 평가보드이며, ST-LINK가 내장되어 별도 장비 없이 프로그램 writing과 debugging이 가능함.

Nucleo-64 보드에는 User Key, Reset Key, User LED, ST-LINK, Arduino extension connector 등이 포함된다.

### Bus Address Decoder와 Memory Map

Cortex-M4 CPU는 32비트 주소선을 가지므로 이론적으로 4GB 주소 공간에 접근할 수 있다. CPU가 어떤 주소에 접근할 때 해당 메모리나 주변장치가 선택되도록 chip select를 만들어주는 역할이 bus decoder임.

같은 Cortex-M4 core를 사용해도 제조사와 제품마다 내장 메모리, 주변장치, 주소 범위는 다를 수 있다. 따라서 실제 레지스터 주소는 반드시 해당 MCU의 reference manual을 기준으로 확인해야 함.

Cortex-M 표준 memory map과 STM32F411xE의 주요 영역은 다음과 같이 정리된다.

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

부팅 시 `BOOT0` 핀 상태에 따라 `0x00000000`에 mirror 되는 영역이 달라진다.

| `BOOT0` | mirror 대상 |
| :--- | :--- |
| `0` | Flash ROM, `0x08000000` |
| `1` | System Memory, `0x1FFFF000` |

Nucleo 보드에서는 `BOOT0`이 GND에 연결되어 Flash ROM 부팅이 기본임.

### STM32F411 주변장치 주소

STM32F411xE의 GPIO는 AHB1 영역에 배치된다. 자료에 나온 GPIO base 주소는 다음과 같음.

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

## GPIO 출력

### GPIO 핀의 역할

GPIO는 `General Purpose Input & Output`의 약어다. 출력으로 사용할 때는 0V 또는 3.3V를 내보내고, 입력으로 사용할 때는 외부 핀 상태가 low인지 high인지 읽는다.

STM32F411에는 Port A~E, H가 있으며, 각 port는 최대 16개 pin을 가진다. F와 G port는 해당 실습 대상에는 없음.

GPIO는 C 코드가 물리 pin을 직접 만지는 것이 아니라, register 값을 바꾸면 내부 회로가 pin 전압을 바꾸는 구조다.

```text
C 코드
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

### 하드웨어와 소프트웨어의 공유 지점

하드웨어와 소프트웨어는 레지스터를 통해 소통한다. 레지스터는 기능이 미리 약속된 메모리이며, 소프트웨어가 값을 쓰면 하드웨어 동작이 바뀌고, 하드웨어가 상태를 저장하면 소프트웨어가 그 값을 읽는다.

GPIO 출력 제어에서 기본적으로 확인한 레지스터는 다음과 같음.

| 레지스터 | 주소 또는 offset | 역할 |
| :--- | :--- | :--- |
| `GPIOA_MODER` | `0x40020000`, offset `0x00` | pin mode 설정 |
| `GPIOA_OTYPER` | `0x40020004`, offset `0x04` | output type 설정 |
| `GPIOA_ODR` | `0x40020014`, offset `0x14` | output data 설정 |

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

`GPIOx_OTYPER`는 출력으로 설정된 pin의 출력 타입을 1bit씩 설정한다.

| 값 | output type |
| :--- | :--- |
| `0` | Push-Pull |
| `1` | Open-Drain |

PA5를 push-pull로 쓰려면 `GPIOA_OTYPER[5] = 0`으로 설정한다.

Push-Pull은 0 또는 1을 적극적으로 출력하는 방식이고, Open-Drain은 0 또는 floating 상태를 만드는 방식이다. 일반적인 디지털 출력은 push-pull이 편하고, active-low LED처럼 0V를 on/off하는 목적에서는 open-drain이 유리할 수 있음.

### `GPIOx_ODR`

`GPIOx_ODR`는 출력 pin의 output value를 설정한다. PA5를 high로 만들려면 `GPIOA_ODR[5] = 1`을 기록한다.

Nucleo-64 보드의 User LED는 PA5에 연결되어 있고, PA5가 high가 되면 LED가 켜지는 구조다.

```text
PA5 MODER[11:10] = 01  -> GPIO output
PA5 OTYPER[5]    = 0   -> push-pull
PA5 ODR[5]       = 1   -> high output, LED ON
```

PA5 user LED는 active-high 구조로 이해하면 된다.

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

### Memory-Mapped I/O와 직접 주소 접근

GPIO는 ARM CPU core의 메모리 버스에 연결된 주변장치다. 주변장치 내부 레지스터는 CPU 입장에서 메모리처럼 주소를 가진다. 이런 구조를 `Memory-Mapped I/O`라고 한다.

C 코드에서는 포인터와 캐스팅을 이용해 특정 주소의 레지스터를 직접 접근할 수 있다.

설명용 예시는 `0x1000` 주소에 `100`을 기록하는 과정이었다.

```c
int *p = (int *)0x1000;
*p = 100;
```

위 코드는 같은 주소를 바로 역참조하는 다음 한 줄로 줄여 쓸 수 있다.

```c
*(int *)0x1000 = 100;
```

`#define`으로 주소 접근 표현을 감추면 이후 코드의 의미가 조금 더 분명해진다.

```c
#define TEMP (*(int *)0x1000)

TEMP = TEMP + 100;
```

하드웨어 레지스터 접근에서는 실제로는 `volatile`을 붙여야 한다.

```c
#define GPIOA_MODER (*(volatile unsigned int *)0x40020000)
#define GPIOA_OTYPER (*(volatile unsigned int *)0x40020004)
#define GPIOA_ODR (*(volatile unsigned int *)0x40020014)
```

`volatile`은 하드웨어 레지스터처럼 프로그램 외부에서 값이 바뀌거나 접근 자체가 의미를 가지는 대상에 필요하다. 컴파일러가 레지스터 접근을 임의로 제거하거나 합치지 않도록 막는 역할을 함.

레지스터 접근에서는 `volatile`만으로 모든 문제가 해결되지는 않는다. 접근 폭은 register 정의와 맞아야 하고, clock enable이 꺼진 peripheral에 접근하면 기대한 동작이 나오지 않을 수 있다. 또한 read-to-clear, write-one-to-clear처럼 읽기나 쓰기 자체가 side effect를 가지는 bit가 있으므로 reference manual의 bit 설명을 기준으로 코드를 작성해야 한다.

### PA5 User LED ON 코드 흐름

PA5 User LED를 켜기 위한 최소 흐름은 다음과 같다.

```text
1. GPIOA_MODER에서 PA5 mode를 output으로 설정
2. GPIOA_OTYPER에서 PA5 output type을 push-pull로 설정
3. GPIOA_ODR에서 PA5 output data를 high로 설정
```

비트 위치는 다음과 같다.

```text
PA5 mode   -> GPIOA_MODER[11:10]
PA5 type   -> GPIOA_OTYPER[5]
PA5 output -> GPIOA_ODR[5]
```

자료의 빈칸 채우기 형태를 완성하면 다음과 같은 코드가 된다.

```c
#define GPIOA_MODER (*(volatile unsigned int *)0x40020000)
#define GPIOA_OTYPER (*(volatile unsigned int *)0x40020004)
#define GPIOA_ODR (*(volatile unsigned int *)0x40020014)

void Main(void)
{
    /* PA5를 GPIO output mode로 설정 */
    GPIOA_MODER &= ~(0x3u << 10);
    GPIOA_MODER |= (0x1u << 10);

    /* PA5를 push-pull output으로 설정 */
    GPIOA_OTYPER &= ~(0x1u << 5);

    /* PA5에 high 출력, Nucleo User LED ON */
    GPIOA_ODR |= (0x1u << 5);
}
```

## PA7 외부 LED 과제

과제는 외부 LED를 PA7에 연결하고 ON/OFF를 제어하는 내용이다. 회로 조건은 LED가 active-low가 되도록 구성하는 방식이다.

| 항목 | 내용 |
| :--- | :--- |
| 연결 pin | `PA7` |
| LED ON 조건 | PA7에서 `0` 출력 |
| LED OFF 조건 | PA7을 floating 또는 high 상태로 둠 |
| 권장 출력 타입 | Open-Drain |

Active-low 구조에서는 LED를 켤 때 `0`을 출력한다. LED를 끌 때 반드시 `1`을 적극적으로 출력할 필요는 없고, open-drain으로 floating 상태를 만들면 연결을 끊는 효과를 낼 수 있다.

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

## Type Qualifier

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

| 경우 | `volatile`이 필요한 이유 |
| :--- | :--- |
| Memory-Mapped I/O | 하드웨어가 레지스터 값을 변경 가능 |
| Timer, ADC 등 주변장치 | CPU 코드와 무관하게 값 변화 |
| DMA 전송 메모리 | CPU가 쓰지 않아도 메모리 내용 변화 |
| ISR 공유 변수 | main code와 interrupt routine이 같은 변수 공유 |
| 멀티 프로세스 공유 메모리 | 다른 실행 흐름에서 값 변경 가능 |

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

GPIO 레지스터 정의도 `volatile unsigned long`으로 작성해야 한다.

```c
#define GPIOA_MODER (*(volatile unsigned long *)0x40020000)
#define GPIOA_OTYPER (*(volatile unsigned long *)0x40020004)
#define GPIOA_ODR (*(volatile unsigned long *)0x40020014)
```

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

Call by address의 신뢰성을 높이는 예시는 다음과 같다.

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

### CMSIS 방식의 레지스터 정의

레지스터를 개별 주소로만 `#define`하는 방식은 규모가 커질수록 관리가 어렵다. ARM CMSIS와 제조사 header는 주변장치를 구조체로 묶어 `장치명->레지스터명` 형식으로 접근하도록 정의함.

System Timer의 구조체 정의 예시는 다음과 같음.

```c
typedef struct
{
    volatile unsigned long CTRL;
    volatile unsigned long LOAD;
    volatile unsigned long VAL;
    volatile const unsigned long CALIB;
} SysTick_Type;

#define SCS_BASE (0xE000E000UL)
#define SysTick_BASE (SCS_BASE + 0x0010UL)
#define SysTick ((SysTick_Type *)SysTick_BASE)
```

사용 예시는 다음과 같다.

```c
SysTick->VAL = 0x1000;
```

STM32F411의 GPIO도 `GPIO_TypeDef` 같은 구조체로 정의되어 있다.

```c
typedef struct
{
    volatile unsigned int MODER;
    volatile unsigned int OTYPER;
    volatile unsigned int OSPEEDR;
    volatile unsigned int PUPDR;
    volatile unsigned int IDR;
    volatile unsigned int ODR;
    volatile unsigned int BSRR;
    volatile unsigned int LCKR;
    volatile unsigned int AFR[2];
} GPIO_TypeDef;

#define PERIPH_BASE (0x40000000UL)
#define AHB1PERIPH_BASE (PERIPH_BASE + 0x00020000UL)

#define GPIOA_BASE (AHB1PERIPH_BASE + 0x0000UL)
#define GPIOB_BASE (AHB1PERIPH_BASE + 0x0400UL)

#define GPIOA ((GPIO_TypeDef *)GPIOA_BASE)
#define GPIOB ((GPIO_TypeDef *)GPIOB_BASE)
```

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

## 비트 연산과 매크로 활용

### 전체 레지스터 대입의 문제

아래 코드는 PA5 LED만 제어하려는 의도지만, `GPIOA->MODER`, `GPIOA->OTYPER`, `GPIOA->ODR` 전체 값을 덮어쓴다.

```c
void Main(void)
{
    GPIOA->MODER = 0x1u << 10;
    GPIOA->OTYPER = 0x0u << 5;
    GPIOA->ODR = 0x1u << 5;
}
```

같은 port의 다른 pin이 이미 다른 회로에 연결되어 있으면, 이 대입 때문에 다른 pin의 설정이나 출력값이 같이 바뀔 수 있다. 따라서 원하는 bit 또는 field만 바꾸는 비트 연산이 필요함.

### 원하는 비트만 set, clear, invert

예시 값은 다음과 같다.

```c
int a = 0x33CC33CC;
```

`0`, `6`, `24`, `25`번 bit를 다룰 때 mask는 다음처럼 만든다.

```c
unsigned int mask = (0x3u << 24) | (0x1u << 6) | (0x1u << 0);
```

mask가 닿는 bit 위치는 다음처럼 표시할 수 있다.

```text
bit index
31        24        16         8         0
|---------|---------|----------|---------|

a    = 0011 0011 1100 1100 0011 0011 1100 1100
mask = 0000 0011 0000 0000 0000 0000 0100 0001
          ^^                          ^        ^
        25,24                         6        0
```

| 연산 | 코드 | 의미 |
| :--- | :--- | :--- |
| Set | `a |= mask;` | mask가 1인 bit만 1로 설정 |
| Clear | `a &= ~mask;` | mask가 1인 bit만 0으로 설정 |
| Invert | `a ^= mask;` | mask가 1인 bit만 반전 |
| Check | `if (a & (1u << n))` | n번 bit가 1인지 확인 |

`=`를 사용하면 전체 값이 mask로 바뀌지만, `|=`, `&=`, `^=`를 사용하면 다른 bit는 유지된다.

### PA5 LED를 비트 연산으로 켜기

PA5 mode field는 2bit이므로 먼저 `GPIOA->MODER[11:10]`을 지우고 `01`을 써야 한다.

```c
void Main(void)
{
    GPIOA->MODER = (GPIOA->MODER & ~(0x3u << 10)) | (0x1u << 10);
    GPIOA->OTYPER &= ~(0x1u << 5);
    GPIOA->ODR |= (0x1u << 5);
}
```

필드 write의 일반형은 다음과 같다.

```c
dest = (dest & ~(bits << position)) | (data << position);
```

### 비트 처리 매크로

한 bit를 처리하는 macro는 다음처럼 정의할 수 있다.

```c
#define Macro_Set_Bit(dest, position) \
    ((dest) |= (1u << (position)))

#define Macro_Clear_Bit(dest, position) \
    ((dest) &= ~(1u << (position)))

#define Macro_Invert_Bit(dest, position) \
    ((dest) ^= (1u << (position)))
```

여러 bit field를 처리하는 macro는 다음과 같음.

```c
#define Macro_Clear_Area(dest, bits, position) \
    ((dest) &= ~((unsigned)(bits) << (position)))

#define Macro_Set_Area(dest, bits, position) \
    ((dest) |= ((unsigned)(bits) << (position)))

#define Macro_Invert_Area(dest, bits, position) \
    ((dest) ^= ((unsigned)(bits) << (position)))

#define Macro_Write_Block(dest, bits, data, position) \
    ((dest) = ((dest) & ~((unsigned)(bits) << (position))) | \
              ((unsigned)(data) << (position)))

#define Macro_Extract_Area(dest, bits, position) \
    ((((unsigned)(dest)) >> (position)) & (bits))
```

예시 동작은 다음과 같다.

```c
int a = 0xCC3355AA;

Macro_Set_Bit(a, 0);
Macro_Clear_Bit(a, 3);
Macro_Invert_Bit(a, 6);

Macro_Clear_Area(a, 0x3, 2);
Macro_Set_Area(a, 0x7, 8);
Macro_Invert_Area(a, 0x1F, 12);

Macro_Write_Block(a, 0x7, 0x5, 2);
a = Macro_Extract_Area(a, 0x7, 2);
```

### 매크로를 이용한 LED Toggle

```c
void Main(void)
{
    volatile int i;

    Macro_Set_Bit(RCC->AHB1ENR, 0);
    Macro_Write_Block(GPIOA->MODER, 0x3, 0x1, 10);
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

### LED Driver 함수 설계

LED 제어 코드를 application에서 직접 쓰지 않고 driver 함수로 감싸면 이후 코드가 깔끔해진다.

```c
void LED_Init(void)
{
    Macro_Set_Bit(RCC->AHB1ENR, 0);
    Macro_Write_Block(GPIOA->MODER, 0x3, 0x1, 10);
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

검증용 main은 다음 형태로 작성할 수 있다.

```c
#include "device_driver.h"

extern void LED_Init(void);
extern void LED_On(void);
extern void LED_Off(void);

void Main(void)
{
    volatile int i;
    int led = 0;

    LED_Init();

    for (;;)
    {
        (led ^= 1) ? LED_Off() : LED_On();

        for (i = 0; i < 0x20000; i++)
            ;
    }
}
```

## System Clock 설정

### Clock source와 PLL

CPU는 clock을 기준으로 동작하므로 clock 입력이 반드시 필요하다. 마이크로컨트롤러에서 흔히 사용하는 clock source는 다음과 같음.

| 구분 | 특징 |
| :--- | :--- |
| Resonator | 저가, 저정밀, 저주파 |
| X-TAL | crystal 기반, 고정밀, 고주파 |
| Oscillator | 부가 회로가 적은 clock source |
| PLL | 낮은 기준 주파수로 더 높은 목표 주파수 합성 |

PLL은 기준 clock을 이용해 더 높은 주파수를 만드는 장치다. 안정된 목표 주파수에 도달하기까지 lock time이 필요하므로, PLL을 켠 뒤 ready 상태를 확인해야 함.

STM32F411 clock tree에서는 HSI 16MHz 또는 HSE를 기준으로 PLL을 구성하고, SYSCLK, AHB, APB1, APB2, USB 48MHz clock 등을 설정한다.

단순화한 clock tree는 다음과 같다.

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

### `RCC->CR`

`RCC->CR`은 clock source ON/OFF와 ready 상태를 확인하는 register다.

| bit | 이름 | 의미 |
| :--- | :--- | :--- |
| `0` | `HSION` | HSI 16MHz clock enable |
| `1` | `HSIRDY` | HSI ready |
| `16` | `HSEON` | HSE clock enable |
| `17` | `HSERDY` | HSE ready |
| `24` | `PLLON` | PLL enable |
| `25` | `PLLRDY` | PLL ready |

### `RCC->PLLCFGR`

PLL 계산식은 다음과 같다.

```text
fVCO = fPLL_input * (PLLN / PLLM)
fPLL_general_output = fVCO / PLLP
fUSB_OTG_FS_SDIO = fVCO / PLLQ
```

자료의 설정값은 HSI 16MHz 기준으로 `SYSCLK = 96MHz`, `USBCLK = 48MHz`를 목표로 한다.

```c
RCC->PLLCFGR = (8u << 24) | (0u << 22) | (1u << 16) | (192u << 6) | (8u << 0);
```

| field | 값 | 의미 |
| :--- | :--- | :--- |
| `PLLM` | `8` | `16MHz / 8 = 2MHz` |
| `PLLN` | `192` | `2MHz * 192 = 384MHz` |
| `PLLP` | `4` | `384MHz / 4 = 96MHz` |
| `PLLQ` | `8` | `384MHz / 8 = 48MHz` |
| `PLLSRC` | `0` | HSI 사용 |

### `RCC->CFGR`

`RCC->CFGR`은 SYSCLK source와 AHB/APB prescaler를 설정한다. 자료에서는 SYSCLK 96MHz에서 AHB와 APB2는 1분주, APB1은 2분주로 설정함.

```c
RCC->CFGR = (0u << 13) | (4u << 10) | (0u << 4);
Macro_Write_Block(RCC->CFGR, 0x3, 0x2, 0);
while (Macro_Extract_Area(RCC->CFGR, 0x3, 2) != 0x2)
    ;
```

| 설정 | 값 | 결과 |
| :--- | :--- | :--- |
| `SW` | `0x2` | PLL output을 SYSCLK로 선택 |
| `SWS` | `0x2` 확인 | PLL이 실제 SYSCLK source인지 확인 |
| `HPRE` | `0` | AHB 1분주 |
| `PPRE2` | `0` | APB2 1분주 |
| `PPRE1` | `4` | APB1 2분주 |

### Flash wait cycle과 `FLASH->ACR`

CPU clock이 빨라지면 Flash memory access time을 맞추기 위해 wait cycle이 필요하다. 3.3V에서 HCLK 96MHz로 동작할 때 자료에서는 3 wait cycle이 필요하다고 설명함.

`FLASH->ACR`은 wait cycle, cache, prefetch를 설정한다.

| field | 의미 |
| :--- | :--- |
| `LATENCY` | Flash wait cycle 수 |
| `PRFTEN` | Prefetch enable |
| `ICEN` | I-Cache enable |
| `DCEN` | D-Cache enable |
| `ICRST`, `DCRST` | cache reset |

설정 예시는 다음과 같다.

```c
FLASH->ACR = (1u << 12) | (1u << 11);
FLASH->ACR = (1u << 10) | (1u << 9) | (1u << 8) | (0x3u << 0);
```

### Clock 초기화 함수

자료의 clock 설정 흐름을 정리하면 다음과 같다.

```c
void clockInit(void)
{
    RCC->CR |= (1u << 0);
    while (!Macro_Check_Bit_Set(RCC->CR, 1))
        ;

    FLASH->ACR = (1u << 12) | (1u << 11);
    FLASH->ACR = (1u << 10) | (1u << 9) | (1u << 8) | (0x3u << 0);

    RCC->PLLCFGR = (8u << 24) | (0u << 22) | (1u << 16) | (192u << 6) | (8u << 0);

    Macro_Set_Bit(RCC->CR, 24);
    while (!Macro_Check_Bit_Set(RCC->CR, 25))
        ;

    RCC->CFGR = (0u << 13) | (4u << 10) | (0u << 4);
    Macro_Write_Block(RCC->CFGR, 0x3, 0x2, 0);
    while (Macro_Extract_Area(RCC->CFGR, 0x3, 2) != 0x2)
        ;
}
```

조건부 compile에서 사용하는 clock 정의 예시는 다음과 같다.

```c
#define SYSCLK 96000000
#define HCLK SYSCLK
#define PCLK2 HCLK
#define PCLK1 (HCLK / 2)
```

### Peripheral clock enable

STM32 주변장치는 기본적으로 clock이 꺼져 있으므로 사용 전에 RCC에서 해당 peripheral clock을 켜야 한다.

| Register | 대상 bus | 예시 bit |
| :--- | :--- | :--- |
| `RCC->AHB1ENR` | AHB1 peripheral | `GPIOAEN`, `GPIOBEN`, `GPIOCEN` |
| `RCC->APB1ENR` | APB1 peripheral | `TIM2EN`, `TIM3EN`, `USART2EN`, `I2C1EN`, `SPI2EN` |
| `RCC->APB2ENR` | APB2 peripheral | `TIM1EN`, `USART1EN`, `SPI1EN`, `SYSCFGEN` |

GPIOA를 사용하려면 다음 코드가 필요함.

```c
Macro_Set_Bit(RCC->AHB1ENR, 0);
```

## GPIO 입력 제어

### 입력 pin과 high impedance

GPIO pin은 출력뿐 아니라 입력으로도 사용할 수 있다. 입력으로 설정된 pin은 외부 전압이 low인지 high인지 읽는다.

아무것도 연결되지 않은 입력은 `0`도 `1`도 안정적으로 보장되지 않는 high impedance 상태가 될 수 있다. 프로세서는 결국 이 상태를 0 또는 1로 판단하지만, 값이 예측 불가능하므로 입력 회로에 default level을 만들어야 함.

입력 pin을 아무 데도 연결하지 않으면 다음처럼 떠 있는 상태가 된다.

```text
GPIO input pin ---- open

결과:
  0V도 아님
  3.3V도 아님
  프로세서가 0 또는 1 중 무엇으로 읽을지 보장 불가
```

### Pull-Up과 Pull-Down

| 회로 | Released 상태 | Pressed 상태 | 설명 |
| :--- | :--- | :--- | :--- |
| Pull-Down | `0V`, low | `3.3V`, high | 평소 low로 끌어내림 |
| Pull-Up | `3.3V`, high | `0V`, low | 평소 high로 끌어올림 |

Nucleo 보드의 User Key는 `PC13`에 연결되어 있고 외부 pull-up이 설치되어 있다. 따라서 active-low 입력이다.

| 상태 | `PC13` 입력 |
| :--- | :--- |
| Key released | `1` |
| Key pressed | `0` |

Pull-down과 pull-up 회로는 다음처럼 반대 방향으로 default 값을 만든다.

```text
Pull-down, active-high key

3.3V
  |
 [SW]
  |
  +---- GPIO input
  |
 [R]
  |
 GND

released -> resistor가 GND로 당김 -> 0
pressed  -> 3.3V 연결         -> 1


Pull-up, active-low key

3.3V
  |
 [R]
  |
  +---- GPIO input
  |
 [SW]
  |
 GND

released -> resistor가 3.3V로 당김 -> 1
pressed  -> GND 연결             -> 0
```

### `GPIOx_MODER`와 `GPIOx_IDR`

PC13을 입력으로 쓰려면 `GPIOC->MODER[27:26] = 00`으로 설정한다.

```c
Macro_Write_Block(GPIOC->MODER, 0x3, 0x0, 26);
```

입력값은 `GPIOx_IDR`에서 읽는다.

```c
if (GPIOC->IDR & (1u << 13))
{
    /* released */
}
else
{
    /* pressed */
}
```

bit check macro는 다음과 같이 작성할 수 있다.

```c
#define Macro_Check_Bit_Set(dest, pos) \
    ((((unsigned)(dest)) >> (pos)) & 0x1u)

#define Macro_Check_Bit_Clear(dest, pos) \
    (!((((unsigned)(dest)) >> (pos)) & 0x1u))
```

### KEY 인식 실습

PC13 User Key가 눌렸으면 PA5 LED를 켜고, 눌리지 않았으면 LED를 끄는 코드 흐름은 다음과 같음.

```c
void Main(void)
{
    Macro_Set_Bit(RCC->AHB1ENR, 2);
    Macro_Write_Block(GPIOC->MODER, 0x3, 0x0, 26);

    LED_Init();

    for (;;)
    {
        if (Macro_Check_Bit_Clear(GPIOC->IDR, 13))
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

외부 KEY 과제에서는 PC7에 active-low key를 연결한다. pull-up 저항을 외부에 연결하지 않으면 released 상태가 floating이 되므로 `GPIOx->PUPDR`에서 internal pull-up 설정이 필요함.

```c
Macro_Set_Bit(RCC->AHB1ENR, 2);
Macro_Write_Block(GPIOC->MODER, 0x3, 0x0, 14);
Macro_Write_Block(GPIOC->PUPDR, 0x3, 0x1, 14);
```

### KEY에 의한 LED Toggling과 Inter-Lock

CPU는 96MHz처럼 매우 빠르게 동작하므로, key를 잠깐 눌러도 loop는 여러 번 실행된다. 단순히 key가 눌린 동안 계속 toggle하면 한 번 누른 입력이 여러 번 처리됨.

해결 방법 중 하나는 inter-lock이다. key가 눌린 것을 한 번 처리하면 lock을 걸고, key가 released 상태가 될 때 lock을 해제한다.

```c
void Main(void)
{
    int lock = 0;

    Macro_Set_Bit(RCC->AHB1ENR, 2);
    Macro_Write_Block(GPIOC->MODER, 0x3, 0x0, 26);

    for (;;)
    {
        if ((lock == 0) && Macro_Check_Bit_Clear(GPIOC->IDR, 13))
        {
            Macro_Invert_Bit(GPIOA->ODR, 5);
            lock = 1;
        }
        else if ((lock == 1) && Macro_Check_Bit_Set(GPIOC->IDR, 13))
        {
            lock = 0;
        }
    }
}
```

이 방식을 사용해도 toggle이 이상하면 switch chattering을 의심해야 함.

### KEY Driver 함수 설계

```c
void Key_Poll_Init(void)
{
    Macro_Set_Bit(RCC->AHB1ENR, 2);
    Macro_Write_Block(GPIOC->MODER, 0x3, 0x0, 26);
}

int Key_Get_Pressed(void)
{
    return Macro_Check_Bit_Clear(GPIOC->IDR, 13);
}

void Key_Wait_Key_Pressed(void)
{
    while (!Key_Get_Pressed())
        ;
}

void Key_Wait_Key_Released(void)
{
    while (Key_Get_Pressed())
        ;
}
```

검증용 main은 다음 흐름으로 작성할 수 있음.

```c
void Main(void)
{
    int i;
    volatile int j;

    LED_Init();
    Key_Poll_Init();

    printf("Key를 누르면 ON, 떼면 OFF => 10회 동작\n");
    for (i = 0; i < 10; i++)
    {
        Key_Wait_Key_Pressed();
        printf("Key Pressed! [%d]\n", i);
        LED_On();

        Key_Wait_Key_Released();
        LED_Off();
    }

    printf("Key를 누르면 Key Pressed! 인쇄, 안 누르면 # 인쇄 => 10회 동작\n");
    for (i = 0; i < 10; i++)
    {
        if (Key_Get_Pressed())
        {
            printf("Key Pressed! [%d]\n", i);
            Key_Wait_Key_Released();
        }
        else
        {
            printf("#");
            for (j = 0; j < 0x80000; j++)
                ;
        }
    }
}
```

## UART와 RS232 통신

### UART와 비동기 직렬 통신

UART는 `Universal Asynchronous Receiver/Transmitter`의 약어다. clock 선을 별도로 공유하지 않고, 송신기와 수신기가 같은 baud rate 설정을 기준으로 start bit, data bit, parity bit, stop bit를 해석하는 비동기 직렬 통신 장치다.

8bit data, parity 없음, 1 stop bit의 UART frame은 다음과 같이 해석한다.

```text
idle     start   D0   D1   D2   D3   D4   D5   D6   D7   stop   idle
  1        0     b0   b1   b2   b3   b4   b5   b6   b7    1      1
───┐     ┌───┬────┬────┬────┬────┬────┬────┬────┬────┬────┐   ┌────
   └─────┘   │    │    │    │    │    │    │    │    │    └───┘

전송 순서: start bit -> LSB(D0) first -> ... -> MSB(D7) -> stop bit
```

| 구성 | 설명 |
| :--- | :--- |
| Start bit | frame 시작 표시 |
| Data bit | 7bit, 8bit, 9bit 등 선택 |
| Parity bit | 오류 검출용 선택 bit |
| Stop bit | frame 종료 표시 |
| Idle | 전송이 없는 상태 |
| Break | 긴 low 상태로 특수 상태 표시 |

일반적으로 data는 LSB first로 전송된다.

### RS232, RS422, RS485

| 규격 | 특징 |
| :--- | :--- |
| RS232 | 근거리 저속 비동기 직렬 통신, DTE-DCE 규약 |
| RS422 | differential 방식, 고속 원거리 전송 |
| RS485 | multi-drop 구성 지원, half-duplex 가능 |

요즘은 RS232 본래의 9개 신호를 모두 쓰기보다 debugging port로 `RX`, `TX`, `GND` 세 선만 연결해 사용하는 경우가 많다.

| DB-9 signal | 의미 |
| :--- | :--- |
| `DCD` | Carrier Detect |
| `RXD` | Receive Data |
| `TXD` | Transmit Data |
| `DTR` | Data Terminal Ready |
| `GND` | Signal Ground |
| `DSR` | Data Set Ready |
| `RTS` | Request To Send |
| `CTS` | Clear To Send |
| `RI` | Ring Indicator |

RS232 전기 신호에서는 TTL 논리와 다른 전압 레벨을 사용한다. 자료에서는 `Space(0)`과 `Mark(1)`이 양/음 전압으로 표현되는 구조를 설명했다.

### RS232-USB Bridge

PC와 MCU 간 통신은 RS232 포트 대신 USB bridge IC를 사용하는 경우가 많다. CP2102 같은 bridge는 UART `TXD`, `RXD`를 USB로 변환하고, PC에서는 virtual COM port로 보이게 함.

```text
MCU USART1_TX  ->  Bridge RXD  -> USB -> PC virtual COM
MCU USART1_RX  <-  Bridge TXD  <- USB <- PC virtual COM
GND            --- GND
```

### USART 기본 설정 레지스터

`USARTx->CR1`은 USART 기본 동작을 설정한다.

| field | 의미 |
| :--- | :--- |
| `UE` | USART enable |
| `M` | word length, 8bit 또는 9bit |
| `PCE` | parity control enable |
| `PS` | parity selection |
| `PEIE` | parity error interrupt enable |
| `TXEIE` | transmit data register empty interrupt enable |
| `RXNEIE` | receive data register not empty interrupt enable |
| `TCIE` | transmission complete interrupt enable |
| `TE` | transmitter enable |
| `RE` | receiver enable |

`USARTx->CR2`에서는 stop bit 수를 설정한다.

| `STOP[1:0]` | stop bit |
| :--- | :--- |
| `00` | 1 stop bit |
| `01` | 0.5 stop bit |
| `10` | 2 stop bits |
| `11` | 1.5 stop bits |

`USARTx->BRR`은 baud rate를 설정한다. 계산 흐름은 다음과 같음.

```text
USARTDIV = fCK / (16 * baud)
DIV_Fraction = round(frac(USARTDIV) * 16)
DIV_Mantissa = int(USARTDIV) + carry
BRR = (DIV_Mantissa << 4) | DIV_Fraction
```

`USARTx->DR`은 송수신 data register다. 프로그래머에게는 같은 address처럼 보이지만, bus transaction 방향에 따라 의미가 달라진다. CPU가 해당 address에 write하면 transmit data register 쪽으로 데이터가 들어가 송신이 시작되고, CPU가 같은 address를 read하면 receive data register에 보관된 수신 byte를 읽는다.

이 구조 때문에 상태 flag 확인이 중요하다. 송신 전에는 `SR.TXE`가 set인지 확인해 data register가 비었는지 보고, 수신 전에는 `SR.RXNE`가 set인지 확인해 수신 data가 준비됐는지 본다. `DR` read는 `RXNE` clear와 연결될 수 있으므로, status read와 data read 순서도 reference manual 기준으로 맞춰야 한다.

`USARTx->SR`의 주요 flag는 다음과 같다.

| flag | 의미 | clear 조건 |
| :--- | :--- | :--- |
| `TXE` | transmit data register empty | `DR` write 후 clear |
| `RXNE` | receive data register not empty | `DR` read 후 clear |
| `TC` | transmission complete | 전송 완료 |
| `ORE` | overrun error | 상태/데이터 처리 필요 |
| `PE` | parity error | parity error |

### USART1 pin mapping

USART1은 alternate function `AF7`로 지정된다. 실습에서는 `PA9`를 TX, `PA10`을 RX로 사용함.

| Pin | Function | AF |
| :--- | :--- | :--- |
| `PA9` | `USART1_TX` | `AF7` |
| `PA10` | `USART1_RX` | `AF7` |

GPIO를 alternate function으로 쓰려면 `MODER`를 `10`으로 설정하고, `AFR[1]`에서 해당 pin의 AF 값을 설정한다.

```c
Macro_Write_Block(GPIOA->MODER, 0xF, 0xA, 18);
Macro_Write_Block(GPIOA->AFR[1], 0xFF, 0x77, 4);
```

### UART 초기화 함수

USART1은 APB2 clock인 `PCLK2`를 사용한다. 자료의 초기화 함수 흐름은 다음과 같이 정리할 수 있음.

```c
#define SYSCLK 96000000
#define HCLK SYSCLK
#define PCLK2 HCLK
#define PCLK1 (HCLK / 2)

void Uart1_Init(int baud)
{
    double div;
    unsigned int mant;
    unsigned int frac;

    Macro_Set_Bit(RCC->AHB1ENR, 0);
    Macro_Set_Bit(RCC->APB2ENR, 4);

    Macro_Write_Block(GPIOA->MODER, 0xF, 0xA, 18);
    Macro_Write_Block(GPIOA->AFR[1], 0xFF, 0x77, 4);
    Macro_Write_Block(GPIOA->PUPDR, 0xF, 0x5, 18);

    div = PCLK2 / (16.0 * baud);
    mant = (unsigned int)div;
    frac = (unsigned int)((div - mant) * 16 + 0.5);
    mant += frac >> 4;
    frac &= 0xF;

    USART1->BRR = (mant << 4) | frac;
    USART1->CR1 = (0u << 15) | (0u << 12) | (0u << 10) | (1u << 3) | (1u << 2);
    USART1->CR2 = 0u << 12;
    USART1->CR3 = 0;
    USART1->CR1 |= (1u << 13);
}
```

설정 의도는 `PA9/PA10`을 USART1 alternate function으로 바꾸고, baud rate를 계산해 `BRR`에 넣은 뒤, TX/RX와 USART를 enable하는 것임.

### USART1 Local Echo-Back 실습

실습은 USART1 TX인 `PA9`와 RX인 `PA10`을 서로 연결한 뒤, TX로 보낸 문자가 다시 RX로 들어오는지 확인하는 구조다.

```text
PA9 USART1_TX  ----  PA10 USART1_RX
```

완성해야 하는 코드 흐름은 다음과 같다.

```c
void Main(void)
{
    char x;
    char y;

    Uart1_Init(115200);

    for (x = 'A'; x <= 'Z'; x++)
    {
        while (!Macro_Check_Bit_Set(USART1->SR, 7))
            ;
        USART1->DR = x;

        while (!Macro_Check_Bit_Set(USART1->SR, 5))
            ;
        y = USART1->DR;

        printf("%c ", y);
    }
}
```

| 단계 | 확인 flag | 동작 |
| :--- | :--- | :--- |
| 송신 가능 대기 | `TXE == 1` | `DR`에 송신 문자 write |
| 수신 완료 대기 | `RXNE == 1` | `DR`에서 수신 문자 read |
| 출력 확인 | `printf` | echo-back된 문자 표시 |

## Timer 제어

### SysTick Timer

`SysTick`은 Cortex-M core에 포함된 24bit down counter다. RTOS의 tick 생성에 자주 쓰이고, 간단한 지연 시간 측정이나 timeout 확인용 범용 timer로도 사용할 수 있음.

동작 구조는 다음처럼 보면 된다.

```text
LOAD 설정값
    |
    v
VAL down count: LOAD -> ... -> 1 -> 0
    |
    +-- COUNTFLAG set
    +-- TICKINT=1이면 SysTick exception 요청
    +-- 다음 주기에서 LOAD 값 reload
```

| Register | 역할 |
| :--- | :--- |
| `SysTick->LOAD` | reload 값 저장, 24bit |
| `SysTick->VAL` | 현재 counter 값, write 시 `0`으로 clear 및 `COUNTFLAG` clear |
| `SysTick->CTRL` | enable, interrupt, clock source, count flag 제어 |
| `SysTick->CALIB` | 제조사 calibration 값, read-only |

`SysTick->CTRL`의 핵심 bit는 다음과 같음.

| Bit | 이름 | 의미 |
| :--- | :--- | :--- |
| `0` | `ENABLE` | counter start |
| `1` | `TICKINT` | 0 도달 시 SysTick exception 허용 |
| `2` | `CLKSOURCE` | `0`: AHB/8, `1`: AHB |
| `16` | `COUNTFLAG` | counter가 0에 도달하면 set, 읽으면 clear |

실습 함수는 `HCLK/8`을 기준 clock으로 두고, interrupt 없이 polling 방식으로 timeout을 확인하는 구조다.

```c
void SysTick_Run(unsigned int msec);
int SysTick_Check_Timeout(void);
unsigned int SysTick_Get_Time(void);
unsigned int SysTick_Get_Load_Time(void);
```

시간 설정 흐름은 다음과 같음.

```text
HCLK = 96 MHz
SysTick clock = HCLK / 8 = 12 MHz
1 tick = 1 / 12 MHz = 83.33 ns

msec 단위 delay
LOAD = 12000 * msec - 1
```

초기화 순서는 `LOAD 설정 → VAL clear → CTRL 설정 → timeout polling` 순서로 잡는다.

```c
void SysTick_Run(unsigned int msec)
{
    SysTick->CTRL = 0;
    SysTick->LOAD = 12000 * msec - 1;
    SysTick->VAL = 0;
    SysTick->CTRL = (0u << 1) | (0u << 2) | (1u << 0);
}
```

### TIMx 기본 구조

STM32의 일반 timer는 `PSC`, `ARR`, `CNT`, `CR1`, `SR`, `DIER`, `EGR` 같은 register를 중심으로 동작한다.

기본 흐름은 다음과 같음.

```text
TIM_CLK
  |
  v
[PSC/PSC_BUF]  prescale
  |
  v
CK_CNT
  |
  v
[CNT]  down count 또는 up count
  |
  +-- CNT == 0 또는 CNT == ARR
        |
        +-- UIF flag set
        +-- UIE=1이면 interrupt request
        +-- repeat mode이면 reload 후 재시작
        +-- one-pulse mode이면 정지
```

| Register | 역할 |
| :--- | :--- |
| `TIMx->PSC` | prescaler 값 저장, `N` 설정 시 `N + 1` 분주 |
| `TIMx->ARR` | auto reload 값, counter의 목표값 |
| `TIMx->CNT` | 현재 counter 값 |
| `TIMx->CR1` | timer enable, 방향, one-pulse, auto-reload preload 제어 |
| `TIMx->SR` | 상태 flag, `UIF` timeout/update flag 포함 |
| `TIMx->DIER` | interrupt enable, `UIE` 포함 |
| `TIMx->EGR` | update event 강제 발생, `UG` bit 사용 |

`PSC`와 `ARR`은 double buffering 구조로 이해해야 한다. 소프트웨어가 `PSC`, `ARR`에 새 값을 쓰더라도 실제 counter에 즉시 반영되지 않을 수 있고, update event가 발생할 때 내부 buffer로 load됨.

```text
software write
    |
    v
PSC, ARR register
    |
    | update event
    v
PSC_BUF, CNT reload
```

### TIM2 Stopwatch와 Delay

`TIM2`는 경과 시간 측정과 delay 생성 예제로 사용한다. 실습에서는 timer tick을 `20us` 단위로 만들기 위해 timer 주파수를 `50kHz`로 맞춘다.

| 함수 | 동작 |
| :--- | :--- |
| `TIM2_Stopwatch_Start()` | down count, one-pulse mode로 시작 |
| `TIM2_Stopwatch_Stop()` | timer 정지 후 남은 count로 경과 시간 계산 |
| `TIM2_Delay(int time)` | 요청한 시간만큼 `ARR` 설정 후 `UIF` polling |

경과 시간 계산 개념은 다음과 같음.

```text
초기 count = 0xFFFF
현재 count = CNT
사용한 pulse = 0xFFFF - CNT
경과 시간 = 사용한 pulse * 20us
```

`TIM2_Delay()`는 interrupt를 실제로 사용하지 않고, timeout flag인 `UIF`를 polling한다.

```text
1. ARR 설정
2. EGR.UG로 update event 발생
3. SR.UIF clear
4. CR1.CEN set
5. SR.UIF가 1이 될 때까지 대기
6. timer stop
```

### TIM4 Repeat Timer

`TIM4`는 repeat mode로 주기적 timeout을 만드는 예제로 사용한다.

```text
TIM4_Repeat(time)
    |
    v
ARR 설정, repeat mode start
    |
    v
timeout마다 UIF set
    |
    v
TIM4_Check_Timeout()에서 flag 확인 및 clear
```

`TIM4_Change_Value()`처럼 동작 중에 `ARR` 값을 바꾸는 경우, 새 값은 update event 이후에 반영될 수 있다. 즉, timer가 이미 한 주기를 돌고 있는 중이면 현재 주기에는 이전 설정이 유지될 수 있음.

### Timer Channel과 Buzzer 출력

`TIM2`~`TIM5`는 timer 하나당 4개의 channel을 가진다. channel은 capture, compare, PWM 같은 기능으로 사용할 수 있다.

```text
TIMx counter
    |
    +-- compare with CCR1 -> CH1 output
    +-- compare with CCR2 -> CH2 output
    +-- compare with CCR3 -> CH3 output
    +-- compare with CCR4 -> CH4 output
```

| 구성 | 의미 |
| :--- | :--- |
| `CCR` | compare 기준값 |
| `CCR_BUF` | preload buffer |
| `CCMRx` | capture/compare mode 설정 |
| `CCER` | channel output enable, polarity 설정 |

PWM은 일정한 period 안에서 high 구간의 비율을 바꾸는 방식이다.

```text
period 고정

duty 25%:  ┌─┐___┌─┐___┌─┐___
duty 50%:  ┌──┐__┌──┐__┌──┐__
duty 75%:  ┌───┐_┌───┐_┌───┐_
```

실습에서는 `PB0`의 `TIM3_CH3`를 buzzer 구동에 사용한다. 음계별 frequency를 `PSC`, `ARR`, `CCR` 설정으로 만들고, duty는 보통 50%로 둔다.

| 음계 예시 | 주파수 |
| :--- | :--- |
| 낮은 도 | 약 `130Hz` |
| 도 | 약 `261Hz` |
| 레 | 약 `293Hz` |
| 높은 도 | 약 `523Hz` |
| 높은 시 | 약 `987Hz` |

## Interrupt 제어

### Exception Vector Table과 ISR

Cortex-M에서는 reset, fault, SysTick, 외부 interrupt를 모두 exception 체계로 다룬다. 0~15번 exception은 Cortex-M 공통 영역이고, 16번부터는 제조사와 MCU 제품별 peripheral interrupt가 배정된다.

```text
Vector Table

0   Initial SP
1   Reset_Handler
2   NMI_Handler
3   HardFault_Handler
...
15  SysTick_Handler
16+ MCU peripheral IRQ handlers
```

STM32F411xE는 여러 peripheral interrupt source를 가지고 있고, startup code에는 정해진 ISR 이름이 미리 선언되어 있다. 사용할 interrupt는 정해진 이름과 같은 C 함수를 작성하면 linker가 vector table entry와 그 함수를 연결한다. 이름이 다르면 ISR이 연결되지 않고 weak default handler로 빠질 수 있다.

예시는 다음과 같음.

| Source | ISR 이름 |
| :--- | :--- |
| `EXTI15_10` | `EXTI15_10_IRQHandler` |
| `USART2` | `USART2_IRQHandler` |
| `TIM4` | `TIM4_IRQHandler` |
| `SPI4` | `SPI4_IRQHandler` |
| `SPI5` | `SPI5_IRQHandler` |

### NVIC 역할

`NVIC`는 `Nested Vectored Interrupt Controller`로, Cortex-M core 외부 peripheral들의 interrupt 요청을 정리한다.

| 기능 | CMSIS 함수 |
| :--- | :--- |
| 전체 interrupt disable/enable | `__disable_irq()`, `__enable_irq()` |
| 특정 IRQ enable/disable | `NVIC_EnableIRQ()`, `NVIC_DisableIRQ()` |
| pending clear/check/set | `NVIC_ClearPendingIRQ()`, `NVIC_GetPendingIRQ()`, `NVIC_SetPendingIRQ()` |
| priority 설정/확인 | `NVIC_SetPriority()`, `NVIC_GetPriority()` |
| system reset | `NVIC_SystemReset()` |

interrupt 처리 흐름은 다음처럼 잡는다.

```text
Peripheral event
    |
    v
Peripheral pending flag set
    |
    v
NVIC pending
    |
    v
CPU jumps to ISR
    |
    v
ISR clears peripheral pending first
    |
    v
ISR clears NVIC pending if needed
    |
    v
return to main flow
```

interrupt가 발생하려면 peripheral 내부 enable bit, peripheral pending flag, NVIC enable, global interrupt enable 조건이 모두 맞아야 한다. ISR 안에서는 원인이 된 peripheral flag를 먼저 확인하고 clear해야 같은 interrupt가 계속 재진입하는 상황을 막을 수 있다. Priority는 동시에 여러 interrupt가 pending 되었을 때 어떤 ISR을 먼저 실행할지와, 실행 중인 ISR을 더 높은 priority interrupt가 선점할 수 있는지를 결정한다.

### EXTI와 KEY Interrupt

GPIO pin은 pin 번호 기준으로 `EXTI0`~`EXTI15` line에 연결된다. 예를 들어 `PC13`은 `EXTI13` line을 사용하고, IRQ는 `EXTI15_10` 그룹에 속함.

```text
PC13 button
  |
  v
SYSCFG EXTICR: EXTI13 source = Port C
  |
  v
EXTI13 line
  |
  v
EXTI15_10 IRQ
  |
  v
EXTI15_10_IRQHandler()
```

`SYSCFG_EXTICR`는 EXTI line이 어느 GPIO port에서 오는지 선택한다. port code는 다음과 같이 사용함.

| Port | Code |
| :--- | :--- |
| `GPIOA` | `0000` |
| `GPIOB` | `0001` |
| `GPIOC` | `0010` |
| `GPIOD` | `0011` |
| `GPIOE` | `0100` |
| `GPIOH` | `0111` |

EXTI 주요 register는 다음과 같음.

| Register | 역할 |
| :--- | :--- |
| `EXTI->IMR` | interrupt mask, `1`이면 unmask |
| `EXTI->EMR` | event mask |
| `EXTI->RTSR` | rising edge trigger enable |
| `EXTI->FTSR` | falling edge trigger enable |
| `EXTI->SWIER` | software interrupt/event request |
| `EXTI->PR` | pending register, `1` write로 clear |

`PC13` button interrupt enable 흐름은 다음과 같다.

```text
1. GPIOC clock enable
2. PC13 input mode 설정
3. SYSCFG clock enable
4. EXTICR에서 EXTI13 source를 GPIOC로 선택
5. falling edge trigger 설정
6. EXTI13 pending clear
7. NVIC pending clear
8. EXTI13 unmask
9. NVIC IRQ40 enable
```

ISR에서는 peripheral pending을 먼저 지우는 것이 핵심임.

```c
void EXTI15_10_IRQHandler(void)
{
    printf("KEY Pressed\n");
    EXTI->PR = 1u << 13;
    NVIC_ClearPendingIRQ((IRQn_Type)40);
}
```

### Interrupt Based와 Event Driven

interrupt 처리 방식은 크게 두 가지로 나눌 수 있다.

| 방식 | 설명 | 장점 | 주의점 |
| :--- | :--- | :--- | :--- |
| Interrupt Based | ISR 내부에서 실제 service 수행 | 구조 단순 | ISR이 길어지면 다른 처리 지연 |
| Event Driven | ISR은 flag만 set, main loop가 처리 | ISR 짧게 유지 | 공유 flag는 `volatile` 필요 |

event-driven 방식은 다음처럼 구성한다.

```c
volatile int Key_Pressed = 0;

void EXTI15_10_IRQHandler(void)
{
    Key_Pressed = 1;
    EXTI->PR = 1u << 13;
    NVIC_ClearPendingIRQ((IRQn_Type)40);
}

void Main(void)
{
    for (;;)
    {
        if (Key_Pressed)
        {
            Key_Pressed = 0;
            printf("KEY event\n");
        }
    }
}
```

ISR과 main loop가 같은 변수를 공유하므로 `volatile`을 사용해야 한다. 그렇지 않으면 compiler가 main loop에서 값이 변하지 않는다고 판단해 잘못 최적화할 수 있음.

### USART2와 TIM4 Interrupt

USART2 interrupt에서는 `RXNEIE`나 `TXEIE`를 켜고, ISR에서 `SR` flag를 확인해 처리한다.

| Register | Bit | 의미 |
| :--- | :--- | :--- |
| `USARTx->CR1` | `RXNEIE` | receive data ready interrupt enable |
| `USARTx->CR1` | `TXEIE` | transmit data register empty interrupt enable |
| `USARTx->SR` | `RXNE` | receive data register not empty |
| `USARTx->SR` | `TXE` | transmit data register empty |

```c
volatile int Uart_Data_In = 0;
volatile int Uart_Data = 0;

void USART2_IRQHandler(void)
{
    if (Macro_Check_Bit_Set(USART2->SR, 5))
    {
        Uart_Data = USART2->DR;
        Uart_Data_In = 1;
    }
}
```

TIM4 interrupt에서는 `DIER.UIE`를 켜고, `SR.UIF`를 확인한 뒤 clear한다.

```c
volatile int TIM4_Expired = 0;

void TIM4_IRQHandler(void)
{
    if (Macro_Check_Bit_Set(TIM4->SR, 0))
    {
        Macro_Clear_Bit(TIM4->SR, 0);
        TIM4_Expired = 1;
    }
}
```

## I2C BUS Interface

### Open-Drain Bus 구조

I2C를 이해하려면 open-drain 출력부터 봐야 한다. push-pull 출력은 high와 low를 모두 능동적으로 구동하지만, open-drain은 low만 직접 구동하고 high는 외부 pull-up resistor가 만든다.

```text
Open-drain line

 VDD
  |
 [Rpull-up]
  |
  +--------- SDA/SCL bus
  |
 [N-MOS]
  |
 GND

output 0 -> N-MOS ON  -> bus low
output 1 -> N-MOS OFF -> pull-up으로 bus high
```

여러 장치가 같은 선을 공유할 때 push-pull을 사용하면 한 장치는 high, 다른 장치는 low를 구동하는 순간 단락이 생길 수 있다. open-drain은 누군가 low를 당기면 전체 bus가 low가 되고, 아무도 당기지 않을 때만 high가 되므로 wired-AND 구조를 만들 수 있음.

```text
device A pulls low  -> bus low
device B pulls low  -> bus low
all released        -> pull-up high
```

### I2C 기본 신호와 frame

I2C는 `Inter-IC Bus`로, `I2C`, `IIC`라고도 부른다. 기본 신호는 두 개다.

| Signal | 역할 |
| :--- | :--- |
| `SCL` | serial clock, master가 생성 |
| `SDA` | serial data, half-duplex 양방향 data |

I2C line은 open-drain/open-collector 구조와 pull-up resistor를 사용한다.

Start/Stop 조건은 `SCL`이 high인 동안 `SDA`가 변하는 것으로 표현한다.

```text
Start condition

SCL: ─────────────
SDA: ───────┐_____
            falling while SCL high

Stop condition

SCL: ─────────────
SDA: _____┌───────
          rising while SCL high
```

일반 data bit는 `SCL`이 high인 동안 안정되어야 하고, `SDA` 변화는 `SCL` low 구간에서 일어나는 것이 기본 규칙임.

```text
SCL: ___/‾‾‾\\___/‾‾‾\\___/‾‾‾\\___
SDA: == stable == change == stable ==
```

7bit slave address frame은 다음과 같음.

```text
S | A6 A5 A4 A3 A2 A1 A0 | R/W | ACK | DATA[7:0] | ACK | P
```

| Field | 의미 |
| :--- | :--- |
| `S` | start |
| `A6:0` | 7bit slave address |
| `R/W` | `0`: write, `1`: read |
| `ACK` | receiver가 SDA low로 응답 |
| `P` | stop |

register address가 있는 slave는 보통 write phase로 register address를 먼저 보낸 뒤, read phase로 데이터를 읽는다.

```text
Write register
S -> slave address + W -> ACK -> register address -> ACK -> data -> ACK -> P

Read register
S -> slave address + W -> ACK -> register address -> ACK
Sr -> slave address + R -> ACK -> data <- NACK -> P
```

### SC16IS752 I2C GPIO 실습

실습 slave는 `SC16IS752`로, I2C/SPI 방식의 2-channel UART와 8bit GPIO를 제공하는 device다. I2C mode에서는 `ITF_MODE=1`로 두고, `SCL`, `SDA`, `A0`, `A1`을 사용한다.

| 연결 | STM32F411 쪽 |
| :--- | :--- |
| `SCL` | `PB6`, `I2C1_SCL` |
| `SDA` | `PB7`, `I2C1_SDA` |
| `A0`, `A1` | `GND` |
| `ITF_MODE` | `3.3V` |
| `VDD_3V3`, `GND` | 전원, ground |

GPIO 출력은 active-low LED와 연결되어 있으므로, 특정 LED 하나를 켜려면 해당 bit만 `0`으로 만들고 나머지를 `1`로 둔다.

```text
GP0~GP7 active-low LED

IOSTATE = 1111_1110 -> GP0 LED ON
IOSTATE = 1111_1101 -> GP1 LED ON
IOSTATE = 0111_1111 -> GP7 LED ON
```

SC16IS752 GPIO 관련 register는 다음과 같음.

| Register | Address | 의미 |
| :--- | :--- | :--- |
| `IODIR` | `0x0A` | GPIO direction, `1`: output |
| `IOSTATE` | `0x0B` | GPIO output write 또는 input state read |

### STM32 I2C1 설정

`PB6`, `PB7`은 alternate function `AF4`로 설정하고, open-drain, high speed, pull-up 구성을 사용한다.

```text
PB6/PB7 GPIO 설정
  MODER  = alternate function
  OTYPER = open-drain
  OSPEEDR = high speed
  PUPDR  = pull-up
  AFR    = AF4
```

I2C1 register 설정 흐름은 다음과 같다.

| Register | 설정 |
| :--- | :--- |
| `I2C1->CR1` | `PE`, `START`, `STOP`, `ACK` 제어 |
| `I2C1->CR2` | peripheral clock frequency 입력, `PCLK1=48MHz`이면 `48` |
| `I2C1->CCR` | SCL speed 설정, standard/fast mode 분주 |
| `I2C1->TRISE` | rise time 설정 |
| `I2C1->SR1` | `SB`, `ADDR`, `BTF`, `TxE`, `RxNE`, error flag |
| `I2C1->SR2` | `BUSY`, `MSL`, `TRA` 등 bus 상태 |
| `I2C1->DR` | 8bit data register |

write register sequence는 다음처럼 진행된다.

```text
1. SR2.BUSY clear 대기
2. CR1.START set
3. SR1.SB set 대기
4. DR = slave address + W
5. SR1.ADDR set 대기, SR2 read로 clear
6. DR = register address
7. BTF 또는 TxE 대기
8. DR = data
9. BTF 대기
10. CR1.STOP set
```

LED 이동 실습은 다음 흐름으로 구성할 수 있음.

```c
#define SC16IS752_IODIR   0x0A
#define SC16IS752_IOSTATE 0x0B

void I2C1_SC16IS752_Config_GPIO(unsigned int config)
{
    I2C1_SC16IS752_Write_Reg(SC16IS752_IODIR, config);
}

void I2C1_SC16IS752_Write_GPIO(unsigned int data)
{
    I2C1_SC16IS752_Write_Reg(SC16IS752_IOSTATE, data);
}

void Main(void)
{
    int i;

    I2C1_SC16IS752_Init(400000);
    I2C1_SC16IS752_Config_GPIO(0xFF);

    for (;;)
    {
        for (i = 0; i < 8; i++)
        {
            I2C1_SC16IS752_Write_GPIO(~(1u << i));
            TIM2_Delay(100);
        }
    }
}
```

## SPI BUS Interface

### SPI 기본 구조

SPI는 Motorola에서 제안한 동기식 serial bus다. I2C와 달리 clock 선과 data 방향을 분리해 full-duplex 전송을 할 수 있음.

| Signal | 의미 |
| :--- | :--- |
| `SCK`, `SCLK` | serial clock, master가 생성 |
| `MOSI` | Master Out Slave In |
| `MISO` | Master In Slave Out |
| `CS`, `SS`, `NSS` | slave select |

full-duplex shift 동작은 다음처럼 동시에 일어난다.

```text
Master shift register  --MOSI-->  Slave shift register
Master shift register  <--MISO--  Slave shift register
             ^                     ^
             |                     |
             +------ shared SCK ---+
```

SPI mode는 `CPOL`, `CPHA` 조합으로 정한다. master와 slave가 같은 mode를 사용해야 함.

| Mode | `CPOL` | `CPHA` | 의미 |
| :--- | :-: | :-: | :--- |
| 0 | `0` | `0` | clock idle low, 첫 edge sample |
| 1 | `0` | `1` | clock idle low, 둘째 edge sample |
| 2 | `1` | `0` | clock idle high, 첫 edge sample |
| 3 | `1` | `1` | clock idle high, 둘째 edge sample |

### SC16IS752 SPI 연결

같은 `SC16IS752`를 SPI mode로 사용할 때는 `ITF_MODE=0`으로 두고, `SCK`, `MISO`, `MOSI`, `CS`를 연결한다.

| 연결 | STM32F411 쪽 |
| :--- | :--- |
| `SPI_SCLK` | `PB3`, `SPI1_SCK` |
| `SPI_MISO` | `PB4`, `SPI1_MISO` |
| `SPI_MOSI` | `PB5`, `SPI1_MOSI` |
| `SPI_CS` | `PA8`, GPIO output |
| `ITF_MODE` | `GND` |
| `VDD_3V3`, `GND` | 전원, ground |

`CS`는 reset 직후 의도치 않게 low가 되면 slave가 선택될 수 있으므로 pull-up으로 high를 유지하는 구성이 필요하다.

### STM32 SPI1 설정

`PB3`, `PB4`, `PB5`는 alternate function `AF5`로 설정한다. `PA8`은 일반 GPIO output으로 사용하여 `CS`를 직접 제어함.

```text
PB3/PB4/PB5
  MODER = alternate function
  AFR   = AF5

PA8
  MODER = output
  ODR   = 1로 초기화하여 CS high
```

SPI1 주요 register는 다음과 같다.

| Register | Field | 의미 |
| :--- | :--- | :--- |
| `SPI1->CR1` | `MSTR` | master mode |
| `SPI1->CR1` | `BR[2:0]` | baud rate prescaler |
| `SPI1->CR1` | `CPOL`, `CPHA` | SPI mode |
| `SPI1->CR1` | `DFF` | `0`: 8bit, `1`: 16bit |
| `SPI1->CR1` | `SPE` | SPI enable |
| `SPI1->SR` | `TXE` | transmit buffer empty |
| `SPI1->SR` | `RXNE` | receive buffer not empty |
| `SPI1->SR` | `BSY` | SPI busy |
| `SPI1->DR` | data register | 송수신 data |

`BR[2:0]`의 prescaler는 다음처럼 잡는다.

| `BR` | 분주 |
| :--- | :--- |
| `000` | `/2` |
| `001` | `/4` |
| `010` | `/8` |
| `011` | `/16` |
| `100` | `/32` |
| `101` | `/64` |
| `110` | `/128` |
| `111` | `/256` |

SC16IS752가 지원하는 SPI clock 한계를 넘지 않도록 `PCLK2`와 prescaler를 함께 봐야 한다.

### SPI write sequence

SC16IS752 register write는 `CS low → command/data shift → busy clear 대기 → CS high` 순서로 처리한다.

```c
#define SPI1_CS_HIGH() Macro_Set_Bit(GPIOA->ODR, 8)
#define SPI1_CS_LOW()  Macro_Clear_Bit(GPIOA->ODR, 8)

void SPI1_SC16IS752_Write_Reg(unsigned int addr, unsigned int data)
{
    SPI1_CS_HIGH();
    SPI1_CS_LOW();

    SPI1->DR = (0u << 15) | ((addr & 0xF) << 11) | (data & 0xFF);

    while (Macro_Check_Bit_Clear(SPI1->SR, 1))
        ;
    while (Macro_Check_Bit_Set(SPI1->SR, 7))
        ;

    SPI1_CS_HIGH();
}
```

I2C 실습과 마찬가지로 `IODIR`을 output으로 설정하고 `IOSTATE`에 active-low data를 써서 LED를 이동시킬 수 있음.

```text
SPI frame

CS  : __\\____________________/__
SCK : ___/‾\\_/‾\\_/‾\\_/‾\\_____
MOSI:  command/address/data bits
MISO:  slave response bits
```

## ADC와 센서 인터페이스 회로

### ADC 개념

`ADC`는 `Analog-to-Digital Converter`로, 연속적인 analog voltage를 digital value로 변환한다. MCU는 sensor 출력 전압을 직접 의미 있는 물리량으로 이해하지 못하므로, ADC를 통해 정수값으로 변환한 뒤 software에서 해석함.

```text
Sensor voltage
    |
    v
ADC input pin
    |
    v
sample and hold
    |
    v
ADC conversion
    |
    v
digital value in ADC_DR
```

STM32F411 ADC는 12/10/8/6bit resolution을 선택할 수 있고, channel별 sampling time을 설정할 수 있다. 입력 전압 범위는 기준 전압 사이여야 함.

| 항목 | 내용 |
| :--- | :--- |
| Resolution | 12bit, 10bit, 8bit, 6bit 선택 |
| Input range | `VREF- <= VIN <= VREF+` |
| Channel | 여러 analog input을 하나의 ADC가 순차 변환 |
| Sampling time | channel별 sampling cycle 설정 |

12bit ADC에서는 변환 결과가 `0`~`4095` 범위다.

```text
ADC code = VIN / VREF * 4095

VIN = 0V      -> 0
VIN = VREF/2  -> 약 2048
VIN = VREF    -> 4095
```

### 가변저항 입력 회로

실습에서는 가변저항을 전압 분배기로 사용하여 `PA6`, `ADC1_IN6`에 analog voltage를 넣는다.

```text
3.3V
  |
 [R1]
  |
  +---- Vout ---- PA6 / ADC1_IN6
  |
 [R2]
  |
 GND

Vout = 3.3V * R2 / (R1 + R2)
```

가변저항 knob를 돌리면 `R1:R2` 비율이 변하고, 이에 따라 `Vout`과 ADC 변환값이 함께 변한다.

### PA6 Analog Input 설정

GPIO pin을 ADC input으로 쓰려면 해당 pin을 analog mode로 설정한다. `PA6`은 `MODER[13:12] = 11`로 설정함.

```text
GPIOA MODER for PA6

bit13 bit12
  0     0    input
  0     1    output
  1     0    alternate function
  1     1    analog
```

Analog mode에서는 digital input buffer를 우회하거나 비활성화하여 analog 신호를 ADC로 전달하는 구조로 이해하면 된다.

### ADC1_IN6 Driver 함수

ADC1 channel 6 초기화 흐름은 다음과 같다.

```text
1. GPIOA clock enable
2. PA6 analog mode 설정
3. ADC1 clock enable
4. CH6 sampling time 설정
5. conversion sequence 길이 1로 설정
6. sequence 첫 channel을 CH6으로 설정
7. ADC common clock 설정
8. ADC1 enable
```

핵심 register 설정은 다음과 같음.

| Register | 설정 |
| :--- | :--- |
| `GPIOA->MODER` | `PA6` analog mode |
| `ADC->SMPR2` | channel 6 sampling time, 예: `480 cycles` |
| `ADC->SQR1` | conversion sequence length |
| `ADC1->SQR3` | first conversion channel = 6 |
| `ADC->CCR` | ADC clock prescaler |
| `ADC1->CR2` | `ADON`, `SWSTART` |
| `ADC1->SR` | `EOC`, overrun 등 상태 |
| `ADC1->DR` | conversion result |

```c
void ADC1_IN6_Init(void)
{
    Macro_Set_Bit(RCC->AHB1ENR, 0);
    Macro_Write_Block(GPIOA->MODER, 0x3, 0x3, 12);

    Macro_Set_Bit(RCC->APB2ENR, 8);
    Macro_Write_Block(ADC->SMPR2, 0x7, 0x7, 18);
    Macro_Write_Block(ADC->SQR1, 0xF, 0x0, 20);
    Macro_Write_Block(ADC1->SQR3, 0x1F, 6, 0);
    Macro_Write_Block(ADC->CCR, 0x3, 0x2, 16);

    Macro_Set_Bit(ADC1->CR2, 0);
}

void ADC1_Start(void)
{
    Macro_Set_Bit(ADC1->CR2, 30);
}

int ADC1_Get_Status(void)
{
    int r = Macro_Check_Bit_Set(ADC1->SR, 1);

    if (r)
    {
        Macro_Clear_Bit(ADC1->SR, 1);
        Macro_Clear_Bit(ADC1->SR, 4);
    }

    return r;
}

int ADC1_Get_Data(void)
{
    return Macro_Extract_Area(ADC1->DR, 0xFFF, 0);
}
```

test code는 conversion을 시작하고 `EOC` 상태를 기다린 뒤 `DR`의 하위 12bit 값을 출력한다.

```c
void Main(void)
{
    ADC1_IN6_Init();

    for (;;)
    {
        ADC1_Start();

        while (!ADC1_Get_Status())
            ;

        printf("0x%.4x\n", ADC1_Get_Data());
    }
}
```

가변저항을 돌리면 출력값이 `0x0000` 근처에서 `0x0fff` 근처까지 변한다. 실제 최솟값과 최댓값은 보드 전원, 회로 오차, 가변저항 상태에 따라 약간 달라질 수 있음.

## 정리

이번 범위의 핵심은 MCU 제어 코드가 단순히 C 문법만으로 동작하는 것이 아니라, 회로와 주소 기반 레지스터 제어를 전제로 한다는 점이다.

```text
전자 소자와 논리 회로
    ↓
IC, ASIC, SoC
    ↓
CPU, 메모리, 주변장치
    ↓
MCU와 memory map
    ↓
Memory-Mapped I/O
    ↓
GPIO 레지스터 직접 제어
    ↓
Timer, Interrupt, I2C, SPI, ADC peripheral 제어
```

GPIO 제어에서는 pin 번호, 레지스터 base address, offset, bit 위치, 회로의 active-high/active-low 조건을 함께 봐야 한다. 같은 LED 제어라도 회로가 active-high인지 active-low인지에 따라 `ODR`에 써야 하는 값과 output type 선택이 달라짐.

뒤쪽 peripheral도 같은 방식으로 이어진다. 먼저 clock을 켜고, pin mode나 alternate function을 맞춘 뒤, peripheral register를 설정하고, status flag와 data register를 읽고 쓰면서 동작을 확인한다.

```text
clock enable
    ↓
GPIO pin mode 또는 alternate function 설정
    ↓
peripheral register 설정
    ↓
status flag 확인
    ↓
data register read/write
    ↓
pending flag clear 또는 다음 transaction 진행
```

`Timer`는 시간 기준을 만들고, `Interrupt`는 event를 main flow로 전달하며, `I2C`/`SPI`는 외부 IC와 통신하고, `ADC`는 analog sensor 값을 digital value로 바꾼다. 결국 모든 실습은 `base address + register offset + bit field + 회로 연결`을 함께 읽는 훈련으로 연결됨.
