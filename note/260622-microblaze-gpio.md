# 26-06-22 - AXI4-Lite Template 분석, GPIO Custom IP, MicroBlaze Block Design

## 수업 흐름

0619 과제에서 다룬 AXI4-Lite master/slave 구조를 다시 보면서, Vivado가 생성해 주는 AXI peripheral template을 코드 단위로 읽었다. 핵심은 `AW`, `W`, `B`, `AR`, `R` channel이 각각 독립된 valid/ready handshake를 갖고, slave template 내부에서 이 handshake를 register write/read enable로 바꾸는 흐름을 이해하는 것이다.

오전에는 `Create and Package New IP`로 만든 `axi_template`의 top wrapper와 `S00_AXI` slave module을 분석했다. 이후에는 수업용 TB를 새로 만들어 AXI4-Lite template register에 write 4회, read 4회를 넣고 readback 값이 맞는지 확인했다. 마지막에는 같은 구조를 GPIO custom IP로 확장하고, packaged IP를 MicroBlaze block design에 연결하는 흐름으로 넘어갔다.

GPIO 쪽은 STM32 계열 datasheet와 reference manual에서 GPIO register 설명을 찾아보는 방식도 함께 언급됐다. FPGA custom IP에서도 CPU가 AXI register에 값을 쓰고, 그 register 값이 LED, switch, button, FND 같은 외부 입출력 제어로 이어지는 구조를 잡는 것이 목표다. 이후 `gpio_1.0` packaging merge, driver `Makefile` 수정 주의점, `260622_MicroBlaze_GPIO` 프로젝트의 MicroBlaze 기본 구성, UART Lite 연결, XSA export, Vitis C application 실행 흐름까지 이어졌다.

## MicroBlaze GPIO 보강 포인트

MicroBlaze 기반 AXI GPIO system을 만들기 위해서는 bus protocol, AXI slave template, custom GPIO IP, Vitis software 실행 흐름을 한 번에 묶어 봐야 한다. 수업 실습에서는 이 중 AXI4-Lite template 코드 분석과 GPIO custom IP를 MicroBlaze system에 붙이는 흐름이 직접 연결된다.

| 범위 | 핵심 내용 |
| :--- | :--- |
| AHB/APB | 마스터-슬레이브 구조의 bus 방식 |
| AXI | 5개 독립 channel 기반 point-to-point interface |
| AXI handshake | `VALID`와 `READY` 동시 1에서 정보 전달 |
| Sticky signal | destination 수락 전까지 `VALID` 유지 |
| AXI slave template | `slv_reg0~3`, address decode, write/read response |
| GPIO custom IP | `CR`, `IDR`, `ODR` register로 입출력 제어 |
| MicroBlaze system | CPU, local memory, MDM, clock/reset, AXI interconnect, UART Lite, custom GPIO |
| Vitis | XSA 기반 platform 생성, C application 작성, `Launch Hardware` 실행 |

`AHB/APB`와 `AXI`는 모두 CPU와 peripheral을 연결하는 bus/interface 계층이지만, 수업에서 실제 코드로 다룬 것은 AXI4-Lite slave template이다. AXI4-Lite에서는 read/write data burst 같은 복잡한 기능보다 register access에 초점이 맞춰져 있고, custom IP register를 CPU가 memory-mapped 방식으로 읽고 쓰는 데 적합하다.

## 현재 소스 위치

| 위치 | 내용 |
| :--- | :--- |
| [260622_AXI_Template](../helloHDL/260622_AXI_Template) | Vivado AXI4-Lite template 분석 및 TB 실습 프로젝트 |
| [axi_template_v1_0.v](../helloHDL/260622_AXI_Template/260622_AXI_Template.srcs/sources_1/imports/hdl/axi_template_v1_0.v) | AXI template top wrapper, `S00_AXI` instance 연결 |
| [axi_template_v1_0_S00_AXI.v](../helloHDL/260622_AXI_Template/260622_AXI_Template.srcs/sources_1/imports/hdl/axi_template_v1_0_S00_AXI.v) | AXI4-Lite slave template 본체, `slv_reg0~3` register 포함 |
| [tb_axi_slave.sv](../helloHDL/260622_AXI_Template/260622_AXI_Template.srcs/sim_1/new/tb_axi_slave.sv) | template slave에 write/read transaction을 직접 넣는 TB |
| [ip_repo/axi_template_1.0](../helloHDL/ip_repo/axi_template_1.0) | Vivado가 생성한 AXI template IP repository |
| [ip_repo/gpio_1.0](../helloHDL/ip_repo/gpio_1.0) | GPIO custom IP로 확장하기 위해 새로 만든 IP draft |
| [gpio driver Makefile](../helloHDL/ip_repo/gpio_1.0/drivers/gpio_v1_0/src/Makefile) | custom IP C driver header copy 규칙 수정 대상 |
| [260622_MicroBlaze_GPIO](../helloHDL/260622_MicroBlaze_GPIO) | MicroBlaze 기반 GPIO 테스트 block design 프로젝트 |
| [GPIO_Test.bd](../helloHDL/260622_MicroBlaze_GPIO/260622_MicroBlaze_GPIO.srcs/sources_1/bd/GPIO_Test/GPIO_Test.bd) | MicroBlaze, UART Lite, custom GPIO block design |
| [Basys-3-Master.xdc](../helloHDL/260622_MicroBlaze_GPIO/260622_MicroBlaze_GPIO.srcs/constrs_1/imports/Basys-3-Master.xdc) | Basys3 clock, reset, UART, GPIOA LED pin 제약 |

