# 논리회로 실전 예제 01 - counter_10000, tick_counter, clk_tick_gen, FND 흐름

> 분류: Korcham 수업 코드와 프로젝트 구조에 종속된 activity note

목적:
- `counter`, `tick generator`, `wire`, `reg`, `assign`, `top/datapath` 구조를 실제 코드 한 묶음으로 익히기
- `100MHz -> 10Hz tick -> 0~9999 count -> FND 표시` 흐름을 끊기지 않게 이해하기
- 수업 시간에 본 최소형 코드와 실제 프로젝트 확장형 코드의 관계를 같이 정리하기

연결 노트:
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-05-counter-timer-counter-register]]
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-03-combinational-vs-sequential]]
- [[domains/semiconductor/verilog-hdl/study-10-wire-reg-assign-always]]

실제 소스 기준:
- 최소형 구조 이해용: 수업 시간에 본 `counter_10000 / datapath / tick_counter / clk_tick_gen`
- 프로젝트 확장형: `activities/korcham/helloHDL/260408_counter_10000/counter_10000.srcs/sources_1/new/counter_10000.v`
- 공통 모듈: `activities/korcham/helloHDL/260408_counter_10000/counter_10000.srcs/sources_1/new/counter_10000_common.v`
- 이 노트의 코드 스타일 설명도 위 실제 수업 소스를 기준으로 적음

## 이 예제를 한 줄로 요약하면

`clk_tick_gen`이 느린 `tick` pulse를 만들고, `tick_counter`가 그 pulse가 들어올 때만 카운트하고, `fnd_controller`가 그 값을 FND에 보여주는 구조다.

## 왜 이걸 익혀야 하나

| 포인트 | 이 예제에서 보이는 것 |
| --- | --- |
| `top module` | 하위 모듈을 연결만 하는 구조 |
| `datapath` | tick 생성기와 counter를 묶는 데이터 경로 |
| `wire` | 모듈 사이 연결선 |
| `reg` | 클럭 기준으로 값 저장 |
| `assign` | 내부 저장값을 출력선으로 연결 |
| `tick` | 느린 pulse를 만드는 enable 신호 |
| `counter` | tick이 들어올 때만 값 변화 |
| `FND` | 계산 결과를 사람이 보는 출력으로 연결 |

## 전체 구조

### ASCII

```text
clk, rst
   |
   v
counter_10000
   |-------------------------------> fnd_controller ------> fnd_com, fnd_data
   |
   '----> datapath
            |----> clk_tick_gen ----> w_tick_10hz
            '----> tick_counter <----'
                         |
                         '----> w_tick_counter[13:0]
```

### Mermaid

```mermaid
flowchart LR
    CLK[clk]
    RST[rst]
    TOP[counter_10000]
    DP[datapath]
    TG[clk_tick_gen]
    TC[tick_counter]
    FND[fnd_controller]
    OUT1[fnd_com]
    OUT2[fnd_data]
    CNT[w_tick_counter[13:0]]
    TICK[w_tick_10hz]

    CLK --> TOP
    RST --> TOP
    TOP --> DP
    DP --> TG
    TG --> TICK
    TICK --> TC
    TC --> CNT
    CNT --> FND
    TOP --> FND
    FND --> OUT1
    FND --> OUT2
```

## 모듈별 역할

| 모듈 | 역할 | 핵심 |
| --- | --- | --- |
| `counter_10000` | 최상위 연결 | `datapath`와 `fnd_controller` 연결 |
| `datapath` | 내부 동작 묶기 | `clk_tick_gen + tick_counter` 체인 |
| `tick_counter` | 실제 카운트 저장 | `i_tick = 1`일 때만 값 변화 |
| `clk_tick_gen` | tick pulse 생성 | `100MHz`를 `10Hz` pulse로 나눔 |
| `fnd_controller` | 표시 제어 | 14비트 카운트 값을 FND에 표시 |

## 데이터 흐름

| 단계 | 무슨 일이 일어나는가 |
| --- | --- |
| 1 | `clk`가 계속 들어옴 |
| 2 | `clk_tick_gen`이 내부 카운터를 셈 |
| 3 | 목표값에 도달하면 `o_tick = 1`을 한 클럭만 냄 |
| 4 | `tick_counter`는 그 순간에만 `tick_counter_reg`를 바꿈 |
| 5 | `assign o_tick_counter = tick_counter_reg`로 출력선에 연결 |
| 6 | `fnd_controller`가 그 14비트 값을 받아 표시함 |

## 1. top module: counter_10000

이 모듈은 직접 계산을 거의 하지 않는다. 역할은 `연결`이다.

