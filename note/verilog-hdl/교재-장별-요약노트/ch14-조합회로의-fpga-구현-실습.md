# CHAPTER 14 조합회로의 FPGA 구현 실습

## 세부 목차

- 14.1 기본 논리 게이트 설계
- 14.2 가산기와 감산기 회로 설계
- 14.3 멀티플렉서 설계
- 14.4 인코더와 디코더 설계

## 세부 목차 기준 포함 내용

- 14.1: gate-level 또는 assign 기반의 조합회로 출발점
- 14.2: half/full adder, subtractor 및 조합 산술 회로
- 14.3: 선택 신호 기반 경로 제어 실습
- 14.4: 입력 코드화/해독 회로를 FPGA에서 검증하는 실습

## 현재 수업과 연결

- `[[verilog-hdl_수업메모_01]]`
- `[[verilog-hdl_수업메모_02]]`
- `[[verilog-hdl_수업메모_03]]`
- `activities/korcham/notes/verilog-hdl/HelloVerilog/adder/`

## 핵심 요약

- 조합회로 FPGA 실습장은 앞선 문법 장과 모델링 장을 실제 보드 동작으로 연결하는 장이다.
- 기본 게이트, adder/subtractor, mux, encoder/decoder는 모두 `입력이 바뀌면 바로 출력이 바뀌는 회로`라는 공통점을 가진다.
- 실습에서는 HDL 코드, testbench, XDC, 보드 장치 연결이 모두 맞아야 최종 동작이 확인된다.
- 시뮬레이션은 논리 오류를, 보드 테스트는 핀 연결과 실사용 동작을 잡아준다.
- 이 장은 `조합회로는 상태 저장이 없다`는 사실을 실제 구현 경험으로 고정하는 장이다.

## 이 장에서 반드시 남길 메모

- adder와 mux를 현재 실습 프로젝트와 연결한다.
- 파형 검증과 보드 검증의 역할 차이를 따로 적는다.
- 조합회로에서는 reset보다 입력/출력 매핑과 논리식이 중요하다는 점을 적는다.

## 공개 보조 자료

- HDLBits hadd / fadd / mux 관련 문제
- Digilent Basys3 manual
