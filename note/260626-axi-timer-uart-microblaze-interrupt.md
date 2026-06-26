# 26-06-26 - AXI Timer/UART IP 패키징과 MicroBlaze Interrupt 연동

## 수업 흐름

0625 수업에서 작성한 AXI TimerCounter 작업본을 0626 수업 환경으로 복제한 뒤, AXI register map과 시뮬레이션 확인 항목을 다시 정리했다. TimerCounter는 단독 RTL 검증에서 끝내지 않고, AXI4-Lite register를 통해 `PSC`, `ARR`, `CNT`, control bit를 설정하고 읽을 수 있어야 한다.

오늘 설명의 중심은 직접 만든 custom IP를 datasheet처럼 설명할 수 있게 만드는 것이다. 단순히 코드가 동작했다는 수준이 아니라, register address, bit field, read/write 속성, reset value, 동작 조건을 표와 문장으로 설명해야 한다. 이후에는 TimerCounter와 UART를 따로따로 추가하기보다, UART를 작성한 뒤 TimerCounter와 함께 AXI peripheral에 붙이는 방향으로 진행한다.

## 현재 소스 위치

| 위치 | 내용 |
| :--- | :--- |
| [260626_AXI_TimerCounter](../helloHDL/260626_AXI_TimerCounter) | 0626 AXI TimerCounter 수업 작업본 |
| [TimerCounter.v](../helloHDL/260626_AXI_TimerCounter/260626_AXI_TimerCounter.srcs/sources_1/new/TimerCounter.v) | timer counter RTL |
| [axi_template_v1_0.v](../helloHDL/260626_AXI_TimerCounter/260626_AXI_TimerCounter.srcs/sources_1/imports/hdl/axi_template_v1_0.v) | AXI custom IP top |
| [axi_template_v1_0_S00_AXI.v](../helloHDL/260626_AXI_TimerCounter/260626_AXI_TimerCounter.srcs/sources_1/imports/hdl/axi_template_v1_0_S00_AXI.v) | AXI4-Lite slave register map |
| [tb_TimerCounter.sv](../helloHDL/260626_AXI_TimerCounter/260626_AXI_TimerCounter.srcs/sim_1/new/tb_TimerCounter.sv) | TimerCounter 단독 testbench |
| [tb_axi_timer.sv](../helloHDL/260626_AXI_TimerCounter/260626_AXI_TimerCounter.srcs/sim_1/new/tb_axi_timer.sv) | AXI write/read 통합 testbench |
| [260626_AXI_UART](../helloHDL/260626_AXI_UART) | UART AXI custom IP 작성용 프로젝트 |
| [260626_MicroBlaze_Timer_UART_Intr](../helloHDL/260626_MicroBlaze_Timer_UART_Intr) | Timer, UART, GPIO, MicroBlaze, interrupt controller 통합 프로젝트 |
| [ip_repo/uart_1.0](../helloHDL/ip_repo/uart_1.0) | 직접 작성한 UART custom IP 패키징 결과 |
| [ip_repo/timer_1.0](../helloHDL/ip_repo/timer_1.0) | 직접 작성한 Timer custom IP 패키징 결과 |
| [MicroBlazeTimerUARTIntr_wrapper.v](../helloHDL/260626_MicroBlaze_Timer_UART_Intr/260626_MicroBlaze_Timer_UART_Intr.srcs/sources_1/imports/hdl/MicroBlazeTimerUARTIntr_wrapper.v) | block design HDL wrapper |
| [MicroBlazeTimerUARTIntr_wrapper.xsa](../helloHDL/260626_MicroBlaze_Timer_UART_Intr/XSA/MicroBlazeTimerUARTIntr_wrapper.xsa) | Vitis platform 생성용 hardware export |
| [StopWatch/src](../helloHDL/260626_MicroBlaze_Timer_UART_Intr/vitis_repo/StopWatch/src) | Vitis application source |
| [HAL/TMR](../helloHDL/260626_MicroBlaze_Timer_UART_Intr/vitis_repo/StopWatch/src/HAL/TMR) | Timer register 접근 HAL |
| [HAL/UART](../helloHDL/260626_MicroBlaze_Timer_UART_Intr/vitis_repo/StopWatch/src/HAL/UART) | UART register 접근 HAL |
| [common/interrupt](../helloHDL/260626_MicroBlaze_Timer_UART_Intr/vitis_repo/StopWatch/src/common/interrupt) | AXI INTC 초기화와 ISR 연결 |
| [main.c](../helloHDL/260626_MicroBlaze_Timer_UART_Intr/vitis_repo/StopWatch/src/main.c) | Timer/UART interrupt enable과 application loop |

