# 26-06-12 - SPI CPHA, I2C Master, SPI/I2C 데모 방향

## 수업 흐름

0612 수업은 전날 진행한 SPI Master 코드에서 `CPHA` 기능을 어떻게 넣을지 다시 설명하고, I2C Master를 어떤 command port와 quarter-clock 구조로 만들지 잡은 뒤, 이후 SPI/I2C를 이용한 보드 데모와 발표 방향을 정리하는 흐름이었다.

핵심은 SPI를 단순히 `sclk`, `mosi`, `miso`, `ss_n` 신호 이름으로만 보는 것이 아니라, master와 slave가 half-clock 단위로 언제 데이터를 내보내고 언제 샘플링하는지 설명할 수 있어야 한다는 점이다. 특히 `CPHA`는 clock phase이므로 sampling/shift 시점을 한 half-clock 밀어 생각해야 한다.

I2C 쪽에서는 master의 기준을 `SCL` clock을 만들어 주는 쪽으로 잡았다. CPU나 host가 I2C Master block에 `START`, write, read, `STOP` 같은 command를 내리고, I2C Master가 그 command에 맞춰 `SCL`과 `SDA`를 protocol 순서대로 움직이는 구조로 이해하면 된다.

## 현재 소스 위치

| 위치 | 내용 |
| :--- | :--- |
| [260612_SPI_Master](../helloHDL/260612_SPI_Master) | 0612 기준 Vivado SPI Master 프로젝트 |
| [spi_master.sv](../helloHDL/260612_SPI_Master/260612_SPI_Master.srcs/sources_1/new/spi_master.sv) | `cpol`, `cpha`, `clk_div`, `tx_data`, SPI line을 가진 SPI Master RTL |
| [tb_spi_master.sv](../helloHDL/260612_SPI_Master/260612_SPI_Master.srcs/sim/new/tb_spi_master.sv) | SPI mode 0~3 loopback testbench |
| [260612_I2C_Master](../helloHDL/260612_I2C_Master) | 0612 기준 Vivado I2C Master 프로젝트 |
| [I2C_Master.sv](../helloHDL/260612_I2C_Master/260612_I2C_Master.srcs/sources_1/new/I2C_Master.sv) | command port, open-drain `SDA`, quarter tick 기반 I2C Master RTL |
| [tb_I2C_Mater.sv](../helloHDL/260612_I2C_Master/260612_I2C_Master.srcs/sim_1/new/tb_I2C_Mater.sv) | 현재 비어 있는 I2C simulation shell |

현재 `260612_SPI_Master` 폴더에서는 직접 작성 소스로 `spi_master.sv`와 `tb_spi_master.sv`가 확인된다. 0611 코드가 `CPOL` 중심이었다면, 0612 코드는 `CPHA` 입력과 mode별 testbench 시나리오까지 붙은 상태로 보는 것이 맞다. `260612_I2C_Master` 폴더에서는 직접 작성 소스로 `I2C_Master.sv`와 빈 testbench shell인 `tb_I2C_Mater.sv`가 확인된다. 따라서 I2C 쪽은 RTL 구조와 compile 가능 여부까지 정리하고, 구체적인 test scenario는 이후 작성 대상으로 남긴다.

## 260612 소스 코드 읽는 순서

| 순서 | 파일 | 확인할 내용 |
| :--- | :--- | :--- |
| 1 | [spi_master.sv](../helloHDL/260612_SPI_Master/260612_SPI_Master.srcs/sources_1/new/spi_master.sv) | `CPOL/CPHA`, `half_tick`, `step`, `rx_data` 마무리 방식 |
| 2 | [tb_spi_master.sv](../helloHDL/260612_SPI_Master/260612_SPI_Master.srcs/sim/new/tb_spi_master.sv) | mode 0~3 loopback, `8'hAA`, `done` 대기 |
| 3 | [I2C_Master.sv](../helloHDL/260612_I2C_Master/260612_I2C_Master.srcs/sources_1/new/I2C_Master.sv)의 `I2C_Master_top` | `inout sda`, `sda_i/sda_o`, open-drain 연결 |
| 4 | [I2C_Master.sv](../helloHDL/260612_I2C_Master/260612_I2C_Master.srcs/sources_1/new/I2C_Master.sv)의 `I2C_Master` | `START`, `WAIT_CMD`, `DATA`, `DATA_ACK`, `STOP` FSM |
| 5 | [tb_I2C_Mater.sv](../helloHDL/260612_I2C_Master/260612_I2C_Master.srcs/sim_1/new/tb_I2C_Mater.sv) | 현재 빈 shell, 이후 command sequence 작성 대상 |

