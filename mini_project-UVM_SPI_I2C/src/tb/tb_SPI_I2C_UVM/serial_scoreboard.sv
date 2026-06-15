class serial_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(serial_scoreboard)

    uvm_analysis_imp #(serial_seq_item, serial_scoreboard) imp;

    int spi_count;
    int i2c_count;
    int pass_count;
    int fail_count;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    function void check_spi(serial_seq_item tr);
        spi_count++;

        if (tr.ctrl_rx_data !== tr.target_tx_data) begin
            fail_count++;
            `uvm_error(get_type_name(), $sformatf(
                "SPI Controller RX mismatch: actual=0x%02h expected target_tx=0x%02h item=%s",
                tr.ctrl_rx_data, tr.target_tx_data, tr.convert2string()
            ))
        end else if (tr.target_rx_data !== tr.ctrl_tx_data) begin
            fail_count++;
            `uvm_error(get_type_name(), $sformatf(
                "SPI Target RX mismatch: actual=0x%02h expected ctrl_tx=0x%02h item=%s",
                tr.target_rx_data, tr.ctrl_tx_data, tr.convert2string()
            ))
        end else begin
            pass_count++;
            `uvm_info(get_type_name(), $sformatf("SPI PASS: %s", tr.convert2string()), UVM_LOW)
        end
    endfunction

    function void check_i2c(serial_seq_item tr);
        i2c_count++;

        if (!tr.ack_seen) begin
            fail_count++;
            `uvm_error(get_type_name(), $sformatf("I2C ACK 미관찰: %s", tr.convert2string()))
        end else if (!tr.target_rx_seen) begin
            fail_count++;
            `uvm_error(get_type_name(), $sformatf("I2C Target rx_valid 미관찰: %s", tr.convert2string()))
        end else if (tr.target_rx_data !== tr.ctrl_tx_data) begin
            fail_count++;
            `uvm_error(get_type_name(), $sformatf(
                "I2C Target RX mismatch: actual=0x%02h expected ctrl_tx=0x%02h item=%s",
                tr.target_rx_data, tr.ctrl_tx_data, tr.convert2string()
            ))
        end else begin
            pass_count++;
            `uvm_info(get_type_name(), $sformatf("I2C PASS: %s", tr.convert2string()), UVM_LOW)
        end
    endfunction

    function void write(serial_seq_item tr);
        case (tr.protocol)
            SERIAL_PROTO_SPI: check_spi(tr);
            SERIAL_PROTO_I2C: check_i2c(tr);
            default: begin
                fail_count++;
                `uvm_error(get_type_name(), "알 수 없는 protocol transaction입니다.")
            end
        endcase
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("SCB", "========================================", UVM_LOW)
        `uvm_info("SCB", "====== SPI/I2C Scoreboard 리포트 ======", UVM_LOW)
        `uvm_info("SCB", $sformatf("  SPI transaction : %0d", spi_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  I2C transaction : %0d", i2c_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  pass count      : %0d", pass_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  fail count      : %0d", fail_count), UVM_LOW)
        `uvm_info("SCB", "========================================", UVM_LOW)
    endfunction
endclass
