# 26-07-16

관련 노트:

- [26-07-15 - LED Driver 과제와 System Clock 설정](260715-led-driver-system-clock.md)

## 복습 요점 - System Clock과 Key 입력

상세 설명은 [26-07-15 노트](260715-led-driver-system-clock.md)를 기준으로 하고, 여기서는 다시 강조된 요점만 정리한다.

- PLL은 켠 직후 바로 안정된 출력을 내지 못한다. 설정 주파수로 출력이 고정될 때까지 걸리는 시간이 lock time이며, `RCC->CR`의 ready flag가 set될 때까지 기다린 뒤 system clock을 전환한다.
- clock source는 HSI 또는 HSE 중에서 선택해 PLL에 입력하고, AHB·APB prescaler 경로를 따라 각 bus clock이 결정된다.
- USB는 PLL의 48MHz 출력 조건을 요구하므로, system clock 후보는 48MHz 제약과 함께 정해진다.
- CPU clock을 올리면 flash memory의 access time이 상대적으로 느려진다. 요구 clock에 맞는 flash wait state를 함께 설정해야 잘못된 값을 읽지 않는다.
- 주변장치는 사용 전에 해당 clock gate를 켜야 한다. 사용하지 않는 장치에 clock을 주지 않는 것이 소비 전력 절감의 기본 방식이다.
- 어디에도 연결되지 않은 입력 pin은 floating 상태가 되어 값이 흔들린다. pull-up은 idle을 high로, pull-down은 idle을 low로 고정한다.
- '한 번 누름' event는 level polling과 다르다. release까지 소비하거나, old/current key 비교 또는 lock flag 상태 기계로 edge를 검출한다.

## 실습 - 외부 Tact Switch와 Chattering 파형 관찰

### Tact switch 배선

tact switch는 4개 pin 중 같은 쪽 두 pin씩 내부에서 이미 연결되어 있다. 어느 쌍이 내부 연결인지 헷갈리면 대각선 방향의 두 pin을 사용한다. 대각선 pin은 내부 연결 여부와 관계없이 항상 switch 접점을 통과하므로 방향 실수를 피할 수 있다.

```text
[1] ──┬── [2]      1-2 내부 연결, 3-4 내부 연결
      sw
[3] ──┴── [4]      대각선(1-4 또는 2-3)으로 쓰면 항상 접점을 통과
```

breadboard에서 switch 한쪽은 `GND`에 연결하고, 다른 쪽은 input pin에 연결한다. input은 pull-up으로 설정해 idle을 high로 고정한다. 누르면 `0`, 떼면 `1`로 읽힌다.

### 실습 pin과 값 읽기

외부 key input은 Arduino header `D9`에 해당하는 `PC7`을 사용한다. GPIOC clock enable, `MODER` input mode, `PUPDR` pull-up 설정 후 `IDR`의 bit 7을 읽는다.

`IDR & (1 << 7)`의 결과는 `0` 아니면 `0x80`이다. 참/거짓 판정에는 그대로 쓸 수 있지만, `0` 또는 `1` 값이 필요하면 mask한 자리만큼 오른쪽으로 shift해 정규화한다.

```c
key = (GPIOC->IDR >> 7) & 1u;   /* pressed = 0, released = 1 */
```

### Logic analyzer로 chattering 관찰

- switch가 연결된 input pin과 같은 지점에 logic analyzer probe channel을 연결하고 `GND`를 공통으로 잡는다. 보드 header에서 해당 pin 위치를 pinout 기준으로 세어 확인한 뒤 연결한다.
- Logic 2 software에서 capture를 시작한 뒤 switch를 누르고 뗀다.
- press와 release 순간을 확대하면 한 번의 조작에서 low/high가 여러 번 튀는 bounce 구간이 짧은 noise처럼 보인다.
- 이 구간이 software에서 press event가 중복 검출되는 원인이며, debounce 대책이 필요한 근거 파형이다.

### N회 연속 sample debounce 구현 방향

가장 단순한 debounce는 같은 값을 N번 연속으로 읽었을 때만 상태를 확정하는 방법이다.

```text
count = 0
loop:
    now = key 읽기
    if now == 직전 값 : count++
    else              : count = 0   (chattering으로 판단하고 다시 센다)
    if count >= N     : 상태 확정, 정상 입력으로 처리
```

N과 sample 주기는 고정된 정답이 없다. 관찰한 bounce 지속 시간을 기준으로 값을 바꿔가며 실험해 조정한다. bounce 구간보다 debounce 시간이 짧으면 중복 검출이 남고, 너무 길면 입력 반응이 늦어진다.

### Trigger로 event 순간 포착

trigger는 지정한 channel의 신호 조건이 발생하는 순간을 기준으로 capture를 잡아 보여주는 기능이다. run/stop을 눈으로 반복하는 대신, 신호가 발생한 시점 전후의 파형을 자동으로 확보한다.

- trigger 설정에서 관찰할 channel을 선택한다.
- pull-up 입력의 버튼은 누르는 순간 low로 떨어지므로 falling edge 조건을 잡는다.
- run 상태로 대기하다가 조건이 발생하면 그 시점을 기준으로 파형이 표시된다.
- UART처럼 산발적으로 도착하는 신호의 첫 data 시점을 잡을 때도 같은 방식을 쓴다.

