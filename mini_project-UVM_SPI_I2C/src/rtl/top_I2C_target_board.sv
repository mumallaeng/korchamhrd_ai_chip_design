`timescale 1ns / 1ps

module top_I2C_target_board (
    // Global
    input logic clk,
    input logic btn_reset,

    // Board controls / display
    input  logic [15:0] sw,
    output logic [15:0] led,

    // I2C pins
    inout wire i2c_scl,
    inout wire i2c_sda
);

    import serial_protocol_pkg::*;

    localparam int DATA_W = 8;
    localparam logic [6:0] I2C_BOARD_ADDR = 7'h12;

    logic reset_n;
    logic [DATA_W-1:0] demo_tx_data;

    logic tgt_scl_drive_low;
    logic tgt_sda_drive_low;
    logic tgt_selected;
    logic tgt_rw;
    logic [DATA_W-1:0] tgt_rx_data;
    logic tgt_rx_valid;

    logic [DATA_W-1:0] display_data;
    logic rx_seen;

    assign reset_n      = ~btn_reset;
    assign demo_tx_data = sw[SW_DEMO_TX_LSB +: DATA_W];

    assign i2c_scl = tgt_scl_drive_low ? 1'b0 : 1'bz;
    assign i2c_sda = tgt_sda_drive_low ? 1'b0 : 1'bz;

    I2C_target #(
        .ADDR_W(7),
        .DATA_W(DATA_W)
    ) u_i2c_target (
        .clk              (clk),
        .reset_n          (reset_n),
        .own_addr         (I2C_BOARD_ADDR),
        .tx_data          (demo_tx_data),
        .scl              (i2c_scl),
        .sda              (i2c_sda),
        .tgt_scl_drive_low(tgt_scl_drive_low),
        .tgt_sda_drive_low(tgt_sda_drive_low),
        .selected         (tgt_selected),
        .rw               (tgt_rw),
        .rx_data          (tgt_rx_data),
        .rx_valid         (tgt_rx_valid)
    );

    always_ff @(posedge clk or negedge reset_n) begin : display_latch
        if (!reset_n) begin
            display_data <= '0;
            rx_seen      <= 1'b0;
        end else if (tgt_rx_valid) begin
            display_data <= tgt_rx_data;
            rx_seen      <= 1'b1;
        end
    end

    always_comb begin
        led = '0;
        led[LED_RX_DATA_LSB +: DATA_W] = display_data;
    end

endmodule