## SPI CPOL/CPHA 정리

SPI mode는 `CPOL`과 `CPHA` 조합으로 정해진다.

| 항목 | 의미 | 수업에서 잡은 해석 |
| :--- | :--- | :--- |
| `CPOL` | clock polarity | `sclk` idle level, `0`: idle low, `1`: idle high |
| `CPHA` | clock phase | data sampling/shift 시점을 첫 half-clock에 둘지, 한 half-clock 뒤로 밀지 결정 |

`CPOL`은 clock의 기본 극성이므로 비교적 단순하다. `CPHA`는 clock 한 주기를 절반씩 나누어 봐야 한다. master 기준으로 `MOSI`에 내보내는 시점과 `MISO`를 샘플링하는 시점이 있고, slave 기준으로는 `MOSI`를 입력으로 받아들이는 시점과 `MISO`를 내보내는 시점이 대응된다.

정리하면 `CPHA=0`은 첫 번째 edge부터 유효 데이터를 샘플링하는 구조이고, `CPHA=1`은 첫 번째 edge를 data setup 쪽으로 사용하고 다음 edge에서 샘플링하는 구조로 이해하면 된다. 그래서 CPHA 기능을 구현할 때는 단순히 `cpha` port만 추가하는 것이 아니라, `step` 또는 half-clock edge 처리에서 sampling과 shifting 순서를 분기해야 한다.

## 0612 SPI Master 코드 기준

현재 [spi_master.sv](../helloHDL/260612_SPI_Master/260612_SPI_Master.srcs/sources_1/new/spi_master.sv)는 0611 코드에 비해 `cpha` 입력, `cpha_r` latch, mode별 edge 동작 분기가 추가된 형태다.

| 코드 요소 | 현재 역할 |
| :--- | :--- |
| `input logic cpol` | 전송 시작 시 `cpol_r` latch, `sclk` idle level 결정 |
| `input logic cpha` | 전송 시작 시 `cpha_r` latch |
| `clk_div`, `clk_div_r` | system clock을 SPI half-clock tick으로 나누기 위한 분주값 |
| `half_tick` | `DATA` 상태에서 `div_cnt == clk_div_r`일 때 1-cycle pulse, `sclk_r` toggle 기준 |
| `step` | 첫 번째 edge와 두 번째 edge 구분용 내부 상태 |
| `tx_shift_reg`, `rx_shift_reg` | 송신/수신 8-bit shift register |
| `IDLE -> START -> DATA -> STOP` | SPI 1-byte 전송 FSM 흐름 |

현재 코드에서 `START` 상태는 `cpha_r == 0`일 때만 `tx_shift_reg[7]`을 먼저 `mosi`로 내보낸다. `CPHA=0`은 첫 edge에서 바로 sample해야 하므로 첫 bit를 미리 올려 두는 구조이고, `CPHA=1`은 첫 edge를 data setup으로 사용하므로 `START`에서는 아직 `mosi`를 밀지 않는다.

`DATA` 상태에서는 `half_tick`마다 `sclk_r`를 toggle하고, `step`으로 첫 번째 edge와 두 번째 edge를 나눈다. 첫 번째 edge(`step==0`)에서 `CPHA=0`이면 `miso`를 sample하고, `CPHA=1`이면 `mosi`에 송신 bit를 올린다. 두 번째 edge(`step==1`)에서 `CPHA=0`이면 다음 `mosi` bit를 준비하고, `CPHA=1`이면 `miso`를 sample한다. 즉 0612 업데이트 코드에서는 `CPHA`에 따라 drive/sample 순서를 실제로 분기하고 있다.