측정 cursor를 파형에 대면 구간 시간과 주파수 성분이 함께 표시되므로, bounce 길이나 bit time 확인에도 활용한다.

## 10과 - UART와 RS232 통신

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

#### Frame 형식은 '문자 1개를 어떤 시간 단위로 보낼지'의 약속

UART 설정에서 `8N1`은 `8 data bits`, `N`(no parity), `1 stop bit`의 약속이다. 이는 data 폭만 정하는 값이 아니다. 송신기와 수신기는 start bit 뒤에 몇 번 sample할지, parity를 data로 볼지 검사 bit로 볼지, 다음 frame을 언제부터 기다릴지를 모두 이 형식으로 결정한다.

| 형식 항목 | 송신기 | 수신기 | 불일치 결과 |
| :--- | :--- | :--- | :--- |
| word length | 7·8·9bit만큼 data bit 전송 | 같은 개수 sample | 다음 bit의 경계가 틀어짐 |
| parity | data의 `1` 개수에서 검사 bit 생성 | even/odd 규칙 검사 | 정상 byte도 parity error |
| stop bit | high 상태를 정해진 bit 시간 유지 | frame 종료·다음 start 탐색 | framing error 또는 경계 오류 |
| baud rate | bit time 생성 | 같은 bit time으로 sample | 문자 깨짐 또는 수신 실패 |

parity는 오류를 고치는 기능이 아니라, 한 frame 안의 일부 오류를 발견하는 검사 bit다. even parity는 data와 parity bit를 합친 `1`의 개수가 짝수가 되게 하고, odd parity는 홀수가 되게 한다. 두 bit가 동시에 뒤집히는 오류처럼 parity가 발견하지 못하는 경우도 있으므로 신뢰성이 더 필요한 protocol은 checksum·CRC·sequence number를 상위 계층에 추가한다.

`USART`는 UART 기능에 synchronous clock 기능까지 포함할 수 있는 주변장치 이름이다. 이 실습은 clock 선을 쓰지 않는 asynchronous mode이므로 실제 data format과 사용 방법은 UART 방식으로 이해하면 된다.

#### UART 수신기는 clock 선 없이 어떻게 bit 경계를 맞추는가

UART에는 송신기와 수신기 사이에 SCLK 같은 별도 clock 선이 없다. 대신 양쪽이 같은 baud rate를 미리 약속하고, 수신기는 idle high 상태에서 start bit의 falling edge를 발견하면 자기 내부 clock으로 bit 중심을 샘플링한다.

```text
idle high
   |
   +-- falling edge 발견: start bit 시작 추정
          |
          +-- 0.5 bit time 뒤 start bit 중앙 확인
                 |
                 +-- 이후 1 bit time 간격으로 D0, D1, ... D7 샘플
```

`115200 baud`는 초당 약 115200bit를 보내는 설정이며, 1bit 시간은 약 `8.68µs`다. 송신기와 수신기의 실제 속도 차이가 너무 크면 sample 위치가 bit 경계 쪽으로 밀려 data를 잘못 읽는다. 그래서 baud rate, data bit 수, parity, stop bit 수는 양쪽이 모두 같아야 한다.

#### 문자 하나가 UART register를 통과하는 경로

`USART1->DR = 'A';`는 문자 자체를 cable에 바로 밀어 넣는 code가 아니다. CPU가 data register에 byte를 쓰면 USART shift register가 start/data/stop frame을 만든 뒤, GPIO alternate-function output을 통해 `PA9` 전압을 시간 순서대로 바꾼다. 수신은 정확히 반대 방향으로 진행됨.

```text
TX: C byte -> USART_DR -> shift register -> UART frame -> PA9 -> bridge/cable
RX: PA10 -> start edge detect -> sample/shift register -> USART_DR -> C byte
```

송신 `TXE`는 CPU가 다음 byte를 `DR`에 넣을 수 있다는 뜻이고, `TC`는 shift register까지 비어 마지막 stop bit가 pin에서 끝났다는 뜻이다. 단순 연속 송신에는 `TXE`를 기다리면 되지만, 송신 방향을 바꾸거나 line이 완전히 idle인지 확인해야 하는 half-duplex 동작에서는 `TC`까지 확인해야 함. 수신 `RXNE`는 unread byte가 있다는 뜻이므로, 처리하지 않은 채 다음 byte가 오면 `ORE` overrun error가 될 수 있다.

| 목적 | 먼저 확인할 flag | 이어서 할 일 |
| :--- | :--- | :--- |
| 다음 byte 송신 | `TXE = 1` | `DR` write |
| 마지막 frame까지 송신 종료 | `TC = 1` | direction 전환 또는 peripheral disable |
| 새 byte 수신 | `RXNE = 1` | `DR` read, application buffer에 보관 |
| 수신이 너무 빠름 | `ORE` 확인 | status/data 처리 순서를 문서 기준으로 수행, buffer/interrupt/DMA 검토 |

### RS232, RS422, RS485

| 규격 | 특징 |
| :--- | :--- |
| RS232 | 근거리 저속 비동기 직렬 통신, DTE-DCE 규약 |
| RS422 | differential 방식, 고속 원거리 전송 |
| RS485 | multi-drop 구성 지원, half-duplex 가능 |

