`timescale 1ns / 1ps

module baud_tick_gen #(
    parameter int unsigned CLK_FREQ_HZ = 100_000_000,
    parameter int unsigned BAUD_HZ     = 9600,
    parameter int unsigned OVERSAMPLE  = 16
) (
    input  logic clk,
    input  logic rst,
    output logic o_baud_tick
);

    localparam int unsigned BAUD_TICK_HZ = BAUD_HZ * OVERSAMPLE;
    localparam int unsigned F_COUNT =
        (CLK_FREQ_HZ / BAUD_TICK_HZ < 1) ? 1 : (CLK_FREQ_HZ / BAUD_TICK_HZ);
    localparam int unsigned BIT_WIDTH =
        (F_COUNT <= 1) ? 1 : $clog2(F_COUNT);

    logic [BIT_WIDTH-1:0] counter_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg <= '0;
            o_baud_tick <= 1'b0;
        end else begin
            if (counter_reg == (F_COUNT - 1)) begin
                counter_reg <= '0;
                o_baud_tick <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1'b1;
                o_baud_tick <= 1'b0;
            end
        end
    end
endmodule
