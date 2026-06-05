# 26-06-05 - UVM 입문과 adder 검증 구조

UVM은 SystemVerilog OOP 위에 만든 검증 framework다.
`class`, `extends`, `virtual`, override, transaction 개념을 사용해 testbench를 계층적으로 만들고, stimulus 생성부터 DUT 구동, 출력 관찰, 결과 비교까지 정해진 component 구조 안에 배치한다.

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | UVM 기본 구조, phase, factory, objection, adder UVM testbench |
| 이전 연결 | `0601`의 SystemVerilog OOP, `0604`의 Linux CLI/VCS 실행 환경 |
| 핵심 흐름 | `run_test -> test -> env -> agent -> sequencer/driver/monitor -> scoreboard` |
| 실습 대상 | `260605_helloUVM/helloUVM.sv`, `260605_helloUVM/tb_weapon.sv`, `260605_adder_uvm_test/tb/tb_adder.sv` |
| 구조 기준 | DUT 연결은 `interface`, 검증 절차는 UVM component, 데이터 전달은 transaction이 담당 |

## 실습 환경 설정

UVM 실습은 원격 Linux 서버에서 VCS와 Verdi를 실행하는 흐름이다.
VS Code Remote-SSH로 서버에 접속하면 local editor처럼 파일을 열 수 있고, compile/simulation은 remote terminal에서 실행한다.

### shell 진입 설정

서버 기본 shell이 `csh` 계열이면 VS Code terminal이나 script 실행이 불편할 수 있다.
interactive shell에서 bash login shell로 넘기려면 `.cshrc`에 아래처럼 둔다.

```shell
# .cshrc
if ( $?prompt ) exec /bin/bash --login
```

`$?prompt` 조건은 interactive shell인지 확인한다.
이 조건 없이 무조건 `exec`를 걸면 비대화형 명령이나 일부 remote 동작까지 영향을 받을 수 있다.

### VCS 환경 변수

`vcs`, `verdi` 같은 Synopsys tool은 실행 파일 경로와 license server 설정이 필요하다.
실습 계정의 `.bashrc`에는 아래 값들을 둔다.

```shell
# .bashrc
export VCS_HOME=/tools/synopsys/vcs/W-2024.09-SP2
export PATH=$VCS_HOME/bin:$PATH
export LM_LICENSE_FILE=27020@kccipangyo1:27020@61.108.38.195
export SNPSLMD_LICENSE_FILE=27020@kccipangyo1:27020@61.108.38.195
```

설정 후 새 terminal을 열거나 `source ~/.bashrc`로 다시 읽는다.
`which vcs`로 실행 파일이 잡히는지, license 관련 error 없이 compile이 시작되는지 확인한다.

## VCS에서 UVM compile

UVM 코드는 일반 SystemVerilog compile option에 UVM library option이 추가된다.

```shell
vcs -full64 -sverilog -debug_access+all -kdb -lca \
  -ntb_opts uvm-1.2 \
  -timescale=1ns/1ps \
  rtl/adder.sv tb/tb_adder.sv \
  -o simv
```

| option | 의미 |
| --- | --- |
| `-full64` | 64-bit mode 사용 |
| `-sverilog` | SystemVerilog 문법 활성화 |
| `-debug_access+all` | debug 접근 정보 생성 |
| `-kdb` | Verdi 연동용 debug database 생성 |
| `-lca` | Synopsys 일부 feature 사용 조건 |
| `-ntb_opts uvm-1.2` | UVM 1.2 library 사용 |
| `-timescale=1ns/1ps` | simulation time unit/precision 지정 |
| `-o simv` | simulation 실행 파일 이름 지정 |

simulation은 compile 결과인 `simv`를 실행한다.

```shell
./simv
```

FSDB dump가 생성되면 Verdi에서 waveform을 연다.

```shell
verdi -dbdir ./simv.daidir -ssf wave.fsdb
```

## UVM을 보기 전에 필요한 OOP 개념

UVM component는 대부분 이미 정의된 UVM base class를 상속받아 만든다.
사용자는 base class 전체를 새로 만들지 않고, 필요한 method를 재정의해 원하는 검증 동작을 끼워 넣는다.

