# 26-04-10 - Control Unit, Datapath, Timing 안정성

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 목표 | 제어와 데이터 경로를 분리해서 읽고, 버튼 입력을 안전하게 받는 구조를 이해한다 |
| 핵심 | `control_unit`, `button_debounce`, `run/stop`, `clear`, `mode`, synchronizer |
| 결과 | 단순 카운터보다 한 단계 올라간 시스템 구조를 읽는 기준을 만든다 |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260408_counter_10000/counter_10000.srcs/sources_1/new/control_unit.v` | `15-24` | 상태와 제어 레지스터 |
| `helloHDL/260408_counter_10000/counter_10000.srcs/sources_1/new/control_unit.v` | `36-75` | next-state / 출력 로직 |
| `helloHDL/260408_counter_10000/counter_10000.srcs/sources_1/new/button_debounce.v` | `17-28` | synchronizer, level, tick 출력 |
| `helloHDL/260408_counter_10000/counter_10000.srcs/sources_1/new/button_debounce.v` | `30-81` | 샘플링과 안정화 |
| `helloHDL/260408_counter_10000/counter_10000.srcs/sources_1/new/counter_10000.v` | `29-75` | 버튼 처리 블록과 control/datapath 연결 |

## 구조를 이렇게 나눈다

| 블록 | 역할 |
| --- | --- |
| `control_unit` | 지금 무엇을 해야 하는지 결정 |
| `datapath` | 실제 수치 값을 바꾸고 전달 |
| `button_debounce` | 비동기 버튼을 내부 `clk` 기준으로 안정화 |

## timing 관점 핵심

| 항목 | 정리 |
| --- | --- |
| synchronizer | 외부 버튼을 바로 FSM에 넣지 않고 두 단계 레지스터로 받는다 |
| debounce | 튀는 입력을 여러 샘플로 안정화한다 |
| level vs tick | 눌려 있는 상태와 한 번 눌렸다는 이벤트는 다르다 |
| `o_btn_tick` | `level_reg & ~level_d1_reg`라서 1클럭 pulse다 |

## 코드에서 바로 읽을 것

| 위치 | 읽는 포인트 |
| --- | --- |
| `button_debounce.v:30-37` | 2-stage synchronizer |
| `button_debounce.v:55-72` | history를 보고 stable high/low 판정 |
| `control_unit.v:42-68` | `STOP`, `RUN`, `CLEAR`, `MODE` 전이 |
| `counter_10000.v:65-75` | control 출력이 datapath 입력으로 들어간다 |

## 주의점

| 실수 | 정리 |
| --- | --- |
| 버튼을 그냥 `if (btn)`로 바로 쓴다 | bounce와 metastability에 취약하다 |
| `run/stop`과 `mode`를 같은 신호로 본다 | 하나는 동작 여부, 하나는 방향/모드다 |
| datapath 안에서 제어까지 다 처리한다 | 규모가 커질수록 읽기 어렵다 |

## 다음 연결

- [[260413-반복문-이벤트제어-tb-rtl]]
- [[260414-프로젝트-설명]]
