// SPI 1 Controller : 1 Target 기본 코드
// 수업 baseline 범위: MODE0(CPOL=0, CPHA=0)
// MSB-first
// active-low cs_n
// 1-byte transfer

`timescale 1ns / 1ps

module SPI_target #(
    parameter int DATA_W = 8
) (
    // 공통 입력
    input logic clk,
    input logic reset_n,

    // SPI 설정
    // 현재 mini project는 MODE0으로 고정한다.
    // cpol/cpha port는 수업 controller interface와 후속 확장 호환성을 위해 유지한다.
    input logic cpol,
    input logic cpha,

    // Target 송신 데이터
    input logic [DATA_W-1:0] tx_data,

    // SPI 외부 신호
    input  logic sclk,
    input  logic cs_n,
    input  logic tgt_sdi,
    output logic tgt_sdo,
    output logic tgt_sdo_oe,

    // 수신 결과
    output logic              selected,
    output logic [DATA_W-1:0] rx_data,
    output logic              rx_valid
);

    localparam int BIT_CNT_W = (DATA_W <= 1) ? 1 : $clog2(DATA_W);

    typedef enum logic [1:0] {
        TGT_IDLE,
        TGT_SETUP,
        TGT_TRANSFER,
        TGT_DONE
    } state_t;

    state_t state;

    logic sclk_d;
    logic cs_n_d;

    logic [DATA_W-1:0] tx_shift_reg;
    logic [DATA_W-1:0] rx_shift_reg;
    logic [BIT_CNT_W-1:0] bit_cnt;

    wire cs_start = (cs_n_d == 1'b1) && (cs_n == 1'b0);
    wire cs_stop  = (cs_n_d == 1'b0) && (cs_n == 1'b1);

    wire sclk_rise = (sclk_d == 1'b0) && (sclk == 1'b1);
    wire sclk_fall = (sclk_d == 1'b1) && (sclk == 1'b0);

    wire sample_edge = sclk_rise;
    wire shift_edge  = sclk_fall;

    always_ff @(posedge clk or negedge reset_n) begin : SPI_TARGET_P2P_FSM
        if (!reset_n) begin
            // edge detect용 지연값
            state        <= TGT_IDLE;
            sclk_d       <= 1'b0;
            cs_n_d       <= 1'b1;

            // TX/RX datapath
            tx_shift_reg <= '0;
            rx_shift_reg <= '0;
            rx_data      <= '0;
            rx_valid     <= 1'b0;

            // counter
            bit_cnt      <= '0;

            // SPI 외부 신호
            selected     <= 1'b0;
            tgt_sdo      <= 1'b1;
            tgt_sdo_oe   <= 1'b0;
        end else begin
            sclk_d   <= sclk;
            cs_n_d   <= cs_n;
            rx_valid <= 1'b0;

            if (cs_start) begin
                state        <= TGT_SETUP;
                selected     <= 1'b1;
                tgt_sdo_oe   <= 1'b1;
                rx_shift_reg <= '0;
                bit_cnt      <= '0;

                tgt_sdo      <= tx_data[DATA_W-1];
                tx_shift_reg <= {tx_data[DATA_W-2:0], 1'b0};
            end else if (cs_stop) begin
                state      <= TGT_IDLE;
                selected   <= 1'b0;
                tgt_sdo    <= 1'b1;
                tgt_sdo_oe <= 1'b0;
            end else if (selected) begin
                if (state == TGT_SETUP) begin
                    state <= TGT_TRANSFER;
                end

                if (sample_edge) begin
                    rx_shift_reg <= {rx_shift_reg[DATA_W-2:0], tgt_sdi};

                    if (bit_cnt == DATA_W - 1) begin
                        state    <= TGT_DONE;
                        rx_data  <= {rx_shift_reg[DATA_W-2:0], tgt_sdi};
                        rx_valid <= 1'b1;
                    end else begin
                        bit_cnt <= bit_cnt + 1'b1;
                    end
                end

                if (shift_edge && (state == TGT_TRANSFER)) begin
                    tgt_sdo      <= tx_shift_reg[DATA_W-1];
                    tx_shift_reg <= {tx_shift_reg[DATA_W-2:0], 1'b0};
                end
            end else begin
                state <= TGT_IDLE;
            end
        end
    end

endmodule
