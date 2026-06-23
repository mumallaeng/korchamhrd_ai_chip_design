# 26-06-23 - MicroBlaze GPIO 확장, Stopwatch Block Design, Firmware 포인터

## 수업 흐름

0622 수업에서 만든 MicroBlaze 기반 GPIO custom IP 흐름을 다시 잡고, CPU가 직접 만드는 대상과 peripheral로 붙이는 대상의 차이를 정리했다. 실제 SoC 제품에서는 ARM Cortex 계열 CPU core를 사 와서 쓰고, 회사의 차별점은 CPU 주변에 붙는 video, audio, filter, modem, accelerator, GPU 같은 peripheral IP에서 나온다. 따라서 수업에서 직접 구현하고 검증해야 하는 대상도 CPU 자체보다 AXI로 연결되는 peripheral과 그 register interface다.

이 관점에서 AXI protocol과 AXI interconnect를 이해하는 것이 중요하다. MicroBlaze가 AXI master가 되고, UART Lite나 custom GPIO가 AXI slave peripheral로 붙는다. AXI interconnect는 여러 peripheral로 가는 통로를 나누는 switch/router에 가깝고, 각 peripheral은 자기 base address 영역을 갖는다.

이후 Vivado block design을 처음부터 다시 만들면서 `stopwatch_design`을 구성했다. 기본 MicroBlaze system을 만들고, UART Lite를 붙인 뒤, 수업에서 만든 `gpio_1.0` custom IP를 repository로 등록해 GPIO peripheral 4개를 추가했다. 목표 기능은 stopwatch를 기준으로 FND, button, mode switch, LED를 GPIO port에 나누어 붙이는 구조다.

수업 후반에는 firmware 쪽에서 C pointer가 중요하다는 이야기가 이어졌다. Memory-mapped register를 다루려면 C에서 address를 pointer로 보고 register offset에 값을 쓰거나 읽는 방식이 기본이기 때문에, 이번 주는 peripheral 설계와 함께 C pointer 기반 제어 코드도 같이 다룰 흐름이다. Block design을 HDL wrapper로 감싸 top을 만든 뒤 XDC로 실제 board pin에 연결하고, bitstream이 포함된 XSA를 Vitis로 넘겨 software project를 만드는 순서까지 이어졌다.

## 현재 소스 위치

| 위치 | 내용 |
| :--- | :--- |
| [260623_MicroBlaze_GPIO](../helloHDL/260623_MicroBlaze_GPIO) | MicroBlaze stopwatch block design project |
| [260623_MicroBlaze_GPIO.xpr](../helloHDL/260623_MicroBlaze_GPIO/260623_MicroBlaze_GPIO.xpr) | Vivado project, top module `stopwatch_design_wrapper` |
| [stopwatch_design.bd](../helloHDL/260623_MicroBlaze_GPIO/260623_MicroBlaze_GPIO.srcs/sources_1/bd/stopwatch_design/stopwatch_design.bd) | MicroBlaze, local memory, UART Lite, AXI interconnect, custom GPIO 4개 |
| [Basys-3-Master.xdc](../helloHDL/260623_MicroBlaze_GPIO/260623_MicroBlaze_GPIO.srcs/constrs_1/imports/imports/Basys-3-Master.xdc) | `sys_clock`, `reset`, `usb_uart`, `GPIOA~D` board pin 제약 |
| [ip_repo/gpio_1.0](../helloHDL/ip_repo/gpio_1.0) | 수업에서 만든 AXI4-Lite GPIO custom IP repository |
| [StopWatch/src/main.c](../helloHDL/260623_MicroBlaze_GPIO/vitis_repo/StopWatch/src/main.c) | Vitis Application Project에서 작성한 MicroBlaze firmware |

현재 `260623_MicroBlaze_GPIO`에는 Vivado project와 block design, XDC, XCI, Vitis workspace가 함께 있다. Vitis 쪽에서는 Application Project에서 Empty file을 C source로 생성하고, `StopWatch/src/main.c`에 `GPIOC/GPIOD`를 16-bit LED port처럼 다루는 firmware를 작성해 build했다.

## SoC와 Peripheral 관점

반도체 SoC 설계에서 CPU core는 직접 새로 만드는 대상이 아니라 이미 검증된 IP를 가져와 사용하는 경우가 많다. 수업에서는 ARM core를 예로 들며, 실제 회사의 제품 성격은 CPU 옆에 어떤 peripheral IP를 붙이고 어떤 기능을 구현하느냐에서 결정된다고 설명했다.

