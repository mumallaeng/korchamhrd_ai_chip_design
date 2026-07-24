# 26-07-24 - Verification Learning Journey 특강

관련 학습:

- [UVM Verification Guide](../../../domains/semiconductor/ai-npu-system-integration/uvm-verification-guide.md)
- [SPI·I2C UVM Verification Plan](../assignment/_project/260618_SPI_I2C_UVM/30-uvm-verification-plan/README.md)
- [디지털 설계·검증 종합 노트](../../../domains/semiconductor/ai-npu-system-integration/digital-design-verification-fpga-vga-and-on-device-ai.md)
- [08-synthesis: elaboration, inference, netlist, optimization, constraints](../../../domains/semiconductor/digital-electronics-foundations/08-synthesis.md)
- [09-physical-design: place, route, timing, parasitic, closure](../../../domains/semiconductor/digital-electronics-foundations/09-physical-design.md)
- [26-06-18 - AXI](260618-axi.md)

## 특강 범위

| 구분 | 내용 |
| :--- | :--- |
| 형식 | Verification Learning Journey 특강 |
| 중심 주제 | RTL·합성·timing·CDC·SystemVerilog/UVM 학습 흐름 |
| 실습 source | 별도 source 없음 |

## 지금까지 배운 내용

SPI·I2C DUT를 대상으로 transaction, driver, monitor, scoreboard, coverage를 연결해 verification environment를 구성했다. 오늘 특강은 Verilog, SystemVerilog, UVM을 왜 이 순서로 배우는지 생각해 보는 시간이었다.

```text
RTL design
    ↓
testbench
    ↓
driver / monitor
    ↓
scoreboard / coverage
    ↓
bug 발견·원인 분석·재발 방지
```

## Verilog를 왜 배우는가

`C`와 `Verilog`는 모두 text로 code를 작성한다. `C`는 CPU가 실행할 software 동작을 표현하고, `Verilog`는 hardware의 state·connection·clock 동작을 표현한다. Verilog source는 simulation에서 waveform으로 먼저 확인하고, synthesis와 implementation을 거쳐 FPGA 또는 ASIC의 hardware logic으로 이어진다.

```text
embedded C source
    ↓ compiler
Cortex-M4 같은 CPU가 instruction을 실행
    ↓
register·peripheral·pin state 변화

RTL source
    ↓ simulation
waveform으로 clock별 동작 확인
    ↓ synthesis / implementation
FPGA 또는 ASIC의 hardware logic
```

## 설계와 검증이 보는 범위

| 관점 | 중심 질문 | 주된 결과물 |
| :--- | :--- | :--- |
| RTL design | 요구 기능이 어떤 gate·state·clock 구조가 되는가 | RTL, netlist, timing·implementation 판단 |
| verification | DUT가 주변 interface·protocol·scenario에서 의도대로 동작하는가 | testbench, stimulus, observation, comparison, coverage |

설계자는 HDL source가 gate mapping, physical delay, timing closure, 제조 test까지 이어지는 결과를 판단한다. 검증자는 DUT 주변의 device·interface·protocol을 language로 모델링하고, scenario별 stimulus와 observation을 구성해 설계 의도를 확인한다.

## 논리식에서 RTL까지

digital circuit의 출발점은 input과 output의 관계를 나타내는 Boolean function이다. truth table과 Boolean expression이 필요한 동작을 나타내고, gate와 flip-flop이 그 관계와 state를 hardware로 만든다. Verilog RTL은 이 gate·state·clock 구조를 사람이 읽고 수정할 수 있는 형태로 표현한다.

```text
truth table / Boolean expression
        ↓ 논리 단순화
gate·flip-flop 구조
        ↓ RTL로 표현
synthesis
        ↓
target library cell·net 연결
```

Karnaugh map은 사람이 Boolean expression을 단순화할 때 쓰는 방법이다. synthesis는 같은 목적을 더 큰 RTL에 적용해, 논리적으로 같은 기능을 유지하면서 target library와 timing constraint에 맞는 gate 구조를 찾는다.

### Boolean 2-state와 simulation의 4-state

Boolean function과 Karnaugh map은 `0`과 `1`의 논리 관계를 다룬다. Verilog simulation은 여기에 `X`와 `Z`를 더한 4-state 값을 사용한다. `Z`는 driver가 line을 release한 high-impedance 상태이고, `X`는 초기값 미정, driver 충돌, 불완전한 assignment처럼 binary value가 결정되지 않은 상태다.

Karnaugh map의 `don't care`는 specification이 `0` 또는 `1`을 모두 허용하는 optimization 조건이다. waveform의 `X`는 signal의 원인을 추적해야 하는 unresolved 상태다. 여러 driver가 `0`과 `1`을 동시에 구동하면 simulation은 보통 `X`를 표시한다. board 수준의 resolved voltage는 driver strength와 load에 따라 결정되며, testbench는 필요할 때 net-strength model로 이 전기적 조건을 표현한다.

### RTL을 gate·state 구조로 읽기

RTL을 읽거나 작성할 때에는 assignment와 `always` block이 어떤 gate, mux, flip-flop, state transition을 만들지 함께 그려 본다. 이 관점은 syntax를 hardware behavior와 연결하는 기준이 된다.

`combinational loop`는 flip-flop 같은 state element 없이 combinational output이 자신의 input으로 되돌아가는 feedback path다. 안정된 state와 전달 순서를 정할 수 없으므로 synthesis flow에서 문제로 다뤄진다. RTL source를 손으로 간단히 gate 구조로 그려 보면 이런 feedback을 일찍 찾을 수 있다.

simulation은 procedural event를 따라 waveform을 만들고, synthesis는 gate·state structure를 hardware로 구현한다. RTL을 학습할 때에는 waveform으로 behavior를 확인하고, 동시에 어떤 gate와 state가 inference될지 직접 추적한다. 이 두 관점이 함께 있어야 source 수정이 design intent와 연결된다.

