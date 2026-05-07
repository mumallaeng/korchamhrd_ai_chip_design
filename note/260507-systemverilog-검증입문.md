# 26-05-07 - SystemVerilog 검증 입문

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | `class`, `interface`, `mailbox`, `randomize()` 기반 검증 구조 |
| 목표 | RTL과 검증 코드를 분리해서 보는 감각 만들기 |
| 핵심 | `tb_alu.sv`, `tb_alu_driver.sv`, `tb_register_8.sv` |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260507_sv_adder/sv_adder.srcs/sim_1/new/tb_alu.sv` | `3-10` | DUT와 TB를 잇는 `interface` |
| `helloHDL/260507_sv_adder/sv_adder.srcs/sim_1/new/tb_alu.sv` | `12-44` | 가장 단순한 `transaction`과 `generator` |
| `helloHDL/260507_sv_adder/sv_adder.srcs/sim_1/new/tb_alu_driver.sv` | `3-36` | `transaction`과 제약 기반 랜덤화 |
| `helloHDL/260507_sv_adder/sv_adder.srcs/sim_1/new/tb_alu_driver.sv` | `38-91` | `generator`, `driver`, `mailbox`, `event` |
| `helloHDL/260507_sv_adder/sv_adder.srcs/sim_1/new/tb_alu_driver.sv` | `93-159` | `monitor`, `scoreboard` |
| `helloHDL/260507_sv_adder/sv_adder.srcs/sim_1/new/tb_alu_driver.sv` | `161-206` | 전체를 묶는 `environment` |
| `helloHDL/260507_sv_register/sv_register.srcs/sim_1/new/tb_register_8.sv` | `3-19` | register DUT용 `interface`와 `transaction` |
| `helloHDL/260507_sv_register/sv_register.srcs/sim_1/new/tb_register_8.sv` | `138-185` | register 검증용 `environment` |

## 검증 블록 역할

| 구성요소 | 코드 기준 역할 |
| --- | --- |
| `transaction` | 한 번의 자극과 관측값을 묶는 객체 |
| `generator` | `randomize()`로 입력 케이스 생성 |
| `driver` | `virtual interface`를 통해 DUT 핀에 값 인가 |
| `monitor` | DUT 입출력을 읽어서 transaction으로 재구성 |
| `scoreboard` | 예상값과 실제값 비교 |
| `environment` | 위 블록을 묶고 실행 순서를 관리 |

## 코드에서 꼭 볼 줄

| 위치 | 포인트 |
| --- | --- |
| `tb_alu.sv:31-43` | 가장 단순한 smoke test는 generator가 바로 DUT 입력을 건드린다 |
| `tb_alu_driver.sv:44-58` | generator는 transaction을 mailbox에 넣고 다음 이벤트를 기다린다 |
| `tb_alu_driver.sv:72-89` | driver는 DUT에 값을 넣고 다음 transaction 타이밍을 열어 준다 |
| `tb_alu_driver.sv:145-155` | scoreboard가 덧셈/뺄셈 기대값을 계산한다 |
| `tb_register_8.sv:126-133` | register scoreboard는 `d == q`인지로 pass/fail을 가른다 |

## 주의점

| 오해 | 정리 |
| --- | --- |
| class를 쓰면 DUT도 객체가 된다 | DUT는 여전히 `module`이고 class는 검증용 구조다 |
| scoreboard와 coverage는 같다 | scoreboard는 정답 비교, coverage는 검증 범위 측정이다 |
| `tb_alu.sv`만 보면 충분하다 | `tb_alu.sv`는 smoke test이고 self-check는 `tb_alu_driver.sv`에 있다 |

## 연결 노트

- [[260508-systemverilog-검증심화]]
- [[260406-260529-복습노트-02-wire-reg-4state]]