| OOP 개념 | UVM에서의 의미 |
| --- | --- |
| inheritance | `uvm_test`, `uvm_driver`, `uvm_monitor` 같은 base class를 상속 |
| override | base class에 정의된 phase method를 자식 class에서 재정의 |
| polymorphism | UVM framework가 base class handle로 실제 자식 component 동작을 호출 |
| virtual method | 부모 handle을 통해 자식의 재정의된 method가 실행되게 함 |
| constructor | `new()`에서 component 이름과 parent 계층 정보를 초기화 |

SystemVerilog에서 부모 class handle이 자식 object를 가리킬 수 있어도, method가 동적으로 선택되려면 부모 쪽 method가 `virtual`이어야 한다.
UVM phase method들은 UVM base class에서 virtual method로 정의되어 있으므로, 사용자는 같은 signature로 `build_phase`, `connect_phase`, `run_phase`, `report_phase`를 재정의한다.

## 다형성 예제로 보는 override

`tb_weapon.sv`는 UVM 전에 다형성을 확인하는 작은 예제다.
부모 class인 `weapon` handle이 `M16`, `AUG`, `K2` object를 차례로 가리키고, 같은 `shot()` 호출이 실제 object에 맞는 동작으로 바뀐다.

| 요소 | 의미 |
| --- | --- |
| `class weapon` | 공통 부모 class |
| `virtual function void shot()` | 자식 class가 재정의할 수 있는 method |
| `class M16 extends weapon` | `weapon`을 상속한 자식 class |
| `weapon BlackPink` | 부모 type handle |
| `BlackPink = m16` | 부모 handle이 자식 object를 가리킴 |

핵심은 "같은 interface로 호출하지만 실제 동작은 object 종류에 따라 달라진다"는 점이다.
UVM도 이 원리를 이용한다.
UVM framework는 `uvm_test` 같은 부모 type 기준으로 phase를 호출하지만, 실제 실행되는 내용은 사용자가 만든 `hello_test`, `adder_test`의 override method다.

## Hello UVM 예제 구조

`helloUVM.sv`는 가장 작은 UVM test 흐름을 보여 준다.

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;

class hello_test extends uvm_test;
    `uvm_component_utils(hello_test)

    function new(string name = "hello_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("BUILD_PHASE", "[1] build_phase run.", UVM_LOW);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("HELLO", "첫 번째 UVM 프로그램이 실행되었습니다.!", UVM_LOW);
        phase.drop_objection(this);
    endtask
endclass
```

| 코드 | 의미 |
| --- | --- |
| `` `include "uvm_macros.svh" `` | UVM macro 정의 포함 |
| `import uvm_pkg::*;` | UVM class와 utility를 현재 scope에서 사용 |
| `class hello_test extends uvm_test` | UVM test base class를 상속 |
| `` `uvm_component_utils(hello_test) `` | UVM factory에 component type 등록 |
| `super.new(name, parent)` | UVM component 계층 이름과 parent 초기화 |
| `run_test("hello_test")` | 등록된 test를 factory에서 생성하고 UVM phase 실행 시작 |

module 쪽에서는 직접 `hello_test` object를 `new()`로 만들지 않고 `run_test("hello_test")`를 호출한다.
UVM은 factory에 등록된 이름을 찾아 test object를 만들고, 정해진 phase 순서대로 method를 실행한다.

## UVM phase

UVM simulation은 component마다 같은 lifecycle phase를 따라간다.
phase를 맞춰 두면 test, env, agent, driver, monitor, scoreboard가 같은 구조적 순서로 생성되고 연결된다.

| phase | type | 역할 |
| --- | --- | --- |
| `build_phase` | `function` | component 생성, config 획득, 내부 object 준비 |
| `connect_phase` | `function` | TLM port/export 연결, sequencer-driver 연결 |
| `run_phase` | `task` | 실제 stimulus, drive, monitor 동작 수행 |
| `report_phase` | `function` | simulation 결과와 summary 출력 |

`build_phase`, `connect_phase`, `report_phase`는 simulation time을 소비하지 않으므로 `function`이다.
`run_phase`는 `#10`, `forever`, sequence 실행처럼 시간이 흐르는 동작이 들어가므로 `task`다.

## objection

`run_phase`는 시간이 흐르는 phase라서 언제 simulation을 끝낼지 정해야 한다.
UVM에서는 objection count로 run phase 유지 여부를 판단한다.