## 문법을 하나의 흐름으로 보기

`blocking`·`nonblocking` assignment, synthesizable RTL, simulation waveform은 설계와 검증 흐름에서 서로 연결된다. 문법을 배울 때마다 source가 어떤 cycle 관계를 만들고, waveform에서 그 관계를 어떻게 확인하는지 함께 본다.

```text
설계 요구사항
    ↓
clock·reset·state·data path를 RTL로 표현
    ↓
testbench stimulus와 waveform 관찰
    ↓
expected / actual 비교
    ↓
bug 원인 분석과 수정
```

waveform은 설계 의도와 simulation 결과의 cycle 관계를 보여 주는 자료다.

simulation을 실행하기 전에 input, current state, next state, output이 cycle마다 어떻게 변할지 먼저 예상한다. waveform에서는 이 예상과 실제 결과를 비교하고, 차이가 보이면 RTL의 state·combinational path·clock 관계를 따라 원인을 찾는다.

### `reg`와 hardware inference

Verilog의 `reg`는 procedural block에서 값을 대입받는 variable이다. CPU architecture의 `R0`·`R1`은 physical storage resource를 가리키고, Verilog의 `reg`는 source 안에서 값을 보관하는 procedural variable을 가리킨다. synthesis는 event control, 조건 구조, 각 path의 assignment 완전성을 보고 combinational logic, latch, flip-flop을 결정한다.

`always @(posedge clk or negedge rst_n)`은 rising-edge flip-flop과 active-low asynchronous reset 의도를 표현한다. `rst_n`이 low로 바뀌는 event는 clock edge와 독립적으로 reset 동작을 시작한다.

combinational `always @(*)` block에서 `*`는 RHS에서 읽는 모든 signal을 sensitivity set에 넣는다. signal 이름 `clk`는 source의 label이고, `posedge`·`negedge` event control과 assignment path의 완전성이 flip-flop·combinational logic·latch inference를 결정한다.

combinational block에서는 실행 가능한 모든 path에서 output에 값을 대입한다. `if`의 `else` 또는 `case`의 `default`가 빠져 assignment path가 비면, 이전 값을 유지할 storage가 필요해져 level-sensitive latch가 추론된다. block 첫머리에 default assignment를 두고 조건 branch에서 필요한 값만 덮어쓰는 방식은 이 조건을 명확하게 만든다.

### SystemVerilog의 `always_*` intent

SystemVerilog의 `always_comb`, `always_ff`, `always_latch`는 procedural block이 표현할 hardware 의도를 명시한다. `always_comb`는 combinational logic, `always_ff`는 edge-triggered sequential logic, `always_latch`는 의도적으로 사용하는 latch를 나타낸다. compiler와 lint tool은 sensitivity, multi-driver, assignment style의 충돌을 더 잘 검사할 수 있다.

### blocking·nonblocking assignment와 RHS·LHS

`RHS`는 assignment 오른쪽의 expression이고, `LHS`는 값을 갱신하는 왼쪽 target이다. blocking assignment `=`는 active region에서 RHS를 평가한 뒤 LHS를 바로 갱신하므로 같은 procedural block의 뒤 statement가 갱신된 값을 읽는다. nonblocking assignment `<=`는 RHS를 active region에서 평가하고 LHS 갱신을 NBA region에 예약한다. 같은 clock edge에서 실행되는 뒤 statement는 edge 직전의 register 값을 읽는다.

```systemverilog
always_comb begin
  a = b;
  c = a;   // c는 현재 b 값을 받음
end

always_ff @(posedge clk) begin
  q1 <= d;
  q2 <= q1; // q2는 edge 직전 q1 값을 받음
end
```

combinational logic에는 `=`를, clocked sequential logic에는 `<=`를 사용하면 source의 behavior와 hardware intent가 일치한다. assignment 사이 data dependency가 없으면 waveform 결과가 같아 보일 수 있다. style을 분리하면 dependency가 생기는 순간에도 동작 의도를 유지할 수 있다.

### event scheduling과 `#0`

procedural assignment를 이해하기 위한 기본 simulation 흐름은 `active → inactive → NBA`다. active region에서는 blocking assignment와 nonblocking assignment의 RHS evaluation이 수행된다. `#0`는 simulation time을 진행시키지 않고 execution을 같은 time slot의 inactive region으로 미룬다. NBA region에서는 예약된 nonblocking assignment의 LHS update가 수행된다.

`#0`는 legacy simulation scheduling에 쓰인 순서 제어 방식이다. synthesizable sequential RTL은 `<=`와 NBA 의미로 flip-flop의 sample·update 관계를 표현한다. SystemVerilog scheduler에는 verification을 위한 추가 region이 있으므로, 이 흐름은 RTL procedural assignment를 읽기 위한 핵심 범위로 사용한다.

### simulation time, `timeunit`, `timeprecision`

