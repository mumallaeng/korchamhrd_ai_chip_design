// I2C 1 Controller : 1 Target 기본 Controller
// 7-bit address
// 1-byte write/read transfer
// open-drain bus용 drive_low 출력

`timescale 1ns / 1ps

module I2C_controller #(
    parameter int ADDR_W = 7,
    parameter int DATA_W = 8,
    parameter int CLK_DIV_W = 16,
    parameter int CLK_DIV_INIT = 250
) (
    // 공통 입력
    input logic clk,
    input logic reset_n,

    // I2C 설정
    input  logic [CLK_DIV_W-1:0] clk_div,
    input  logic [ADDR_W-1:0]    target_addr,
    input  logic                 rw,

    // I2C resolved bus 관찰 신호
    input logic scl,
    input logic sda,

    // open-drain drive 제어 신호
    output logic ctrl_scl_drive_low,
    output logic ctrl_sda_drive_low,

    // transaction 요청/전송 데이터
    input  logic                 start,
    input  logic [DATA_W-1:0]    tx_data,
    input  logic                 ack_in,

    // transaction 상태/수신 결과
    output logic                 ack_seen,
    output logic [DATA_W-1:0]    rx_data,
    output logic                 busy,
    output logic                 done
);

    typedef enum logic [3:0] {
        CTRL_IDLE,
        CTRL_GEN_START,
        CTRL_TX_BYTE,
        CTRL_WAIT_ACK,
        CTRL_RX_BYTE,
        CTRL_SEND_ACK,
        CTRL_GEN_STOP,
        CTRL_DONE
    } state_t;

    typedef enum logic [1:0] {
        BYTE_ADDR,
        BYTE_DATA
    } byte_phase_t;

    state_t state;
    byte_phase_t byte_phase;

    localparam logic [CLK_DIV_W-1:0] CLK_DIV_INIT_VALUE = CLK_DIV_INIT;

    logic [CLK_DIV_W-1:0] div_cnt;
    logic [CLK_DIV_W-1:0] clk_div_r;
    logic                 qtr_tick;

    logic [1:0] step;
    logic [2:0] bit_cnt;

    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic       rw_r;
    logic       ack_in_r;

    wire tx_bit_is_one = tx_shift_reg[7];

    always_ff @(posedge clk or negedge reset_n) begin : i2c_tick_generator
        if (!reset_n) begin
            div_cnt  <= '0;
            qtr_tick <= 1'b0;
        end else begin
            if (state == CTRL_IDLE || state == CTRL_DONE) begin
                div_cnt  <= '0;
                qtr_tick <= 1'b0;
            end else if (div_cnt == clk_div_r - 1'b1) begin
                div_cnt  <= '0;
                qtr_tick <= 1'b1;
            end else begin
                div_cnt  <= div_cnt + 1'b1;
                qtr_tick <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk or negedge reset_n) begin : I2C_CONTROLLER_FSM
        if (!reset_n) begin
            state              <= CTRL_IDLE;
            byte_phase         <= BYTE_ADDR;
            clk_div_r          <= CLK_DIV_INIT_VALUE;
            step               <= '0;
            bit_cnt            <= '0;
            tx_shift_reg       <= '0;
            rx_shift_reg       <= '0;
            rw_r               <= 1'b0;
            ack_in_r           <= 1'b1;
            rx_data            <= '0;
            busy               <= 1'b0;
            done               <= 1'b0;
            ack_seen           <= 1'b0;
            ctrl_scl_drive_low <= 1'b0;
            ctrl_sda_drive_low <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                CTRL_IDLE: begin
                    busy               <= 1'b0;
                    ctrl_scl_drive_low <= 1'b0;
                    ctrl_sda_drive_low <= 1'b0;
                    step               <= '0;
                    bit_cnt            <= '0;

                    if (start) begin
                        busy         <= 1'b1;
                        ack_seen     <= 1'b0;
                        clk_div_r    <= (clk_div == '0) ? CLK_DIV_INIT_VALUE : clk_div;
                        tx_shift_reg <= {target_addr, rw};
                        rx_shift_reg <= '0;
                        rw_r         <= rw;
                        ack_in_r     <= ack_in;
                        byte_phase   <= BYTE_ADDR;
                        state        <= CTRL_GEN_START;
                    end
                end

                CTRL_GEN_START: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                ctrl_scl_drive_low <= 1'b0;
                                ctrl_sda_drive_low <= 1'b0;
                                step               <= 2'd1;
                            end
                            2'd1: begin
                                ctrl_scl_drive_low <= 1'b0;
                                ctrl_sda_drive_low <= 1'b1;
                                step               <= 2'd2;
                            end
                            2'd2: begin
                                ctrl_scl_drive_low <= 1'b1;
                                ctrl_sda_drive_low <= 1'b1;
                                step               <= 2'd0;
                                state              <= CTRL_TX_BYTE;
                            end
                            default: step <= 2'd0;
                        endcase
                    end
                end

                CTRL_TX_BYTE: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                ctrl_scl_drive_low <= 1'b1;
                                ctrl_sda_drive_low <= ~tx_bit_is_one;
                                step               <= 2'd1;
                            end
                            2'd1: begin
                                ctrl_scl_drive_low <= 1'b0;
                                step               <= 2'd2;
                            end
                            2'd2: begin
                                step <= 2'd3;
                            end
                            2'd3: begin
                                ctrl_scl_drive_low <= 1'b1;
                                tx_shift_reg       <= {tx_shift_reg[6:0], 1'b0};
                                step               <= 2'd0;

                                if (bit_cnt == 3'd7) begin
                                    bit_cnt <= '0;
                                    state   <= CTRL_WAIT_ACK;
                                end else begin
                                    bit_cnt <= bit_cnt + 1'b1;
                                end
                            end
                        endcase
                    end
                end

                CTRL_WAIT_ACK: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                ctrl_scl_drive_low <= 1'b1;
                                ctrl_sda_drive_low <= 1'b0;
                                step               <= 2'd1;
                            end
                            2'd1: begin
                                ctrl_scl_drive_low <= 1'b0;
                                step               <= 2'd2;
                            end
                            2'd2: begin
                                ack_seen <= ~sda;
                                step     <= 2'd3;
                            end
                            2'd3: begin
                                ctrl_scl_drive_low <= 1'b1;
                                step               <= 2'd0;

                                if (byte_phase == BYTE_ADDR) begin
                                    if (rw_r) begin
                                        state <= CTRL_RX_BYTE;
                                    end else begin
                                        tx_shift_reg <= tx_data;
                                        byte_phase   <= BYTE_DATA;
                                        state        <= CTRL_TX_BYTE;
                                    end
                                end else begin
                                    state <= CTRL_GEN_STOP;
                                end
                            end
                        endcase
                    end
                end

                CTRL_RX_BYTE: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                ctrl_scl_drive_low <= 1'b1;
                                ctrl_sda_drive_low <= 1'b0;
                                step               <= 2'd1;
                            end
                            2'd1: begin
                                ctrl_scl_drive_low <= 1'b0;
                                step               <= 2'd2;
                            end
                            2'd2: begin
                                rx_shift_reg <= {rx_shift_reg[6:0], sda};
                                step         <= 2'd3;
                            end
                            2'd3: begin
                                ctrl_scl_drive_low <= 1'b1;
                                step               <= 2'd0;

                                if (bit_cnt == 3'd7) begin
                                    bit_cnt <= '0;
                                    rx_data <= {rx_shift_reg[6:0], sda};
                                    state   <= CTRL_SEND_ACK;
                                end else begin
                                    bit_cnt <= bit_cnt + 1'b1;
                                end
                            end
                        endcase
                    end
                end

                CTRL_SEND_ACK: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                ctrl_scl_drive_low <= 1'b1;
                                ctrl_sda_drive_low <= ~ack_in_r;
                                step               <= 2'd1;
                            end
                            2'd1: begin
                                ctrl_scl_drive_low <= 1'b0;
                                step               <= 2'd2;
                            end
                            2'd2: begin
                                step <= 2'd3;
                            end
                            2'd3: begin
                                ctrl_scl_drive_low <= 1'b1;
                                ctrl_sda_drive_low <= 1'b0;
                                step               <= 2'd0;
                                state              <= CTRL_GEN_STOP;
                            end
                        endcase
                    end
                end

                CTRL_GEN_STOP: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                ctrl_scl_drive_low <= 1'b1;
                                ctrl_sda_drive_low <= 1'b1;
                                step               <= 2'd1;
                            end
                            2'd1: begin
                                ctrl_scl_drive_low <= 1'b0;
                                ctrl_sda_drive_low <= 1'b1;
                                step               <= 2'd2;
                            end
                            2'd2: begin
                                ctrl_scl_drive_low <= 1'b0;
                                ctrl_sda_drive_low <= 1'b0;
                                step               <= 2'd0;
                                state              <= CTRL_DONE;
                            end
                            default: step <= 2'd0;
                        endcase
                    end
                end

                CTRL_DONE: begin
                    busy               <= 1'b0;
                    done               <= 1'b1;
                    ctrl_scl_drive_low <= 1'b0;
                    ctrl_sda_drive_low <= 1'b0;
                    state              <= CTRL_IDLE;
                end

                default: state <= CTRL_IDLE;
            endcase
        end
    end

endmodule
