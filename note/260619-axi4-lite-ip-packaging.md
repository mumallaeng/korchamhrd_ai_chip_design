# 26-06-19 - AXI4-Lite Master/Slave, IP Packaging

## 수업 흐름

0619 수업은 전날 정리한 AXI 개념을 실제 AXI4-Lite master/slave 코드와 Vivado IP packaging 흐름에 연결하는 방향이었다. 핵심은 AXI4-Lite에서 write transaction이 `AW`, `W`, `B` channel로 나뉘고, read transaction이 `AR`, `R` channel로 나뉜다는 점을 코드의 FSM과 파형에서 확인하는 것이다.

직접 작성한 [260619_AXI_Mater_Slave](../helloHDL/260619_AXI_Mater_Slave) 프로젝트는 `transfer`, `write`, `addr`, `wdata` 같은 간단한 CPU-side 제어 신호를 AXI4-Lite channel handshake로 바꾸는 master와, 4개 register bank를 가진 slave를 연결한다. 별도로 [ip_repo/260619_myip_1.0](../helloHDL/ip_repo/260619_myip_1.0)은 Vivado의 `Create and Package New IP` 흐름에서 생성된 AXI4-Lite slave template로, 수업 코드와 비교해서 Xilinx template이 어떤 구조로 write/read를 처리하는지 볼 때 사용한다.

수업에서 작성한 master/slave 코드는 AXI4-Lite 동작을 이해하기 위한 교육용 구조이고, 실제 상용 수준 IP 코드로 바로 쓰기 위한 완성본은 아니다. 대신 `valid/ready` handshake, address/data latch, response 생성, register bank 접근을 손으로 구현해 보면서 Vivado가 생성하는 AXI peripheral template을 읽을 수 있게 만드는 것이 목표다.

0619 과제는 AXI4-Lite slave module을 설계하고 master-slave 연동 simulation을 확인한 뒤 source code와 simulation capture를 제출하는 것이다. 이 노트에서는 0619 수업 소스인 `260619_AXI_Mater_Slave`의 master/slave/TB 파형 확인을 기준으로 정리한다.

## 현재 소스 위치

| 위치 | 내용 |
| :--- | :--- |
| [260619_AXI_Mater_Slave](../helloHDL/260619_AXI_Mater_Slave) | AXI4-Lite master/slave 직접 작성 Vivado 프로젝트 |
| [axi_master.sv](../helloHDL/260619_AXI_Mater_Slave/260619_AXI_Mater_Slave.srcs/sources_1/new/axi_master.sv) | CPU-side 요청을 AXI4-Lite `AW/W/B/AR/R` channel로 변환 |
| [axi_slave.sv](../helloHDL/260619_AXI_Mater_Slave/260619_AXI_Mater_Slave.srcs/sources_1/new/axi_slave.sv) | AXI4-Lite 요청을 받아 `slv_reg0~3` register bank read/write |
| [tb_axi_master_slave.sv](../helloHDL/260619_AXI_Mater_Slave/260619_AXI_Mater_Slave.srcs/sim_1/new/tb_axi_master_slave.sv) | write 4회, read 4회 transaction을 넣는 기본 testbench |
| [ip_repo/260619_myip_1.0](../helloHDL/ip_repo/260619_myip_1.0) | Vivado AXI4-Lite peripheral 생성 결과 |
| [260619_myip_v1_0.v](../helloHDL/ip_repo/260619_myip_1.0/hdl/260619_myip_v1_0.v) | 생성 IP top wrapper, `S00_AXI` slave instance 연결 |
| [260619_myip_v1_0_S00_AXI.v](../helloHDL/ip_repo/260619_myip_1.0/hdl/260619_myip_v1_0_S00_AXI.v) | 생성 AXI4-Lite slave template, `slv_reg0~3` 포함 |

## AXI4-Lite IP 생성 흐름

Vivado의 `Create and Package New IP`에서 `Create a new AXI4 peripheral`을 선택하면 AXI4-Lite slave interface가 포함된 IP skeleton을 만들 수 있다. 수업에서는 `S00_AXI` slave interface, 32-bit data width, 4개 register 구조를 기준으로 봤다.