simulation time은 simulator가 event 순서를 계산하는 논리 시간이다. host computer가 이 event를 처리하는 실제 경과 시간과는 별개다. `timeunit`은 `#1` 같은 delay의 기준 단위이고, `timeprecision`은 표현·처리할 수 있는 최소 시간 간격이다. legacy Verilog의 `` `timescale 1ns/100ps ``도 이 두 값을 함께 표현한다.

```systemverilog
timeunit 1ns;
timeprecision 100ps;
```

precision보다 짧은 delay는 timeprecision tick으로 반올림되어 waveform에서 `0` delay처럼 보이거나 예상과 다른 시점에 나타날 수 있다. 각 time slot에서는 active·inactive·NBA 같은 scheduler region의 event가 모두 처리된 뒤 그 시점의 값이 정해진다.

### race condition과 DUT·testbench 경계

같은 simulation time과 scheduler region에서 독립 process가 같은 signal을 read·write하면 실행 순서가 source로 정해지지 않는 `race condition`이 생긴다. 한 simulator에서 반복 실행한 결과가 같아도 language가 그 순서를 보장한 것은 아니다. signal update와 `$display` 같은 관찰 process가 같은 time slot에 있으면 old value와 new value 중 무엇을 관찰하는지도 scheduling 관계에 따라 달라질 수 있다.

testbench는 DUT의 input drive 시점과 output sample 시점을 protocol으로 정해 race를 제거한다. `#0`는 inactive region으로 실행을 미루는 legacy 방법이고, RTL hardware timing을 표현하는 수단은 아니다. SystemVerilog의 `program`은 testbench procedure를 DUT `module`과 다른 scheduling 관점에 두어 race를 줄이기 위해 도입된 construct다.

### 하나의 MUX를 여러 RTL 형식으로 표현하기

2:1 MUX의 선택 동작은 combinational `always` block의 `if/else` 또는 `case`, continuous assignment의 conditional operator, Boolean expression, gate primitive처럼 여러 RTL 형식으로 표현할 수 있다. 같은 combinational behavior를 정확히 표현하면 synthesis는 target library 또는 FPGA resource에 맞는 MUX 구조로 mapping한다.

2:1 MUX는 select `S`가 `0`일 때 `A`, `1`일 때 `B`를 output `Y`로 전달하는 선택 회로다. Boolean expression은 `Y = (~S & A) | (S & B)`로 쓸 수 있다. 이 식은 `S` inverter, 두 개의 AND gate, 한 개의 OR gate로 구현할 수 있다.

| `S` | 선택 input | `Y` |
| :---: | :---: | :---: |
| `0` | `A` | `A` |
| `1` | `B` | `B` |

source를 읽을 때에는 문법 형식보다 input, select, output 사이에 어떤 hardware behavior가 생기는지 먼저 파악한다.

`if / else if` chain은 조건이 동시에 참일 수 있을 때 source 순서에 따라 priority를 만든다. `case` item과 조건이 서로 배타적인 `if / else if` chain은 synthesis에서 더 평평한 selection logic으로 최적화할 수 있다. source의 `if`·`case` 형식만으로 physical topology나 critical path를 단정하지 않고, Boolean dependency, target library, timing constraint를 반영한 netlist와 STA 결과로 확인한다.

### MUX의 physical delay와 glitch

RTL functional simulation에서는 MUX의 Boolean function이 같은 simulation time에 계산되는 모습이 주로 보인다. gate-level netlist와 physical implementation에서는 inverter, AND gate, OR gate, wire마다 propagation delay가 생긴다. `S`가 바뀌는 순간 `~S & A` path와 `S & B` path의 도착 시간이 어긋나면 `Y`에 짧은 `glitch` 또는 `hazard`가 나타날 수 있다.

data MUX output이 edge-triggered flip-flop의 D input으로 들어갈 때에는 capture edge의 setup·hold window를 만족하는 안정된 값이 중요하다. window 밖의 transient는 다음 state에 전달되지 않을 수 있고, window와 겹치는 transient는 잘못된 capture 또는 metastability 위험으로 이어진다. level-sensitive latch는 enable level 동안 input 변화를 전달하므로 같은 glitch를 더 긴 시간 범위에서 검토한다.

## 합성 가능한 RTL과 testbench code

Verilog와 SystemVerilog source에는 실제 hardware logic으로 합성할 RTL과 simulation에서 DUT를 검증할 testbench code가 함께 등장한다. RTL은 register, combinational logic, state machine 같은 hardware structure를 표현한다. testbench는 stimulus를 만들고 DUT signal을 관찰하며 expected 결과를 비교한다.

| 구분 | 주된 역할 | 결과 |
| :--- | :--- | :--- |
| synthesizable RTL | hardware structure·clock 동작 표현 | synthesis 대상 |
| testbench code | stimulus·관찰·비교 | simulation 전용 |

source를 읽을 때 먼저 '이 code는 회로가 되는 RTL인가, testbench에서 DUT를 검증하는 code인가'를 구분한다. 이 구분이 잡히면 `Verilog`와 `SystemVerilog` 문법을 어떤 목적으로 쓰는지 읽기 쉬워진다.

| 구분 | 대표 construct | 사용 목적 |
| :--- | :--- | :--- |
| synthesizable RTL | `assign`, `always_comb`, `always_ff`, `if`, `case`, static `for`·`generate` | target hardware structure 표현 |
| simulation·testbench | `#delay`, class·object, queue, randomization, coverage, `$display`, strength·`pullup` | virtual environment와 observation 표현 |

construct의 synthesis 지원 범위는 FPGA·ASIC target, tool version, constraint에 따라 달라진다. RTL source는 target hardware로 고정할 structure를 표현하고, testbench는 simulation에서만 필요한 시간·object·scenario를 자유롭게 사용한다.

`module` 문법만으로 DUT와 testbench의 역할이 결정되지는 않는다. top hierarchy와 component 역할이 구분한다. DUT가 clock edge에서 input을 sample하는 시점, testbench가 같은 edge 전후에 drive·observe하는 시점을 명시하면 verification environment의 race를 줄일 수 있다.

## FSM의 hardware 구조와 3-block coding

FSM은 current state를 flip-flop에 저장하고, combinational logic이 `current state + input → next state`를 계산하며, 다음 clock edge에서 next state를 저장하는 structure다. output logic은 current state와 input에서 필요한 output을 계산한다.

```text
current-state register
        ↓ current state
next-state combinational logic ← input
        ↓ next state
next clock edge에서 register 갱신

output combinational logic ← current state·input
```

