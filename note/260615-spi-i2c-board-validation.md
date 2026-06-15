# 26-06-15 - SPI/I2C 사용처, 보드 연결, 로직 애널라이저 검증

## 수업 흐름

0615 수업은 SPI와 I2C를 "어디에 쓰는가"에서 시작해 실제 보드 연결, I2C open-drain 동작, testbench 작성, 로직 애널라이저 측정까지 이어졌다. 지난 수업에서 SPI Master와 I2C Master의 RTL 구조를 봤다면, 오늘은 그 protocol이 실제 sensor나 peripheral과 어떻게 연결되고, 만든 신호가 실제로 나가는지 어떻게 확인하는지가 중심이었다.

핵심은 SPI와 I2C가 FPGA, MCU, CPU 같은 controller와 외부 sensor/peripheral 사이의 chip-to-chip 통신에 사용된다는 점이다. 예를 들어 NFC 모듈은 I2C 방식으로 연결될 수 있고, FND 출력은 SPI 방식으로 연결될 수 있다. 장치마다 요구하는 interface가 다르므로, 먼저 datasheet나 모듈 설명에서 어떤 protocol을 쓰는지 확인한 뒤 controller, target, Custom IP, UVM 검증 구조를 잡아야 한다.

오전에는 브레드보드와 로직 애널라이저 사용법도 함께 확인했다. 브레드보드는 가운데 홈을 기준으로 좌우가 끊어져 있고, 행 단위 연결과 전원 rail 연결 방식이 다르므로 부품을 꽂는 방향을 잘못 잡으면 short가 날 수 있다. I2C/SPI 실습에서는 FPGA 보드와 외부 회로의 `GND`를 반드시 공통으로 묶어야 하고, I2C line에는 pull-up 저항과 open-drain 동작을 함께 생각해야 한다.

## 현재 소스 위치

| 위치 | 내용 |
| :--- | :--- |
| [260615_I2C_Master](../helloHDL/260615_I2C_Master) | 0615 기준 Vivado I2C Master 실습 프로젝트 |
| [I2C_Master.sv](../helloHDL/260615_I2C_Master/260615_I2C_Master.srcs/sources_1/new/I2C_Master.sv) | command 기반 I2C Master, open-drain `SDA`, quarter tick FSM |
| [I2C_demo_counter.sv](../helloHDL/260615_I2C_Master/260615_I2C_Master.srcs/sources_1/new/I2C_demo_counter.sv) | 스위치 입력으로 counter 값을 I2C write하는 demo wrapper |
| [tb_I2C_Master.sv](../helloHDL/260615_I2C_Master/260615_I2C_Master.srcs/sim_1/new/tb_I2C_Master.sv) | `START -> write -> STOP` command task를 둔 기본 I2C testbench |
| [I2c_demo.xdc](../helloHDL/260615_I2C_Master/260615_I2C_Master.srcs/constrs_1/new/I2c_demo.xdc) | Basys3 clock, switch, reset, PMOD JB `SCL/SDA` pin mapping |
| [SPI_I2C_UVM](../helloHDL/260618_SPI_I2C_UVM) | SPI/I2C controller-target 구조와 검증 testbench를 묶기 위한 프로젝트 |
| [src/rtl/spi](../helloHDL/260618_SPI_I2C_UVM/src/rtl/spi) | `SPI`, `SPI_controller`, `SPI_target` 작성 위치 |
| [src/rtl/i2c](../helloHDL/260618_SPI_I2C_UVM/src/rtl/i2c) | `I2C`, `I2C_controller`, `I2C_target` 작성 위치 |
| [src/tb](../helloHDL/260618_SPI_I2C_UVM/src/tb) | `tb_SPI`, `tb_I2C`, 통합 TB placeholder 위치 |

0615 소스는 두 갈래로 보면 된다. `260615_I2C_Master`는 수업 중 I2C Master와 counter demo를 빠르게 확인하기 위한 Vivado 프로젝트이고, `SPI_I2C_UVM`은 SPI/I2C controller-target 구조를 발표와 검증 과제로 확장하기 위한 정리 프로젝트다. 수업 노트에서는 Vivado 생성물 전체가 아니라 직접 작성한 RTL/TB 파일만 기준으로 본다.