| 생성 항목 | 의미 |
| :--- | :--- |
| `S00_AXI` | 생성 IP가 외부 AXI master와 연결되는 slave interface |
| `C_S00_AXI_DATA_WIDTH=32` | AXI data width 32-bit |
| `C_S00_AXI_ADDR_WIDTH=4` | 4개 32-bit register 접근에 필요한 address width |
| `slv_reg0~3` | AXI4-Lite로 접근 가능한 내부 register bank |
| `component.xml` | Vivado IP repository에서 IP를 인식하기 위한 metadata |

생성된 top wrapper [260619_myip_v1_0.v](../helloHDL/ip_repo/260619_myip_1.0/hdl/260619_myip_v1_0.v)는 `s00_axi_*` port를 그대로 하위 [260619_myip_v1_0_S00_AXI.v](../helloHDL/ip_repo/260619_myip_1.0/hdl/260619_myip_v1_0_S00_AXI.v)에 연결한다. 실제 register write/read 동작은 `S00_AXI` module 내부에 들어 있다.

수업에서 설명한 Vivado 흐름은 `Tools -> Create and Package New IP -> Create AXI Peripheral` 순서다. 이번에는 직접 IP 내용을 완성하기보다 template을 얻는 목적이었고, interface는 AXI4-Lite, mode는 slave, data width는 32-bit, register 수는 기본 4개로 둔다. 생성 결과는 프로젝트 주변의 `ip_repo` 아래에 생기며, 그 안의 `hdl` 폴더에서 top wrapper와 `S00_AXI` template을 확인한다.

| Vivado 선택 | 수업 기준 |
| :--- | :--- |
| IP 생성 메뉴 | `Tools -> Create and Package New IP` |
| Peripheral 종류 | AXI4 peripheral |
| Interface | AXI4-Lite slave |
| Data width | 32-bit |
| Register count | 4개 |
| 저장 위치 | IP Repository |
| 확인할 코드 | `hdl/*_v1_0.v`, `hdl/*_S00_AXI.v` |

## 직접 작성 Master 코드

[axi_master.sv](../helloHDL/260619_AXI_Mater_Slave/260619_AXI_Mater_Slave.srcs/sources_1/new/axi_master.sv)는 간단한 CPU-side 입력을 AXI4-Lite transaction으로 바꾼다.

| CPU-side 신호 | 역할 |
| :--- | :--- |
| `transfer` | transaction 시작 pulse |
| `write` | `1`: write transaction, `0`: read transaction |
| `addr` | 접근할 AXI address |
| `wdata` | write data |
| `ready` | write 또는 read transaction 완료 |
| `rdata` | read transaction에서 받은 data |

Master는 write와 read channel을 별도 FSM으로 나누어 둔다.

| Channel | FSM | 시작 조건 | 완료 조건 |
| :--- | :--- | :--- | :--- |
| `AW` | `AW_IDLE -> AW_VALID` | `transfer & write` | `AWREADY` |
| `W` | `W_IDLE -> W_VALID` | `transfer & write` | `WREADY` |
| `B` | `B_IDLE -> B_READY` | write data phase 이후 | `BVALID` |
| `AR` | `AR_IDLE -> AR_VALID` | `transfer & !write` | `ARREADY` |
| `R` | `R_IDLE -> R_READY` | `ARVALID` 이후 | `RVALID` |

현재 master는 `w_ready`와 `r_ready`를 합쳐 `ready = w_ready | r_ready`로 내보낸다. testbench의 `axi_write`, `axi_read` task는 이 `ready`가 올라올 때까지 기다린 뒤 다음 transaction으로 넘어간다.

## 직접 작성 Slave 코드

[axi_slave.sv](../helloHDL/260619_AXI_Mater_Slave/260619_AXI_Mater_Slave.srcs/sources_1/new/axi_slave.sv)는 4개의 32-bit register를 갖는 AXI4-Lite slave 구조다.

| 내부 신호 | 역할 |
| :--- | :--- |
| `slv_reg0~3` | address `0x00`, `0x04`, `0x08`, `0x0C`에 대응하는 register |
| `addr_r` | write address decode용 address |
| `araddr` | read address decode용 address |
| `BRESP=2'b00` | write response OKAY |
| `RRESP=2'b00` | read response OKAY |