| 호출 | 의미 |
| --- | --- |
| `phase.raise_objection(this)` | 현재 component가 아직 실행할 일이 있으므로 run phase를 유지 |
| `phase.drop_objection(this)` | 현재 component의 실행 일이 끝났음을 알림 |

모든 objection이 내려가면 UVM은 run phase를 종료하고 다음 phase로 넘어갈 수 있다.
sequence를 시작하거나 일정 시간 stimulus를 넣는 test는 시작 전에 objection을 올리고, 필요한 동작이 끝난 뒤 objection을 내려야 한다.

## factory 등록과 생성

UVM factory는 class type을 이름과 함께 등록해 두고, 필요할 때 object/component를 생성하는 구조다.
이 구조 덕분에 testbench 상위 구조를 크게 바꾸지 않고도 특정 component type을 다른 구현으로 교체할 수 있다.

| 대상 | 등록 macro | 생성 형태 |
| --- | --- | --- |
| `uvm_component` 계열 | `` `uvm_component_utils(class_name) `` | `class_name::type_id::create("NAME", parent)` |
| `uvm_object` 계열 | `` `uvm_object_utils(class_name) `` | `class_name::type_id::create("NAME")` |
| field 자동화 포함 object | `` `uvm_object_utils_begin/end `` | field print/copy/compare/pack 등 utility 등록 |

`uvm_component_utils`에는 실제 class 이름을 정확히 넣어야 한다.
`run_test("hello_test")`처럼 문자열로 test를 실행하는 것도 factory 등록이 되어 있어야 가능하다.

## UVM testbench 계층

UVM adder 예제의 큰 구조는 아래처럼 읽는다.

```text
tb_adder module
├─ adder_intf
├─ adder DUT
└─ UVM test hierarchy
   └─ adder_test
      └─ adder_env
         ├─ adder_agent
         │  ├─ uvm_sequencer #(adder_seq_item)
         │  ├─ adder_drv
         │  └─ adder_mon
         └─ adder_scb
```

| component | base class | 역할 |
| --- | --- | --- |
| `adder_test` | `uvm_test` | sequence와 env를 만들고 test scenario 실행 |
| `adder_env` | `uvm_env` | agent와 scoreboard를 묶는 상위 검증 환경 |
| `adder_agent` | `uvm_agent` | sequencer, driver, monitor를 한 interface 단위로 묶음 |
| `uvm_sequencer #(adder_seq_item)` | `uvm_sequencer` | sequence item을 driver에 공급 |
| `adder_drv` | `uvm_driver #(adder_seq_item)` | transaction을 interface 신호로 변환해 DUT 구동 |
| `adder_mon` | `uvm_monitor` | interface 신호를 관찰해 transaction으로 변환 |
| `adder_scb` | `uvm_scoreboard` | 관측 transaction을 기대값과 비교 |

module 영역에는 실제 DUT와 interface instance가 있다.
UVM class 영역은 DUT 포트에 직접 연결되지 않으므로 `virtual interface` handle을 통해 module의 interface instance에 접근한다.

## transaction과 sequence item

`adder_seq_item`은 adder 검증에서 한 번 전달할 data 묶음이다.

```systemverilog
class adder_seq_item extends uvm_sequence_item;
    rand logic [7:0] a;
    rand logic [7:0] b;
    logic [8:0] y;
endclass
```

| field | 의미 |
| --- | --- |
| `a`, `b` | DUT에 넣을 random 입력 |
| `y` | DUT 출력 또는 monitor가 관찰한 결과 |
| `rand` | sequence에서 randomize 대상 |

`uvm_object_utils_begin/end`와 `uvm_field_int`를 쓰면 item의 field가 UVM utility에 등록된다.
print, copy, compare, pack 같은 기능을 일관되게 사용할 수 있고, log/debug에서도 transaction 내용을 다루기 쉬워진다.

## sequence와 sequencer

`adder_seq`는 `adder_seq_item`을 만들어 driver로 보낼 stimulus 흐름을 정의한다.

```systemverilog
virtual task body();
    a_seq_item = adder_seq_item::type_id::create("SEQ_ITEM");

    repeat (100) begin
        start_item(a_seq_item);
        if (!a_seq_item.randomize()) begin
            `uvm_error("SEQ_ITEM", "Fail to generate random value!");
        end
        finish_item(a_seq_item);
    end
