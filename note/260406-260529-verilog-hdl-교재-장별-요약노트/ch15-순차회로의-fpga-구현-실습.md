# CHAPTER 15 순차회로의 FPGA 구현 실습

```table-of-contents
```

> Verilog HDL 교재 장별 강의 노트  
> 작성 기준: 현재 수업의 counter / control / FSM 실습 + 공개 참고 자료 재구성

## 이 장의 핵심

- 순차회로 FPGA 실습은 조합회로 실습보다 `클럭`, `리셋`, `상태`, `시간`을 더 엄격하게 다룬다.
- 카운터, tick generator, FSM은 보드에서 실제로 동작을 확인하기 좋은 대표 예제다.
- 시뮬레이션과 보드 검증 사이의 차이를 이해해야 한다.
- 순차회로 실습 보고서는 `상태 변화 근거`를 보여 주는 것이 중요하다.

## 세부 목차

1. 순차 실습 흐름
2. 카운터 기반 실습
3. FSM 기반 실습
4. 테스트벤치와 보드 검증의 차이
5. 보고서 관점의 정리

## 한 줄 요약

15장은 "기억하는 회로"를 보드에서 확인하는 장이다. 조합회로 때보다 시간 축 검증과 상태 해석이 훨씬 중요해진다.

## 현재 수업과 연결

- Day 4의 tick generator / tick counter
- Day 5의 control unit, up/down counter, latch/flip-flop 개념
- Day 6의 `fsm_led`

## 1. 순차 실습의 기본 흐름

### 형식만 먼저 보기

```text
상태/동작 정의
-> state diagram or timing intent
-> RTL 작성
-> testbench 작성
-> simulation
-> top + XDC 연결
-> board test
-> report
```

### 해석

- 조합회로 실습보다 상태 정의가 먼저 와야 한다.
- 특히 FSM은 상태도와 천이 조건을 먼저 적는 편이 훨씬 안정적이다.

## 2. 카운터 실습

가장 대표적인 순차회로 실습이다.

### 문법만 먼저 보기

```verilog
always @(posedge clk or posedge rst) begin
    if (rst)
        q <= 0;
    else
        q <= q + 1'b1;
end
```

### 예제

```verilog
module tick_counter (
    input        clk,
    input        rst,
    input        en,
    output reg [13:0] q
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= 14'd0;
        else if (en) begin
            if (q == 14'd9999)
                q <= 14'd0;
            else
                q <= q + 1'b1;
        end
    end
endmodule
```

### 해석

- Day 4~5의 카운터 실습과 거의 같은 틀이다.
- enable, reset, wrap-around 조건이 모두 순차 로직의 일부다.

## 3. FSM 실습

상태를 명시적으로 다루는 대표 예제다.

### 문법만 먼저 보기

```verilog
always @(posedge clk or posedge rst) begin
    ...
end

always @(*) begin
    ...
end
```

### 예제

```verilog
module fsm_led (
    input        clk,
    input        rst,
    input  [2:0] sw,
    output reg [2:0] led
);
    localparam STATE_A = 3'd0,
               STATE_B = 3'd1,
               STATE_C = 3'd2,
               STATE_D = 3'd3,
               STATE_E = 3'd4;

    reg [2:0] current_state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= STATE_A;
        else
            current_state <= next_state;
    end

    always @(*) begin
        next_state = current_state;

        case (current_state)
            STATE_A: if (sw == 3'b001) next_state = STATE_B;
            STATE_B: if (sw == 3'b010) next_state = STATE_C;
            STATE_C: if (sw == 3'b100) next_state = STATE_D;
            default: next_state = STATE_A;
        endcase
    end

    always @(*) begin
        case (current_state)
            STATE_A: led = 3'b001;
            STATE_B: led = 3'b010;
            STATE_C: led = 3'b011;
            STATE_D: led = 3'b100;
            STATE_E: led = 3'b101;
            default: led = 3'b000;
        endcase
    end
endmodule
```

### 해석

- 상태 저장, next-state 계산, 출력 decode를 분리했다.
- Day 6 과제 보고서와 직접 연결되는 구조다.
- 보드에서는 LED 패턴으로 상태를 관찰할 수 있다.

## 4. 테스트벤치에서 무엇을 검증해야 하는가

- reset 후 시작 상태
- 각 천이 조건
- hold 조건
- 경계조건
- 예외 입력 처리

### 문법만 먼저 보기

```verilog
initial begin
    ...
    @(posedge clk);
    ...
end
```

### 예제

```verilog
initial begin
    rst = 1'b1;
    sw  = 3'b000;
    #12 rst = 1'b0;

    sw = 3'b001;
    @(posedge clk);

    sw = 3'b010;
    @(posedge clk);

    $finish;
end
```

### 해석

- FSM은 단순 시간 지연보다 클럭 엣지 기준으로 검증하는 것이 읽기 쉽다.
- 상태 변화가 언제 반영되는지 더 명확하게 보인다.

## 5. 보드 검증은 왜 별도로 필요한가

시뮬레이션이 통과해도 보드에서는 다른 문제가 생길 수 있다.

- 핀 연결 오류
- 버튼/스위치 극성 해석 오류
- 외부 입력 타이밍 문제
- 클럭 분주가 체감상 너무 빠르거나 느린 문제

즉 "파형이 맞다"와 "보드가 사람이 보기 좋게 동작한다"는 별개의 검증이다.

## 6. 보고서에 무엇을 보여줘야 하는가

순차회로 실습 보고서는 조합회로보다 다음 항목이 더 중요하다.

- 상태도
- reset 시점
- 상태 천이 표
- 파형에서 상태 변화 구간
- 보드 사진/영상

`fsm_led`처럼 상태 기반 실습은 "왜 그렇게 바뀌는지"를 설명할 수 있어야 한다.

## 7. 순차 실습에서 자주 생기는 실제 문제

- reset이 기대대로 안 먹는다
- blocking / non-blocking 혼용
- state와 output decode를 한 블록에 뒤엉키게 쓴다
- 외부 입력이 비동기인데 그대로 샘플링한다

## 자주 하는 실수

- 카운터와 FSM을 조합논리처럼 읽는다.
- 테스트벤치에서 클럭 기준 검증을 하지 않는다.
- 리셋 동작을 파형에서 확인하지 않는다.
- 상태도 없이 FSM을 바로 코드로 쓰기 시작한다.

## 복습 질문

1. 순차회로 실습은 왜 상태 정의가 먼저 와야 하는가
2. 카운터와 FSM 검증에서 공통적으로 중요한 것은 무엇인가
3. 시뮬레이션 검증과 보드 검증은 어떻게 다른가
4. 순차회로 실습 보고서에 반드시 들어가야 할 것은 무엇인가

## 참고 출처

- Digilent Basys3 Reference Manual: https://digilent.com/reference/_media/reference/programmable-logic/basys-3/basys3_rm.pdf
- AMD Vivado Design Flows Overview (UG892): https://docs.amd.com/r/2024.2-English/ug892-vivado-design-flows-overview
- 로컬 수업 메모 및 보고서: [[260409-합성-구조-확장-fnd-시스템]], [[260410-control-unit-datapath-timing]], [[260413-반복문-이벤트제어-tb-rtl]], [[260413-day06-complete-report]]