## AXI TimerCounter 확인 흐름

TimerCounter는 내부 clock을 그대로 세는 모듈이 아니라 `PSC`로 prescaler tick을 만들고, 그 tick마다 `CNT`를 증가시키는 구조이다. `ARR` 값에 도달하면 다음 tick에서 counter가 0으로 돌아가며 `intr_tick`이 1클럭 발생한다. 외부로 나가는 `intr`는 `intr_tick & intr_en`이므로, overflow가 발생해도 interrupt enable bit가 0이면 외부 interrupt는 발생하지 않는다.

AXI Timer testbench에서는 AXI write transaction으로 register를 설정한 뒤, 내부 counter와 readback 값을 함께 확인한다. `tb_axi_timer.sv` 기준 설정값은 `PSC=99`, `ARR=99`, `CR[1:0]=2'b11`이다. 이 경우 prescaler tick은 100클럭마다 발생하고, counter는 `0`부터 `99`까지 진행한 뒤 rollover된다.

| 확인 항목 | 봐야 할 신호/값 |
| :--- | :--- |
| control register write | `slv_reg0[0]=cnt_en`, `slv_reg0[1]=intr_en` |
| prescaler 설정 | `PSC=99` |
| auto-reload 설정 | `ARR=99` |
| counter 진행 | `o_cnt` 증가와 `99 -> 0` rollover |
| interrupt 조건 | `intr_tick` 1클럭 pulse, `intr=intr_tick & intr_en` |
| register readback | `CR`, `PSC`, `ARR`, `CNT` read 값 확인 |
| testbench 종료 | `$finish`로 무한 실행 방지 |

`tb_axi_timer.sv`는 `AXI_WriteData` task로 `PSC`, `ARR`, `CR`을 설정하고, `intr` 발생 이후 `AXI_ReadData` task로 register readback을 수행한다. 서버나 원격 환경에서 시뮬레이션을 돌릴 때는 종료 조건이 없으면 계속 실행될 수 있으므로 `$finish`를 명시하는 습관이 필요하다.

## Register Map 작성 방향

AXI custom IP를 설명할 때는 register map을 datasheet처럼 작성한다. 주소별 register 이름만 쓰는 것이 아니라, 각 bit가 어떤 의미를 갖는지와 소프트웨어가 어떻게 접근해야 하는지를 함께 적어야 한다. 사용하지 않는 bit도 reserved 범위로 남겨야 나중에 확장하거나 디버깅할 때 혼동이 줄어든다.

| Address | Register | Bit | R/W | Reset | 설명 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `0x00` | `TIM_CR` | `[0] CNT_EN` | R/W | `0` | `0`이면 정지, `1`이면 counter 동작 |
| `0x00` | `TIM_CR` | `[1] INTR_EN` | R/W | `0` | `1`이면 timer interrupt 출력 enable |
| `0x00` | `TIM_CR` | `[31:2] Reserved` | R/W | `0` | 미사용 bit |
| `0x04` | `PSC` | `[31:0] PSC` | R/W | `0` | prescaler compare value |
| `0x08` | `ARR` | `[31:0] ARR` | R/W | `0` | auto-reload compare value |
| `0x0C` | `CNT` | `[31:0] CNT` | R/W | `0` | write 시 counter load, read 시 live `o_cnt` |

현재 `timer_v1_0_S00_AXI.v`는 4개의 32-bit slave register를 사용한다. Write/read address decode는 `axi_awaddr[2+1:2]`, `axi_araddr[2+1:2]` 기준으로 `0x00`, `0x04`, `0x08`, `0x0C`를 구분한다. `CNT` 주소에 write하면 `slv_reg3`에 값이 저장되고, 동시에 `cnt_valid_r`이 1클럭 올라가 TimerCounter의 `counter <= i_cnt` load 동작으로 연결된다. `CNT` read는 저장된 `slv_reg3`가 아니라 현재 counter 값인 `o_cnt`를 반환한다.

Vitis 쪽 `TMR_TypeDef_t` 구조체는 Timer register 배치를 그대로 C 구조체로 표현한다. 구조체 멤버 순서가 `CR`, `PSC`, `ARR`, `CNT`이므로 base address에서 4바이트 단위로 `0x00`, `0x04`, `0x08`, `0x0C`에 대응한다.