## 260615 I2C Master 코드 구조

[I2C_Master.sv](../helloHDL/260615_I2C_Master/260615_I2C_Master.srcs/sources_1/new/I2C_Master.sv)는 `I2C_Master_top`과 `I2C_Master`로 나뉜다. `I2C_Master_top`은 board level의 `inout sda`를 내부 `sda_i`, `sda_o`로 분리하고, `assign sda = sda_o ? 1'bz : 1'b0`로 open-drain 동작을 표현한다. 내부 master는 `cmd_start`, `cmd_write`, `cmd_read`, `cmd_stop` 명령을 받아 `SCL/SDA`를 protocol 순서대로 움직인다.

| 코드 요소 | 역할 |
| :--- | :--- |
| `I2C_Master_top` | 외부 `inout sda`와 내부 `sda_i/sda_o` 분리 |
| `sda_o=1` | High-Z release, pull-up으로 high |
| `sda_o=0` | SDA low drive |
| `div_cnt == 250 - 1` | 100 MHz 기준 quarter tick 생성 |
| `qtr_tick` | SCL 한 주기의 1/4 진행 pulse |
| `step[1:0]` | 각 상태 안에서 quarter 구간 진행 |
| `tx_shift_reg`, `rx_shift_reg` | 8-bit write/read shift |
| `ack_in`, `ack_out` | read 후 master ACK/NACK, write 후 target ACK/NACK |

I2C FSM은 아래 흐름이다.

| 상태 | 동작 |
| :--- | :--- |
| `IDLE` | `SCL=1`, `SDA=1`, command 대기 |
| `START` | `SCL` high 상태에서 `SDA` falling edge 생성 |
| `WAIT_CMD` | write/read/stop/repeated-start command 선택 |
| `DATA` | write면 `tx_shift_reg[7]` 출력, read면 `SDA` release 후 sample |
| `DATA_ACK` | write ACK sample 또는 read ACK/NACK drive |
| `STOP` | `SCL` high 상태에서 `SDA` rising edge 생성 |

[tb_I2C_Master.sv](../helloHDL/260615_I2C_Master/260615_I2C_Master.srcs/sim_1/new/tb_I2C_Master.sv)는 `SDA`에 `pullup`을 두고 `i2c_start`, `i2c_write`, `i2c_read`, `i2c_stop` task로 command를 순서대로 넣는다. `SCL`은 DUT output이 직접 구동하므로 별도 pullup을 두지 않는다. 현재 `initial` block의 의도는 `START`, slave address write, `8'h55`, `8'hAA`, `STOP` 순서다. 다만 현재 `i2c_write(byte data)` task 내부는 인자 `data`를 쓰지 않고 `tx_data = (SLA << 1) | 1'b0`로 고정되어 있으므로, 실제 data byte 파형을 확인하려면 이 부분을 먼저 수정해야 한다.

## I2C counter demo 코드 구조

[I2C_demo_counter.sv](../helloHDL/260615_I2C_Master/260615_I2C_Master.srcs/sources_1/new/I2C_demo_counter.sv)는 스위치 입력을 받아 I2C write transaction으로 counter 값을 내보내는 demo wrapper다. `SLA_W = {7'h12, 1'b0}`로 slave address와 write bit를 만들고, `I2C_Master_top`에 command를 넣어 address byte와 counter byte를 전송한다.

| 코드 요소 | 역할 |
| :--- | :--- |
| `dff[1:0]` | 비동기 스위치 입력 2-stage synchronizer |
| `sw_posedge` | 스위치 rising edge 검출 |
| `counter[7:0]` | 전송할 demo data |
| `SLA_W` | `7'h12` slave address와 write bit |
| `IDLE -> START -> ADDR -> WRITE -> STOP` | counter write transaction 흐름 |
| `counter <= counter + 1'b1` | STOP 완료 후 다음 전송값 증가 |