권장 구조는 state register용 `always_ff`, next-state logic용 `always_comb`, output logic용 `always_comb`의 세 block이다. next-state와 output block의 첫 부분에 default value를 두면 latch inference를 막고, state transition·output 조건·waveform debug를 분리할 수 있다.

여러 FSM이 서로의 state 또는 handshake를 기다리는 구조에서는 circular wait가 `deadlock`으로 이어질 수 있다. reset, 진행 조건, timeout 또는 탈출 경로를 요구사항에 포함해 state machine 전체의 forward progress를 확인한다.

### state encoding과 상태 상수

binary, Gray, one-hot은 state encoding의 선택지다. encoding은 flip-flop 수, decode logic, timing에 영향을 준다. 상태의 의미와 bit pattern을 분리해 이름으로 정의하면 RTL을 읽기 쉽다.

```systemverilog
typedef enum logic [1:0] {IDLE, READ, WRITE, ERROR} state_t;
state_t state_q, state_d;
```

Verilog에서는 `localparam`으로 module 내부 state code를 정의한다. `parameter`는 instance마다 바꿀 수 있는 width·depth 같은 configurable value에 사용하고, FSM state code처럼 instance가 바꾸면 안 되는 값은 `localparam`으로 고정한다. `` `define``는 preprocessing macro이므로 compilation unit과 `include` source에 영향을 줄 수 있다. macro definition·package import·`timescale`은 consumer source보다 먼저 처리되도록 file list와 compile order를 관리한다.

## synthesis와 gate-level netlist

synthesis는 RTL의 논리 관계를 target technology에 맞는 logic cell과 연결로 바꾼다. ASIC flow에서는 target standard-cell library를 기준으로 cell을 선택하고 최적화한다. library에는 사용할 수 있는 logic cell의 기능, drive strength, timing 특성이 담긴다.

```text
RTL
    ↓ synthesis
target standard-cell library에 맞춘 logic mapping
    ↓
gate-level netlist
    ↓
cell placement / routing / timing 검토
```

`gate-level netlist`는 선택된 cell과 cell 사이 net 연결을 나타낸다. 같은 RTL도 target library와 timing constraint에 따라 다른 mapping 결과를 만들 수 있다.

FPGA에서는 Vivado가 RTL을 LUT, FF, BRAM, DSP 같은 FPGA resource로 mapping한다. ASIC의 standard-cell mapping과 target은 다르지만, 'RTL을 target hardware resource로 바꾸고 timing을 확인한다'는 큰 흐름은 같다.

### formal equivalence checking

`formal equivalence checking`은 기준 RTL 또는 기준 netlist와 synthesis·optimization·DFT 삽입 뒤 netlist가 같은 기능을 유지하는지 비교한다. `LEC`는 Logic Equivalence Checking의 약자이며, `Formality`는 이 목적에 쓰는 대표적인 tool 이름이다.

```text
reference RTL 또는 netlist
        ↓ implementation transform
candidate netlist
        ↓ formal equivalence checking
기능 동등성 확인
```

functional verification은 요구 scenario에서 DUT behavior를 확인한다. formal equivalence checking은 implementation 과정에서 design intent가 유지되었는지 확인한다. 두 검증은 서로 다른 시점에서 같은 chip의 신뢰성을 높인다.

### target library가 optimization의 기준이 되는 이유

synthesis의 핵심은 source의 논리 관계를 target library cell과 timing constraint에 맞는 gate network로 mapping하고 최적화하는 데 있다. library에 실제로 존재하는 gate·buffer·flip-flop의 종류, drive strength, timing 특성이 이 결과를 결정한다. library가 달라지면 사용할 수 있는 cell 조합도 달라지므로 같은 RTL이라도 netlist 구조가 달라질 수 있다.

`gate-level netlist`는 원래 RTL의 algorithm 표현보다 cell instance와 net 연결에 가깝다. Verilog와 비슷한 text 형식으로 보이더라도, 읽을 때에는 target library cell과 physical implementation으로 이어지는 구조로 이해한다.

## clock와 handshake

비동기 data 전달에서는 보내는 쪽과 받는 쪽이 request·acknowledge 또는 준비 상태를 확인하며 data를 주고받는다. 동기식 회로에서는 공통 clock edge를 기준으로 register가 state와 data를 받아 다음 cycle로 전달한다.

| 방식 | data 전달 기준 | 수업에서 만나는 예 |
| :--- | :--- | :--- |
| 비동기 handshake | 송신·수신 준비와 acknowledge | 서로 다른 timing을 가진 block 사이 제어 |
| 동기식 transfer | 공통 clock edge | FPGA RTL, AXI channel |

AXI의 `VALID/READY`는 shared `ACLK`의 rising edge에서 두 signal이 함께 high일 때 transfer가 성립하는 동기식 handshake다. `VALID/READY`라는 이름만 보고 비동기 회로로 읽지 않도록 구분한다.

### multi-clock와 CDC

`CDC`는 Clock Domain Crossing의 약자다. 서로 다른 clock domain 사이를 signal이 건너는 구조를 뜻한다. multi-clock chip은 계속 복잡해지고 있으며, clock 관련 issue가 줄어든 배경에는 CDC analysis tool이 crossing 구조와 constraint를 조기에 점검하는 역할이 있다.

CDC tool은 architecture의 의도를 자동으로 만들어 주지는 않는다. design에는 source·destination clock, crossing signal의 의미, reset 관계, protocol rule이 명확히 표현되어야 한다. clock switching의 pulse 안전성과 CDC의 domain-crossing 검증은 서로 다른 문제로 구분한다.

### clock 관계와 CDC 판단

CDC 여부는 frequency 값보다 clock source와 phase relation으로 판단한다. 하나의 PLL과 divider에서 파생된 clock은 frequency·phase 관계가 알려져 있고 timing constraint로 표현되면 synchronous timing path로 분석한다. 독립 PLL에서 나온 clock은 chip을 켤 때마다 상대 phase가 달라질 수 있으므로 CDC protocol로 data 전달을 설계한다.

| clock 관계 | 설계·분석 기준 |
| :--- | :--- |
| common PLL·known phase relation | related-clock timing constraint와 STA |
| independent PLL·unknown relative phase | CDC synchronizer·handshake·FIFO |
| 외부 asynchronous input | destination-domain synchronizer |

### metastability와 `MTBF`

asynchronous input이 destination clock edge의 setup·hold window와 겹치면 capture flip-flop 내부가 `metastability` 상태에 들어갈 수 있다. metastability는 physical circuit의 analog settling 현상이다. 최종적으로 `0` 또는 `1`로 수렴하지만, 수렴 값과 수렴 시점은 보장할 수 없다. 이 출력을 여러 downstream logic에 직접 fanout하면 consumer마다 다른 결과를 관찰할 위험이 생긴다.

simulation의 `X`는 unresolved condition을 보이는 digital symbol이다. metastability의 발생과 recovery time은 transistor·voltage·temperature·noise에 좌우되는 physical behavior다. RTL functional simulation은 protocol과 cycle behavior를 확인하고, CDC analysis·library data·physical implementation은 metastability risk를 관리한다.

`MTBF`는 Mean Time Between Failures다. metastability failure의 대표 model은 `MTBF ∝ e^(T_res / τ) / (C × f_clk × f_data)` 형태를 사용한다. `T_res`는 다음 stage가 sample하기 전까지 확보한 resolution time, `τ`는 target flip-flop의 metastability time constant, `f_clk`는 destination sampling frequency, `f_data`는 asynchronous input의 toggle rate다. resolution time을 늘리고 `τ`가 작은 cell을 쓰면 MTBF가 커진다. clock frequency·data toggle rate가 커지면 risk가 늘어난다.

RTL 작성자는 standard-cell의 setup·hold·`τ`를 바꾸지 않는다. architecture에서 synchronizer stage 수, available resolution time, protocol latency, data rate를 조정해 목표 MTBF와 performance를 함께 맞춘다.

### single-bit CDC synchronizer

single-bit control signal은 destination domain의 `2-FF synchronizer`로 받는 구조를 자주 사용한다. 첫 번째 flip-flop은 metastability가 생길 수 있는 경계다. destination logic은 두 번째 flip-flop output만 사용한다. 첫 stage output을 pulse 생성이나 control logic에 연결하면 metastability가 downstream으로 다시 전파된다.

```systemverilog
logic sync_ff1, sync_ff2, sync_ff2_d;