## AXI4-Lite Template 생성 흐름

Vivado에서는 `Tools -> Create and Package New IP -> Create a new AXI4 peripheral` 순서로 AXI peripheral template을 만든다. 수업에서는 이름을 `axi_template`으로 두고, interface는 기본 `S00_AXI` slave, data width는 32-bit, register 수는 기본 4개로 두었다.

처음에는 template 코드를 얻고 분석하는 것이 목적이므로 `Next Steps`에서 `Add IP to the repository`로 진행했다. 이후 GPIO 실습처럼 IP 내부를 바로 수정해야 할 때는 `Edit IP`로 열어 custom port와 내부 logic을 추가하는 흐름으로 넘어간다.

| 설정 항목 | 수업 기준 |
| :--- | :--- |
| Vivado 메뉴 | `Tools -> Create and Package New IP` |
| Peripheral 종류 | AXI4 peripheral |
| Interface | `S00_AXI` AXI4-Lite slave |
| Data width | 32-bit |
| Register count | 4개 |
| Template 분석 위치 | `hdl/*_v1_0.v`, `hdl/*_S00_AXI.v` |

## Valid/Ready Handshake

AXI4-Lite는 write와 read가 하나의 덩어리로 움직이는 것이 아니라 channel별 handshake로 나뉜다. `valid`는 보내는 쪽이 정보가 유효하다는 뜻으로 올리고, `ready`는 받는 쪽이 받을 수 있다는 뜻으로 올린다. clock edge에서 `valid`와 `ready`가 동시에 1이면 해당 channel의 전달이 성립한다.

| Channel | 전달 정보 | Handshake |
| :--- | :--- | :--- |
| `AW` | write address | `AWVALID/AWREADY` |
| `W` | write data, byte strobe | `WVALID/WREADY` |
| `B` | write response | `BVALID/BREADY` |
| `AR` | read address | `ARVALID/ARREADY` |
| `R` | read data, read response | `RVALID/RREADY` |

`VALID`는 sticky signal로 봐야 한다. source가 `VALID`를 올렸다면 destination이 `READY`를 올려 handshake가 성립할 때까지 유지해야 하며, 중간에 임의로 내리면 transaction이 유실되거나 timing diagram 해석이 틀어질 수 있다. 반대로 `READY`는 destination 상태에 따라 먼저 올라와 있어도 되고, `VALID` 이후에 올라와도 된다.

write transaction은 `AW`와 `W`가 모두 처리된 뒤 `B` response로 끝난다. read transaction은 `AR` address를 받은 뒤, slave가 `RDATA`와 `RVALID`를 내보내고 master가 `RREADY`로 받으면서 끝난다.

## S00_AXI 코드 구조

[axi_template_v1_0.v](../helloHDL/260622_AXI_Template/260622_AXI_Template.srcs/sources_1/imports/hdl/axi_template_v1_0.v)는 top wrapper다. 외부의 `s00_axi_*` port를 하위 [axi_template_v1_0_S00_AXI.v](../helloHDL/260622_AXI_Template/260622_AXI_Template.srcs/sources_1/imports/hdl/axi_template_v1_0_S00_AXI.v)에 그대로 연결하고, 실제 AXI4-Lite 동작은 `S00_AXI` module에서 처리한다.

`S00_AXI` 내부에서 가장 먼저 봐야 할 부분은 4개의 memory-mapped register다. `slv_reg0~3`는 CPU 또는 MicroBlaze가 AXI4-Lite로 접근할 수 있는 register bank이고, 주소는 32-bit register 기준으로 4 byte 단위로 증가한다.

| Register | Address decode | 의미 |
| :--- | :--- | :--- |
| `slv_reg0` | `axi_awaddr[3:2] == 2'h0` | address `0x00` |
| `slv_reg1` | `axi_awaddr[3:2] == 2'h1` | address `0x04` |
| `slv_reg2` | `axi_awaddr[3:2] == 2'h2` | address `0x08` |
| `slv_reg3` | `axi_awaddr[3:2] == 2'h3` | address `0x0C` |

`ADDR_LSB`는 byte offset을 제외하고 register index를 고르기 위한 값이다. data width가 32-bit이면 한 register가 4 byte이므로 address 하위 2 bit는 byte 위치로 쓰고, register 선택은 `addr[3:2]`를 기준으로 한다.

## Write 동작

write 쪽은 `AWVALID`와 `WVALID`가 함께 올라온 상태에서 `aw_en`이 1이면 `axi_awready`와 `axi_wready`를 1 cycle 올린다. 이때 `axi_awaddr`에 write address를 저장하고, `slv_reg_wren` 조건이 성립하면 `slv_reg0~3` 중 하나에 `S_AXI_WDATA`를 기록한다.

| 신호/조건 | 역할 |
| :--- | :--- |
| `aw_en` | write transaction 1건씩 처리하기 위한 gate |
| `axi_awready` | write address 수신 가능 표시 |
| `axi_wready` | write data 수신 가능 표시 |
| `axi_awaddr` | handshake 시점 write address 저장 |
| `slv_reg_wren` | register write enable |
| `S_AXI_WSTRB` | byte lane별 write enable |