| Register | Vitis HAL 연결 | 의미 |
| :--- | :--- | :--- |
| `CR` `0x00` | `TMR_StartTimer`, `TMR_StopTimer`, `TMR_StartInterrupt`, `TMR_StopInterrupt` | timer enable bit와 interrupt enable bit 제어 |
| `PSC` `0x04` | `TMR_SetPSC(TMR0, 100 - 1)` | prescaler compare value 설정 |
| `ARR` `0x08` | `TMR_SetARR(TMR0, 1000 - 1)` | auto-reload 기준값 설정 |
| `CNT` `0x0C` | `TMR_GetCNT`, `TMR_SetCNR` | 현재 counter 확인 또는 counter load |

현재 수업 원본의 `TMR_GetPSC()`, `TMR_GetARR()`, `TMR_GetCNT()`는 함수 내부에 `return`문이 있으나 선언과 정의의 반환형이 `void`로 되어 있다. 실제 값을 읽어 사용하는 HAL 함수로 정리하려면 반환형을 `uint32_t`로 맞춰야 한다.

## 코드 구조

| 파일 | 역할 |
| :--- | :--- |
| `TimerCounter.v` | prescaler, counter, rollover, interrupt pulse 생성 |
| `axi_template_v1_0.v` | AXI slave와 TimerCounter 연결 top |
| `axi_template_v1_0_S00_AXI.v` | AXI4-Lite register write/read, TimerCounter 제어 신호 생성 |
| `tb_TimerCounter.sv` | TimerCounter 단독 동작 검증 |
| `tb_axi_timer.sv` | AXI register write/read 기반 통합 검증 |

`TimerCounter.v`에서 `psc_counter`는 `cnt_en`이 1일 때만 증가한다. `psc_counter == psc`가 되면 `psc_tick`을 1클럭 만들고 다시 0으로 초기화한다. `counter`는 `cnt_valid`가 들어오면 `i_cnt`로 직접 load되고, 그렇지 않을 때 `psc_tick` 기준으로 증가한다. `counter == arr`이면 다음 값은 0이고 `intr_tick`이 1클럭 발생한다.

`axi_template_v1_0.v`는 AXI bus 신호와 TimerCounter 내부 신호 사이의 연결 계층이다. `timer_v1_0_S00_AXI`에서 나온 `cnt_en`, `intr_en`, `psc`, `arr`, `i_cnt`, `cnt_valid`를 TimerCounter로 넘기고, TimerCounter의 `o_cnt`와 `intr`를 다시 AXI register read와 외부 interrupt로 연결한다.

## UART 연동 준비

TimerCounter 다음 단계는 UART를 함께 붙이는 것이다. TimerCounter만 먼저 완성하고 나중에 UART를 따로 추가하면 block design, AXI 연결, 시뮬레이션 확인을 반복해야 하므로 시간이 많이 걸린다. UART RTL을 작성한 뒤 TimerCounter와 UART를 한 custom peripheral 안에서 같이 연결하는 방향으로 진행한다.

UART에서 사용할 주요 handshake 의미는 다음처럼 정리한다.

| 신호 | 의미 |
| :--- | :--- |
| `valid` | 입력 data가 의미 있는 값임을 표시 |
| `ready` | TX가 data를 받을 수 있는 상태 |
| RX data valid/done | RX 결과 data가 유효해진 시점 |

`ready`는 `valid`에 대한 일반적인 ready/valid pair로만 해석하면 안 된다. 여기서는 TX가 전송 가능한 상태인지 나타내는 의미가 더 강하다. RX 쪽은 data가 실제로 수신되어 사용할 수 있을 때 별도의 valid 또는 done 계열 신호로 AXI register에 연결한다.

## UART Register 설계 방향

UART는 CPU가 직접 serial line을 제어하는 것이 아니라 register를 통해 TX/RX 동작을 제어하도록 만든다. CPU가 TX data register에 값을 쓰면 UART TX 쪽으로 8-bit data가 전달되고, 이때 `tx_valid`가 1클럭 pulse로 발생해야 한다. TX가 전송 중이면 `tx_ready`는 0이 되므로, software는 status register를 읽어 전송 가능한 상태인지 확인할 수 있다.

