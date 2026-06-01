# 26-06-01 - SystemVerilog OOP와 RAM 검증 구조

SystemVerilog의 `class` 문법은 단순 문법 암기 대상이 아니라, testbench를 구조화하기 위한 도구로 이해하는 것이 핵심이다.
`interface`가 DUT와 연결되는 실제 신호 묶음이라면, `class`는 transaction 생성, DUT 구동, 출력 관찰, 기대값 비교 같은 검증 절차를 나눠 담는 객체다.

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | SystemVerilog OOP, `class`, `virtual interface`, RAM self-checking testbench |
| 이전 연결 | `interface`, `transaction`, `mailbox`, `event` 기반 검증 구조 |
| 핵심 흐름 | 검증을 `generator -> driver -> monitor -> scoreboard` 흐름으로 나눠 읽기 |
| 실습 대상 | `ALU.sv`, `RAM.sv`, `tb_ALU.sv`, `tb_RAM.sv`, RAM assignment testbench |
| 구조 기준 | DUT는 `module`, 검증 로직은 `class`, DUT 연결은 `interface`가 담당 |

## testbench의 범위와 UVM 위치

testbench는 특정 작성 방식 하나를 뜻하지 않는다.
DUT를 검증하기 위해 자극을 넣고 결과를 확인하는 코드 전체를 testbench로 본다.

| 방식 | 의미 |
| --- | --- |
| 순차형 TB | `initial` 블록에서 값을 하나씩 넣고 확인 |
| OOP 기반 TB | `class`, `transaction`, `driver`, `scoreboard` 등으로 검증 역할 분리 |
| UVM 기반 TB | SystemVerilog OOP 위에 만든 검증 framework 사용 |

따라서 UVM을 쓰면 testbench가 되는 것이 아니라, UVM도 testbench를 구성하는 한 방식이다.
UVM을 이해하려면 SystemVerilog의 class, inheritance, polymorphism, transaction 개념을 먼저 알아야 한다.

## RAM을 볼 때 필요한 memory hierarchy 감각

RAM은 CPU가 program과 data를 실제로 올려 두고 접근하는 작업 공간이다.
storage에 있는 data를 바로 연산하는 것이 아니라, 필요한 내용을 memory 계층을 거쳐 가져와 처리한다고 보면 된다.

| 계층 | 특징 |
| --- | --- |
| Cache | CPU 가까이에 있어 빠르지만 용량이 작음 |
| RAM | 실행 중인 program과 data가 올라오는 주 작업 공간 |
| SSD/HDD | 용량은 크지만 CPU가 직접 매 cycle 접근하기에는 느림 |
| Network storage | 물리적으로 더 멀어 latency가 훨씬 커질 수 있음 |

이 차이는 AI/GPU 시스템에서도 중요하다.
연산기가 빨라도 data를 충분히 빠르게 공급하지 못하면 memory bandwidth나 capacity가 병목이 된다.
따라서 hardware를 볼 때는 연산기 성능뿐 아니라 data가 어느 memory 계층에서 오고, 얼마나 자주 이동하는지도 같이 봐야 한다.

## 관련 코드 위치

| 파일 | 의미 |
| --- | --- |
| `Hello/260601_OOP_SV/.../sources_1/new/ALU.sv` | `opcode`에 따라 add/sub를 수행하는 조합회로 DUT |
| `Hello/260601_OOP_SV/.../sim_1/new/tb_ALU.sv` | 가장 단순한 `tester` class와 `virtual interface` 사용 예 |
| `Hello/260601_OOP_SV/.../sources_1/new/RAM.sv` | `we=1`이면 write, `we=0`이면 read하는 256 x 8 RAM DUT |
| `Hello/260601_OOP_SV/.../sim_1/new/tb_RAM.sv` | `transaction`, `tester`, `tester_child`로 상속과 결과 집계 연습 |
| `Hello/260601_OOP_SV/.../sim_1/new/tb_RAM_김연우_260601_OOP_SV_assignment.sv` | generator/driver/monitor/scoreboard/environment로 확장한 RAM 검증 TB |

## C struct와 class의 차이

C의 `struct`는 기본적으로 data field를 묶는 구조다.
반면 C++나 SystemVerilog의 `class`는 data와 동작을 함께 묶을 수 있다.

| 구분 | 담을 수 있는 것 | 검증 코드에서의 의미 |
| --- | --- | --- |
| `struct` | 주로 변수 묶음 | 신호값이나 data field를 단순히 모음 |
| `class` | 변수 + task/function | data와 검증 절차를 같은 객체 안에 둠 |

