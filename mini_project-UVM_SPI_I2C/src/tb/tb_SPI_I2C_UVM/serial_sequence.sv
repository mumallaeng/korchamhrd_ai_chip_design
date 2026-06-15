class serial_base_seq extends uvm_sequence #(serial_seq_item);
    `uvm_object_utils(serial_base_seq)

    function new(string name = "serial_base_seq");
        super.new(name);
    endfunction

    task do_spi(
        input serial_test_kind_e kind,
        input bit [7:0]          ctrl_data,
        input bit [7:0]          target_data
    );
        serial_seq_item item;

        item = serial_seq_item::type_id::create("spi_item");
        start_item(item);
        item.protocol       = SERIAL_PROTO_SPI;
        item.test_kind      = kind;
        item.cpol           = 1'b0;
        item.cpha           = 1'b0;
        item.ctrl_tx_data   = ctrl_data;
        item.target_tx_data = target_data;
        item.target_addr    = 7'h12;
        finish_item(item);
    endtask

    task do_i2c_write(
        input serial_test_kind_e kind,
        input bit [7:0]          ctrl_data
    );
        serial_seq_item item;

        item = serial_seq_item::type_id::create("i2c_item");
        start_item(item);
        item.protocol       = SERIAL_PROTO_I2C;
        item.test_kind      = kind;
        item.target_addr    = 7'h12;
        item.ctrl_tx_data   = ctrl_data;
        item.target_tx_data = '0;
        item.cpol           = 1'b0;
        item.cpha           = 1'b0;
        finish_item(item);
    endtask
endclass

class serial_smoke_seq extends serial_base_seq;
    `uvm_object_utils(serial_smoke_seq)

    function new(string name = "serial_smoke_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "serial_smoke_seq 시작", UVM_LOW)
        do_spi(SERIAL_TEST_SMOKE, 8'hA5, 8'h3C);
        do_i2c_write(SERIAL_TEST_SMOKE, 8'hA5);
        `uvm_info(get_type_name(), "serial_smoke_seq 종료", UVM_LOW)
    endtask
endclass

class serial_basic_seq extends serial_base_seq;
    `uvm_object_utils(serial_basic_seq)

    function new(string name = "serial_basic_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "serial_basic_seq 시작", UVM_LOW)
        do_spi(SERIAL_TEST_BASIC, 8'h5A, 8'hC3);
        do_i2c_write(SERIAL_TEST_BASIC, 8'h5A);
        `uvm_info(get_type_name(), "serial_basic_seq 종료", UVM_LOW)
    endtask
endclass

class serial_boundary_seq extends serial_base_seq;
    `uvm_object_utils(serial_boundary_seq)

    function new(string name = "serial_boundary_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "serial_boundary_seq 시작", UVM_LOW)
        do_spi(SERIAL_TEST_BOUNDARY, 8'h00, 8'hFF);
        do_spi(SERIAL_TEST_BOUNDARY, 8'hFF, 8'h00);
        do_spi(SERIAL_TEST_BOUNDARY, 8'hAA, 8'h55);
        do_spi(SERIAL_TEST_BOUNDARY, 8'h55, 8'hAA);

        do_i2c_write(SERIAL_TEST_BOUNDARY, 8'h00);
        do_i2c_write(SERIAL_TEST_BOUNDARY, 8'hFF);
        do_i2c_write(SERIAL_TEST_BOUNDARY, 8'hAA);
        do_i2c_write(SERIAL_TEST_BOUNDARY, 8'h55);
        `uvm_info(get_type_name(), "serial_boundary_seq 종료", UVM_LOW)
    endtask
endclass

class serial_random_seq extends serial_base_seq;
    `uvm_object_utils(serial_random_seq)

    function new(string name = "serial_random_seq");
        super.new(name);
    endfunction

    task body();
        bit [7:0] ctrl_data;
        bit [7:0] target_data;

        `uvm_info(get_type_name(), "serial_random_seq 시작: SPI 64 + I2C 64", UVM_LOW)
        for (int i = 0; i < 64; i++) begin
            ctrl_data   = $urandom_range(0, 255);
            target_data = $urandom_range(0, 255);
            do_spi(SERIAL_TEST_RANDOM, ctrl_data, target_data);
        end

        for (int i = 0; i < 64; i++) begin
            ctrl_data = $urandom_range(0, 255);
            do_i2c_write(SERIAL_TEST_RANDOM, ctrl_data);
        end
        `uvm_info(get_type_name(), "serial_random_seq 종료", UVM_LOW)
    endtask
endclass

class serial_back_to_back_seq extends serial_base_seq;
    `uvm_object_utils(serial_back_to_back_seq)

    function new(string name = "serial_back_to_back_seq");
        super.new(name);
    endfunction

    task body();
        bit [7:0] ctrl_data;
        bit [7:0] target_data;

        `uvm_info(get_type_name(), "serial_back_to_back_seq 시작", UVM_LOW)
        for (int i = 0; i < 8; i++) begin
            ctrl_data   = 8'h10 + i;
            target_data = 8'hE0 - i;
            do_spi(SERIAL_TEST_BACK_TO_BACK, ctrl_data, target_data);
        end

        for (int i = 0; i < 8; i++) begin
            ctrl_data = 8'h30 + i;
            do_i2c_write(SERIAL_TEST_BACK_TO_BACK, ctrl_data);
        end
        `uvm_info(get_type_name(), "serial_back_to_back_seq 종료", UVM_LOW)
    endtask
endclass

class serial_regression_seq extends serial_base_seq;
    `uvm_object_utils(serial_regression_seq)

    function new(string name = "serial_regression_seq");
        super.new(name);
    endfunction

    task body();
        serial_smoke_seq       smoke_seq;
        serial_basic_seq       basic_seq;
        serial_boundary_seq    boundary_seq;
        serial_random_seq      random_seq;
        serial_back_to_back_seq back_to_back_seq;

        `uvm_info(get_type_name(), "serial_regression_seq 시작", UVM_LOW)

        smoke_seq = serial_smoke_seq::type_id::create("smoke_seq");
        smoke_seq.start(m_sequencer);

        basic_seq = serial_basic_seq::type_id::create("basic_seq");
        basic_seq.start(m_sequencer);

        boundary_seq = serial_boundary_seq::type_id::create("boundary_seq");
        boundary_seq.start(m_sequencer);

        random_seq = serial_random_seq::type_id::create("random_seq");
        random_seq.start(m_sequencer);

        back_to_back_seq = serial_back_to_back_seq::type_id::create("back_to_back_seq");
        back_to_back_seq.start(m_sequencer);

        `uvm_info(get_type_name(), "serial_regression_seq 종료", UVM_LOW)
    endtask
endclass