RS422는 두 신호가 대칭으로 나가는 differential 방식이라 원거리에서도 손상이 적고, CAN도 같은 differential 계열이다. RS485는 master 하나에 slave 여러 개가 붙는 1:N multi-drop half-duplex 구성이라, 건물 보안 sensor망처럼 설비·장비 간 배선에 지금도 널리 쓰인다.

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

#### DTE-DCE 기원과 현재의 3선 cross 연결

RS232는 원래 DTE(Data Terminal Equipment, 단말기·PC)와 DCE(Data Communication Equipment, 모뎀)를 잇는 근거리(약 10m) 저속 규약이다. PC통신 시절 PC와 전화망 모뎀을 연결하던 규약이 지금까지 내려온 것이다. `DCD`, `DTR`, `DSR`, `RI`는 모뎀 상태를 다루는 신호라 모뎀이 없는 현재 용도에서는 의미가 없고, 그래서 `RX`, `TX`, `GND` 세 선만 남았다.

DCE 없이 DTE끼리 직접 통신하므로 연결은 cross다. 한쪽 `TX`는 상대 `RX`로, 상대 `TX`는 내 `RX`로 교차 연결한다.

#### RTS·CTS handshake와 flow control

수신 쪽 buffer가 가득 찼는데 송신 쪽이 계속 밀어 넣으면 데이터가 유실된다. 이를 막는 것이 flow control이다.

| 방식 | 동작 | 비고 |
| :--- | :--- | :--- |
| Hardware (`RTS`/`CTS`) | 보내겠다(`RTS`)-보내도 된다(`CTS`)를 신호선으로 확인 | 양쪽 설정이 모두 같아야 동작 |
| Software (XON/XOFF) | 전송 가능/불가 제어 문자를 data stream에 삽입 | 별도 선 불필요, overhead 때문에 잘 안 씀 |
| None | flow control 없음 | 일반 debug console 기본값 |

terminal 프로그램의 serial port 설정에 있는 flow control 항목이 이 선택이고, 이 확인 절차를 handshake라고 부른다.

RS232 전기 신호에서는 TTL 논리와 다른 전압 레벨을 사용한다. `Space(0)`은 `+3V ~ +15V`, `Mark(1)`은 `-3V ~ -15V`의 양/음 전압으로 표현되어 논리 극성이 TTL과 반대이고, `-3V ~ +3V` 사이는 undefined 전이 구간이다. 이 큰 전압 폭 덕분에 TTL보다 긴 거리(근거리 기준 10m 수준)의 cable 전송이 가능하다.

UART 쪽 `0V/5V`(또는 `3.3V`) logic을 RS232의 ± 전압으로 바꾸는 대표적인 level transceiver가 `MAX232` 계열 IC다. UART 출력을 cable에 그대로 넣는 것이 아니라 이 변환 IC를 거쳐 극성이 반전된 ± 전압으로 전송된다.

`UART`와 `RS232`는 같은 말이 아니다. UART는 start/data/stop frame을 만들고 해석하는 digital logic block이며, RS232는 그 bit를 cable로 보내기 위한 전기적 전압 규격이다. MCU pin의 `3.3V` UART signal을 PC의 RS232 connector에 직접 연결하면 전압·논리 극성이 맞지 않을 수 있으므로 level shifter 또는 USB-UART bridge가 필요하다.

#### TTL UART, RS232, USB는 서로 다른 층

`TX`와 `RX`라는 signal 이름이 같아도 선 위의 전기 규칙은 다를 수 있다. 보드 안에서 MCU와 bridge IC를 잇는 선은 보통 `3.3V` CMOS/TTL 수준의 UART이고, 전통적인 DB-9 cable은 RS232 전압과 polarity 규칙을 사용하며, PC의 USB connector는 packet 기반 USB signaling을 사용한다.

```text
application 문자
       |
USART peripheral: start/data/parity/stop frame
       |
3.3V MCU TX/RX -------- UART-USB bridge -------- USB -------- PC virtual COM
                 또는
3.3V MCU TX/RX -------- RS232 level transceiver - DB-9 ----- RS232 장비
```

따라서 terminal에서 글자가 깨진다면 C string 문제로 바로 단정하지 않는다. 실제 clock 값과 `BRR` divider, terminal baud/frame 설정, TX/RX 교차 연결, GND 공통, bridge driver와 전기 level을 순서대로 확인한다.

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

stop bit 수를 늘리면 연속 전송에서 문자와 문자 사이에 idle 여유 시간이 생긴다. 수신 쪽이 byte마다 처리 시간을 확보해야 하는 느린 장치라면, stop bit를 크게 잡아 자간 delay를 만드는 용도로 쓸 수 있다. 한두 byte씩 보낼 때는 문제없다가 firmware image처럼 긴 data를 연속 전송할 때 수신 쪽이 밀리는 문제가 이 경우이고, terminal 프로그램의 문자/라인 단위 send delay 설정도 같은 목적의 송신 측 여유 시간이다.

`USARTx->BRR`은 baud rate를 설정한다. 계산에 들어가는 `fCK`는 USART 번호에 따라 다르다. `USART1`은 `PCLK2`, `USART2`는 `PCLK1`을 쓴다. Nucleo 보드에서 ST-Link virtual COM port에 연결된 기본 UART는 `USART2`다. 계산 흐름은 다음과 같음.

