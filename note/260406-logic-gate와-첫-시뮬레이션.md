# 26-04-06 - Logic Gate와 첫 시뮬레이션

## 한눈에 보기

| 항목 | 내용 |
| --- | --- |
| 목표 | 가장 단순한 조합논리를 Verilog로 쓰고 파형으로 검증한다 |
| 핵심 | `assign`, `wire`, `reg`, testbench, XDC |
| 결과 | `gates.v -> tb_gates.v -> gates.xdc` 흐름을 직접 본다 |

## 관련 코드 위치

| 파일 | 위치 | 의미 |
| --- | --- | --- |
| `helloHDL/260406_gates/gates.srcs/sources_1/new/gates.v` | `3-21` | AND, NAND, OR, NOR, XOR, XNOR, NOT |
| `helloHDL/260406_gates/gates.srcs/sim_1/new/tb_gates.v` | `5-37` | `reg` 입력, `wire` 출력, DUT 인스턴스, 자극 입력 |
| `helloHDL/260406_gates/gates.srcs/constrs_1/new/gates.xdc` | `1-18` | 스위치/LED 핀 매핑 |

## 코드에서 바로 볼 것

| 항목 | 정리 |
| --- | --- |
| `` `timescale 1ns / 1ps `` | 시뮬레이션 시간 단위와 정밀도 |
| `assign y0 = a & b;` | 조합논리를 가장 직접적으로 쓰는 방식 |
| `reg a, b` | testbench에서 입력을 직접 바꾸기 위해 사용 |
| `wire y0 ... y6` | DUT 출력은 선처럼 받아서 본다 |
| `#10` | testbench 시간 지연 |

## `wire`와 `reg`

| 구분 | 핵심 |
| --- | --- |
| `wire` | 연결선 개념, 다른 곳이 값을 drive해야 한다 |
| `reg` | procedural block 안에서 값을 잡아두는 변수 |
| 주의 | `reg = 실제 플립플롭`으로 바로 외우면 안 된다 |

## 이 날 실습 흐름

```text
입력 a, b 설정
-> gates DUT가 조합 결과 생성
-> tb_gates가 00, 01, 10, 11 순서로 자극 입력
-> 파형에서 각 게이트 출력 확인
```

## 보드 연결 체크

| 항목 | 확인할 것 |
| --- | --- |
| 포트 이름 | RTL과 XDC 이름이 같은가 |
| 핀 번호 | 스위치/LED가 기대한 위치에 연결되는가 |
| IOSTANDARD | `LVCMOS33`처럼 보드 기준에 맞는가 |

## 주의점

| 실수 | 정리 |
| --- | --- |
| 시뮬레이션만 보고 끝낸다 | XDC가 틀리면 보드에서는 다르게 보인다 |
| `reg`를 저장소자로만 외운다 | 조합 `always @(*)`에서도 쓸 수 있다 |
| `assign`와 `always`를 같은 감각으로 본다 | `assign`은 연결, `always`는 절차 블록 |

## 다음 연결

- [[260407-adder와-첫-fnd-표시]]
- [[260406-260529-복습노트-02-wire-reg-4state]]
- [[260406-260529-복습노트-03-basys3-xdc-constraints]]
