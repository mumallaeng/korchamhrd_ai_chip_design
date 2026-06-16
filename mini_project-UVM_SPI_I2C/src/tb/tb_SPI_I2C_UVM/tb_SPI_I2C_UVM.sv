`timescale 1ns / 1ps

import uvm_pkg::*;
import serial_uvm_pkg::*;

module tb_SPI_I2C_UVM;
    logic clk;
    string test_name;

    serial_smoke_if smoke_if(.clk(clk));

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin : waveform_dump_control
        string wave_basename;
        string wave_path;

        if (!$value$plusargs("WAVE_BASENAME=%s", wave_basename)) begin
            wave_basename = "tb_SPI_I2C_UVM";
        end

        if ($test$plusargs("DUMP_FSDB")) begin
`ifdef USE_FSDB
            wave_path = $sformatf("wave/%s.fsdb", wave_basename);
            $fsdbDumpfile(wave_path);
            $fsdbDumpvars(0, tb_SPI_I2C_UVM, "+all");
`else
            $display("DUMP_FSDB requested, but USE_FSDB is not defined.");
`endif
        end

        if ($test$plusargs("DUMP_VCD")) begin
            wave_path = $sformatf("wave/%s.vcd", wave_basename);
            $dumpfile(wave_path);
            $dumpvars(0);
        end
    end

    always_comb begin
        smoke_if.spi_ctrl_sdi = 1'b1;

        if ((smoke_if.spi_ctrl_cs_n == 1'b0) && smoke_if.spi_tgt_sdo_oe) begin
            smoke_if.spi_ctrl_sdi = smoke_if.spi_tgt_sdo;
        end
    end

    SPI_controller #(
        .DATA_W      (8),
        .CLK_DIV_W   (16),
        .CLK_DIV_INIT(4)
    ) u_spi_controller (
        // Global
        .clk       (clk),
        .reset_n   (smoke_if.reset_n),

        // SPI Configuration
        .cpol      (smoke_if.spi_cpol),
        .cpha      (smoke_if.spi_cpha),
        .clk_div   (smoke_if.spi_clk_div),

        // SPI Interface
        .cs_n      (smoke_if.spi_ctrl_cs_n),
        .sclk      (smoke_if.spi_sclk),
        .ctrl_sdi  (smoke_if.spi_ctrl_sdi),
        .ctrl_sdo  (smoke_if.spi_ctrl_sdo),

        // Transaction Interface
        .start     (smoke_if.spi_start),
        .tx_data   (smoke_if.spi_ctrl_tx_data),
        .busy      (smoke_if.spi_ctrl_busy),
        .done      (smoke_if.spi_ctrl_done),
        .rx_data   (smoke_if.spi_ctrl_rx_data),
        .rx_valid  (smoke_if.spi_ctrl_rx_valid)
    );

    SPI_target #(
        .DATA_W(8)
    ) u_spi_target (
        // Global
        .clk       (clk),
        .reset_n   (smoke_if.reset_n),

        // SPI Configuration
        .cpol      (smoke_if.spi_cpol),
        .cpha      (smoke_if.spi_cpha),

        // Target TX data
        .tx_data   (smoke_if.spi_target_tx_data),

        // SPI Interface
        .sclk      (smoke_if.spi_sclk),
        .cs_n      (smoke_if.spi_ctrl_cs_n),
        .tgt_sdi   (smoke_if.spi_ctrl_sdo),
        .tgt_sdo   (smoke_if.spi_tgt_sdo),
        .tgt_sdo_oe(smoke_if.spi_tgt_sdo_oe),

        // Receive Result
        .selected  (smoke_if.spi_target_selected),
        .rx_data   (smoke_if.spi_target_rx_data),
        .rx_valid  (smoke_if.spi_target_rx_valid)
    );

    I2C #(
        .ADDR_W      (7),
        .DATA_W      (8),
        .CLK_DIV_W   (16),
        .CLK_DIV_INIT(4)
    ) u_i2c (
        // Global
        .clk               (clk),
        .reset_n           (smoke_if.reset_n),

        // Controller Transaction Interface
        .ctrl_start        (smoke_if.i2c_ctrl_start),
        .ctrl_target_addr  (smoke_if.i2c_ctrl_target_addr),
        .ctrl_rw           (smoke_if.i2c_ctrl_rw),
        .ctrl_tx_data      (smoke_if.i2c_ctrl_tx_data),
        .ctrl_ack_in       (smoke_if.i2c_ctrl_ack_in),
        .ctrl_clk_div      (smoke_if.i2c_ctrl_clk_div),
        .ctrl_rx_data      (smoke_if.i2c_ctrl_rx_data),
        .ctrl_busy         (smoke_if.i2c_ctrl_busy),
        .ctrl_done         (smoke_if.i2c_ctrl_done),
        .ctrl_ack_seen     (smoke_if.i2c_ctrl_ack_seen),

        // Target Configuration / Result
        .target_own_addr   (smoke_if.i2c_target_own_addr),
        .target_tx_data    (smoke_if.i2c_target_tx_data),
        .target_selected   (smoke_if.i2c_target_selected),
        .target_rw         (smoke_if.i2c_target_rw),
        .target_rx_data    (smoke_if.i2c_target_rx_data),
        .target_rx_valid   (smoke_if.i2c_target_rx_valid),

        // Resolved I2C bus
        .scl               (smoke_if.i2c_scl),
        .sda               (smoke_if.i2c_sda),

        // Open-drain drive-low observation signals
        .ctrl_scl_drive_low(smoke_if.i2c_ctrl_scl_drive_low),
        .ctrl_sda_drive_low(smoke_if.i2c_ctrl_sda_drive_low),
        .tgt_scl_drive_low (smoke_if.i2c_tgt_scl_drive_low),
        .tgt_sda_drive_low (smoke_if.i2c_tgt_sda_drive_low)
    );

    initial begin
        uvm_config_db#(virtual serial_smoke_if)::set(null, "*", "vif", smoke_if);

        if (!$value$plusargs("UVM_TESTNAME=%s", test_name)) begin
            test_name = "serial_smoke_test";
        end

        run_test(test_name);
    end
endmodule
