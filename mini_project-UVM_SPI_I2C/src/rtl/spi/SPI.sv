// SPI 1 Controller : 1 Target 기본 top
// Controller와 Target을 같은 simulation top 안에서 직접 연결한다.

`timescale 1ns / 1ps

module SPI #(
    parameter int DATA_W = 8,
    parameter int CLK_DIV_W = 16,
    parameter int CLK_DIV_INIT = 50
) (
    // 공통 입력
    input logic clk,
    input logic reset_n,

    // Controller 설정 및 command
    input logic                 cpol,
    input logic                 cpha,
    input logic [CLK_DIV_W-1:0] clk_div,
    input logic                 start,
    input logic [DATA_W-1:0]    ctrl_tx_data,

    // Controller 결과
    output logic              ctrl_busy,
    output logic              ctrl_done,
    output logic [DATA_W-1:0] ctrl_rx_data,
    output logic              ctrl_rx_valid,

    // Target 데이터 및 결과
    input  logic [DATA_W-1:0] target_tx_data,
    output logic              target_selected,
    output logic [DATA_W-1:0] target_rx_data,
    output logic              target_rx_valid,

    // 공유 SPI 신호 및 debug
    output logic sclk,
    output logic cs_n,
    output logic ctrl_sdo,
    output logic ctrl_sdi,
    output logic tgt_sdo,
    output logic tgt_sdo_oe
);

    always_comb begin
        ctrl_sdi = 1'b1;

        if ((cs_n == 1'b0) && tgt_sdo_oe) begin
            ctrl_sdi = tgt_sdo;
        end
    end

    SPI_controller #(
        .DATA_W      (DATA_W),
        .CLK_DIV_W   (CLK_DIV_W),
        .CLK_DIV_INIT(CLK_DIV_INIT)
    ) u_spi_controller (
        // 공통 입력
        .clk      (clk),
        .reset_n  (reset_n),

        // SPI 설정
        .cpol     (cpol),
        .cpha     (cpha),
        .clk_div  (clk_div),

        // SPI 외부 신호
        .sclk     (sclk),
        .cs_n     (cs_n),
        .ctrl_sdi (ctrl_sdi),
        .ctrl_sdo (ctrl_sdo),

        // transaction 제어 신호
        .start    (start),
        .tx_data  (ctrl_tx_data),
        .busy     (ctrl_busy),
        .done     (ctrl_done),
        .rx_data  (ctrl_rx_data),
        .rx_valid (ctrl_rx_valid)
    );

    SPI_target #(
        .DATA_W(DATA_W)
    ) u_spi_target (
        // 공통 입력
        .clk       (clk),
        .reset_n   (reset_n),

        // SPI 설정
        .cpol      (cpol),
        .cpha      (cpha),

        // Target 송신 데이터
        .tx_data   (target_tx_data),

        // SPI 외부 신호
        .sclk      (sclk),
        .cs_n      (cs_n),
        .tgt_sdi   (ctrl_sdo),
        .tgt_sdo   (tgt_sdo),
        .tgt_sdo_oe(tgt_sdo_oe),

        // 수신 결과
        .selected  (target_selected),
        .rx_data   (target_rx_data),
        .rx_valid  (target_rx_valid)
    );

endmodule