| 항목 | 수업 관점 |
| :--- | :--- |
| CPU core | ARM Cortex, MicroBlaze처럼 system 중심에 위치 |
| Peripheral | video, audio, filter, modem, accelerator, GPIO 등 기능 IP |
| AXI | CPU와 peripheral 사이의 register/data access interface |
| AXI interconnect | 여러 AXI slave peripheral로 address routing |
| 검증 대상 | protocol 이해, register interface 동작, peripheral 기능 |
| portfolio 연결 | 직접 만든 peripheral과 검증 결과를 설명하는 근거 |

따라서 AXI를 단순히 이름만 아는 것이 아니라, CPU가 어떤 address로 어떤 peripheral register를 읽고 쓰는지까지 이해해야 한다. 이후 UVM 검증이나 board demo를 설명할 때도 `AXI transaction -> custom IP register -> 외부 출력` 흐름이 연결되어야 한다.

## MicroBlaze 기본 System

Vivado에서 `Create Block Design`으로 `stopwatch_design`을 만들고 MicroBlaze를 추가했다. `Run Block Automation`을 사용하면 MicroBlaze에 필요한 local memory, MDM debug module, clock/reset 관련 block이 자동으로 들어간다.

| Block | 역할 |
| :--- | :--- |
| `microblaze_0` | AXI master CPU |
| `microblaze_0_local_memory` | instruction/data local memory |
| `mdm_1` | MicroBlaze debug module |
| `clk_wiz_1` | board clock 기반 system clock 생성 |
| `rst_clk_wiz_1_100M` | clock domain reset 생성 |
| `axi_uartlite_0` | USB UART 통신 peripheral |
| `microblaze_0_axi_periph` | AXI interconnect/peripheral routing |

Clocking Wizard는 Basys3 board의 `sys_clock`을 받아 system clock을 만든다. 수업에서는 특별히 조정할 필요가 적고, 기존 실습처럼 100 MHz 기준이 안정적이라고 정리했다. Reset은 XDC에서 button 한 개를 `reset` port에 연결한다.

UART Lite는 PC와 board 사이의 UART 통신용 peripheral이다. MicroBlaze가 UART Lite register를 AXI로 접근하고, 외부 pin은 `usb_uart_rxd`, `usb_uart_txd`로 XDC에 잡는다.

## Custom GPIO IP Repository 등록

Vivado에는 Xilinx 기본 GPIO IP도 있지만, 이번 수업의 목적은 직접 만든 `gpio_1.0` custom IP를 MicroBlaze system에 붙이는 것이다. 기본 GPIO는 동작이 검증된 IP이고, custom GPIO는 직접 만든 register map과 `io_port` 동작을 board에 연결해 보는 대상이다.

직접 만든 IP가 IP Catalog에 보이지 않으면 project settings에서 repository path를 추가해야 한다.

1. `Project Manager -> Settings`
2. `IP -> Repository`
3. `+` 버튼으로 `helloHDL/ip_repo` 또는 `gpio_1.0` 포함 경로 선택
4. repository에 `gpio_1.0`이 잡히는지 확인
5. block design에서 custom GPIO IP 추가

이후 custom GPIO를 4개 배치하고 `Run Connection Automation`으로 AXI interface를 MicroBlaze AXI interconnect에 붙였다. 각 GPIO instance의 외부 `io_port`는 `Make External`로 빼고, 이름을 `GPIOA`, `GPIOB`, `GPIOC`, `GPIOD`처럼 정리한다.

## Stopwatch GPIO 분배 구상

Stopwatch 예제는 단순 LED blink보다 peripheral 설계 요구사항을 더 많이 포함한다. FND 출력, digit select, button 입력, mode switch, LED 표시를 GPIO port에 나누어 배치해야 하므로, 먼저 어떤 port가 어떤 역할을 맡을지 정해야 한다.

| 대상 | 필요한 bit | 설계 메모 |
| :--- | :---: | :--- |
| FND segment data | 8 bit | `a~g`, `dp` 출력 후보 |
| FND digit select | 4 bit | 4자리 FND 자리 선택 |
| Button | 2~4 bit | run/stop, reset, up/down 후보 |
| Mode switch | 2 bit | 표시 단위 또는 동작 mode 선택 후보 |
| LED | 16 bit | 동작 상태 또는 이동 패턴 표시 |

현재 block design은 8-bit GPIO 4개를 사용한다. 총 32 bit의 GPIO 공간이 있으므로 FND data, digit select, button/mode, LED 같은 신호를 나눠 담을 수 있다. 현재 XDC에서는 `GPIOA`를 FND segment, `GPIOB`를 FND digit select와 button/switch 입력, `GPIOC/GPIOD`를 16개 LED 출력으로 나누어 연결한다.