`S_AXI_WSTRB`는 32-bit write data 중 어느 byte lane을 실제로 쓸지 고르는 신호다. `4'b1111`이면 4 byte 전체를 쓰고, 특정 bit만 1이면 해당 byte만 갱신한다. 수업에서는 이 부분을 `byte_index` loop와 `[(byte_index*8) +: 8]` part-select로 읽었다.

write가 끝나면 slave는 `BVALID=1`, `BRESP=2'b00`을 내보낸다. 여기서 `2'b00`은 OKAY response로, 수업 template에서는 error response를 따로 만들지 않고 정상 응답만 사용한다.

## Read 동작

read 쪽은 `ARVALID`가 올라오면 `axi_arready`를 1 cycle 올리고 `axi_araddr`에 read address를 저장한다. 이후 `slv_reg_rden` 조건에서 address decode 결과를 `reg_data_out`에 고르고, 다음 clock에서 `axi_rdata`로 내보낸다.

| 신호/조건 | 역할 |
| :--- | :--- |
| `axi_arready` | read address 수신 가능 표시 |
| `axi_araddr` | handshake 시점 read address 저장 |
| `slv_reg_rden` | register read enable |
| `reg_data_out` | address decode로 선택된 register 값 |
| `axi_rdata` | read data channel 출력 |
| `axi_rvalid` | read data 유효 표시 |

read response도 `RRESP=2'b00`으로 OKAY만 반환한다. master는 `RVALID`가 올라온 뒤 `RREADY`로 read data를 받는다.

## Testbench와 Simulation 확인

[tb_axi_slave.sv](../helloHDL/260622_AXI_Template/260622_AXI_Template.srcs/sim_1/new/tb_axi_slave.sv)는 `axi_write`와 `axi_read` task를 만들어 template slave에 직접 transaction을 넣는다. write task는 `AWADDR/AWVALID`, `WDATA/WVALID`, `WSTRB`, `BREADY`를 올리고, `AWREADY/WREADY`와 `BVALID`를 기다린다. read task는 `ARADDR/ARVALID`, `RREADY`를 올리고, `ARREADY`와 `RVALID`를 기다린다.

현재 소스를 `iverilog`/`vvp`로 실행하면 write 4회와 read 4회가 모두 같은 값으로 readback된다. TB 자체에는 PASS assertion은 없고, `$display` 출력으로 결과를 확인하는 구조다.

| 시간 | 동작 | 확인 값 |
| :--- | :--- | :--- |
| 95 ns | write `0x00` | `0xDEADBEEF` |
| 145 ns | write `0x04` | `0xCAFEBABE` |
| 195 ns | write `0x08` | `0x12345678` |
| 245 ns | write `0x0C` | `0xAAAABBBB` |
| 315 ns | read `0x00` | `0xDEADBEEF` |
| 365 ns | read `0x04` | `0xCAFEBABE` |
| 415 ns | read `0x08` | `0x12345678` |
| 465 ns | read `0x0C` | `0xAAAABBBB` |

수업 파형 설명에서는 write 시 `AWADDR/AWVALID`와 `WDATA/WVALID`가 먼저 나가고, slave가 `AWREADY/WREADY`를 올린 뒤 `BVALID/BREADY`로 write response가 끝나는 순서를 확인했다. read에서는 `ARADDR/ARVALID`, `ARREADY`, `RDATA/RVALID/RREADY` 순서를 확인했다.

## GPIO Custom IP 방향

AXI4-Lite template 분석 이후에는 같은 구조를 GPIO custom IP로 확장하는 방향을 잡았다. GPIO는 CPU가 AXI register에 값을 쓰면 FPGA 외부 pin, LED, switch, button, FND 같은 장치에 반영되는 대표적인 예시다.

수업에서는 STM32 계열 문서의 GPIO register 설명도 참고 대상으로 언급했다. MCU datasheet나 reference manual에서 GPIO control register, input data register, output data register가 어떤 의미를 갖는지 보고, 비슷한 관점으로 FPGA custom IP register map을 설계하는 흐름이다.

현재 [ip_repo/gpio_1.0](../helloHDL/ip_repo/gpio_1.0)에는 GPIO IP draft가 생겨 있다. [gpio_v1_0.v](../helloHDL/ip_repo/gpio_1.0/hdl/gpio_v1_0.v)는 AXI4-Lite wrapper에 외부 `io_port`를 추가하고, 하위 [gpio_v1_0_S00_AXI.v](../helloHDL/ip_repo/gpio_1.0/hdl/gpio_v1_0_S00_AXI.v)에서 나온 `cr`, `idr`, `odr`를 내부 `gpio` module과 연결하는 방향으로 수정 중이다.

수업에서는 GPIO pin을 입력으로 쓸지 출력으로 쓸지 결정하는 설정값이 필요하다고 설명했다. 이 설정을 control register인 `cr`로 두고, `cr[i]`가 1이면 해당 bit를 output mode로, 0이면 input mode로 해석하는 구조다. output mode에서는 `odr[i]` 값을 `io_port[i]`로 내보내고, input mode에서는 output driver를 high impedance인 `1'bz`로 만들어 외부 입력을 받을 수 있게 한다.

현재 `gpio` module의 기본 동작은 다음 구조다.

```systemverilog
assign io_port[i] = cr[i] ? odr[i] : 1'bz;
assign idr[i]     = cr[i] ? 1'bz   : io_port[i];
```

