# 26-06-08 - Clocked Adder UVM 소스코드 읽기

0608 수업은 0605에서 본 adder UVM 구조를 다시 확장해서, clock/reset이 있는 sequential adder를 UVM testbench로 검증하는 흐름으로 정리한다.
핵심은 UVM 개념을 따로 외우는 것이 아니라, `260608_clk_adder_uvm` 소스에서 `object`, `component`, `phase`, `TLM`, `config_db`, `objection`이 실제로 어디에 쓰였는지 연결해서 읽는 것이다.

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | clocked adder DUT와 UVM testbench 구조 |
| 소스 위치 | `helloHDL/260608_clk_adder_uvm` |
| RTL | `rtl/adder.sv` |
| TB | `tb/tb_adder.sv` |
| 이전 연결 | `0601` SystemVerilog OOP, `0605` UVM adder 기본 구조 |
| 핵심 흐름 | `sequence item -> sequencer -> driver -> interface -> DUT -> monitor -> scoreboard` |
| 0605와 차이 | DUT 출력 `y`가 clock에 맞춰 register로 갱신되므로 driver/monitor timing을 맞춰야 한다. |

## 소스 파일 구성

| 파일 | 주요 코드 위치 | 역할 |
| --- | --- | --- |
| `rtl/adder.sv` | 1~15행 | clock/reset이 있는 sequential adder DUT |
| `tb/tb_adder.sv` | 4~11행 | DUT와 UVM component가 공유하는 `adder_if` |
| `tb/tb_adder.sv` | 13~31행 | transaction data인 `adder_seq_item` |
| `tb/tb_adder.sv` | 33~55행 | random item을 생성하는 `adder_sequence` |
| `tb/tb_adder.sv` | 57~111행 | expected/actual을 비교하는 `adder_scoreboard` |
| `tb/tb_adder.sv` | 114~156행 | item을 interface signal로 drive하는 `adder_driver` |
| `tb/tb_adder.sv` | 158~198행 | interface signal을 transaction으로 관찰하는 `adder_monitor` |
| `tb/tb_adder.sv` | 200~228행 | sequencer, driver, monitor를 묶는 `adder_agent` |
| `tb/tb_adder.sv` | 231~257행 | agent와 scoreboard를 묶는 `adder_env` |
| `tb/tb_adder.sv` | 259~301행 | sequence 실행과 objection을 담당하는 `adder_test` |
| `tb/tb_adder.sv` | 303~332행 | clock/reset, interface, DUT, `run_test()`가 있는 top module |

## DUT: clocked adder

이번 DUT는 조합논리 adder가 아니라 clock에 맞춰 `y`를 register에 저장하는 구조다.

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        y <= 0;
    end else begin
        y <= a + b;
    end
end
```

| 신호 | 의미 |
| --- | --- |
| `clk` | `y`가 갱신되는 기준 clock |
| `rst_n` | active-low reset |
| `a`, `b` | 8-bit 입력 operand |
| `y` | 9-bit 출력. `8'hff + 8'hff`까지 담기 위해 9-bit 필요 |

중요한 점은 `a`, `b`가 바뀐 즉시 `y`가 바뀌는 것이 아니라 다음 clock edge에서 `y <= a + b`가 실행된다는 것이다.
따라서 monitor는 driver가 입력을 넣은 직후 바로 `y`를 비교하면 안 되고, clock latency를 고려해서 샘플링해야 한다.

## Interface와 module/class 경계

`adder_if`는 module 영역의 DUT signal과 class 기반 UVM component 사이를 연결하는 경계다.

```systemverilog
interface adder_if (
    input logic clk,
    input logic rst_n
);
    logic [7:0] a;
    logic [7:0] b;
    logic [8:0] y;
endinterface
```

| 위치 | 코드 | 의미 |
| --- | --- | --- |
| top module | `adder_if a_if(clk, rst_n);` | 실제 interface instance 생성 |
| top module | `uvm_config_db#(virtual adder_if)::set(null, "*", "a_if", a_if);` | UVM component가 쓸 virtual interface 등록 |
| driver | `uvm_config_db#(virtual adder_if)::get(this, "", "a_if", a_if)` | driver가 interface handle 획득 |
| monitor | `uvm_config_db#(virtual adder_if)::get(this, "", "a_if", a_if)` | monitor가 interface handle 획득 |

UVM class는 DUT port에 직접 연결되지 않는다.
`uvm_config_db`로 전달받은 `virtual adder_if` handle을 통해 driver와 monitor가 실제 signal에 접근한다.

