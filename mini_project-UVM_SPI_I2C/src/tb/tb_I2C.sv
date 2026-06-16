`timescale 1ns / 1ps

module tb_I2C;

    localparam int ADDR_W    = 7;
    localparam int DATA_W    = 8;
    localparam int CLK_DIV_W = 16;

    logic clk;
    logic reset_n;

    logic                 ctrl_start;
    logic [ADDR_W-1:0]    ctrl_target_addr;
    logic                 ctrl_rw;
    logic [DATA_W-1:0]    ctrl_tx_data;
    logic                 ctrl_ack_in;
    logic [CLK_DIV_W-1:0] ctrl_clk_div;
    logic [DATA_W-1:0]    ctrl_rx_data;
    logic                 ctrl_busy;
    logic                 ctrl_done;
    logic                 ctrl_ack_seen;

    logic [ADDR_W-1:0] target_own_addr;
    logic [DATA_W-1:0] target_tx_data;
    logic              target_selected;
    logic              target_rw;
    logic [DATA_W-1:0] target_rx_data;
    logic              target_rx_valid;

    logic scl;
    logic sda;

    logic ctrl_scl_drive_low;
    logic ctrl_sda_drive_low;
    logic tgt_scl_drive_low;
    logic tgt_sda_drive_low;

    I2C #(
        .ADDR_W      (ADDR_W),
        .DATA_W      (DATA_W),
        .CLK_DIV_W   (CLK_DIV_W),
        .CLK_DIV_INIT(4)
    ) dut (
        // Global
        .clk               (clk),
        .reset_n           (reset_n),

        // Controller Transaction Interface
        .ctrl_start        (ctrl_start),
        .ctrl_target_addr  (ctrl_target_addr),
        .ctrl_rw           (ctrl_rw),
        .ctrl_tx_data      (ctrl_tx_data),
        .ctrl_ack_in       (ctrl_ack_in),
        .ctrl_clk_div      (ctrl_clk_div),
        .ctrl_rx_data      (ctrl_rx_data),
        .ctrl_busy         (ctrl_busy),
        .ctrl_done         (ctrl_done),
        .ctrl_ack_seen     (ctrl_ack_seen),

        // Target Configuration / Result
        .target_own_addr   (target_own_addr),
        .target_tx_data    (target_tx_data),
        .target_selected   (target_selected),
        .target_rw         (target_rw),
        .target_rx_data    (target_rx_data),
        .target_rx_valid   (target_rx_valid),

        // Resolved I2C bus
        .scl               (scl),
        .sda               (sda),

        // Debug / Logic Analyzer 후보
        .ctrl_scl_drive_low(ctrl_scl_drive_low),
        .ctrl_sda_drive_low(ctrl_sda_drive_low),
        .tgt_scl_drive_low (tgt_scl_drive_low),
        .tgt_sda_drive_low (tgt_sda_drive_low)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
`ifdef USE_FSDB
        if ($test$plusargs("DUMP_FSDB")) begin
            $fsdbDumpfile("wave/tb_I2C.fsdb");
            $fsdbDumpvars(0, tb_I2C);
        end
`endif

        if ($test$plusargs("DUMP_VCD")) begin
            $dumpfile("wave/tb_I2C.vcd");
            $dumpvars(0, tb_I2C);
        end
    end

    task automatic i2c_write(
        input logic [ADDR_W-1:0] addr,
        input logic [DATA_W-1:0] data
    );
        begin
            ctrl_target_addr = addr;
            ctrl_rw          = 1'b0;
            ctrl_tx_data     = data;
            ctrl_ack_in      = 1'b1;

            @(posedge clk);
            ctrl_start = 1'b1;
            @(posedge clk);
            ctrl_start = 1'b0;

            wait (ctrl_done);
            if (!ctrl_ack_seen) begin
                $error("I2C ACK mismatch addr=%02h data=%02h", addr, data);
            end
            if (target_rx_data !== data) begin
                $error("I2C target RX mismatch addr=%02h actual=%02h expected=%02h",
                       addr, target_rx_data, data);
            end
            repeat (4) @(posedge clk);
        end
    endtask

    initial begin
        reset_n          = 1'b0;
        ctrl_start       = 1'b0;
        ctrl_target_addr = '0;
        ctrl_rw          = 1'b0;
        ctrl_tx_data     = '0;
        ctrl_ack_in      = 1'b1;
        ctrl_clk_div     = 16'd4;
        target_own_addr  = 7'h12;
        target_tx_data   = 8'hC3;

        repeat (5) @(posedge clk);
        reset_n = 1'b1;
        repeat (5) @(posedge clk);

        i2c_write(7'h12, 8'hA5);
        i2c_write(7'h12, 8'h5A);

        #100;
        $finish;
    end

endmodule