```text
USARTDIV = fCK / (16 * baud)
DIV_Fraction = round(frac(USARTDIV) * 16)
DIV_Mantissa = int(USARTDIV) + carry
BRR = (DIV_Mantissa << 4) | DIV_Fraction
```

`OVER8 = 0`인 16배 oversampling 조건에서 `PCLK2 = 96MHz`, 목표 `115200 baud`라면 다음과 같이 계산한다.

```text
USARTDIV = 96,000,000 / (16 * 115,200)
          = 52.08333...

mantissa = 52
fraction = round(0.08333... * 16) = 1
BRR      = (52 << 4) | 1 = 0x341
```

fraction 반올림 결과가 `16`이면 fraction field에는 `0`을 쓰고 mantissa에 carry `1`을 더한다. 수업 code의 `mant += frac >> 4; frac &= 0xF;`가 바로 이 overflow 처리를 한다. carry가 실제로 발생하는 예로 `USARTDIV = 50.99`를 계산하면 다음과 같다.

```text
mantissa = 50
fraction = round(0.99 * 16) = round(15.84) = 16  -> 4bit 초과
carry    -> mantissa = 51, fraction = 0
BRR      = (51 << 4) | 0 = 0x330
```

소수부에 16을 곱하는 것은 1/16 단위 고정소수점으로 바꾸는 진법 변환이다. 결과가 `0xF`를 넘으면 자리올림이므로 정수부로 넘긴다. `PCLK2`가 실제로 `96MHz`인지 확인하지 않은 채 이 계산만 맞춰도 baud는 맞지 않는다. clock tree의 실제 bus clock과 `BRR` 계산의 입력값은 반드시 같은 조건이어야 함.

`USARTx->DR`은 송수신 data register다. GPIO가 `ODR`과 `IDR`로 나뉘는 것과 달리 이름도 address도 하나이며, 내부에는 TX/RX register가 분리되어 있어 송수신이 동시에 진행되는 full-duplex 동작이 가능하다. 프로그래머에게는 같은 address처럼 보이지만, bus transaction 방향에 따라 의미가 달라진다. CPU가 해당 address에 write하면 transmit data register 쪽으로 데이터가 들어가 송신이 시작되고, CPU가 같은 address를 read하면 receive data register에 보관된 수신 byte를 읽는다.

이 구조 때문에 상태 flag 확인이 중요하다. 송신 전에는 `SR.TXE`가 set인지 확인해 data register가 비었는지 보고, 수신 전에는 `SR.RXNE`가 set인지 확인해 수신 data가 준비됐는지 본다. `DR` read는 `RXNE` clear와 연결될 수 있으므로, status read와 data read 순서도 reference manual 기준으로 맞춰야 한다.

`USARTx->SR`의 주요 flag는 다음과 같다.

| flag | 의미 | clear 조건 |
| :--- | :--- | :--- |
| `TXE` | transmit data register empty | `DR` write 후 clear |
| `RXNE` | receive data register not empty | `DR` read 후 clear |
| `TC` | transmission complete | 전송 완료 |
| `ORE` | overrun error | 상태/데이터 처리 필요 |
| `PE` | parity error | parity error |

`TXE`는 empty, `RXNE`는 not empty로 이름의 극성이 반대다. 송신은 register가 비어야 다음 byte를 넣을 수 있고, 수신은 차 있어야 읽을 것이 있기 때문이다. 두 flag 모두 set이면 '지금 `DR`에 접근해도 된다'는 공통 의미로 읽으면 된다.

두 flag는 사용자가 직접 clear하지 않는다. `TXE`는 `DR` write 순간, `RXNE`는 `DR` read 순간 hardware가 자동으로 clear한다. read/write 동작 자체에 clear를 연동해 둔 이유는, CPU가 아니라 DMA 같은 hardware가 UART를 끌고 갈 때도 별도의 clear 절차 없이 전송이 이어지게 하기 위해서다.

송수신의 overflow 취급은 비대칭이다. 송신은 `TXE`가 set되기 전에 `DR`을 쓰면 아직 나가지 않은 byte를 덮어써서 데이터가 조용히 사라질 뿐 error는 아니다. 수신은 안 읽은 byte 위에 새 byte가 도착하면 `ORE` error flag가 선다. 손 타이핑 속도에서는 발생하지 않지만, 연속 데이터 수신에서는 error 복구 처리가 필요하며 이후 interrupt 기반 수신으로 구조적으로 대비한다.

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

#### AF mapping table 읽는 법

pin과 주변장치의 연결 후보는 data sheet의 alternate function mapping 표에 정리되어 있다. 열은 `AF0`~`AF15`, 행은 pin이다.

1. 쓰려는 주변장치가 속한 AF 열을 찾는다. USART1은 `AF7`이다.
2. 그 열을 따라 내려가며 `USART1_TX`, `USART1_RX`가 적힌 pin 행을 찾는다.
3. 후보 중 회로에서 다른 용도와 겹치지 않는 pin을 선택한다.