## Object: `adder_seq_item`

`adder_seq_item`은 UVM component 사이를 이동하는 transaction object다.
Driver가 이 object를 받아 `a_if.a`, `a_if.b`로 변환하고, monitor는 interface에서 읽은 값을 다시 item에 담아 scoreboard로 보낸다.

| field | 방향 | 의미 |
| --- | --- | --- |
| `rand logic [7:0] a` | sequence -> driver | randomize되는 입력 A |
| `rand logic [7:0] b` | sequence -> driver | randomize되는 입력 B |
| `logic [8:0] y` | monitor -> scoreboard | DUT에서 관찰한 출력 |

| 코드 | 의미 |
| --- | --- |
| `extends uvm_sequence_item` | transaction data type으로 사용 |
| `` `uvm_object_utils_begin/end `` | factory 등록과 field automation |
| `` `uvm_field_int(a, UVM_ALL_ON) `` | print, copy, compare 등에 field 포함 |
| `convert2string()` | log에서 `a`, `b`, `y`를 한 줄로 출력 |

## Sequence: random stimulus 생성

`adder_sequence`는 `adder_seq_item`을 10개 생성하고 randomize해서 sequencer로 보낸다.

```text
for loop
-> type_id::create()
-> start_item()
-> randomize()
-> finish_item()
```

| 코드 | 의미 |
| --- | --- |
| `int loop_count` | 생성할 transaction 개수 |
| `item = adder_seq_item::type_id::create(...)` | factory 기반 item 생성 |
| `start_item(item)` | sequencer-driver handshake 시작 |
| `item.randomize()` | `a`, `b` random 값 생성 |
| `finish_item(item)` | driver가 받을 수 있도록 item 전송 완료 |

`adder_test.run_phase`에서 `seq.loop_count = 10`으로 설정하므로, 이번 test는 총 10개 transaction을 수행한다.

## Component 계층

이번 UVM testbench hierarchy는 아래처럼 읽는다.

```text
tb_adder module
├─ adder_if a_if
├─ adder dut
└─ UVM hierarchy
   └─ adder_test
      └─ adder_env
         ├─ adder_agent
         │  ├─ uvm_sequencer #(adder_seq_item) sqr
         │  ├─ adder_driver drv
         │  └─ adder_monitor mon
         └─ adder_scoreboard scb
```

| component | 생성 위치 | 역할 |
| --- | --- | --- |
| `adder_test` | `run_test("adder_test")` | 전체 test scenario 실행 |
| `adder_env` | `adder_test.build_phase` | agent와 scoreboard를 묶음 |
| `adder_agent` | `adder_env.build_phase` | sequencer, driver, monitor를 묶음 |
| `sqr` | `adder_agent.build_phase` | sequence item 공급 |
| `drv` | `adder_agent.build_phase` | interface 입력 구동 |
| `mon` | `adder_agent.build_phase` | interface 출력 관찰 |
| `scb` | `adder_env.build_phase` | 결과 비교와 summary 출력 |

## Phase별 코드 읽기

UVM 코드는 phase 기준으로 나누면 구조가 보인다.

| phase | source 위치 | 하는 일 |
| --- | --- | --- |
| `build_phase` | `adder_test`, `adder_env`, `adder_agent`, `adder_driver`, `adder_monitor` | component 생성, virtual interface 획득 |
| `connect_phase` | `adder_agent`, `adder_env` | sequencer-driver, monitor-scoreboard 연결 |
| `run_phase` | `adder_test`, `adder_driver`, `adder_monitor` | sequence 실행, item drive, signal sampling |
| `report_phase` | `adder_scoreboard`, `adder_test` | pass/fail summary와 topology 출력 |

### build phase

`build_phase`는 부모 component가 자식 component를 만드는 단계다.

| 위치 | 코드 | 의미 |
| --- | --- | --- |
| `adder_test` | `env = adder_env::type_id::create("env", this);` | test 아래 env 생성 |
| `adder_env` | `agt = adder_agent::type_id::create("agt", this);` | env 아래 agent 생성 |
| `adder_env` | `scb = adder_scoreboard::type_id::create("scb", this);` | env 아래 scoreboard 생성 |
| `adder_agent` | `sqr`, `drv`, `mon` 생성 | agent 내부 component 생성 |
| `adder_driver` | `uvm_config_db::get(..., "a_if", a_if)` | virtual interface 획득 |
| `adder_monitor` | `uvm_config_db::get(..., "a_if", a_if)` | virtual interface 획득 |

### connect phase