이 demo는 "스위치를 누르면 FPGA가 I2C Master로 address와 counter 값을 전송한다"는 보드 동작 설명에 연결하기 좋다. 실제 제출물로 쓰려면 XDC pin mapping, pull-up 저항, logic analyzer channel 설정, target ACK 모델 또는 실제 target 장치 연결까지 함께 확인해야 한다.

## Basys3 XDC 연결

[I2c_demo.xdc](../helloHDL/260615_I2C_Master/260615_I2C_Master.srcs/constrs_1/new/I2c_demo.xdc)는 `I2C_demo_counter`를 Basys3 보드에서 확인하기 위한 제약 파일이다. Vivado 프로젝트의 top module도 `I2C_demo_counter`로 맞춰져 있고, XDC는 synthesis/implementation에 포함되도록 등록되어 있다.

| 포트 | 핀 | 보드 연결 | 확인 내용 |
| :--- | :--- | :--- | :--- |
| `clk` | `W5` | Basys3 100 MHz clock | `create_clock` 10 ns |
| `sw` | `V17` | switch 0 | I2C 전송 trigger 입력 |
| `reset` | `U18` | center button | active-high reset |
| `scl` | `A15` | PMOD JB7 | I2C clock 출력 |
| `sda` | `A17` | PMOD JB8 | I2C open-drain data line |

현재 XDC의 `sda` active line에는 내부 `PULLUP true`가 붙어 있지 않다. 따라서 실제 보드 연결에서는 외부 pull-up 저항을 쓰는지, 또는 XDC에서 내부 pull-up을 사용할지 먼저 정해야 한다. 로직 애널라이저 캡처에서는 JB7을 `SCL`, JB8을 `SDA`로 잡고, FPGA 보드와 외부 회로의 `GND`를 공통으로 연결한다.

## SPI/I2C UVM 프로젝트 코드 구조

[SPI_I2C_UVM](../helloHDL/260618_SPI_I2C_UVM)은 이름은 UVM 프로젝트지만, 현재 소스 기준으로는 protocol RTL과 self-checking testbench의 기초 구조가 먼저 들어가 있다.

| 파일 | 역할 |
| :--- | :--- |
| [SPI.sv](../helloHDL/260618_SPI_I2C_UVM/src/rtl/spi/SPI.sv) | 1 controller : N target SPI top |
| [SPI_controller.sv](../helloHDL/260618_SPI_I2C_UVM/src/rtl/spi/SPI_controller.sv) | CPOL/CPHA 4 mode, target select, 1-byte transfer |
| [SPI_target.sv](../helloHDL/260618_SPI_I2C_UVM/src/rtl/spi/SPI_target.sv) | selected target의 `MOSI` sample, `MISO` shift, `rx_valid` 생성 |
| [I2C.sv](../helloHDL/260618_SPI_I2C_UVM/src/rtl/i2c/I2C.sv) | N controller : N target I2C top, open-drain bus resolve |
| [I2C_controller.sv](../helloHDL/260618_SPI_I2C_UVM/src/rtl/i2c/I2C_controller.sv) | 7-bit address, 1-byte write/read, ACK, arbitration lost |
| [I2C_target.sv](../helloHDL/260618_SPI_I2C_UVM/src/rtl/i2c/I2C_target.sv) | address match, write data receive, read data shift, ACK drive |
| [tb_SPI.sv](../helloHDL/260618_SPI_I2C_UVM/src/tb/tb_SPI.sv) | SPI target 0/1 선택과 controller/target data 비교 |
| [tb_I2C.sv](../helloHDL/260618_SPI_I2C_UVM/src/tb/tb_I2C.sv) | controller 0/1이 target 0/1에 write하는 self-checking TB |

SPI 쪽은 `target_sel`로 하나의 target을 선택하고, 선택된 target의 `tgt_sdo`만 controller의 `ctrl_sdi`로 되돌린다. `SPI_controller`는 `cpol`, `cpha`, `clk_div`, `target_sel`, `start`, `tx_data`를 transaction 설정으로 받고, `cs_n`, `sclk`, `ctrl_sdo`를 만든다. `SPI_target`은 `cs_n` falling edge에서 선택되고, CPOL/CPHA에 맞춰 sample edge와 shift edge를 분리한다.

