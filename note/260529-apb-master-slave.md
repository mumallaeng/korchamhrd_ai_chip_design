# 26-05-29 - APB Master/Slave와 CPU bus transfer

memory map과 address decoding은 실제 bus transfer로 이어진다.
CPU가 peripheral을 직접 제어하는 것이 아니라, 주소와 read/write 요청을 bus protocol 신호로 바꾸고, 선택된 Slave만 응답하게 만드는 구조를 본다.

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | CPU bus example, address decoding, APB Master/Slave, APB transfer FSM |
| 이전 연결 | `0528`의 memory map, address decoder, APB 필요성 |
| 이번 핵심 | `address -> select -> SETUP -> ACCESS -> response`로 bus transaction 읽기 |
| 추가 범위 | `APB_BRAM.sv`, `tb_apb_master.sv`, C pointer write, `li`/`sw` machine-code 흐름 |
| 남길 기준 | `PSEL`은 선택, `PENABLE`은 access phase, `PREADY`는 완료 가능 여부 |

## 전체 구조

CPU가 주변장치에 접근하는 흐름은 아래처럼 보면 된다.

```text
CPU
-> address / write data / read-write request
-> address decoder
-> APB Master
-> APB Slave
-> RAM / GPIO / FND / UART / Timer
```

| 블록 | 역할 |
| --- | --- |
| CPU | 주소, 쓰기 데이터, read/write 요청 생성 |
| Address Decoder | 주소 범위를 보고 어느 장치를 선택할지 결정 |
| APB Master | CPU 쪽 요청을 APB 신호로 변환 |
| APB Slave | APB 신호를 받아 실제 peripheral register 접근 수행 |
| Peripheral | RAM, GPIO, FND, UART, Timer 같은 제어 대상 |

CPU 입장에서는 특정 주소에 `load/store`하는 동작이다.
hardware 입장에서는 그 주소가 어느 장치의 register인지 decoding하고, bus protocol에 맞춰 전송해야 한다.

## CPU bus example에서 보이는 하드웨어 구성

원문 자료의 CPU bus 예제는 discrete chip 기반 구조를 통해 memory map과 chip select를 설명한다.

| 부품 / 블록 | 역할 |
| --- | --- |
| CPU / `U2` | address, data, control 신호를 내보내는 중심 장치 |
| ROM / `U8 27C256` | program code 저장 |
| RAM / `U3 IS62C256AL` | data 저장 |
| 8255A / `U6` | GPIO 확장용 programmable peripheral interface |
| 74LS138 | `3-to-8` address decoder, chip select 생성 |
| clock/reset 회로 | CPU 동작 기준 clock과 초기화 담당 |

이 예제에서 중요한 것은 특정 부품 번호 자체보다 `주소 해석 -> chip select -> 장치 접근` 흐름이다.
FPGA 내부 SoC로 옮겨도 같은 개념이 `address decoder`, `PSEL`, `HSEL`, peripheral select 같은 신호로 나타난다.

## 주소 버스와 제어 신호

주소와 데이터가 pin에 실리는 방식도 같은 관점으로 볼 수 있다.

| 신호 / 포트 | 의미 |
| --- | --- |
| `P0.0 ~ P0.7` | 하위 주소 `A0~A7`와 data `D0~D7`를 multiplexing해서 사용 |
| `P2.0 ~ P2.7` | 상위 주소 `A8~A15` 출력 |
| `RESET` | 시스템 초기화 |
| `WR` | 외부 memory/peripheral write 제어 |
| `RD` | 외부 memory/peripheral read 제어 |
| `PSEN` | program memory read 선택 |

즉 address bus, data bus, control signal이 따로 존재하고, 어떤 cycle에 어떤 의미로 쓰이는지 정해져야 memory나 peripheral이 올바르게 반응한다.

## memory map과 chip select

memory map은 주소 범위에 장치를 배치한 표다.

| 주소 범위 예시 | 선택 대상 | 의미 |
| --- | --- | --- |
| `0x0000_0000 ~ 0x0000_0FFF` | ROM / Flash | program code |
| `0x1000_0000 ~ 0x1000_0FFF` | RAM / SRAM | data memory, stack |
| `0x2000_0000 ...` | GPIO / 8255A | 입출력 register |
| `0x2200_0000 ...` | FND / Timer 등 | memory-mapped peripheral |
| `0x3000_0000 ...` | UART 등 | 통신 peripheral |

실제 수업 자료의 주소 범위 표기는 자료마다 조금 다르게 적혀 있었지만, 정리할 때는 아래 원칙만 잡으면 된다.

```text
CPU address
-> address decoder
-> one-hot select
-> 선택된 장치만 응답
```

`74LS138`은 `A13~A15` 같은 상위 주소선을 보고 출력 하나를 선택한다.

| decoder 출력 | 선택 대상 | 의미 |
| --- | --- | --- |
| `Y0` | ROM | `0000h` 시작 영역 |
| `Y1` | RAM | `1000h` 시작 영역 |
| `Y2` | 8255A / GPIO | `2000h` 시작 영역 |