always_ff @(posedge clk_dst) begin
  sync_ff1   <= req_src;
  sync_ff2   <= sync_ff1;
  sync_ff2_d <= sync_ff2;
end

assign pulse_dst = sync_ff2 & ~sync_ff2_d;
```

위 구조의 `pulse_dst`는 destination domain에서 만든 one-shot event다. source pulse는 destination이 capture할 수 있도록 충분히 길게 유지하거나 request·acknowledge handshake로 보장한다. 빠른 source의 짧은 pulse는 느린 destination에서 놓칠 수 있고, 느린 source의 level signal은 빠른 destination에서 여러 cycle 동안 high로 보일 수 있다.

`2-FF`는 자주 쓰는 출발점이다. target MTBF, destination frequency, available resolution time, latency budget에 따라 `3-FF` 이상을 선택할 수 있다. stage가 늘면 metastability recovery 시간은 늘고 control latency도 늘어난다.

### multi-bit CDC와 handshake

multi-bit bus의 각 bit를 독립 synchronizer로 통과시키면 destination에서 old bit와 new bit가 섞인 word를 관찰할 수 있다. multi-bit transfer는 data bus와 control signal의 역할을 분리해 설계한다.

```text
source domain
  data bus를 stable하게 유지
  request / valid control을 destination으로 CDC
        ↓
destination domain
  synchronized control을 확인
  stable window에서 data bus sample
  acknowledge를 source로 CDC
```

open-loop 방식은 source가 control signal을 보내고 수신 확인 없이 다음 동작으로 진행한다. closed-loop handshake는 request와 acknowledge를 양방향으로 synchronize하고, source는 acknowledgement 전까지 data를 안정적으로 유지한다. closed-loop 구조는 delivery guarantee를 높이고 latency를 추가한다. 양쪽 FSM은 ready state, transfer event, return acknowledgement를 관리한다.

source에서 만든 pulse를 destination에서 바로 쓰지 않는다. synchronizer 최종 stage 뒤에서 destination-domain one-shot을 만들고, 그 event를 기준으로 local FSM과 data capture를 진행한다.

### asynchronous FIFO

연속적이거나 throughput이 높은 multi-bit CDC에는 `asynchronous FIFO`를 사용한다. dual-port RAM의 write side와 read side는 각자의 clock으로 동작한다. write pointer와 read pointer 정보는 반대 domain에 안전하게 전달하고, 각 domain은 이 정보를 기준으로 `full`과 `empty`를 판단한다.

circular FIFO에서는 address bit만으로 `full`과 `empty`를 구분할 수 없다. pointer에 wrap 정보를 추가하면 같은 address에서도 `empty`의 같은 phase와 `full`의 한 바퀴 차이를 구분할 수 있다. 대표 implementation은 Gray-coded pointer를 synchronize해 pointer 변화 중 여러 bit가 동시에 바뀌어 보이는 risk를 줄인다.

| 전달 조건 | 주된 CDC 구조 | trade-off |
| :--- | :--- | :--- |
| 드문 1-bit control event | `2-FF`·destination one-shot | latency 추가 |
| 드문 multi-bit transaction | stable-data request·acknowledge | latency·FSM 관리 |
| 지속적 multi-bit stream | asynchronous FIFO | RAM·pointer·status 관리 |

CDC 구조 선택은 signal width, event rate, loss 허용 여부, latency budget, resource를 함께 기준으로 정한다.

## setup·hold와 물리 구현

capture register는 clock edge 전 `setup time` 동안 input data가 안정되어 있어야 하고, edge 뒤 `hold time` 동안에도 data를 유지해야 한다. 이 window가 깨지면 register 내부에서 metastability가 생길 수 있고, 다음 logic이 안정된 `0` 또는 `1`을 받을 시점을 보장하기 어려워진다.

placement는 cell의 실제 위치를 정하고, routing은 cell 사이 wire를 연결한다. 같은 논리도 cell 위치와 wire 길이에 따라 path delay가 달라진다. implementation 과정에서는 buffer와 route를 조정하고, 모든 path가 setup·hold 조건을 만족하는지 timing 분석으로 확인한다.

```text
gate-level netlist
    ↓
