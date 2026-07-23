# 26-07-23 - 16과 DMA·Software Trigger

관련 노트:

- [26-07-23 - 15과 ADC·Sensor Interface](260723-adc-sensor-interface.md)
- [26-07-21 - Startup·Interrupt·Event-Driven Firmware](260721-interrupt-event-driven.md)
- [16과 DMA source](../helloEmbedded/1601.DMA_SW/) · [active `main.c`](../helloEmbedded/1601.DMA_SW/main.c) · [DMA driver](../helloEmbedded/1601.DMA_SW/dma.c) · [DMA ISR](../helloEmbedded/1601.DMA_SW/exception.c) · [`printf` UART retarget](../helloEmbedded/1601.DMA_SW/runtime.c) · [UART driver](../helloEmbedded/1601.DMA_SW/uart.c) · [register wrapper](../helloEmbedded/1601.DMA_SW/device_driver.h) · [device header](../helloEmbedded/1601.DMA_SW/stm32f411xe.h)

## 수업 범위

| 구분 | 주제 | 실습 source의 위치 |
| :--- | :--- | :--- |
| 16과 앞부분 | STM32F4 DMA controller, stream·channel, FIFO, 전송 단위·주소 증가 | `main.c` active `#if 1`, `dma.c` |
| 16과 M2M | software trigger로 SRAM array를 DMA2가 복사하고 완료 interrupt를 main에 전달 | `DMA2_Stream0_IRQHandler()` |
| 16과 M2P | USART2 TX request를 hardware trigger로 사용해 memory 문자열을 UART data register에 전달 | `main.c`의 `#if 0` M2P block, `DMA1_Stream6_*()` |

## DMA가 하는 일

`DMA`는 CPU가 data를 한 단위씩 load/store하는 대신, CPU가 먼저 설정한 주소·방향·전송 개수에 따라 DMA controller가 system bus를 사용해 data를 이동하는 MCU peripheral이다.

```text
CPU
  │  register 설정: source, destination, count, direction, mode
  v
DMA controller ────────────────┐
  │                             │
  ├─ memory-to-memory           ├─ source data
  ├─ memory-to-peripheral       └─ destination data
  └─ peripheral-to-memory
  │
  └─ transfer complete / error interrupt
                 │
                 v
             ISR flag → main loop의 다음 작업
```

DMA가 data를 옮기는 동안에도 CPU는 다른 instruction을 실행할 수 있다. 다만 CPU와 DMA가 같은 bus·memory·peripheral에 접근하면 arbitration이 일어나므로, DMA가 CPU를 완전히 공짜로 만드는 기능은 아니다. 큰 buffer를 반복 복사하거나 peripheral event마다 data를 옮길 때 CPU의 polling·copy 부담을 크게 줄인다.

### STM32F1 계열과 STM32F4 계열의 controller 구조

수업의 비교 대상은 CPU core 자체보다 MCU에 통합된 DMA controller 구조다. STM32F1 계열의 단순 DMA는 주로 channel 단위로 선택한다. STM32F411이 속한 STM32F4 계열의 DMA는 `DMA1`·`DMA2` controller 아래에 각각 stream `0`~`7`이 있고, 각 stream에서 channel selection을 한다.

```text
STM32F411
├─ DMA1
│   └─ Stream 0 ... Stream 7
└─ DMA2
    └─ Stream 0 ... Stream 7
         └─ CHSEL: 연결할 peripheral request 선택
```

hardware-triggered transfer에서는 peripheral마다 가능한 DMA controller·stream·channel 조합이 정해져 있으므로 reference manual의 request mapping table을 확인해야 한다. 이 수업의 USART2 TX 예제는 `DMA1 Stream6 + Channel4` 조합을 사용한다. M2M active 실습은 `DMA2 Stream0 + Channel0`을 사용한다.

### F1 예제와 F4 실습의 register 이름 구분

수업 화면의 STM32F1 예제는 channel 기반 DMA를 설명한다. 현재 `STM32F411` 실습 source는 F4의 stream 기반 DMA register를 사용한다. DMA의 역할은 같아도 source에서 접근하는 register 이름과 interrupt flag 위치가 달라진다.