I2C 쪽은 각 controller와 target이 `drive_low`만 만들고, top의 `always_comb`에서 하나라도 low를 drive하면 resolved bus `scl/sda`가 0이 되는 방식이다. 이 구조가 open-drain bus를 SystemVerilog 내부 신호로 모델링한 것이다. `I2C_controller`는 address byte와 data byte를 보내고, `I2C_target`은 address match 후 ACK와 data receive/read data shift를 담당한다.

현재 `tb_SPI.sv`는 mode 0 조건으로 target 0과 target 1을 각각 선택해 controller 수신값과 selected target 수신값을 비교한다. `tb_I2C.sv`는 controller 0이 target 0 주소 `7'h12`에 `8'hA5`, controller 1이 target 1 주소 `7'h34`에 `8'h5A`를 write하고 target 수신 여부와 data를 비교한다.

이번 정리 중 확인한 최소 시뮬레이션 결과는 다음과 같다.

| 대상 | 실행 기준 | 결과 |
| :--- | :--- | :--- |
| `tb_SPI.sv` | `iverilog -g2012` + `vvp` | `pass=4`, `fail=0`, `[TEST PASS]` |
| `tb_I2C.sv` | `iverilog -g2012` + `vvp` | `pass=6`, `fail=0`, `[TEST PASS]` |
| `tb_I2C_Master.sv` | `iverilog -g2012` compile | compile 통과, run 종료는 command task 보강 후 재확인 |

## SPI/I2C 사용처

SPI와 I2C는 둘 다 controller와 peripheral 사이의 serial communication이다. 단순히 `SCLK`, `SDA` 같은 선 이름을 외우는 것이 아니라, controller가 command/data를 보내고 peripheral이 상태, sensor 값, 출력 제어 결과를 돌려주는 구조로 봐야 한다.

| 예시 장치 | 연결 protocol | 확인 관점 |
| :--- | :--- | :--- |
| NFC 모듈 | I2C | `SCL`, `SDA`, address, `ACK/NACK` |
| FND 출력 | SPI | `SCLK`, `MOSI`, `SS_N`, mode |
| Sensor류 | I2C 또는 SPI | datasheet interface 기준 |
| Custom IP | SPI/I2C 상위 연결 | register, command, status, output |

I2C는 `SCL`과 `SDA` 두 선을 공유하고 address로 target을 선택하므로 여러 sensor를 적은 pin 수로 붙일 때 유리하다. SPI는 master가 clock과 slave select를 직접 제어하고 shift 방식으로 데이터를 주고받으므로 display driver, FND, 빠른 peripheral 제어에 쓰기 좋다.

## 브레드보드와 배선

브레드보드는 가운데 홈을 기준으로 좌우가 끊어져 있고, 양쪽 구멍은 보통 행 방향으로 연결된다. 전원 rail의 `+`, `-` 라인은 길게 이어져 있지만, 보드에 따라 중간이 끊어진 제품도 있으므로 실제 선 표시를 확인해야 한다. 전원 rail이 중간에서 끊어진 경우에는 같은 `+` 또는 `-` 표시라도 한쪽 끝과 반대쪽 끝이 연결되지 않을 수 있다.

I2C/SPI 실습에서는 다음 순서로 배선을 확인한다.

| 확인 항목 | 이유 |
| :--- | :--- |
| `GND` 공통 연결 | FPGA 보드와 외부 회로의 기준 전압 일치 |
| 전원 rail 연결 상태 | 중간 단선 rail 여부 확인 |
| 부품 방향 | 같은 행 short 또는 미연결 방지 |
| 저항값 | pull-up 또는 보호 저항 값 확인 |
| 로직 애널라이저 GND | 측정 기준점 일치 |

저항은 색띠로 값을 읽는다. 수업에서는 10 kOhm 계열 저항을 예로 들며 앞쪽 색띠가 유효 숫자, 다음 색띠가 곱셈 자리, 마지막 색띠가 오차율을 나타낸다고 설명했다. 금색은 보통 5% 오차, 갈색은 1% 오차로 볼 수 있다.