placement
    ↓
routing
    ↓
setup·hold timing 분석
    ↓
timing closure
```

functional verification은 RTL behavior와 protocol이 요구사항에 맞는지 확인한다. physical implementation의 timing 분석은 실제 target에서 signal이 정해진 시간 안에 전달되는지 확인한다. 두 흐름은 같은 design을 서로 다른 관점에서 완성한다.

### P&R와 STA의 위치

`P&R`은 placement와 routing을 합쳐 부르는 말이다. synthesis가 만든 gate-level netlist에 cell의 실제 위치와 wire 경로를 부여한다. 이 단계에서 path의 실제 길이와 delay가 구체화된다.

`STA`는 clock period, setup, hold constraint를 기준으로 path timing을 분석한다. P&R 과정은 buffer 삽입, cell 위치 조정, routing 변경을 반복해 STA의 setup·hold 조건을 만족시키며 timing closure에 도달한다.

`CTS`는 Clock Tree Synthesis의 약자다. clock source에서 sequential element까지 clock network를 구성하고, 각 register에 도착하는 clock의 차이인 skew를 관리한다. CTS와 routing 결과가 반영된 뒤 STA가 setup·hold 조건을 다시 확인한다.

### RTL simulation과 physical delay

RTL functional simulation은 주로 clock과 logic behavior를 확인한다. gate-level netlist에 cell delay와 post-layout timing annotation이 적용되면 각 path의 실제 도착 시간이 달라진다. 여러 path가 한 output으로 모이는 구조에서는 전이 중 짧은 `glitch` 또는 `hazard`가 나타날 수 있다.

edge-triggered flip-flop은 active clock edge에서 setup·hold window를 만족한 data를 capture한다. level-sensitive latch는 enable level 동안 input 변화를 전달한다. 두 storage element는 transient signal을 받아들이는 시간 범위가 다르므로 timing과 waveform을 읽는 기준도 다르다.

### clock switching과 전용 cell

clock 선택은 data 선택보다 엄격한 timing 제어가 필요한 clock infrastructure다. 서로 다른 frequency의 clock을 바꾸는 경로에서는 ASIC standard-cell library의 glitch-free clock mux 또는 FPGA vendor의 dedicated clock-control primitive를 사용한다. 짧은 pulse도 downstream sequential logic에는 clock edge로 인식될 수 있기 때문이다.

```text
PLL
  ↓
clock divider
  ↓
dedicated glitch-free clock mux
  ↓
clock domain에 공급되는 selected clock
```

예를 들어 `50 MHz`와 `100 MHz` clock을 선택하는 domain은 `100 MHz` 기준으로 정상 동작 상태의 setup·hold timing을 검토한다. selection transition에서 생길 수 있는 `runt pulse`는 두 source clock period보다 짧은 high·low pulse 또는 추가 edge다. 이 pulse는 downstream flip-flop에 예상 밖 clock event로 전달될 수 있으므로, dedicated glitch-free clock-control cell이 별도로 안전성을 관리한다. glitch-free clock mux는 한 clock path가 안전한 level에 도달한 뒤 다른 path를 enable하는 구조로 selection transition을 관리한다.

`assign clk_out = sel ? clk_b : clk_a;`는 functional data MUX를 표현한다. clock path에서는 ASIC library의 clock MUX cell 또는 FPGA vendor의 dedicated clock-control primitive를 instance해 clock resource와 timing rule을 tool에 전달한다. 이미 검증된 library cell과 IP를 재사용하면 silicon timing risk와 검증 범위를 관리할 수 있다. clock-control module에서 `PLL → divider → dedicated clock mux` 연결을 보면, data path의 일반 MUX와 구분해 읽는다.

## DFT와 제조 test

`DFT`는 Design for Test의 약자다. chip 내부에 제조 test를 위한 구조를 넣어 wafer test와 final test에서 physical defect를 관찰하고 판정할 수 있게 한다. functional verification은 요구 기능과 protocol behavior를 확인하고, DFT 기반 제조 test는 fabrication·packaging 뒤 physical chip의 testability를 활용한다.

`GDSII`는 physical verification과 signoff를 거친 뒤 foundry에 전달하는 physical layout data다.

```text
RTL / netlist
    ↓ synthesis·P&R·signoff
GDSII layout data
    ↓ foundry fabrication
wafer / die
    ↓ packaging