전송 완료 판단은 두 번째 edge 시점에서 `bit_cnt == 7`일 때 수행한다. `CPHA=0`은 마지막 sample이 이미 첫 번째 edge에서 `rx_shift_reg`에 들어온 것으로 보고 `rx_data <= rx_shift_reg`를 사용한다. `CPHA=1`은 같은 clock edge에서 `rx_shift_reg` 갱신과 `rx_data` 갱신이 nonblocking assignment로 동시에 일어나므로, 마지막 `miso` 값을 직접 결합해 `rx_data <= {rx_shift_reg[6:0], miso}`로 마무리한다.

## 0612 SPI Master Testbench 기준

현재 [tb_spi_master.sv](../helloHDL/260612_SPI_Master/260612_SPI_Master.srcs/sim/new/tb_spi_master.sv)는 `mosi`와 `miso`를 `loop_wire`로 연결한 loopback 구조다. 실제 slave 동작 검증은 아니지만, master가 내보낸 serial data가 다시 master input으로 들어와 `rx_data`가 구성되는지 확인하기 위한 기본 testbench다.

| TB 요소 | 현재 역할 |
| :--- | :--- |
| `always #5 clk = ~clk` | 10 ns 주기 system clock 생성 |
| `repeat (3) @(posedge clk)` | reset 3 cycle 유지 |
| `clk_div = 4` | 주석 기준 100 MHz clock에서 10 MHz SCLK 생성 |
| `spi_set_mode(bit [1:0] mode)` | `{cpol, cpha}`를 한 번에 설정 |
| `spi_send_data(8'hAA)` | `tx_data` 설정, `start` 1-cycle pulse, `done` 대기 |
| `loop_wire` | `mosi`와 `miso`를 연결해 loopback 구성 |

TB는 `2'b00`, `2'b01`, `2'b10`, `2'b11` 순서로 SPI mode 0~3을 설정하고, 각 mode에서 `8'hAA`를 한 번씩 전송한다. 따라서 파형 캡처를 할 때는 mode가 바뀔 때마다 `cpol`, `cpha`, `sclk` idle level, 첫 edge에서의 `mosi/miso` 동작, `rx_data` 최종값을 같이 묶어 확인해야 한다.

## CPHA 구현 시 생각할 점

수업에서 강조한 관점은 half-clock 단위로 master와 slave의 입장을 나눠 보는 것이다.

| 관점 | 확인할 내용 |
| :--- | :--- |
| Master output | `MOSI` 변경 half-clock |
| Slave input | slave의 `MOSI` sampling edge |
| Slave output | slave의 `MISO` 변경 half-clock |
| Master input | master의 `MISO` sampling edge |

CPHA 기능을 검증하려면 `CPHA=0`과 `CPHA=1`을 같은 data pattern으로 돌려 보고, `sclk` edge 기준으로 `mosi`가 먼저 안정된 뒤 sample되는지 확인해야 한다. 현재 TB는 mode 0~3을 모두 실행하므로, `CPOL=0/1`에 따른 idle level과 `CPHA=0/1`에 따른 첫 edge 의미를 분리해서 보면 된다. `CPHA=1`에서는 첫 edge가 data 준비용으로 쓰이므로, 첫 bit를 언제 `mosi`에 올릴지와 마지막 `rx_data` 결합 방식이 특히 중요하다.

## I2C / IIC 개요

수업에서는 I2C와 IIC가 같은 말이라고 정리했다. 원래 명칭은 `IIC`(Inter-Integrated Circuit)이고, `I2C`(Inter-Integrated Circuit, I-squared-C로 읽음)라고도 표기한다.

| 항목 | I2C |
| :--- | :--- |
| 신호 | `SCL`(Serial Clock), `SDA`(Serial Data) 두 선 사용 |
| 선택 방식 | SPI처럼 slave select 선을 여러 개 두지 않고, slave address 기반 대상 선택 |
| 특징 | SPI보다 느린 편, 선 수가 적고 확장성 높음 |
| 관련 흐름 | I3C는 I2C의 속도와 기능 개선 표준, 실무에서는 I2C 사용 비중 높음 |

SPI(Serial Peripheral Interface)와 I2C는 둘 다 chip 간 serial communication에 쓰이지만 구조가 다르다. SPI는 `SCLK`(Serial Clock), `MOSI`(Master Out Slave In), `MISO`(Master In Slave Out), `SS_N`(Slave Select, active-low)으로 master가 slave를 직접 선택하고 전이중 전송을 만들기 쉽다. I2C는 `SCL`/`SDA` 두 선을 공유하고 address와 protocol 규칙으로 여러 slave를 다룬다.