| 설정 목적 | STM32F1 channel 예제 | STM32F411 stream 실습 | 현재 source에서 볼 위치 |
| :--- | :--- | :--- | :--- |
| 전송 설정 | `DMA_CCRx` | `DMA_SxCR` | `DMA2_STREAM[stream]->CR`, `DMA1_Stream6->CR` |
| 전송 개수 | `DMA_CNDTRx` | `DMA_SxNDTR` | `->NDTR` |
| peripheral side address | `DMA_CPARx` | `DMA_SxPAR` | `->PAR` |
| memory address | `DMA_CMARx` | `DMA_SxM0AR` | `->M0AR` |
| FIFO 설정 | 별도 FIFO register 없음 | `DMA_SxFCR` | `->FCR` |
| 완료·error flag | `DMA_ISR` 확인, `DMA_IFCR` clear | `DMA_LISR`·`DMA_HISR` 확인, `DMA_LIFCR`·`DMA_HIFCR` clear | Stream0은 `LISR`·`LIFCR`, Stream6은 `HISR`·`HIFCR` |

F1 예제의 `DMA1_CH[ch - 1]->CCR` 접근은 F1 channel project에 맞는 형태다. `STM32F411`의 M2M 실습은 `DMA2_STREAM[stream]->CR`과 stream별 `NDTR`·`PAR`·`M0AR`·`FCR`을 설정한다. M2P UART 실습은 `DMA1_Stream6`의 같은 register 묶음을 사용한다.

## DMA 전송을 위한 다섯 가지 결정

| 결정 | register·설정 | 의미 | M2M 실습값 |
| :--- | :--- | :--- | :--- |
| 방향 | `DIR` | `P2M`, `M2P`, `M2M` 중 data 흐름 | `M2M` |
| 시작 주소 | `PAR`, `M0AR` | peripheral side와 memory side address | `src1_dat` → `PAR`, `dst1_dat` → `M0AR` |
| 전송 횟수 | `NDTR` | 전송 unit의 개수 | `40` |
| 한 unit의 크기 | `PSIZE`, `MSIZE` | 8/16/32bit unit | 둘 다 32bit |
| 주소 mode | `PINC`, `MINC` | 각 unit 뒤 해당 address를 증가할지 고정할지 | 둘 다 increment |

`NDTR = 40`은 40byte가 아니다. active M2M 실습은 `unsigned int` array를 쓰고 `PSIZE = MSIZE = 32bit`로 설정하므로, 32bit unit 40개, 즉 총 `160byte`를 전송한다.

M2M mode에서는 source address가 `PAR`, destination address가 `M0AR`에 놓인다. 이름에 `P`와 `M`이 남아 있어도, `DIR = M2M`일 때에는 controller의 peripheral side port가 source 역할을 맡는 register naming이다. 그래서 source와 destination을 뒤집어 전달하면 copy 방향도 뒤집힌다.

### `NDTR`은 설정값이면서 진행 상태다

`DMA_SxNDTR.NDT[15:0]`에는 전송할 data unit 수를 `0`~`65535` 범위로 설정한다. stream이 disable된 동안 write할 수 있고, enable된 뒤에는 read-only로 남은 unit 수를 나타낸다. DMA가 한 unit을 옮길 때마다 값이 하나씩 감소하며, normal mode의 완료 시점에는 `0`이 된다.

따라서 non-circular transfer를 다시 시작하는 순서는 `EN = 0` 확인 → 주소와 `NDTR` 설정 → 이전 flag clear → `EN = 1`이다. active M2M driver와 `DMA1_Stream6_Start()`가 이 순서로 동작한다. 실행 중 `NDTR`을 읽으면 남은 전송량을 확인할 수 있다.

### increment·fixed mode

```text
M2M array copy
src[0] → dst[0]
src[1] → dst[1]
src[2] → dst[2]
  └─ source와 destination 모두 increment

UART TX
text[0] → USART2->DR
text[1] → USART2->DR
text[2] → USART2->DR
  └─ memory는 increment, USART2->DR는 fixed

UART RX
USART2->DR → rx_buffer[0]
USART2->DR → rx_buffer[1]
USART2->DR → rx_buffer[2]
  └─ peripheral은 fixed, memory는 increment
```

## M2M Software Trigger 실습

active `#if 1` block은 `src1_dat[i] = i + 8`로 `8`~`47`을 채우고, `dst1_dat`은 `0`으로 초기화한다. CPU의 `for` copy loop를 쓰지 않고 DMA2가 `src1_dat`에서 `dst1_dat`으로 40개 unit을 옮긴다.

```text
`main.c`

src1_dat / dst1_dat 초기화
        ↓
`scr1`에 M2M·increment·32bit·non-circular 설정
        ↓
`DMA2_Stream_Init(0, src1_dat, dst1_dat, scr1, 40)`
        ↓
`DMA2_ISR_Enable(0, 0, 0, 1)`
        ↓
`DMA2_Start(0)` = software trigger
        ↓
DMA2 Stream0 transfer complete
        ↓
`DMA2_Stream0_IRQHandler()`가 flag clear 후 `DMA2_STREAM_DONE[0] = 1`
        ↓
main loop가 flag를 확인하고 `dst1_dat[0..39]` 출력
```