manufacturing test with DFT support
```

## 같은 testbench를 함께 쓰는 방법

testbench에는 stimulus 생성, DUT signal 구동, DUT 동작 관찰, 결과 비교, log와 coverage 수집처럼 반복되는 구조가 있다. 공통 체계와 약속을 두면 각 사람이 비슷한 testbench를 매번 처음부터 작성하는 시간을 줄이고, component를 재사용할 수 있다.

chip은 board와 peripheral, memory, interface device 같은 주변 환경과 연결되어 동작한다. verification environment는 실제 chip·board가 준비되기 전에 이 주변 조건을 transaction, interface, protocol model로 구성한다. DUT와 외부 환경의 연결 조건을 pre-silicon 단계에서 확인하는 것이 testbench의 범위다.

### open-drain protocol model

I²C device의 open-drain output은 line을 low로 능동 구동하거나 `Z`로 release한다. high level은 모든 participant가 line을 release했을 때 pull-up이 만든다. 이 electrical contract를 testbench에 반영해야 DUT가 protocol을 지키는지 확인할 수 있다.

```systemverilog
tri sda;
pullup (sda);
assign sda = drive_low ? 1'b0 : 1'bz;
```

master·slave counterpart는 실제 chip RTL 복제본일 필요가 없다. SystemVerilog, C, Python 등으로 behavior model을 만들 수 있다. 다만 open-drain·pull-up·release timing처럼 관찰 가능한 protocol contract는 model에서도 유지한다. counterpart가 high level을 push-pull로 직접 구동하면 특정 testbench 조합만 통과하는 검증이 될 수 있다.

현재 배운 UVM은 이 구조를 위한 framework다.

```text
verification scenario
    ↓
SystemVerilog로 transaction과 testbench component 작성
    ↓
UVM sequence / driver / monitor / scoreboard 연결
    ↓
DUT behavior 관찰·비교·보고
```

## SystemVerilog와 OOP

SystemVerilog는 RTL에도 쓰고 testbench에도 쓴다. UVM testbench에서는 class와 object를 이용해 transaction과 component를 표현한다. OOP는 verification에 필요한 개념부터 익혀서 sequence, driver, monitor, scoreboard의 역할과 연결한다.

SystemVerilog verification에서 함께 보는 세 축은 OOP, assertion, coverage다.

| 항목 | verification에서 하는 일 |
| :--- | :--- |
| OOP | transaction과 testbench component 구성·재사용 |
| assertion | clock 기준 property·protocol 규칙 검사 |
| coverage | 실행한 scenario·state·value 범위 측정 |

### testbench가 SystemVerilog 기능을 쓰는 이유

testbench는 hardware로 합성하지 않는 simulation code다. 그래서 transaction 생성, component 재사용, protocol rule 검사, coverage 수집처럼 복잡한 verification 작업을 표현할 수 있는 SystemVerilog 기능을 사용한다. hardware 제작 전에 functional bug를 넓은 scenario에서 찾는 것이 이 구조의 목적이다.

## UVM environment의 구조

### static HDL과 dynamic class의 경계

simulation은 `compile → elaboration → run` 흐름을 거친다. compile은 syntax와 type을 확인하고, elaboration은 `module`·instantiated `interface`·DUT의 static hierarchy를 만든다. run 단계에서는 class object가 생성되고 sequence·driver·monitor가 simulation time을 사용해 동작한다.

class handle 선언만으로 object가 생기지는 않는다. `new` 또는 factory의 `create()`가 heap에 object를 만들고 handle이 그 object를 가리킨다. UVM driver와 monitor는 dynamic class object이고, DUT interface instance는 static HDL 영역에 있다. `virtual interface` handle은 이 둘을 연결하는 경계다.

```text
static HDL world
tb_top
  ├ DUT
  ├ interface instance
  └ run_test()
        ↓ virtual interface
dynamic UVM world
uvm_test
  └ uvm_env
      ├ uvm_agent → sequencer / driver / monitor
      ├ uvm_scoreboard
      └ coverage subscriber
```

### component와 object

`uvm_component` 계열은 parent-child hierarchy를 이루는 environment 구조다. phase callback을 통해 생성·연결·실행 순서에 참여한다. `uvm_object` 계열은 transaction data와 그 생성 절차를 표현하며 component tree의 node가 되지 않는다.

| 구분 | 대표 type | 역할 |
| :--- | :--- | :--- |
| component | `uvm_test`, `uvm_env`, `uvm_agent`, `uvm_sequencer`, `uvm_driver`, `uvm_monitor`, `uvm_scoreboard`, `uvm_subscriber` | hierarchy·phase·연결 구조 |
| object | `uvm_sequence_item`, `uvm_sequence` | transaction data·scenario 생성 규칙 |

`sequence_item`은 protocol field를 담은 data packet이고, `sequence`는 item의 순서·반복·randomization rule을 만든다. agent가 `UVM_ACTIVE`일 때는 sequencer·driver·monitor를 구성한다. `UVM_PASSIVE` agent는 monitor만 두어 DUT를 구동하지 않고 observation을 재사용한다.

### transaction에서 pin까지

```text
sequence_item
  ↓ sequence가 scenario·randomization 결정
sequencer
  ↓ TLM sequence-item connection
driver
  ↓ virtual interface로 pin-level protocol 구동
DUT
  ↓ interface signal sample
monitor
  ↓ analysis transaction broadcast
scoreboard / coverage subscriber
```

driver는 transaction field를 clock-cycle signal과 protocol timing으로 변환한다. monitor는 interface signal을 passive하게 sample해 observation transaction으로 복원하고, `analysis_port.write(observed_txn)`로 scoreboard와 coverage subscriber에 같은 observation stream을 broadcast할 수 있다. scoreboard는 input과 output observation을 받아 expected와 actual을 비교한다. reference model은 DUT의 RTL microarchitecture를 복제할 필요가 없으며, specification behavior를 계산하는 algorithmic model로 expected result를 만들 수 있다.

### sequencer arbitration과 sequence-item handshake

test의 `run_phase`는 보통 `sequence.start(sequencer)`로 scenario를 시작한다. sequence의 중심 task는 `body()`이며, 그 안에서 여러 transaction을 만들어 driver에게 보낸다. `start_item(req)`는 sequencer의 grant를 기다리고, `randomize()`는 transaction field를 정하며, `finish_item(req)`는 준비된 request를 전달한다.

```text
sequence
  └ start_item(req) → randomize() → finish_item(req)
                                  ↓
