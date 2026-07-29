# 논리회로 시험 대비 05 - Counter/Timer와 Counter Register

> 분류: 2026-04-06부터 2026-05-29까지의 Korcham 수업·시험 범위에 종속된 activity note

범위
- `register`
- `counter`
- `counter/timer` 지정형 구현
- `timer / tick generator`

연결 노트:
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-00-core-minimum-summary]]
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-02-gate-to-combinational-logic-bridge]]
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-04-logic-circuit-to-verilog-curriculum]]
- [[domains/semiconductor/verilog-hdl/study-10-wire-reg-assign-always]]
- [[domains/semiconductor/verilog-hdl/study-11-latch-flip-flop-vivado-checks]]

## 목표

이 노트의 목표는 시험에 바로 나올 수 있는 아래 구조를 고정하는 것이다.

- 입력: `clk`, `reset_n`, `load`, `data_in[7:0]`, `en`
- 상태: `count_reg[7:0]`
- 동작: `00h` reset -> `03h` load -> `03 -> 02 -> 01 -> 00` decrement
- 출력: `done`
- 확장: `target_reg`가 가리키는 값만큼 세고 `tick` pulse를 만들기

즉 `counter/timer`를 `register + arithmetic logic + comparator + select logic`으로 읽는 것이 핵심이다.

---

## 1. register와 counter를 먼저 짧게 고정

### register

`register`는 값을 저장하는 블록이다.

```text
d -> register -> q
     ^
     clk
```

```verilog
always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        q <= 8'h00;
    else
        q <= d;
end
```

### counter

`counter`는 저장값을 클럭마다 규칙적으로 바꾸는 register다.

```text
count_reg -> next_count 계산 -> count_reg
```

증가 카운터든 감소 카운터든 본질은 같다.

---

## 2. 이번 시험 지정형 1: Counter Register 감소형

### 입력과 출력

| 신호 | 의미 |
| --- | --- |
| `clk` | 시스템 클럭 |
| `reset_n` | active-low reset |
| `load` | 외부 데이터 로드 |
| `data_in[7:0]` | 로드할 8비트 값 |
| `en` | 카운트 진행 enable |
| `count_reg[7:0]` | 현재 카운터 값 |
| `done` | 카운트 완료 신호 |

### 요구 동작

1. `reset_n = 0`이면 `count_reg = 8'h00`
2. `load = 1`이면 `data_in`을 `count_reg`에 저장
3. `en = 1`이면 `count_reg`를 1씩 감소
4. `03h`를 로드했다면 `03 -> 02 -> 01 -> 00`
5. `00h`에 도달하면 `done` 발생

---

## 3. 회로적으로 분해하면 무엇이 있는가

1. `count_reg`: 현재 값 저장 register
2. `count_reg - 1`: 감소 계산기
3. `count_reg == 0` 또는 `count_reg == 1`: 종료 판단 비교기
4. `reset / load / decrement / hold` 중 무엇을 쓸지 고르는 선택 로직

즉 아래처럼 읽는다.

```text
count_reg
-> decrement logic
-> next_count
-> count_reg

count_reg
-> compare
-> done
```

핵심은 `counter/timer = register + arithmetic block + comparator + mux`라는 점이다.

---

## 4. `done` 신호는 어떻게 해석하나

시험에서 먼저 정할 것은 `done`이 `pulse`인지 `level`인지다.

### 더 안전한 기본 해석: 1클럭 pulse

- `01 -> 00`으로 내려가는 그 클럭에서만 `done = 1`
- 다음 클럭에는 다시 `done = 0`

### 다른 가능성: level signal

- `count_reg == 8'h00`인 동안 계속 `done = 1`

답안에서는 `pulse`로 먼저 설명하고, 필요하면 `level`도 가능하다고 덧붙이는 편이 안전하다.

---

## 5. 감소형 최소 Verilog 골격

```verilog
module counter_register_down (
    input  wire       clk,
    input  wire       reset_n,
    input  wire       load,
    input  wire       en,
    input  wire [7:0] data_in,
    output reg  [7:0] count_reg,
    output reg        done
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            count_reg <= 8'h00;
            done      <= 1'b0;
        end else if (load) begin
            count_reg <= data_in;
            done      <= 1'b0;
        end else if (en) begin
            if (count_reg > 8'h00) begin
                count_reg <= count_reg - 8'h01;
                done      <= (count_reg == 8'h01);
            end else begin
                count_reg <= 8'h00;
                done      <= 1'b0;
            end
        end else begin
            done <= 1'b0;
        end
    end
endmodule
```

핵심 두 줄:

- `count_reg <= count_reg - 8'h01;`
- `done <= (count_reg == 8'h01);`

현재 값이 `01h`일 때 다음 값이 `00h`가 되므로, 그 순간 완료 pulse를 만든다.

---

## 6. 예시 추적: `03h` 로드 후 감소