Write 쪽은 `AWVALID`를 보고 `AWREADY`를 만들고, `WVALID`와 write address handshake 조건을 바탕으로 `WREADY`를 만든 뒤 `addr_r[3:2]`로 register를 선택한다. Read 쪽은 `ARVALID`를 보고 `ARREADY`를 만들고, `araddr[3:2]`에 따라 `RDATA`로 `slv_reg0~3` 중 하나를 내보낸다.

| Address | Register |
| :--- | :--- |
| `0x00` | `slv_reg0` |
| `0x04` | `slv_reg1` |
| `0x08` | `slv_reg2` |
| `0x0C` | `slv_reg3` |

현재 직접 작성 slave는 수업 중 구조를 이해하기 위한 단순 FSM 형태다. Vivado 생성 template과 비교하면 `WSTRB` byte enable, `AWPROT/ARPROT`, `aw_en`, `slv_reg_wren`, `slv_reg_rden` 같은 세부 제어가 생략되어 있다.

AXI4-Lite에서는 full AXI의 burst 관련 신호가 빠지므로, 수업 범위에서는 `LAST` 같은 full AXI 신호를 다루지 않는다. write는 address channel과 data channel이 따로 오지만 slave 입장에서는 둘 다 받은 뒤 register write를 수행해야 한다. 그래서 address는 latch하고, write data도 latch한 뒤, `AWVALID/AWREADY`와 `WVALID/WREADY` handshake가 모두 끝난 시점에 `BRESP=OKAY`와 `BVALID`를 내보내는 흐름으로 이해한다.

## Vivado 생성 Slave Template 비교

[260619_myip_v1_0_S00_AXI.v](../helloHDL/ip_repo/260619_myip_1.0/hdl/260619_myip_v1_0_S00_AXI.v)는 Vivado가 생성한 AXI4-Lite slave 예제다. 직접 작성한 `axi_slave.sv`와 같은 4-register 구조를 쓰지만, AXI4-Lite template답게 handshake와 register write enable을 더 정형화해서 만든다.

| 생성 template 요소 | 의미 |
| :--- | :--- |
| `axi_awready`, `axi_wready` | `S_AXI_AWVALID`와 `S_AXI_WVALID`가 함께 유효할 때 1-cycle ready |
| `aw_en` | outstanding transaction 없이 write 1개씩 처리하기 위한 gate |
| `slv_reg_wren` | address/data handshake가 모두 성립했을 때 register write enable |
| `S_AXI_WSTRB` | byte lane별 write enable |
| `axi_bvalid`, `S_AXI_BRESP` | write response valid와 OKAY response |
| `slv_reg_rden` | read address handshake 기준 register read enable |
| `reg_data_out`, `axi_rdata` | address decode 결과를 read data channel로 전달 |

직접 작성 코드와 생성 template을 같이 보면, 수업 코드의 FSM이 AXI4-Lite 동작을 이해하기 위한 단순 모델이고, Vivado template은 실제 IP packaging에 필요한 port와 byte strobe, read/write enable을 더 갖춘 형태라는 차이를 볼 수 있다.

## Testbench 시나리오

[tb_axi_master_slave.sv](../helloHDL/260619_AXI_Mater_Slave/260619_AXI_Mater_Slave.srcs/sim_1/new/tb_axi_master_slave.sv)는 10 ns 주기 clock을 만들고, reset을 3 cycle 유지한 뒤 write 4회와 read 4회를 순서대로 실행한다.

| 순서 | Task | Address | Data |
| :--- | :--- | :--- | :--- |
| 1 | `axi_write` | `32'h00` | `32'h11111111` |
| 2 | `axi_write` | `32'h04` | `32'h22222222` |
| 3 | `axi_write` | `32'h08` | `32'h33333333` |
| 4 | `axi_write` | `32'h0c` | `32'h44444444` |
| 5 | `axi_read` | `32'h00` | expected `32'h11111111` |
| 6 | `axi_read` | `32'h04` | expected `32'h22222222` |
| 7 | `axi_read` | `32'h08` | expected `32'h33333333` |
| 8 | `axi_read` | `32'h0c` | expected `32'h44444444` |

