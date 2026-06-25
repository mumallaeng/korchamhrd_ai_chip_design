# 26-06-25 - AXI TimerCounter

## 수업 흐름

StopWatch application에서 software delay 기반으로 시간을 만들던 한계를 확인한 뒤, 정확한 시간 기준을 만들기 위해 timer peripheral을 직접 설계하는 흐름으로 넘어갔다. TimerCounter는 바로 AXI에 붙이지 않고, 먼저 독립 RTL로 작성한 뒤 testbench로 동작을 확인하고, 이후 AXI4-Lite template에 연결하는 순서로 진행한다.

이 방식은 timer 내부 동작 문제와 AXI register 연결 문제를 분리해서 확인하기 위한 흐름이다. 먼저 prescaler, auto reload counter, interrupt pulse, counter load 기능을 단독 RTL에서 검증하고, 이후 AXI write/read register map으로 제어할 수 있게 확장한다.

## 현재 소스 위치

| 위치 | 내용 |
| :--- | :--- |
| [260625_AXI_TimerCounter](../helloHDL/260625_AXI_TimerCounter) | AXI TimerCounter custom IP 작업본 |
| [TimerCounter.v](../helloHDL/260625_AXI_TimerCounter/260625_AXI_TimerCounter.srcs/sources_1/new/TimerCounter.v) | prescaler, auto reload counter, interrupt gate, counter load RTL |
| [tb_TimerCounter.sv](../helloHDL/260625_AXI_TimerCounter/260625_AXI_TimerCounter.srcs/sim_1/new/tb_TimerCounter.sv) | PSC/ARR 설정, interrupt enable, timer disable, counter load 검증용 TB |
| [axi_template_v1_0.v](../helloHDL/260625_AXI_TimerCounter/260625_AXI_TimerCounter.srcs/sources_1/imports/hdl/axi_template_v1_0.v) | TimerCounter를 연결할 AXI custom IP top template |
| [axi_template_v1_0_S00_AXI.v](../helloHDL/260625_AXI_TimerCounter/260625_AXI_TimerCounter.srcs/sources_1/imports/hdl/axi_template_v1_0_S00_AXI.v) | register map과 AXI4-Lite slave 연결 대상 template |
| [tb_axi_timer.sv](../helloHDL/260625_AXI_TimerCounter/260625_AXI_TimerCounter.srcs/sources_1/new/tb_axi_timer.sv) | AXI write/read transaction 검증용 TB 작성 대상 |

## Timer Peripheral 방향

정확한 시간 기준을 만들려면 software delay 대신 timer peripheral을 사용하는 방향으로 확장한다. timer는 입력 clock을 prescaler로 나누고, 나뉜 clock마다 counter를 증가시킨 뒤, counter 값이 auto reload 값과 같아지거나 overflow가 발생했을 때 event 또는 interrupt를 만든다.

| 구성 요소 | 약어 | 역할 |
| :--- | :---: | :--- |
| Prescaler | `PSC` | 입력 clock을 나누는 clock divider |
| Counter | `CNT` | prescaler 출력 tick마다 증가 |
| Auto Reload Register | `ARR` | counter 비교 기준값 |
| Interrupt/Event | - | `CNT == ARR` 또는 overflow 시 발생 |

clock source는 timer가 시간을 세기 시작하는 기준이다. MCU 자료에서는 RCC 같은 clock control block에서 timer clock을 공급하고, 내부 clock을 `CK_INT`, timer에 공급되는 clock을 `TIMxCLK`, prescaler를 지난 counter 입력 clock을 `CK_CNT`처럼 구분해서 부른다. 수업 코드에서는 Basys3의 100 MHz system clock이 `clk`로 들어오고, `psc_counter`가 prescaler 역할을 하며, `psc_tick`이 `CK_CNT`에 해당하는 1 clock pulse로 동작한다.

| 용어 | 수업 코드 대응 | 의미 |
| :--- | :--- | :--- |
| `CK_INT` / `TIMxCLK` | `clk` | timer 입력 기준 clock |
| `PSC` | `psc` | prescaler compare 값 |
| `CK_CNT` | `psc_tick` | counter 증가 기준 tick |
| `CNT` | `counter` / `o_cnt` | 현재 timer count |
| `ARR` | `arr` | auto reload compare 값 |
| update event | `intr_tick` | rollover 순간 내부 pulse |

Basys3 기준 system clock이 100 MHz이면 clock period는 10 ns다. prescaler를 100으로 두면 100 MHz를 100으로 나누어 1 MHz tick을 만들 수 있고, 이 tick의 주기는 1 us다. 이후 counter가 1,000,000번 증가할 때 event를 만들면 1초 주기의 기준 신호를 만들 수 있다.