| 코드 요소 | 의미 |
| --- | --- |
| `input clk, rst` | 시스템 클럭과 리셋 |
| `output [3:0] fnd_com` | 자리 선택 |
| `output [7:0] fnd_data` | 세그먼트 데이터 |
| `wire [13:0] w_tick_counter` | 내부 카운트값 연결선 |

핵심은 이 두 줄이다:
- `fnd_controller`는 `w_tick_counter`를 받아 표시
- `datapath`는 `w_tick_counter`를 만들어냄

즉 top module은:

```text
만든다 -> datapath
보여준다 -> fnd_controller
```

## 2. datapath

`datapath`는 이름 그대로 데이터가 흐르는 핵심 경로를 묶은 것이다.

### 구조

```text
clk, rst
-> clk_tick_gen
-> w_tick_10hz
-> tick_counter
-> tick_counter 값 출력
```

### 여기서 중요한 점

- `clk_tick_gen`은 `느린 클럭`을 만드는 게 아니라 `tick pulse`를 만든다
- `tick_counter`는 원래 시스템 `clk`로 동작한다
- 단지 `i_tick`이 `1`일 때만 카운트를 바꾼다

즉:

```text
slow clock 사용
```

이 아니라

```text
fast clock + enable pulse 사용
```

으로 읽는 게 더 정확하다.

## 3. tick_counter

### 핵심 선언

| 코드 | 의미 |
| --- | --- |
| `output [13:0] o_tick_counter` | 외부로 내보낼 14비트 값 |
| `reg [$clog2(10_000)-1:0] tick_counter_reg` | 실제 저장 레지스터 |
| `assign o_tick_counter = tick_counter_reg` | 저장값을 출력선에 연결 |

### 왜 14비트인가

`0 ~ 9999`를 표현해야 한다.

| 값 | 결과 |
| --- | --- |
| `2^13 = 8192` | 부족함 |
| `2^14 = 16384` | 충분함 |

그래서 `14bit`가 필요하다.

### always 블록 해석

```verilog
always @(posedge clk, posedge rst)
```

뜻:
- 평소에는 `clk` 상승엣지마다 동작
- `rst`가 `1`이 되는 순간에도 즉시 리셋

즉 `active-high asynchronous reset`이다.

### 동작 순서

| 조건 | 동작 |
| --- | --- |
| `rst = 1` | `tick_counter_reg <= 0` |
| `i_tick = 0` | 값 유지 |
| `i_tick = 1` | 카운트 값 증가 |
| 현재 값이 `9999` | 다음 값은 `0`으로 복귀 |

### 수업 코드에서 꼭 이해할 점

수업 버전은 대략 이런 흐름이다.

```verilog
tick_counter_reg <= tick_counter_reg + 1;
if (tick_counter_reg == 10_000 - 1) begin
    tick_counter_reg <= 14'd0;
end
```

이건 동작은 맞는다.

이유:
- nonblocking assignment는 같은 클럭에서 여러 번 써도 됨
- 같은 레지스터에 여러 번 쓰면 `나중에 쓴 값`이 최종 적용됨
- 현재 값이 `9999`이면 첫 줄은 `10000`을 예약하고, 둘째 줄이 `0`을 다시 예약해서 최종값은 `0`

다만 가독성은 떨어진다. 실제 프로젝트 버전처럼 아래 형태가 더 명확하다.

```verilog
if (tick_counter_reg == 14'd9999)
    tick_counter_reg <= 14'd0;
else
    tick_counter_reg <= tick_counter_reg + 1'b1;
```

즉:
- 수업 코드는 `원리 이해용`
- 프로젝트 코드는 `실무적으로 더 읽기 쉬운 형태`

## 4. clk_tick_gen

이 모듈의 역할은 `100MHz 시스템 클럭`을 바로 느리게 바꾸는 게 아니라, `10Hz마다 1클럭짜리 pulse`를 만드는 것이다.

### 왜 `10_000_000 - 1`인가

| 항목 | 값 |
| --- | --- |
| 입력 클럭 | `100_000_000 Hz` |
| 원하는 tick | `10 Hz` |
| 필요한 클럭 수 | `100_000_000 / 10 = 10_000_000` |
| 카운트 시작값 | `0` |
| 마지막 비교값 | `10_000_000 - 1` |

즉 `0`부터 세기 때문에 `-1`이 들어간다.

### 왜 `$clog2(...)`를 쓰나

`10_000_000`까지 셀 수 있는 레지스터 폭을 자동으로 구하려는 것이다.

| 식 | 의미 |
| --- | --- |
| `$clog2(10_000_000)` | 10,000,000을 표현하는 데 필요한 최소 비트 수 |
| 결과 | `24` |

