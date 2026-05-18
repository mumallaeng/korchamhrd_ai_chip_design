# 26-05-18 - Dedicated CPU 누적합 설계와 확장 포인트

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | dedicated CPU 누적합 설계, counter 예제 확장, 최종 결과 latch |
| 목표 | 학습용 counter 전용 CPU를 `0 ~ 10` 누적합 CPU로 확장해서 읽는 기준 정리 |
| 핵심 | `lecture_dedicated_cpu.sv`, `dedicated_cpu.sv`, `tb_dedicated_cpu.sv` |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260518_dedicated_cpu_0to10_55/dedicated_cpu_0to10_55.srcs/sources_1/new/lecture_dedicated_cpu.sv` | `22-94` | `A_REG`, `SUM_REG`, `OUT_REG`, MUX, comparator가 묶인 학습용 datapath |
| `helloHDL/260518_dedicated_cpu_0to10_55/dedicated_cpu_0to10_55.srcs/sources_1/new/lecture_dedicated_cpu.sv` | `149-242` | `S0 ~ S5` 기반 control unit |
| `helloHDL/260518_dedicated_cpu_0to10_55/dedicated_cpu_0to10_55.srcs/sources_1/new/dedicated_cpu.sv` | `65-67` | `count_next`, `sum_next`, `count_is_last`로 데이터 흐름 정리 |
| `helloHDL/260518_dedicated_cpu_0to10_55/dedicated_cpu_0to10_55.srcs/sources_1/new/dedicated_cpu.sv` | `135-161` | `ST_INIT -> ST_ACCUM -> ST_INC -> ST_LATCH -> ST_DONE` 상태 흐름 |
| `helloHDL/260518_dedicated_cpu_0to10_55/dedicated_cpu_0to10_55.srcs/sim_1/new/tb_dedicated_cpu.sv` | `145-175` | 완료 전 `out=0`, 완료 후 hold를 monitor가 검사 |
| `helloHDL/260518_dedicated_cpu_0to10_55/dedicated_cpu_0to10_55.srcs/sim_1/new/tb_dedicated_cpu.sv` | `222-251` | scoreboard가 최종 `out=55`, `count_reg=10`, `sum_reg=55`를 확인 |

## 핵심 구조

| 포인트 | 정리 |
| --- | --- |
| 설계 목표 | `0 + 1 + 2 + ... + 10 = 55`를 계산하고 최종 결과를 유지하는 전용 CPU |
| counter 확장 | register 1개짜리 counter 예제를 `count_reg + sum_reg + out` 구조로 확장한 문제 |
| datapath 역할 | `count_reg`는 현재 항, `sum_reg`는 누적합, `out`은 마지막 결과를 고정하는 register |
| control 역할 | 초기화, 누적, 증가, 결과 저장, 종료를 state로 나눠 제어 |
| 검증 기준 | reset clear, 제한 cycle 안 완료, 완료 전 `out=0`, 완료 후 result hold |

## 알고리즘 흐름

```text
reset
-> count = 0, sum = 0
-> sum = sum + count
-> count == 10 이면 out = sum
-> 아니면 count = count + 1 후 다시 누적
```

- `10`도 더해야 하므로 누적을 먼저 하고 종료를 판단하는 흐름으로 읽어야 함
- 최종 출력은 현재 `count`가 아니라 누적된 `sum`

## 누적합 설계 포인트

| 항목 | 정리 |
| --- | --- |
| 상태 설계 | 학습용 `S0 ~ S5`든 정리본 `ST_*`든 핵심은 `초기화 -> 누적 -> 증가 -> 결과 고정 -> 정지` |
| 종료 조건 | 학습용 comparator는 `areg_out > 9`, 정리본은 `count_reg == 10`; 표현만 다르고 의미는 같다 |
| 출력 정책 | 중간 합을 계속 보일지 마지막 값만 latch할지 먼저 정해야 한다. 현재 정리본과 TB 기준은 마지막 값 latch |
| 범용 CPU와 차이 | instruction fetch/decode 없이 정해진 알고리즘 하나만 수행하므로 control이 더 작고 직접적 |

## 코드에서 꼭 볼 줄

| 위치 | 포인트 |
| --- | --- |
| `lecture_dedicated_cpu.sv:81-85` | comparator는 종료 조건을 사실상 `a >= 10` 의미로 만든다 |
| `dedicated_cpu.sv:65-67` | next-value를 분리하면 datapath 해석이 쉬워진다 |
| `dedicated_cpu.sv:142-156` | 현재 값 누적 뒤 마지막 cycle에 결과를 latch한다 |
| `tb_dedicated_cpu.sv:148-156` | 완료 전 `out`이 바뀌지 않는지 확인한다 |
| `tb_dedicated_cpu.sv:246-251` | PASS 기준이 최종 계약을 그대로 보여준다 |

## 연결 노트

- [[260515-dedicated-cpu]]
- [[260514-cpu-구조]]


## 추가 설계 과제

dedicated CPU 정리에는 두 축을 함께 남긴다.
1. dedicated waveform 분석
2. general purpose CPU 코드 전개
