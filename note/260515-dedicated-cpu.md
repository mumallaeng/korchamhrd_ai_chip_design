# 26-05-15 - Dedicated CPU와 single-cycle control/datapath

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | dedicated CPU, datapath/control 분리, single-cycle vs multi-cycle vs pipeline |
| 목표 | 작은 알고리즘을 상태기계와 데이터패스로 나눠 읽는 감각 잡기 |
| 핵심 | `lecture_dedicated_cpu.sv`, `dedicated_cpu.sv`, `tb_dedicated_cpu.sv` |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260518_dedicated_cpu_0to10_55/dedicated_cpu_0to10_55.srcs/sources_1/new/lecture_dedicated_cpu.sv` | `3-18` | top이 control unit과 datapath를 연결 |
| `helloHDL/260518_dedicated_cpu_0to10_55/dedicated_cpu_0to10_55.srcs/sources_1/new/lecture_dedicated_cpu.sv` | `22-94` | register, mux, alu, comparator로 datapath 구성 |
| `helloHDL/260518_dedicated_cpu_0to10_55/dedicated_cpu_0to10_55.srcs/sources_1/new/lecture_dedicated_cpu.sv` | `149-244` | 상태별 제어 신호를 만드는 FSM |
| `helloHDL/260518_dedicated_cpu_0to10_55/dedicated_cpu_0to10_55.srcs/sources_1/new/dedicated_cpu.sv` | `46-98` | `count_reg`, `sum_reg`, `out` 레지스터와 next-value logic |
| `helloHDL/260518_dedicated_cpu_0to10_55/dedicated_cpu_0to10_55.srcs/sources_1/new/dedicated_cpu.sv` | `101-168` | `ST_INIT -> ST_ACCUM -> ST_INC -> ST_LATCH -> ST_DONE` FSM |
| `helloHDL/260518_dedicated_cpu_0to10_55/dedicated_cpu_0to10_55.srcs/sim_1/new/tb_dedicated_cpu.sv` | `25-84` | reset 확인, timeout, 최종값/hold 검사 |

## CPU 구조 메모

| 주제 | 정리 |
| --- | --- |
| single-cycle | instruction 하나의 필요한 작업을 한 cycle 안에 끝내는 구조 |
| critical path | single-cycle clock period는 가장 오래 걸리는 combinational path에 맞춰진다 |
| multi-cycle | 일을 여러 cycle로 나눠 cycle time을 줄일 수 있지만 instruction당 cycle 수는 늘어난다 |
| pipeline | stage를 겹쳐 throughput을 높이는 구조다. 개별 instruction latency가 자동으로 줄어드는 것은 아니다 |

## 예제의 핵심 구조

| 포인트 | 정리 |
| --- | --- |
| dedicated CPU | 범용 ISA CPU가 아니라 한 가지 작업만 하는 작은 제어기 예제 |
| 목표 동작 | `0`부터 `10`까지를 한 번씩 누적해서 최종 `55`를 만든다 |
| datapath | 값을 저장하는 레지스터와 값을 계산/선택하는 ALU, MUX로 나눈다 |
| control unit | 현재 state에 따라 `clear`, `load`, `inc`, `add` 같은 제어 신호를 만든다 |
| 학습용 코드 | `lecture_dedicated_cpu.sv`는 datapath/control 분리 구조를 읽는 참고 코드 |
| 정리본 코드 | `dedicated_cpu.sv`는 같은 예제를 더 직접적인 신호 이름과 상태 이름으로 다시 쓴 버전 |
| testbench | `tb_dedicated_cpu.sv`는 파형 보기용이 아니라 reset/result/hold를 자동 검사하는 self-checking TB |

## 알고리즘 흐름

```text
reset
-> count = 0, sum = 0
-> sum = sum + count
-> count == 10 이면 결과 저장
-> 아니면 count = count + 1 후 다시 누적
```

- 핵심은 `0, 1, 2, ... , 10`을 각각 한 번씩 `sum_reg`에 더한 뒤 `out`에 고정하는 것
- 즉, 동작은 `while (count <= 10)` 계열로 읽어야 하며, `10`을 빼먹는 해석이면 안 된다.

## 코드에서 꼭 볼 줄

| 위치 | 포인트 |
| --- | --- |
| `lecture_dedicated_cpu.sv:16-18` | top은 wiring 역할만 하고 실제 동작은 하위 모듈이 맡는다 |
| `lecture_dedicated_cpu.sv:81-85` | comparator는 `areg_out > 9`를 검사하므로 종료 조건 신호는 사실상 `a >= 10` 의미로 읽어야 한다 |
| `lecture_dedicated_cpu.sv:176-242` | control unit은 state마다 `sel/load` 신호를 조합논리로 만든다 |
| `dedicated_cpu.sv:65-67` | `count_next`, `sum_next`, `count_is_last`를 분리해 두면 데이터 흐름이 훨씬 읽기 쉽다 |
| `dedicated_cpu.sv:122-167` | `always_ff + always_comb + enum` 조합이 SV 스타일 FSM의 기본 형태다 |
| `tb_dedicated_cpu.sv:49-64` | 완료를 무한정 기다리지 않고 timeout으로 검증 실패를 잡는다 |
| `tb_dedicated_cpu.sv:67-84` | 최종 `out`만 보지 않고 내부 `count_reg`, `sum_reg`, output hold까지 같이 본다 |

## 주의점

| 오해 | 정리 |
| --- | --- |
| single-cycle이면 무조건 빠르다 | 아니다. 가장 긴 경로가 clock period를 결정하므로 오히려 주파수가 낮아질 수 있다 |
| pipeline이면 한 instruction도 바로 빨라진다 | 보통 핵심은 latency보다 throughput 개선이다 |
| control signal은 순차적으로 천천히 만들어도 된다 | single-cycle에서는 같은 cycle 안에 datapath 제어까지 끝나야 하므로 control도 빠른 조합논리여야 한다 |
| 테스트는 오래 돌리기만 하면 된다 | 반복 횟수, 종료 조건, 기대값 검사 근거가 같이 있어야 한다 |

## 발표/검증 메모

- 반복 횟수와 자극 개수는 이유를 설명할 수 있어야 함
- 검증 결과는 단순 pass/fail보다 coverage나 결과 분석과 연결해서 설명하면 좋음
- 시뮬레이션 시간을 줄이려고 실제와 다른 파라미터/자극을 쓰면 기준이 흐려질 수 있음

## 연결 노트

- [[260514-cpu-구조]]
- [[260512-systemverilog-fifo-검증]]

## 참고 자료

- Cornell CS3410 CPU Architecture
  - https://www.cs.cornell.edu/courses/cs3410/2024fa/notes/arch.html
- Cornell CS3410 Pipelining and Performance
  - https://www.cs.cornell.edu/courses/cs3410/2025sp/notes/pipelining.html