```text
100 MHz clock
    -> PSC 100
    -> 1 MHz tick
    -> CNT 1,000,000 count
    -> 1 second event
```

이 구조는 기존에 작성했던 clock divider와 counter 개념의 연장이다. 차이는 단순히 LED나 FND를 직접 토글하는 것이 아니라, timer register와 interrupt/event를 통해 application이 정확한 시간 기준을 사용할 수 있게 만드는 점이다.

시간 계산은 입력 clock, prescaler, auto reload 값을 분리해서 본다. 예를 들어 `clk`가 100 MHz이면 1 clock은 10 ns이고, `psc=99`로 설정하면 100 clock마다 `psc_tick`이 발생하므로 counter 증가 기준은 1 us가 된다. 이 상태에서 `arr=999`이면 counter가 `0`부터 `999`까지 1000 tick을 세고 rollover되므로 약 1 ms 주기의 event를 만들 수 있다.

```text
timer event period = (PSC + 1) x (ARR + 1) x input clock period
```

## AXI TimerCounter 작업 흐름

현재 `TimerCounter.v`는 Verilog로 작성한다. AXI template가 Verilog 기반으로 생성되어 있으므로, 우선 같은 언어로 timer RTL을 구성하고 이후 template의 slave register와 연결하는 방향이다. reset은 AXI 쪽 reset 관례에 맞춰 active-low인 `rst_n`을 사용한다.

| 단계 | 확인 내용 |
| :--- | :--- |
| TimerCounter 단독 작성 | `psc`, `arr`, `cnt_en`, `intr_en`, `i_cnt`, `cnt_valid` port 구성 |
| 단독 TB 확인 | prescaler tick, counter rollover, interrupt gate, counter load 흐름 |
| AXI template import | 기존 `axi_template_v1_0` 파일을 project에 추가 |
| Register map 연결 | AXI slave register를 timer control/status register로 매핑 |
| 통합 확인 | AXI write/read로 timer 설정과 count 읽기 동작 확인 |

## TimerCounter RTL 구조

`TimerCounter.v`는 prescaler block과 main counter block을 분리한다. prescaler는 `psc_counter`를 증가시키다가 `psc` 값과 같아지는 순간 `psc_tick`을 1 clock 동안 발생시킨다. main counter는 이 `psc_tick`이 발생한 clock에서만 `counter`를 증가시킨다.

| Signal | 방향 | 역할 |
| :--- | :---: | :--- |
| `clk` | input | timer 동작 기준 clock |
| `rst_n` | input | active-low reset |
| `cnt_en` | input | timer count enable |
| `intr_en` | input | external interrupt output enable |
| `psc` | input | prescaler compare 값 |
| `arr` | input | auto reload compare 값 |
| `cnt_valid` | input | 외부 counter load valid pulse |
| `i_cnt` | input | 외부에서 load할 counter 값 |
| `o_cnt` | output | 현재 counter 값 |
| `intr` | output | enable gate를 통과한 interrupt pulse |

내부 신호는 다음 역할을 가진다.

| 내부 신호 | 역할 |
| :--- | :--- |
| `psc_counter` | `psc`까지 증가하는 prescaler 내부 counter |
| `psc_tick` | `psc_counter == psc`일 때 1 clock pulse |
| `counter` | `psc_tick`마다 증가하는 timer counter |
| `intr_tick` | `counter == arr` rollover 시 1 clock pulse |

핵심 연결은 `psc_tick`이다. prescaler가 tick을 만들더라도 main counter가 그 tick을 조건으로 사용하지 않으면 timer count가 정상적으로 증가하지 않는다. 따라서 main counter block은 `cnt_en`이 켜져 있고 `psc_tick`이 발생한 경우에만 `counter`를 증가시키는 구조로 작성한다.

```verilog
if (cnt_en) begin
    if (psc_tick) begin
        if (counter == arr) begin
            counter   <= 0;
            intr_tick <= 1'b1;
        end else begin
            counter   <= counter + 1;
            intr_tick <= 1'b0;
        end
    end
end
```

`intr_tick`은 rollover 순간을 나타내는 내부 pulse이고, 최종 output인 `intr`은 `intr_en`과 AND로 묶는다. 이 때문에 interrupt가 disable된 상태에서는 rollover가 발생해도 외부 `intr`은 올라가지 않고, enable된 상태에서만 `intr_tick`과 같은 1 clock pulse가 외부로 전달된다.

```verilog
assign intr = intr_tick & intr_en;
```

## Counter Load와 Valid Pulse

Timer counter register는 외부에서 값을 직접 load할 수 있어야 한다. 이를 위해 `i_cnt`와 `cnt_valid`를 추가한다. `i_cnt`는 load할 값이고, `cnt_valid`는 이 값이 유효하다는 1 clock pulse다.