이 구조와 APB의 `PSELx`는 같은 계열로 읽으면 된다.
둘 다 여러 장치 중 하나만 선택해서 bus 충돌을 막는다.

## APB 신호 정리

| 신호 | 방향 | 의미 |
| --- | --- | --- |
| `PCLK` | clock | APB 동작 clock |
| `PRESETn` | reset | active-low APB reset |
| `PADDR` / `PAddr` | Master -> Slave | 접근 주소 |
| `PWRITE` | Master -> Slave | `1`이면 write, `0`이면 read |
| `PSEL` / `PSELx` / `PSel` | Master -> Slave | 해당 Slave 선택 |
| `PENABLE` | Master -> Slave | access phase 진입 |
| `PWDATA` | Master -> Slave | write data |
| `PRDATA` | Slave -> Master | read data |
| `PREADY` | Slave -> Master | 전송 완료 가능 여부 |

주소와 데이터 폭은 구현에 따라 달라질 수 있지만, 이번 자료에서는 32-bit 주소/데이터 흐름으로 읽으면 된다.
APB 신호는 `PCLK` 기준으로 동작하고, reset은 `PRESETn`이 low일 때 걸리는 active-low 구조로 정리한다.

가장 먼저 외울 신호는 `PSEL`, `PENABLE`, `PREADY`다.

| 신호 | 한 줄 의미 |
| --- | --- |
| `PSEL` | 지금 이 Slave를 선택함 |
| `PENABLE` | setup이 끝나고 실제 access를 수행 중 |
| `PREADY` | Slave가 이번 transfer를 끝낼 수 있음 |

## APB transfer phase

APB 전송은 기본적으로 두 phase로 나뉜다.

| phase | 신호 상태 | 의미 |
| --- | --- | --- |
| `SETUP` | `PSEL=1`, `PENABLE=0` | 주소, 방향, write data 준비 |
| `ACCESS` | `PSEL=1`, `PENABLE=1` | 실제 read/write 수행 |

전송이 없을 때는 `IDLE` 상태다.

| 상태 | `PSEL` | `PENABLE` | 의미 |
| --- | --- | --- | --- |
| `IDLE` | `0` | `0` | 전송 없음 |
| `SETUP` | `1` | `0` | Slave 선택, 주소/제어 안정화 |
| `ACCESS` | `1` | `1` | 실제 전송, `PREADY` 확인 |

`SETUP`은 보통 1 clock 동안 주소와 제어 신호를 안정화하는 단계다.
`ACCESS`에서는 `PENABLE=1`이 되고, `PREADY=1`이 될 때 transfer가 끝난다.
실제 데이터 갱신과 관측은 `PCLK` 상승 edge 기준으로 맞춰 읽는다.

## write transfer 흐름

write는 Master가 Slave로 데이터를 보내는 동작이다.

```text
IDLE
-> CPU write 요청
-> SETUP: PADDR, PWRITE=1, PWDATA, PSEL 설정
-> ACCESS: PENABLE=1
-> PREADY=1이면 write 완료
-> IDLE 또는 다음 SETUP
```

| 단계 | 확인할 신호 |
| --- | --- |
| 요청 준비 | `PADDR`, `PWRITE=1`, `PWDATA` |
| Slave 선택 | `PSEL=1` |
| 전송 수행 | `PENABLE=1` |
| 완료 확인 | `PREADY=1` |

wait가 없는 write transfer는 `SETUP` 다음 `ACCESS`에서 바로 완료된다.
RAM이나 GPIO output register처럼 빠르게 받을 수 있는 Slave는 `PREADY=1`을 바로 줄 수 있다.

## read transfer 흐름

read는 Slave가 Master로 데이터를 반환하는 동작이다.

```text
IDLE
-> CPU read 요청
-> SETUP: PADDR, PWRITE=0, PSEL 설정
-> ACCESS: PENABLE=1
-> Slave가 PRDATA 준비
-> PREADY=1이면 read 완료
-> Master가 PRDATA를 CPU 쪽 RDATA로 전달
```

| 단계 | 확인할 신호 |
| --- | --- |
| 요청 준비 | `PADDR`, `PWRITE=0` |
| Slave 선택 | `PSEL=1` |
| 전송 수행 | `PENABLE=1` |
| 데이터 반환 | `PRDATA` |
| 완료 확인 | `PREADY=1` |

write와 read의 큰 구조는 같다.
차이는 write는 `PWDATA`가 Master에서 Slave로 가고, read는 `PRDATA`가 Slave에서 Master로 온다는 점이다.

## wait state를 읽는 법

`PREADY=0`이면 transfer가 아직 끝나지 않았다.
이때 Master는 `ACCESS` 상태를 유지한다.

| 조건 | 다음 상태 |
| --- | --- |
| `PREADY=0` | `ACCESS` 유지 |
| `PREADY=1` and 다음 transfer 없음 | `IDLE` |
| `PREADY=1` and 다음 transfer 있음 | 다음 `SETUP` |

