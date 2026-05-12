`timescale 1ns / 1ps

module uart_rx (
    input  logic clk,
    input  logic rst,
    input  logic baud_tick,
    input  logic rx,
    output logic rx_done,
    output logic [7:0] rx_data
);

    localparam int unsigned OVERSAMPLE = 16;
    localparam int unsigned STOP_TICK  = 23;

    typedef enum logic [1:0] {
        IDLE  = 2'd0,
        START = 2'd1,
        DATA  = 2'd2,
        STOP  = 2'd3
    } state_t;

    state_t c_state, n_state;

    logic [4:0] baud_tick_cnt_reg, baud_tick_cnt_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;
    logic [7:0] data_reg, data_next;
    logic [7:0] rx_data_reg, rx_data_next;
    logic rx_done_reg, rx_done_next;
    logic rx_meta_reg, rx_sync_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;
            baud_tick_cnt_reg <= '0;
            bit_cnt_reg    <= '0;
            data_reg       <= '0;
            rx_data_reg    <= '0;
            rx_done_reg    <= 1'b0;
            rx_meta_reg    <= 1'b1;
            rx_sync_reg    <= 1'b1;
        end else begin
            c_state        <= n_state;
            baud_tick_cnt_reg <= baud_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            data_reg       <= data_next;
            rx_data_reg    <= rx_data_next;
            rx_done_reg    <= rx_done_next;
            rx_meta_reg    <= rx;
            rx_sync_reg    <= rx_meta_reg;
        end
    end

    always_comb begin
        n_state         = c_state;
        baud_tick_cnt_next = baud_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        data_next       = data_reg;
        rx_data_next    = rx_data_reg;
        rx_done_next    = 1'b0;

        unique case (c_state)
            IDLE: begin
                baud_tick_cnt_next = '0;
                bit_cnt_next    = '0;
                if (!rx_sync_reg) begin
                    n_state = START;
                end
            end

            START: begin
                if (baud_tick) begin
                    if (baud_tick_cnt_reg == (OVERSAMPLE / 2 - 1)) begin
                        baud_tick_cnt_next = '0;
                        if (!rx_sync_reg) begin
                            n_state = DATA;
                        end else begin
                            n_state = IDLE;
                        end
                    end else begin
                        baud_tick_cnt_next = baud_tick_cnt_reg + 1'b1;
                    end
                end
            end

            DATA: begin
                if (baud_tick) begin
                    if (baud_tick_cnt_reg == (OVERSAMPLE - 1)) begin
                        data_next       = {rx_sync_reg, data_reg[7:1]};
                        baud_tick_cnt_next = '0;
                        if (bit_cnt_reg == 3'd7) begin
                            bit_cnt_next = '0;
                            n_state      = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1'b1;
                        end
                    end else begin
                        baud_tick_cnt_next = baud_tick_cnt_reg + 1'b1;
                    end
                end
            end

            STOP: begin
                if (baud_tick) begin
                    if (baud_tick_cnt_reg == STOP_TICK) begin
                        baud_tick_cnt_next = '0;
                        if (rx_sync_reg) begin
                            rx_done_next = 1'b1;
                            rx_data_next = data_reg;
                        end
                        n_state = IDLE;
                    end else begin
                        baud_tick_cnt_next = baud_tick_cnt_reg + 1'b1;
                    end
                end
            end

            default: begin
                n_state         = IDLE;
                baud_tick_cnt_next = '0;
                bit_cnt_next    = '0;
                data_next       = '0;
                rx_data_next    = '0;
                rx_done_next    = 1'b0;
            end
        endcase
    end

    assign rx_done = rx_done_reg;
    assign rx_data = rx_data_reg;

endmodule
