# CHAPTER 01 Verilog HDL의 개요

```table-of-contents
```

> Verilog HDL 교재 장별 강의 노트  
> 작성 기준: 교재 목차 + 수업 메모 + 공개 참고 자료 재구성

## 이 장의 핵심

- Verilog HDL은 소프트웨어 실행문이 아니라 `하드웨어 구조와 동작을 기술하는 언어`다.
- 실습의 기본 흐름은 `RTL 작성 -> 시뮬레이션 -> 합성 -> 구현 -> 비트스트림 생성 -> 보드 다운로드`다.
- 설계 코드와 테스트벤치는 역할이 다르며 처음부터 분리해서 생각해야 한다.
- HDL에서는 `구조`, `동시성`, `시간`, `검증`을 같이 본다.

## 세부 목차

1. Verilog HDL이 무엇인지
2. HDL 기반 설계 흐름
3. 설계 소스와 테스트벤치
4. 모델링 관점의 큰 분류
5. 첫 실습에서 보는 Vivado 흐름

## 한 줄 요약

1장은 Verilog 문법을 깊게 다루기보다, 왜 HDL이 필요한지와 Verilog 코드를 실제 FPGA 동작으로 연결하는 전체 흐름을 잡는 장이다.

## 현재 수업과 연결

- Day 1의 `gates.v`, `tb_gates.v`, Basys3 XDC, bitstream 생성 흐름과 직접 연결된다.
- 이후 모든 장에서 반복되는 `Design Source / Simulation Source / Constraints / Hardware Manager` 구조의 출발점이다.

## 1. Verilog HDL이 무엇인가

Verilog HDL은 디지털 회로를 기술하는 언어다.  
중요한 점은, C처럼 "명령을 실행"하는 언어로만 보면 자꾸 헷갈린다는 것이다.

HDL에서는 보통 아래를 같이 표현한다.

- 어떤 입출력이 있는가
- 어떤 논리 관계가 있는가
- 어떤 신호가 시간에 따라 바뀌는가
- 어떤 하위 블록들로 구성되는가

즉 Verilog는 `회로의 모양`과 `회로의 동작`을 함께 적는 언어다.

### 문법만 먼저 보기

```verilog
module module_name (
    input  a,
    input  b,
    output y
);
    assign y = a & b;
endmodule
```

### 예제

```verilog
module gates (
    input  a,
    input  b,
    output y_and,
    output y_or,
    output y_xor
);
    assign y_and = a & b;
    assign y_or  = a | b;
    assign y_xor = a ^ b;
endmodule
```

### 해석

- `module`은 하나의 회로 블록이다.
- `input`, `output`은 외부와 연결되는 포트다.
- `assign`은 조합논리를 연속적으로 연결한다.
- 코드는 짧지만 실제로는 세 개의 서로 다른 논리 게이트 회로를 뜻한다.

## 2. HDL 기반 설계 흐름

수업에서 가장 먼저 잡아야 하는 그림은 전체 설계 흐름이다.

### 형식만 먼저 보기

```text
RTL 작성
-> 시뮬레이션
-> 합성
-> 구현
-> 비트스트림 생성
-> FPGA 다운로드
```

### 예제: 현재 수업 기준 흐름

```text
gates.v 작성
-> tb_gates.v 작성
-> Run Simulation
-> Run Synthesis
-> Run Implementation
-> Generate Bitstream
-> Program Device
```

### 해석

- 시뮬레이션은 논리 검증 단계다.
- 합성은 HDL을 논리 회로 구조로 바꾸는 단계다.
- 구현은 FPGA 자원 위에 실제로 배치/배선하는 단계다.
- 비트스트림은 보드에 다운로드할 최종 설정 파일이다.

## 3. 설계 소스와 테스트벤치의 역할

처음부터 분리해서 이해해야 이후 장에서 덜 꼬인다.

- 설계 소스: 합성 대상 RTL
- 테스트벤치: 입력을 만들고 결과를 확인하는 검증 코드

### 문법만 먼저 보기

설계 모듈:

```verilog
module dut (...);
endmodule
```

테스트벤치:

```verilog
module tb;
    reg  a, b;
    wire y;

    dut uut (...);

    initial begin
        ...
    end
endmodule
```