`connect_phase`는 이미 만들어진 component의 TLM 연결을 묶는 단계다.

| 위치 | 코드 | 의미 |
| --- | --- | --- |
| `adder_agent` | `drv.seq_item_port.connect(sqr.seq_item_export);` | sequencer가 driver에 item 공급 |
| `adder_env` | `agt.mon.ap.connect(scb.ap_imp);` | monitor가 scoreboard에 관찰 item 전달 |

Driver 쪽 연결은 sequence item request/response 흐름이고, monitor 쪽 연결은 analysis TLM broadcast 흐름이다.

### run phase

`run_phase`는 simulation time이 흐르는 task다.
이번 코드에서는 test, driver, monitor가 각각 시간 동작을 가진다.

| 위치 | 핵심 코드 | 의미 |
| --- | --- | --- |
| `adder_test` | `phase.raise_objection(this)` | sequence가 끝날 때까지 run phase 유지 |
| `adder_test` | `seq.start(env.agt.sqr)` | sequence를 agent의 sequencer에서 실행 |
| `adder_driver` | `seq_item_port.get_next_item(item)` | sequencer에서 다음 transaction 수신 |
| `adder_driver` | `drive_item(item)` | item field를 interface signal로 drive |
| `adder_driver` | `seq_item_port.item_done()` | 현재 item 처리 완료 알림 |
| `adder_monitor` | `ap.write(item)` | 관찰한 transaction을 scoreboard로 전달 |
| `adder_test` | `phase.drop_objection(this)` | sequence 완료 후 run phase 종료 허용 |

## Driver와 Monitor timing

이번 예제에서 가장 중요한 부분은 driver와 monitor의 clock timing이다.
DUT가 sequential adder이므로 `a`, `b`를 넣은 뒤 `y`가 바로 맞는 값이 되는 것이 아니다.

### Driver timing

```systemverilog
@(posedge a_if.clk);
a_if.a <= item.a;
a_if.b <= item.b;
@(posedge a_if.clk);
@(posedge a_if.clk);
```

| 순서 | 의미 |
| --- | --- |
| 첫 번째 posedge | transaction의 `a`, `b`를 interface에 구동 |
| 다음 posedge | DUT가 새 `a`, `b`를 보고 `y <= a + b` 갱신 |
| 그 다음 posedge | monitor가 안정된 결과를 볼 수 있도록 여유를 둠 |

### Monitor timing

```systemverilog
@(posedge a_if.clk);
@(posedge a_if.clk);
item.a = a_if.a;
item.b = a_if.b;
@(posedge a_if.clk);
item.y = a_if.y;
ap.write(item);
```

| 순서 | 의미 |
| --- | --- |
| 두 번의 posedge 대기 | driver가 넣은 `a`, `b`가 안정된 뒤 입력값 샘플링 |
| 추가 posedge 대기 | registered output `y`가 갱신될 시간 확보 |
| `ap.write(item)` | `a`, `b`, `y`를 하나의 transaction으로 scoreboard에 전달 |

Nonblocking assignment와 registered output 때문에 sample 시점을 맞추는 것이 중요하다.
조합논리 adder였다면 같은 cycle에서 `y`를 볼 수 있지만, 이번 `adder.sv`는 `always_ff` 구조라 clock latency를 고려해야 한다.

## Scoreboard와 analysis TLM

`adder_monitor`는 `uvm_analysis_port`를 가지고 있고, `adder_scoreboard`는 `uvm_analysis_imp`를 가진다.
`connect_phase`에서 둘을 연결하면 monitor의 `ap.write(item)` 호출이 scoreboard의 `write(item)`으로 들어간다.

| class | TLM 객체 | 역할 |
| --- | --- | --- |
| `adder_monitor` | `uvm_analysis_port #(adder_seq_item) ap` | 관찰 transaction 송신 |
| `adder_scoreboard` | `uvm_analysis_imp #(adder_seq_item, adder_scoreboard) ap_imp` | transaction 수신 후 `write()` 실행 |

Scoreboard의 비교 기준은 단순하다.

```systemverilog
if (item.y === item.a + item.b) pass_count++;
else fail_count++;
```

| 결과 | 처리 |
| --- | --- |
| `item.y === item.a + item.b` | `pass_count++` |
| mismatch | `uvm_error`, `fail_count++` |
| `report_phase` | total/pass/fail과 TEST PASSED/FAILED 출력 |

## Factory와 macro

이번 코드의 모든 UVM class는 factory에 등록된다.