I2C bus가 아무 전송도 하지 않는 idle 상태에서는 `SCL`과 `SDA`가 모두 high로 유지된다. 전송을 시작할 때는 `SCL`이 high인 상태에서 `SDA`가 high에서 low로 떨어지는 `START` 조건을 만들고, 전송을 끝낼 때는 `SCL`이 high인 상태에서 `SDA`가 low에서 high로 올라가는 `STOP` 조건을 만든다. 그래서 I2C 파형을 볼 때는 data bit만 보는 것이 아니라, `SCL` high 구간에서 `SDA`가 어떻게 변하는지도 함께 확인해야 한다.

I2C의 기본 전송 단위는 8-bit, 즉 1 byte이다. 처음 byte는 보통 `SLA`(Slave Address)와 `R/W`(Read/Write) bit로 구성된다. `R/W=0`이면 master가 slave로 data를 쓰는 write 동작이고, `R/W=1`이면 master가 slave로부터 data를 읽는 read 동작이다. 이 bit가 뒤에 이어지는 data byte의 방향을 결정하므로, I2C transaction을 설명할 때는 address뿐 아니라 read/write 방향도 같이 표시해야 한다.

각 byte 뒤에는 수신자가 `ACK`(Acknowledgement) 또는 `NACK`(Negative Acknowledgement)을 돌려준다. `ACK`는 byte를 정상적으로 받았다는 의미이고, `NACK`는 더 이상 받을 data가 없거나 수신을 종료하겠다는 의미로 사용된다. write transaction에서는 slave가 address와 data byte를 받은 뒤 `ACK`를 보내고, read transaction에서는 master가 slave로부터 data byte를 받은 뒤 계속 읽을 byte가 있으면 `ACK`, 마지막 byte에서는 `NACK`를 보낸 뒤 `STOP`으로 종료한다.

순차 read에서는 slave 내부 address pointer가 증가하면서 0번지, 1번지, 2번지처럼 연속된 byte를 읽을 수 있다. 이때 master가 1 byte만 읽고 싶으면 첫 data byte 뒤에 바로 `NACK`를 보내고 종료하고, 2 byte 또는 3 byte 이상을 읽고 싶으면 중간 byte마다 `ACK`를 보내 계속 read를 진행한다. 따라서 I2C read 파형에서는 address 단계, `R/W=1`, data byte, master의 `ACK/NACK`, `STOP`까지 이어지는 흐름을 한 transaction으로 묶어 봐야 한다.

## 0612 I2C Master 코드 기준

현재 [I2C_Master.sv](../helloHDL/260612_I2C_Master/260612_I2C_Master.srcs/sources_1/new/I2C_Master.sv)는 CPU/host가 I2C Master에게 command를 내려 주고, I2C Master가 `SCL`과 `SDA`를 protocol timing에 맞게 움직이는 구조다. 위쪽 `I2C_Master_top`은 board level의 `inout sda`를 내부 `sda_i`, `sda_o`로 나누고, 아래쪽 `I2C_Master`가 실제 FSM과 timing을 담당한다.

| 코드 요소 | 현재 역할 |
| :--- | :--- |
| `I2C_Master_top` | 외부 `inout sda`와 내부 `sda_i/sda_o` 분리 |
| `assign sda = sda_o ? 1'bz : 1'b0` | open-drain 방식 표현, `0` drive 또는 High-Z release |
| `cmd_start` | I2C `START` 조건 생성 명령 |
| `cmd_write` | `tx_data`를 SDA로 내보내는 write 명령 |
| `cmd_read` | SDA에서 data를 읽어 `rx_data`로 모으는 read 명령 |
| `cmd_stop` | I2C `STOP` 조건 생성 명령 |
| `tx_data`, `rx_data` | 8-bit 송신 data, 8-bit 수신 data |
| `ack_in` | read 후 master가 보낼 `ACK/NACK` 선택 |
| `ack_out` | write 후 slave에서 받은 `ACK/NACK` 저장 |
| `busy`, `done` | command 수행 중 상태, command 완료 pulse |
| `sda_i`, `sda_o` | 양방향 SDA를 내부에서 input/output으로 분리해 생각하기 위한 신호 |
| `scl` | I2C clock 출력, master 판별 기준 |
| `div_cnt`, `qtr_tick`, `step` | SCL 한 주기를 4개 구간으로 나누는 quarter-clock 진행 기준 |
| `bit_cnt`, `tx_shift_reg`, `rx_shift_reg` | 8-bit write/read data 진행 관리 |
| `is_read` | 현재 data phase가 read인지 write인지 구분 |
| `START -> WAIT_CMD -> DATA -> DATA_ACK -> STOP` | I2C command 처리 FSM 흐름 |

