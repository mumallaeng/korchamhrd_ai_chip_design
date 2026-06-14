class serial_monitor extends uvm_monitor;
    `uvm_component_utils(serial_monitor)

    virtual serial_smoke_if vif;
    uvm_analysis_port #(serial_seq_item) ap;

    int unsigned cycle_count;
    int unsigned spi_start_cycle;
    int unsigned i2c_start_cycle;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual serial_smoke_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "virtual interface(vif)를 config_db에서 찾지 못했습니다.")
        end
    endfunction

    function serial_test_kind_e observed_test_kind();
        serial_test_kind_e kind;

        if (!$cast(kind, vif.current_test_kind)) begin
            kind = SERIAL_TEST_SMOKE;
        end

        return kind;
    endfunction

    task run_phase(uvm_phase phase);
        serial_seq_item tr;

        forever begin
            @(posedge vif.clk);

            if (!vif.reset_n) begin
                cycle_count     = 0;
                spi_start_cycle = 0;
                i2c_start_cycle = 0;
            end else begin
                cycle_count++;

                if (vif.spi_start) begin
                    spi_start_cycle = cycle_count;
                end

                if (vif.spi_ctrl_done) begin
                    tr = serial_seq_item::type_id::create("spi_observed");
                    tr.protocol       = SERIAL_PROTO_SPI;
                    tr.test_kind      = observed_test_kind();
                    tr.cpol           = vif.spi_cpol;
                    tr.cpha           = vif.spi_cpha;
                    tr.ctrl_tx_data   = vif.spi_ctrl_tx_data;
                    tr.target_tx_data = vif.spi_target_tx_data;
                    tr.ctrl_rx_data   = vif.spi_ctrl_rx_data;
                    tr.target_rx_data = vif.spi_target_rx_data;
                    tr.target_addr    = 7'h12;
                    tr.latency_cycles = cycle_count - spi_start_cycle;

                    `uvm_info(get_type_name(), $sformatf("관찰: %s", tr.convert2string()), UVM_MEDIUM)
                    ap.write(tr);
                end

                if (vif.i2c_ctrl_start) begin
                    i2c_start_cycle = cycle_count;
                end

                if (vif.i2c_ctrl_done) begin
                    tr = serial_seq_item::type_id::create("i2c_observed");
                    tr.protocol       = SERIAL_PROTO_I2C;
                    tr.test_kind      = observed_test_kind();
                    tr.target_addr    = vif.i2c_ctrl_target_addr;
                    tr.ctrl_tx_data   = vif.i2c_ctrl_tx_data;
                    tr.target_tx_data = '0;
                    tr.ctrl_rx_data   = vif.i2c_ctrl_rx_data;
                    tr.ack_seen       = vif.i2c_ctrl_ack_seen;
                    tr.target_rx_seen = vif.i2c_target_rx_seen;
                    tr.target_rx_data = vif.i2c_target_rx_latched;
                    tr.latency_cycles = cycle_count - i2c_start_cycle;

                    `uvm_info(get_type_name(), $sformatf("관찰: %s", tr.convert2string()), UVM_MEDIUM)
                    ap.write(tr);
                end
            end
        end
    endtask
endclass
