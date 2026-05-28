# 26-05-28 - pipeline, memory map, APB 확장 방향

multi-cycle CPU 다음 단계에서는 pipeline으로 갈 때 생기는 문제와 CPU가 memory/peripheral을 주소 공간 안에 배치하는 구조를 함께 봐야 한다.
핵심은 CPU 내부 실행 단계만 보는 데서 멈추지 않고, `주소 -> memory map -> address decoder -> bus -> peripheral`까지 이어서 보는 것이다.

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | pipeline 개념, memory map, address decoding, APB/peripheral 연결 |
| 이전 연결 | `0527`의 RV32I multi-cycle state 분할 |
| 다음 연결 | `0529`의 APB Master/Slave와 transfer phase 상세 |
| 참고 관점 | STM32F103xx 같은 MCU 구조는 CPU, memory, bus, peripheral이 한 chip 안에 묶인 예시 |

## CPU 실행 방식 비교

| 구조 | 실행 방식 | 읽을 포인트 |
| --- | --- | --- |
| `single-cycle` | instruction 하나를 한 clock 안에서 완료 | 가장 긴 경로가 clock period를 결정 |
| `multi-cycle` | instruction 하나를 여러 state/cycle로 나눠 처리 | cycle당 일이 줄지만 instruction당 cycle 수는 늘어남 |
| `pipeline` | 여러 instruction을 서로 다른 stage에서 겹쳐 실행 | throughput은 좋아지지만 hazard 처리가 필요 |

`800ps -> 200ps` 같은 숫자는 pipeline stage를 이상적으로 나눴을 때의 감각으로 보면 된다.
실제 성능은 stage 균형, register overhead, memory latency, hazard stall에 따라 달라진다.

## pipeline을 multi-cycle과 구분해서 보기

pipeline stage 이름은 multi-cycle state 이름과 비슷하다.

```text
IF  -> instruction fetch
ID  -> decode / register read
EX  -> ALU / branch target 계산
MEM -> data memory 접근
WB  -> register write-back
```

하지만 동작 방식은 다르다.

| 구분 | multi-cycle | pipeline |
| --- | --- | --- |
| 한 시점에 처리 중인 instruction | 기본적으로 하나 | 여러 개 |
| stage register | 다음 cycle로 값을 넘기기 위해 사용 | 서로 다른 instruction 사이 stage 경계 역할 |
| 성능 목표 | 긴 combinational path를 나눔 | instruction throughput 증가 |
| 어려운 점 | state별 제어 신호 정리 | hazard, flush, stall, forwarding |

즉 `stage로 나눈다`는 말만 보고 multi-cycle과 pipeline을 같은 구조로 보면 안 된다.

## pipeline에서 생기는 문제

pipeline으로 넘어가면 다음 문제가 생긴다.

| 문제 | 의미 | 예시 처리 |
| --- | --- | --- |
| structural hazard | 같은 hardware 자원을 동시에 요구 | instruction/data memory 분리, stall |
| data hazard | 앞 instruction 결과가 아직 write-back되지 않았는데 뒤 instruction이 사용 | forwarding, bubble |
| load-use hazard | load 결과가 MEM 이후에야 나오는데 다음 instruction이 바로 사용 | 1-cycle stall 또는 forwarding |
| control hazard | branch/jump target이 확정되기 전에 다음 instruction을 fetch | flush, stall, branch prediction |

branch predictor가 필요한 이유도 여기에 있다.
branch 결과가 `EX` 단계쯤 확정된다면, 그 전까지 가져온 instruction이 맞는 경로인지 알 수 없다. 예측이 맞으면 계속 진행하고, 틀리면 잘못 가져온 instruction을 버리고 다시 fetch해야 한다.

## memory map이 필요한 이유

CPU는 address를 내보내지만, 그 address가 RAM인지 GPIO인지 UART인지 CPU 혼자 자동으로 알지 않는다.
시스템은 address range를 나눠 각 영역에 의미를 부여한다.

| 영역 | 의미 |
| --- | --- |
| ROM / Flash | instruction 또는 program image 저장 |
| RAM / SRAM | stack, 전역 변수, 임시 data 저장 |
| GPIO | 외부 핀 입출력 register |
| Timer / UART / FND 등 | peripheral 제어 register |

이렇게 address 공간 안에 memory와 peripheral register를 함께 배치하는 방식을 memory-mapped I/O 관점으로 볼 수 있다.
software 입장에서는 특정 주소에 `load/store`를 수행하지만, hardware 입장에서는 그 주소가 어느 slave를 선택하는지 decoding해야 한다.

## address decoding과 chip select

address decoder는 CPU address의 상위 비트 또는 특정 범위를 보고 어느 장치를 선택할지 결정한다.

| CPU address 범위 예시 | 선택 대상 | 의미 |
| --- | --- | --- |
| `0x0000_0000 ...` | ROM / instruction memory | program code |
| `0x1000_0000 ...` | RAM | data memory |
| `0x2000_0000 ...` | GPIO / FND | memory-mapped peripheral |
| `0x3000_0000 ...` | UART 등 | 느린 peripheral |