수업에서는 I2C Master의 기준을 "clock을 주는 쪽"으로 설명했다. CPU나 MCU 안쪽에 있는 I2C controller가 보통 master 역할을 맡고, 센서, RTC chip, LCD 같은 외부 peripheral은 slave device로 붙는다. SPI도 마찬가지로 `SCLK`를 만들어 주는 쪽이 master이므로, serial protocol을 볼 때는 먼저 누가 clock을 공급하는지 확인하면 구조를 잡기 쉽다.

I2C Master는 CPU/host가 직접 `SDA`를 bit마다 만지는 구조가 아니라, CPU/host가 `START`, write, read, `STOP` 같은 command를 I2C Master block에 넣고 I2C Master가 해당 protocol 동작을 수행하는 구조로 설계한다. 그래서 RTL port에도 command port, data port, `ACK/NACK` 관련 port, 완료 상태 port가 분리되어 있어야 한다.

`SDA`는 실제 board level에서는 bidirectional line이지만, RTL을 처음 설계할 때부터 `inout` 하나로 생각하면 timing을 따라가기 어렵다. 수업에서는 먼저 `sda_i`와 `sda_o`처럼 입력과 출력을 분리해 생각하고, 나중에 top level이나 별도 연결 회로에서 bidirectional SDA로 묶는 방식으로 접근했다.

I2C timing은 SPI에서 half-clock으로 생각했던 것보다 더 잘게 나누어 본다. SCL 한 주기를 네 구간으로 나누고, 각 quarter 구간에서 `SCL`과 `SDA`를 바꾸거나 sample한다. 예를 들어 read에서 SDA를 sample할 때는 SDA 변화 직후보다 안정된 구간에서 읽어야 하므로, 두 번째 구간보다 세 번째 구간처럼 data가 안정된 시점을 sample point로 잡는 식으로 생각한다.

SCL frequency도 quarter-clock 기준으로 계산해야 한다. Standard mode 100 kHz SCL을 만들고 싶다면 SCL 한 주기를 네 구간으로 나누므로 내부 quarter tick은 400 kHz 기준으로 움직여야 한다. 현재 코드의 `div_cnt == 250 - 1` 주석은 100 MHz system clock에서 400 kHz quarter tick을 만들기 위한 divider 관점으로 볼 수 있다.

현재 `I2C_Master.sv`는 `START`, `WAIT_CMD`, `DATA`, `DATA_ACK`, `STOP` 흐름을 모두 작성한 상태다. `DATA` 상태에서는 `is_read`가 0이면 `tx_shift_reg[7]`을 `sda_r`로 내보내고, `is_read`가 1이면 SDA를 release한 뒤 `sda_i`를 `rx_shift_reg`로 sample한다. 8-bit data phase가 끝나면 `DATA_ACK`로 넘어가고, write에서는 slave가 준 ACK/NACK을 `ack_out`에 저장하며 read에서는 master가 보낼 `ack_in_r`을 SDA에 싣는다.

Vivado에서 한 번 발생했던 오류는 reset edge와 reset 조건이 서로 맞지 않았기 때문이다. 첫 번째 always block이 `negedge reset`으로 되어 있으면서 내부에서는 `if (reset)`을 사용하면 active-low edge와 active-high 조건이 충돌한다. 현재 코드는 두 always block 모두 `posedge reset`과 `if (reset)`으로 맞춰 active-high reset 구조가 되었다.

현재 [tb_I2C_Mater.sv](../helloHDL/260612_I2C_Master/260612_I2C_Master.srcs/sim_1/new/tb_I2C_Mater.sv)는 module shell만 있는 상태다. 따라서 I2C Master는 RTL compile 기준으로는 정리되었지만, start/write/read/stop command sequence와 SDA ACK 모델을 넣는 testbench는 다음 단계에서 작성해야 한다.

