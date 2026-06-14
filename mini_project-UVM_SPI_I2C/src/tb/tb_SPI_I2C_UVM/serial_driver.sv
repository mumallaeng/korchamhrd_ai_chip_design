class serial_driver extends uvm_driver #(serial_seq_item);
    `uvm_component_utils(serial_driver)

    virtual serial_smoke_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual serial_smoke_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "virtual interface(vif)를 config_db에서 찾지 못했습니다.")
        end
    endfunction

    task reset_all();
        vif.reset_n <= 1'b0;

        vif.current_test_kind <= SERIAL_TEST_SMOKE;

        vif.spi_cpol           <= 1'b0;
        vif.spi_cpha           <= 1'b0;
        vif.spi_clk_div        <= 16'd4;
        vif.spi_start          <= 1'b0;
        vif.spi_ctrl_tx_data   <= '0;
        vif.spi_target_tx_data <= '0;

        vif.i2c_ctrl_start           <= 1'b0;
        vif.i2c_ctrl_target_addr     <= 7'h12;
        vif.i2c_ctrl_rw              <= 1'b0;
        vif.i2c_ctrl_tx_data         <= '0;
        vif.i2c_ctrl_ack_in          <= 1'b1;
        vif.i2c_ctrl_clk_div         <= 16'd4;
        vif.i2c_target_own_addr      <= 7'h12;
        vif.i2c_target_tx_data       <= '0;
        vif.i2c_target_rx_seen_clear <= 1'b0;

        repeat (5) @(posedge vif.clk);
        vif.reset_n <= 1'b1;
        repeat (5) @(posedge vif.clk);
    endtask

    task wait_spi_done();
        for (int i = 0; i < 5000; i++) begin
            @(posedge vif.clk);
            if (vif.spi_ctrl_done) return;
        end

        `uvm_fatal("SPI_WAIT", "SPI ctrl_done을 기다리다가 종료했습니다.")
    endtask

    task wait_i2c_done();
        for (int i = 0; i < 30000; i++) begin
            @(posedge vif.clk);
            if (vif.i2c_ctrl_done) return;
        end

        `uvm_fatal("I2C_WAIT", "I2C ctrl_done을 기다리다가 종료했습니다.")
    endtask

    task drive_spi(serial_seq_item tr);
        `uvm_info(get_type_name(), $sformatf("구동 시작: %s", tr.convert2string()), UVM_MEDIUM)

        if ((tr.cpol != 1'b0) || (tr.cpha != 1'b0)) begin
            `uvm_fatal("SPI_MODE", "현재 UVM 범위는 MODE0(CPOL=0, CPHA=0)만 구동합니다.")
        end

        vif.current_test_kind   <= tr.test_kind;
        vif.spi_cpol            <= 1'b0;
        vif.spi_cpha            <= 1'b0;
        vif.spi_clk_div         <= 16'd4;
        vif.spi_ctrl_tx_data    <= tr.ctrl_tx_data;
        vif.spi_target_tx_data  <= tr.target_tx_data;

        @(posedge vif.clk);
        vif.spi_start <= 1'b1;
        @(posedge vif.clk);
        vif.spi_start <= 1'b0;

        wait_spi_done();
        @(posedge vif.clk);
    endtask

    task clear_i2c_target_latch();
        vif.i2c_target_rx_seen_clear <= 1'b1;
        @(posedge vif.clk);
        vif.i2c_target_rx_seen_clear <= 1'b0;
    endtask

    task drive_i2c(serial_seq_item tr);
        `uvm_info(get_type_name(), $sformatf("구동 시작: %s", tr.convert2string()), UVM_MEDIUM)

        if (tr.target_addr != 7'h12) begin
            `uvm_fatal("I2C_SCOPE", "현재 UVM 범위는 target_addr=0x12 write만 구동합니다.")
        end

        vif.current_test_kind      <= tr.test_kind;
        vif.i2c_ctrl_clk_div       <= 16'd4;
        vif.i2c_target_own_addr    <= 7'h12;
        vif.i2c_target_tx_data     <= '0;
        vif.i2c_ctrl_target_addr   <= 7'h12;
        vif.i2c_ctrl_rw            <= 1'b0;
        vif.i2c_ctrl_tx_data       <= tr.ctrl_tx_data;
        vif.i2c_ctrl_ack_in        <= 1'b1;

        clear_i2c_target_latch();

        @(posedge vif.clk);
        vif.i2c_ctrl_start <= 1'b1;
        @(posedge vif.clk);
        vif.i2c_ctrl_start <= 1'b0;

        wait_i2c_done();
        repeat (2) @(posedge vif.clk);
    endtask

    task run_phase(uvm_phase phase);
        reset_all();

        forever begin
            seq_item_port.get_next_item(req);

            case (req.protocol)
                SERIAL_PROTO_SPI: drive_spi(req);
                SERIAL_PROTO_I2C: drive_i2c(req);
                default: `uvm_error(get_type_name(), "알 수 없는 protocol item입니다.")
            endcase

            seq_item_port.item_done();
        end
    endtask
endclass