RX는 반대로 UART가 1바이트를 수신했을 때 `rx_valid`를 발생시키고, AXI register logic은 이 값을 receive data register에 저장한다. 동시에 RX flag를 1로 올려 CPU가 새 data가 들어왔음을 알 수 있게 한다. CPU가 receive data register를 읽으면 RX flag를 다시 0으로 내리는 구조가 된다.

| Address | Register | 접근 | 주요 bit/값 | 역할 |
| :--- | :--- | :--- | :--- | :--- |
| `0x00` | `SR` | Read | `[0] tx_ready`, `[1] rx_flag` | 전송 가능 상태와 수신 flag 제공 |
| `0x04` | `TDR` | Write | `[7:0] tx_data` | write 시 TX data 저장과 `tx_valid` 1클럭 pulse |
| `0x08` | `RDR` | Read | `[7:0] rx_data` | RX data 저장, read 시 `rx_flag` clear |
| `0x0C` | `CR` | R/W | `[0] rx_ie` | UART receive interrupt enable |

`SR`은 peripheral 상태를 보여주는 register이므로 software가 임의로 write하는 대상이 아니다. 상용 UART의 status register도 read-only bit가 많으며, 현재 설계에서도 `tx_ready`나 `rx_flag` 같은 상태값은 hardware가 만든 값을 read path에서 보여주는 방식으로 생각한다.

Vitis 쪽 `UART_TypeDef_t` 구조체도 같은 순서로 `SR`, `TDR`, `RDR`, `CR`을 둔다. 현재 수업 원본의 `UART_Transmit()`과 `UART_Receive()`는 `SR[0]`, `SR[1]`을 검사하는 형태로 작성되어 있지만, `if`문 뒤 세미콜론 때문에 실제 대기 없이 각각 `TDR` write와 `RDR` read로 진행한다. 따라서 Vitis HAL은 register 접근 골격은 갖췄지만, polling wait 동작은 추가 정리가 필요하다. RTL에서는 `RDR` read가 `rx_flag`를 clear하는 side effect로 연결된다.

## UART Register Side Effect

AXI template의 기본 write logic은 여러 slave register를 하나의 case문으로 묶어 처리한다. UART처럼 register마다 side effect가 다른 IP에서는 이 묶음을 그대로 두기보다 register별 조건으로 분리해서 생각하는 편이 명확하다.

| 동작 | 조건 | side effect |
| :--- | :--- | :--- |
| `TDR` write | `slv_reg_wren` 및 `AWADDR == TDR` | 8-bit TX data 저장, `tx_valid` 1클럭 pulse |
| `RDR` update | `rx_valid == 1` | RX data 저장, `rx_flag <= 1` |
| `RDR` read | `slv_reg_rden` 및 `ARADDR == RDR` | `rx_flag <= 0` |
| `SR` read | `slv_reg_rden` 및 `ARADDR == SR` | 현재 `tx_ready`, `rx_flag` 조합 반환 |
| `CR` write | `slv_reg_wren` 및 `AWADDR == CR` | interrupt enable 등 제어 bit 저장 |
| `intr` output | `rx_ie & rx_valid` | UART top에서 receive interrupt 생성 |

`TDR`은 8-bit UART data만 필요하므로 write data 전체 32-bit를 모두 의미 있게 사용할 필요는 없다. 하위 8-bit를 TX data로 보고, 그 값이 저장되는 시점에 `tx_valid`를 함께 발생시키면 UART top과 연결할 수 있다.

`RDR` 쪽에는 FIFO가 없으면 CPU가 읽기 전에 다음 byte가 들어왔을 때 이전 값이 덮어써질 수 있다. FIFO를 넣는다면 UART RX와 `RDR` 사이에 배치하여 여러 byte를 임시 저장할 수 있다. 다만 FIFO에도 깊이 제한이 있으므로, 그 깊이를 넘는 data가 들어오면 동일하게 유실 가능성이 있다.

## UART 통합 시 확인할 신호

UART top을 AXI peripheral에 붙일 때는 port만 선언하고 끝내면 안 된다. `tx_data`, `tx_valid`, `tx_ready`, `rx_data`, `rx_valid`, interrupt 관련 신호가 실제 register logic과 연결되어야 한다.

| 연결 항목 | 확인 기준 |
| :--- | :--- |
| `tx_data` | `TDR` 하위 8-bit 값 전달 |
| `tx_valid` | `TDR` write 시 1클럭 pulse |
| `tx_ready` | TX 전송 가능 상태를 `SR` bit로 제공 |
| `rx_data` | RX 1바이트 수신값을 `RDR`에 저장 |
| `rx_valid` | RX data 유효 시 `rx_flag` set |
| `rx_flag clear` | `RDR` read 시 flag clear |
| interrupt | `rx_ie & rx_valid` 조합 |