파형에서는 write phase에서 `AWADDR`, `WDATA`, `BVALID/BREADY` 순서를 보고, read phase에서 `ARADDR`, `RDATA`, `RVALID/RREADY` 순서를 확인한다.

수업 중 testbench 작성 흐름은 write task와 read task를 나누어 보는 방식이었다. write task는 `addr`, `wdata`, `write=1`, `transfer=1`을 넣은 뒤 다음 clock에서 `transfer=0`으로 내리고, `ready`가 올라올 때까지 기다린다. read task는 address만 넣고 `write=0`, `transfer=1`로 시작한 뒤 `ready`와 `rdata`를 확인한다.

| TB 확인점 | 관찰 대상 |
| :--- | :--- |
| `transfer` pulse | 1-cycle 시작 요청 |
| `write` 값 | write/read task 구분 |
| `ready` 대기 | transaction 완료 기준 |
| `slv_reg0~3` | write 결과 저장 확인 |
| `rdata` | readback 기대값 확인 |

## 수업 중 handshake 정리

AXI4-Lite write는 `AW`, `W`, `B` channel이 각각 다른 역할을 갖는다. master가 address를 `AWADDR`로 보내고 `AWVALID`를 올리면, slave는 address를 latch한 뒤 `AWREADY`로 받았다는 표시를 준다. data도 같은 방식으로 `WDATA/WVALID/WREADY` handshake를 거치며, address와 data가 모두 처리되면 slave는 `BVALID`와 `BRESP=2'b00`으로 OKAY response를 낸다.

| Channel | 수업 설명 핵심 |
| :--- | :--- |
| `AW` | write address 전달, slave address latch |
| `W` | write data 전달, slave data latch |
| `B` | write 처리 결과 response, `2'b00` OKAY |
| `AR` | read address 전달, slave read address latch |
| `R` | read data와 response 반환 |

Read는 `ARVALID/ARREADY` handshake 후 address에 맞는 register 값을 `RDATA`로 내보내고 `RVALID/RREADY` handshake로 완료된다. master 내부에서는 write 완료 ready와 read 완료 ready가 서로 다른 의미를 가지므로, 수업 코드처럼 `w_ready`, `r_ready`로 나눈 뒤 `ready = w_ready | r_ready`로 CPU-side 완료 신호를 만드는 구조가 필요하다.

여기서 `AWREADY`, `WREADY`, `BREADY`, `RREADY`는 AXI channel handshake용 ready이고, CPU-side의 `ready`는 testbench task가 다음 transaction으로 넘어가기 위한 내부 완료 신호다. 이름은 비슷하지만 의미가 다르므로 파형을 볼 때 두 ready를 섞어 보면 안 된다.

## 0619 TB 파형 확인

로컬 macOS에는 Vivado/xsim 명령이 없어서, 같은 0619 TB sequence를 `/tmp`의 임시 testbench로 복사한 뒤 `iverilog`/`vvp`로 VCD를 생성해 파형 흐름을 확인했다. repo 안의 원본 `tb_axi_master_slave.sv`는 수정하지 않았고, 임시 TB에는 VCD dump와 강제 종료 시점만 추가했다.

실행 결과는 PASS가 아니라 첫 write transaction 진입 후 파형이 멈추는 상태다. 45 ns에 첫 write 요청이 들어가고, 55 ns에 master가 `AWVALID`와 `WVALID`를 올리지만, slave의 `AWREADY`와 `WREADY`가 0인 상태로 유지되며 `ready`도 0이다. VCD는 65 ns 시점에서 더 이상 진행되지 않아, testbench가 첫 `axi_write(32'h00, 32'h11111111)`의 `wait(ready)`를 빠져나오지 못하는 상태로 해석된다.