| 단계 | 조건 | `count_reg` | `done` |
| --- | --- | --- | --- |
| reset | `reset_n = 0` | `00h` | `0` |
| load | `load = 1`, `data_in = 03h` | `03h` | `0` |
| dec 1 | `en = 1` | `02h` | `0` |
| dec 2 | `en = 1` | `01h` | `0` |
| dec 3 | `en = 1` | `00h` | `1` |
| next | 다음 클럭 | `00h` | `0` |

---

## 7. 이번 시험 지정형 2: Timer / Tick Generator

사용자가 말한 문장:

`레지스터가 가리키는 값만큼 카운터해서 tick 신호 발생`

이 말은 보통 아래 구조를 뜻한다.

### 핵심 구성

| 블록 | 역할 |
| --- | --- |
| `target_reg` | 몇 클럭을 셀지 저장 |
| `count_reg` | 현재 몇 클럭 셌는지 저장 |
| comparator | `count_reg == target_reg - 1` 검사 |
| tick logic | 조건이 맞는 순간 `tick = 1` pulse 발생 |

### 회로 그림

```text
target_in
-> target_reg

count_reg
-> +1
-> compare with target_reg - 1
-> tick
-> count_reg reset or hold
```

### 동작 흐름

1. `target_reg`에 목표값 `N`을 저장한다.
2. `count_reg`는 `0`부터 1씩 증가한다.
3. `count_reg == target_reg - 1`이 되면 `tick = 1`
4. 그 다음 `count_reg`를 `0`으로 되돌리거나 다시 순환한다.

즉 `N`클럭마다 1번 pulse가 나온다.

### 최소 Verilog 골격

```verilog
module timer_tick_generator (
    input  wire       clk,
    input  wire       reset_n,
    input  wire       target_load,
    input  wire       en,
    input  wire [7:0] target_in,
    output reg        tick
);
    reg  [7:0] target_reg;
    reg  [7:0] count_reg;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            target_reg <= 8'd0;
            count_reg  <= 8'd0;
            tick       <= 1'b0;
        end else if (target_load) begin
            target_reg <= target_in;
            count_reg  <= 8'd0;
            tick       <= 1'b0;
        end else if (en) begin
            if (count_reg == target_reg - 8'd1) begin
                count_reg <= 8'd0;
                tick      <= 1'b1;
            end else begin
                count_reg <= count_reg + 8'd1;
                tick      <= 1'b0;
            end
        end else begin
            tick <= 1'b0;
        end
    end
endmodule
```

이 골격은 `HelloVerilog/counter_10000/counter_10000_common.v`처럼 `if (counter_reg == TICK_COUNT - 1)` 또는 `if (tick_counter_reg == 14'd9999)`처럼 비교식을 직접 쓰는 수업 코드 스타일에 맞춰 읽으면 된다.

### 한 줄 해석

`target_reg`가 가리키는 값만큼 세고, 비교가 맞는 순간 `tick` pulse를 낸다.

---

## 8. 여기서 MUX를 같이 봐야 하는 이유

counter/timer 안에서는 사실상 아래 중 하나를 고른다.

- reset 값
- load 값
- 증가값 또는 감소값
- 현재값 유지

즉 내부 선택 로직은 결국 `MUX` 감각이다.

그래서:
- `load`
- `en`
- `hold`
- `reset`

순서를 묻는 문제는 곧 `어느 입력을 선택하는가` 문제다.

---

## 9. 시험장에서 자주 틀리는 점

1. `reset_n`이 active-low인데 극성을 반대로 적음
2. `load`와 `en` 우선순위를 안 정함
3. `count == 0`에서 또 감소시키려 함
4. `done`과 `tick`을 pulse로 둘지 level로 둘지 명확히 안 적음
5. `target_reg`와 `count_reg` 역할을 뒤섞음
6. `count_reg == target_reg - 1` 비교 시점을 헷갈림

## 10. 손코딩 체크리스트

- reset 극성이 `reset_n`에 맞는가
- `load`가 `en`보다 우선하는가
- 감소는 `count_reg > 0`일 때만 하는가
- `done` 정의를 분명히 적었는가
- `target_reg`와 `count_reg`를 분리해서 적었는가
- `tick`이 1클럭 pulse인지 설명할 수 있는가

## 한 줄 요약

이번 시험의 `Counter/Timer`는 `값을 저장하는 register`, `다음 값을 만드는 계산`, `비교`, `MUX 성격의 선택 로직`, 그리고 필요하면 `target_reg`를 보고 `tick`을 발생시키는 구조로 읽으면 된다.

## 다음 연결

- [[domains/semiconductor/ai-npu-system-integration/hardware-time-clock-counter-timer-interrupt]]
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-worked-01-counter-10000-tick-counter-and-fnd-flow]]
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-06-synchronizer-edge-detector-and-0101-non-overlap-fsm]]
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-02-gate-to-combinational-logic-bridge]]
