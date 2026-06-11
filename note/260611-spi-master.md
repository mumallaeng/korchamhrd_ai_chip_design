# 26-06-11 - RAM 보강, SPI Master, SPI/I2C 실습 방향

## 수업 흐름

오전 초반에는 전날 진행한 RAM UVM 예제인 [260610_ram](../helloHDL/260610_ram)을 다시 가져와 sequence와 test scenario 관점으로 보강했다. 세부 내용은 0610 수업의 연장선이므로 [260610-uvm-ram.md](./260610-uvm-ram.md)의 `0611 오전 보강: sequence와 test scenario 관점`에 합쳐 두었다.

오후에는 SPI 통신을 중심으로 master RTL 구조를 보고, 이후 SPI slave와 I2C slave를 직접 구현해 FPGA 보드 동작과 UVM 검증까지 연결하는 방향을 정리했다. 목표는 단순히 RTL을 작성하는 것이 아니라, 어떤 값을 보내고 어떤 결과가 나와야 하는지 test scenario로 설명할 수 있게 만드는 것이다.

## 현재 소스 위치

| 위치 | 내용 |
| :--- | :--- |
| [260610_ram](../helloHDL/260610_ram) | RAM UVM 예제. 0611 오전 보강 내용은 0610 노트에 연결한다. |
| [260611_SPI_Master](../helloHDL/260611_SPI_Master) | Vivado 프로젝트 형태로 저장된 SPI master 실습 코드 |
| [spi_master.sv](../helloHDL/260611_SPI_Master/20260611_SPI_Master.srcs/sources_1/new/spi_master.sv) | SPI master RTL |
| [tb_spi_master.sv](../helloHDL/260611_SPI_Master/20260611_SPI_Master.srcs/sim_1/new/tb_spi_master.sv) | SPI master loopback testbench |

현재 `260611_SPI_Master`는 Vivado 프로젝트 디렉토리 형태로 들어와 있다. 수업 노트에서는 생성물 전체가 아니라 직접 작성한 RTL/TB 파일을 기준으로 내용을 정리한다.

## 소스 코드 읽는 순서

0611 SPI 코드는 testbench에서 전송 조건을 만들고, RTL의 FSM이 그 조건을 받아 `sclk`, `mosi`, `ss_n`, `done`을 만드는 흐름으로 읽으면 된다.

| 읽는 순서 | 소스 위치 | 확인할 내용 |
| :--- | :--- | :--- |
| 1 | `tb_spi_master.sv`의 `initial` block | reset 해제, `clk_div = 4`, `cpol` 변경, 전송 data pattern 순서 |
| 2 | `tb_spi_master.sv`의 `spi_send_data` task | `tx_data` 설정, `start` 1-cycle pulse, `done` 대기 |
| 3 | `spi_master.sv`의 `IDLE` 상태 | `start`를 받으면 `tx_data`, `clk_div`, `cpol`을 latch하고 `ss_n=0`, `busy=1`로 전송 시작 |
| 4 | `spi_master.sv`의 `START` 상태 | `tx_shift_reg[7]`을 먼저 `mosi`로 내보내고 `DATA` 상태로 이동 |
| 5 | `spi_master.sv`의 `DATA` 상태 | `half_tick`마다 `sclk` toggle, `step`에 따라 `miso` sampling과 다음 `mosi` bit 준비 |
| 6 | `spi_master.sv`의 `STOP` 상태 | `ss_n=1`, `done=1`, `busy=0`으로 전송 완료 표시 |

이 흐름을 발표나 복습에서 설명할 때는 "testbench가 `spi_send_data(8'hAA)`를 호출하면, RTL은 `IDLE -> START -> DATA -> STOP` 순서로 8-bit를 shift하고, loopback된 `miso`를 `rx_data`로 모은다"라고 연결하면 된다.

## SPI 기본 신호

SPI는 master가 clock과 slave select를 제어하고, master와 slave가 shift 방식으로 데이터를 주고받는 동기식 직렬 통신이다.

| 신호 | 방향 | 역할 |
| :--- | :--- | :--- |
| `SCLK` | master -> slave | master가 만드는 serial clock |
| `MOSI` | master -> slave | master가 slave로 보내는 data line |
| `MISO` | slave -> master | slave가 master로 보내는 data line |
| `SS_N` / `CS_N` | master -> slave | 통신할 slave를 선택하는 low-active select 신호 |

SPI는 일반적으로 전이중 통신이 가능하다. master가 `MOSI`로 데이터를 내보내는 동안 slave도 `MISO`로 데이터를 돌려줄 수 있다. I2C는 같은 serial 통신 계열이지만 선 수, 주소 지정, 속도, bus 구성 방식이 다르므로 이후 별도 slave 구현 대상으로 본다.

