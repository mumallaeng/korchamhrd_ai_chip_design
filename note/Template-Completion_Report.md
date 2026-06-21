# 완료 보고서 양식

김연우

2026.01.01 ~ 2026.12.31

# 1. 개요 (Overview)

## 1.1 목적 및 목표

- 시스템 구현 목적 정의
- 핵심 기능 및 성능 목표 명시

본 설계의 목적은 특정 기능을 수행하는 디지털 시스템을 구현하고, Timing 및 기능적 정확성을 만족하는 것이다.

## 1.2 설계 범위

- 포함 기능 정의
- 제외 범위 정의

## 1.3 프로젝트 요약

- 설계 대상 시스템 한 줄 요약
- 핵심 기술 키워드 나열

## 1.4 설계 사양 요약 (Specification Summary)

- 주요 설계 파라미터 명시

예:

- 동작 주파수: 100 MHz
- 데이터 해상도: 12-bit
- 동작 전압: 1.0 V
- 설계 목표: Low Power / High Throughput

## 1.5 AS-IS / TO-BE

- 기존 구조 정의
- 개선 구조 정의
- 주요 개선 사항 요약

# 2. 프로젝트 관리 (Project Management)

## 2.1 일정 계획 (Schedule)

| 단계 | 기간 | 주요 작업 |
| --- | --- | --- |
| 요구사항 정의 | Week 1 | Spec 정의 |
| 아키텍처 설계 | Week 2 | Block Diagram |
| RTL 설계 | Week 3~4 | Module 구현 |
| 검증 | Week 5~6 | Simulation |
| FPGA 구현 | Week 7 | Implementation |

## 2.2 역할 분담 (Roles & Responsibilities)

| 역할 | 담당 업무 |
| --- | --- |
| RTL 설계 | Datapath / Control 구현 |
| Verification | Testbench, Coverage |
| Physical | Synthesis, STA |
| PM | 일정 관리 |

## 2.3 개발 환경 (Development Environment)

| 분류 | 기술 |
| --- | --- |
| 형상관리 | Git |
| 협업 | Slack, Jira |
| 문서 | Confluence |

## 2.4 설계 환경 (Design Environment)

| 분류 | 내용 |
| --- | --- |
| 언어 | Verilog, SystemVerilog |
| FPGA | Basys3 |
| EDA | Vivado, Synopsys |
| Simulator | ModelSim |

# 3. 아키텍처 설계 (Architecture)

## 3.1 시스템 구조

- Block Diagram
- 데이터 흐름 정의

## 3.2 설계 이론 및 배경 (Theory & Background)

- FSM / ASM 이론
- Pipeline 구조 이론
- 관련 데이터시트 및 논문 기반 설계 근거

관련 이론은 참고 문헌 [0], [1]을 기반으로 한다.

# 4. 상세 설계 (Detailed Design)

## 4.1 RTL 설계

- Module 구성
- 주요 구조 설명(순서도 혹은 ASM 등)

## 4.2 Datapath / Control

- 연산 구조 정의
- 상태 제어 로직

## 4.3 Timing 설계

- Critical Path 정의
- Pipeline 분할

## 4.4 설계 전략 (Design Strategy)

- Timing Optimization
- Low Power Design
- 안정성 확보 (Glitch 방지, CDC 처리 등)

# 5. 시뮬레이션 및 검증 (Simulation & Verification)

## 5.1 Testbench

| 신호 이름 | 신호 설명 |
| --- | --- |
| clk | 전체 시스템 Main CLK으로 100MHz의 주파수를 가진다. |
| rst | 전체 순차 회로에 Reset 동작을 부여하기 위한 신호이다. |
| sw | 스위치 입력 신호로 State Machine의 입력 신호이다. 해당 신호와 현재 State Machine의 상태에 따라 다음 State가 결정된다. |
| Current State | State Machine에서 현재 State를 나타내는 신호이다. |
| Next State | State Machine에서 입력 및 현재 State에 따라 다음 State를 정의하는 신호이다. |
| led | 출력 신호이다. Moore Machine으로 설계하여 출력 신호는 Current State 신호에 맞추어 출력되는 신호이다. |

표 1. 시뮬레이션 신호 정의

| State 이름 | State 설명 |
| --- | --- |
| State A | 의미 |
| State B | 의미 |
| State C | 의미 |
| State D | 의미 |
| State E | 의미 |

표 2. State Machine State 신호 정의

## 5.2 시뮬레이션 시나리오

주요 동작 사항 list or table화

시뮬레이션 시나리오 1. 어떤 입력일 때 State가 어떻게 바뀌어서 출력이 어떻게 나오기를 기대한다.

## 5.3 Waveform 분석

- 입출력 파형 캡처 및 주석
- 주요 시뮬레이션 상세 파형 캡처 및 설명

시뮬레이션 시나리오 1번 시뮬레이션 결과. 기대한 State 변화와 출력이 이루어지는 것을 확인했다.

## 5.4 시뮬레이션 결과 요약 테이블

| 항목 | 목표치 (Spec) | 측정치 (Sim Result) | 달성 여부 |
| --- | --- | --- | --- |
| Tolerance | < 3% | 2% | 달성 |

(Tolerance 항목은 예시입니다)

# 6. 결과 분석 및 트러블슈팅 (Analysis & trouble shooting)

## 6.1 FPGA 결과

- 논리 합성 결과 분석
- 오차 분석(이론값과 시뮬레이션 결과 분석)
- Trade-off 분석 (예를 들어 속도를 높이기 위해 전력 소모가 얼마나 늘어났는지 등 설계 요소 간의 상관관계 고찰.)

## 6.2 문제 원인 분석

- 성공 / 실패 원인 정의

## 6.3 개선 방안

- 구조 개선 제안
- 추가 최적화 방향 제시

# 7. 결론

- 설계 성과 요약
- 학습 내용 정리

# 참고 문헌

- [0] Datasheet
- [1] Paper
- [2] Technical Document