| Port | 현재 용도 |
| :--- | :--- |
| `GPIOA[7:0]` | FND segment data |
| `GPIOB[0]~GPIOB[3]` | FND digit select |
| `GPIOB[4]~GPIOB[5]` | button 입력 |
| `GPIOB[6]~GPIOB[7]` | switch 입력 |
| `GPIOC[7:0]` | LED 0~7 |
| `GPIOD[7:0]` | LED 8~15 |

## Address Map

`stopwatch_design.bd` 기준으로 MicroBlaze data address space에는 UART Lite와 custom GPIO 4개가 각각 64 KB range로 배치되어 있다.

| Segment | Base address | Range | 연결 |
| :--- | :--- | :---: | :--- |
| `SEG_axi_uartlite_0_Reg` | `0x40600000` | `64K` | `axi_uartlite_0/S_AXI` |
| `SEG_gpio_0_S00_AXI_reg` | `0x44A00000` | `64K` | `gpio_0/S00_AXI`, `GPIOA` |
| `SEG_gpio_1_S00_AXI_reg` | `0x44A10000` | `64K` | `gpio_1/S00_AXI`, `GPIOB` |
| `SEG_gpio_2_S00_AXI_reg` | `0x44A20000` | `64K` | `gpio_2/S00_AXI`, `GPIOC` |
| `SEG_gpio_3_S00_AXI_reg` | `0x44A30000` | `64K` | `gpio_3/S00_AXI`, `GPIOD` |
| `SEG_dlmb_bram_if_cntlr_Mem` | `0x00000000` | `128K` | data local memory |
| `SEG_ilmb_bram_if_cntlr_Mem` | `0x00000000` | `128K` | instruction local memory |

Firmware에서는 이 base address에 custom GPIO register offset을 더해 control register와 output data register를 접근하게 된다. Base address는 해당 peripheral을 선택하는 chip select에 가깝고, offset은 선택된 peripheral 내부의 register를 고르는 값이다.

Vivado의 Address Editor에서는 AXI peripheral마다 자동 할당된 base address와 range를 확인할 수 있다. 수업에서는 `gpio_0~gpio_3`가 `0x44A00000`, `0x44A10000`, `0x44A20000`, `0x44A30000`처럼 순서대로 잡힌 상태를 확인했다. 주소는 필요하면 바꿀 수 있지만, 실습에서는 자동 할당값을 그대로 두고 firmware에서 이 주소를 기준으로 register를 제어하는 쪽이 관리하기 쉽다.

## Custom GPIO Register 의미

관련 노트: [[domains/semiconductor/verilog-hdl/study-reference-13-gpio-register-mmio-cr-idr-odr]]

직접 만든 GPIO IP는 AXI4-Lite slave register를 통해 mode와 data를 제어한다. Software에서는 `base address + offset`으로 register에 접근하고, custom GPIO 내부에서는 해당 register write/read가 `io_port` 방향과 출력값으로 이어진다. 이번 코드에서는 `GPIO_TypeDef` 구조체 순서가 곧 register offset 기준이므로, `CR`, `IDR`, `ODR` 순서를 소스와 맞춰 보는 것이 중요하다.

| Register | Offset | Access | 의미 |
| :---: | :--- | :--- | :--- |
| `CR` | `0x00` | read/write | bit별 direction 설정 |
| `IDR` | `0x04` | read | 외부 입력값 확인 |
| `ODR` | `0x08` | read/write | 외부 출력값 설정 |

`CR` bit가 `1`이면 해당 GPIO bit는 output mode로 동작하고, `0`이면 input mode로 동작한다. LED와 FND처럼 값을 밖으로 내보내는 신호는 output mode가 필요하고, button/switch처럼 외부 전압 상태를 읽는 신호는 input mode가 필요하다.

`IDR`은 input mode에서 외부 pin의 전압 상태를 읽는 register다. Board 기준으로 button이나 switch 입력은 해당 pin이 3.3 V인지 0 V인지에 따라 register bit가 `1` 또는 `0`으로 읽힌다.

`ODR`은 output mode에서 외부 pin으로 내보낼 값을 쓰는 register다. 해당 bit에 `1`을 쓰면 출력 pin이 high 상태가 되고, `0`을 쓰면 low 상태가 된다. 따라서 LED 출력에서는 `ODR` bit가 board LED의 ON/OFF와 직접 연결된다.

## HDL Wrapper와 Top Port

Block design을 board에 올리려면 block design 자체를 top으로 사용할 수 없고, `Create HDL Wrapper`를 통해 Verilog top wrapper를 생성해야 한다. `stopwatch_design_wrapper`는 block design의 외부 port를 HDL port로 감싸며, XDC는 이 wrapper port 이름을 기준으로 pin을 연결한다.

| Wrapper port | 의미 |
| :--- | :--- |
| `GPIOA~GPIOD` | custom GPIO 4개에서 외부로 뺀 8-bit `io_port` |
| `sys_clock` | Basys3 100 MHz clock 입력 |
| `reset` | board button reset 입력 |
| `usb_uart_rxd`, `usb_uart_txd` | UART Lite 외부 통신 pin |

