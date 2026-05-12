# 26-05-12 - SystemVerilog FIFO 검증 구조

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 주제 | `interface`, `transaction`, `mailbox`, `queue scoreboard` |
| 목표 | FIFO RTL 자체보다 class 기반 SV testbench 구조를 읽는 감각 잡기 |
| 핵심 | `fifo.sv`, `tb_fifo.sv` |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260522_sv_FIFO/sv_FIFO.srcs/sources_1/new/fifo.sv` | `18-36` | top FIFO가 `register_file`과 `control_unit`으로 분리됨 |
| `helloHDL/260522_sv_FIFO/sv_FIFO.srcs/sources_1/new/fifo.sv` | `51-62` | write는 `always_ff`, read는 `always_comb`인 저장 구조 |
| `helloHDL/260522_sv_FIFO/sv_FIFO.srcs/sources_1/new/fifo.sv` | `106-149` | `push/pop/full/empty` 조합에 따른 pointer 제어 |
| `helloHDL/260522_sv_FIFO/sv_FIFO.srcs/sim_1/new/tb_fifo.sv` | `3-12` | `fifo_interface`, DUT 신호 묶음 |
| `helloHDL/260522_sv_FIFO/sv_FIFO.srcs/sim_1/new/tb_fifo.sv` | `32-55` | generator가 transaction randomize 후 mailbox에 전달 |
| `helloHDL/260522_sv_FIFO/sv_FIFO.srcs/sim_1/new/tb_fifo.sv` | `70-84` | driver `preset()`, reset 뒤 `empty/full` 즉시 확인 |
| `helloHDL/260522_sv_FIFO/sv_FIFO.srcs/sim_1/new/tb_fifo.sv` | `86-129` | `push_only`, `pop_only`, `push_pop` 자극 task 분리 |
| `helloHDL/260522_sv_FIFO/sv_FIFO.srcs/sim_1/new/tb_fifo.sv` | `158-173` | monitor가 `negedge clk`에서 샘플링 |
| `helloHDL/260522_sv_FIFO/sv_FIFO.srcs/sim_1/new/tb_fifo.sv` | `177-225` | scoreboard가 queue로 expected FIFO 상태 유지 |
| `helloHDL/260522_sv_FIFO/sv_FIFO.srcs/sim_1/new/tb_fifo.sv` | `253-287` | environment 실행 구조, 현재는 `push_only` 위주로만 연결됨 |

## 핵심 구조

| 주제 | 정리 |
| --- | --- |
| `interface` | DUT 신호를 한곳에 모아 driver/monitor가 `virtual interface`로 접근 |
| `transaction` | `push`, `pop`, `push_data`, `pop_data`, `full`, `empty`를 한 묶음으로 다룸 |
| `mailbox + event` | generator가 transaction을 보내고, driver/scoreboard가 다음 케이스 타이밍을 열어 줌 |
| `queue scoreboard` | FIFO expected model을 queue로 유지하고 실제 `pop_data`와 비교 |
| 구조 전환 포인트 | FIFO 개념 복습보다 “절차형 TB -> 구조화된 SV TB” 전환이 중요 |

## 코드에서 꼭 볼 줄

| 위치 | 포인트 |
| --- | --- |
| `fifo.sv:32-33` | write enable은 `~full & push`로 막는다 |
| `fifo.sv:117-121` | `push only`에서 다음 write pointer가 read pointer를 만나면 `full`이 된다 |
| `fifo.sv:127-130` | `pop only`에서 다음 read pointer가 write pointer를 만나면 `empty`가 된다 |
| `tb_fifo.sv:78-83` | reset 직후 `empty=1`, `full=0`을 assertion으로 바로 확인한다 |
| `tb_fifo.sv:160-170` | monitor는 구동 직후가 아니라 `negedge clk`에서 결과를 묶어 가져간다 |
| `tb_fifo.sv:196-210` | scoreboard는 `push_front()`와 `pop_back()` 조합으로 FIFO 순서를 모델링한다 |
| `tb_fifo.sv:257-264` | 현재 `env.run()`은 `gen.run()`과 `drv.push_only()`만 실제로 돌고, `mon.run()`과 `scb.run()`은 주석 처리되어 있다 |

## 주의점

| 오해 | 정리 |
| --- | --- |
| 이 TB가 이미 full random verification까지 완성됐다 | 현재 연결은 `push_only` 중심이고 monitor/scoreboard main run은 아직 붙지 않았다 |
| queue만 쓰면 검증이 끝난다 | queue는 expected model일 뿐이고 샘플링 시점과 event handshake가 같이 맞아야 한다 |
| FIFO 검증 핵심은 랜덤만 많이 돌리는 것이다 | 먼저 reset, full, empty, push/pop 단일 시나리오가 제대로 구조화되어야 한다 |
| 출력 요약을 그대로 믿어도 된다 | `tb_fifo.sv:280-283`에는 아직 `RAM Verification` 문구가 남아 있어 copy-paste 흔적이 보인다 |

## 연결 노트

- [[260430-fifo-sensor-interface]]
- [[260508-systemverilog-검증심화]]