하나의 pin은 여러 주변장치와 겸용이다. 예를 들어 `PA5`는 GPIO 외에 `TIM2_CH1`, `SPI1_SCK` 등으로도 쓸 수 있다. 반대로 하나의 주변장치 신호도 여러 pin에 매핑 후보를 가진다. `USART1` TX/RX는 `PA9`/`PA10` 외에 `PB6`/`PB7` 쪽 후보도 있어, 원하는 pin이 이미 다른 용도로 쓰이고 있으면 대체 pin으로 피할 수 있다.

#### `AFR[0]`/`AFR[1]` 구조

AF가 16종이므로 pin 하나당 4bit가 필요하고, 32bit register 하나에는 8개 pin만 담긴다. 그래서 alternate function register는 low/high 두 개로 나뉘며, header가 이 둘을 배열로 선언해 `AFR[0]`, `AFR[1]`로 접근한다.

| Register | 담당 pin |
| :--- | :--- |
| `AFR[0]` (low) | pin `0`~`7` |
| `AFR[1]` (high) | pin `8`~`15` |

`PA9`/`PA10`은 high 쪽이므로 `AFR[1]`에서 두 pin의 4bit field에 각각 `7`을 쓴다. 위 code의 `0x77`이 연속한 두 field에 `AF7`을 넣는 값이다.

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

초기화 순서는 각 hardware block이 동작할 조건을 앞에서부터 준비하는 순서다.

| 순서 | 설정 | 이유 |
| :---: | :--- | :--- |
| 1 | `GPIOAEN`, `USART1EN` clock gate enable | register 접근과 peripheral clock 공급 |
| 2 | `PA9`, `PA10`을 alternate function mode·`AF7`로 설정 | USART signal이 pin mux를 통과하도록 연결 |
| 3 | 실제 `PCLK2`로 `BRR` 계산 | 요구 baud rate의 bit time 생성 |
| 4 | `CR2` stop bit, `CR3` 부가 기능 설정 | frame·flow-control 조건 확정 |
| 5 | `CR1.TE`, `CR1.RE` enable | 송신기·수신기 회로 동작 허용 |
| 6 | `CR1.UE` enable | USART 전체 동작 시작 |

GPIO `PUPDR` 설정은 external 회로와 board 연결에 따라 달라진다. UART line이 bridge 또는 다른 device에 연결되어 idle high가 안정적으로 구동되는 경우 내부 pull-up은 필수가 아니다. 반대로 상대 device가 reset 중이거나 line이 open이 될 수 있는 회로에서는 idle level과 전기 조건을 회로도 기준으로 확인한다.

### USART1 Local Echo-Back 실습

UART 검증은 원래 상대 UART 장치와 교차 연결해 서로 주고받으며 확인한다. 지금은 USART2가 ST-Link virtual COM port로 이미 쓰이고 있어 상대 장치를 붙이기 어려우므로, 자기 TX를 자기 RX에 묶어 '보낸 것을 내가 받는' loopback으로 확인한다. loopback은 실무에서도 UART 경로 검증에 흔히 쓰는 방법이다.

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

`printf`는 USART2(ST-Link virtual COM port)로 나가므로 terminal에는 loopback으로 되돌아온 문자가 표시된다. 정상 동작이면 `A B C ... Z`가 한 번에 출력된다.

terminal에 직접 타이핑한 글자가 화면에 보이지 않는 것은 terminal의 local echo가 기본으로 꺼져 있기 때문이다. 내가 친 글자를 보려면 terminal 설정에서 local echo를 켜거나, 보드가 수신 byte를 되돌려 보내는 echo 구조를 만들면 된다.

#### Flag 대기를 생략하면 생기는 일

`RXNE` 대기는 '1이 될 때까지'(`while (!Macro_Check_Bit_Set(...));`)로 쓰거나 '0인 동안'(`while (Macro_Check_Bit_Clear(...));`)으로 써도 같은 코드다. 문제는 이 무한대기 자체를 빼먹고 flag를 한 번만 확인한 뒤 지나가는 경우다. 수신 실패 시 `*`를 출력하도록 기본값을 넣고 돌려 보면 실패 과정이 그대로 보인다.

- 처음 두 글자는 `*`가 찍힌다. CPU는 96MHz라 `DR` write 직후 바로 `RXNE`를 확인하지만, UART frame이 되돌아오려면 10bit 시간이 걸려 아직 도착 전이기 때문이다.
- 세 번째 글자를 보낼 즈음 처음 보낸 `A`가 도착해 읽히고, 이후 출력은 보낸 글자보다 한 박자 늦게 따라온다.
- 그 사이 읽지 못한 글자는 buffer에서 유실되고, 마지막 `Z`는 도착했지만 loop 횟수가 끝나 읽히지 않는다. 결과적으로 일부 글자가 빠진 출력이 나온다.

CPU와 주변장치의 속도 차이 때문에 상태 flag 무한대기는 생략할 수 없다. 이런 통신 오류를 디버깅할 때는 '어느 시점에 어떤 byte가 유실됐는가'를 송신·수신 timeline으로 맞춰보며 따라가는 것이 핵심이다.

#### Protocol analyzer로 UART frame 확인