| 시간 | 파형 상태 | 해석 |
| :--- | :--- | :--- |
| 0 ns | `ARESETn=0`, `AWVALID=0`, `WVALID=0`, `ready=0` | reset 시작 |
| 25 ns | `ARESETn=1`, master/slave FSM idle | reset 해제 후 idle |
| 45 ns | `transfer=1`, `write=1`, `addr=0`, `wdata=11111111` | 첫 write request 입력 |
| 55 ns | `AWADDR=0`, `AWVALID=1`, `WDATA=11111111`, `WVALID=1` | master가 write address/data valid 출력 |
| 55 ns | `AWREADY=0`, `WREADY=0`, `BVALID=0`, `ready=0` | slave handshake 미완료 |
| 65 ns | `AWVALID=1`, `WVALID=1`, `AWREADY=0`, `WREADY=0`, `ready=0` | 첫 write transaction 대기 상태 지속 |

파형상 master 쪽은 write request를 받고 `AW_VALID`, `W_VALID` 상태로 들어가지만, slave 쪽 ready handshake가 완료되지 않기 때문에 `B` response까지 진행하지 못한다. 그래서 이후 `slv_reg0` write, 두 번째 write transaction, readback 파형은 아직 관찰되지 않는다.

현재 파형에서 우선 확인할 원인은 slave의 write address/data handshake 구조와 register write 위치다. 특히 `axi_slave.sv`는 `addr_r`, `araddr`, `slv_reg0~3` 갱신을 조합 블록 안에서 다루고 있어, Vivado 생성 template의 `slv_reg_wren`, `slv_reg_rden`처럼 clock 기준 write/read enable로 분리하는 구조와 비교해 볼 필요가 있다.

## 파형 캡처 기준

| 확인 대상 | 파형 신호 |
| :--- | :--- |
| Write address handshake | `AWADDR`, `AWVALID`, `AWREADY` |
| Write data handshake | `WDATA`, `WVALID`, `WREADY` |
| Write response handshake | `BRESP`, `BVALID`, `BREADY` |
| Read address handshake | `ARADDR`, `ARVALID`, `ARREADY` |
| Read data handshake | `RDATA`, `RRESP`, `RVALID`, `RREADY` |
| CPU-side 제어 | `transfer`, `write`, `addr`, `wdata`, `ready`, `rdata` |
| Slave register | `slv_reg0`, `slv_reg1`, `slv_reg2`, `slv_reg3` |

제출용 capture에서는 write 후 register 값이 바뀌고, 이후 read에서 같은 address의 `RDATA`가 기대값으로 나오는 흐름이 보여야 한다. 현재 0619 TB 파형은 첫 write handshake에서 멈추므로, 먼저 `AWREADY/WREADY`가 올라오고 `ready`가 pulse 되는 구조를 확인해야 한다.

## 현재 코드 확인 포인트

현재 직접 작성 코드는 수업 실습 중인 상태라서 simulation 결과를 확정하기 전에 다음 항목을 확인해야 한다.

| 항목 | 확인 이유 |
| :--- | :--- |
| `axi_slave.sv` register write 위치 | `slv_reg0~3` 갱신이 clocked logic 기준으로 안정적인지 확인 |
| write address 저장 | `addr_r`가 `AWADDR` handshake 시점 값을 유지하는지 확인 |
| read address 저장 | `araddr`가 `ARADDR` handshake 시점 값을 유지하는지 확인 |
| `ready` pulse | `axi_write`/`axi_read` task가 다음 transaction으로 넘어가는 기준 확인 |
| Vivado template 비교 | `slv_reg_wren`, `slv_reg_rden`, `WSTRB` 구조 참고 |

직접 수정이 필요한지 판단하기 전에는 먼저 파형으로 `AW/W/B`와 `AR/R` handshake가 기대 순서로 발생하는지 확인한다. 특히 register readback이 기대값과 다르면 slave의 address latch와 register write 위치를 Vivado template 구조와 비교해서 보는 것이 좋다.

## 과제/실습 연결

주말 과제의 핵심은 Xilinx가 생성한 AXI4-Lite peripheral template을 읽고, 수업에서 만든 master/slave 개념과 연결해 보는 것이다. template code는 처음 보면 port와 주석이 많아서 복잡해 보이지만, 안쪽 구조는 `AW`, `W`, `B`, `AR`, `R` channel과 `slv_reg0~3` register bank를 이해하면 따라갈 수 있다.