## SPI mode와 현재 RTL 범위

SPI mode는 `CPOL`과 `CPHA` 조합으로 정의된다.

| 항목 | 의미 |
| :--- | :--- |
| `CPOL` | clock idle level. `0`이면 idle low, `1`이면 idle high |
| `CPHA` | data sampling edge 선택. 첫 번째 edge에서 샘플링할지, 두 번째 edge에서 샘플링할지 결정 |

현재 [spi_master.sv](../helloHDL/260611_SPI_Master/20260611_SPI_Master.srcs/sources_1/new/spi_master.sv)는 `cpol` 입력을 받아 `sclk`의 idle level을 바꾸는 구조다. `CPHA`를 별도 port로 받지는 않고, 내부 `step` 신호로 첫 번째 edge와 두 번째 edge를 나눠 `miso` sampling과 다음 `mosi` shift를 처리한다. 따라서 현재 수업 코드 설명에서는 "CPOL을 설정할 수 있는 SPI master 구조"로 보는 것이 정확하다.

## SPI Master RTL 구조

`spi_master`의 외부 port는 내부 제어 신호와 실제 SPI line으로 나뉜다.

| 구분 | 신호 | 역할 |
| :--- | :--- | :--- |
| 제어 입력 | `start` | 전송 시작 trigger |
| 제어 입력 | `cpol` | `sclk` idle level 선택 |
| 제어 입력 | `clk_div` | `sclk` 속도 생성을 위한 분주값 |
| 송신 데이터 | `tx_data[7:0]` | master가 보낼 8-bit data |
| 상태 출력 | `busy` | 전송 중 표시 |
| 상태 출력 | `done` | 1-byte 전송 완료 pulse |
| 수신 데이터 | `rx_data[7:0]` | `miso`에서 shift-in한 결과 |
| SPI line | `sclk`, `mosi`, `miso`, `ss_n` | 실제 SPI 통신 신호 |

내부에는 `tx_shift_reg`, `rx_shift_reg`, `bit_cnt`, `div_cnt`, `half_tick`, `step`, `cpol_r`, `sclk_r`가 있다. `start`가 들어오면 `tx_data`, `clk_div`, `cpol`을 latch하고, 전송 중에는 latch된 값으로 동작한다.

### FSM 상태

| 상태 | 동작 |
| :--- | :--- |
| `IDLE` | `ss_n=1`, `mosi=1`, `sclk=cpol`로 대기한다. `start`가 들어오면 `tx_data`, `clk_div`, `cpol`을 latch하고 `ss_n=0`, `busy=1`로 전송을 시작한다. |
| `START` | `tx_shift_reg[7]`을 `mosi`로 먼저 내보내고 shift register를 한 칸 이동한 뒤 `DATA`로 이동한다. |
| `DATA` | `half_tick`마다 `sclk`를 toggle한다. `step==0`인 첫 번째 edge에서는 `miso`를 `rx_shift_reg`에 sample하고, `step==1`인 두 번째 edge에서는 다음 `mosi` bit를 준비한다. |
| `STOP` | `sclk`를 latch된 `cpol_r`로 되돌리고 `ss_n=1`, `done=1`, `busy=0`, `mosi=1`로 정리한 뒤 `IDLE`로 돌아간다. |

`clk_div`는 `DATA` 상태에서만 count된다. testbench에서는 `clk_div = 4`로 설정하고 있으며, 주석 기준으로 100 MHz system clock에서 약 10 MHz `sclk`를 만들기 위한 값이다.

## Testbench 시나리오

[tb_spi_master.sv](../helloHDL/260611_SPI_Master/20260611_SPI_Master.srcs/sim_1/new/tb_spi_master.sv)는 `mosi`와 `miso`를 `loop_wire`로 연결해서 master가 보낸 값을 다시 master가 읽는 loopback 구조로 확인한다.

| 요소 | 내용 |
| :--- | :--- |
| clock | `always #5 clk = ~clk;`로 10 ns 주기의 clock 생성 |
| reset | 처음 3번의 posedge 동안 reset 유지 후 해제 |
| `spi_set_cpol` | `cpol` 값을 바꾸고 다음 clock까지 대기 |
| `spi_send_data` | `tx_data` 설정, `start` 1-cycle pulse, `done` 대기 |
| loopback | `mosi`와 `miso`를 같은 `loop_wire`에 연결 |

현재 TB는 아래 data pattern을 `cpol=0`, `cpol=1` 각각에서 전송한다.

