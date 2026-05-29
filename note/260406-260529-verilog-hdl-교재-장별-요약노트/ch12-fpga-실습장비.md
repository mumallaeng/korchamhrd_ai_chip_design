# CHAPTER 12 FPGA 실습장비

```table-of-contents
```

> Verilog HDL 교재 장별 강의 노트  
> 작성 기준: 교재 목차 + 현재 수업 실습 보드(Basys3) + 공개 참고 자료 재구성

## 이 장의 핵심

- FPGA 실습장비 장의 본질은 "코드가 실제 입출력 장치와 어떻게 이어지는가"를 배우는 데 있다.
- 실습 보드는 단순 부속품이 아니라 `클럭`, `리셋`, `스위치`, `버튼`, `LED`, `7-segment`, `제약조건`을 함께 묶는 학습 플랫폼이다.
- 현재 수업은 교재의 원 장비 대신 `Basys3`를 사용하므로, 실습 감각은 Basys3 기준으로 정리하는 편이 더 실용적이다.

## 세부 목차

1. FPGA 실습장비의 역할
2. 현재 수업의 Basys3 자원
3. 포트와 실제 핀의 연결
4. XDC의 의미
5. 보드 실습 시 주의점

## 한 줄 요약

12장은 Verilog 문법을 넘어서, 코드가 실제 보드 자원에 매핑되는 과정을 이해하는 장이다.

## 현재 수업과 연결

- Day 1의 Basys3 레퍼런스 매뉴얼 탐색
- Day 1의 XDC 작성
- Day 4~6의 FND, 스위치, LED, 버튼 연결

## 1. 실습장비를 왜 따로 배우는가

보드 실습에서는 논리식만 맞는다고 끝나지 않는다.

- 어느 핀이 클럭인지
- 어느 핀이 스위치인지
- 어느 핀이 LED인지
- 어떤 전압 표준을 써야 하는지

이 정보가 있어야 비로소 RTL이 보드에서 동작한다.

## 2. 현재 수업 기준 주요 보드 자원

현재 수업은 Digilent `Basys3`를 사용한다.

대표 자원:

- 100MHz 시스템 클럭
- 스위치
- 버튼
- LED
- 4-digit 7-segment display
- USB-JTAG 프로그래밍 인터페이스

### 형식만 먼저 보기

```text
Board resource
-> top module port
-> XDC PACKAGE_PIN
-> 실제 FPGA 핀
```

## 3. Top module과 보드 자원 연결

실습에서는 top module이 보드와 직접 맞닿는 계층이다.

### 문법만 먼저 보기

```verilog
module top (
    input        clk,
    input        rst,
    input  [2:0] sw,
    output [2:0] led
);
endmodule
```

### 예제

```verilog
module led_pass (
    input  [2:0] sw,
    output [2:0] led
);
    assign led = sw;
endmodule
```

### 해석

- 설계 모듈이 보드 자원을 직접 받으려면 포트 이름과 폭을 정확히 잡아야 한다.
- 이 포트가 XDC와 연결되어야 실제 스위치와 LED가 매칭된다.

## 4. XDC는 왜 필요한가

XDC는 Verilog 문법이 아니라 Vivado용 제약조건 파일이다.

### 형식만 먼저 보기

```tcl
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
```

### 예제

```tcl
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]

set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
```

### 해석

- `get_ports`는 Verilog top port를 찾는다.
- `PACKAGE_PIN`은 실제 FPGA 핀 위치를 지정한다.
- `IOSTANDARD`는 전기적 입출력 표준을 잡는다.
- 강의에서 I/O standard 누락 시 구현 에러가 나는 것도 확인했다.

## 5. FND 같은 복합 자원은 어떻게 읽어야 하는가

7-segment는 단순 LED 하나가 아니다.

- segment data
- digit common control
- 다중화 스캔

이 세 가지를 같이 봐야 한다.

### 형식만 먼저 보기

```text
value
-> digit_splitter
-> mux
-> bcd decoder
-> segment output

counter
-> digit select
-> decoder
-> common pins
```

### 해석

- FND 실습은 보드 자원 이해와 조합/순차회로 모델링이 합쳐진 과제다.
- 보드 장은 단순 장비 소개가 아니라 `시스템 연결 감각`을 배우는 장이다.

## 6. 버튼과 스위치의 차이

- 스위치: 유지형 입력
- 버튼: 순간 입력

실습에서는 버튼 바운스와 비동기 입력 문제도 고려해야 한다.

강의에서 CDC와 메타스테빌리티 이야기가 나온 이유도 외부 입력이 완전히 이상적인 클럭 신호가 아니기 때문이다.

## 7. 보드 실습 체크리스트

- top module 포트 이름과 폭이 맞는가
- XDC 핀 번호가 맞는가
- `IOSTANDARD`를 넣었는가
- reset, clock, switch polarity를 확인했는가
- FND가 common anode인지 common cathode인지 확인했는가

## 자주 하는 실수

- 보드 핀과 top module 포트를 맞추지 않는다.
- 클럭 핀과 일반 입력 핀을 구분하지 않는다.
- FND 구동에서 active low/active high를 헷갈린다.
- 보드 문제인지 RTL 문제인지 분리해서 보지 않는다.

## 복습 질문

1. 왜 FPGA 실습에는 XDC가 필요한가
2. top module은 왜 보드와 직접 맞닿는 계층인가
3. FND 제어가 단순 LED 제어와 다른 이유는 무엇인가
4. 버튼과 스위치 입력은 왜 같은 디지털 0/1로만 보면 부족한가

## 참고 출처

- Digilent Basys3 Reference Manual: https://digilent.com/reference/_media/reference/programmable-logic/basys-3/basys3_rm.pdf
- 한빛미디어 도서 소개: https://www.hanbit.co.kr/store/books/look.php?p_code=B7241537082
- 로컬 수업 메모: [[260406-logic-gate와-첫-시뮬레이션]], [[260406-260529-복습노트-03-basys3-xdc-constraints]]