여기서 `odr`은 output data register 성격이고, `idr`은 input data register 성격이다. 수업에서는 STM32 문서의 GPIO register 이름을 참고해서, FPGA custom IP에서도 비슷하게 `CR`, `ODR`, `IDR`로 나누어 생각하면 이해하기 쉽다고 설명했다.

| GPIO 신호 | 역할 |
| :--- | :--- |
| `cr` | pin별 output/input 방향 제어 |
| `odr` | output data register 성격의 출력값 |
| `idr` | input data register 성격의 입력값 |
| `io_port` | FPGA 외부 pin과 연결될 GPIO port |

`gpio_v1_0_S00_AXI.v` 입장에서는 `cr`와 `odr`는 AXI register 값에서 GPIO core 쪽으로 나가는 신호이고, `idr`은 GPIO core에서 AXI read path 쪽으로 들어오는 신호다. 그래서 top module에서 보는 GPIO core의 방향과 `S00_AXI` module에서 보는 방향이 반대로 보일 수 있다.

| 현재 register map | 연결 대상 | 용도 |
| :--- | :--- | :--- |
| `slv_reg0[7:0]` | `cr` | pin별 입력/출력 방향 설정 |
| `slv_reg1[7:0]` | 현재 GPIO 연결 없음 | 후속 `idr` readback 또는 확장 후보 |
| `slv_reg2[7:0]` | `odr` | output mode일 때 외부 pin으로 내보낼 값 |
| `slv_reg3` | 미사용 | 후속 확장용 reserve |

현재 GPIO draft는 register map을 코드에 연결하는 중간 단계다. `gpio_v1_0.v`에는 `io_port`, 내부 `cr/idr/odr` wire, `gpio` instance가 추가됐고, `gpio_v1_0_S00_AXI.v`에는 `cr/idr/odr` port가 추가됐다. 현재 소스 기준으로 `cr`은 `slv_reg0[7:0]`, `odr`은 `slv_reg2[7:0]`에 연결되어 있으므로, Vitis C code에서 LED 출력값을 쓰려면 custom IP base address에 `0x08` offset을 더한 register에 write하는 흐름으로 이해한다. `idr` readback을 register read path에 연결하는 부분은 후속 정리 대상이다.

## GPIO IP Packaging과 Driver Makefile

`gpio_1.0`은 `Edit IP`로 연 IP project에서 HDL을 수정한 뒤 다시 package해야 한다. `Package IP` 화면의 `Packaging Steps`에서 변경된 파일을 merge하면 항목이 초록색 상태로 바뀌고, re-package 후 edit IP 창을 닫으면 local IP repository 쪽에 수정된 IP가 반영된다. 수업에서는 이 merge 단계를 빠뜨리면 `io_port` 같은 새 port가 repository에 반영되지 않아 이후 block design에서 보이지 않을 수 있다고 강조했다.

packaging 결과로 [component.xml](../helloHDL/ip_repo/gpio_1.0/component.xml)에는 `hdl/gpio_v1_0.v`, `hdl/gpio_v1_0_S00_AXI.v`, driver source, xgui 파일이 IP 구성 파일로 등록된다. 이 중 software driver 쪽은 [drivers/gpio_v1_0/src/Makefile](../helloHDL/ip_repo/gpio_1.0/drivers/gpio_v1_0/src/Makefile)을 함께 확인해야 한다.

| 항목 | 확인 내용 |
| :--- | :--- |
| Packaging merge | HDL 수정분과 port 변경분을 IP metadata에 반영 |
| `component.xml` | HDL, driver, xgui 파일 등록 확인 |
| driver `Makefile` | SDK/Vitis C driver build 시 header/source 규칙 확인 |
| 수정 시점 | custom IP 생성 직후, MicroBlaze system에 붙이기 전 |

수업에서는 driver `Makefile`의 header include 대상을 wildcard 함수 형태로 정리해야 한다고 설명했다. custom IP를 MicroBlaze system에 붙이고 주변장치까지 추가한 뒤 수정하면 반영이 꼬일 수 있으므로, IP를 package한 직후 바로 확인하는 편이 안전하다. 특히 `wildcard`와 `*.h` 사이의 공백, 괄호까지 맞지 않으면 Vitis 쪽 C driver build에서 header copy 단계가 꼬일 수 있다.

```make
INCLUDEFILES=$(wildcard *.h)
```

driver source file 쪽도 `wildcard *.c` 형태로 확인해야 한다. 현재 Makefile에는 `LIBSOURCES=*.c`, `INCLUDEFILES=*.h`처럼 단순 glob 문자열이 들어 있으므로, Vitis driver build에서 source/header 인식 문제가 생기면 `LIBSOURCES=$(wildcard *.c)`, `INCLUDEFILES=$(wildcard *.h)` 형태로 고치는 것을 우선 확인한다.

현재 repository의 `Makefile`은 `INCLUDEFILES=*.h` 상태로 보이므로, 실제 Vivado/Vitis build 전에 수업에서 설명한 형태로 반영됐는지 재확인해야 한다. 수업에서는 이 수정이 늦어지면 MicroBlaze system을 구성한 뒤에도 같은 driver 문제가 반복될 수 있으니, custom IP packaging 직후 바로 수정하는 순서를 권장했다.

## Edit IP 완료와 원래 Project 복귀

