# CHAPTER 15 순차회로의 FPGA 구현 실습

## 세부 목차

- 15.1 플립플롭과 시프트 레지스터 설계
- 15.2 계수기 설계
- 15.3 주파수 분주기 설계
- 15.4 키패드 스캔 회로 설계
- 15.5 Piezo 응용회로 설계
- 15.6 스텝 모터 구동회로 설계
- 15.7 Color LED 디스플레이 회로 설계
- 15.8 Text LCD 문자 디스플레이 회로 설계

## 세부 목차 기준 포함 내용

- 15.1: 상태 저장과 시프트 동작을 보드로 검증하는 기본 순차회로
- 15.2: up/down, enable, reset을 갖는 계수기
- 15.3: 시스템 클럭을 사람이 다룰 수 있는 느린 동작으로 만드는 divider
- 15.4: 입력 스캔과 상태 처리 결합 예제
- 15.5: timing 기반 출력 제어 응용
- 15.6: 상태 천이와 구동 순서가 중요한 actuator 제어
- 15.7: PWM 또는 색 제어 기반의 출력 응용
- 15.8: 문자 표시 장치와 타이밍/인터페이스 제어

## 현재 수업과 연결

- `[[verilog-hdl_수업메모_04]]`
- `[[verilog-hdl_수업메모_05]]`
- `[[verilog-hdl_수업메모_06]]`
- `activities/korcham/notes/verilog-hdl/HelloVerilog/counter_10000/`
- `activities/korcham/notes/verilog-hdl/HelloVerilog/fsm_led/`

## 핵심 요약

- 순차회로 FPGA 실습장은 저장소자, 클럭, reset, timing, 상태 전이를 실제 과제로 묶어 경험하게 하는 장이다.
- 플립플롭, 시프트 레지스터, counter, divider는 모두 시간 축 위에서 상태가 바뀌는 회로다.
- keypad scan, piezo, step motor, color LED, text LCD 같은 응용은 단순 문법이 아니라 `시간 순서에 따른 제어` 문제로 이해해야 한다.
- counter와 FSM은 현재 강의 범위와 가장 직접적으로 이어지며, divider는 사람이 볼 수 있는 속도로 동작을 낮추는 실습에서 중요하다.
- 이 장의 핵심은 `순차회로는 파형과 상태 전이를 함께 봐야 한다`는 점을 보드 실습으로 체득하는 데 있다.

## 이 장에서 반드시 남길 메모

- counter, divider, FSM을 현재 강의 실습과 바로 연결한다.
- `clk`, `rst`, `enable/tick`, `state` 의 역할을 따로 적는다.
- 주변장치 응용은 나중 단계로 미루되, 모두 `상태 기반 제어`로 묶인다는 점을 메모한다.

## 공개 보조 자료

- HDLBits sequential logic / FSM
- Digilent Basys3 manual
- AMD Vivado implementation flow docs
