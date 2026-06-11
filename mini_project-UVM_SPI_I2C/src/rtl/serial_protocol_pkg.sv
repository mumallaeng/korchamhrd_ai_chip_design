// 보드 데모용 공통 설정 package
// SPI 보드 top과 I2C 보드 top이 공통 switch/LED map을 공유한다.

`timescale 1ns / 1ps

package serial_protocol_pkg;

    typedef enum logic [1:0] {
        ROLE_IDLE       = 2'b00,
        ROLE_CONTROLLER = 2'b01,
        ROLE_TARGET     = 2'b10
    } board_role_e;

    localparam int BOARD_ID_W = 2;
    localparam int NUM_SPI_TARGETS = 2;
    localparam int NUM_I2C_TARGETS = 1;

    localparam logic [6:0] I2C_TARGET_ADDR0 = 7'h12;
    localparam logic [6:0] I2C_TARGET_ADDR1 = 7'h34;

    // Switch map
    // sw[1:0] = board_id 후보
    // sw[7:0] = demo tx_data[7:0]
    // sw[8]   = SPI target select 후보
    localparam int SW_BOARD_ID_LSB = 0;
    localparam int SW_ROLE_LSB     = 3;
    localparam int SW_TARGET_SEL   = 8;
    localparam int SW_DEMO_TX_LSB  = 0;

    // LED map
    // led[7:0] = board demo data value. Higher LEDs are status indicators per top module.
    localparam int LED_RX_DATA_LSB = 0;

endpackage