`Edit IP`로 열린 `gpio_v1_0` project에서 `Re-Package IP`까지 끝낸 뒤에는 edit project를 닫고 원래 Vivado project로 돌아와야 한다. 원래 project의 IP catalog는 자동으로 최신 custom IP를 다시 읽지 않을 수 있으므로, 이어지는 block design 작업에서 같은 IP를 쓰려면 repository refresh 상태를 먼저 확인한다.

| 단계 | 작업 내용 |
| :--- | :--- |
| Edit IP 종료 | `Review and Package -> Re-Package IP` 후 edit project close |
| Repository 경로 확인 | `Project Manager -> Settings -> IP -> Repository` |
| Custom IP 경로 | `helloHDL/ip_repo` 또는 `gpio_1.0`이 포함된 repository root 등록 |
| Refresh | `Refresh All Repositories` 실행 |

이번 확인에서는 `Refresh All Repositories`까지 수행했다. 기존 block design에 아직 `gpio_v1_0` instance가 올라간 상태가 아니면 `Upgrade Selected`가 뜨지 않는 것이 자연스럽고, `Validate Design`도 block design을 열어 IP instance를 추가한 뒤 확인하는 단계다.

## MicroBlaze GPIO Block Design 구성

`260622_MicroBlaze_GPIO` 프로젝트에서는 `IP Integrator`로 MicroBlaze 기반 block design을 새로 만드는 흐름을 진행했다. 기존 AXI template 분석은 RTL/TB 관점이었고, 여기서는 CPU가 AXI interconnect를 통해 custom IP와 주변장치를 제어하는 SoC 구성을 Vivado block design으로 잡는 것이 목적이다.

| 단계 | 작업 내용 |
| :--- | :--- |
| Block design 생성 | `IP Integrator -> Create Block Design`, 이름 `GPIO_Test` |
| CPU 추가 | `+` 버튼에서 `MicroBlaze` 검색 후 추가 |
| Block Automation | `Run Block Automation`, local memory `128KB` 설정 |
| Clock 설정 | `Clocking Wizard`의 board interface를 `sys clock`으로 설정 |
| Connection Automation | clock/reset/LMB/AXI 연결 자동 생성 |
| 기본 구성 | MicroBlaze, local memory, debug 회로, clock/reset 회로, AXI interconnect |

MicroBlaze는 block design 안에서 CPU 역할을 한다. `Run Block Automation`을 실행하면 local memory와 debug용 회로, clock/reset 관련 IP가 함께 배치된다. 수업에서는 `ILMB`가 instruction local memory, `DLMB`가 data local memory 쪽으로 연결되는 구조를 설명했고, instruction memory와 data memory가 나뉘어 보이므로 Harvard 구조 관점으로 이해할 수 있다고 정리했다.

`Clocking Wizard`는 board의 system clock을 받아 내부 clock으로 분배하는 역할이다. 수업에서는 입력 clock을 100 MHz 기준으로 쓰거나 필요하면 낮출 수 있다고 설명했고, 이번 실습에서는 board interface를 `sys clock`으로 맞추는 정도만 진행했다. 이후 `Run Connection Automation`에서 clock/reset 관련 항목을 전체 선택하면 Vivado가 자동으로 선을 연결한다.

현재 [GPIO_Test.bd](../helloHDL/260622_MicroBlaze_GPIO/260622_MicroBlaze_GPIO.srcs/sources_1/bd/GPIO_Test/GPIO_Test.bd)에는 `microblaze_0`, `microblaze_0_local_memory`, `clk_wiz_1`, `rst_clk_wiz_1_100M`, `axi_uartlite_0`, `microblaze_0_axi_periph`, `gpio_0`가 저장되어 있다. 외부 interface는 `usb_uart`, `diff_clock_rtl`, 일반 port는 `reset`, `GPIOA`가 잡혀 있으므로, 이후 wrapper/XDC 단계에서는 이 top-level port 이름과 constraint의 `get_ports` 이름을 맞춰야 한다.

## UART Lite와 AXI Interconnect 연결

GPIO custom IP를 붙이기 전에 기본 주변장치로 `AXI Uartlite`를 추가했다. `+` 버튼에서 `UART`를 검색해 `AXI Uartlite`를 넣고, IP 설정에서 board interface를 `usb uart`로 맞춘다. `IP Configuration`에서는 baud rate를 `115200`, data bits를 `8`, parity를 `No Parity` 기준으로 둔다.

| UART 설정 | 값 |
| :--- | :--- |
| IP | `AXI Uartlite` |
| Board interface | `usb uart` |
| Baud rate | `115200` |
| Data bits | `8` |
| Parity | `No Parity` |

UART Lite를 추가한 뒤 `Run Connection Automation`을 다시 실행하면 아직 연결되지 않은 AXI interface와 clock/reset이 자동으로 연결된다. 이때 Vivado가 `AXI Interconnect`를 생성하고, MicroBlaze 쪽 master interface와 UART/GPIO 같은 slave peripheral 사이를 이어 준다. 개념적으로는 CPU가 master, interconnect가 중간 연결망, UART/GPIO/custom IP가 slave peripheral이 되는 구조다.

## Custom GPIO IP를 Block Design에 추가

MicroBlaze 기본 system과 UART Lite 연결을 만든 뒤에는 직접 만든 `gpio_v1_0` custom IP를 block design에 추가하는 단계로 넘어간다. `+` 버튼에서 `GPIO`를 검색하면 Xilinx가 제공하는 `AXI GPIO`도 함께 보이는데, 이것은 수업에서 직접 만든 `gpio_v1_0`과 다른 IP다. 이번 실습에서 써야 하는 것은 user repository 쪽에 등록된 `gpio_v1_0`이다.