### 예제

```verilog
module tb_gates;
    reg  a, b;
    wire y_and, y_or, y_xor;

    gates dut (
        .a    (a),
        .b    (b),
        .y_and(y_and),
        .y_or (y_or),
        .y_xor(y_xor)
    );

    initial begin
        a = 1'b0; b = 1'b0;
        #10 a = 1'b0; b = 1'b1;
        #10 a = 1'b1; b = 1'b0;
        #10 a = 1'b1; b = 1'b1;
        #10 $finish;
    end
endmodule
```

### 해석

- 테스트벤치는 DUT를 실체화해서 입력을 준다.
- `#10`은 시뮬레이션 시간 지연이다.
- `$finish`는 시뮬레이션 종료용 시스템 태스크다.
- 이런 문법은 검증용이며 그대로 FPGA 하드웨어가 되는 것은 아니다.

## 4. 시간 단위와 시뮬레이션 감각

시뮬레이션에서는 시간 단위와 정밀도를 지정한다.

### 문법만 먼저 보기

```verilog
`timescale 1ns / 1ps
```

### 예제

```verilog
`timescale 1ns / 1ps

module tb_clock;
    reg clk;

    initial clk = 1'b0;
    always #5 clk = ~clk;
endmodule
```

### 해석

- 앞의 `1ns`는 기본 시간 단위다.
- 뒤의 `1ps`는 더 세밀한 해석 정밀도다.
- `always #5 clk = ~clk;`는 주기 10ns의 클럭을 만드는 대표적인 테스트벤치 문장이다.

## 5. 모델링 관점의 큰 분류

Verilog에서는 같은 회로도 여러 관점으로 기술할 수 있다.

- 게이트 수준 모델링
- 데이터흐름 모델링
- 행위수준 모델링
- 구조적 모델링

### 형식만 먼저 보기

```text
게이트 수준: gate primitive
데이터흐름: assign
행위수준: always / initial
구조적: module instantiation
```

### 예제 비교

```verilog
// dataflow
assign y = a & b;

// behavioral
always @(*) begin
    y = a & b;
end
```

### 해석

- 결과는 같은 AND 게이트여도 표현 방식은 다를 수 있다.
- 어떤 표현이 맞는지는 회로의 복잡도와 계층에 따라 달라진다.
- 이후 장들이 사실상 이 네 관점을 하나씩 확장하는 구조다.

## 6. 첫 실습에서 반드시 남겨야 할 감각

- HDL은 소스 코드이지만 목적은 회로다.
- 시뮬레이션 없이 보드에 바로 올리는 습관은 좋지 않다.
- XDC 없이는 설계 포트가 실제 핀과 연결되지 않는다.
- Vivado는 코드 편집기가 아니라 `설계/검증/구현 환경`이다.

## 자주 하는 실수

- 테스트벤치와 설계 소스를 구분하지 못한다.
- 합성과 구현을 같은 단계로 생각한다.
- `#delay`가 실제 하드웨어 지연을 그대로 뜻한다고 착각한다.
- bitstream 생성 전 단계에서 나온 경고를 무시한다.

## 복습 질문

1. 설계 소스와 테스트벤치의 역할 차이는 무엇인가
2. 시뮬레이션과 합성은 무엇이 다른가
3. `timescale 1ns / 1ps`는 각각 무엇을 뜻하는가
4. 왜 FPGA 실습에서 XDC가 필요한가

## 참고 출처

- 한빛미디어 도서 소개: https://www.hanbit.co.kr/store/books/look.php?p_code=B7241537082
- Google Books 도서 정보: https://books.google.com/books/about/Verilog_HDL_%EC%84%A4%EA%B3%84_Vivado%EC%99%80_FPGA%EB%A5%BC_%EC%9D%B4.html?id=ph7HEAAAQBAJ
- AMD Vivado Design Flows Overview (UG892): https://docs.amd.com/r/2024.2-English/ug892-vivado-design-flows-overview
- Digilent Basys3 Reference Manual: https://digilent.com/reference/_media/reference/programmable-logic/basys-3/basys3_rm.pdf
- 로컬 수업 메모: [[260406-logic-gate와-첫-시뮬레이션]], [[260406-260529-복습노트-01-설계흐름]]
