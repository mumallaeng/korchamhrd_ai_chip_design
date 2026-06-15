typedef enum int {
    SERIAL_PROTO_SPI = 0,
    SERIAL_PROTO_I2C = 1
} serial_proto_e;

typedef enum int {
    SERIAL_TEST_SMOKE = 0,
    SERIAL_TEST_BASIC = 1,
    SERIAL_TEST_BOUNDARY = 2,
    SERIAL_TEST_RANDOM = 3,
    SERIAL_TEST_BACK_TO_BACK = 4
} serial_test_kind_e;

localparam int SERIAL_TEST_KIND_COUNT = 5;

function string serial_test_kind_name(serial_test_kind_e kind);
    case (kind)
        SERIAL_TEST_SMOKE:        return "SMOKE";
        SERIAL_TEST_BASIC:        return "BASIC";
        SERIAL_TEST_BOUNDARY:     return "BOUNDARY";
        SERIAL_TEST_RANDOM:       return "RANDOM";
        SERIAL_TEST_BACK_TO_BACK: return "BACK_TO_BACK";
        default:                  return "UNKNOWN";
    endcase
endfunction

class serial_seq_item extends uvm_sequence_item;
    rand serial_proto_e     protocol;
    rand serial_test_kind_e test_kind;

    rand bit       cpol;
    rand bit       cpha;
    rand bit [6:0] target_addr;
    rand bit [7:0] ctrl_tx_data;
    rand bit [7:0] target_tx_data;

    bit [7:0]      ctrl_rx_data;
    bit [7:0]      target_rx_data;
    bit            ack_seen;
    bit            target_rx_seen;
    int unsigned   latency_cycles;

    `uvm_object_utils_begin(serial_seq_item)
        `uvm_field_enum(serial_proto_e, protocol, UVM_ALL_ON)
        `uvm_field_enum(serial_test_kind_e, test_kind, UVM_ALL_ON)
        `uvm_field_int(cpol, UVM_ALL_ON)
        `uvm_field_int(cpha, UVM_ALL_ON)
        `uvm_field_int(target_addr, UVM_ALL_ON)
        `uvm_field_int(ctrl_tx_data, UVM_ALL_ON)
        `uvm_field_int(target_tx_data, UVM_ALL_ON)
        `uvm_field_int(ctrl_rx_data, UVM_ALL_ON)
        `uvm_field_int(target_rx_data, UVM_ALL_ON)
        `uvm_field_int(ack_seen, UVM_ALL_ON)
        `uvm_field_int(target_rx_seen, UVM_ALL_ON)
        `uvm_field_int(latency_cycles, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "serial_seq_item");
        super.new(name);
        cpol = 1'b0;
        cpha = 1'b0;
        target_addr = 7'h12;
    endfunction

    function string convert2string();
        if (protocol == SERIAL_PROTO_SPI) begin
            return $sformatf(
                "SPI kind=%s mode=%0d ctrl_tx=0x%02h target_tx=0x%02h ctrl_rx=0x%02h target_rx=0x%02h latency=%0d",
                serial_test_kind_name(test_kind), {cpol, cpha}, ctrl_tx_data, target_tx_data,
                ctrl_rx_data, target_rx_data, latency_cycles
            );
        end

        return $sformatf(
            "I2C kind=%s addr=0x%02h ctrl_tx=0x%02h ack_seen=%0b target_rx_seen=%0b target_rx=0x%02h latency=%0d",
            serial_test_kind_name(test_kind), target_addr, ctrl_tx_data, ack_seen,
            target_rx_seen, target_rx_data, latency_cycles
        );
    endfunction
endclass