| 단계 | 작업 내용 |
| :--- | :--- |
| GPIO 검색 | `+` 버튼에서 `GPIO` 검색 |
| 기본 IP 구분 | Xilinx 제공 `AXI GPIO`와 custom `gpio_v1_0` 구분 |
| Repository 확인 | `Settings -> IP -> Repository`에서 custom IP 경로 확인 |
| Repository refresh | `Refresh All Repositories` 후 `gpio_v1_0` 표시 확인 |
| Custom IP 추가 | user repository의 `gpio_v1_0`을 block design에 추가 |
| 자동 연결 | `Run Connection Automation`으로 clock/reset/AXI 연결 |
| 외부 포트 생성 | `io_port` 우클릭 후 `Make External`, 단축키 `Ctrl+T` |

custom IP가 보이지 않으면 repository 경로가 잘못됐거나, `Edit IP`에서 `Re-Package IP` 후 원래 project에 refresh가 반영되지 않은 상태로 볼 수 있다. custom IP를 block design에 올린 뒤에는 `S00_AXI`, clock, reset 연결을 확인한다. 이후 GPIO pin을 실제 보드 외부로 빼야 하므로 `io_port`에서 오른쪽 마우스를 누르고 `Make External`을 선택해 external port를 만든다. 이 기능은 `Ctrl+T` 단축키로도 실행할 수 있다.

이번 실습에서는 `io_port` 방향이 처음에 input으로 잡히는 문제가 있었고, `gpio_v1_0.v`의 port 방향과 IP packager metadata를 다시 맞춘 뒤 복구했다. 이후 block design에서 custom GPIO IP를 다시 반영하고 `io_port`에 `Make External`을 적용해 외부 GPIO port 생성까지 완료했다.

외부 port가 생성되면 기본 이름은 `io_port_0[7:0]`처럼 잡힌다. 생성된 external port를 클릭한 뒤 왼쪽 `External Port Properties`에서 name을 `GPIOA`로 바꿔, 이후 constraint나 block design 확인 시 GPIO port 의미가 바로 보이도록 정리했다.

## Generate Block Design Output Products

external port까지 정리한 뒤에는 block design의 output products를 생성한다. Vivado 왼쪽 `Flow Navigator`에서 `IP Integrator -> Generate Block Design`을 실행하고, synthesis option과 run setting을 지정한 뒤 generate를 진행한다.

1. external port 이름이 `GPIOA`로 되어 있는지 확인한다.
2. `IP Integrator -> Generate Block Design`을 클릭한다.
3. `Synthesis Options`는 `Global`로 둔다.
4. `Run Settings`는 `On local host`로 둔다.
5. `Number of jobs`는 수업 PC 기준 `16`, macOS 가상환경에서는 `8`로 둔다.
6. `Generate`를 클릭한다.
7. 설정 확인 창이 뜨면 `Apply`를 클릭한다.
8. `Managing Output Products` 창에서 `Hierarchical elaboration completed` 상태를 확인한다.
9. 마지막에 `Generation of output products completed successfully`가 뜨면 output products 생성 완료로 본다.

## HDL Wrapper 생성과 Basys3 XDC 추가

block design output products를 만든 뒤에는 design sources에 있는 `GPIO_Test`를 top-level HDL로 감싸는 wrapper를 만든다. `Sources -> Design Sources`에서 `GPIO_Test`를 오른쪽 마우스로 클릭하고 `Create HDL Wrapper`를 선택한다. 옵션은 `Let Vivado manage wrapper and auto-update`로 두면 Vivado가 block design 변경에 맞춰 wrapper를 자동 갱신한다. wrapper 생성 후 sources view를 새로고침하면 `GPIO_Test_wrapper.v`가 보인다.

현재 생성된 [GPIO_Test_wrapper.v](../helloHDL/260622_MicroBlaze_GPIO/260622_MicroBlaze_GPIO.gen/sources_1/bd/GPIO_Test/hdl/GPIO_Test_wrapper.v)는 block design의 외부 port를 Verilog top module port로 내보내는 역할이다. 여기에는 `GPIOA[7:0]`, differential clock, reset, USB UART RX/TX가 top-level port로 선언되어 있다.

| Wrapper port | 방향 | 역할 |
| :--- | :--- | :--- |
| `GPIOA[7:0]` | `inout` | custom GPIO 외부 pin |
| `diff_clock_rtl_clk_p/n` | `input` | block design clock 입력 |
| `reset` | `input` | system reset 입력 |
| `usb_uart_rxd` | `input` | USB UART 수신 |
| `usb_uart_txd` | `output` | USB UART 송신 |

wrapper까지 생성한 뒤에는 Basys3 board pin과 top-level port를 연결할 XDC를 추가해야 한다. Vivado에서는 `Add Sources -> Add or Create Constraints -> Add Files`로 Basys3 master XDC를 추가한 뒤, 실제 top port 이름에 맞춰 필요한 줄만 활성화하거나 이름을 바꾼다. 이번 프로젝트는 top port가 `GPIOA`, `reset`, `usb_uart_rxd`, `usb_uart_txd`처럼 생성됐으므로 XDC의 `get_ports` 이름이 wrapper port와 일치하는지 확인해야 한다.