즉 wait state는 별도 특수 동작이 아니라, `ACCESS` phase가 늘어나는 것이다.
UART처럼 내부 처리 시간이 필요한 peripheral은 `PREADY`로 CPU를 기다리게 할 수 있다.

## `APB_BRAM.sv` 구현과 write 테스트

추가 자료의 구현 예시는 APB Slave로 붙은 BRAM을 통해 memory-mapped write가 실제로 어떻게 보이는지 보여 준다.

| 대상 | 정리 |
| --- | --- |
| `APB_BRAM.sv` | APB Slave 역할의 RAM block |
| memory 구조 | 64개의 32-bit word를 저장하는 단순 BRAM 형태 |
| 주소 기준 | `PADDR`를 해석해 내부 memory index 선택 |
| ready 생성 | `PENABLE & PSEL` 조건에서 `PREADY`를 올리는 단순 응답 구조 |
| write 조건 | `PWRITE`와 `PREADY`가 함께 활성일 때 `PWDATA`를 해당 주소에 저장 |
| read 조건 | 선택된 주소의 값을 `PRDATA`로 반환 |

즉 `APB_BRAM`은 APB protocol을 실제 저장소에 연결한 가장 작은 예제다.
`PSEL/PENABLE/PWRITE/PADDR/PWDATA`가 맞게 들어오면 memory가 갱신되고, read에서는 `PRDATA`로 값이 돌아온다.

## C 코드와 assembly에서 보이는 bus 접근

software 쪽에서는 peripheral이나 RAM 접근이 포인터 write처럼 보인다.

```c
*(unsigned int *)0x10000000 = 0x0a0a5050;
```

이 문장은 hardware 관점에서 아래 흐름으로 내려간다.

```text
C pointer write
-> address constant 준비
-> write data 준비
-> store word instruction
-> CPU data memory request
-> APB write transfer
-> APB_BRAM write
```

assembly 수준에서는 대체로 아래 패턴으로 읽으면 된다.

| 단계 | 의미 |
| --- | --- |
| `li` | `0x1000_0000` 같은 address immediate를 register에 준비 |
| `li` | `0x0a0a5050` 같은 write data를 register에 준비 |
| `sw` | 준비한 data를 준비한 address로 store |

`tb_apb_master.sv`의 write 테스트도 같은 흐름을 검증한다.
특정 메모리 주소인 `0x1000_0000`에 데이터를 쓰고, APB 신호가 `SETUP -> ACCESS -> PREADY` 순서로 맞는지 확인하는 쪽으로 보면 된다.

## Rooz SoC / RV32I APB 연결

추가 자료의 Rooz/Ruiz SoC 구조는 RV32I core가 Master가 되고, APB bridge 또는 APB Master가 여러 Slave를 선택하는 구조로 보면 된다.

| 항목 | 정리 |
| --- | --- |
| Master | RISC-V RV32I core 또는 그 요청을 받는 APB Master |
| Slave | RAM, GPIO, FND, UART 등 |
| 대표 RAM 주소 | `0x1000_0000` 대역 |
| Address Decoder | `PAddr`를 해석해 `PSel0~PSel4` 중 하나를 활성화 |
| Read Data Mux | 여러 Slave의 `PRDATA` 중 선택된 Slave의 값만 Master로 전달 |
| Ready Mux | 여러 Slave의 `PREADY` 중 선택된 Slave의 응답만 Master로 전달 |

여기서 중요한 점은 read data와 ready도 선택되어야 한다는 것이다.
주소 decoder가 Slave 하나를 고르면, 그 Slave의 `PRDATA`와 `PREADY`만 CPU 쪽으로 돌아가야 한다.

## AHB와 APB를 구분해서 보기

`0514`와 `0528`에서 잡은 AMBA bus 구분을 다시 연결하면 아래처럼 정리된다.

| 버스 | 용도 | 특징 |
| --- | --- | --- |
| `AHB` | CPU, RAM, DMA, high-speed peripheral | 고속, 더 복잡한 system bus |
| `APB` | GPIO, UART, Timer, Watchdog 같은 peripheral | 단순, 저전력, 비파이프라인 |

실제 SoC에서는 CPU 가까운 고속 영역은 AHB 계열로 묶고, 느린 peripheral은 bridge를 거쳐 APB에 붙이는 구조가 흔하다.
핵심은 `고속 system bus`와 `저속 peripheral bus`를 같은 것으로 보지 않는 것이다.

## 핵심 정리

APB는 peripheral을 메모리 주소 공간 안에 붙이기 위한 단순한 bus protocol이다.
CPU가 주소와 read/write 요청을 내면, address decoder가 Slave를 고르고, APB Master가 `PSEL/PENABLE/PWRITE/PADDR/PWDATA`를 만들며, 선택된 Slave는 `PRDATA/PREADY`로 응답한다.

## 참고 링크

* [AMBA APB specification PDF](https://github.com/daxzio/cocotbext-apb/blob/main/assets/IHI0024E_amba_apb_architecture_spec.pdf)

## 연결 노트

* [[260528-pipeline-memory-map-apb]]
* [[260514-cpu-구조]]