| 전송 데이터 | 확인 목적 |
| :--- | :--- |
| `8'hAA` | `10101010` 교대 bit pattern |
| `8'h55` | `01010101` 교대 bit pattern |
| `8'hFF` | 모든 bit가 1인 경우 |
| `8'h00` | 모든 bit가 0인 경우 |

아직 이 노트에는 정확한 waveform ns 구간이나 PASS 로그를 기록하지 않는다. 현재 정리 범위는 수업에서 작성한 RTL/TB 구조와 test scenario 수준이다.

## 코드 기준 관찰 포인트

Vivado 시뮬레이션에서 파형을 볼 때는 아래 신호를 함께 묶어 보면 RTL 동작이 가장 잘 보인다.

| 관찰 신호 | 코드와 연결되는 의미 |
| :--- | :--- |
| `start` | TB의 `spi_send_data` task가 1 cycle 동안 올리는 전송 trigger |
| `state` | `IDLE`, `START`, `DATA`, `STOP` 순서로 전송 FSM 진행 확인 |
| `cpol`, `cpol_r` | TB에서 설정한 clock polarity가 전송 시작 시 latch되는지 확인 |
| `clk_div`, `clk_div_r`, `div_cnt`, `half_tick` | system clock을 SPI clock edge로 나누는 분주 흐름 확인 |
| `sclk` | `DATA` 상태에서만 toggle되고, `STOP` 이후 `cpol_r` idle level로 복귀하는지 확인 |
| `ss_n` | 전송 중 low, 전송 종료 후 high로 돌아오는 low-active select 확인 |
| `mosi`, `miso`, `loop_wire` | 현재 TB에서는 `mosi`와 `miso`가 loopback되어 같은 serial data를 공유 |
| `tx_shift_reg`, `rx_shift_reg`, `bit_cnt` | 8-bit shift 진행과 bit count 증가 확인 |
| `done`, `busy`, `rx_data` | 전송 완료 pulse, busy 해제, 최종 수신 data 확인 |

현재 TB는 실제 slave를 붙인 구조가 아니라 loopback 확인용이다. 따라서 FPGA 산출물로 넘어갈 때는 `miso`를 단순 loopback으로 두는 대신, SPI slave가 `MOSI/SCLK/SS_N`을 받아 내부 register나 LED/FND 제어값으로 변환하는 구조가 필요하다.

## UVM 검증으로 연결할 점

0610 RAM 수업에서 정리한 것처럼 UVM 검증에서는 sequence가 test scenario를 만든다. SPI에서도 단순히 `start`를 누르는 것이 아니라, 어떤 `tx_data`, 어떤 `cpol`, 어떤 `clk_div`, 어떤 `miso` 응답을 넣고 `done`, `busy`, `ss_n`, `rx_data`가 어떻게 나와야 하는지를 transaction 단위로 정리해야 한다.

| 검증 관점 | 확인할 내용 |
| :--- | :--- |
| 기본 기능 | `start` 후 `ss_n`이 low가 되고 8-bit 전송 후 `done`이 발생하는지 |
| data pattern | `8'hAA`, `8'h55`, `8'hFF`, `8'h00` 같은 대표 pattern이 정상 shift되는지 |
| clock 설정 | `cpol=0/1`에서 idle level이 맞는지 |
| 속도 설정 | `clk_div`에 따라 `sclk` toggle 간격이 달라지는지 |
| 결과 비교 | loopback 또는 slave model에서 기대 `rx_data`와 실제 `rx_data`를 비교 |

## FPGA 산출물 방향

이후 과제 방향은 SPI slave를 만들어 FPGA에서 실제 출력을 제어하는 것이다. 예시는 LED control, FND control, 또는 이와 비슷한 간단한 출력 제어가 될 수 있다.

최종 확인은 시뮬레이션 로그만으로 끝내지 않고, FPGA 보드에서 SPI slave가 실제로 LED나 FND를 제어하는 장면을 동영상으로 남기는 방향이다. 발표에서는 코드 전체를 설명하기보다 SPI master/slave 역할, 보낸 값, FPGA 출력 결과, UVM에서 expected/actual을 어떻게 비교했는지를 짧게 연결한다.

I2C도 같은 방향으로 slave 구현을 먼저 생각한다. 이후 SPI/I2C 결과물을 UVM 검증 내용과 함께 묶어서 정리한다.

## 다음 연결

다음 단계에서는 SPI slave 또는 I2C slave 구현 범위를 정하고, 그에 맞춰 UVM transaction과 sequence를 설계해야 한다. 발표 일정과 준비 기준은 [presentation_operations_final_by_date.md](/Users/mumallaeng/git/Vault/activities/korcham/presentation_operations_final_by_date.md)에 따로 정리한다.