endtask
```

| 동작 | 의미 |
| --- | --- |
| `type_id::create` | factory를 통해 sequence item 생성 |
| `start_item` | sequencer-driver handshake 시작 |
| `randomize()` | `rand` field 값 생성 |
| `finish_item` | item 준비 완료, driver가 가져갈 수 있게 함 |

sequence는 transaction을 만드는 쪽이고, sequencer는 그 transaction을 driver에게 중계하는 쪽이다.
driver는 sequencer의 export와 연결된 port를 통해 item을 받는다.

## driver와 monitor

driver는 transaction을 실제 DUT 입력 신호로 바꾼다.

```systemverilog
seq_item_port.get_next_item(a_seq_item);
adder_if.a <= a_seq_item.a;
adder_if.b <= a_seq_item.b;
#10;
seq_item_port.item_done();
```

| driver 동작 | 의미 |
| --- | --- |
| `get_next_item` | sequencer에서 다음 transaction 수신 |
| `adder_if.a <= ...` | virtual interface를 통해 DUT 입력 구동 |
| `#10` | DUT 출력이 반영될 시간을 둠 |
| `item_done` | 현재 item 처리 완료를 sequencer에 알림 |

monitor는 interface 신호를 관찰해 다시 transaction으로 묶는다.
driver는 "넣는 쪽", monitor는 "관찰하는 쪽"이다.
driver가 보낸 값만 믿지 않고 실제 interface에서 관찰한 값을 scoreboard로 보내야 DUT 출력 검증이 가능하다.

## TLM 연결과 scoreboard

UVM component 사이의 transaction 전달에는 TLM port/export/imp가 쓰인다.
adder 예제에서는 monitor가 analysis port로 transaction을 보내고, scoreboard가 analysis imp로 받는다.

```systemverilog
a_agt.a_mon.send.connect(a_scb.recv);
```

| 연결 | 의미 |
| --- | --- |
| `uvm_analysis_port #(adder_seq_item) send` | monitor가 transaction을 broadcast하는 port |
| `uvm_analysis_imp #(adder_seq_item, adder_scb) recv` | scoreboard가 transaction을 받는 imp |
| `send.write(a_seq_item)` | monitor가 관찰 결과를 scoreboard로 전달 |
| `write(adder_seq_item data)` | scoreboard의 수신 method |

scoreboard는 받은 transaction에서 `a + b == y`인지 비교한다.
검증의 핵심은 DUT 출력이 기대 모델과 일치하는지 자동으로 판정하는 것이다.

## virtual interface와 config_db

class는 module instance나 interface instance에 직접 포트 연결될 수 없다.
module에서 만든 `adder_intf adder_if()`를 UVM component가 사용하려면 `virtual interface` handle을 넘겨야 한다.

```systemverilog
uvm_config_db#(virtual adder_intf)::set(null, "*", "adder_if", adder_if);
```

driver와 monitor는 build phase에서 같은 이름으로 interface를 가져온다.

```systemverilog
if (!uvm_config_db#(virtual adder_intf)::get(this, "", "adder_if", adder_if)) begin
    `uvm_fatal(get_name(), "Unable to access adder interface.")
