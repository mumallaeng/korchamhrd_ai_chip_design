`timescale 1ns / 1ps

module top_SPI_controller_board (
    // Global
    input logic clk,
    input logic btn_reset,
    input logic btn_start,
    input logic btn_check,

    // Board controls / display
    input  logic [15:0] sw,
    output logic [15:0] led,
    output logic [6:0]  seg,
    output logic [3:0]  an,
    output logic        dp,

    // SPI pins
    output logic       sclk,
    output logic       mosi,
    input  logic       miso,
    output logic [1:0] ss_n
);

    import serial_protocol_pkg::*;

    localparam int DATA_W    = 8;
    localparam int CLK_DIV_W = 16;

    localparam logic [CLK_DIV_W-1:0] SPI_CLK_DIV = 16'd100;

    logic reset_n;
    logic [DATA_W-1:0] custom_led;
    logic              target_sel;

    logic              ctrl_cs_n;
    logic              ctrl_sclk;
    logic              ctrl_sdo;
    logic              ctrl_start;
    logic              ctrl_busy;
    logic              ctrl_done;
    logic [DATA_W-1:0] ctrl_tx_data;
    logic [DATA_W-1:0] ctrl_rx_data;
    logic              ctrl_rx_valid;

    logic              result_valid;
    logic [1:0]        result_code;

    assign reset_n      = ~btn_reset;
    assign target_sel   = sw[8];

    assign sclk    = ctrl_sclk;
    assign mosi    = ctrl_sdo;
    assign ss_n[0] = (target_sel == 1'b0) ? ctrl_cs_n : 1'b1;
    assign ss_n[1] = (target_sel == 1'b1) ? ctrl_cs_n : 1'b1;

    custom_ip_master u_custom_ip_master (
        .clk         (clk),
        .reset       (btn_reset),

        .sw          (sw[7:0]),
        .btn_start   (btn_start),
        .btn_check   (btn_check),

        .spi_busy    (ctrl_busy),
        .spi_done    (ctrl_done),
        .spi_rx_data (ctrl_rx_data),

        .spi_start   (ctrl_start),
        .spi_tx_data (ctrl_tx_data),
        .led         (custom_led),

        .result_valid(result_valid),
        .result_code (result_code)
    );

    SPI_controller #(
        .DATA_W      (DATA_W),
        .CLK_DIV_W   (CLK_DIV_W),
        .CLK_DIV_INIT(SPI_CLK_DIV)
    ) u_spi_controller (
        // Global
        .clk       (clk),
        .reset_n   (reset_n),

        // SPI Configuration
        .cpol      (1'b0),
        .cpha      (1'b0),
        .clk_div   (SPI_CLK_DIV),

        // SPI Interface
        .cs_n      (ctrl_cs_n),
        .sclk      (ctrl_sclk),
        .ctrl_sdi  (miso),
        .ctrl_sdo  (ctrl_sdo),

        // Transaction Interface
        .start     (ctrl_start),
        .tx_data   (ctrl_tx_data),
        .busy      (ctrl_busy),
        .done      (ctrl_done),
        .rx_data   (ctrl_rx_data),
        .rx_valid  (ctrl_rx_valid)
    );

    fnd_status_display #(
        .HOLD_COUNT(300_000_000)
    ) u_fnd_status_display (
        .clk         (clk),
        .reset       (btn_reset),

        .busy        (ctrl_busy),
        .done        (ctrl_done),

        .result_valid(result_valid),
        .result_code (result_code),

        .seg         (seg),
        .an          (an),
        .dp          (dp)
    );

    assign led = {4'b0000, ctrl_rx_valid, ctrl_done, ctrl_busy, target_sel, custom_led};

endmodule
