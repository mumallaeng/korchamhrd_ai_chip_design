`timescale 1ns / 1ps

module top_I2C_controller_board (
    // Global
    input logic clk,
    input logic btn_reset,
    input logic btn_start,

    // Board controls / display
    input  logic [15:0] sw,
    output logic [15:0] led,

    // I2C pins
    inout wire i2c_scl,
    inout wire i2c_sda
);

    import serial_protocol_pkg::*;

    localparam int DATA_W    = 8;
    localparam int CLK_DIV_W = 16;

    localparam logic [CLK_DIV_W-1:0] I2C_CLK_DIV = 16'd500;
    localparam logic [6:0] I2C_BOARD_ADDR = 7'h12;
    localparam int START_LOCKOUT_W = 23;
    localparam logic [START_LOCKOUT_W-1:0] START_LOCKOUT_COUNT = 23'd5_000_000;

    logic reset_n;
    logic start_meta;
    logic start_sync;
    logic start_sync_d;
    logic start_pulse_raw;
    logic start_pulse;
    logic [START_LOCKOUT_W-1:0] start_lockout_cnt;

    logic [DATA_W-1:0] demo_tx_data;
    logic [DATA_W-1:0] ctrl_rx_data;
    logic              ctrl_busy;
    logic              ctrl_done;
    logic              ctrl_ack_seen;
    logic              ctrl_scl_drive_low;
    logic              ctrl_sda_drive_low;

    logic [DATA_W-1:0] display_data;
    logic              done_seen;
    logic              ack_seen_latched;

    assign reset_n      = ~btn_reset;
    assign demo_tx_data = sw[SW_DEMO_TX_LSB +: DATA_W];

    always_ff @(posedge clk or negedge reset_n) begin : start_edge_detect
        if (!reset_n) begin
            start_meta   <= 1'b0;
            start_sync   <= 1'b0;
            start_sync_d <= 1'b0;
        end else begin
            start_meta   <= btn_start;
            start_sync   <= start_meta;
            start_sync_d <= start_sync;
        end
    end

    assign start_pulse_raw = start_sync & ~start_sync_d;
    assign start_pulse = start_pulse_raw && !ctrl_busy && (start_lockout_cnt == '0);

    always_ff @(posedge clk or negedge reset_n) begin : start_lockout
        if (!reset_n) begin
            start_lockout_cnt <= '0;
        end else if (start_pulse) begin
            start_lockout_cnt <= START_LOCKOUT_COUNT;
        end else if (start_lockout_cnt != '0) begin
            start_lockout_cnt <= start_lockout_cnt - 1'b1;
        end
    end

    assign i2c_scl = ctrl_scl_drive_low ? 1'b0 : 1'bz;
    assign i2c_sda = ctrl_sda_drive_low ? 1'b0 : 1'bz;

    I2C_controller #(
        .ADDR_W      (7),
        .DATA_W      (DATA_W),
        .CLK_DIV_W   (CLK_DIV_W),
        .CLK_DIV_INIT(I2C_CLK_DIV)
    ) u_i2c_controller (
        .clk               (clk),
        .reset_n           (reset_n),

        // I2C 설정
        .clk_div           (I2C_CLK_DIV),
        .target_addr       (I2C_BOARD_ADDR),
        .rw                (1'b0),

        // I2C resolved bus 관찰 신호
        .scl               (i2c_scl),
        .sda               (i2c_sda),

        // open-drain drive 제어 신호
        .ctrl_scl_drive_low(ctrl_scl_drive_low),
        .ctrl_sda_drive_low(ctrl_sda_drive_low),

        // transaction 요청/전송 데이터
        .start             (start_pulse),
        .tx_data           (demo_tx_data),
        .ack_in            (1'b1),

        // transaction 상태/수신 결과
        .ack_seen          (ctrl_ack_seen),
        .rx_data           (ctrl_rx_data),
        .busy              (ctrl_busy),
        .done              (ctrl_done)
    );

    always_ff @(posedge clk or negedge reset_n) begin : display_latch
        if (!reset_n) begin
            display_data      <= '0;
            done_seen         <= 1'b0;
            ack_seen_latched  <= 1'b0;
        end else begin
            if (start_pulse) begin
                done_seen        <= 1'b0;
                ack_seen_latched <= 1'b0;
            end

            if (ctrl_done) begin
                display_data     <= demo_tx_data;
                done_seen        <= 1'b1;
                ack_seen_latched <= ctrl_ack_seen;
            end
        end
    end

    always_comb begin
        led = '0;
        led[LED_RX_DATA_LSB +: DATA_W] = display_data;
    end

endmodule