## UART Loopback 검증 흐름

UART loopback은 TX에서 나가는 serial 출력을 RX 입력으로 다시 연결하여, 내가 보낸 값을 같은 UART 수신 경로에서 다시 읽는 검증 방식이다. 별도의 외부 장치를 붙이기 전에 `wire`로 TX/RX를 연결하면 TX register write, serial 전송, RX flag set, `RDR` read 흐름을 한 번에 확인할 수 있다.

Polling 방식에서는 software가 status register를 반복해서 읽는다. TX 전송 전에는 `SR[0]` ready bit를 확인하고, ready가 0이면 대기하다가 ready가 1이 된 뒤 `TDR`에 data를 쓴다. RX 쪽은 loopback으로 data가 돌아오면 `SR[1]` RX flag가 1이 되고, 이때 `RDR`을 읽어 수신 data를 확인한다.

| 단계 | 확인 내용 |
| :--- | :--- |
| 전송 전 | `RDR=0` 초기 상태 |
| TX ready 확인 | `SR[0]=1` 대기 |
| data write | polling 구간에서 `AA`, `55`, `12` 순서 write |
| RX flag 확인 | `SR[1]=1` 대기 |
| data read | `RDR`에서 loopback 수신값 확인 |

Loopback에서는 외부 UART line 대신 내부 연결로 data가 되돌아오므로, TX에서 보낸 값이 RX `RDR`에 같은 순서로 들어오는지가 핵심 확인 항목이다. 이때 `RDR` read side effect로 RX flag가 clear되는지도 함께 봐야 한다.

## Polling과 Interrupt 방식

Polling 방식은 `SR`을 계속 읽으며 ready flag와 RX flag가 원하는 값이 될 때까지 기다리는 구조이다. 구현이 단순하고 testbench에서 흐름을 따라가기 쉽지만, software가 계속 status register를 읽어야 한다.

Interrupt 방식은 RX flag를 계속 읽는 대신 interrupt 발생을 기다린 뒤 `RDR`을 읽는 구조이다. `tb_axi_uart.sv`의 interrupt 구간은 `34`, `11`, `22`를 전송 대상으로 두고, `wait(intr)` 이후 `RDR`에서 수신값을 읽는다.

| 방식 | 핵심 흐름 |
| :--- | :--- |
| Polling | `SR` 반복 read, ready/RX flag 확인 후 다음 단계 진행 |
| Interrupt | data 전송 후 interrupt 대기, interrupt 발생 후 `RDR` read |
| 공통 확인 | `TDR` write 값과 `RDR` read 값 일치 |

UART register 설계에서는 polling과 interrupt가 같은 status source를 공유한다. 차이는 software가 `SR`을 반복해서 확인하느냐, interrupt 신호를 기다린 뒤 처리하느냐이다.

Interrupt는 실행 중인 main 흐름을 완전히 망가뜨리는 동작이 아니라, peripheral event가 발생했을 때 정해진 ISR로 잠시 제어를 옮겼다가 처리가 끝나면 원래 흐름으로 돌아오는 구조이다. Timer overflow나 UART RX event처럼 소프트웨어가 계속 감시하기 부담스러운 일을 hardware event로 알려주는 방식이다.

| 용어 | 의미 | 수업 맥락 |
| :--- | :--- | :--- |
| Interrupt | 실행 흐름을 잠시 멈추고 ISR 실행 후 복귀 | Timer tick, UART RX 처리 |
| Disrupt | 진행 중인 흐름 자체를 깨뜨림 | 정상 제어 흐름 설명에는 부적합 |
| Interfere | 외부 개입으로 흐름에 영향 | interrupt보다 포괄적인 개입 의미 |

## UART IP Packaging 메모

UART를 Vivado custom IP로 만들 때는 `Tools -> Create and Package New IP`에서 AXI peripheral 기반 IP를 생성한 뒤 `Edit IP`로 들어간다. 생성된 template의 top module과 `S00_AXI` module에 직접 작성한 UART/AXI register logic을 옮길 수 있지만, module 이름은 IP packager가 만든 이름과 정확히 맞아야 한다.