sequencer: 여러 sequence의 request 순서를 arbitration
                                  ↓
driver: get_next_item(req) → protocol signal 구동 → item_done()
```

sequencer는 여러 sequence가 하나의 driver를 공유할 때 request 순서를 arbitration하는 component다. driver는 `seq_item_port.get_next_item(req)`에서 다음 item이 올 때까지 기다리고, item을 DUT protocol의 pin signal로 변환한 뒤 `item_done()`으로 완료를 알린다. 이 흐름은 sequence가 data를 만들고, sequencer가 접근 순서를 정하며, driver가 물리 signal로 변환하는 역할 분리를 만든다.

sequence는 `body()` 앞뒤에 `pre_start()`, `pre_body()`, `post_body()`, `post_start()` callback을 둘 수 있다. 공통 초기화·후처리가 필요할 때 사용한다. `pre_body()`와 `post_body()`는 `start()`의 `call_pre_post` 설정에 따라 생략될 수 있다.

### UVM API의 blocking·nonblocking 의미

UVM sequence-item API에서 `blocking`은 grant나 transaction availability가 될 때까지 task가 기다리는 call semantics다. Verilog procedural assignment의 blocking `=`와 nonblocking `<=`는 같은 simulation time slot 안에서 LHS update 순서를 정하는 semantics다. 두 용어는 이름이 같고, 적용하는 계층과 판단 기준이 다르다.

### UVM phase와 연결 순서

`build_phase`는 top-down으로 test부터 child component를 만들고 configuration을 읽는다. `connect_phase`는 bottom-up으로 port·export·analysis connection을 완성한다. `end_of_elaboration_phase`에서는 만든 topology를 print해 component 구성과 connection을 debug할 수 있다.

`run_phase`는 simulation time을 쓰는 task phase다. clock wait, stimulus drive, monitor sample, sequence execution이 이 단계에서 진행된다. build·connect처럼 function으로 동작하는 phase는 simulation time을 소비하지 않는다. phase 이름은 team이 공유하는 lifecycle contract이므로 component 생성·연결·runtime behavior를 역할에 맞게 분리한다.

runtime workload를 시작한 component 또는 sequence는 `phase.raise_objection(this)`로 objection을 올리고, 끝나면 `phase.drop_objection(this)`으로 내린다. outstanding objection이 남아 있으면 run phase는 끝나지 않는다. 여러 sequence와 component가 동시에 실행될 때에도 마지막 objection이 내려진 뒤에 다음 lifecycle 단계로 진행한다.

### factory, `config_db`, TLM

`type_id::create()`는 UVM factory를 통해 object 또는 component를 만든다. test가 type override를 등록하면 공통 environment source를 고치지 않고도 특정 sequence·driver·component의 concrete type을 바꿀 수 있다. factory가 재사용성을 높이는 이유다.

component를 만들 때 `type_id::create("child_name", this)`의 첫 번째 argument는 instance name이고, 두 번째 argument `this`는 새 component를 현재 component 아래에 넣는 parent handle이다. `super.new(name, parent)`는 base `uvm_component`에 이 hierarchy 정보를 전달한다. factory는 override 가능한 concrete type을 선택하고, parent argument는 UVM component tree의 위아래 관계를 만든다.

`uvm_config_db::set/get`은 `virtual interface`와 agent configuration을 component hierarchy에 전달하는 방식이다. top harness 또는 상위 component가 value를 `set`하고, driver·monitor 같은 consumer가 자기 scope에서 `get`한다. direct hierarchical path를 component마다 고정하지 않아 environment의 이동과 재구성을 쉽게 한다.

TLM port·export는 transaction-level component 연결을 표현한다. sequencer와 driver는 sequence item 전달용 TLM connection을 사용하고, monitor의 analysis port는 scoreboard와 coverage subscriber에 observation transaction을 broadcast할 수 있다. `uvm_info` 같은 report macro는 component name·message ID·verbosity를 포함해 UVM log를 제어한다.

### code coverage와 functional coverage

code coverage는 statement·branch·toggle·FSM state처럼 RTL structure가 실행됐는지 측정한다. functional coverage는 specification에서 정한 value, transition, sequence, cross 조합이 실행됐는지 측정한다. 두 coverage는 서로 다른 질문에 답한다. code coverage가 `100%`여도 요구 scenario가 모두 실행됐다는 보장은 없다.

## 생각과 language

algorithm, data structure, verification scenario에는 먼저 해결하려는 생각과 절차가 있다. Python, C, SystemVerilog 같은 language는 그 생각을 각 실행 환경에 맞게 표현한다. 그래서 SystemVerilog 학습도 UVM component와 verification scenario를 작성하는 데 필요한 표현부터 익힌다.

## 이후 연결

```text
이 표현은 어떤 hardware 또는 verification 의도를 나타내는가?
    ↓
simulation에서 어떤 waveform·transaction 흐름으로 확인하는가?
    ↓
UVM environment에서는 어느 component가 이 역할을 맡는가?
```

- RTL 설계 경험을 verification 관점의 test scenario·coverage·debug 경험으로 재정리
- Cortex-M firmware와 FPGA RTL 실습에서 검증 가능한 요구사항·관찰 지점 분리
- SPI·I2C UVM environment에서 transaction이 signal로 변환되고 다시 observation으로 돌아오는 경로를 source와 waveform으로 대조
