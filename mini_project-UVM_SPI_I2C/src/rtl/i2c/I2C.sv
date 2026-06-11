// I2C 1 Controller : 1 Target 기본 top
// Controller/Target은 drive_low만 만들고, 이 top에서 resolved scl/sda를 만든다.

`timescale 1ns / 1ps

module I2C #(
    parameter int ADDR_W = 7,
    parameter int DATA_W = 8,
    parameter int CLK_DIV_W = 16,
    parameter int CLK_DIV_INIT = 250
) (
    // 공통 입력
    input logic clk,
    input logic reset_n,

    // Controller transaction 제어 신호
    input  logic                ctrl_start,
    input  logic [ADDR_W-1:0]   ctrl_target_addr,
    input  logic                ctrl_rw,
    input  logic [DATA_W-1:0]   ctrl_tx_data,
    input  logic                ctrl_ack_in,
    input  logic [CLK_DIV_W-1:0] ctrl_clk_div,
    output logic [DATA_W-1:0]   ctrl_rx_data,
    output logic                ctrl_busy,
    output logic                ctrl_done,
    output logic                ctrl_ack_seen,

    // Target 설정 및 결과
    input  logic [ADDR_W-1:0]   target_own_addr,
    input  logic [DATA_W-1:0]   target_tx_data,
    output logic                target_selected,
    output logic                target_rw,
    output logic [DATA_W-1:0]   target_rx_data,
    output logic                target_rx_valid,

    // resolved I2C bus
    output logic scl,
    output logic sda,

    // debug 및 Logic Analyzer 후보
    output logic ctrl_scl_drive_low,
    output logic ctrl_sda_drive_low,
    output logic tgt_scl_drive_low,
    output logic tgt_sda_drive_low
);

    always_comb begin
        scl = 1'b1;
        sda = 1'b1;

        if (ctrl_scl_drive_low || tgt_scl_drive_low) begin
            scl = 1'b0;
        end

        if (ctrl_sda_drive_low || tgt_sda_drive_low) begin
            sda = 1'b0;
        end
    end

    I2C_controller #(
        .ADDR_W      (ADDR_W),
        .DATA_W      (DATA_W),
        .CLK_DIV_W   (CLK_DIV_W),
        .CLK_DIV_INIT(CLK_DIV_INIT)
    ) u_i2c_controller (
        // 공통 입력
        .clk               (clk),
        .reset_n           (reset_n),

        // transaction 제어 신호
        .target_addr       (ctrl_target_addr),
        .start             (ctrl_start),
        .rw                (ctrl_rw),
        .tx_data           (ctrl_tx_data),
        .ack_in            (ctrl_ack_in),
        .clk_div           (ctrl_clk_div),
        .rx_data           (ctrl_rx_data),
        .busy              (ctrl_busy),
        .done              (ctrl_done),
        .ack_seen          (ctrl_ack_seen),

        // resolved I2C bus 관찰 신호
        .scl               (scl),
        .sda               (sda),

        // open-drain drive 제어
        .ctrl_scl_drive_low(ctrl_scl_drive_low),
        .ctrl_sda_drive_low(ctrl_sda_drive_low)
    );

    I2C_target #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W)
    ) u_i2c_target (
        // 공통 입력
        .clk              (clk),
        .reset_n          (reset_n),

        // Target 설정
        .own_addr         (target_own_addr),
        .tx_data          (target_tx_data),

        // resolved I2C bus 관찰 신호
        .scl              (scl),
        .sda              (sda),

        // open-drain drive 제어
        .tgt_scl_drive_low(tgt_scl_drive_low),
        .tgt_sda_drive_low(tgt_sda_drive_low),

        // 수신 결과
        .selected         (target_selected),
        .rw               (target_rw),
        .rx_data          (target_rx_data),
        .rx_valid         (target_rx_valid)
    );

endmodule