## I2C open-drain과 high-Z

I2C의 `SDA`는 master와 target이 함께 사용하는 line이다. 따라서 누군가가 항상 `1`을 강제로 drive하는 구조가 아니라, `0`은 직접 끌어내리고 `1`은 line을 release해서 pull-up 저항이 high로 올리는 open-drain 방식으로 생각해야 한다.

read 동작에서는 `SDA`를 읽는 쪽이 line을 직접 drive하면 안 된다. 출력 쪽을 high-Z 상태로 놓아야 외부 target이 `0`을 내릴 수 있고, target이 아무것도 내리지 않으면 pull-up 때문에 `1`로 읽힌다. 그래서 RTL에서는 board level `inout sda`를 내부에서 `sda_i`와 `sda_o`처럼 나눠 생각하고, `sda_o=1`이면 high-Z release, `sda_o=0`이면 low drive로 해석하는 구조가 필요하다.

| 상태 | `SDA` 해석 |
| :--- | :--- |
| write 0 | master 또는 target이 line을 low로 drive |
| write 1 | line release, pull-up으로 high |
| read | 출력 high-Z, 외부 line 값을 input으로 sample |
| target ACK | target이 ACK bit 구간에서 low drive |

## I2C testbench 흐름

수업에서는 I2C Master가 만든 `SCL/SDA`가 protocol 순서대로 나가는지 먼저 simulation에서 확인했다. 단순히 module이 compile되는지보다 `START`, slave address, write data, `ACK`, `STOP` 조건이 파형으로 맞는지를 보는 것이 중요하다.

testbench에서 잡은 기본 흐름은 다음과 같다.

| 순서 | 동작 | 확인 대상 |
| :--- | :--- | :--- |
| 1 | `cmd_start` | `SCL` high 상태에서 `SDA` falling edge |
| 2 | slave address + write bit 전송 | address bit와 `R/W=0` |
| 3 | data byte 전송 | 예시 `8'h55`, `01010101` pattern |
| 4 | ACK 구간 | 수신자가 `SDA` low drive |
| 5 | `cmd_stop` | `SCL` high 상태에서 `SDA` rising edge |

수업 중 파형에서는 `START` 조건, address 전송, `8'h55` data pattern, `STOP` 조건을 보는 흐름으로 확인했다. 다만 ACK 모델을 testbench에서 제대로 넣어야 실제 I2C transaction처럼 보인다. ACK bit를 target이 내려주지 않으면 master 입장에서는 `NACK`처럼 보일 수 있으므로, TB에는 SDA line을 release/drive하는 slave-side 모델이 필요하다.

## 로직 애널라이저 검증

오늘 수업에서 중요한 부분은 simulation만 보는 것이 아니라 실제 보드에서 나온 I2C/SPI 신호를 로직 애널라이저로 측정하는 것이다. 내가 만든 protocol 신호가 실제 pin에서 나가고 있는지, address/data/control 신호가 기대한 순서로 나오는지 외부 측정 장비로 확인해야 한다.

로직 애널라이저에서는 protocol decoder를 추가해 I2C, SPI, UART 같은 신호를 해석할 수 있다. I2C는 `SCL`과 `SDA` channel을 지정하고, SPI는 `SCLK`, `MOSI`, `MISO`, `SS_N` channel과 mode 설정을 맞춘다. SPI slave는 이번 실습에서 mode 0 기준, 즉 `CPOL=0`, `CPHA=0`으로 맞추는 방향이다.

| protocol | analyzer 설정 | 확인 대상 |
| :--- | :--- | :--- |
| I2C | `SCL`, `SDA` channel 지정 | `START`, address, data, `ACK/NACK`, `STOP` |
| SPI | `SCLK`, `MOSI`, `MISO`, `SS_N` channel 지정 | mode, data shift, select 구간 |
| UART | TX/RX channel, baud rate | serial byte decode |