로컬에서 추가할 Basys3 master XDC 후보는 다음 파일이다.

```text
/Users/mumallaeng/git/Vault/activities/korcham/helloHDL/260421_uart_fsm/uart_fsm.srcs/constrs_1/new/Basys-3-Master.xdc
```

이 파일은 Basys3 pin map을 담고 있지만, 현재 wrapper port와 이름이 그대로 맞지는 않는다. 예를 들어 일반 UART 예제에서는 `rx/tx/rst/clk`처럼 되어 있을 수 있고, 이번 wrapper는 `usb_uart_rxd/usb_uart_txd/reset/GPIOA`를 사용한다. 따라서 XDC를 추가한 뒤 `get_ports` 이름을 현재 top module에 맞게 수정해야 한다. `GPIOA[7:0]`는 LED나 PMOD 중 실제 연결할 대상에 맞춰 pin을 선택하고, clock/reset/UART는 board automation으로 이미 생성된 XDC와 중복되지 않는지도 함께 확인한다.

이번 XDC 수정에서는 Vivado project가 참조하는 constraint 파일을 다음 위치로 맞췄다.

```text
260622_MicroBlaze_GPIO.srcs/constrs_1/imports/Basys-3-Master.xdc
```

활성화한 Basys3 constraint는 다음 범위다.

| 구분 | 설정 |
| :--- | :--- |
| Clock | `W5`, `LVCMOS33`, `get_ports {sys_clock}`, 100 MHz clock 생성 |
| GPIO LED 출력 | `GPIOA[0]~GPIOA[7]`을 Basys3 LED 0~7 pin에 연결 |
| Button reset | `U18`, `get_ports {reset}` |
| USB UART | `B18 -> usb_uart_rxd`, `A18 -> usb_uart_txd` |

주의할 점은 wrapper port와 XDC port 이름이 반드시 일치해야 한다는 것이다. 현재 디스크에 생성된 `GPIO_Test_wrapper.v`는 clock port가 `diff_clock_rtl_clk_p/n`로 보이므로, bitstream 전에 Vivado에서 clock external port명을 `sys_clock`으로 맞춘 뒤 wrapper를 다시 생성하거나, XDC clock port명을 실제 wrapper port에 맞춰 수정해야 한다.

XDC까지 정리한 뒤에는 bitstream 생성과 hardware export를 거쳐 Vitis에서 C application을 작성하는 흐름으로 이어진다. 여기부터는 Vivado hardware platform을 Vitis에 넘기는 단계이므로, 실제 작업 전에 wrapper port와 XDC 이름이 맞는지 먼저 확인해야 한다.

## XSA Export와 Vitis IDE 연결

bitstream까지 생성한 뒤에는 Vivado에서 hardware platform을 XSA로 내보낸다. 메뉴는 `File -> Export -> Export Hardware`이고, export wizard에서 `Include bitstream` 옵션을 선택해야 Vitis에서 bitstream이 포함된 hardware platform을 사용할 수 있다.

| 단계 | 설정 |
| :--- | :--- |
| Vivado export 메뉴 | `File -> Export -> Export Hardware` |
| Bitstream 포함 | `Include bitstream` 선택 |
| Export 경로 | `helloHDL/XSA/` |
| XSA file name | `GPIO_Test_wrapper` |
| 생성 확인 | `GPIO_Test_wrapper.xsa` 파일 확인 |

XSA 파일이 생성되면 Vivado에서 `Tools -> Launch Vitis IDE`를 실행한다. Vitis는 MicroBlaze 위에서 동작할 C 언어 application을 작성하고 build하는 IDE로 보면 된다. workspace는 해당 날짜의 `helloHDL` 프로젝트 하위에 `vitis_repo`를 만들어 지정한다.

| Vitis 단계 | 설정 |
| :--- | :--- |
| Workspace | `helloHDL/260622_MicroBlaze_GPIO/vitis_repo` |
| Project 생성 | `Create Application Project` 선택 |
| Wizard 시작 | 첫 화면 `Next` |
| Platform 선택 | `Create a new platform from hardware (XSA)` |
| XSA 입력 | `helloHDL/XSA/GPIO_Test_wrapper.xsa` 선택 |
| Application project name | `ledBlink` 입력 후 `Next` |
| Domain details | 기본 설정 유지 후 `Next` |
| Template | `Hello World` 선택 후 `Finish` |

이후 Vitis application project에서 MicroBlaze가 custom GPIO IP register에 값을 쓰고, 그 값이 `GPIOA` LED 출력으로 이어지는지 확인하는 C code를 작성하게 된다.

## Vitis C Application과 LED Blink 확인

Vitis에서는 XSA로부터 hardware platform을 만들고, 그 위에 application project를 생성한다. 수업에서는 application 이름을 `ledBlink`로 잡고, template은 `Hello World`를 선택한 뒤 GPIO register에 직접 값을 쓰는 방식으로 수정했다.

| Vitis 확인 항목 | 내용 |
| :--- | :--- |
| `xparameters.h` | Vivado hardware platform에서 넘어온 IP base address 확인 |
| custom GPIO base address | `xparameters.h`에서 `gpio_0` 또는 custom IP 관련 base address 확인 |
| Control register write | GPIO pin을 output mode로 설정 |
| Output data write | LED pattern 값을 GPIO output register에 write |
| 실행 메뉴 | application 우클릭 후 `Run As -> Launch Hardware` |

