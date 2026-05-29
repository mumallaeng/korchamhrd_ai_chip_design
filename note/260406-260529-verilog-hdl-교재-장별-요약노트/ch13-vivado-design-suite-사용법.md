# CHAPTER 13 Vivado Design Suite 사용법

```table-of-contents
```

> Verilog HDL 교재 장별 강의 노트  
> 작성 기준: 현재 수업의 Vivado 2020.2 실습 흐름 + 공개 공식 문서 재구성

## 이 장의 핵심

- Vivado는 단순 편집기가 아니라 `설계 입력`, `시뮬레이션`, `합성`, `구현`, `프로그램 다운로드`를 묶은 전체 설계 환경이다.
- GUI 흐름을 먼저 익히되, 어떤 단계가 어떤 결과물을 만드는지 같이 이해해야 한다.
- `Open Elaborated Design`, `Synthesis`, `Implementation`, `Generate Bitstream`, `Hardware Manager`는 서로 다른 목적을 가진다.

## 세부 목차

1. 프로젝트 생성
2. Design Sources / Simulation Sources / Constraints
3. 시뮬레이션
4. 합성 / 구현 / 비트스트림
5. Hardware Manager

## 한 줄 요약

13장은 Vivado 메뉴를 외우는 장이 아니라, Verilog RTL이 FPGA 다운로드 파일로 바뀌는 단계별 의미를 익히는 장이다.

## 현재 수업과 연결

- Day 1의 Vivado 설치와 프로젝트 생성
- Day 1~2의 시뮬레이션 실행
- Day 1의 Synthesis, Implementation, Bitstream 생성
- Day 6 이후 과제 제출용 보드 동작 확인

## 1. 프로젝트 생성

프로젝트 생성 시 가장 먼저 정해야 하는 것은 보드/디바이스와 파일 구조다.

### 형식만 먼저 보기

```text
Create Project
-> RTL Project
-> Add Sources
-> Add Constraints
-> Select Board / Part
```

### 해석

- 초반에는 Board 기준 선택이 더 쉽다.
- 수업에서는 Basys3와 Vivado 2020.2 조합을 기준으로 맞췄다.
- 경로에 공백, 한글, 불필요한 동기화 폴더를 피하는 습관이 좋다.

## 2. Source 종류 구분

Vivado 안에서는 소스 종류를 구분해서 관리한다.

- Design Sources
- Simulation Sources
- Constraints

### 형식만 먼저 보기

```text
Design Source      = 합성 대상 RTL
Simulation Source  = testbench
Constraints        = XDC
```

### 해석

- 이 구분이 흐려지면 테스트벤치가 합성 대상에 섞이거나, top module이 꼬이기 쉽다.

## 3. Elaborated Design

RTL 구조를 먼저 눈으로 확인하는 단계다.

### 형식만 먼저 보기

```text
RTL Analysis
-> Open Elaborated Design
```

### 해석

- 소스 코드가 계층적으로 어떻게 해석되었는지 볼 수 있다.
- 작성한 구조와 도식이 맞는지 빠르게 확인하는 데 좋다.
- 강의에서 "작성한 코드와 합성 결과가 꼭 똑같지 않을 수 있다"는 설명과 연결된다.

## 4. 시뮬레이션

보드에 올리기 전에 기능 검증을 한다.

### 형식만 먼저 보기

```text
Run Simulation
-> Open Waveform
-> Zoom Fit
```

### 예제

```verilog
module tb;
    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;
endmodule
```

### 해석

- 시뮬레이션은 입력 자극과 시간 흐름을 가장 싸게 검증하는 단계다.
- 파형 해석을 먼저 하고 보드에 올리는 습관이 중요하다.

## 5. 합성

HDL을 논리 회로 구조로 바꾼다.

### 형식만 먼저 보기

```text
Run Synthesis
-> Reports
-> Schematic / Utilization
```

### 해석

- 논리 최적화가 일어나므로, 코드 구조와 결과 구조가 완전히 같지 않을 수 있다.
- 자원 사용량과 경고 메시지를 같이 봐야 한다.

## 6. 구현

합성된 회로를 실제 FPGA 자원에 배치/배선한다.

### 형식만 먼저 보기

```text
Run Implementation
-> placement
-> routing
```

### 해석

- 이 단계에서 제약조건 오류나 타이밍 문제가 더 잘 드러난다.
- 강의에서 본 I/O standard 누락 오류도 구현 단계와 밀접하다.

## 7. 비트스트림 생성과 프로그램 다운로드

### 형식만 먼저 보기

```text
Generate Bitstream
-> Open Hardware Manager
-> Program Device
```

### 해석

- bitstream은 FPGA를 설정하는 최종 파일이다.
- 여기까지 와야 보드에서 실제 동작을 볼 수 있다.

## 8. TCL 형태를 최소한으로 보기

GUI를 주로 써도 흐름을 명령형으로 보는 감각이 있으면 좋다.

### 형식만 먼저 보기

```tcl
read_verilog top.v
read_xdc top.xdc
synth_design -top top
place_design
route_design
write_bitstream -force top.bit
```

### 해석

- 내부적으로는 이런 흐름이 돌아간다고 생각하면 된다.
- 초반엔 GUI 중심으로 익혀도 충분하다.

## 9. Vivado 사용 시 실전 체크리스트

- top module이 맞는가
- testbench가 Design Source에 섞이지 않았는가
- XDC가 적용되었는가
- 시뮬레이션을 먼저 통과했는가
- 합성 경고와 구현 경고를 읽었는가

## 자주 하는 실수

- 프로젝트 구조를 이해하지 못하고 파일만 추가한다.
- Elaborated Design과 Synthesis 결과를 같은 것으로 본다.
- 시뮬레이션 없이 bitstream부터 만든다.
- Constraints 누락 상태로 implementation을 돌린다.

## 복습 질문

1. Design Source와 Simulation Source는 왜 나누는가
2. Elaborated Design은 무엇을 보여 주는가
3. 합성과 구현은 어떻게 다른가
4. bitstream 생성 전 반드시 확인해야 하는 것은 무엇인가

## 참고 출처

- AMD Vivado Design Flows Overview (UG892): https://docs.amd.com/r/2024.2-English/ug892-vivado-design-flows-overview
- AMD Vivado Design Suite User Guide: Synthesis (UG901): https://docs.amd.com/r/2024.2-English/ug901-vivado-synthesis
- 한빛미디어 도서 소개: https://www.hanbit.co.kr/store/books/look.php?p_code=B7241537082
- 로컬 수업 메모: [[260406-logic-gate와-첫-시뮬레이션]], [[260406-260529-복습노트-01-설계흐름]]
