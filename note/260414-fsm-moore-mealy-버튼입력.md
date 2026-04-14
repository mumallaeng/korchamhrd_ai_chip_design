# 26-04-14 - FSM, Moore/Mealy, 버튼 입력 처리

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 목표 | FSM을 `state register + next-state logic + output logic`로 읽는다 |
| 핵심 | `fsm_led`, `seq_det_mealy`, reset, 상태 전이, 출력 위치 |
| 주의 | 파일명이나 주석보다 실제 출력식이 Moore인지 Mealy인지 더 중요하다 |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260414_fsm_led/fsm_led.srcs/sources_1/new/fsm_led.v` | `10-24` | 상태 인코딩, state reg, LED reg |
| `helloHDL/260414_fsm_led/fsm_led.srcs/sources_1/new/fsm_led.v` | `27-35` | 상태 레지스터 |
| `helloHDL/260414_fsm_led/fsm_led.srcs/sources_1/new/fsm_led.v` | `41-101` | next-state / output logic |
| `helloHDL/260414_fsm_led/fsm_led.srcs/sim_1/new/tb_fsm_led.v` | `20-51` | 상태 전이 시나리오 |
| `helloHDL/260414_fsm_led/fsm_led.srcs/sources_1/new/seq_det_mealy.v` | `13-17`, `19-56` | 패턴 검출 상태기계 |

## FSM을 읽는 기준

| 블록 | 질문 |
| --- | --- |
| state register | 현재 상태를 어디에 저장하는가 |
| next-state logic | 입력을 보고 다음 상태를 어떻게 정하는가 |
| output logic | 출력이 현재 상태만 보나, 입력도 같이 보나 |

## Moore와 Mealy

| 구분 | 핵심 |
| --- | --- |
| Moore | 출력이 현재 상태에만 의존 |
| Mealy | 출력이 현재 상태와 현재 입력에 함께 의존 |

## 코드에서 바로 볼 것

| 위치 | 읽는 포인트 |
| --- | --- |
| `fsm_led.v:27-35` | `current_state <= next_state` 구조가 기본 state register다 |
| `fsm_led.v:43-45` | 기본값을 먼저 주고 case에서 덮어쓴다 |
| `tb_fsm_led.v:33-49` | 클럭 에지 기준으로 상태 전이를 확인한다 |
| `seq_det_mealy.v:55-56` | 현재 출력식은 `din_bit`을 직접 보지 않아서 엄밀히는 Moore 쪽에 가깝다 |

## 중요한 정정

| 항목 | 정리 |
| --- | --- |
| `seq_det_mealy.v` 파일명 | 이름은 Mealy지만 현재 `dout_bit` 식은 state만 본다 |
| 따라서 | 파일명보다 `출력 조건식`을 직접 보고 Moore/Mealy를 판단해야 한다 |

## 버튼 입력 처리 관점

| 항목 | 정리 |
| --- | --- |
| 스위치 | 계속 유지되는 level 입력에 가깝다 |
| 버튼 | 순간 입력이라 debounce / pulse화가 필요하다 |
| FSM 입력 | level보다 1클럭 tick으로 단순화하면 읽기 쉽다 |

## 다음 연결

- [[260414-프로젝트-설명]]
