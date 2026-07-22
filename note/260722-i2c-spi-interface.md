# 26-07-22 - 13과 I2C·14과 SPI Interface

관련 노트:

- [26-07-21 - Startup·Interrupt·Event-Driven Firmware](260721-interrupt-event-driven.md)
- [13과 I2C `main.c`](../helloEmbedded/1301.I2C_IF_EX/main.c) · [I2C driver](../helloEmbedded/1301.I2C_IF_EX/i2c.c)
- [14과 SPI `main.c`](../helloEmbedded/1401.SPI_IF_EX/main.c) · [SPI driver](../helloEmbedded/1401.SPI_IF_EX/spi.c)

## 수업 범위

| 과 | 주제 |
| :--- | :--- |
| 13과 | I2C BUS Interface |
| 14과 | SPI BUS Interface |

## 실습 code 연결

두 실습은 STM32F411의 peripheral register를 설정한 뒤, 동일한 `SC16IS752`의 GPIO register를 제어해 active-low LED를 이동시킨다. 차이는 STM32와 외부 IC 사이의 wire protocol이다. `1301`은 I2C1의 shared two-wire bus를, `1401`은 SPI1의 clock·MOSI·MISO와 GPIO `CS`를 사용한다.

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

I2C의 `SCL`, `SDA`는 open-drain shared bus다. 어느 장치도 high를 직접 밀어 올리지 않고, 모두가 pin을 release했을 때 pull-up resistor가 high를 만든다. 장치 하나라도 low를 만들면 bus는 low가 된다. 이 성질 덕분에 여러 장치가 같은 두 선을 공유할 수 있고, 동시에 다른 값을 내보냈을 때 low를 쓴 장치가 bus 상태를 확인해 arbitration에 사용할 수 있다.

```text
모든 장치 release  -> pull-up이 SDA/SCL = high
어느 한 장치 low   -> shared wire = low
```

I2C는 SCL이 high인 동안 SDA를 안정적으로 유지한다. SCL high 구간에서 SDA가 high→low로 바뀌면 START, low→high로 바뀌면 STOP이다. data bit는 보통 SCL low에서 준비하고 SCL high에서 sample한다.

I2C는 `Inter-IC Bus`로, Philips 반도체(현 NXP)가 IC 소자 사이 통신을 위해 개발한 규격이며 `I2C`, `IIC`라고도 부른다. 두 선만으로 여러 IC를 연결할 수 있어 오디오·비디오·설정용 소자와 프로세서 사이 통신에 널리 쓰인다. 기본 신호는 두 개다.

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

I2C data는 byte 단위 MSB first로 전송된다(UART의 LSB first와 반대). slave address `0x00`은 모든 slave에게 보내는 general call(broadcast) 주소로 예약되어 있다.

register address가 있는 slave는 보통 write phase로 register address를 먼저 보낸 뒤, read phase로 데이터를 읽는다.

```text
Write register
S -> slave address + W -> ACK -> register address -> ACK -> data -> ACK -> P

Read register
S -> slave address + W -> ACK -> register address -> ACK
Sr -> slave address + R -> ACK -> data <- NACK -> P
```

#### STM32 I2C peripheral을 state machine으로 읽기

I2C1은 `DR`에 byte 하나를 쓰는 순간 전체 transaction을 자동으로 끝내는 단순 register가 아니다. START·address·data·STOP의 각 단계가 hardware status flag로 보이고, software는 다음 단계가 준비됐을 때만 다음 control 또는 data를 write한다. polling code의 `while`은 이 state machine을 순서대로 진행시키는 대기다.

```text
bus idle
  -> CR1.START set       -> SR1.SB set
  -> DR에 address+R/W    -> SR1.ADDR set
  -> SR1 읽기 후 SR2 읽기 -> ADDR clear, address phase 종료
  -> DR에 data write     -> TXE/BTF set
  -> CR1.STOP set        -> bus idle
```

| 상태 또는 오류 | 뜻 | driver가 확인할 일 |
| :--- | :--- | :--- |
| `SB` | START 생성 완료 | address byte write 진행 |
| `ADDR` | target가 address를 ACK | 문서가 정한 `SR1`→`SR2` read sequence로 address phase 종료 |
| `TXE` | CPU가 보는 `DR`가 비어 다음 byte를 받을 수 있는 상태 | 다음 byte write 가능. 직전 byte의 wire 전송 완료와는 구분 |
| `BTF` | `DR`와 내부 shift register가 모두 비어 byte 전송 경계가 끝난 상태 | 마지막 byte 뒤 `STOP` 또는 repeated `START` 판단 |
| `RXNE` | 수신 data register에 byte 존재 | `DR` read |
| `AF` | ACK failure, 보통 target NACK | address·mode·전원·배선 확인 후 flag 처리 |
| `BERR`, `ARLO`, `OVR` | bus error, arbitration lost, overrun | transaction 중단·flag clear·bus recovery 또는 재시도 |

flag 이름만 보고 임의로 read/write 순서를 바꾸면 `ADDR`, `STOP`, 마지막 ACK 처리에서 bus가 멈출 수 있다. 실제 flag clear sequence는 `RM0383` §18.3~§18.6의 해당 register 설명을 그대로 따르며, 이 실습의 단일 target polling code를 여러 byte read나 interrupt/DMA 방식으로 확장할 때도 같은 순서를 기준으로 삼음.

