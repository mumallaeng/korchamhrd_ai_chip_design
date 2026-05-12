`timescale 1ns / 1ps

module uart_tx (
    input  logic       clk,
    input  logic       rst,
    input  logic       baud_tick,
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic       tx_busy,
    output logic       tx
);

    localparam int unsigned OVERSAMPLE = 16;

    typedef enum logic [1:0] {
        IDLE  = 2'd0,
        START = 2'd1,
        DATA  = 2'd2,
        STOP  = 2'd3
    } state_t;

    state_t c_state, n_state;

    logic       tx_reg, tx_next;
    logic [7:0] data_reg, data_next;
    logic [3:0] baud_tick_cnt_reg, baud_tick_cnt_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;
    logic       tx_busy_reg, tx_busy_next;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;
            tx_reg         <= 1'b1;
            data_reg       <= '0;
            baud_tick_cnt_reg <= '0;
            bit_cnt_reg    <= '0;
            tx_busy_reg    <= 1'b0;
        end else begin
            c_state        <= n_state;
            tx_reg         <= tx_next;
            data_reg       <= data_next;
            baud_tick_cnt_reg <= baud_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            tx_busy_reg    <= tx_busy_next;
        end
    end

    always_comb begin
        n_state         = c_state;
        tx_next         = tx_reg;
        data_next       = data_reg;
        baud_tick_cnt_next = baud_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        tx_busy_next    = tx_busy_reg;

        unique case (c_state)
            IDLE: begin
                tx_next         = 1'b1;
                tx_busy_next    = 1'b0;
                baud_tick_cnt_next = '0;
                bit_cnt_next    = '0;

                if (tx_start) begin
                    data_next       = tx_data;
                    baud_tick_cnt_next = '0;
                    bit_cnt_next    = '0;
                    tx_busy_next    = 1'b1;
                    n_state         = START;
                end
            end

            START: begin
                tx_next      = 1'b0;
                tx_busy_next = 1'b1;

                if (baud_tick) begin
                    if (baud_tick_cnt_reg == (OVERSAMPLE - 1)) begin
                        baud_tick_cnt_next = '0;
                        bit_cnt_next    = '0;
                        n_state         = DATA;
                    end else begin
                        baud_tick_cnt_next = baud_tick_cnt_reg + 1'b1;
                    end
                end
            end

            DATA: begin
                tx_next      = data_reg[0];
                tx_busy_next = 1'b1;

                if (baud_tick) begin
                    if (baud_tick_cnt_reg == (OVERSAMPLE - 1)) begin
                        baud_tick_cnt_next = '0;
                        if (bit_cnt_reg == 3'd7) begin
                            bit_cnt_next = '0;
                            n_state      = STOP;
                        end else begin
                            data_next    = {1'b0, data_reg[7:1]};
                            bit_cnt_next = bit_cnt_reg + 1'b1;
                        end
                    end else begin
                        baud_tick_cnt_next = baud_tick_cnt_reg + 1'b1;
                    end
                end
            end

            STOP: begin
                tx_next      = 1'b1;
                tx_busy_next = 1'b1;

                if (baud_tick) begin
                    if (baud_tick_cnt_reg == (OVERSAMPLE - 1)) begin
                        baud_tick_cnt_next = '0;
                        tx_busy_next    = 1'b0;
                        n_state         = IDLE;
                    end else begin
                        baud_tick_cnt_next = baud_tick_cnt_reg + 1'b1;
                    end
                end
            end

            default: begin
                n_state         = IDLE;
                tx_next         = 1'b1;
                data_next       = '0;
                baud_tick_cnt_next = '0;
                bit_cnt_next    = '0;
                tx_busy_next    = 1'b0;
            end
        endcase
    end

    assign tx      = tx_reg;
    assign tx_busy = tx_busy_reg;

endmodule