| 작업 | 확인 기준 |
| :--- | :--- |
| IP 생성 | AXI peripheral 기반 UART IP 생성 |
| top 교체 | 생성된 top module 이름 유지 |
| `S00_AXI` 교체 | 생성된 `S00_AXI` module 이름 유지 |
| 내부 logic 이식 | 직접 작성한 register/interface logic 반영 |
| 저장 전 확인 | top과 `S00_AXI` instance/module name 일치 |

이름이 맞지 않으면 Vivado가 IP 내부 module을 찾지 못하거나 instance 연결이 깨질 수 있다. 따라서 전체 코드를 붙여넣을 때도 module name과 instance name을 먼저 맞춘 뒤, 내부 port와 register logic을 가져오는 순서로 정리한다.

## UART/Timer IP 패키징 절차

직접 작성한 RTL을 Vivado custom IP로 등록할 때는 AXI peripheral template의 뼈대와 module 이름을 유지한 상태에서 내부 logic을 옮긴다. UART는 `uart_v1_0.v` top과 `uart_v1_0_S00_AXI.v` slave module에 작성한 TX/RX register logic을 넣고, Timer는 `timer_v1_0.v` top과 `timer_v1_0_S00_AXI.v`에 TimerCounter 제어 register logic을 넣는다.

| 작업 | 확인 기준 |
| :--- | :--- |
| top module 이식 | template top module 이름 유지 |
| `S00_AXI` module 이식 | instance 이름과 module 이름 일치 |
| 내부 RTL 포함 | UART/Timer 하위 module이 top에서 참조 가능 |
| Merge 확인 | package 단계에서 변경 파일 merge 처리 |
| Review and Package | `Re-Package IP`로 repository 반영 |

Timer AXI 프로젝트 원본에서는 `TimerCounter.v`가 `sources_1/new`의 별도 source이고, AXI top인 `axi_template_v1_0.v`가 `TimerCounter`를 instance한다. IP 패키징 단계에서 TimerCounter를 top 파일 안에 합칠지, 별도 source로 함께 포함할지는 package file list를 기준으로 확인해야 한다.

IP driver의 `Makefile`도 같이 확인해야 한다. Vitis BSP가 custom IP driver를 빌드할 때 `drivers/<ip>_v1_0/src/Makefile`을 사용하므로, header와 C source가 빠지지 않도록 wildcard 기반으로 정리한다.

| 항목 | 적용 내용 |
| :--- | :--- |
| `INCLUDEFILES` | `$(wildcard *.h)` |
| `LIBSOURCES` | `$(wildcard *.c)` |
| `OUTS` | `$(wildcard *.o)` |
| 적용 대상 | `timer_1.0`, `uart_1.0` driver source |

## MicroBlaze Block Design 통합

MicroBlaze 통합 프로젝트에서는 GPIO 4개, 직접 만든 UART IP, 직접 만든 Timer IP, interrupt controller를 하나의 block design 안에 배치한다. GPIO는 기존 LED/FND/Button 연결을 위해 유지하고, UART와 Timer는 AXI peripheral로 붙인다.

| IP | 역할 |
| :--- | :--- |
| MicroBlaze | software 실행 processor |
| Local Memory | instruction/data memory |
| Clocking Wizard | Basys3 100MHz clock 입력 처리 |
| Processor System Reset | MicroBlaze reset 동기화 |
| AXI Interconnect/Crossbar | MicroBlaze와 peripheral 사이 AXI 연결 |
| AXI INTC | Timer/UART interrupt 입력을 MicroBlaze interrupt로 전달 |
| GPIO 0~3 | LED, FND, button 등 기존 board I/O |
| UART custom IP | 직접 작성한 UART TX/RX register interface |
| Timer custom IP | 직접 작성한 TimerCounter register interface |

Block design 이름은 기본 `design_1`보다 의미가 드러나는 이름으로 관리하는 편이 좋다. 현재 통합 설계는 `MicroBlazeTimerUARTIntr`로 정리했고, wrapper top도 `MicroBlazeTimerUARTIntr_wrapper`로 생성했다.

Block design을 생성한 뒤에는 다음 순서로 진행한다.

1. `Run Connection Automation`으로 AXI, clock, reset 연결 생성
2. GPIO instance 순서 확인
3. UART custom IP와 Timer custom IP AXI 연결 확인
4. Timer interrupt port를 AXI INTC 입력에 연결
5. 필요한 interrupt 입력 수가 늘어나면 AXI INTC/concat 입력 개수 확장
6. `Validate Design` 성공 확인
7. `Generate Block Design`에서 synthesis option은 `Global` 기준 사용
8. `Create HDL Wrapper`에서 Vivado auto update 선택
9. bitstream 생성
10. `Export Hardware`에서 bitstream 포함 XSA 생성

