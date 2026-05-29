# CHAPTER 14 조합회로의 FPGA 구현 실습

```table-of-contents
```

> Verilog HDL 교재 장별 강의 노트  
> 작성 기준: 현재 수업의 조합회로 실습 흐름 + 공개 참고 자료 재구성

## 이 장의 핵심

- 조합회로 FPGA 실습은 `논리 정의 -> RTL -> testbench -> XDC -> 보드 검증`의 흐름으로 본다.
- 작은 조합 블록을 먼저 검증한 뒤 상위 시스템으로 묶는 습관이 중요하다.
- FND, decoder, mux 같은 실습은 조합회로와 보드 자원 이해를 동시에 요구한다.

## 세부 목차

1. 조합회로 실습 흐름
2. 단일 블록 검증
3. 상위 모듈 통합
4. XDC 적용
5. 보드 검증

## 한 줄 요약

14장은 조합회로를 "코드로만 끝내지 않고 실제 FPGA 보드에서 확인하는 법"을 정리하는 실습 장이다.

## 현재 수업과 연결

- Day 1의 gates 실습
- Day 2의 half/full adder
- Day 3의 8bit adder, BCD, mux, decoder, FND controller

## 1. 조합회로 실습의 기본 흐름

### 형식만 먼저 보기

```text
문제 정의
-> truth table / block diagram
-> RTL 작성
-> testbench 작성
-> simulation
-> top + XDC 연결
-> implementation / bitstream
-> board test
```

### 해석

- 조합회로라 해도 보드에 올리면 핀과 입출력 장치까지 같이 봐야 한다.
- 그래서 설계/검증/연결/하드웨어 확인이 모두 한 세트다.

## 2. 작은 블록부터 검증하기

예를 들어 `mux_4x1`과 `decoder_2x4`를 먼저 따로 검증하는 식이다.

### 문법만 먼저 보기

```verilog
module block (...);
endmodule

module tb_block;
    ...
endmodule
```

### 예제

```verilog
module decoder_2x4 (
    input  [1:0] sel,
    output reg [3:0] out
);
    always @(*) begin
        case (sel)
            2'b00: out = 4'b1110;
            2'b01: out = 4'b1101;
            2'b10: out = 4'b1011;
            2'b11: out = 4'b0111;
            default: out = 4'b1111;
        endcase
    end
endmodule
```

### 해석

- 단독 블록 검증을 먼저 하면 통합 시 디버깅 범위를 줄일 수 있다.
- 강의에서 구조적 모델링을 강조한 이유와 연결된다.

## 3. 상위 모듈 통합

실습에서는 조합 블록들을 상위 모듈에서 엮는다.

### 형식만 먼저 보기

```verilog
module top (...);
    wire ...;
    block_a u0 (...);
    block_b u1 (...);
endmodule
```

### 예제

```verilog
module adder_display_top (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] sum
);
    assign sum = a + b;
endmodule
```

### 해석

- 실제 수업에서는 여기에 `digit_splitter`, `mux`, `bcd decoder`, `decoder_2x4`가 더 붙는다.
- 상위 모듈은 계산보다 연결 책임이 크다.

## 4. 테스트벤치에서 확인해야 할 것

- 입력 조합별 출력이 맞는가
- 경계조건이 맞는가
- `x`, `z`가 퍼지지 않는가
- default 처리 누락이 없는가

### 문법만 먼저 보기

```verilog
initial begin
    ...
    #10;
    ...
    $finish;
end
```

### 예제

```verilog
module tb_decoder;
    reg  [1:0] sel;
    wire [3:0] out;

    decoder_2x4 dut (.sel(sel), .out(out));

    initial begin
        sel = 2'b00;
        #10 sel = 2'b01;
        #10 sel = 2'b10;
        #10 sel = 2'b11;
        #10 $finish;
    end
endmodule
```

### 해석

- 조합회로는 클럭이 없어도 입력 조합을 체계적으로 훑어야 한다.
- 파형과 텍스트 로그를 같이 쓰면 더 좋다.

## 5. XDC와 보드 연결

조합회로라도 보드에 올리려면 핀 매핑이 필요하다.

### 형식만 먼저 보기

```tcl
set_property PACKAGE_PIN ... [get_ports ...]
set_property IOSTANDARD LVCMOS33 [get_ports ...]
```

### 해석

- Gates 실습처럼 스위치 입력을 LED 출력으로 연결하는 단순 회로도 XDC 없이는 동작하지 않는다.

## 6. FND 기반 조합 실습의 의미

FND 실습은 조합회로가 보드 실습에서 어떻게 커지는지를 보여 준다.

- 숫자 분리
- 선택
- 디코딩
- 공통단자 제어

이 과정이 각각 독립 조합 블록으로 나뉜다.

## 7. 제출 산출물 관점에서 보기

조합회로 실습 보고서는 보통 다음을 포함하면 좋다.

- 블록 다이어그램
- RTL 코드 요약
- 테스트벤치 시나리오
- 파형 캡처
- XDC 연결 요약
- 보드 동작 사진 또는 영상

## 자주 하는 실수

- 작은 블록을 따로 검증하지 않고 바로 통합한다.
- 조합회로인데 래치를 만든다.
- testbench 없이 보드에서만 확인하려 한다.
- active low FND 출력을 반대로 해석한다.

## 복습 질문

1. 조합회로 실습은 왜 블록별 검증이 중요한가
2. 상위 모듈과 하위 모듈의 역할 차이는 무엇인가
3. FND 기반 조합 실습은 왜 단순 gate 실습보다 어렵나
4. 보드 실습 보고서에는 무엇이 들어가야 하는가

## 참고 출처

- Digilent Basys3 Reference Manual: https://digilent.com/reference/_media/reference/programmable-logic/basys-3/basys3_rm.pdf
- AMD Vivado Design Flows Overview (UG892): https://docs.amd.com/r/2024.2-English/ug892-vivado-design-flows-overview
- 로컬 수업 메모: [[260406-logic-gate와-첫-시뮬레이션]], [[260407-adder와-첫-fnd-표시]], [[260408-8bit-adder와-fnd-controller]], [[260409-합성-구조-확장-fnd-시스템]]