### 왜 `DMA2`와 FIFO를 사용하는가

STM32F411의 M2M transfer는 DMA2가 담당한다. DMA1 controller의 AHB peripheral port는 bus matrix에 연결되지 않고, DMA2 controller의 AHB peripheral port는 bus matrix에 연결된다. 이 구조 때문에 STM32F411에서는 DMA2 stream만 M2M transfer를 수행할 수 있다.

active driver는 `RCC->AHB1ENR`의 DMA2 clock을 켜고, stream을 disable한 뒤 source·destination·`NDTR`·`CR`을 설정한다.

```c
DMA2_STREAM[stream]->PAR  = (uint32_t)src_addr;
DMA2_STREAM[stream]->M0AR = (uint32_t)dst_addr;
DMA2_STREAM[stream]->NDTR = num_data;
DMA2_STREAM[stream]->CR   = scr1.ui_data;
DMA2_STREAM[stream]->FCR |= (1UL << 2) | (3UL << 0);
```

마지막 줄은 `DMDIS = 1`로 direct mode를 끄고, FIFO threshold를 full로 설정한다. STM32F411 M2M transfer는 FIFO mode를 사용하며 circular mode도 사용할 수 없다. 따라서 active code의 `circ = DMA_CIRCULAR_DIS`와 FIFO 설정은 M2M 조건에 맞는다.

### software trigger와 hardware trigger

M2M에는 data가 들어오는 external peripheral event가 없으므로 CPU가 준비가 끝난 시점에 `DMA2_Start()`로 `CR.EN`을 set한다. 이 호출이 software trigger다.

```text
software trigger
CPU가 `DMA2_Start()` 호출
    ↓
DMA2 Stream EN = 1
    ↓
DMA2가 설정한 40개 unit 전송
```

반대로 UART TX처럼 peripheral의 상태 변화가 data 이동 시점을 결정하는 경우에는 peripheral request가 hardware trigger가 된다. CPU는 transfer를 한 번 설정하고 stream을 enable한다. 이후 USART TX data register가 비어 request를 낼 때마다 DMA가 다음 byte를 넣는다.

```text
hardware trigger: USART2 TX
memory buffer → DMA1 Stream6 → USART2->DR → serial line
                    ↑
          USART2 TX request
```

## interrupt와 main의 역할 분리

`DMA2_Stream0_IRQHandler()`는 `LISR`의 `TCIF0`를 확인하고 `LIFCR`에 `0x3D`를 써서 stream0의 완료·half·transfer error·direct mode error·FIFO error flag를 clear한다. 그 다음 `volatile int DMA2_STREAM_DONE[8]`의 0번을 `1`로 설정한다.

ISR은 짧게 끝내고, `printf`와 data 검증은 main loop에서 한다. 이는 12과의 timer interrupt와 같은 구조다.

```c
if (DMA2_STREAM_DONE[STREAM])
{
    /* main context에서 결과 출력·검증 */
    DMA2_STREAM_DONE[STREAM] = 0;
}
```

현재 active path는 `DMA2_STREAM_DONE[]`로 완료를 전달한다. `dma.c`의 `DMA_STATUS[]`는 driver 내부 상태용 배열이지만, 이 M2M ISR은 그 배열을 `COMPLETE`로 갱신하지 않는다. 두 상태 전달 방식을 하나의 설계에서 섞어 읽지 않도록 구분한다.

### 확인할 결과와 error 진단

정상 M2M 결과는 `dst1_dat[0] = 8`부터 `dst1_dat[39] = 47`까지다. `NDTR`이 `0`이 되고 `TCIF0`가 발생한 뒤 main의 완료 flag가 `1`이 된다.

현재 ISR은 `TCIF0`가 set된 경우에만 진입 처리한다. 완료 출력이 나타나지 않을 때에는 `TEIF0`, `DMEIF0`, `FEIF0`도 함께 확인해야 한다. 실전 driver에서는 transfer error interrupt도 켜고, error flag별 원인과 recovery를 main 또는 별도 error handler로 전달한다.

## M2P UART DMA로 이어지는 부분

같은 source의 `#if 0` M2P example은 DMA1 Stream6을 USART2 TX용으로 설정한다.