#### `TXE`와 `BTF`가 가리키는 전송 경계

`I2C1->DR`는 CPU가 read/write하는 8bit staging register다. peripheral 안에는 SDA로 bit를 하나씩 내보내는 별도의 shift register가 있으며, 이 register는 code에서 직접 보이지 않는다. CPU가 `DR`에 byte를 쓰면 hardware가 이를 shift register로 넘겨 전송한다.

`TXE = 1`은 `DR`가 비어서 다음 byte를 받을 수 있다는 뜻이다. 이때 shift register는 직전 byte를 아직 SCL에 맞춰 전송하거나 target의 ACK를 기다릴 수 있다. 반면 `BTF = 1`은 `DR`와 shift register가 모두 비어 전송 byte의 완료 경계까지 도달했다는 뜻이다. 따라서 여러 byte를 연속으로 보낼 때는 `TXE`마다 다음 byte를 `DR`에 공급할 수 있고, 마지막 byte 뒤에는 `BTF`를 확인한 뒤 `STOP` 또는 repeated `START`를 요청한다.

현재 [`I2C1_SC16IS752_Write_Reg()`](../helloEmbedded/1301.I2C_IF_EX/i2c.c)는 pipeline을 최대한 채우기보다 상태를 눈으로 따라가기 쉬운 polling 순서를 사용한다. register address는 `TXE` 뒤 `DR`에 쓰고, `BTF`로 그 byte의 전송 경계를 확인한 뒤 write data를 보낸다. 마지막 data의 `BTF` 뒤에만 `CR1.STOP`을 set한다. 이 순서에서 `TXE`는 다음 `DR` write 허가, `BTF`는 transaction을 닫아도 되는 완료 경계로 읽는다.

#### polling 대기의 실습 범위와 확장 방향

현재 source의 `while` 대기는 성공 flag만 기다리며 timeout 또는 error exit를 두지 않는다. target가 address를 NACK하거나 bus error·arbitration lost가 발생하면 기대한 `SB`·`ADDR`·`TXE`·`BTF`가 오지 않아 main이 해당 loop에 계속 머무를 수 있다. 실제 driver는 각 대기에 timeout을 두고 `AF`, `BERR`, `ARLO`, `OVR`, `TIMEOUT`을 함께 확인해 실패를 호출자에게 반환한다. 이 error path와 bus recovery는 현재 GPIO write 실습 source에 구현된 동작이 아니라 다음 driver 확장 범위다.

#### I2C polling을 event interrupt state machine으로 확장하기

현재 13과 source는 `SR1`·`SR2`를 `while`로 읽는 polling 방식이다. 같은 I2C state machine을 interrupt 방식으로 옮기면, main은 transaction 요청과 완료 상태만 관리하고 peripheral flag 변화는 ISR이 다음 단계로 이어 간다. STM32F411은 I2C1 event와 error에 각각 `I2C1_EV_IRQn`, `I2C1_ER_IRQn`을 사용하므로, 여러 I2C flag가 하나의 event handler로 들어온 뒤 `SR1`을 읽어 현재 단계를 판별한다.

| `I2C1->CR2` gate | interrupt 대상 | ISR에서 하는 일 |
| :--- | :--- | :--- |
| `ITEVTEN` | `SB`, `ADDR`, `ADD10`, `STOPF`, `BTF` 같은 protocol event | address write, `ADDR` clear, final `STOP` 판단 |
| `ITBUFEN` | `TXE`, `RXNE` buffer event. `ITEVTEN`도 함께 enable한 경우 | 다음 transmit byte write 또는 receive `DR` read |
| `ITERREN` | `BERR`, `ARLO`, `AF`, `OVR`, `TIMEOUT` 등 error event | error 기록, transaction 종료·recovery 판단 |

interrupt가 들어왔다는 사실만으로 다음 동작을 정하지 않는다. event ISR은 `SR1` flag를 우선순위에 맞춰 확인해 `SB → address`, `ADDR → SR1/SR2 read`, `TXE → 다음 byte`, `BTF → STOP/repeated START`처럼 상태를 전진시킨다. 모든 event를 interrupt로 처리하면 `BTF`만 기다리는 방식으로는 부족하고, 시작·address·buffer·오류 event를 모두 처리해야 한다. 이 구조는 [`260721 interrupt note`](260721-interrupt-event-driven.md)의 'ISR이 event를 기록하고 main이 완료 상태를 소비하는' 흐름을 I2C peripheral에 적용한 형태다. 현재 13과 source에는 이 IRQ enable·NVIC·handler가 구현되어 있지 않다.

#### I2C가 느려도 여러 장치를 두 선에 붙일 수 있는 이유

I2C의 high는 pull-up resistor가 선을 천천히 충전해 만드는 level이므로, speed는 resistor 값·bus capacitance·배선 길이의 영향을 받는다. 반대로 low는 device가 transistor로 직접 GND에 연결해 만든다. 이 전기적 구조가 clock stretching과 arbitration을 가능하게 함.