GPIO instance 번호는 software의 `XPAR_GPIO_0_S00_AXI_BASEADDR` 같은 macro와 직접 연결된다. GPIO 0~3의 용도를 정해 둔 뒤 block design에서 instance 순서가 바뀌지 않도록 확인해야 한다. 수업 흐름에서는 GPIOA~GPIOD를 0~3번 instance에 대응시키고, GPIOB의 6번/7번 bit를 button 또는 추가 입력으로 활용하는 방향을 확인했다.

## Clock, Wrapper, XSA 메모

Basys3 board clock은 differential clock이 아니라 single-ended `sys_clock`으로 처리해야 한다. Clocking Wizard 입력도 single-ended clock 기준으로 맞추고, XDC에서는 W5 pin의 `sys_clock` constraint가 적용되어야 한다.

| 산출물 | 현재 이름 |
| :--- | :--- |
| block design | `MicroBlazeTimerUARTIntr` |
| wrapper top | `MicroBlazeTimerUARTIntr_wrapper` |
| bitstream | `MicroBlazeTimerUARTIntr_wrapper.bit` |
| XSA | `MicroBlazeTimerUARTIntr_wrapper.xsa` |

XSA는 Vitis에서 hardware platform을 만들 때 사용하는 파일이다. bitstream을 포함해서 export하면 Vitis에서 platform project와 application project를 만들고, software build 후 MicroBlaze에 올릴 수 있다.

## Interrupt Controller와 Vitis 연결

Timer와 UART를 polling만으로 확인할 수도 있지만, interrupt 방식으로 연결하려면 AXI INTC를 통해 peripheral interrupt를 MicroBlaze interrupt로 전달해야 한다. Hardware에서는 Timer interrupt line을 AXI INTC 입력에 연결하고, software에서는 INTC device ID와 peripheral interrupt ID를 이용해 ISR을 등록한다.

| 단계 | 의미 |
| :--- | :--- |
| INTC device ID 확인 | `xparameters.h`의 AXI INTC device macro 확인 |
| Timer interrupt ID 확인 | Timer IP interrupt vector ID 확인 |
| UART interrupt ID 확인 | UART IP interrupt vector ID 확인 |
| INTC 초기화 | interrupt controller instance 초기화 |
| ISR 연결 | Timer/UART interrupt 발생 시 실행할 handler 등록 |
| INTC 시작 | hardware interrupt mode로 controller start |
| interrupt enable | controller와 MicroBlaze exception enable |

수업에서 강조한 부분은 대부분의 boilerplate는 Xilinx/Vitis가 제공하는 형태를 따라가고, 사용자가 직접 수정해야 하는 핵심은 device ID와 handler 연결 부분이라는 점이다. Timer interrupt가 발생하면 Timer ISR로 진입하고, UART interrupt가 발생하면 UART ISR로 진입하도록 연결해야 한다.

Vitis application은 기존 stopwatch software 계층을 재사용하면서 시간 기준과 UART 수신 처리를 interrupt 쪽으로 옮기는 방향이다. 현재 `main.c`는 `TMR_SetPSC(TMR0, 100 - 1)`, `TMR_SetARR(TMR0, 1000 - 1)`로 1ms 기준 timer interrupt를 만들고, `TMR_StartInterrupt()`, `TMR_StartTimer()`, `UART_StartInterrupt()` 후 `SetupInterruptsystem()`으로 ISR 연결을 활성화한다.

| ISR | 발생 조건 | 처리 |
| :--- | :--- | :--- |
| `TMR_ISR` | Timer overflow interrupt | `FND_Excute()` 실행, `incTick()` 호출 |
| `UART_ISR` | UART RX interrupt | `UART_Receive(UART0)`로 수신 byte read |
| `UART_ISR`의 `r` 처리 | 수신 data가 `r` | LED 0 toggle |
| `UART_ISR`의 `c` 처리 | 수신 data가 `c` | LED 1 toggle |

main loop는 stopwatch application logic을 계속 실행하고, button release event가 들어오면 `UART_Transmit(UART0, 'r')` 또는 `UART_Transmit(UART0, 'c')`로 loopback 확인용 byte를 보낸다. Timer 기준의 `FND_Excute()`와 `incTick()`은 main loop에서 직접 반복 호출하지 않고 `TMR_ISR`에서 처리하는 흐름으로 분리된다.