| class | macro | 이유 |
| --- | --- | --- |
| `adder_seq_item` | `` `uvm_object_utils_begin/end `` | field automation까지 포함한 object 등록 |
| `adder_sequence` | `` `uvm_object_utils `` | sequence object 등록 |
| `adder_scoreboard` | `` `uvm_component_utils `` | component factory 등록 |
| `adder_driver` | `` `uvm_component_utils `` | component factory 등록 |
| `adder_monitor` | `` `uvm_component_utils `` | component factory 등록 |
| `adder_agent` | `` `uvm_component_utils `` | component factory 등록 |
| `adder_env` | `` `uvm_component_utils `` | component factory 등록 |
| `adder_test` | `` `uvm_component_utils `` | `run_test("adder_test")`로 생성 가능하게 등록 |

`type_id::create()`와 `run_test("adder_test")`는 factory 등록이 되어 있다는 전제에서 동작한다.
따라서 macro는 단순 반복 코드가 아니라 UVM이 class type을 찾을 수 있게 해 주는 등록 절차다.

## 실행 흐름 정리

```text
tb_adder initial
-> uvm_config_db::set("a_if")
-> run_test("adder_test")
-> factory creates adder_test
-> build_phase creates env/agent/sqr/driver/monitor/scoreboard
-> driver and monitor get virtual interface
-> connect_phase connects driver-sequencer and monitor-scoreboard
-> adder_test.run_phase raises objection
-> adder_sequence creates 10 randomized items
-> driver gets each item and drives a_if.a, a_if.b
-> DUT updates y on clock edge
-> monitor samples a, b, y with registered-output timing
-> monitor ap.write(item)
-> scoreboard write(item) compares y with a + b
-> sequence completes
-> adder_test drops objection
-> scoreboard report_phase prints summary
-> adder_test report_phase prints topology
```

## 실행 명령 메모

Synopsys VCS 환경에서는 아래처럼 실행할 수 있다.

```sh
cd /Users/mumallaeng/git/Vault/activities/korcham/helloHDL/260608_clk_adder_uvm
vcs -full64 -sverilog -debug_access+all -kdb -lca \
  -ntb_opts uvm-1.2 \
  -timescale=1ns/1ps \
  rtl/adder.sv tb/tb_adder.sv \
  -o simv
./simv +UVM_VERBOSITY=UVM_MEDIUM
```

`UVM_HIGH`, `UVM_DEBUG` message가 보이지 않는다면 코드가 실행되지 않은 것이 아니라 verbosity 설정에서 필터링된 것일 수 있다.

## 주의점

| 오해 또는 실수 | 정리 |
| --- | --- |
| `adder_seq_item`이 DUT로 직접 들어간다 | driver가 item을 interface signal로 변환해야 DUT가 본다. |
| `y`는 `a`, `b`를 drive하자마자 바로 비교하면 된다 | 이번 DUT는 `always_ff`라 clock edge 이후 registered output을 샘플링해야 한다. |
| `uvm_config_db` key는 아무 이름이나 써도 된다 | `set()`과 `get()`의 key `"a_if"`가 일치해야 한다. |
| `connect_phase`는 생략해도 된다 | sequencer-driver, monitor-scoreboard TLM 연결이 없으면 item이 흐르지 않는다. |
| `run_phase`는 function으로 작성할 수 있다 | clock wait와 sequence 실행이 있으므로 `task`여야 한다. |
| `phase.drop_objection()`을 빨리 호출해도 상관없다 | 모든 objection이 내려가면 run phase가 끝날 수 있으므로 sequence 완료 후 내려야 한다. |
| log가 적으면 검증이 안 돈 것이다 | verbosity에 따라 `uvm_info` 출력이 숨겨질 수 있다. |

## 핵심 정리

0608의 핵심은 UVM 구조를 실제 source code에 대입해서 읽는 것이다.
`adder_seq_item`은 data object이고, `adder_test/env/agent/driver/monitor/scoreboard`는 component hierarchy다.
`build_phase`는 component 생성과 virtual interface 획득, `connect_phase`는 TLM 연결, `run_phase`는 sequence 실행과 clock 기반 drive/monitor 동작을 담당한다.

이번 `260608_clk_adder_uvm` 예제는 DUT가 clocked adder이므로, driver와 monitor가 clock latency를 고려해야 한다.
즉 UVM 구조 자체뿐 아니라 DUT의 sequential timing을 이해해야 scoreboard 비교가 올바르게 된다.

## 연결 노트

- [[260601-systemverilog-oop]]
- [[260604-linux-vcs-verdi]]
- [[260605-uvm-adder]]