| 설정 | M2M software trigger | USART2 TX hardware trigger |
| :--- | :--- | :--- |
| controller·stream | `DMA2 Stream0` | `DMA1 Stream6` |
| channel | `CHSEL = 0` | `CHSEL = 4` |
| `DIR` | `M2M` | `M2P` |
| increment | source·destination 모두 증가 | memory만 증가, `USART2->DR`는 고정 |
| trigger | `DMA2_Start()` | USART2 TX request |
| 종료 event | `TCIF0` | `TCIF6` |

M2P example은 `USART2->CR3 |= USART_CR3_DMAT`로 USART2의 TX DMA request를 허용하고, `DMA1_Stream6_Start()`가 `PAR = &USART2->DR`, `M0AR = 문자열 시작 주소`, `NDTR = 문자열 길이`를 채운 뒤 stream을 enable한다. 문자열마다 시작 주소와 길이가 달라지므로 완료 ISR flag를 받은 main이 다음 문자열의 address·length를 설정하고 다시 start한다.

### USART2 DMA request와 Stream6의 분담

DMA stream을 설정한 뒤 USART2도 DMA request를 낼 수 있게 허용한다. `USART2->CR3`의 두 bit는 송신과 수신 방향을 나눠 제어한다.

| bit | 역할 | 이 예제에서의 사용 |
| :--- | :--- | :--- |
| `DMAT` | USART transmitter가 TX DMA request를 낼 수 있게 한다 | `USART2->CR3 |= USART_CR3_DMAT` |
| `DMAR` | USART receiver가 RX DMA request를 낼 수 있게 한다 | UART RX P2M DMA를 만들 때 사용 |

현재 TX 예제의 `DMA1_Stream6_USART2_TX_Init()`은 stream을 disable한 뒤 `CHSEL = 4`, `PL = Very High`, `MINC = 1`, `DIR = M2P`, `TCIE = 1`을 설정하고 `DMA1_Stream6_IRQn`을 NVIC에 enable한다. `CHSEL = 4`가 USART2 TX request mapping을 선택하고, `TCIE`가 전송 완료를 ISR에 전달한다.

```text
USART2 TX data register empty
        ↓  TX DMA request (`DMAT = 1`)
DMA1 Stream6: memory byte → USART2->DR
        ↓  마지막 byte를 DMA가 전달
`HISR.TCIF6` set
        ↓
`DMA1_Stream6_IRQHandler()`
    → `HIFCR.CTCIF6`에 1을 써서 clear
    → `g_dma_tx_done = 1`
        ↓
main이 flag를 0으로 되돌리고 다음 문자열의 address·`strlen()`을 설정해 start
```

Stream6의 flag는 F4 DMA의 high register group인 `HISR`·`HIFCR`에 있다. 모든 문자열을 보낸 뒤 현재 M2P example은 stream의 `EN` bit를 clear한다.

DMA transfer complete는 DMA가 지정한 byte를 USART data register로 전달했다는 뜻이다. 마지막 byte가 serial line으로 완전히 shift-out됐는지는 USART의 `TC` flag로 별도 확인한다. 송신 직후 transmitter를 끄거나 half-duplex 방향을 바꾸는 경우에는 serial line이 완전히 idle이 된 `TC`를 확인한다.

## Serial Terminal ANSI·VT100 Color Output

### 색상은 terminal이 해석하는 byte stream

수업에서 말한 'ANSI color code'는 terminal 화면 효과를 위한 escape sequence다. 정확히는 ECMA-48 control sequence 중 `CSI Pm m` 형식의 `SGR`(Select Graphic Rendition)이다. MCU의 UART hardware와 DMA controller는 color라는 개념을 갖지 않고 `ESC`, `[`, 숫자, `m` byte를 순서대로 전송한다. serial terminal이 그 byte stream을 해석해 글자 색을 바꾼다.

```text
firmware `printf`
    ↓
`_write()` → `Uart2_Send_Byte()` → `USART2->DR`
    ↓
UART / USB virtual COM byte stream
    ↓
serial terminal의 ANSI·VT100 parser
    ↓
colored text pixels
```

현재 source의 polling `printf` 경로에서 `runtime.c`의 `_write()`는 모든 byte를 `Uart2_Send_Byte()`로 전달한다. `uart.c`는 `\n`일 때만 `\r`을 먼저 전송해 `\r\n`으로 만들고, `ESC`를 포함한 ANSI control byte에는 관여하지 않는다. 따라서 color sequence도 일반 text와 같은 UART byte stream으로 전달된다.

### `ESC[31m`의 구조