그래서 `counter_reg`는 `24bit`면 충분하다.

### 1클럭 pulse가 되는 이유

수업 코드 핵심은 이 줄이다.

```verilog
o_tick <= 1'b0;
```

이 줄을 매 클럭 기본값으로 먼저 깔아두고, 비교가 맞는 순간에만:

```verilog
o_tick <= 1'b1;
```

을 다시 넣는다.

즉 결과는:

| 순간 | `o_tick` |
| --- | --- |
| 평소 | `0` |
| 목표값 도달한 그 클럭 | `1` |
| 다음 클럭 | 다시 `0` |

그래서 `한 클럭짜리 pulse`가 된다.

## 5. `wire`, `reg`, `assign` 관점으로 다시 보기

| 코드 | 종류 | 이유 |
| --- | --- | --- |
| `wire [13:0] w_tick_counter` | `wire` | 모듈 사이 연결선이기 때문 |
| `wire w_tick_10hz` | `wire` | tick pulse 연결선이기 때문 |
| `reg [13:0] tick_counter_reg` | `reg` | always 블록 안에서 저장되기 때문 |
| `reg [23:0] counter_reg` | `reg` | always 블록 안에서 클럭마다 값이 변하기 때문 |
| `output reg o_tick` | `output reg` | 출력이지만 always 블록에서 직접 할당하기 때문 |
| `assign o_tick_counter = tick_counter_reg` | `assign` | 내부 저장값을 출력선에 붙이기 때문 |

핵심 구분:

```text
wire = 연결선
reg  = 저장되는 값
assign = 연속 할당
```

## 6. 수업 최소형과 프로젝트 확장형 차이

| 항목 | 수업 최소형 | 프로젝트 확장형 |
| --- | --- | --- |
| 버튼 입력 | 없음 | `btnL`, `btnR`, `btnD` 있음 |
| debounce | 없음 | `button_debounce` 있음 |
| mode | 단순 증가형 | 증가/감소 모드 있음 |
| clear | 리셋만 | 별도 clear 있음 |
| run/stop | 항상 동작 | 버튼으로 제어 가능 |
| 핵심 본질 | tick 만들기 + count + 표시 | 본질은 같고 제어만 늘어남 |

즉 프로젝트가 커져도 본질은 바뀌지 않는다.

```text
tick 생성
-> counter 동작
-> 표시
```

이 뼈대는 그대로다.

## 7. 이 코드에서 꼭 익혀야 할 설명

| 질문 | 바로 답할 수 있어야 할 것 |
| --- | --- |
| `datapath`는 왜 있나 | tick 생성기와 counter를 묶는 내부 경로이기 때문 |
| `i_tick`은 무엇인가 | 느린 pulse이자 counter enable |
| `o_tick`은 왜 1클럭인가 | 매 클럭 기본 `0`, 비교 성공 시만 `1` |
| `assign o_tick_counter = tick_counter_reg`는 왜 쓰나 | reg 값을 출력 wire에 연결하려고 |
| 왜 `9999`에서 `0`으로 가나 | `0~9999` 범위를 반복하려고 |
| 왜 `10_000_000 - 1`과 비교하나 | `0`부터 세기 때문 |

## 8. 시험장에서 자주 틀리는 점

1. `i_tick`을 별도 느린 클럭으로 오해함
2. `wire`와 `reg`를 기능이 아니라 선언 문법으로만 외움
3. `assign`이 저장이 아니라 연결이라는 점을 놓침
4. `10_000_000 - 1`의 이유를 설명 못함
5. `9999` 다음 값이 왜 `0`인지 범위로 설명 못함
6. 수업 코드의 중복 nonblocking assignment를 이상한 버그로만 보고 원리를 설명 못함

## 9. 손으로 다시 적는 최소 답안 순서

1. top module 포트 적기
2. `wire w_tick_counter`, `wire w_tick_10hz` 적기
3. `datapath` 안에 `clk_tick_gen -> tick_counter` 체인 적기
4. `tick_counter_reg`, `counter_reg` 같은 내부 `reg` 적기
5. `assign o_tick_counter = tick_counter_reg` 적기
6. `if (counter_reg == 10_000_000 - 1)`와 `o_tick <= 1'b1` 적기
7. `if (tick_counter_reg == 9999) tick_counter_reg <= 0` 적기

## 한 줄 요약

이 예제의 핵심은 `빠른 시스템 클럭에서 1클럭짜리 tick pulse를 만들고`, `그 pulse를 enable처럼 써서 counter를 움직이고`, `그 결과를 FND에 연결하는 구조`를 `top -> datapath -> tick generator -> counter -> display` 순서로 읽는 것이다.