`cnt_valid`는 `cnt_en`보다 우선순위가 높다. timer가 disable되어 있거나 prescaler tick이 없는 구간이어도, 외부에서 counter 값을 바꾸는 동작은 register write 성격이므로 즉시 반영되어야 한다.

```verilog
if (cnt_valid) begin
    counter <= i_cnt;
end else if (cnt_en) begin
    ...
end
```

이 구조에서 `cnt_valid`를 level 신호처럼 오래 유지하면 counter가 같은 값으로 계속 load될 수 있다. TB에서는 `TIM_SetCNT()` task가 `i_cnt`를 넣고 `cnt_valid`를 1로 만든 뒤, 다음 clock에서 다시 0으로 내려 1 clock pulse로 사용한다.

```systemverilog
task automatic TIM_SetCNT(logic [31:0] CNT);
    i_cnt = CNT;
    cnt_valid = 1'b1;
    @(posedge clk);
    cnt_valid <= 1'b0;
endtask
```

## TimerCounter Testbench 시나리오

`tb_TimerCounter.sv`는 timer register 설정을 함수처럼 호출할 수 있도록 task를 나눠 작성한다. 실제 AXI register write가 붙기 전 단계에서, software driver API처럼 timer 설정 순서를 읽을 수 있게 만드는 목적이다.

| Task | 역할 |
| :--- | :--- |
| `TIM_SetPSC()` | prescaler compare 값 설정 |
| `TIM_SetARR()` | auto reload compare 값 설정 |
| `TIM_EnTimer()` | `cnt_en` set |
| `TIM_DisTimer()` | `cnt_en` clear |
| `TIM_EnIntr()` | `intr_en` set |
| `TIM_DisIntr()` | `intr_en` clear |
| `TIM_SetCNT()` | `i_cnt` load와 `cnt_valid` pulse 생성 |

TB clock은 `always #5 clk = ~clk`로 생성하므로 clock period는 10 ns다. `TIM_SetPSC(100 - 1)`은 100 MHz 기준 100 clock마다 `psc_tick`이 발생하도록 설정하는 값이고, 결과 tick 주기는 1 us다. `TIM_SetARR(1000 - 1)`은 timer counter가 `0`부터 `999`까지 증가한 뒤 `0`으로 돌아가도록 하는 설정이다.

| 구간 | 확인 대상 |
| :--- | :--- |
| reset 이후 설정 | `psc=99`, `arr=999`, interrupt disable |
| timer enable | `o_cnt`가 `psc_tick`마다 증가 |
| interrupt disable rollover | `o_cnt=999 -> 0`, 외부 `intr` 비활성 |
| interrupt enable rollover | `o_cnt=999 -> 0`, 외부 `intr` 1 clock pulse |
| timer disable | `cnt_en=0` 이후 `o_cnt` 유지 |
| counter load | `TIM_SetCNT(10)` 이후 `o_cnt` load 확인 |

현재 TB는 단독 RTL 검증용이다. AXI template에 연결한 뒤에는 위 task들이 AXI write/read transaction으로 바뀌어야 한다. 예를 들어 PSC register write, ARR register write, control register의 enable bit set, status register read 같은 형태로 확장된다.

## AXI Template 연결 방향

TimerCounter를 AXI custom IP로 만들 때는 기존 Vivado template의 slave register를 timer register처럼 사용한다. 핵심은 AXI write로 control/config register를 갱신하고, AXI read로 counter/status 값을 읽을 수 있게 만드는 것이다.

일반적인 timer peripheral 관점에서는 control register, prescaler register, auto reload register, counter/status register를 나눈다. 이름은 구현마다 다를 수 있지만, 수업에서는 `TIM-CR`, `PSC`, `ARR`처럼 제어와 시간 기준 설정을 분리해서 보는 것이 핵심이다.

| Register | 연결 대상 | 역할 |
| :--- | :--- | :--- |
| `TIM-CR` | `cnt_en`, `intr_en` | timer enable, interrupt enable 제어 |
| `PSC` | `psc` | clock divider 기준값 설정 |
| `ARR` | `arr` | rollover 기준값 설정 |
| `CNT` write | `i_cnt`, `cnt_valid` | counter load 요청 |
| `CNT` read | `o_cnt` | 현재 counter 값 확인 |
| `STATUS` | `intr` 또는 event bit | rollover/interrupt 상태 확인 |

| Timer 기능 | AXI register 연결 방향 |
| :--- | :--- |
| `cnt_en` | control register bit |
| `intr_en` | control register bit |
| `psc` | prescaler register |
| `arr` | auto reload register |
| `i_cnt` | counter load register |
| `cnt_valid` | counter load write 시 1 clock pulse |
| `o_cnt` | counter status/read register |
| `intr` | IP output 또는 status bit |