trigger로 잡은 UART 파형은 Logic 2의 protocol analyzer로 decode할 수 있다. Async Serial analyzer를 추가하고 대상 channel과 함께 signal 설정과 동일한 값(baud `115200`, data 8bit, stop 1bit, parity 없음)을 지정하면, start/data/stop 구간 위에 해석된 byte 값이 표시된다. code가 보낸 문자와 선 위의 frame이 실제로 일치하는지 이 표시로 대조한다.

### 줄바꿈 `\n`과 CR/LF

terminal에서 줄바꿈은 실제로 두 글자다. CR(`0x0D`, carriage return)은 커서를 줄 맨 앞으로 되돌리고, LF(`0x0A`, line feed)는 커서를 한 줄 아래로 내린다. C 문자열의 `'\n'` 하나로 줄바꿈이 보이게 하려면 송신 함수가 `'\n'`을 만났을 때 `0x0D`를 먼저 보내고 이어서 `0x0A`를 보내야 한다. `Uart1_Send_Byte()`가 `data == '\n'`일 때 `0x0D`를 추가 전송하는 이유가 이것이다.

### Send 함수 계층과 printf retargeting

1 byte 전송의 표준형은 '`TXE`가 설 때까지 대기 후 `DR` write'다. 문자열 전송은 NUL 종료까지 `Send_Byte()`를 반복하는 `Send_String()`으로 그 위에 쌓는다. UART printf는 이렇게 byte마다 flag를 확인하며 한 글자씩 나가는 매우 느린 함수이므로, debug 용도로 넣은 출력은 debug가 끝나면 제거하는 것이 맞다.

bare-metal에는 표준 출력 장치가 없으므로 printf는 원래 동작하지 않는다. 실습에서 printf가 동작하는 이유는 `runtime.c`가 C library의 `_write()`를 구현해 두었기 때문이다. printf는 내부에서 형식화를 마친 뒤 약속된 signature의 `_write(file, ptr, len)`을 부르고, 이 구현이 길이만큼 UART 송신 함수를 호출해 USART2로 내보낸다. 표준 함수의 하부 hook을 내 장치 code로 채우는 이 작업을 library retargeting이라 부른다.

| 표준 함수 | 구현할 hook | 역할 |
| :--- | :--- | :--- |
| `printf` | `_write()` | 형식화된 문자열을 장치로 출력 |
| `scanf` | `_read()` | 장치에서 입력을 받아 반환 |
| `malloc` | heap hook (`_sbrk` 계열) | heap 공간 관리 제공 |

같은 방법으로 `_write`가 다른 장치 전송 함수를 부르게 하면 LCD printf처럼 원하는 장치로 출력하는 printf 계열 함수를 만들 수 있다.

### 가변인자와 `Uart1_Printf` 구성

`printf(const char *format, ...)`의 `...`는 개수와 타입이 정해지지 않은 인자를 받는 가변인자 선언이다. 함수는 인자가 몇 개 왔는지 스스로 알 수 없으므로, printf는 format 문자열의 `%` 지정자를 해석하며 다음 인자를 어떤 타입으로 꺼낼지 결정한다. format이 곧 인자 목록의 설계도다.

`<stdarg.h>`가 제공하는 도구는 네 가지다.

```c
va_list ap;              /* 가변인자 순회 커서 */
va_start(ap, fmt);       /* 마지막 이름 있는 인자 다음부터 시작 */
x = va_arg(ap, int);     /* 현재 위치에서 해당 타입으로 꺼내고 전진 */
va_end(ap);              /* 순회 종료 */
```

`va_list`의 실제 타입은 compiler마다 다르다. C 표준은 가변인자의 내부 처리 방식을 규정하지 않으므로, 구조체든 `char *`든 compiler가 정의한 타입을 그대로 쓰고 임의 타입으로 바꾸지 않는다. `...`는 항상 매개변수 목록의 마지막에 오고, `va_start`의 두 번째 인자는 `...` 바로 앞의 이름 있는 인자다. LCD printf처럼 고정 인자(좌표, 색상 등)가 여러 개라면 그 전부가 `...` 앞에 온다.

개수를 전달하는 기준만 다를 뿐 원리는 printf와 같다는 것을 보여주는 최소 예제다.

```c
int Sum(int count, ...)
{
    va_list ap;
    int total = 0;

    va_start(ap, count);
    for (int i = 0; i < count; i++)
        total += va_arg(ap, int);
    va_end(ap);

    return total;
}

Sum(3, 10, 20, 30);   /* 60 */
```

`Sum`은 이름 있는 인자 `count`로 개수를 전달받고, printf는 format 파싱으로 개수와 타입을 알아낸다. 가변인자의 해석 기준을 별도 경로로 함께 전달해야 한다는 원리는 동일하다.

표준 formatting 함수에는 `va_list`를 직접 받는 `v` 변형(`vprintf`, `vsprintf`, `vsnprintf`)이 있어, 받은 가변인자를 그대로 위임할 수 있다. UART 전용 printf는 이 조합으로 만든다.

```c
void Uart1_Printf(const char *fmt, ...)
{
    char buf[128];
    va_list ap;

    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);   /* 형식화는 library에 위임 */
    va_end(ap);

    Uart1_Send_String(buf);                 /* 전송만 장치 함수로 */
}
```