따라서 wrapper를 만든 뒤에는 wrapper code의 port 이름과 XDC의 `get_ports` 이름이 일치하는지 확인해야 한다. 특히 `GPIOB[4]`, `GPIOB[5]`처럼 bus bit를 직접 잡는 XDC line은 `[get_ports {GPIOB[4]}]`처럼 중괄호로 감싸 Tcl parser가 bus index를 정확히 해석하도록 둔다.

## XSA와 Vitis 실행

Bitstream 생성 뒤에는 `File -> Export -> Export Hardware`에서 `Include bitstream`을 선택해 XSA 파일을 만든다. XSA는 MicroBlaze CPU, local memory, AXI interconnect, UART Lite, custom GPIO, address map, bitstream처럼 software가 참고해야 하는 hardware platform 정보를 묶은 파일이다.

XSA 파일은 project root에 흩어 두기보다 `helloHDL/XSA`처럼 별도 폴더를 만들어 관리하는 편이 좋다. Bitstream이나 peripheral 구성이 바뀌면 XSA를 다시 export할 수 있으므로, 여러 버전이 생겨도 찾기 쉽도록 위치를 분리한다.

Vitis를 실행하면 먼저 workspace를 정해야 한다. Workspace에는 application source, BSP, platform, build output 같은 software 작업 환경이 들어가므로, 해당 Vivado project와 가까운 위치를 잡아 두면 관리가 편하다.

Application Project를 만들 때는 Vivado에서 export한 XSA를 선택해 platform을 만든다. 여기서 platform은 software가 실행될 환경을 뜻한다. 일반 PC로 비유하면 CPU, memory, OS, middleware 같은 실행 환경이 platform에 해당하고, MicroBlaze 실습에서는 XSA 안에 담긴 hardware 구성과 address map이 software가 참고해야 하는 platform 정보가 된다.

Vivado에서 `Tools -> Launch Vitis IDE`로 넘어가지 않고 software project만 바로 열고 싶을 때는 Xilinx Design Tools 메뉴에서 `Xilinx Vitis 2020.2`를 실행한다.

Xilinx Design Tools 안에는 Vitis 관련 실행 항목이 여러 개 보일 수 있다. 이때 `Vitis HLS`는 C/C++ 기반 High-Level Synthesis용 별도 프로그램이므로 MicroBlaze firmware 작성용으로 사용하지 않는다. MicroBlaze application project, BSP, C source를 다룰 때는 일반 `Xilinx Vitis 2020.2`를 선택한다.

수업 자료나 설치 환경에 따라 Vivado/Vitis 2022.2 메뉴 흐름으로 설명될 수 있지만, 현재 로컬 실습 프로젝트는 Vivado/Vitis 2020.2 기준 경로와 파일로 관리한다. 버전이 달라도 이번 실습에서 중요한 순서는 `Vivado block design -> bitstream 포함 XSA export -> Vitis platform -> application project -> C firmware build`로 동일하게 본다.

## Vitis Application Project Wizard

`Create a New Application Project` wizard는 Vivado에서 만든 hardware platform 위에 software application을 얹는 절차다. 큰 흐름은 XSA로 platform을 만들고, application을 system project에 넣은 뒤, processor와 runtime domain을 정하고, 마지막으로 시작 template을 고르는 순서다.

1. Vivado에서 export한 XSA 선택 또는 platform project 생성
2. Application project를 system project에 넣고 processor와 연결
3. Application runtime용 domain 준비
4. 개발 시작용 template 선택

| 항목 | 의미 |
| :--- | :--- |
| `XSA` | Vivado에서 export한 hardware 정보 묶음 |
| `Platform` | hardware 정보와 software 실행 환경 설정 |
| `Project` | 실제 application project |
| `System Project` | 동시에 실행될 수 있는 application 묶음 |
| `Processor` | application이 올라갈 CPU, 이번 실습에서는 `microblaze_0` |
| `Domain` | application runtime, OS 또는 BSP 설정 |
| `App` | C/C++로 작성하는 실행 대상 application |
| `Workspace` | 여러 platform과 system project를 담는 작업 공간 |

이번 MicroBlaze GPIO 실습에서는 `stopwatch_design_wrapper.xsa`를 platform 입력으로 사용하고, processor는 `microblaze_0`를 선택한다. 별도 OS를 쓰지 않는 bare-metal 흐름에서는 domain이 standalone BSP 중심 runtime을 제공하고, application은 이 BSP 위에서 GPIO register를 직접 접근하는 C code로 작성된다. 시작 template은 `Hello World`로 UART 출력과 build 흐름을 확인할 수도 있고, 이후 `Empty Application` 또는 blank C file을 사용해 `main.c`를 직접 작성할 수도 있다.