| 상황 | bus에서 보이는 결과 | master가 해야 할 일 |
| :--- | :--- | :--- |
| slave가 SCL을 low로 유지 | clock stretching | SCL high를 요청했어도 실제 high가 될 때까지 기다림 |
| 두 master가 서로 다른 SDA bit를 전송 | `0`을 낸 쪽이 low를 유지 | `1`을 냈는데 low를 읽은 master가 arbitration 양보 |
| slave address가 맞지 않음 | 9번째 clock에서 ACK 없음 | NACK 처리 후 STOP 또는 재시도 |

따라서 I2C driver의 `while`은 단순한 지연이 아니라 `SB`, `ADDR`, `TXE`, `BTF`, `RXNE` 같은 protocol state가 실제로 바뀌었는지 기다리는 단계다. 각 flag의 clear sequence는 STM32 I2C peripheral의 규칙을 따라야 하며, ACK·STOP을 너무 이르게 바꾸면 마지막 byte가 누락될 수 있음.

### SC16IS752 I2C GPIO 실습

실습 slave는 `SC16IS752`로, I2C/SPI 방식의 2-channel UART와 8bit GPIO를 제공하는 device다. I2C mode에서는 `ITF_MODE=1`로 두고, `SCL`, `SDA`, `A0`, `A1`을 사용한다.

| 연결 | STM32F411 쪽 |
| :--- | :--- |
| `SCL` | `PB6`, `I2C1_SCL` |
| `SDA` | `PB7`, `I2C1_SDA` |
| `A0`, `A1` | `GND`, SC16IS752 I2C address strap |
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

wire로 보내는 register address byte는 고유 주소 4bit를 그대로 쓰지 않는다. 고유 주소 `A[3:0]`을 bit `6:3`에 놓고, bit `2:1`은 UART 사용 시 channel 번호(GPIO 제어에서는 무의미)로 쓰는 구성이라, driver code는 `addr << 3` 형태로 address byte를 만든다. 예를 들어 `IODIR`의 고유 주소 `0x0A`는 address byte `0x50`으로 전송된다.

`A0`, `A1`은 같은 I2C bus에 여러 SC16IS752를 달 때 slave address를 구분하는 hardware address pin이다. 현재 확장 board는 두 pin을 `GND`에 연결한다. 수업 source는 이 board의 device 7bit address를 `0x4D`로 사용한다. wire에는 이 값을 왼쪽으로 한 bit 옮기고 bit `0`에 `R/W`를 넣어 write `0x9A`, read `0x9B`를 전송한다.

```text
7bit address: A6 A5 A4 A3 A2 A1 A0
address byte: A6 A5 A4 A3 A2 A1 A0 R/W

write: (address7 << 1) | 0
read : (address7 << 1) | 1
```

이 구분을 놓치면 address 표의 7bit 값과 code에서 `DR`에 쓰는 8bit address byte를 서로 다른 device address라고 잘못 이해하기 쉽다.

### 현재 실습 code 기준 확인

[13과 `i2c.c`](../helloEmbedded/1301.I2C_IF_EX/i2c.c)는 `SC16IS752_I2CADDR = 0x9A`를 두고 write byte `0x9A`를 `I2C1->DR`에 쓴다. `SC16IS752_I2CADDR_RD`는 bit `0`을 set한 `0x9B`다. 두 값의 상위 7bit는 모두 `0x4D`이므로, write와 read가 서로 다른 device address라는 뜻이 아니다.

현재 `Main()`은 `I2C1_SC16IS752_Init(400000)`을 호출한다. 이 값은 `CR2.FREQ`에 들어가지 않고, `CCR = PCLK1 / (2 × freq)` 계산에만 쓰인다. 따라서 `PCLK1 = 48 MHz`에서는 `CR2.FREQ = 48`, `CCR = 60`, `TRISE = 49`가 된다.

#### `I2C1_SC16IS752_Init(400000)`이 배선이 맞아도 실패할 수 있는 이유