실제 주소 범위는 설계마다 달라질 수 있다.
중요한 것은 `address -> decoder -> chip select` 흐름이다. 하나의 CPU address bus에서 여러 장치를 연결하려면, 특정 cycle에 어떤 장치만 응답해야 하는지 선택해야 한다.

`address_decoder` 구현도 이 관점을 따른다.
RAM은 `0x1000_0000`부터 `0x1000_0FFF`까지 하나의 range로 묶고, peripheral 영역은 `0x2000_0000`부터 `0x2000_0FFF`까지 잡은 뒤 `PADDR[15:12]`로 GPO/GPI/GPIO/reserve를 나눈다.
이처럼 base range를 먼저 나누고 그 안에서 sub-select를 만들면 실제 사용하는 register가 적어도 decode가 단순해지고 확장 공간도 남길 수 있다.

## APB로 이어지는 이유

peripheral이 많아지면 CPU가 모든 장치의 세부 신호를 직접 다루기 어렵다.
그래서 CPU 쪽 요청을 bus protocol로 바꾸는 계층이 필요하다.

```text
CPU request
-> address decoding
-> APB Master
-> APB Slave
-> RAM / GPIO / FND / UART / Timer
```

APB는 ARM AMBA 계열에서 peripheral 접근에 많이 쓰는 단순 버스다.
고속 memory path보다는 GPIO, UART, Timer처럼 상대적으로 느린 register 기반 peripheral 접근에 어울린다.

여기서 중요한 점은 peripheral이 CPU bus에 자기 임의 신호로 바로 붙는 것이 아니라는 것이다.
FND, GPIO, UART 같은 블록도 bus protocol을 해석하는 slave wrapper를 통해 연결된다.

| 위치 | 역할 |
| --- | --- |
| APB Master | CPU 쪽 request를 APB 신호로 변환 |
| APB Slave wrapper | `PSEL`, `PENABLE`, `PWRITE`, `PADDR`, `PWDATA`를 peripheral 내부 제어로 변환 |
| Peripheral core | 실제 FND, GPIO, UART, Timer register 동작 수행 |

즉 peripheral이 하나 늘어난다는 것은 단순히 RTL 블록 하나를 옆에 붙이는 것이 아니라, 그 블록을 memory-mapped bus 규칙으로 감싸는 slave interface가 하나 더 필요하다는 뜻이다.

## APB에서 먼저 기억할 신호

| 신호 | 방향 | 의미 |
| --- | --- | --- |
| `PADDR` | Master -> Slave | 접근 주소 |
| `PWRITE` | Master -> Slave | write/read 구분 |
| `PSEL` | Master -> Slave | 특정 slave 선택 |
| `PENABLE` | Master -> Slave | access phase 진입 |
| `PWDATA` | Master -> Slave | write data |
| `PRDATA` | Slave -> Master | read data |
| `PREADY` | Slave -> Master | transfer 완료 가능 |

`PSEL`은 chip select와 비슷하게 보면 된다.
`PENABLE`은 setup이 끝나고 실제 access phase에 들어갔다는 표시다.
`PREADY`가 0이면 slave가 아직 준비되지 않은 것이므로 wait state가 생긴다.

## STM32F103xx를 참고 구조로 보는 법

STM32F103xx 같은 MCU는 Cortex-M3 CPU, Flash, SRAM, interrupt controller, DMA, timer, USART, SPI, I2C, ADC 같은 peripheral을 한 chip 안에 묶은 구조다.
이 예시는 현재 RV32I 학습용 구현과 같은 구현체라는 뜻이 아니라, 실제 MCU에서도 CPU가 memory map과 bus를 통해 peripheral을 제어한다는 참고 구조로 보면 된다.

| 관점 | STM32에서 보이는 것 | 수업 RV32I와 연결 |
| --- | --- | --- |
| program memory | Flash | instruction memory / ROM |
| data memory | SRAM | data memory / stack |
| peripheral | GPIO, USART, TIM, ADC | memory-mapped I/O |
| bus | AHB/APB 계층 | APB Master/Slave 학습으로 연결 |

## 0529로 이어지는 포인트

0528은 APB를 쓰는 이유와 system memory map을 잡는 단계다.
0529에서는 APB 자체의 transfer timing을 더 자세히 본다.

| 0528에서 잡을 것 | 0529에서 이어질 것 |
| --- | --- |
| CPU address가 특정 장치를 선택한다 | `PSEL` 생성과 address decoding |
| peripheral 접근은 bus protocol로 감싼다 | APB Master/Slave 역할 |
| 느린 slave는 대기할 수 있다 | `PREADY`와 wait state |
| read/write는 같은 bus에서 구분된다 | `PWRITE`, `PWDATA`, `PRDATA` |

## 핵심 정리

CPU 구조 학습은 datapath/control에서 끝나지 않는다.
프로그램이 커지고 peripheral이 붙으면, CPU가 내보낸 address를 system memory map으로 해석하고 bus protocol을 통해 각 장치에 연결하는 구조까지 같이 봐야 한다.

## 연결 노트

- [[260527-rv32i-multicycle]]
- [[260529-apb-master-slave]]
- [[260514-cpu-구조]]