로직 애널라이저의 sampling rate도 중요하다. 수업에서 사용한 장비는 최대 24 MHz급으로 설명되었고, channel을 많이 쓰거나 통신 clock이 너무 빠르면 edge를 놓칠 수 있다. 따라서 보드에서 SPI를 확인할 때는 처음부터 너무 빠르게 돌리지 말고, `SCLK`를 1 MHz 정도처럼 낮춰서 analyzer가 충분히 따라올 수 있게 잡는 것이 좋다.

## I2C counter demo 구상

오후에는 I2C로 간단한 counter 값을 내보내는 demo 흐름을 잡았다. 현재 코드 기준으로는 스위치 상승엣지가 들어오면 한 번의 I2C write transaction이 실행되고, 전송이 끝난 뒤 counter가 1 증가하는 구조다. counter 값은 I2C Master가 slave address와 write transaction으로 내보내며, 파형에서는 address byte 뒤에 data byte가 반복적으로 나가는지 확인한다.

구상한 FSM 흐름은 다음과 같이 볼 수 있다.

| 상태 | 역할 |
| :--- | :--- |
| `IDLE` | 스위치 입력 대기 |
| `START` | I2C start command 요청 |
| `ADDR` | slave address + write bit 전송 |
| `DATA` | counter value 전송 |
| `STOP` | I2C stop command 요청 |
| `IDLE` 복귀 | counter 증가 또는 유지 |

스위치 입력은 system clock과 동기화되지 않은 비동기 입력이다. 그래서 실제 보드에서는 스위치를 바로 FSM 조건으로 쓰기보다, 두 단계 flip-flop synchronizer를 거쳐 metastability 가능성을 낮추는 것이 좋다. 수업에서는 간단한 구조로 시작하되, 스위치가 들어오면 `IDLE`에서 `START`로 넘어가고, 전송이 끝나면 counter를 증가시킨 뒤 다시 `IDLE`로 돌아오는 흐름을 잡았다.

## 발표와 과제 연결

이번 주 과제/발표는 SPI와 I2C protocol을 구현했다는 설명만으로는 부족하다. 실제 보드에서 master와 slave 또는 controller와 peripheral이 연결되고, 값이 전송되며, 그 결과가 LED/FND/counter/register 같은 확인 가능한 출력으로 이어져야 한다. 또한 simulation 결과와 로직 애널라이저 캡처를 함께 제시해야 한다.

발표 자료에서는 다음 항목이 필요하다.

| 항목 | 준비 내용 |
| :--- | :--- |
| protocol 설명 | SPI/I2C 신호와 master/target 역할 |
| 구현 구조 | controller, target, Custom IP, register 흐름 |
| simulation | `START/STOP`, address, data, ACK 또는 SPI mode 검증 |
| 보드 동작 | LED, FND, counter, register read/write 결과 |
| 로직 애널라이저 | 실제 pin에서 나온 I2C/SPI waveform decode |
| UVM 검증 | sequence, transaction, monitor, scoreboard 연결 |

수업에서는 문서 작성 시간도 따로 언급되었다. 2026-06-16까지 구현과 문서 정리를 최대한 마무리하고, 발표 순서는 랜덤으로 정해질 수 있다. 인원이 많기 때문에 발표가 하루에 끝나지 않을 수 있으므로, 발표 자료와 demo 영상은 먼저 완성해 두는 편이 안전하다.

## 다음에 확인할 것

* `tb_I2C_Master.sv`의 `i2c_write(byte data)` task가 인자 `data`를 실제 `tx_data`로 쓰도록 수정
* `tb_I2C_Master.sv`에 ACK drive/release slave-side 모델 추가 여부 확인
* `SPI_I2C_UVM/src/tb/tb_SPI_I2C_UVM.sv` 통합 TB 작성 여부 확인
* `serial_protocol_pkg.sv`에 공통 transaction enum/parameter를 둘지 결정
* `SDA` pull-up을 외부 저항으로 둘지 XDC 내부 `PULLUP true`로 둘지 결정
* 로직 애널라이저 channel mapping과 sampling rate 설정 캡처
* SPI는 mode 0 기준, `SCLK` 약 1 MHz 수준부터 실제 측정
