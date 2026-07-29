# 논리회로 시험 대비 04 - 논리회로에서 Verilog까지 커리큘럼

> 분류: 2026-04-06부터 2026-05-29까지의 Korcham 수업·시험 범위에 종속된 activity note

목적:
- 현재 시험 범위를 무엇부터 봐야 하는지 우선순위로 고정하기
- `00 요약본 -> 상세 노트`로 넓어지는 구조를 명확히 하기
- 최소 필수 범위와 함께 따라가는 보조 범위도 분리해서 보기 쉽게 만들기

연결 노트:
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-00-core-minimum-summary]]
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-01-prerequisite-logic-gates-and-symbols]]
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-02-gate-to-combinational-logic-bridge]]
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-03-combinational-vs-sequential]]
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-05-counter-timer-counter-register]]
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-06-synchronizer-edge-detector-and-0101-non-overlap-fsm]]
- [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-check-01-gate-truth-table-10min-quiz]]

## 최소 필수 범위

| 범위 | 반드시 들어갈 내용 | 바로 답할 수 있어야 할 것 |
| --- | --- | --- |
| `Counter/Timer - Counter Register` | `clk`, `reset_n`, `load`, `data_in[7:0]`, `en`, decrement, `done` | `00h` reset, `03h` load, `03 -> 02 -> 01 -> 00`, `done` 시점 |
| `Synchronizer / Edge Detector (MCP)` | `MCP = Multi-Cycle Path`, `data hold`, `control/toggle sync`, `edge detect`, `capture pulse` | 왜 `data bus`를 비트별로 각각 동기화하지 않고 `control path`를 동기화하는가 |
| `0101 pattern FSM non-overlap` | 상태 정의, 비겹침 전이, RTL 골격 | `S3 + din=1 -> detect=1, next_state=S0` |

## 같이 포함되어야 하는 보조 범위

| 범위 | 시험에서 기대되는 이해 |
| --- | --- |
| `MUX` | `if`, `case`, `?:`를 보면 선택 회로로 읽기 |
| `Timer / Tick Generator` | `target_reg`가 가리키는 값만큼 세고 `tick` pulse 발생 |
| `SIPO / PISO` | 둘 다 `shift register`라는 점, `load / shift / hold` 구분 |
| `pattern detector` | 특정 비트열 검출 문제를 FSM으로 읽기 |
| `ASM chart` | 상태 박스, 조건 박스, 조건부 출력 박스를 코드로 옮기기 |

## 현재 우선순위

| 우선순위 | 읽을 노트 | 역할 |
| --- | --- | --- |
| `0` | [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-00-core-minimum-summary]] | 한 페이지 요약 진입점 |
| `1` | [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-05-counter-timer-counter-register]] | Counter/Timer, target register, tick generator 정리 |
| `2` | [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-06-synchronizer-edge-detector-and-0101-non-overlap-fsm]] | `MCP`, synchronizer, edge detector, shift register, FSM, ASM 정리 |
| `3` | [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-check-01-gate-truth-table-10min-quiz]] | 본선 학습 후 마지막 반복 점검 |

## 막히는 지점별 보강 노트

| 막히는 지점 | 보강 노트 |
| --- | --- |
| gate 기호, bubble, 진리표가 흔들림 | [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-01-prerequisite-logic-gates-and-symbols]] |
| gate에서 조합논리로 왜 넘어가는지 흐림, `MUX` 감각이 약함 | [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-02-gate-to-combinational-logic-bridge]] |
| 조합논리와 순차논리 경계가 흐림, `tick generator`, `shift register`, `FSM`이 섞여 보임 | [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-exam-03-combinational-vs-sequential]] |

## 현재 기준 답안 프레임

### 1. Counter / Timer / Register

- `register + increment/decrement logic + comparator + select logic`
- `load` 우선순위
- `done`와 `tick`은 pulse인지 level인지 먼저 정의
- `target_reg`가 있으면 `그 값만큼 세고 pulse 발생` 구조로 설명

### 2. Synchronizer / Edge Detector (MCP) / Shift Register

- 여기서 `MCP`는 `Multi-Cycle Path`
- `source data hold -> control/toggle -> sync_ff1 -> sync_ff2 -> edge detect -> capture pulse`
- `toggle` 기반이면 변화 검출은 `sync_sig ^ sync_dly`처럼 읽는 편이 정확함
- `SIPO/PISO`는 둘 다 `shift register`
- `load / shift / hold` 순서를 분명히 적기

### 3. FSM / Pattern Detector / ASM

- 상태 정의 먼저
- 비겹침이면 검출 후 `S0` 복귀
- `state / next_state / output` 분리
- `ASM chart`는 상태 박스와 조건 박스를 코드 블록으로 번역

## 읽는 순서

1. `00`에서 전체 구조를 잡는다.
2. `05`에서 `counter / timer / target register / tick`을 잡는다.
3. `06`에서 `MCP`, `synchronizer`, `edge detector`, `SIPO / PISO`, `FSM`, `ASM`을 잡는다.
4. `02`, `03`으로 돌아가 `MUX`와 `조합/순차` 감각을 보강한다.
5. [[activities/korcham/notes/260406-260529-논리회로-시험대비/study-check-01-gate-truth-table-10min-quiz]]로 빠르게 반복 점검한다.

## 한 줄 요약

현재 시험 대비는 `00 요약본`에서 시작해서 `05 Counter/Timer`, `06 Synchronizer / Edge Detector (MCP) + Shift Register + FSM + ASM`으로 바로 넓어지고, `02/03`으로 `MUX`와 구조 감각을 보강하는 흐름이 핵심이다.
