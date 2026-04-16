# 26-04-16 보충 - `parameter`와 `localparam`

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| `parameter` | 모듈 밖에서 바꿀 수 있는 설정값 |
| `localparam` | 모듈 안에서만 쓰는 고정 상수 |
| 읽는 기준 | 바꿔야 하는 값인지, 내부 규칙인지로 구분한다 |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260415_practice_misc/practice.srcs/sources_1/new/practice.v` | `3-5`, `45-47`, `77-79` | `parameter TICK_COUNT` |
| `helloHDL/260416_stopwatch_watch/stopwatch_watch.srcs/sources_1/new/stopwatch_datapath.v` | `3-12` | bit width와 범위를 parameter로 받음 |
| `helloHDL/260408_counter_10000/counter_10000.srcs/sources_1/new/button_debounce.v` | `15` | 내부 폭 계산용 `localparam` |
| `helloHDL/260408_counter_10000/counter_10000.srcs/sources_1/new/control_unit.v` | `15-18` | 상태 인코딩 `localparam` |
| `helloHDL/260506_SR04/SR04.srcs/sources_1/new/sr04.v` | `61-69` | timeout, pulse width 같은 내부 규격 |

## 구분

| 질문 | `parameter` | `localparam` |
| --- | --- | --- |
| 외부에서 override할 수 있나 | 가능 | 불가 |
| 용도 | 주파수, 비트폭, 횟수 같은 설정값 | 상태값, 내부 계산 결과, 규격 상수 |
| 읽는 감각 | 옵션 | 내부 약속 |

## 코드로 보면 이런 차이다

```verilog
module practice #(
    parameter TICK_COUNT = 10
) ();
```

```verilog
localparam [1:0] STOP  = 2'd0;
localparam [1:0] RUN   = 2'd1;
```

## 언제 무엇을 쓰는가

| 상황 | 권장 |
| --- | --- |
| testbench나 상위 모듈에서 바꿔가며 써야 함 | `parameter` |
| FSM state 값처럼 내부 규칙이어야 함 | `localparam` |
| `clog2` 계산 결과처럼 내부 폭 산출값 | `localparam` |

## 주의점

| 실수 | 정리 |
| --- | --- |
| 모든 상수를 `parameter`로 둔다 | 내부 state 값까지 외부에서 바뀌면 읽기 어렵다 |
| 모든 상수를 `localparam`로 둔다 | 재사용해야 할 값까지 고정돼 버린다 |

## 다음 연결

- [[260406-260529-10-정리보류]]