SystemVerilog testbench에서 class가 유용한 이유는 transaction 값뿐 아니라 `write()`, `read()`, `result()` 같은 절차도 같은 객체 안에 넣을 수 있기 때문이다.

## OOP 개념을 검증 코드 기준으로 보기

| 개념 | SystemVerilog TB에서의 의미 |
| --- | --- |
| 추상화 | 검증에 필요한 값을 `transaction`, `tester`, `scoreboard` 같은 역할 단위로 나눔 |
| 캡슐화 | 관련 변수와 task/function을 하나의 class 안에 묶음 |
| 상속 | `tester_child extends tester`처럼 기본 동작을 물려받고 기능을 추가 |
| 다형성 | 부모 class의 메서드를 자식 class에서 재정의해 결과 출력/집계 방식을 바꿈 |

여기서 중요한 것은 OOP 개념 자체보다 "왜 검증 코드를 이렇게 나누는가"다.
작은 DUT는 `initial` 블록만으로도 확인할 수 있지만, 반복 테스트와 pass/fail 집계가 필요하면 class 기반 구조가 유리하다.

## `interface`와 `class`의 역할 구분

| 항목 | `interface` | `class` |
| --- | --- | --- |
| 본질 | DUT와 TB가 공유하는 실제 신호 묶음 | 검증 데이터와 절차를 담는 객체 |
| 예시 | `clk`, `we`, `addr`, `wdata`, `rdata` | `transaction`, `generator`, `driver`, `scoreboard` |
| DUT 포트 연결 | 가능 | 직접 불가 |
| class 안 접근 방식 | `virtual interface` handle로 접근 | 자기 멤버 변수와 메서드 사용 |

정리하면 `class`는 DUT 핀에 직접 붙지 않는다.
DUT에 값을 넣거나 출력을 읽으려면 class 안에서 `virtual ram_intf ram_vif`처럼 interface handle을 들고 있어야 한다.

## class handle과 `new()`

class 변수를 선언하는 것과 실제 객체가 만들어지는 것은 다르다.
`tester iu;`처럼 선언하면 class handle만 생기고, `iu = new(ram_if);`를 호출해야 object instance가 만들어진다.

| 단계 | 의미 |
| --- | --- |
| handle 선언 | 객체를 가리킬 이름만 준비 |
| `new()` 호출 | 실제 object instance 생성 |
| constructor 실행 | interface handle, transaction 같은 내부 멤버 초기화 |

따라서 class 기반 TB를 읽을 때는 handle 선언, `new()` 생성, constructor 초기화를 구분해서 봐야 한다.
객체가 만들어진 뒤에야 `iu.test_run(1000)`처럼 그 객체의 task/function을 호출할 수 있다.

## ALU 예제에서 보는 가장 작은 OOP TB

`tb_ALU.sv`는 `tester` class가 `alu_intf`를 받아서 DUT 입력을 바꾸는 가장 단순한 형태다.

| 구성 | 역할 |
| --- | --- |
| `alu_intf` | `opcode`, `A`, `B`, `result` 신호 묶음 |
| `tester` | `add_test()`, `sub_test()` task로 DUT 입력 구동 |
| `BTS`, `BlackPink` | 같은 class에서 만든 서로 다른 객체 instance |

이 예제의 포인트는 class 변수 자체가 DUT 신호가 아니라는 점이다.
`tester` 객체가 `virtual interface`를 통해 `alu_if.A`, `alu_if.B`, `alu_if.opcode`를 바꾸기 때문에 DUT 입력이 변한다.

## RAM 기본 예제에서 보는 상속과 재정의

`tb_RAM.sv`는 RAM read/write를 하나의 `tester` class로 묶고, `tester_child`에서 결과 집계 기능을 확장한다.

| class | 역할 |
| --- | --- |
| `transaction` | 한 번의 RAM 접근에 필요한 `addr`, `wdata`, `rdata`를 묶음 |
| `tester` | `write()`, `read()`, `result()`, 반복 테스트 흐름을 담당 |
| `tester_child` | `result()`를 재정의하고 `pass`, `fail`, `report()`를 추가 |

상속을 쓰는 이유는 기존 read/write 절차를 다시 쓰지 않고, 결과 처리 방식만 바꾸기 위해서다.
즉 `extends`는 코드 재사용이고, `virtual`/override는 동작의 일부를 바꿀 수 있게 하는 장치다.

## `virtual` 키워드를 두 문맥으로 구분하기

`virtual`은 같은 키워드지만 두 문맥에서 다르게 읽어야 한다.
`virtual function`이나 `virtual task`는 child class가 method를 재정의할 수 있게 하는 OOP 문맥이다.
반면 `virtual ram_intf`는 class 안에서 실제 interface instance를 가리키는 handle이다.

