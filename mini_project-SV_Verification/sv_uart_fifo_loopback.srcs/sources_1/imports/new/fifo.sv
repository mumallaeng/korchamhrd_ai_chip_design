`timescale 1ns / 1ps

module fifo #(
    parameter int DEPTH = 16
) (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] push_data,
    input  logic       push,
    input  logic       pop,
    output logic [7:0] pop_data,
    output logic       empty,
    output logic       full
);

    localparam int ADDR_WIDTH = $clog2(DEPTH);

    // 상위 FIFO는
    // 1) 데이터를 저장하는 register_file
    // 2) 포인터와 상태 플래그를 관리하는 control_unit
    // 으로 나뉜다.
    logic [ADDR_WIDTH-1:0] wptr;
    logic [ADDR_WIDTH-1:0] rptr;

    register_file #(
        .DEPTH(DEPTH)
    ) u_register_file (
        .*,
        .wdata(push_data),
        .waddr(wptr),
        .raddr(rptr),
        .we   (~full & push),  // full이 아니면서 push가 들어올 때만 write enable
        .rdata(pop_data)
    );

    control_unit #(.DEPTH(DEPTH)) u_control_unit (.*);
endmodule


module register_file #(
    parameter int DEPTH = 16
) (
    input  logic                     clk,
    input  logic [              7:0] wdata,
    input  logic [$clog2(DEPTH)-1:0] waddr,
    input  logic [$clog2(DEPTH)-1:0] raddr,
    input  logic                     we,
    output logic [              7:0] rdata
);

    // 단순 single-port 저장소
    // - write는 clock edge에서 수행
    // - read는 조합회로 방식으로 바로 출력
    logic [7:0] reg_file[0:DEPTH-1];

    always_ff @(posedge clk) begin
        if (we) begin
            reg_file[waddr] <= wdata;
        end
    end

    always_comb rdata = reg_file[raddr];

endmodule


module control_unit #(
    parameter int DEPTH = 16
) (
    input  logic                     clk,
    input  logic                     rst,
    input  logic                     push,
    input  logic                     pop,
    output logic [$clog2(DEPTH)-1:0] wptr,
    output logic [$clog2(DEPTH)-1:0] rptr,
    output logic                     full,
    output logic                     empty
);

    localparam int ADDR_WIDTH = $clog2(DEPTH);

    logic [ADDR_WIDTH-1:0] wptr_reg, wptr_next;
    logic [ADDR_WIDTH-1:0] rptr_reg, rptr_next;
    logic full_reg, full_next;
    logic empty_reg, empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wptr_reg  <= '0;
            rptr_reg  <= '0;
            full_reg  <= 1'b0;
            empty_reg <= 1'b1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always_comb begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;

        unique case ({
            push, pop
        })
            2'b10: begin
                // push만 들어오면, 가득 차지 않았을 때 write 포인터를 증가시킨다.
                if (!full_reg) begin
                    wptr_next  = wptr_reg + 1'b1;
                    // wptr_next  = wptr_reg++; // ++은 읽는 것 말고도 값 자체를 갱신까지 해버림
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg) full_next = 1'b1;
                end
            end

            2'b01: begin
                // pop만 들어오면, 비어 있지 않을 때 read 포인터를 증가시킨다.
                if (!empty_reg) begin
                    rptr_next = rptr_reg + 1'b1;
                    full_next = 1'b0;
                    if (rptr_next == wptr_reg) empty_next = 1'b1;
                end
            end

            2'b11: begin
                // push와 pop이 동시에 들어오면
                // - full이면 pop만 처리
                // - empty면 push만 처리
                // - 그 외에는 두 포인터를 함께 이동
                if (full_reg) begin
                    rptr_next = rptr_reg + 1'b1;
                    full_next = 1'b0;
                end else if (empty_reg) begin
                    wptr_next  = wptr_reg + 1'b1;
                    empty_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1'b1;
                    rptr_next = rptr_reg + 1'b1;
                end
            end

            default: begin
            end
        endcase
    end

endmodule