`i2c.c`의 `freq` parameter는 `CCR = PCLK1 / (2 × freq)` 계산에만 들어간다. `I2C1->CCR = 60`은 register 전체를 write하므로 `F/S` bit와 `DUTY` bit도 모두 `0`이 된다. [`RM0383 §18.6.8`](https://www.st.com/resource/en/reference_manual/dm00119316.pdf)에서 `F/S = 0`은 standard mode(`Sm`, 최대 `100 kHz`), `F/S = 1`은 fast mode(`Fm`, 최대 `400 kHz`)를 선택한다.

| 항목 | 현재 `Init(400000)` source | 의미 |
| :--- | :--- | :--- |
| `CCR` | `48 MHz / (2 × 400 kHz) = 60` | standard-mode 분주식으로 계산 |
| `F/S` | `0` | hardware는 standard mode 선택 |
| `DUTY` | `0` | fast-mode duty 미구성 |
| `TRISE` | `48 + 1 = 49` | standard-mode `1000 ns` rise-time 기준 |

현재 `F/S = 0` 경로에서는 `tHIGH = tLOW = 60 / 48 MHz = 1.25 μs`다. [I2C bus specification](https://www.nxp.com/docs/en/user-guide/UM10204.pdf)의 fast-mode 최소값은 `tLOW = 1.3 μs`, `tHIGH = 0.6 μs`이고 rise time 최대값은 `300 ns`다. 따라서 nominal `400 kHz`라도 low period가 짧고, `TRISE = 49`도 fast-mode rise-time 기준과 맞지 않는다.

이것이 배선이 맞아도 실패할 수 있는 정확한 이유다. `SCL`이 나와도 fast-mode timing 규격과 맞지 않아 target가 ACK하지 않거나 transaction이 끝나지 않을 수 있다. 이 현상은 배선·전원·address 오류와 겉으로 비슷하게 보인다. [SC16IS752](sc16is752-datasheet.md)는 fast-mode `400 kbit/s`를 지원하므로, 이 경우 `400 kHz` 자체가 금지된 것이 아니라 STM32 I2C timing 설정이 완결되지 않은 것이다.

문제를 분리하는 첫 확인은 호출값만 `I2C1_SC16IS752_Init(100000)`으로 바꾸는 것이다. 이때 `F/S = 0`, `CCR = 240`, `TRISE = 49`가 같은 standard-mode 기준에 맞는다. 이 속도에서 LED가 동작하면 배선·전원·address보다 speed-mode mismatch를 먼저 의심한다.

정식 `400 kHz` fast mode는 호출값만 `400000`으로 두는 것으로 끝나지 않는다. `PE = 0` 상태에서 `F/S = 1`, duty, fast-mode `TRISE`를 함께 설정한다. `PCLK1 = 48 MHz`, duty `2:1` 기준의 한 조합은 `CCR = 40`, `TRISE = 15`다. 이 값은 source 수정이 필요한 fast-mode 설정 기준이며, 현재 실습 source에는 구현되어 있지 않다.

fast mode는 register 값만의 문제가 아니라 physical waveform 조건이기도 하다. extension board에 pull-up resistor가 있어도 jumper 길이·bus capacitance·pull-up 값 때문에 실제 `SCL/SDA` rise time이 `300 ns`를 넘으면 `400 kHz`가 불안정할 수 있다. 따라서 `100 kHz` 통과는 배선과 protocol의 1차 확인이고, `400 kHz` 전환 뒤에는 fast-mode register 설정과 waveform을 함께 확인한다.

[13과 `main.c`](../helloEmbedded/1301.I2C_IF_EX/main.c)는 `IODIR = 0xFF`를 쓴 뒤 `~(1u << i)`를 `IOSTATE`에 보내 LED를 이동시킨다. 이동 간격은 `TIM2_Delay()`가 아니라 source의 busy loop가 만든다.

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
| `I2C1->CR1` | `PE` enable, `SMBUS = 0` I2C 선택, `START`·`STOP` 생성, `ACK` enable |
| `I2C1->CR2` | peripheral clock frequency 입력, `PCLK1=48MHz`이면 `48` |
| `I2C1->CCR` | SCL speed 설정, standard/fast mode 분주 |
| `I2C1->TRISE` | rise time 설정 |
| `I2C1->SR1` | `SB`, `ADDR`, `BTF`, `TxE`, `RxNE`, error flag |
| `I2C1->SR2` | `BUSY`, `MSL`, `TRA` 등 bus 상태 |
| `I2C1->DR` | 8bit data register |

#### I2C1 초기화 write 순서

[`i2c.c`](../helloEmbedded/1301.I2C_IF_EX/i2c.c)의 초기화는 peripheral reset 뒤 `CR2.FREQ`에 `PCLK1` 값을 먼저 기록한다. 이어 `CR1.PE = 0`을 명시해 peripheral을 멈춘 상태로 만들고, `TRISE`와 `CCR` timing을 설정한다. 마지막으로 `CR1.SMBUS = 0`으로 I2C mode를 선택한 뒤, `PE = 1`, `ACK = 1`을 순서대로 set한다.

`CR1.ACK`는 master가 receive할 때 ACK를 낼지 정하는 peripheral 정책이다. 현재 `Write_Reg()`는 master-transmit 경로이므로, address와 data 뒤에 target가 bus에 내는 ACK와 같은 bit가 아니다. 이후 read path를 추가할 때는 마지막 byte에서 ACK를 끄고 NACK으로 read를 끝내는 동작까지 연결해 본다.

#### I2C clock register를 숫자로 설정하는 이유

`I2C1->CR2`의 `FREQ` field는 통신 속도 자체를 쓰는 곳이 아니라, I2C peripheral에 공급되는 `PCLK1` frequency를 MHz 단위로 알려 주는 field다. 이어서 `CCR`과 `TRISE`가 이 입력 clock을 기준으로 SCL low/high timing과 rise-time allowance를 만든다. 따라서 `PCLK1` macro만 바꾸고 실제 clock 초기화를 하지 않으면 I2C bit time도 달라진다.

standard mode `100kHz`, `PCLK1 = 48MHz`의 기본 계산은 다음과 같다.

```text
CR2.FREQ = 48                         // PCLK1 = 48MHz
CCR      = PCLK1 / (2 * fSCL)
         = 48MHz / (2 * 100kHz)
         = 240
TRISE    = FREQ_MHz + 1
         = 48 + 1
         = 49
```

`CCR`은 hardware가 SCL high·low 시간을 나누는 기준이고(standard mode 최소값 `4`), `TRISE`는 pull-up resistor와 bus capacitance 때문에 high가 되는 데 걸리는 시간을 반영하는 값이다. standard mode의 SCL 최대 rise time이 `1000ns`이므로 `TRISE`에는 I2C 기준 주파수로 `1000ns` 동안 발생하는 펄스 수에 1을 더한 값, 곧 `FREQ(MHz) + 1`을 쓴다. fast mode는 duty 설정과 rise-time 식이 달라지므로 `100kHz`의 standard-mode 식을 그대로 복사하지 않고 `RM0383`의 해당 mode 표를 따라 설정한다.

`CCR` field의 숫자는 mode와 duty bit를 함께 읽어야 한다. 같은 `CCR` 값이라도 high·low period와 SCL frequency 식이 달라진다.

| mode | `CCR`이 만드는 SCL period | `fSCL` 식 |
| :--- | :--- | :--- |
| standard mode, `F/S = 0` | `tHIGH = CCR × TPCLK`, `tLOW = CCR × TPCLK` | `fPCLK1 / (2 × CCR)` |
| fast mode, `F/S = 1`, `DUTY = 0` | `tHIGH = CCR × TPCLK`, `tLOW = 2 × CCR × TPCLK` | `fPCLK1 / (3 × CCR)` |
| fast mode, `F/S = 1`, `DUTY = 1` | `tHIGH = 9 × CCR × TPCLK`, `tLOW = 16 × CCR × TPCLK` | `fPCLK1 / (25 × CCR)` |

따라서 fast mode의 duty `2:1` 조합에서 `PCLK1 = 48MHz`, `CCR = 40`이면 `48MHz / (3 × 40) = 400kHz`가 된다. `CCR = 60`만 보고 `400kHz`라고 판단하면 안 되는 이유다.

초기화 함수는 clock enable 뒤에 `RCC->APB1RSTR`의 I2C1 reset bit를 잠시 set했다 clear해 peripheral을 깨끗한 상태로 되돌리는 단계를 둔다. I2C는 bus 상태를 내부에 유지하는 peripheral이라, 이전 비정상 상태가 남아 있으면 다음 transaction이 시작부터 꼬일 수 있기 때문이다.

현재 source의 reset pulse는 `clear → set → 짧은 대기 → clear` 순서다. 첫 `clear`는 reset이 풀린 상태를 정리하고, 이어진 `set`이 I2C1 reset을 assertion 상태로 유지한다. 마지막 `clear`가 reset을 release하므로 그 뒤에 `CR2`, `CCR`, `TRISE`, `PE`를 설정할 수 있다. 여기서 reset bit의 `set`과 `clear`는 GPIO 출력 level을 만드는 동작이 아니라 peripheral 내부 상태를 초기화하는 clock/reset control이다.

```c
/* PCLK1 = 48MHz, I2C standard mode 100kHz 예 */
Macro_Write_Block(I2C1->CR2, 0x3Fu, 48u, 0u);
I2C1->CCR = 240u;
I2C1->TRISE = 49u;
```

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

`ADDR`는 단순히 flag 하나를 지우는 것이 아니라 `SR1` read 뒤 `SR2` read라는 순서를 요구한다. 현재 [`i2c.c`](../helloEmbedded/1301.I2C_IF_EX/i2c.c)의 `while(Macro_Check_Bit_Clear(I2C1->SR1, 1));`가 먼저 `SR1`을 읽고, 바로 다음 `(void)I2C1->SR2;`가 두 번째 read를 수행해 이 규칙을 만족한다. 이 polling 구조를 다른 helper나 interrupt handler로 바꿀 때도 두 read의 순서를 유지한다.

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
    int i, j;

    I2C1_SC16IS752_Init(400000);
    I2C1_SC16IS752_Config_GPIO(0xFF);

    for (;;)
    {
        for (i = 0; i < 8; i++)
        {
            I2C1_SC16IS752_Write_GPIO(~(1u << i));
            for (j = 0; j < 1000000; j++)
                ;
        }
    }
}
```

## 0722 수업 보강: I2C protocol과 address 해석

### 7bit device address와 wire byte

수업에서 가장 중요한 확인 지점은 device address와 wire byte를 분리하는 일이다.

| 구분 | 현재 SC16IS752 실습 값 | 뜻 |
| :--- | :--- | :--- |
| device address | `0x4D` | target IC 자체를 선택하는 7bit address |
| write address byte | `0x9A` | 7bit address left shift, `R/W = 0` |
| read address byte | `0x9B` | 7bit address left shift, `R/W = 1` |

따라서 `0x9A`와 `0x9B`는 같은 target을 가리킨다. 마지막 bit가 각각 write·read 동작을 지정한다. code에서 `SC16IS752_I2CADDR_WR`와 `SC16IS752_I2CADDR_RD`를 따로 둔 이유다.

### device register를 선택하는 sub-address

I2C device는 IC 선택용 7bit address와 별도로 내부 register·memory 위치를 고르는 sub-address를 가질 수 있다. 현재 실습에서는 `IODIR`·`IOSTATE` 같은 SC16IS752 register가 그 대상이다. [`I2C1_SC16IS752_Write_Reg()`](../helloEmbedded/1301.I2C_IF_EX/i2c.c)는 device write byte 뒤에 `addr << 3`으로 만든 register address byte, 이어서 write data를 보낸다.

```text
S → 0x9A (SC16IS752 + W) → ACK
  → register address → ACK
  → write data → ACK → P
```

register read는 먼저 write phase에서 register 위치를 지정한 뒤 repeated START로 같은 device를 read mode로 다시 선택한다.

```text
S → device + W → ACK → register address → ACK
Sr → device + R → ACK → data ← NACK → P
```

`Sr`은 bus ownership을 놓지 않은 채 direction을 write에서 read로 바꾸는 boundary다. 마지막 read byte 뒤 master가 `NACK`을 보내고 `STOP`으로 transaction을 끝낸다.

### multi-byte와 signal timing

data를 여러 byte 보낼 때는 address phase 뒤에 data·ACK를 반복하고 마지막에 `STOP`을 낸다. read도 master가 계속 `ACK`을 보내면 slave가 다음 byte를 보낸다. 마지막 byte에서 `NACK`을 보내면 더 이상 받지 않겠다는 뜻이 된다.

I2C physical signal 규칙은 다음 네 가지로 정리한다.

- `SCL`이 high인 동안 `SDA`가 high→low로 바뀌면 START다.
- `SCL`이 high인 동안 `SDA`가 low→high로 바뀌면 STOP다.
- 일반 data bit는 `SCL` high 구간에서 안정되어야 한다.
- sender는 `SCL` low 구간에서만 다음 data bit로 바꾼다.

ACK도 open-drain line에서 receiver가 `SDA`를 low로 당겨 만드는 응답이다. sender가 line을 release해야 receiver가 ACK를 만들 수 있으므로, 이 전기적 동작이 I2C의 protocol 규칙과 직접 연결된다.

## 0722 수업 보강: I2C1·SC16IS752 연결

### Firmware 설정과 실제 signal route

`I2C1`은 STM32F411 안의 hardware peripheral이고, `PB6`·`PB7`은 그 signal을 밖으로 내보낼 MCU pad다. [`I2C1_SC16IS752_Init()`](../helloEmbedded/1301.I2C_IF_EX/i2c.c)는 두 pin을 alternate function `AF4`, open-drain, fast speed로 설정한다.

| Signal | extension board | STM32F411 firmware 설정 | 역할 |
| :--- | :--- | :--- | :--- |
| `SCL` | serial clock | `PB6`, `I2C1_SCL`, `AF4` | clock |
| `SDA` | bidirectional data | `PB7`, `I2C1_SDA`, `AF4` | address·data·ACK |
| `ITF_MODE` | `3.3 V` | SC16IS752 I2C mode | interface 선택 |
| `A0`, `A1` | `GND` | I2C address strap | target address 선택 |
| `VDD_3V3` | `3.3 V` | power | device supply |
| `GND` | `GND` | common ground | voltage reference |

배선은 power부터 연결한다. `VDD_3V3 → 3.3 V`, `GND → GND`, `ITF_MODE → 3.3 V`, `A0/A1 → GND`를 먼저 연결하고, 그다음 `SCL → PB6`, `SDA → PB7`을 연결한다. 표는 logical signal 기준이므로 jumper의 실제 header 위치와 방향은 extension board와 Nucleo의 silk-screen을 함께 확인한다.

같은 MCU pad는 한 시점에 하나의 pin function만 선택한다. 따라서 `PB6`·`PB7`을 I2C1에 할당한 동안에는 그 pin의 다른 alternate function을 동시에 사용할 수 없다.

### 확장 board의 SC16IS752와 LED 검증

`SC16IS752`는 I2C 또는 SPI로 접근하는 dual UART·8bit GPIO bridge다. `ITF_MODE`를 high로 두면 I2C mode가 선택되고, `SCL`·`SDA`와 `A0`·`A1` signal이 사용된다. 이 확장 board에는 I2C line의 pull-up resistor가 포함되어 있어 수업 배선에서 별도 pull-up resistor를 추가하지 않는다. firmware source는 `PB6`·`PB7`의 internal pull-up도 enable한다.

GPIO `0`부터 `7`은 active-low LED에 연결된다. [`main.c`](../helloEmbedded/1301.I2C_IF_EX/main.c)는 먼저 `IODIR = 0xFF`로 GPIO output을 설정하고, `IOSTATE`에 `~(1u << i)`를 쓴다. 선택한 bit만 `0`이 되어 해당 LED가 켜진다.

```text
STM32F411 I2C1
  → SC16IS752 device address
  → IODIR / IOSTATE register write
  → SC16IS752 GPIO output
  → active-low LED
```

LED 이동은 I2C protocol, address decode, register access, extension board wiring이 모두 이어졌는지 확인하는 end-to-end test다.

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

#### SPI는 write해도 동시에 read가 일어난다

SPI의 두 shift register는 clock edge마다 한 bit씩 동시에 이동한다. 따라서 master가 command byte를 MOSI로 보낼 때에도 slave가 MISO로 내보낸 byte 하나가 master receive register에 들어온다. write-only command처럼 보여도 `RXNE`를 처리하지 않으면 receive side가 막히거나 overrun 상태가 될 수 있음.

```text
master write DR -> SCK 8회 발생 -> slave와 byte 교환 -> RXNE set
```

`CS`는 단순 enable 선이 아니라 '이 clock 묶음이 어느 slave의 어느 transaction인가'를 구분하는 frame boundary다. slave data sheet가 요구하는 CS setup time, byte 사이 CS 유지 여부, 마지막 clock 뒤 hold time을 지켜야 command/address/data가 하나의 명령으로 해석된다. SPI는 주소·ACK가 protocol에 고정되어 있지 않으므로, 이 frame 형식은 slave별 data sheet가 정함.

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
| `SPI1->CR1` | `LSBFIRST` | `0`: MSB first, `1`: LSB first |
| `SPI1->CR1` | `DFF` | `0`: 8bit, `1`: 16bit |
| `SPI1->CR1` | `SSM`, `SSI` | software NSS management와 `SSM = 1`일 때의 내부 NSS level |
| `SPI1->CR1` | `SPE` | SPI enable |
| `SPI1->CR2` | `SSOE` | master mode에서 SPI peripheral의 `NSS` output enable |
| `SPI1->SR` | `TXE` | transmit buffer empty |
| `SPI1->SR` | `RXNE` | receive buffer not empty |
| `SPI1->SR` | `BSY` | SPI busy |
| `SPI1->DR` | data register | 송수신 data |

SPI peripheral의 `NSS` 설정과 외부 IC를 선택하는 `PA8` `CS`는 source에서 분리되어 있다. [14과 `spi.c`](../helloEmbedded/1401.SPI_IF_EX/spi.c)는 `PA8`을 GPIO output으로 직접 low/high 하면서, `SPI1->CR2.SSOE = 1`, `CR1.SSM = 0`, `CR1.SSI = 0`도 설정한다. `SSOE`는 SPI peripheral의 `NSS` output을 enable하는 bit이며, `PA8`의 target `CS` pulse를 만들어 주는 bit가 아니다. 따라서 `SSOE`를 single/multi-master 선택 bit로 읽거나 `PA8` manual `CS`와 같은 signal로 합치면 안 된다.

`SSM = 1`은 external `NSS` input 대신 software가 정한 `SSI` level을 SPI 내부 NSS 판단에 쓰는 선택이다. 반대로 현재 source의 `SSM = 0`, `SSOE = 1`은 peripheral NSS output 경로를 사용한다. 실제 target을 선택하는 frame boundary는 여전히 `SPI1_CS_LOW()`·`SPI1_CS_HIGH()`가 만드는 `PA8` signal이다. 다른 board나 multi-master 구성으로 옮길 때는 target `CS`, MCU peripheral `NSS`, `SSM`·`SSI`·`SSOE`를 각각 분리해 datasheet와 reference manual 조건을 확인한다.

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

SC16IS752는 SPI mode에서 최대 `4Mbps`로 동작한다. SPI1의 입력 clock은 `PCLK2 = 96MHz`이므로, 이 한계를 넘지 않는 분주를 골라야 한다. 예를 들어 `/32` 분주면 `3MHz`로 한계 안에 들어온다. slave의 최대 clock을 넘기면 데이터가 깨지므로 slave datasheet의 한계와 `PCLK2`·prescaler를 항상 함께 확인한다.

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

### 현재 실습 code 기준 확인

[14과 `main.c`](../helloEmbedded/1401.SPI_IF_EX/main.c)는 `SPI1_SC16IS752_Init(32)`를 호출한다. `PCLK2 = 96 MHz`에서 source의 `__builtin_ctz(32)` 계산은 `BR = /32`, 즉 `3 MHz`를 만든다. 이 helper는 `2`의 거듭제곱 분주값을 입력으로 사용한다.

[14과 `spi.c`](../helloEmbedded/1401.SPI_IF_EX/spi.c)는 16bit frame, master, mode 0, MSB first로 `DR`에 command word를 쓰고 `TXE` set·`BSY` clear만 기다린다. SPI physical transfer는 full-duplex이므로 receive `DR`를 읽거나 `RXNE`·overrun을 처리하는 경로는 현재 최소 write 예제에 포함되지 않는다. 반복 transfer 또는 receive 기능으로 확장할 때는 receive flag와 overrun clear sequence를 추가한다.

#### `__builtin_ctz()`로 `BR` field를 만드는 조건

[`SPI1_SC16IS752_Init()`](../helloEmbedded/1401.SPI_IF_EX/spi.c)는 `div`를 `/2`, `/4`, `/8`처럼 `2`의 거듭제곱 분주값으로 받고 `__builtin_ctz(div)`를 이용해 `BR[2:0]` encoding을 만든다. `ctz`는 'count trailing zeros'로, `0`번 bit부터 연속된 `0`의 개수를 반환한다. `div`가 `2^k`이면 `ctz(div) = k`이고, SPI의 `BR = 0`이 `/2`를 뜻하므로 원하는 field 값은 `k - 1`이다.

| `div` | binary 끝의 `0` 개수 | source가 만드는 `BR` | SCK |
| :---: | :---: | :---: | :--- |
| `2` | `1` | `0` | `PCLK2 / 2` |
| `8` | `3` | `2` | `PCLK2 / 8` |
| `32` | `5` | `4` | `PCLK2 / 32 = 3MHz` |
| `128` | `7` | `6` | `PCLK2 / 128` |

현재 source의 식은 `(__builtin_ctz(div) & 0x7) - 1`이다. 따라서 실제 사용값 `32`에서는 정확히 동작한다. 다만 `div = 256`이면 `ctz(256) = 8`이지만 `& 0x7`이 먼저 `0`으로 만든 뒤 `-1`이 되어, 이후 `n << 3`에 negative value가 들어간다. C에서 negative value의 left shift는 정의되지 않은 동작이다. `div = 0`의 `__builtin_ctz(0)`도 정의되지 않는다. 이 helper를 일반 API로 확장할 때는 입력을 `2`부터 `128`까지의 power of two로 제한하거나, `/256`을 포함하는 별도 검증·mapping을 둔다. 현재 수업의 `SPI1_SC16IS752_Init(32)`에는 이 문제가 적용되지 않는다.

#### source가 첫 `TXE` 대기를 생략한 이유

[`SPI1_SC16IS752_Write_Reg()`](../helloEmbedded/1401.SPI_IF_EX/spi.c)는 함수 시작에서 바로 `DR`에 16bit word를 쓴 뒤 `TXE`와 `BSY`를 기다린다. 이 순서는 초기화 직후 `TXE = 1`인 상태, 또는 이전 호출이 `BSY = 0`까지 확인하고 반환한 상태를 전제로 한다. 현재 `main.c`는 한 transaction이 끝난 뒤 다음 함수를 호출하므로 이 전제가 성립한다.

이 전제는 단일 polling 실습의 단순화다. 다른 task·ISR·DMA가 같은 SPI를 동시에 사용할 수 있는 driver에서는 다음 `DR` write 전에 ownership과 `TXE`를 확인하고, full-duplex로 쌓인 receive data도 처리해야 한다. 현재 source의 직렬 호출 구조를 일반적인 concurrent SPI driver의 안전 조건으로 확대 해석하지 않는다.

#### SPI의 16bit write word를 field로 읽기

실습 code는 `DFF=1`로 SPI frame을 16bit로 설정하고, command·register address·data를 한 word에 넣어 보낸다.

```c
(0u << 15) | ((addr & 0xFu) << 11) | (data & 0xFFu)
```

| bit | field | write 함수에서 넣는 값 |
| :---: | :--- | :--- |
| `15` | R/W | `0`: write |
| `14:11` | SC16IS752 register address | `addr & 0xF` |
| `10:9` | UART channel 선택, GPIO 제어에서는 무의미 | `0` |
| `8` | 미사용 bit | `0` |
| `7:0` | register write data | `data & 0xFF` |

예를 들어 `IOSTATE` register에 `0xFE`를 쓰면, 먼저 16bit frame 안의 register field가 `IOSTATE`를 선택하고 data field가 `1111_1110`을 전달한다. active-low LED 회로에서는 이 값의 bit `0`이 low이므로 GP0 LED가 켜진다. I2C에서는 address·register·data가 여러 byte와 ACK로 나뉘지만, 이 SPI 실습에서는 slave data sheet가 정한 16bit command format으로 같은 의미를 전달하는 차이임.

#### SPI register read와 dummy clock

SC16IS752의 SPI read는 write와 달리 8bit command byte의 `R/W = 1`을 먼저 보낸 뒤, 이어지는 8개의 SCK로 register data를 받는다. SPI는 full-duplex이므로 command byte를 shift하는 첫 8 clocks 동안 MISO에 들어온 값은 target가 아직 register를 선택하는 중이라 유효 data가 아니다. master는 `CS`를 low로 유지한 채 dummy byte 하나를 추가로 보내 두 번째 8 clocks를 만들고, 그때 `DR`로 들어온 byte를 read result로 사용한다.

```text
CS low
  -> command byte: R/W=1, register address, channel, reserved bit
  -> dummy byte: MOSI 값은 don't-care, SCK 8개 생성
  -> MISO second byte: register data
CS high
```

현재 `SPI1_SC16IS752_Write_Reg()`는 16bit write만 구현한다. register read를 추가할 때는 SPI frame size를 8bit로 맞추거나 8bit transfer 두 번을 같은 `CS` frame 안에서 수행하고, 첫 receive byte를 버린 뒤 두 번째 `RXNE` data를 읽는다. 이 read path와 overrun clear sequence는 현재 source에 구현되어 있지 않다.

I2C 실습과 마찬가지로 `IODIR`을 output으로 설정하고 `IOSTATE`에 active-low data를 써서 LED를 이동시킬 수 있음.

```text
SPI frame

CS  : __\\____________________/__
SCK : ___/‾\\_/‾\\_/‾\\_/‾\\_____
MOSI:  command/address/data bits
MISO:  slave response bits
```

#### Bus 파형은 trigger로 잡는다

I2C·SPI처럼 산발적으로 발생하는 bus transaction은 logic analyzer의 trigger로 잡는 것이 기본이다. I2C의 `SDA`(start condition) 또는 SPI의 `CS` falling edge를 trigger 조건으로 걸고 run 상태로 두면, 첫 transaction 시점 전후 파형이 자동으로 capture된다. Logic 2의 protocol analyzer를 채널에 붙이면 address·ACK·data 단위로 해석된 값을 함께 확인할 수 있어, register write가 실제 전기 신호로 어떻게 나갔는지 code와 대조할 수 있다.