Vitis에서도 serial terminal을 제공한다. Vitis 상단 검색에서 `serial`을 입력하면 `Vitis Serial Terminal` 항목이 나오고, 이 항목을 선택해 UART 출력 확인용 terminal을 열 수 있다. Board의 COM port를 확인한 뒤 baud rate를 `115200`으로 맞추면, MicroBlaze application에서 `print()`나 `xil_printf()`로 출력한 문자열을 이 terminal에서 확인할 수 있다.

## Vitis Firmware 작성

Application Project에서는 template code에 의존하지 않고 Empty file을 C file로 만든 뒤 `src/main.c`에 직접 코드를 작성했다. 처음에는 `base address + offset`을 직접 pointer로 바꾸어 register에 접근했지만, 이후에는 같은 동작을 구조체와 helper 함수로 감싸 코드 의미가 보이도록 정리했다.

| 항목 | 내용 |
| :--- | :--- |
| source file | `260623_MicroBlaze_GPIO/vitis_repo/StopWatch/src/main.c` |
| GPIOA base address | `XPAR_GPIO_0_S00_AXI_BASEADDR` |
| GPIOB base address | `XPAR_GPIO_1_S00_AXI_BASEADDR` |
| GPIOC base address | `XPAR_GPIO_2_S00_AXI_BASEADDR` |
| GPIOD base address | `XPAR_GPIO_3_S00_AXI_BASEADDR` |
| control register offset | `0x00` |
| input data register offset | `0x04` |
| output data register offset | `0x08` |
| 현재 확인 동작 | `GPIOC/GPIOD`를 16-bit LED port로 묶어 `0xffff`, `0x0000` 반복 출력 |
| 출력 로그 | `xil_printf()`로 `counter` 값 반복 출력 |

`main.c`에서는 `stdint.h`, `xparameters.h`, `sleep.h`, `xil_printf.h`를 include한다. `xparameters.h`에는 Vitis platform이 알고 있는 hardware parameter와 peripheral address 정의가 들어가며, `XPAR_GPIO_0_S00_AXI_BASEADDR`처럼 Vivado에서 export한 address map을 C code에서 사용할 수 있게 해 준다.

`GPIO_TypeDef`는 GPIO register map을 C 구조체로 표현한 것이다. `CR`, `IDR`, `ODR`이 각각 32-bit member로 선언되어 있으므로, GPIO base address를 `GPIO_TypeDef *`로 cast하면 `GPIOC->CR`, `GPIOC->ODR`처럼 register 이름으로 접근할 수 있다. 컴파일 결과로는 직접 주소 접근과 같은 register write가 되지만, 코드만 봐도 어떤 register를 다루는지 훨씬 명확해진다.

`GPIOC->CR = 0xff`, `GPIOD->CR = 0xff` 또는 `GPIO_SetMode(GPIOC, 0xff)`는 각 8-bit GPIO port를 output mode로 설정하는 의미다. 현재 `main.c`에서는 이를 `LED_Init()`으로 감싸고, while loop에서 `LED_Port(0xffff)`와 `LED_Port(0x0000)`을 반복해 16개 LED 전체를 켰다가 끄는 구조로 정리했다. `usleep(100000)`을 넣어 board에서 LED 변화가 눈으로 보이도록 delay를 둔다.

`GPIOB`는 FND digit select와 button/switch 입력 후보로 남아 있다. 현재는 `GPIOC/GPIOD` LED 출력 확인이 중심이지만, 이후 button이나 switch를 읽을 때는 `GPIO_ReadPort()` 또는 `GPIO_ReadPin()`을 사용해 `IDR` 값을 읽는 구조로 확장할 수 있다.

## C 포인터와 MMIO 접근

관련 노트: [[domains/semiconductor/verilog-hdl/study-reference-14-c-pointer-struct-mmio-gpio-register-access]]

이 수업의 firmware 부분은 C pointer, 자료형 크기, 구조체 layout을 GPIO register 접근으로 연결해서 보는 흐름이다. 자세한 보강은 위 관련 노트에 정리하고, 이 노트에서는 `base address + offset`으로 register 주소를 만들고, pointer cast와 dereference로 실제 hardware register에 read/write하는 흐름만 잡는다.

Memory-mapped I/O register는 C 코드에서 일반 변수처럼 보이지만 실제로는 특정 주소에 놓인 hardware register다. 따라서 숫자로 보이는 address를 pointer type으로 변환하고, dereference한 위치에 값을 write해야 hardware register write가 된다.

```c
(*(uint32_t *)(GPIOC_BASEADDR + 0x08)) = 0xff;
```

