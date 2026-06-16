`timescale 1ns / 1ps

module tb_SPI;

    localparam int DATA_W      = 8;
    localparam int CLK_DIV_W   = 16;

    logic clk;
    logic reset_n;

    logic                   cpol;
    logic                   cpha;
    logic [CLK_DIV_W-1:0]   clk_div;
    logic                   start;
    logic [DATA_W-1:0]      ctrl_tx_data;

    logic                   ctrl_busy;
    logic                   ctrl_done;
    logic [DATA_W-1:0]      ctrl_rx_data;
    logic                   ctrl_rx_valid;

    logic [DATA_W-1:0]      target_tx_data;
    logic                   target_selected;
    logic [DATA_W-1:0]      target_rx_data;
    logic                   target_rx_valid;

    logic                   sclk;
    logic                   ctrl_sdo;
    logic                   ctrl_sdi;
    logic                   cs_n;
    logic                   tgt_sdo;
    logic                   tgt_sdo_oe;

    always_comb begin
        ctrl_sdi = 1'b1;

        if ((cs_n == 1'b0) && tgt_sdo_oe) begin
            ctrl_sdi = tgt_sdo;
        end
    end

    SPI_controller #(
        .DATA_W      (DATA_W),
        .CLK_DIV_W   (CLK_DIV_W),
        .CLK_DIV_INIT(4)
    ) u_spi_controller (
        // Global
        .clk       (clk),
        .reset_n   (reset_n),

        // SPI Configuration
        .cpol      (cpol),
        .cpha      (cpha),
        .clk_div   (clk_div),

        // SPI Interface
        .cs_n      (cs_n),
        .sclk      (sclk),
        .ctrl_sdi  (ctrl_sdi),
        .ctrl_sdo  (ctrl_sdo),

        // Transaction Interface
        .start     (start),
        .tx_data   (ctrl_tx_data),
        .busy      (ctrl_busy),
        .done      (ctrl_done),
        .rx_data   (ctrl_rx_data),
        .rx_valid  (ctrl_rx_valid)
    );

    SPI_target #(
        .DATA_W(DATA_W)
    ) u_spi_target (
        // Global
        .clk       (clk),
        .reset_n   (reset_n),

        // SPI Configuration
        .cpol      (cpol),
        .cpha      (cpha),

        // Target TX data
        .tx_data   (target_tx_data),

        // SPI Interface
        .sclk      (sclk),
        .cs_n      (cs_n),
        .tgt_sdi   (ctrl_sdo),
        .tgt_sdo   (tgt_sdo),
        .tgt_sdo_oe(tgt_sdo_oe),

        // Receive Result
        .selected  (target_selected),
        .rx_data   (target_rx_data),
        .rx_valid  (target_rx_valid)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
`ifdef USE_FSDB
        if ($test$plusargs("DUMP_FSDB")) begin
            $fsdbDumpfile("wave/tb_SPI.fsdb");
            $fsdbDumpvars(0, tb_SPI);
        end
`endif

        if ($test$plusargs("DUMP_VCD")) begin
            $dumpfile("wave/tb_SPI.vcd");
            $dumpvars(0, tb_SPI);
        end
    end

    task automatic spi_transfer(
        input logic [DATA_W-1:0] tx_data_i,
        input logic [DATA_W-1:0] target_tx_i
    );
        begin
            ctrl_tx_data   = tx_data_i;
            target_tx_data = target_tx_i;

            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            wait (ctrl_done);
            if (ctrl_rx_data !== target_tx_i) begin
                $error("SPI controller RX mismatch actual=%02h expected=%02h",
                       ctrl_rx_data, target_tx_i);
            end
            if (target_rx_data !== tx_data_i) begin
                $error("SPI target RX mismatch actual=%02h expected=%02h",
                       target_rx_data, tx_data_i);
            end
            repeat (4) @(posedge clk);
        end
    endtask

    initial begin
        reset_n        = 1'b0;
        start          = 1'b0;
        cpol           = 1'b0;
        cpha           = 1'b0;
        clk_div        = 16'd4;
        ctrl_tx_data   = '0;
        target_tx_data = '0;

        repeat (5) @(posedge clk);
        reset_n = 1'b1;
        repeat (2) @(posedge clk);

        spi_transfer(8'hA5, 8'h3C);
        spi_transfer(8'h5A, 8'hC3);

        #100;
        $finish;
    end

endmodule