`_write()` retargeting이 표준 printf 전체를 한 장치로 가로채는 방식이라면, 이 방식은 장치별 wrapper 함수를 추가하는 방식이다. 마지막 전송 함수만 바꾸면 LCD 등 임의 장치용 printf를 만들 수 있다. 수업 구현은 UART1 쪽에 PC 연결 커넥터가 없어 ST-Link virtual COM port로 이어지는 USART2 전송 함수를 마지막 단계에 연결한다.

가변인자 사용 시 주의할 점:

- format 지정자와 실제 인자 타입이 다르면 undefined behavior다. `-Wall`이면 컴파일러가 경고한다.
- 가변인자는 기본 승격을 거쳐 전달된다. `char`·`short`는 `int`로, `float`는 `double`로 승격되므로 `va_arg`도 `int`/`double`로 꺼내야 한다. `%f`가 double 기준인 이유이고, newlib nano에서 float 형식화를 쓰려고 Makefile에 `-u _printf_float`를 지정하는 것과 연결된다.
- `va_end` 생략이나 `va_list` 재사용은 이식성 문제를 만든다. 두 번 순회하려면 `va_copy`를 쓴다.

### 문자열 조립과 명령 파싱 - sprintf, sscanf, strcmp

C에는 Python 같은 문자열 `+` 연결이 없다. 변수 값과 문자열을 조합해 새 문자열을 만들 때는 `sprintf`로 형식화 결과를 buffer에 담는다.

```c
char buf[32];
sprintf(buf, "%d %c hello %f\n", 100, 'A', 3.14);   /* 표준 출력 대신 buf에 저장 */
```

반대 방향이 `sscanf`다. 문자열 buffer에서 format 기준으로 값을 추출하며, UART로 enter까지 받아 둔 명령 문자열을 토큰으로 분리할 때 쓴다.

```c
char a[10], b[10];
int num;

sscanf(buf, "%s %s %d", a, b, &num);   /* "LED ON 1" -> a="LED", b="ON", num=1 */
```

분리한 토큰은 `==`로 비교할 수 없고 `strcmp`로 비교한다. 완전히 같으면 `0`, 사전순으로 앞 문자열이 크면 양수, 뒤가 크면 음수를 반환하므로 일치 판정은 `== 0`으로 쓴다.

```c
if (strcmp(a, "LED") == 0)
{
    /* LED 명령 분기 */
}
```

수신 buffer 채우기 -> `sscanf` 토큰 분리 -> `strcmp` 분기 -> 장치 제어가 UART 명령 처리기의 기본 뼈대다. 명령 체계는 `1`, `2` 같은 숫자 코드보다 `LED ON 1`처럼 읽히는 문자 명령으로 설계한다.

## 11과 - Timer 제어

### 시간·event·data를 만드는 peripheral의 공통 구조

11~15과는 서로 다른 기능을 다루지만 모두 'hardware가 CPU와 무관하게 상태를 바꾸고, CPU는 register와 flag를 통해 그 변화를 관찰하거나 설정한다'는 구조를 공유한다. timer는 counter가 변하고, UART·I2C·SPI는 shift register가 변하고, ADC는 conversion result가 변한다. 이 때문에 6과의 `volatile`과 7과의 bit mask가 뒤의 모든 driver에 다시 등장함.

```text
configuration register  -> hardware 동작 조건 설정
data/counter register   -> 현재 data 또는 진행 상태
status flag             -> 완료·오류·새 event 표시
enable bit / NVIC       -> polling 또는 interrupt 처리 선택
```

polling은 main loop가 status flag를 읽는 방식이고, interrupt는 status flag가 set될 때 hardware가 handler를 호출하는 방식이다. 어느 쪽이든 flag를 언제 clear하는지, data를 어떤 순서로 read/write하는지가 peripheral driver의 핵심이 됨.

timer의 본질은 counter다. 일정한 주기의 clock pulse를 세면 '개수 x 주기 = 시간'이 되므로, 시간을 재는 장치는 결국 정해진 속도로 들어오는 pulse의 개수를 세는 장치다.

### SysTick Timer

`SysTick`은 제조사가 만든 주변장치가 아니라 Cortex-M core 자체에 포함된 24bit down counter다. RTOS의 scheduling tick 발생용으로 core에 표준 장착되어 있으며, 그래서 출력 채널이나 PWM 같은 부가 기능 없이 구조가 단순하다. 간단한 지연 시간 측정이나 timeout 확인용 범용 timer로도 사용할 수 있음.

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

#### Polling과 interrupt는 같은 event를 다르게 처리하는 방식

counter가 `0`에 도달했다는 하드웨어 event 자체는 같다. polling은 main loop가 `COUNTFLAG`를 반복해서 읽어 event를 발견하고, interrupt는 hardware가 CPU 실행을 잠시 멈춘 뒤 handler를 호출해 event를 알린다.

```text
polling:   main -> flag read -> main -> flag read -> event 발견
interrupt: main 실행 중 -> timer event -> NVIC -> ISR 실행 -> main 복귀
```

polling은 흐름이 단순하고 짧은 delay에 편하지만 CPU가 계속 flag를 확인한다. interrupt는 CPU가 다른 일을 하다가 event가 올 때만 처리할 수 있어 주기 작업과 입력 반응에 유리하다. interrupt handler는 짧게 끝내고, 오래 걸리는 작업은 flag를 main loop에 전달하는 구조가 안전함.

