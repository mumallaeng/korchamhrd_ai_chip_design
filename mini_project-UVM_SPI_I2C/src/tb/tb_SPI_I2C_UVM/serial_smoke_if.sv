`timescale 1ns / 1ps

interface serial_smoke_if(input logic clk);
    localparam int DATA_W = 8;
    localparam int I2C_ADDR_W = 7;
    localparam int CLK_DIV_W = 16;

    logic reset_n;
    int unsigned current_test_kind;

    // SPI 1 Controller : 1 Target verification signals
    logic                 spi_cpol;
    logic                 spi_cpha;
    logic [CLK_DIV_W-1:0] spi_clk_div;
    logic                 spi_start;
    logic                 spi_ctrl_cs_n;
    logic [DATA_W-1:0]    spi_ctrl_tx_data;
    logic                 spi_ctrl_busy;
    logic                 spi_ctrl_done;
    logic [DATA_W-1:0]    spi_ctrl_rx_data;
    logic                 spi_ctrl_rx_valid;
    logic [DATA_W-1:0]    spi_target_tx_data;
    logic                 spi_target_selected;
    logic [DATA_W-1:0]    spi_target_rx_data;
    logic                 spi_target_rx_valid;
    logic                 spi_sclk;
    logic                 spi_ctrl_sdo;
    logic                 spi_ctrl_sdi;
    logic                 spi_tgt_sdo;
    logic                 spi_tgt_sdo_oe;

    // I2C 1 Controller : 1 Target write verification signals
    logic                 i2c_ctrl_start;
    logic [I2C_ADDR_W-1:0] i2c_ctrl_target_addr;
    logic                 i2c_ctrl_rw;
    logic [DATA_W-1:0]    i2c_ctrl_tx_data;
    logic                 i2c_ctrl_ack_in;
    logic [CLK_DIV_W-1:0] i2c_ctrl_clk_div;
    logic [DATA_W-1:0]    i2c_ctrl_rx_data;
    logic                 i2c_ctrl_busy;
    logic                 i2c_ctrl_done;
    logic                 i2c_ctrl_ack_seen;
    logic [I2C_ADDR_W-1:0] i2c_target_own_addr;
    logic [DATA_W-1:0]    i2c_target_tx_data;
    logic                 i2c_target_selected;
    logic                 i2c_target_rw;
    logic [DATA_W-1:0]    i2c_target_rx_data;
    logic                 i2c_target_rx_valid;
    logic                 i2c_scl;
    logic                 i2c_sda;
    logic                 i2c_ctrl_scl_drive_low;
    logic                 i2c_ctrl_sda_drive_low;
    logic                 i2c_tgt_scl_drive_low;
    logic                 i2c_tgt_sda_drive_low;

    logic                 i2c_target_rx_seen_clear;
    logic                 i2c_target_rx_seen;
    logic [DATA_W-1:0]    i2c_target_rx_latched;

    // target_rx_valid는 1-cycle pulse라서 done 이후 self-check에 사용할 값을 저장한다.
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            i2c_target_rx_seen    <= 1'b0;
            i2c_target_rx_latched <= '0;
        end else if (i2c_target_rx_seen_clear) begin
            i2c_target_rx_seen    <= 1'b0;
            i2c_target_rx_latched <= '0;
        end else begin
            if (i2c_target_rx_valid) begin
                i2c_target_rx_seen    <= 1'b1;
                i2c_target_rx_latched <= i2c_target_rx_data;
            end
        end
    end
endinterface