```text
\033[31m
 │   │ │ └─ SGR final byte: `m`
 │   │ └─── parameter: foreground red
 │   └───── 7-bit CSI의 `[` byte
 └───────── ESC, hexadecimal `0x1B`, octal `033`
```

`\033`과 `\x1B`은 모두 ESC byte를 나타낸다. 아래처럼 `\033`을 쓰면 C의 octal escape로 ESC를 명시한다. `COLOR_RESET`의 `0`은 normal rendition으로 복귀하므로, 각 message 뒤에 반드시 붙인다.

```c
#define COLOR_RESET  "\033[0m"
#define COLOR_RED    "\033[31m"
#define COLOR_GREEN  "\033[32m"
#define COLOR_YELLOW "\033[33m"
#define COLOR_BLUE   "\033[34m"

printf(COLOR_RED "[ERROR] This is a red error message!" COLOR_RESET "\n");
printf(COLOR_GREEN "[INFO] System normal." COLOR_RESET "\n");
```

`COLOR_RED "[ERROR]" COLOR_RESET`처럼 comma 없이 string literal을 이어 쓰는 것은 C의 adjacent string literal concatenation이다. compiler가 다음처럼 하나의 string literal로 합친다.

```c
"\033[31m" "[ERROR] This is a red error message!" "\033[0m" "\n"
```

| SGR parameter | foreground | 용도 예시 |
| :--- | :--- | :--- |
| `0` | reset | message 종료 |
| `31` | red | error·failure |
| `32` | green | success·normal |
| `33` | yellow | warning |
| `34` | blue | category label |
| `36` | cyan | DMA·debug label |
| `1;31` | bold red | 강조할 error |

기본 `30`~`37` foreground color만 사용하면 terminal 호환성이 좋다. 256-color와 truecolor sequence는 terminal마다 지원 범위가 다르므로 이 bare-metal UART 실습에서는 기본 8색을 우선 사용한다.

### DMA UART 전송과 줄바꿈 차이

polling `printf`는 `Uart2_Send_Byte()`를 거치므로 `\n`이 `\r\n`으로 확장된다. 반면 M2P DMA path는 `DMA1_Stream6_Start()`가 memory의 문자열을 `USART2->DR`로 직접 옮기며 `Uart2_Send_Byte()`를 거치지 않는다. DMA용 문자열에는 line ending을 `\r\n`으로 직접 넣는다.

```c
static const char *dma_log =
    "\033[36m[DMA]\033[0m transfer ready\r\n";
```

ANSI control byte도 문자열 길이에 포함된다. M2P example에서 `strlen()`으로 계산한 `NDTR`은 visible text, `ESC[36m`, `ESC[0m`, `\r`, `\n`을 모두 전송한다.

### terminal에서 확인할 조건

`screen /dev/cu.usbmodem1102 115200`은 VT100/ANSI-compatible terminal이며, 현재 macOS의 `screen` terminfo는 기본 8색 foreground와 reset sequence를 제공한다. ANSI·VT100 rendering을 지원하지 않는 serial monitor나 raw log viewer에서는 control byte가 색으로 바뀌지 않고 문자처럼 보일 수 있다.

formatting output은 diagnostic 편의 기능이다. ISR에서 color `printf`를 수행하지 않고, DMA 완료 flag를 받은 main context에서 출력한다. 이렇게 해야 ISR 지연과 UART blocking이 DMA event 처리에 섞이지 않는다.

참고:

- [ECMA-48: control functions and SGR](https://www.ecma-international.org/wp-content/uploads/ECMA-48_5th_edition_june_1991.pdf)
- [GNU Screen terminal compatibility](https://www.gnu.org/software/screen/manual/html_node/Term.html)

## 실습 실행 흐름

```text
source C / header / startup assembly
        ↓
ARM GCC cross compile·link
        ↓
ELF file
        ↓
SWD flash to STM32F411RE
        ↓
reset 후 Cortex-M4가 `Main()` 실행
        ↓
UART2 115200 baud monitor에서 결과 확인
```

현재 `1601.DMA_SW/Makefile`은 Windows ARM toolchain 경로와 `STM32_Programmer_CLI.exe`를 지정한다. macOS에서 build·flash하려면 host에 맞는 cross compiler와 STM32CubeProgrammer CLI 경로로 이 build 설정을 준비해야 한다. 이는 DMA source logic과 별개인 실행 환경 조건이다.

## 다음 연결

ADC는 `ADC1->DR`의 한 conversion result를 CPU가 polling으로 읽었다. sampling이 빠르거나 buffer를 계속 채워야 하면 `ADC EOC/DMA request → DMA P2M → circular 또는 double buffer`로 확장한다. 다음 단계에서는 peripheral request mapping, buffer ownership, transfer error 처리, double buffer를 연결해 본다.