end
```

| 항목 | 의미 |
| --- | --- |
| `set` | module 쪽 실제 interface instance를 UVM config database에 저장 |
| `get` | component 쪽에서 virtual interface handle로 꺼냄 |
| `"adder_if"` | set/get이 일치해야 하는 key |
| `uvm_fatal` | interface를 못 받으면 simulation을 계속할 수 없으므로 즉시 중단 |

이 구조를 이해하면 UVM class와 실제 DUT 신호가 어디서 만나는지 볼 수 있다.
driver와 monitor가 `adder_if`를 통해 접근하는 순간 class 기반 검증 로직이 hardware signal과 연결된다.

## component 생성과 연결 순서

UVM component는 phase 안에서 생성하고 연결한다.

| 위치 | 생성/연결 |
| --- | --- |
| `adder_test.build_phase` | `adder_seq`, `adder_env` 생성 |
| `adder_env.build_phase` | `adder_agent`, `adder_scb` 생성 |
| `adder_agent.build_phase` | `adder_mon`, `adder_drv`, `a_sqr` 생성 |
| `adder_agent.connect_phase` | `a_drv.seq_item_port`와 `a_sqr.seq_item_export` 연결 |
| `adder_env.connect_phase` | `a_mon.send`와 `a_scb.recv` 연결 |
| `adder_test.run_phase` | objection을 올리고 sequence를 sequencer에서 실행 |

구조는 build phase에서 만들고, 통신 경로는 connect phase에서 묶고, 실제 transaction 흐름은 run phase에서 시작한다.
이 세 단계를 섞지 않고 읽으면 UVM 코드가 훨씬 덜 복잡해진다.

## UVM message와 report

UVM은 logging macro로 message를 남긴다.

| macro | 용도 |
| --- | --- |
| `` `uvm_info(ID, MSG, VERBOSITY) `` | 정상 진행 상황 출력 |
| `` `uvm_warning(ID, MSG) `` | 경고 출력 |
| `` `uvm_error(ID, MSG) `` | 오류 출력, simulation은 계속 가능 |
| `` `uvm_fatal(ID, MSG) `` | 치명 오류 출력 후 simulation 중단 |

simulation이 끝나면 `UVM Report Summary`에서 severity별 발생 횟수를 확인한다.
`ERROR`, `FATAL` count가 0인지 먼저 보고, 실패가 있으면 해당 ID와 message를 기준으로 source와 waveform을 추적한다.

## 실습 코드 위치

| 파일 | 의미 |
| --- | --- |
| `helloHDL/260605_helloUVM/tb_weapon.sv` | OOP 다형성, `virtual function`, override 감각 확인 |
| `helloHDL/260605_helloUVM/helloUVM.sv` | `uvm_test`, factory 등록, phase, objection 최소 예제 |
| `helloHDL/260605_adder_uvm_test/rtl/adder.sv` | 검증 대상 adder DUT |
| `helloHDL/260605_adder_uvm_test/tb/tb_adder.sv` | sequence item, sequence, driver, monitor, scoreboard, env, test 전체 구조 |

## UVM 흐름 한 줄 정리

```text
run_test("adder_test")
-> factory creates adder_test
-> build_phase creates env/agent/driver/monitor/scoreboard
-> connect_phase connects sequencer-driver and monitor-scoreboard
-> run_phase starts sequence on sequencer
-> sequence creates randomized seq_item
-> driver drives interface
-> DUT computes output
-> monitor samples interface
-> scoreboard compares expected and actual result
-> objection drops
-> report summary
```

## 주의점

| 오해 | 정리 |
| --- | --- |
| UVM은 새로운 HDL이다 | SystemVerilog OOP 기반 검증 framework다 |
| `run_test()`가 단순 function call처럼 test code를 직접 실행한다 | factory로 test를 생성하고 UVM phase scheduler를 시작한다 |
| `` `uvm_component_utils ``는 장식용 macro다 | factory 등록을 위한 필수 macro로 봐야 한다 |
| phase method 이름은 임의로 정한다 | UVM base class에 정의된 phase 이름과 signature를 맞춰 override한다 |
| `raise_objection` 없이도 run phase가 충분히 유지된다 | objection이 없으면 run phase가 너무 빨리 끝나 sequence가 수행되지 않을 수 있다 |
| driver와 monitor는 같은 역할이다 | driver는 DUT 입력을 구동하고, monitor는 실제 interface 신호를 관찰한다 |
| scoreboard는 log만 출력한다 | 기대 모델과 관찰 결과를 비교해 pass/fail을 판단한다 |
| UVM class가 DUT 포트에 직접 연결된다 | `virtual interface`와 `uvm_config_db`를 통해 module의 interface instance를 받아 접근한다 |

## 핵심 정리

UVM은 검증 코드를 역할별 component로 나누고, 정해진 phase에 따라 생성, 연결, 실행하게 만든다.
OOP의 override와 다형성 덕분에 UVM framework는 공통 phase 흐름을 유지하면서도 사용자가 만든 `test`, `env`, `agent`, `driver`, `monitor`, `scoreboard` 동작을 실행할 수 있다.
adder 예제는 sequence가 만든 random transaction이 driver를 통해 DUT 입력으로 들어가고, monitor가 관찰한 결과가 scoreboard에서 자동 비교되는 가장 기본적인 UVM 검증 흐름이다.

## 연결 노트

- [[260601-systemverilog-oop]]
- [[260604-linux-vcs-verdi]]
