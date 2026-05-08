# 26-05-08 - SystemVerilog 검증 심화

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | `event`, `mailbox`, `fork-join`, 샘플링 타이밍 |
| 목표 | class 기반 TB에서 race 없이 검증 흐름을 맞추는 방법 이해 |
| 핵심 | `tb_alu_driver.sv`, `tb_register_8.sv` |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260507_sv_adder/sv_adder.srcs/sim_1/new/tb_alu_driver.sv` | `40-58` | generator가 mailbox에 transaction을 넣고 event를 기다림 |
| `helloHDL/260507_sv_adder/sv_adder.srcs/sim_1/new/tb_alu_driver.sv` | `79-89` | driver가 DUT를 구동하고 다음 generator 이벤트를 열어 줌 |
| `helloHDL/260507_sv_adder/sv_adder.srcs/sim_1/new/tb_alu_driver.sv` | `104-117` | monitor가 `#5` 지점에서 샘플링 |
| `helloHDL/260507_sv_adder/sv_adder.srcs/sim_1/new/tb_alu_driver.sv` | `179-195` | `fork ... join_none`, `wait`, `disable fork` 종료 구조 |
| `helloHDL/260507_sv_register/sv_register.srcs/sim_1/new/tb_register_8.sv` | `31-44` | generator가 `event_gen_next`를 기다림 |
| `helloHDL/260507_sv_register/sv_register.srcs/sim_1/new/tb_register_8.sv` | `65-75` | driver가 `negedge`에서 monitor 이벤트를 발생 |
| `helloHDL/260507_sv_register/sv_register.srcs/sim_1/new/tb_register_8.sv` | `92-103` | monitor가 `posedge clk` 뒤 `#1`에 `q`를 캡처 |
| `helloHDL/260507_sv_register/sv_register.srcs/sim_1/new/tb_register_8.sv` | `120-135` | scoreboard가 비교 후 다음 generator 이벤트를 발생 |
| `helloHDL/260507_sv_register/sv_register.srcs/sim_1/new/tb_register_8.sv` | `157-173` | 순차 DUT용 환경 종료 구조 |

## 동기화 구조 핵심

| 요소 | 의미 |
| --- | --- |
| `mailbox` | transaction을 프로세스 사이에 안전하게 전달 |
| `event` | 다음 단계로 넘어갈 타이밍을 명시적으로 열어 줌 |
| `join_none + wait` | background task를 띄운 뒤 목표 개수만큼 검증하고 종료 |
| 샘플링 지점 | DUT가 갱신된 뒤를 잡아야 race를 줄일 수 있다 |

## 코드에서 꼭 볼 줄

| 위치 | 포인트 |
| --- | --- |
| `tb_alu_driver.sv:52-58` | generator는 randomize 후 바로 다음 케이스로 가지 않는다 |
| `tb_alu_driver.sv:106-116` | monitor는 driver와 같은 시각에 읽지 않으려고 중간 지점에서 본다 |
| `tb_alu_driver.sv:191-193` | `wait (scb.total_cnt >= target_count)`로 종료 시점을 제어한다 |
| `tb_register_8.sv:73-75` | driver가 `negedge`에서 monitor 이벤트를 열어 샘플 타이밍을 맞춘다 |
| `tb_register_8.sv:95-100` | 플립플롭 출력은 `posedge` 직후 한 델타 뒤에 읽는다 |

## 주의점

| 오해 | 정리 |
| --- | --- |
| monitor에 delay만 주면 다 해결된다 | DUT가 언제 갱신되는지 기준을 먼저 잡아야 한다 |
| `join_none`는 그냥 편한 문법이다 | 종료 조건과 `disable fork`가 같이 있어야 안전하다 |
| `logic`이면 `wire`가 완전히 필요 없다 | net 의미가 필요한 경우는 여전히 `wire`가 맞다 |

## 연결 노트

- [[260507-systemverilog-검증입문]]
- [[260406-260529-복습노트-02-wire-reg-4state]]
