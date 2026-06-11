// I2C 1 Controller : 1 Target 기본 Target
// 7-bit address Target
// 1-byte write/read transfer
// open-drain bus용 drive_low 출력

`timescale 1ns / 1ps

module I2C_target #(
    parameter int ADDR_W = 7,
    parameter int DATA_W = 8
) (
    // 공통 입력
    input logic clk,
    input logic reset_n,

    // Target 설정
    input logic [ADDR_W-1:0] own_addr,
    input logic [DATA_W-1:0] tx_data,

    // resolved I2C bus 관찰 신호
    input logic scl,
    input logic sda,

    // open-drain drive 제어
    output logic tgt_scl_drive_low,
    output logic tgt_sda_drive_low,

    // 수신 결과
    output logic              selected,
    output logic              rw,
    output logic [DATA_W-1:0] rx_data,
    output logic              rx_valid
);

    typedef enum logic [2:0] {
        TGT_IDLE,
        TGT_RX_ADDR,
        TGT_ADDR_ACK,
        TGT_RX_DATA,
        TGT_DATA_ACK,
        TGT_TX_DATA,
        TGT_WAIT_ACK,
        TGT_IGNORE
    } state_t;

    state_t state;

    logic scl_meta;
    logic scl_sync;
    logic scl_prev;
    logic sda_meta;
    logic sda_sync;
    logic sda_prev;

    logic [7:0] addr_shift_reg;
    logic [7:0] data_shift_reg;
    logic [7:0] tx_shift_reg;
    logic [2:0] bit_cnt;
    logic       ack_active;

    wire start_detect = (scl_sync == 1'b1) && (sda_prev == 1'b1) && (sda_sync == 1'b0);
    wire stop_detect  = (scl_sync == 1'b1) && (sda_prev == 1'b0) && (sda_sync == 1'b1);
    wire scl_rise     = (scl_prev == 1'b0) && (scl_sync == 1'b1);
    wire scl_fall     = (scl_prev == 1'b1) && (scl_sync == 1'b0);

    assign tgt_scl_drive_low = 1'b0;

    always_ff @(posedge clk or negedge reset_n) begin : I2C_TARGET_FSM
        logic [7:0] addr_byte;
        logic [7:0] data_byte;

        if (!reset_n) begin
            state             <= TGT_IDLE;
            scl_meta          <= 1'b1;
            scl_sync          <= 1'b1;
            scl_prev          <= 1'b1;
            sda_meta          <= 1'b1;
            sda_sync          <= 1'b1;
            sda_prev          <= 1'b1;
            addr_shift_reg    <= '0;
            data_shift_reg    <= '0;
            tx_shift_reg      <= '0;
            bit_cnt           <= '0;
            ack_active        <= 1'b0;
            selected          <= 1'b0;
            rw                <= 1'b0;
            rx_data           <= '0;
            rx_valid          <= 1'b0;
            tgt_sda_drive_low <= 1'b0;
        end else begin
            scl_meta <= scl;
            scl_sync <= scl_meta;
            scl_prev <= scl_sync;
            sda_meta <= sda;
            sda_sync <= sda_meta;
            sda_prev <= sda_sync;
            rx_valid <= 1'b0;

            if (start_detect) begin
                state             <= TGT_RX_ADDR;
                addr_shift_reg    <= '0;
                data_shift_reg    <= '0;
                bit_cnt           <= '0;
                ack_active        <= 1'b0;
                selected          <= 1'b0;
                rw                <= 1'b0;
                tgt_sda_drive_low <= 1'b0;
            end else if (stop_detect) begin
                state             <= TGT_IDLE;
                bit_cnt           <= '0;
                ack_active        <= 1'b0;
                selected          <= 1'b0;
                tgt_sda_drive_low <= 1'b0;
            end else begin
                case (state)
                    TGT_IDLE: begin
                        tgt_sda_drive_low <= 1'b0;
                    end

                    TGT_RX_ADDR: begin
                        if (scl_rise) begin
                            addr_byte      = {addr_shift_reg[6:0], sda_sync};
                            addr_shift_reg <= addr_byte;

                            if (bit_cnt == 3'd7) begin
                                selected <= (addr_byte[7:1] == own_addr);
                                rw       <= addr_byte[0];
                                bit_cnt  <= '0;

                                if (addr_byte[7:1] == own_addr) begin
                                    state <= TGT_ADDR_ACK;
                                end else begin
                                    state <= TGT_IGNORE;
                                end
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end
                    end

                    TGT_ADDR_ACK: begin
                        if (scl_fall && !ack_active) begin
                            tgt_sda_drive_low <= 1'b1;
                            ack_active        <= 1'b1;
                        end else if (scl_fall && ack_active) begin
                            tgt_sda_drive_low <= 1'b0;
                            ack_active        <= 1'b0;
                            bit_cnt           <= '0;

                            if (rw) begin
                                tx_shift_reg      <= tx_data;
                                tgt_sda_drive_low <= ~tx_data[DATA_W-1];
                                state             <= TGT_TX_DATA;
                            end else begin
                                data_shift_reg <= '0;
                                state          <= TGT_RX_DATA;
                            end
                        end
                    end

                    TGT_RX_DATA: begin
                        if (scl_rise) begin
                            data_byte      = {data_shift_reg[6:0], sda_sync};
                            data_shift_reg <= data_byte;

                            if (bit_cnt == 3'd7) begin
                                rx_data  <= data_byte;
                                rx_valid <= 1'b1;
                                bit_cnt  <= '0;
                                state    <= TGT_DATA_ACK;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end
                    end

                    TGT_DATA_ACK: begin
                        if (scl_fall && !ack_active) begin
                            tgt_sda_drive_low <= 1'b1;
                            ack_active        <= 1'b1;
                        end else if (scl_fall && ack_active) begin
                            tgt_sda_drive_low <= 1'b0;
                            ack_active        <= 1'b0;
                            state             <= TGT_IGNORE;
                        end
                    end

                    TGT_TX_DATA: begin
                        if (scl_fall) begin
                            if (bit_cnt == 3'd7) begin
                                tgt_sda_drive_low <= 1'b0;
                                bit_cnt           <= '0;
                                state             <= TGT_WAIT_ACK;
                            end else begin
                                bit_cnt           <= bit_cnt + 1'b1;
                                tx_shift_reg      <= {tx_shift_reg[6:0], 1'b0};
                                tgt_sda_drive_low <= ~tx_shift_reg[6];
                            end
                        end
                    end

                    TGT_WAIT_ACK: begin
                        if (scl_fall) begin
                            state <= TGT_IGNORE;
                        end
                    end

                    TGT_IGNORE: begin
                        tgt_sda_drive_low <= 1'b0;
                    end

                    default: state <= TGT_IDLE;
                endcase
            end
        end
    end

endmodule
