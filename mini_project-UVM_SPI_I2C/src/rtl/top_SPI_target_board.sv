`timescale 1ns / 1ps

module top_SPI_target_board (
    // Global
    input logic clk,
    input logic btn_reset,

    // Board controls / display
    input  logic [15:0] sw,
    output logic [15:0] led,
    output logic [6:0]  seg,
    output logic [3:0]  an,
    output logic        dp,

    // SPI pins
    input  logic sclk,
    input  logic mosi,
    output wire  miso,
    input  logic ss_n
);

    import serial_protocol_pkg::*;

    localparam int DATA_W = 8;

    logic reset_n;

    logic              tgt_sdo;
    logic              tgt_sdo_oe;
    logic              tgt_selected;
    logic [DATA_W-1:0] tgt_tx_data;
    logic [DATA_W-1:0] tgt_rx_data;
    logic              tgt_rx_valid;

    logic [DATA_W-1:0] custom_led;

    assign reset_n       = ~btn_reset;

    assign miso = tgt_sdo_oe ? tgt_sdo : 1'bz;

    SPI_target #(
        .DATA_W(DATA_W)
    ) u_spi_target (
        // Global
        .clk       (clk),
        .reset_n   (reset_n),

        // SPI Configuration
        .cpol      (1'b0),
        .cpha      (1'b0),

        // Target TX data
        .tx_data   (tgt_tx_data),

        // SPI Interface
        .sclk      (sclk),
        .cs_n      (ss_n),
        .tgt_sdi   (mosi),
        .tgt_sdo   (tgt_sdo),
        .tgt_sdo_oe(tgt_sdo_oe),

        // Receive Result
        .selected  (tgt_selected),
        .rx_data   (tgt_rx_data),
        .rx_valid  (tgt_rx_valid)
    );

    custom_ip_slave u_custom_ip_slave (
        .clk        (clk),
        .reset      (btn_reset),

        .spi_rx_data(tgt_rx_data),
        .spi_done   (tgt_rx_valid),

        .spi_tx_data(tgt_tx_data),
        .led        (custom_led)
    );

    fnd_status_display #(
        .HOLD_COUNT(100_000_000)
    ) u_fnd_status_display (
        .clk         (clk),
        .reset       (btn_reset),

        .busy        (tgt_selected),
        .done        (tgt_rx_valid),

        .result_valid(1'b0),
        .result_code (2'd0),

        .seg         (seg),
        .an          (an),
        .dp          (dp)
    );

    assign led = {4'b0000, 2'b00, tgt_rx_valid, tgt_selected, custom_led};

endmodule
