class serial_protocol_collector extends uvm_subscriber #(serial_seq_item);
    `uvm_component_utils(serial_protocol_collector)

    int spi_count;
    int i2c_count;
    int test_kind_count[SERIAL_TEST_KIND_COUNT];
    int unsigned spi_latency_sum;
    int unsigned i2c_latency_sum;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void write(serial_seq_item t);
        int kind_idx;

        kind_idx = int'(t.test_kind);
        if ((kind_idx >= 0) && (kind_idx < SERIAL_TEST_KIND_COUNT)) begin
            test_kind_count[kind_idx]++;
        end

        if (t.protocol == SERIAL_PROTO_SPI) begin
            spi_count++;
            spi_latency_sum += t.latency_cycles;
        end else if (t.protocol == SERIAL_PROTO_I2C) begin
            i2c_count++;
            i2c_latency_sum += t.latency_cycles;
        end
    endfunction

    function real average_latency(input int count, input int unsigned sum);
        if (count == 0) return 0.0;
        return $itor(sum) / $itor(count);
    endfunction

    function void report_phase(uvm_phase phase);
        serial_test_kind_e kind;

        super.report_phase(phase);

        `uvm_info("COLLECTOR", "========================================", UVM_LOW)
        `uvm_info("COLLECTOR", "====== Protocol Collector 리포트 =======", UVM_LOW)
        `uvm_info("COLLECTOR", $sformatf("  SPI count       : %0d", spi_count), UVM_LOW)
        `uvm_info("COLLECTOR", $sformatf("  I2C count       : %0d", i2c_count), UVM_LOW)
        for (int i = 0; i < SERIAL_TEST_KIND_COUNT; i++) begin
            kind = serial_test_kind_e'(i);
            `uvm_info("COLLECTOR", $sformatf("  %-12s count : %0d", serial_test_kind_name(kind), test_kind_count[i]), UVM_LOW)
        end
        `uvm_info("COLLECTOR", $sformatf("  SPI avg latency : %0.2f cycles", average_latency(spi_count, spi_latency_sum)), UVM_LOW)
        `uvm_info("COLLECTOR", $sformatf("  I2C avg latency : %0.2f cycles", average_latency(i2c_count, i2c_latency_sum)), UVM_LOW)
        `uvm_info("COLLECTOR", "========================================", UVM_LOW)
    endfunction
endclass