## 부가 개념: handshake

통신에서 handshake는 본격적인 data 전송 전에 서로 통신할 준비가 되었는지 확인하거나, 전송 중 data가 정상적으로 받아들여졌는지 확인하는 절차를 말한다. 네트워크에서 TCP(Transmission Control Protocol)가 `SYN`(Synchronize) -> `SYN/ACK`(Synchronize/Acknowledgement) -> `ACK`(Acknowledgement) 순서로 연결을 여는 것이 대표적인 handshake 예시다.

다만 SPI/I2C에서 말하는 handshake는 TCP handshake와 같은 연결 수립 절차라기보다, bus나 protocol 수준에서 "상대가 선택되었는가", "이 byte를 받았는가", "다음 전송을 진행해도 되는가"를 확인하는 의미에 가깝다.

| 구분 | handshake 관점 |
| :--- | :--- |
| TCP network | 연결 시작 전 `SYN`, `SYN/ACK`, `ACK`로 양쪽 송수신 가능 상태 확인 |
| SPI | byte별 `ACK` 없음, `SS_N`으로 slave 선택, `SCLK` edge 기준 `MOSI/MISO` 동시 shift, 필요 시 상위 protocol에서 별도 status byte 또는 ready 신호 설계 |
| I2C | `START`, address 전송, `ACK`(Acknowledgement)/`NACK`(Negative Acknowledgement), data byte별 `ACK/NACK`, `STOP` 흐름, clock stretching도 handshake 성격 |
| RTL(Register Transfer Level) ready/valid | `valid`와 `ready`가 동시에 1일 때 data 전달 |

이번 수업 맥락에서 SPI는 `SS_N`이 low가 되면 선택된 slave가 `SCLK`에 맞춰 bit를 주고받는 구조이고, I2C는 address와 `ACK/NACK`로 상대 장치와 byte 수신 여부를 확인하는 구조라고 구분하면 된다. 그래서 SPI slave 데모를 만들 때 "값을 보냈다"에서 끝내지 않고, slave가 받은 command를 register에 저장했는지, status를 다시 돌려주는지 같은 상위 handshake를 직접 설계할 수도 있다.

## 과제 연결

0611에 나온 과제는 `SPI Master CPHA 기능 구현`이다. 제출물은 소스코드와 시뮬레이션 결과다.

이번 과제에서 확인해야 할 최소 항목은 다음과 같다.

| 확인 항목 | 내용 |
| :--- | :--- |
| `cpha` port | RTL port와 내부 latch 유무 확인 |
| `CPHA=0` 동작 | `START`에서 첫 bit drive, 첫 번째 edge에서 sampling, 두 번째 edge에서 다음 bit drive |
| `CPHA=1` 동작 | 첫 번째 edge에서 bit drive, 두 번째 edge에서 sampling, 마지막 bit는 `miso` 직접 결합 |
| mode test | TB의 `2'b00`, `2'b01`, `2'b10`, `2'b11` 순서 확인 |
| waveform | `sclk`, `ss_n`, `mosi`, `miso`, `start`, `busy`, `done`, `tx_data`, `rx_data`, `bit_cnt`, `step` 함께 확인 |
| test pattern | 현재 TB는 `8'hAA` 사용, 추가 검증 시 `8'h55`, `8'hFF`, `8'h00` 확장 가능 |

현재 노트에는 실제 시뮬레이션 PASS 로그나 정확한 ns 파형값을 새로 만들지 않는다. 파형 캡처는 testbench와 실행 결과가 확정된 뒤, `CPHA=0`과 `CPHA=1` 각각에서 sampling edge와 `rx_data` 결과를 기준으로 따로 기록한다.

## 다음 연결

다음 단계에서는 현재 SPI Master의 `CPHA` 분기를 시뮬레이션으로 확인하고, mode 0~3에서 `rx_data`가 기대값과 맞는지 정리해야 한다. 이후 SPI/I2C slave 데모로 넘어갈 때는 단순 loopback이 아니라 command, register, status, output 제어 흐름을 정해서 master가 보낸 값이 FPGA 출력으로 어떻게 이어지는지 설명할 수 있어야 한다.
