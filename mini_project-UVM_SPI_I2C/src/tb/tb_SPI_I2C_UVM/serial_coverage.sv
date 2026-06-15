class serial_coverage extends uvm_subscriber #(serial_seq_item);
    `uvm_component_utils(serial_coverage)

    serial_seq_item tr;

    covergroup serial_cg;
        option.per_instance = 1;

        cp_protocol: coverpoint tr.protocol {
            bins spi = {SERIAL_PROTO_SPI};
            bins i2c = {SERIAL_PROTO_I2C};
        }

        cp_test_kind: coverpoint tr.test_kind {
            bins smoke       = {SERIAL_TEST_SMOKE};
            bins basic       = {SERIAL_TEST_BASIC};
            bins boundary    = {SERIAL_TEST_BOUNDARY};
            bins random      = {SERIAL_TEST_RANDOM};
            bins back_to_back = {SERIAL_TEST_BACK_TO_BACK};
        }

        cp_spi_mode0: coverpoint {tr.cpol, tr.cpha} iff (tr.protocol == SERIAL_PROTO_SPI) {
            bins mode0 = {2'b00};
            illegal_bins non_mode0_values = {2'b01, 2'b10, 2'b11};
        }

        cp_spi_ctrl_tx_class: coverpoint tr.ctrl_tx_data iff (tr.protocol == SERIAL_PROTO_SPI) {
            bins zero        = {8'h00};
            bins ones        = {8'hFF};
            bins alternating = {8'hAA, 8'h55};
            bins directed    = {8'hA5, 8'h5A};
            bins back_to_back = {[8'h10:8'h17]};
            bins other       = default;
        }

        cp_spi_target_tx_class: coverpoint tr.target_tx_data iff (tr.protocol == SERIAL_PROTO_SPI) {
            bins zero        = {8'h00};
            bins ones        = {8'hFF};
            bins alternating = {8'hAA, 8'h55};
            bins directed    = {8'h3C, 8'hC3};
            bins back_to_back = {[8'hD9:8'hE0]};
            bins other       = default;
        }

        cp_spi_full_duplex_cross: cross cp_spi_ctrl_tx_class, cp_spi_target_tx_class
            iff (tr.protocol == SERIAL_PROTO_SPI) {
            option.cross_auto_bin_max = 0;
            bins directed_pair =
                binsof(cp_spi_ctrl_tx_class.directed) && binsof(cp_spi_target_tx_class.directed);
            bins zero_to_ones =
                binsof(cp_spi_ctrl_tx_class.zero) && binsof(cp_spi_target_tx_class.ones);
            bins ones_to_zero =
                binsof(cp_spi_ctrl_tx_class.ones) && binsof(cp_spi_target_tx_class.zero);
            bins alternating_pair =
                binsof(cp_spi_ctrl_tx_class.alternating) && binsof(cp_spi_target_tx_class.alternating);
            bins back_to_back_pair =
                binsof(cp_spi_ctrl_tx_class.back_to_back) && binsof(cp_spi_target_tx_class.back_to_back);
        }

        cp_i2c_addr: coverpoint tr.target_addr iff (tr.protocol == SERIAL_PROTO_I2C) {
            bins target_12 = {7'h12};
            illegal_bins other_addr = default;
        }

        cp_i2c_ack_seen: coverpoint tr.ack_seen iff (tr.protocol == SERIAL_PROTO_I2C) {
            bins ack = {1'b1};
        }

        cp_i2c_target_rx_seen: coverpoint tr.target_rx_seen iff (tr.protocol == SERIAL_PROTO_I2C) {
            bins received = {1'b1};
        }

        cp_i2c_ack_receive_cross: cross cp_i2c_ack_seen, cp_i2c_target_rx_seen
            iff (tr.protocol == SERIAL_PROTO_I2C);

        cp_spi_latency: coverpoint tr.latency_cycles iff (tr.protocol == SERIAL_PROTO_SPI) {
            bins byte_mode0 = {[1:100]};
        }

        cp_i2c_latency: coverpoint tr.latency_cycles iff (tr.protocol == SERIAL_PROTO_I2C) {
            bins byte_write = {[101:1000]};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        serial_cg = new();
    endfunction

    function void write(serial_seq_item t);
        tr = t;
        serial_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("COV", "========================================", UVM_LOW)
        `uvm_info("COV", "===== SPI/I2C Functional Coverage =====", UVM_LOW)
        `uvm_info("COV", $sformatf("  전체              : %6.2f %%", serial_cg.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  protocol          : %6.2f %%", serial_cg.cp_protocol.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  test_kind         : %6.2f %%", serial_cg.cp_test_kind.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  SPI MODE0         : %6.2f %%", serial_cg.cp_spi_mode0.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  SPI ctrl class    : %6.2f %%", serial_cg.cp_spi_ctrl_tx_class.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  SPI target class  : %6.2f %%", serial_cg.cp_spi_target_tx_class.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  SPI full-duplex x : %6.2f %%", serial_cg.cp_spi_full_duplex_cross.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  I2C address       : %6.2f %%", serial_cg.cp_i2c_addr.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  I2C ACK           : %6.2f %%", serial_cg.cp_i2c_ack_seen.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  I2C receive       : %6.2f %%", serial_cg.cp_i2c_target_rx_seen.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  I2C ACK/RX x      : %6.2f %%", serial_cg.cp_i2c_ack_receive_cross.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  SPI latency       : %6.2f %%", serial_cg.cp_spi_latency.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  I2C latency       : %6.2f %%", serial_cg.cp_i2c_latency.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", "========================================", UVM_LOW)
    endfunction
endclass