| 과제 항목 | 정리 기준 |
| :--- | :--- |
| Template code 분석 | Vivado 생성 `S00_AXI` 구조 파악 |
| 수업 코드 연결 | master 코드와 slave/template 동작 비교 |
| Testbench 작성 | write/read task와 master-slave 연동 확인 |
| Simulation capture | timing diagram 또는 waveform 캡처 |
| 제출물 | code, simulation result, 분석 내용 업로드 |

다음 수업에서는 이 AXI peripheral 구조를 실제 보드 실습으로 이어갈 예정이다. MicroBlaze 같은 CPU가 C 코드에서 AXI register에 write/read를 수행하고, custom IP 내부 register가 LED, switch, button, timer, UART, I2C, SPI 같은 외부 동작과 연결되는 흐름이다. 그래서 AXI protocol을 알아야 Vivado template을 수정해 custom IP와 register interface를 연결할 수 있다.

이번 과제 제출 항목은 다음처럼 정리한다.

- [x] 코드 분석 report 제출: Vivado 생성 AXI4-Lite template의 구조와 주요 signal 설명을 한글 또는 doc 파일로 작성
- [x] 수업 모듈 code와 template 모듈 code 연동: 수업에서 만든 master/slave 개념을 template module과 연결하고 write/read testbench 작성
- [x] 시뮬레이션 결과 업로드: write/read test 결과와 simulation waveform capture 첨부
- [x] report에 timing diagram 포함: waveform을 바탕으로 AXI4-Lite transaction 순서를 timing chart 형태로 정리

여기서 timing diagram은 XDC나 FPGA pin timing 제약을 뜻하는 것이 아니라, simulation waveform에서 확인한 AXI4-Lite handshake 순서를 그림으로 정리하라는 의미로 보는 것이 맞다. 따라서 report에는 Vivado behavioral simulation waveform 캡처와 함께, write/read transaction이 clock 기준으로 어떤 순서로 진행되는지 간단한 timing chart를 넣으면 된다.

| Report timing diagram 항목 | 넣을 내용 |
| :--- | :--- |
| Write 시작 | `transfer=1`, `write=1`, `addr`, `wdata` 입력 |
| Write address phase | `AWADDR`, `AWVALID`, `AWREADY` handshake |
| Write data phase | `WDATA`, `WVALID`, `WREADY` handshake |
| Write response phase | `BVALID`, `BREADY`, `BRESP=2'b00` 확인 |
| Write 완료 | CPU-side `ready` pulse, register write 결과 |
| Read 시작 | `transfer=1`, `write=0`, `addr` 입력 |
| Read address phase | `ARADDR`, `ARVALID`, `ARREADY` handshake |
| Read data phase | `RDATA`, `RVALID`, `RREADY`, `RRESP=2'b00` 확인 |
| Read 완료 | CPU-side `ready` pulse, `rdata` 기대값 확인 |

캡처는 전체 흐름 1장과 write/read 확대 캡처를 나누면 설명하기 쉽다. 전체 흐름에서는 reset 이후 write 4회와 read 4회가 순서대로 끝나는 것을 보이고, 확대 캡처에서는 `valid`와 `ready`가 동시에 1이 되는 handshake 순간을 표시한다. 수업에서 말한 "timing diagram 함께 그리기"는 이 waveform을 그대로 붙이는 것에서 끝내지 말고, `AW/W/B`와 `AR/R` channel이 어떤 순서로 완료되는지 report 안에서 한 번 더 도식화하라는 의미로 정리한다.

## 다음에 확인할 것

- 0619 TB에서 첫 write transaction이 `BVALID/BREADY`까지 진행되는지 확인
- write 4회, read 4회가 끝까지 진행되는지 확인
- readback 값이 `11111111`, `22222222`, `33333333`, `44444444`로 나오는지 확인
- 파형에서 `AWVALID/AWREADY`, `WVALID/WREADY`, `BVALID/BREADY` 순서 캡처
- 파형에서 `ARVALID/ARREADY`, `RVALID/RREADY`, `RDATA` 순서 캡처
- 직접 작성 `axi_slave.sv`와 Vivado 생성 `S00_AXI` template의 register write/read enable 차이 정리
- Vivado 생성 template과 직접 작성 assignment code의 register write/read 구조 비교
