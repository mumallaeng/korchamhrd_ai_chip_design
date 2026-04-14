# CHAPTER 13 Vivado Design Suite 사용법

## 세부 목차

- 13.1 Xilinx Vivado 소프트웨어 개요
- 13.2 Vivado Project 생성
- 13.3 설계 입력
- 13.4 Behavioral 시뮬레이션
- 13.5 RTL 분석 및 설계 합성
- 13.6 설계 구현
- 13.7 Bitstream 생성 및 디바이스 프로그래밍

## 세부 목차 기준 포함 내용

- 13.1: Vivado IDE와 전체 설계 흐름
- 13.2: 프로젝트, 디바이스, 보드 선택
- 13.3: HDL, XDC, testbench 입력 구조
- 13.4: 시뮬레이션 실행과 파형 확인
- 13.5: RTL 분석, 합성 결과, 자원 사용
- 13.6: implementation, placement, routing, timing 확인
- 13.7: bitstream 생성과 board programming

## 현재 수업과 연결

- `[[verilog-hdl_수업메모_00]]`
- `[[verilog-hdl_수업메모_01]]`
- `[[verilog-hdl_복습노트_01_설계흐름]]`

## 핵심 요약

- 이 장은 Vivado IDE를 단순히 클릭 순서로 설명하는 것이 아니라, 도구가 설계 흐름의 각 단계를 어떻게 지원하는지 설명한다.
- Project 생성에서는 보드/디바이스 선택, 소스 등록, constraints 구성의 출발점을 만든다.
- Behavioral simulation은 논리 검증 단계이고, synthesis는 RTL을 논리 구조로 바꾸는 단계이며, implementation은 실제 FPGA 자원과 배선에 맞추는 단계다.
- bitstream 생성과 device programming은 구현 결과를 실제 하드웨어에 반영하는 마지막 단계다.
- 시뮬레이션과 synthesis/implementation 결과를 구분해 읽는 습관이 있으면 보드 디버깅 비용이 크게 줄어든다.

## 이 장에서 반드시 남길 메모

- Flow Navigator 순서를 한 번 더 정리한다.
- simulation, synthesis, implementation의 차이를 각각 한 줄로 적는다.
- 현재 강의에서 자주 쓰는 메뉴와 창을 따로 표시한다.

## 공개 보조 자료

- AMD UG892 design flow overview
- AMD Vivado design entry and implementation overview