template를 수정할 때는 먼저 `axi_template_v1_0_S00_AXI.v` 안에서 slave register write/read 위치를 확인한다. 이후 `slv_reg` 값을 TimerCounter 입력으로 연결하고, `o_cnt`와 interrupt 상태를 read data path에 반영한다. 이 단계부터는 timer RTL 자체보다 AXI register map 설계가 중심이 된다.

## AXI Register Map 구체화

AXI slave template의 `slv_reg`는 timer의 control/config/status register로 해석한다. control register 전체를 timer에 그대로 넘기는 것이 아니라, 필요한 bit를 잘라 `cnt_en`, `intr_en` 같은 제어 신호로 만든다.

| AXI register | bit/data | Timer 연결 | 의미 |
| :--- | :---: | :--- | :--- |
| `slv_reg0` | bit 0 | `cnt_en` | counter enable |
| `slv_reg0` | bit 1 | `intr_en` | interrupt output enable |
| `slv_reg1` | 32-bit | `psc` | prescaler compare 값 |
| `slv_reg2` | 32-bit | `arr` | auto reload compare 값 |
| `slv_reg3` write | 32-bit | `i_cnt` | counter load 값 |
| `slv_reg3` write pulse | 1 clock | `cnt_valid` | counter load 요청 |
| counter read path | 32-bit | `o_cnt` | live counter readback |

`cnt_valid`는 `slv_reg3`에 값을 쓸 때만 1 clock 동안 올라가야 한다. 매 clock 기본값을 `0`으로 두고, `slv_reg3` write가 발생한 cycle에만 `1`로 만드는 방식이다. 이렇게 해야 counter가 한 번만 load되고, 이후에는 prescaler tick에 따라 정상 증가한다.

`o_cnt`는 TimerCounter 내부에서 계속 변하는 현재 counter 값이다. 따라서 현재 count를 software가 읽어야 하는 구조에서는 `slv_reg3`에 저장된 마지막 write 값보다 TimerCounter의 live output인 `o_cnt`를 read data path에 연결하는 편이 목적에 맞다.

## AXI Write/Read 검증 방향

AXI 통합 이후에는 단독 TB의 task 호출을 AXI4-Lite write/read transaction으로 바꿔 확인한다. 먼저 timer 설정 register에 값을 쓰고, control register로 timer를 enable한 뒤, counter readback과 response channel을 확인하는 순서다.

| 순서 | 동작 | 확인 대상 |
| :---: | :--- | :--- |
| 1 | `PSC` register write | `slv_reg1=99`, 100 MHz -> 1 MHz tick |
| 2 | `ARR` register write | `slv_reg2=999`, 1 ms rollover 기준 |
| 3 | control register write | `slv_reg0[0]=1`, timer enable |
| 4 | 선택적 interrupt enable | `slv_reg0[1]=1`, rollover interrupt output |
| 5 | counter load write | `slv_reg3`, `cnt_valid` 1 clock pulse |
| 6 | counter read | `o_cnt` readback |
| 7 | response 확인 | `BRESP=2'b00`, `RRESP=2'b00` |

AXI write data channel에서는 `WSTRB`도 반드시 구동해야 한다. Vivado AXI slave template는 byte 단위 write loop에서 `S_AXI_WSTRB[byte_index]`가 1인 byte만 register에 반영한다. 32-bit register 전체 write를 의도한다면 testbench나 master 쪽에서 `S_AXI_WSTRB=4'b1111`을 같이 넣어야 한다.

```verilog
for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1; byte_index = byte_index + 1) begin
    if (S_AXI_WSTRB[byte_index] == 1) begin
        slv_reg1[(byte_index * 8) +: 8] <= S_AXI_WDATA[(byte_index * 8) +: 8];
    end
end
```

이 구조에서 `WSTRB`가 빠지거나 `0`이면 address/write handshake가 진행되어도 실제 `slv_reg` 값은 기대대로 갱신되지 않을 수 있다. 따라서 AXI 통합 TB는 `AWVALID/AWREADY`, `WVALID/WREADY`, `BVALID/BREADY`, `ARVALID/ARREADY`, `RVALID/RREADY`뿐 아니라 `WSTRB`까지 함께 확인해야 한다.

## 다음에 확인할 것

| 항목 | 확인 내용 |
| :--- | :--- |
| TimerCounter TB | PSC tick, ARR rollover, interrupt gate, counter load 흐름 확인 |
| AXI register map | `slv_reg0` control bit, `slv_reg1` PSC, `slv_reg2` ARR, `slv_reg3` CNT load 매핑 |
| `cnt_valid` | counter load write 시 1 clock pulse 생성 |
| `WSTRB` | 32-bit register write에서 `4'b1111` 구동 |
| AXI 통합 TB | PSC/ARR/control write, `o_cnt` readback, `BRESP/RRESP` 확인 |