이 표현에서 `GPIOC_BASEADDR + 0x08`은 GPIOC peripheral의 ODR address다. `(uint32_t *)` cast는 이 값을 32-bit register를 가리키는 주소로 해석하겠다는 의미이고, 앞의 `*`는 그 주소가 가리키는 register 자체를 lvalue로 만들어 assignment가 가능하게 한다. `*`가 없으면 register가 아니라 주소값을 표현한 것이므로 왼쪽에 두고 값을 대입할 수 없다.

Pointer 변수는 주소를 담는 변수이므로 변수 크기는 대상 자료형 크기가 아니라 address size를 따른다. 수업의 MicroBlaze 환경에서는 address가 4 byte 기준으로 설명되었고, `uint32_t *` 앞의 `uint32_t`는 pointer 변수 자체의 크기가 아니라 pointer가 가리키는 register data width를 설명하는 역할이다.

구조체 pointer를 사용할 때는 `GPIOC->ODR`처럼 `->` 연산자를 쓴다. 일반 구조체 변수에서는 `sc.a`처럼 점 연산자로 member에 접근하지만, `GPIOC`는 base address를 구조체 pointer로 본 것이므로 `(*GPIOC).ODR`을 줄여 쓴 형태가 `GPIOC->ODR`이다.

이번 내용에서 함께 연결되는 개념은 `volatile`, pointer arithmetic, 구조체 padding, register offset 검증이다. `volatile`은 compiler가 MMIO register 접근을 일반 변수처럼 제거하거나 합치지 못하게 하는 장치이고, pointer type은 dereference 폭과 `p + 1`의 증가 단위를 결정한다. 구조체로 `CR/IDR/ODR` register map을 표현할 때는 member 순서와 padding이 실제 offset과 맞아야 하므로, 필요하면 `offsetof()`와 `_Static_assert`로 compile-time 검증을 둔다.

## GPIO Helper 함수와 bit 제어

GPIO access를 함수로 감싸면 register offset 숫자나 bit 연산을 main loop마다 반복하지 않아도 된다. 직접 레지스터에 값을 쓰는 low-level 코드를 먼저 이해한 뒤, 그 동작을 `GPIO_SetMode`, `GPIO_WritePort`, `GPIO_WritePin`, `GPIO_ReadPort`, `GPIO_ReadPin` 같은 함수로 묶는 흐름이다.

| 함수 | 역할 |
| :--- | :--- |
| `GPIO_SetMode(GPIOx, mode)` | `CR`에 direction 설정값 write |
| `GPIO_WritePort(GPIOx, data)` | `ODR` 전체에 8-bit 출력값 write |
| `GPIO_WritePin(GPIOx, gpio_pin, state)` | `ODR`의 특정 bit만 set/reset |
| `GPIO_ReadPort(GPIOx)` | `IDR` 전체 값 반환 |
| `GPIO_ReadPin(GPIOx, gpio_pin)` | `IDR`에서 특정 bit만 읽어 `0/1` 반환 |

`GPIO_WritePin()`은 특정 bit만 바꾸기 위해 OR/AND 연산을 사용한다. `GPIO_SET`이면 `GPIOx->ODR |= gpio_pin`으로 해당 bit를 `1`로 만들고, `GPIO_RESET`이면 `GPIOx->ODR &= ~gpio_pin`으로 해당 bit만 `0`으로 만든다. 다른 bit는 유지되므로 port 전체를 덮어쓰는 것보다 LED 한 개나 특정 pin 제어에 적합하다.

`void` 함수는 반환값 없이 내부 register write만 수행한다. `GPIO_SetMode()`나 `GPIO_WritePin()`은 하드웨어 register를 직접 바꾸는 side effect가 목적이므로 `void`로 충분하다. 반대로 `GPIO_ReadPort()`와 `GPIO_ReadPin()`은 읽은 값을 caller에게 돌려줘야 하므로 `uint32_t` 반환형을 사용한다.

## Firmware Layer와 Driver 호출 방향

관련 노트: [[domains/semiconductor/verilog-hdl/study-reference-12-embedded-layered-architecture-hal-driver]]

GPIO helper 함수를 만든 다음에는 application code가 hardware register를 직접 만지는 구조를 줄이고, 기능 단위 driver를 거쳐 제어하는 방향으로 정리한다. 예를 들어 LED를 켜고 끄는 동작은 application에서 `GPIOC->ODR` 또는 `GPIOD->ODR`를 직접 쓰는 방식보다, LED driver가 GPIO driver를 사용해 처리하는 구조가 유지보수에 유리하다.

