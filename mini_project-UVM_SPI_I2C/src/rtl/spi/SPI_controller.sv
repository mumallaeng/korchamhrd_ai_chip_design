// SPI 1 Controller : 1 Target 기본 코드
// 수업 baseline 범위: MODE0(CPOL=0, CPHA=0)
// MSB-first
// active-low cs_n
// 1-byte transfer
// runtime clk_div 입력으로 SCLK 속도 transaction별 설정

`timescale 1ns / 1ps

module SPI_controller #(
    parameter int DATA_W = 8,
    parameter int CLK_DIV_W = 16,
    parameter int CLK_DIV_INIT = 50
) (
    // 공통 입력
    input logic clk,
    input logic reset_n,

    // SPI 설정
    // 현재 mini project는 MODE0으로 고정한다.
    // cpol/cpha port는 수업 controller interface와 후속 확장 호환성을 위해 유지한다.
    input logic                 cpol,
    input logic                 cpha,
    input logic [CLK_DIV_W-1:0] clk_div,

    // SPI 외부 신호
    output logic sclk,
    output logic cs_n,
    input  logic ctrl_sdi,
    output logic ctrl_sdo,

    // transaction 제어 신호
    input  logic              start,
    input  logic [DATA_W-1:0] tx_data,
    output logic              busy,
    output logic              done,
    output logic [DATA_W-1:0] rx_data,
    output logic              rx_valid
);

    typedef enum logic [1:0] {
        CTRL_IDLE,
        CTRL_SETUP,
        CTRL_TRANSFER,
        CTRL_DONE
    } state_t;

    state_t state;

    localparam logic [CLK_DIV_W-1:0] CLK_DIV_INIT_VALUE = CLK_DIV_INIT;
    localparam int BIT_CNT_W = (DATA_W <= 1) ? 1 : $clog2(DATA_W);

    logic                 sclk_half_tick;
    logic [CLK_DIV_W-1:0] clk_div_r;
    logic [CLK_DIV_W-1:0] div_cnt;

    logic [DATA_W-1:0] tx_shift_reg;
    logic [DATA_W-1:0] rx_shift_reg;
    logic [BIT_CNT_W-1:0] bit_cnt;

    logic sclk_r;
    logic sclk_edge_cnt;

    assign sclk = sclk_r;

    always_ff @(posedge clk or negedge reset_n) begin : sclk_divider
        if (!reset_n) begin
            div_cnt        <= '0;
            sclk_half_tick <= 1'b0;
        end else begin
            if (state == CTRL_TRANSFER) begin
                if (div_cnt == clk_div_r - 1'b1) begin
                    div_cnt        <= '0;
                    sclk_half_tick <= 1'b1;
                end else begin
                    div_cnt        <= div_cnt + 1'b1;
                    sclk_half_tick <= 1'b0;
                end
            end else begin
                div_cnt        <= '0;
                sclk_half_tick <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk or negedge reset_n) begin : SPI_CONTROLLER_P2P_FSM
        if (!reset_n) begin
            // FSM 상태
            state         <= CTRL_IDLE;

            // transaction 설정값
            clk_div_r     <= '0;

            // TX/RX datapath
            tx_shift_reg  <= '0;
            rx_shift_reg  <= '0;
            rx_data       <= '0;
            rx_valid      <= 1'b0;

            // 상태 출력
            busy          <= 1'b0;
            done          <= 1'b0;

            // counter
            bit_cnt       <= '0;
            sclk_edge_cnt <= 1'b0;

            // SPI 외부 신호
            ctrl_sdo      <= 1'b1;
            cs_n          <= 1'b1;
            sclk_r        <= 1'b0;
        end else begin
            done     <= 1'b0;
            rx_valid <= 1'b0;

            case (state)
                CTRL_IDLE: begin
                    busy     <= 1'b0;
                    ctrl_sdo <= 1'b1;
                    cs_n     <= 1'b1;
                    sclk_r   <= 1'b0;

                    if (start) begin
                        state         <= CTRL_SETUP;
                        busy          <= 1'b1;
                        clk_div_r     <= (clk_div == '0) ? CLK_DIV_INIT_VALUE : clk_div;
                        tx_shift_reg  <= tx_data;
                        rx_shift_reg  <= '0;
                        bit_cnt       <= '0;
                        sclk_edge_cnt <= 1'b0;
                        cs_n          <= 1'b0;
                        sclk_r        <= 1'b0;
                    end
                end

                CTRL_SETUP: begin
                    ctrl_sdo     <= tx_shift_reg[DATA_W-1];
                    tx_shift_reg <= {tx_shift_reg[DATA_W-2:0], 1'b0};

                    state <= CTRL_TRANSFER;
                end

                CTRL_TRANSFER: begin
                    if (sclk_half_tick) begin
                        sclk_r <= ~sclk_r;

                        if (sclk_edge_cnt == 1'b0) begin
                            sclk_edge_cnt <= 1'b1;

                            rx_shift_reg <= {rx_shift_reg[DATA_W-2:0], ctrl_sdi};
                        end else begin
                            sclk_edge_cnt <= 1'b0;

                            if (bit_cnt != DATA_W - 1) begin
                                ctrl_sdo     <= tx_shift_reg[DATA_W-1];
                                tx_shift_reg <= {tx_shift_reg[DATA_W-2:0], 1'b0};
                            end

                            if (bit_cnt == DATA_W - 1) begin
                                state <= CTRL_DONE;
                                rx_data <= rx_shift_reg;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end
                    end
                end

                CTRL_DONE: begin
                    state    <= CTRL_IDLE;
                    busy     <= 1'b0;
                    done     <= 1'b1;
                    rx_valid <= 1'b1;
                    sclk_r   <= 1'b0;
                    cs_n     <= 1'b1;
                    ctrl_sdo <= 1'b1;
                end

                default: begin
                    state <= CTRL_IDLE;
                end
            endcase
        end
    end

endmodule