| 계층 | 현재 연결 방향 |
| :--- | :--- |
| `main.c` | application loop, Timer/UART interrupt enable, button 기반 UART transmit |
| `HAL/GPIO` | 기존 GPIO register 구조체 기반 접근 |
| `HAL/TMR` | `CR`, `PSC`, `ARR`, `CNT` register 접근 |
| `HAL/UART` | `SR`, `TDR`, `RDR`, `CR` register 접근 |
| `driver/FND` | FND multiplexing 출력 |
| `driver/LED` | LED 출력 제어 |
| `driver/button` | GPIOB 기반 button edge 처리 |
| `common/interrupt` | INTC 초기화, Timer/UART ISR 연결 |

## IP 수정과 Repository Refresh

Custom IP는 `Edit IP` 창에서만 수정할 수 있는 것이 아니라, 원본 `ip_repo/<ip>_1.0`의 HDL을 수정한 뒤 Vivado에서 repository refresh/upgrade를 수행하는 방식으로도 반영할 수 있다. 원본 HDL을 수정했는데 block design의 IP가 예전 상태를 물고 있으면 `Report IP Status` 또는 repository refresh 후 upgrade 흐름을 확인한다.

| 상황 | 처리 |
| :--- | :--- |
| IP HDL 수정 | `ip_repo/<ip>_1.0/hdl` 원본 수정 |
| packaged IP stale | IP repository refresh |
| block design IP update 필요 | upgrade selected IP |
| module/port mismatch | component packaging과 HDL module name 재확인 |
| generated output stale | output products 재생성 |

## 프로젝트/발표 연결

최종 프로젝트는 지금까지 배운 AI 활용, FPGA board, custom IP, peripheral 제어를 조합하는 방향으로 준비한다. 같은 기술을 사용하더라도 주제와 제목이 약하면 결과물이 약해 보일 수 있으므로, 구현 아이디어와 발표 제목을 일찍 고민해야 한다.

발표에서는 구현한 회로와 소프트웨어가 어떤 register와 protocol을 통해 연결되는지 설명할 수 있어야 한다. TimerCounter의 경우에는 `TIM_CR`, `PSC`, `ARR`, `CNT` register가 어떤 동작을 만들고, UART까지 붙였을 때 software가 어떤 순서로 값을 write/read하는지 보여주는 것이 핵심이다.

미니 프로젝트는 수업에서 만든 custom IP와 Vitis application 구조를 최대한 활용하는 방향으로 준비한다. 단순 polling demo보다 interrupt를 반드시 포함한 동작을 보여주는 것이 핵심 조건이다. FPGA board에서는 GPIO 기반 LED/Switch 계열 입출력과 UART TX/RX/GND 연결을 함께 확인하고, 발표 자료에는 동작 영상, troubleshooting, 느낀 점을 포함한다.

| 항목 | 준비 내용 |
| :--- | :--- |
| 하드웨어 | FPGA board, GPIO LED/Switch, UART TX/RX/GND 연결 |
| 필수 구조 | interrupt 사용 |
| 활용 범위 | 수업 코드와 custom IP 구조 재사용 |
| 제출/발표 자료 | 동작 영상, troubleshooting, 느낀 점 |
| 제출 시점 | 안내 기준 10일 이내 |

## 다음에 확인할 것

- AXI TimerCounter waveform에서 `o_cnt`, `intr_tick`, `intr`, AXI readback 값 확인
- `TIM_CR`, `PSC`, `ARR`, `CNT` register map 문서화
- UART TX/RX valid, ready, RX flag 계열 신호의 register 연결 확인
- UART register write/read side effect 시뮬레이션 확인
- UART loopback polling test에서 `TDR` write와 `RDR` read 값 일치 확인
- UART interrupt 방식에서 interrupt 발생 후 `UART_ISR` 진입과 `RDR` read 확인
- Vitis에서 `xparameters.h`의 Timer/UART vector ID와 `interrupt.h` macro 일치 확인
- board에서 Timer ISR 기반 FND refresh와 UART RX 기반 LED toggle 확인
- `TMR_GetPSC()`, `TMR_GetARR()`, `TMR_GetCNT()` 반환형 정리
- `UART_Transmit()`, `UART_Receive()`의 status wait 조건문 정리
- Edit IP 이후 top과 `S00_AXI` module name mismatch 여부 확인