RAM 검증 예제에서는 `tester_child`의 `result()`, `report()`, `test_run()` 재정의가 method override 쪽이고, `tester`, `driver`, `monitor`가 들고 있는 `virtual ram_intf`는 DUT 신호 접근용이다.

## `task`와 `function` 선택 기준

`task`와 `function`은 시간 제어가 필요한지로 먼저 구분한다.
simulation time을 소비하는 동작이 있으면 `task`로 작성해야 한다.

| 구분 | 사용 기준 | 예 |
| --- | --- | --- |
| `task` | `@(posedge clk)`, `wait`, `#10` 같은 시간 제어가 필요함 | `write()`, `read()`, `test_run()` |
| `function` | 이미 얻은 값으로 즉시 계산하거나 판단함 | `result()`, `report()` |

이번 RAM TB에서 `write()`와 `read()`는 clock edge를 기다리므로 task가 맞다.
반대로 `result()`는 `wdata`와 `rdata`를 비교해 pass/fail을 판단할 뿐이므로 function으로 둘 수 있다.

## RAM assignment TB의 검증 흐름

assignment testbench는 단일 `tester`보다 한 단계 더 구조화되어 있다.

```text
generator
-> transaction
-> gen2drv_mbox
-> driver
-> virtual interface
-> interface
-> RAM DUT
-> monitor
-> mon2scb_mbox
-> scoreboard
```

| 블록 | 역할 |
| --- | --- |
| `generator` | `randomize()`로 주소와 write data를 만들고 mailbox에 넣음 |
| `driver` | transaction을 받아 RAM에 write/read 자극을 실제 신호로 인가 |
| `monitor` | interface 신호를 읽어 관측 transaction으로 다시 묶음 |
| `scoreboard` | `ref_mem[addr]`를 기대값 모델로 유지하고 실제 `rdata`와 비교 |
| `environment` | mailbox, event, 각 component를 생성하고 전체 실행/종료 조건 관리 |

이 구조에서는 DUT 안팎을 오가는 것은 실제 신호이고, class 사이를 오가는 것은 transaction이다.
`mailbox`는 transaction 전달 통로이고, `event`는 다음 transaction으로 넘어갈 타이밍을 맞추는 동기화 신호다.

## RAM scoreboard가 기억해야 하는 것

RAM은 조합 ALU처럼 현재 입력만으로 정답을 계산할 수 없다.
이전에 어떤 주소에 어떤 값을 썼는지 기억해야 하므로 scoreboard 안에 reference memory가 필요하다.

| DUT 종류 | 기대값 모델 |
| --- | --- |
| ALU | 입력 `A`, `B`, `opcode`로 바로 계산 |
| Register | 직전 clock의 입력값을 한 변수로 저장 |
| RAM | 주소별 저장값을 `ref_mem[0:255]`로 유지 |
| FIFO | 순서를 보존하는 queue 모델 필요 |

RAM 검증 구조의 핵심은 write transaction에서 `ref_mem[addr] = wdata`를 갱신하고, read transaction에서 `rdata == ref_mem[addr]`인지 비교하는 것이다.

## 실행 결과 기준

RAM assignment TB는 `tb_RAM` top으로 실행한다.
실행 결과는 아래 기준을 만족했다.

| 항목 | 결과 |
| --- | --- |
| compile | `XVLOG_EXIT_CODE: 0` |
| elaborate | `XELAB_EXIT_CODE: 0` |
| simulation | `XSIM_EXIT_CODE: 0` |
| total test | `1000` |
| pass count | `1000` |
| fail count | `0` |

## 주의점

| 오해 | 정리 |
| --- | --- |
| `class`가 DUT를 대신한다 | DUT는 여전히 `module`이고 class는 검증용 구조다 |
| `transaction`이 DUT 안으로 들어간다 | DUT는 transaction을 모르고 interface 신호만 본다 |
| random만 많이 돌리면 검증이 끝난다 | 기대값 모델, 샘플링 시점, pass/fail 집계가 같이 맞아야 한다 |
| `mailbox`는 신호선이다 | mailbox는 class 객체 사이의 transaction 전달 통로다 |

## 핵심 정리

SystemVerilog OOP 검증은 DUT를 객체로 만드는 것이 아니라, DUT를 둘러싼 자극 생성, 구동, 관찰, 비교 절차를 class로 나누고 `virtual interface`를 통해 실제 신호 세계와 연결하는 구조다.

## 연결 노트

- [[260507-systemverilog-검증입문]]
- [[260512-systemverilog-fifo-검증]]
- [[260406-260529-복습노트-04-systemverilog-검증-접근법]]
