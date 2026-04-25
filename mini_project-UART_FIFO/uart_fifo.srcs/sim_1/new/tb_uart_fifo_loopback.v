`timescale 1ns / 1ps

module tb_uart_fifo_loopback ();

    parameter BAUD_PERIOD = (100_000_000 / 9600) * 10;

    reg [7:0] compare_data;
    reg clk, rst, rx;
    wire tx_busy;
    wire tx;

    uart_fifo_loopback dut (
        .clk(clk),
        .rst(rst),
        .rx (rx),
        .tx_busy(tx_busy),
        .tx (tx)
    );

    always #5 clk = ~clk;

    integer i;

    task SENDER_UART(input [7:0] send_data);
        begin
            // pc tx
            // start
            rx = 0;
            // start bit
            #(BAUD_PERIOD);
            // data bit
            for (i = 0; i < 8; i = i + 1) begin
                // rx, send_data[0 - 7]
                rx = send_data[i];
                #(BAUD_PERIOD);
            end
            // stop bit
            rx = 1;
            #(BAUD_PERIOD);
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        rx = 1;
        compare_data = 8'h30;
        repeat (3) @(negedge clk);
        rst = 0;

        SENDER_UART(compare_data);
        repeat (10) #(BAUD_PERIOD);
        #1000;
        $stop;
    end
endmodule
