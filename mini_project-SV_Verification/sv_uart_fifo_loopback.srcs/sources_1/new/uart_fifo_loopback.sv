`timescale 1ns / 1ps

module uart_fifo_loopback #(
    parameter int unsigned CLK_FREQ_HZ = 100_000_000,
    parameter int unsigned BAUD_HZ     = 9600,
    parameter int unsigned FIFO_DEPTH  = 16
) (
    input  logic clk,
    input  logic rst,
    input  logic rx,
    output logic tx,
    output logic tx_busy
);

    logic       w_baud_tick;
    logic [7:0] w_rx_data;
    logic       w_rx_done;

    logic [7:0] w_fifo_pop_data;
    logic       w_fifo_full;
    logic       w_fifo_empty;
    logic       w_tx_start;

    baud_tick_gen #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_HZ    (BAUD_HZ)
    ) u_baud_tick_gen (
        .clk     (clk),
        .rst     (rst),
        .o_baud_tick(w_baud_tick)
    );

    uart_rx u_uart_rx (
        .clk    (clk),
        .rst    (rst),
        .baud_tick (w_baud_tick),
        .rx     (rx),
        .rx_done(w_rx_done),
        .rx_data(w_rx_data)
    );

    uart_tx u_uart_tx (
        .clk     (clk),
        .rst     (rst),
        .baud_tick  (w_baud_tick),
        .tx_start(w_tx_start),
        .tx_data (w_fifo_pop_data),
        .tx_busy (tx_busy),
        .tx      (tx)
    );

    assign w_tx_start = !w_fifo_empty && !tx_busy;

    fifo #(
        .DEPTH(FIFO_DEPTH)
    ) u_fifo (
        .clk      (clk),
        .rst      (rst),
        .push_data(w_rx_data),
        .push     (w_rx_done),
        .pop      (w_tx_start),
        .pop_data (w_fifo_pop_data),
        .full     (w_fifo_full),
        .empty    (w_fifo_empty)
    );

endmodule