#### SysTick library 설계

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

`LOAD` 계산은 단위로 유도하면 외울 필요가 없다. `HCLK/8`은 1초당 pulse 수이므로 1000으로 나누면 1ms당 pulse 수가 되고, 여기에 원하는 ms를 곱하면 필요한 count가 된다.

```text
LOAD = (HCLK / 8 / 1000) * msec = (HCLK / 8000.) * msec
```

계산식에서 한쪽을 `8000.`처럼 실수로 두는 이유는 정수 나눗셈으로 소수부가 잘려나가는 것을 막기 위해서이고, 최종 값만 정수로 변환해 register에 쓴다. 또 `CTRL`을 전부 0으로 만들 때도 그냥 `0`을 쓰기보다 `(0 << 2) | (0 << 1) | (0 << 0)`처럼 어떤 bit를 0으로 두는지 보이게 쓰면 설정 의도가 code에 남는다.

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

경과 시간 실측은 down counter를 거꾸로 읽는다. delay loop처럼 소요 시간을 모르는 구간을 감쌀 때 쓴다.

```text
elapsed_ms = (SysTick_Get_Load_Time() - SysTick_Get_Time()) / 12000
```

실습은 1000ms tick으로 LED를 1초마다 반전시키고 점을 출력하는 구조로 확인한다. 대충 잡은 delay loop가 아니라 원하는 시간 간격으로 작업을 나눌 수 있게 된다는 것이 이 library의 목적이다.

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

#### Timer period를 식으로 설계하기

timer는 '몇 초를 기다린다'는 명령을 직접 이해하지 않는다. timer input clock을 prescaler로 나눈 counter tick과, counter가 몇 tick을 셀지를 `ARR`로 정해 시간으로 바꾼다.

```text
fCNT    = fTIM / (PSC + 1)
Ttick   = 1 / fCNT
Tperiod = (ARR + 1) * Ttick
        = (PSC + 1) * (ARR + 1) / fTIM
```

예를 들어 `fTIM = 96MHz`, `PSC = 9599`이면 `fCNT = 10kHz`, 즉 한 tick은 `100µs`다. `ARR = 9999`이면 `10000 * 100µs = 1s`마다 update event가 발생한다. `PSC`와 `ARR`에 `-1` 관계가 생기는 것은 register에 '나눌 값'이나 '셀 횟수'가 아니라, 0부터 시작하는 count의 마지막 값을 저장하기 때문임.

timer clock `fTIM`은 단순히 `PCLK`와 항상 같다고 가정하면 안 된다. STM32F4의 APB timer clock은 APB prescaler가 1이면 `PCLK`와 같지만, prescaler가 1이 아니면 `PCLK`의 2배가 된다. 이 실습의 clock 설정은 APB1 prescaler 2, `PCLK1 = 48MHz`이므로 APB1 timer(TIM2~TIM5)의 입력 clock은 `48MHz * 2 = 96MHz`다. `PSC` 계산은 이 96MHz를 기준으로 한다.

`CR1` 설정에서 down counter 실습은 `DIR = 1`(down), `ARPE = 0`을 기본으로 둔다. one-pulse는 `OPM = 1`(timeout 시 `CEN` 자동 clear), repeat는 `OPM = 0`이다.

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

PWM은 embedded 제품 전반에서 아날로그 양을 조절하는 표준 수단이다.

| 응용 | PWM이 하는 일 |
| :--- | :--- |
| noise에 강한 신호 전달 | 전압 크기 대신 duty 비율로 값 표현, 전압이 흔들려도 duty는 유지 |
| LCD backlight, LED 밝기 | duty로 평균 전류 조절 |
| SMPS, DC-DC converter | switching duty로 출력 전압 제어 |
| motor, dimmer | 평균 전력 조절 |
| 간이 DAC | PWM 출력에 low-pass filter를 걸어 평균 전압을 아날로그로 사용 |

실습에서는 `PB0`의 `TIM3_CH3`를 buzzer 구동에 사용한다. 음계별 frequency를 `PSC`, `ARR`, `CCR` 설정으로 만들고, duty는 보통 50%로 둔다.

음계 주파수는 12평균율을 따른다. 기준 도(`261Hz`)에서 반음마다 `2^(1/12)`배씩 올라가므로, N번째 반음의 주파수는 `261 * 2^(N/12)`이고 한 옥타브 위는 정확히 2배다.

| 음계 예시 | 주파수 |
| :--- | :--- |
| 낮은 도 | 약 `130Hz` |
| 도 | 약 `261Hz` |
| 레 | 약 `293Hz` |
| 높은 도 | 약 `523Hz` |
| 높은 시 | 약 `987Hz` |

timer 주파수 선택에는 제약이 있다. `ARR`은 16bit라 최대 `65,535`펄스이므로, 가장 낮은 음(`130Hz`)의 한 주기에 필요한 펄스 수가 이 한계를 넘지 않는 범위에서 timer 입력 주파수를 정하고, 그 주파수가 나오도록 `PSC`를 설정한다. 주파수가 높을수록 음정 분해능은 좋아지지만 낮은 음이 `ARR` 범위를 벗어나기 쉽다.