수업에서는 이 구조를 layer가 쌓이는 stack 관점으로 설명했다. 위쪽 application은 바로 아래 driver layer를 호출하고, driver는 다시 아래쪽 GPIO access layer를 호출한다. 하위 layer가 상위 layer를 호출하면 의존 방향이 뒤집혀 코드 재사용과 이식이 어려워진다.

| Layer | 역할 |
| :--- | :--- |
| Application | `main()`, stopwatch 동작, LED pattern 결정 |
| LED driver | LED on/off, write, toggle, shift 같은 기능 API 제공 |
| GPIO driver | `CR/IDR/ODR` register 접근과 bit set/reset 처리 |
| Custom GPIO IP | AXI4-Lite register와 `io_port` 방향/출력 제어 |
| Board hardware | LED, FND, button, switch 실제 pin 동작 |

호출 관계는 caller와 callee로 볼 수 있다. `main()`이 `GPIO_WritePin()`을 부르면 `main()`은 caller, `GPIO_WritePin()`은 callee다. 화살표 방향은 항상 caller에서 callee로 향하며, application에서 driver로 내려가는 방향이 된다.

| 관계 | 의미 |
| :---: | :--- |
| caller | 함수를 호출하는 상위 layer |
| callee | 호출되는 하위 layer 기능 |
| 좋은 방향 | application -> LED driver -> GPIO driver -> register |
| 피할 방향 | GPIO driver -> LED driver 또는 GPIO driver -> application |

이 규칙은 새 제품이나 새 board로 코드를 옮길 때 중요하다. Application이 GPIO register 주소와 bit 배치를 직접 알고 있으면 hardware 구성이 바뀔 때 application 전체를 고쳐야 한다. 반대로 LED driver가 16개 LED의 실제 GPIOC/GPIOD 배치를 감싸면, application은 `LED_Write()`나 `LED_ShiftLeft()` 같은 기능 이름만 보고 사용할 수 있다.

## LED Driver 설계 방향

현재 board LED 16개는 `GPIOC[7:0]`, `GPIOD[7:0]`로 나뉘어 있다. Application 입장에서는 LED가 16-bit 하나처럼 보이는 편이 편하므로, LED driver에서 하위 8 bit는 GPIOC, 상위 8 bit는 GPIOD로 나누어 쓰는 구조가 적합하다.

| API | 상태 | 동작 |
| :--- | :---: | :--- |
| `LED_Init()` | 구현 | `GPIOC/GPIOD` output mode 설정 |
| `LED_Port(uint16_t led)` | 구현 | 하위 8 bit는 GPIOC, 상위 8 bit는 GPIOD로 분리 출력 |
| `LED_PinOn(uint16_t ledPin)` | 구현 | 지정 LED bit set |
| `LED_PinOff(uint16_t ledPin)` | 구현 | 지정 LED bit reset |
| `LED_PinToggle(uint16_t ledPin)` | 구현 | 지정 LED bit toggle |
| `LED_ShiftLeft()` | 다음 확장 | 켜진 LED를 왼쪽으로 이동 |
| `LED_ShiftRight()` | 다음 확장 | 켜진 LED를 오른쪽으로 이동 |

`LED_PinOn()`, `LED_PinOff()`, `LED_PinToggle()`은 `ledPin` 번호를 `1 << ledPin` mask로 바꾼 뒤 GPIOC/GPIOD에 나눠 적용한다. LED 0~7은 하위 byte로 GPIOC에 들어가고, LED 8~15는 상위 byte를 오른쪽으로 8 bit shift한 값으로 GPIOD에 들어가야 한다. 이 분리 처리를 LED driver에 넣어 두면 application은 LED 번호나 16-bit pattern만 다루고 실제 GPIO port 배치는 몰라도 된다.

LED 한 개씩 제어할 수도 있고 16개 전체를 한 번에 쓸 수도 있다. 이번 과제처럼 LED 1개가 좌우로 이동하는 동작은 `uint16_t led_state`를 두고 `0x0001 -> 0x0002 -> ... -> 0x8000 -> 0x4000 -> ...` 순서로 값을 바꾸는 방식이 단순하다. 이때 application은 shift 방향과 delay만 결정하고, 실제 GPIOC/GPIOD write는 LED driver가 맡는 구조가 좋다.

## 3상태 버퍼와 GPIO 방향 제어

GPIO가 output과 input을 모두 지원하려면 같은 외부 pin을 항상 구동하면 안 된다. LED나 FND처럼 값을 내보낼 때는 `ODR` 값을 pin으로 drive하고, button이나 switch처럼 외부 값을 읽을 때는 내부 출력 driver를 꺼서 외부 회로가 pin 값을 만들 수 있게 해야 한다.