수업에서 GPIOA 1차 확인용으로 잡은 Vitis application 설정은 다음과 같다.

| Vitis 설정 항목 | 값 |
| :--- | :--- |
| Project name | `ledBlink` |
| System project name | `ledBlink_system` |
| Processor | `microblaze_0` |
| Associated application | `ledBlink` |
| Domain details | 기본 설정 유지 |
| Template | `Hello World` |
| 실행 | `Run As -> Launch Hardware` |

`xparameters.h`는 Vitis가 hardware platform 정보를 바탕으로 만들어 주는 header다. 이 파일 안에는 UART Lite, custom GPIO 같은 peripheral의 base address가 들어 있으므로, C code에서 pointer 또는 memory-mapped I/O macro로 해당 주소에 접근한다. 현재 GPIO RTL 기준으로는 `cr`이 `slv_reg0`, `odr`이 `slv_reg2`에 연결되어 있으므로, control register에는 output enable 값을 쓰고, output data register에는 LED에 보낼 pattern 값을 쓴다.

C code에서는 시작 시 `init_platform()`을 호출하고, `#define`으로 register address 또는 offset을 정리한 뒤 pointer write로 register 값을 바꾸는 방식으로 GPIO를 제어한다. 이때 register offset은 AXI slave template의 address decode와 맞아야 하며, `CR=0x00`, `IDR=0x04`, `ODR=0x08`처럼 정의했다면 RTL의 `slv_reg` 연결도 같은 의미로 맞춰야 한다.

GPIOA만 먼저 확인할 때의 C code는 [helloworld.c](../helloHDL/260622_MicroBlaze_GPIO/vitis_repo/ledBlink/src/helloworld.c)에 정리했다. `GPIOA_BASEADDR`는 `xparameters.h`에 생성되는 `XPAR_GPIO_0_S00_AXI_BASEADDR`를 사용하고, `GPIOA_CR`에 `0xff`를 써서 8개 pin을 output mode로 둔다. 이후 `GPIOA_ODR`에 `0xff`와 `0x00`을 번갈아 쓰면 GPIOA에 연결된 LED 8개가 0.2초 간격으로 모두 켜졌다 꺼지는 blink 동작을 확인할 수 있다.

보드에 bitstream과 application이 정상적으로 올라가면 LED가 깜빡이는 것으로 1차 동작을 확인한다. 수업에서는 LED blink가 한 번에 되지 않을 수 있으므로, block design 저장, wrapper port, XDC port, bitstream 포함 XSA, Vitis platform, C code base address를 순서대로 확인해야 한다고 설명했다.

## 과제 방향

0622 수업 끝부분의 숙제는 `20260622_MicroBlaze_GPIO LED 좌우 이동`이다. 수업에서 `GPIOA[7:0]`를 LED에 연결한 구조를 기준으로, `GPIOA`와 동일한 방식의 `GPIOB[7:0]`를 추가해 Basys3 LED 16개를 모두 제어하는 것이 목표다. 한 번에 여러 LED를 모두 켜는 것이 아니라, 한 개 LED만 켜진 상태가 좌측 끝까지 순차 이동한 뒤 다시 우측 끝까지 순차 이동하는 pattern을 무한 반복해야 한다.

| 과제 항목 | 내용 |
| :--- | :--- |
| 과제명 | `20260622_MicroBlaze_GPIO LED 좌우 이동` |
| GPIOA | 수업에서 연결한 `GPIOA[7:0]` LED 8개 구성 |
| GPIOB | `GPIOA`와 동일하게 `GPIOB[7:0]` 추가 |
| LED 연결 | `GPIOA[7:0]`, `GPIOB[7:0]`로 LED 16개 제어 |
| 동작 pattern | 한 개 LED만 ON |
| 이동 방향 | 좌끝까지 순차 이동 후 우끝까지 순차 이동 |
| 반복 조건 | 좌우 이동 무한 반복 |
| 구현 위치 | Vitis C application에서 GPIO register write |
| 제출물 | 코드와 동작 영상 업로드 |

과제용 정리 파일은 [260622-MicroBlaze-GPIO-LED-shift](../assignment/260622-MicroBlaze-GPIO-LED-shift)에 두었다. 여기에는 Vitis C application 예시와 `GPIOA/GPIOB` 16 LED용 XDC 기준을 함께 정리했다.

## 다음에 확인할 것

- wrapper의 clock port 이름과 XDC의 `sys_clock` 이름 일치 여부 확인
- `GPIOA[0]~GPIOA[7]`, `GPIOB[0]~GPIOB[7]` LED pin 제약 적용 상태 확인
- board automation으로 생성된 clock/reset/UART XDC와 Basys3 master XDC 중복 여부 확인
- bitstream 생성 전 `Validate Design`, synthesis, implementation 순서 진행
- `Export Hardware`에서 `Include bitstream` 선택 후 `helloHDL/XSA/GPIO_Test_wrapper.xsa` 생성 확인
- Vitis workspace를 `helloHDL/260622_MicroBlaze_GPIO/vitis_repo`로 지정하고 XSA 기반 platform 생성
- GPIO custom IP register write가 LED 출력으로 이어지는 C application 동작 확인
- GPIOB 추가 시 block design external port, wrapper, XDC LED pin, C register offset을 함께 갱신
