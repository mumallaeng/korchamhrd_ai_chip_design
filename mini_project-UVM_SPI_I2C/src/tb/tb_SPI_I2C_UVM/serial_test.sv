class serial_base_test extends uvm_test;
    `uvm_component_utils(serial_base_test)

    serial_env env;

    function new(string name = "serial_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = serial_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    task drain_after_sequence(int unsigned cycles = 50);
        repeat (cycles) @(posedge env.agt.drv.vif.clk);
    endtask
endclass

class serial_smoke_test extends serial_base_test;
    `uvm_component_utils(serial_smoke_test)

    function new(string name = "serial_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        serial_smoke_seq seq;

        phase.raise_objection(this);
        seq = serial_smoke_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        drain_after_sequence();
        phase.drop_objection(this);
    endtask
endclass

class serial_basic_test extends serial_base_test;
    `uvm_component_utils(serial_basic_test)

    function new(string name = "serial_basic_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        serial_basic_seq seq;

        phase.raise_objection(this);
        seq = serial_basic_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        drain_after_sequence();
        phase.drop_objection(this);
    endtask
endclass

class serial_boundary_test extends serial_base_test;
    `uvm_component_utils(serial_boundary_test)

    function new(string name = "serial_boundary_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        serial_boundary_seq seq;

        phase.raise_objection(this);
        seq = serial_boundary_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        drain_after_sequence();
        phase.drop_objection(this);
    endtask
endclass

class serial_random_test extends serial_base_test;
    `uvm_component_utils(serial_random_test)

    function new(string name = "serial_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        serial_random_seq seq;

        phase.raise_objection(this);
        seq = serial_random_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        drain_after_sequence();
        phase.drop_objection(this);
    endtask
endclass

class serial_back_to_back_test extends serial_base_test;
    `uvm_component_utils(serial_back_to_back_test)

    function new(string name = "serial_back_to_back_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        serial_back_to_back_seq seq;

        phase.raise_objection(this);
        seq = serial_back_to_back_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        drain_after_sequence();
        phase.drop_objection(this);
    endtask
endclass

class serial_regression_test extends serial_base_test;
    `uvm_component_utils(serial_regression_test)

    function new(string name = "serial_regression_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        serial_regression_seq seq;

        phase.raise_objection(this);
        seq = serial_regression_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        drain_after_sequence(100);
        phase.drop_objection(this);
    endtask
endclass