이때 사용하는 개념이 3상태 버퍼다. 일반 digital output은 `0`과 `1`만 생각하기 쉽지만, 3상태 버퍼는 출력하지 않는 `Z` 상태를 함께 가진다. `Z`는 high impedance 상태로, 해당 회로가 선을 강하게 `0`이나 `1`로 밀지 않고 사실상 연결을 놓는 상태다.

Custom GPIO에서는 `CR` bit가 output enable처럼 동작한다. `CR=1`이면 출력용 3상태 버퍼가 활성화되어 `ODR` 값이 `io_port`로 나가고, `CR=0`이면 출력 driver가 비활성화되어 외부 pin을 input으로 읽을 수 있는 상태가 된다. 따라서 `0xff`를 mode register에 쓰면 8개 bit 모두 output mode가 되고, button/switch를 연결할 bit는 `0`으로 두어 input mode로 남겨야 한다.

| `CR` bit | GPIO pin 상태 | 연결되는 register 의미 |
| :---: | :--- | :--- |
| `1` | output drive | `ODR` 값이 외부 pin으로 출력 |
| `0` | input/Hi-Z | 외부 pin 값이 `IDR`로 읽힘 |

3상태 버퍼를 쓰지 않고 여러 회로가 같은 선을 동시에 구동하면 한쪽은 `1`, 다른 쪽은 `0`을 내보내는 bus contention이 생길 수 있다. GPIO 방향 제어는 단순히 software mode 이름을 바꾸는 것이 아니라, 내부 출력 driver를 켜고 끄는 hardware control과 연결된다.

## XDC 연결

현재 XDC는 100 MHz system clock, reset button, UART, FND, button/switch, 16 LED 연결이 활성화되어 있다.

| Port | Pin mapping |
| :--- | :--- |
| `sys_clock` | `W5`, 10 ns period |
| `reset` | `U18` |
| `usb_uart_rxd` | `B18` |
| `usb_uart_txd` | `A18` |
| `GPIOA[0]~GPIOA[7]` | FND segment pin `W7, W6, U8, V8, U5, V5, U7, V7` |
| `GPIOB[0]~GPIOB[3]` | FND digit select pin `U2, U4, V4, W4` |
| `GPIOB[4]~GPIOB[5]` | button pin `T18, U17` |
| `GPIOB[6]~GPIOB[7]` | switch pin `V17, V16` |
| `GPIOC[0]~GPIOC[7]` | LED pin `U16, E19, U19, V19, W18, U15, U14, V14` |
| `GPIOD[0]~GPIOD[7]` | LED pin `V13, V3, W3, U3, P3, N3, P1, L1` |

XDC에서 port 이름은 wrapper port와 정확히 맞아야 한다. FND segment와 digit select는 `GPIOA/GPIOB`로, LED 16개는 `GPIOC/GPIOD`로 분리되어 있으므로 firmware에서도 각 GPIO instance의 base address와 실제 board 출력 대상을 함께 확인해야 한다.

## Block Design과 코드 작성의 차이

Vivado block design은 완전히 다른 방식으로 동작하는 것이 아니라, 이미 존재하는 IP module을 GUI에서 instance로 배치하고 wire를 연결하는 방식이다. Verilog로 top module을 작성해 하위 module을 instance하고 signal을 연결하는 것과 개념적으로 같다.

| 방식 | 수업에서의 의미 |
| :--- | :--- |
| 직접 RTL 작성 | 새 기능, 새 peripheral 내부 logic 구현 |
| IP Catalog 사용 | 이미 만들어진 IP block 재사용 |
| Block Design | module instance와 wire 연결을 GUI로 구성 |
| Elaboration 화면 | RTL instance/wire 구조를 schematic처럼 확인 |
| 실제 ASIC/SoC 설계 | 코드와 system-level 설계 중심, GUI block design은 교육/FPGA 실습에 적합 |

따라서 직접 만든 GPIO처럼 내부 logic이 필요한 부분은 RTL로 작성하고, MicroBlaze, UART Lite, clock/reset, AXI interconnect처럼 이미 제공되는 block은 IP로 가져와 연결한다. 수업에서 다루는 GUI block design은 AXI SoC 구조를 눈으로 확인하기 위한 실습 도구로 이해하면 된다.

## 다음에 확인할 것

| 항목 | 확인 내용 |
| :--- | :--- |
| Vitis C application | `GPIOA~D` base address와 register offset 정의 |
| Stopwatch 상태 | run/stop/reset, up/down, mode switch 동작 정의 |
| FND pin mapping | `GPIOA[7:0]` segment, `GPIOB[3:0]` digit select 기준 확인 |
| Button/switch mapping | `GPIOB[4]~GPIOB[7]` 입력 기준 확인 |
| LED driver API | 16-bit LED 값을 GPIOC/GPIOD로 분리하는 함수 구조 |
| Board demo | LED/FND가 register write 결과와 연결되는지 확인 |
