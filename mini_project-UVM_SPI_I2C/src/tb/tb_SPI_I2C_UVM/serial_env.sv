class serial_env extends uvm_env;
    `uvm_component_utils(serial_env)

    serial_agent              agt;
    serial_scoreboard         scb;
    serial_coverage           cov;
    serial_protocol_collector collector;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agt       = serial_agent::type_id::create("agt", this);
        scb       = serial_scoreboard::type_id::create("scb", this);
        cov       = serial_coverage::type_id::create("cov", this);
        collector = serial_protocol_collector::type_id::create("collector", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        agt.mon.ap.connect(scb.imp);
        agt.mon.ap.connect(cov.analysis_export);
        agt.mon.ap.connect(collector.analysis_export);
    endfunction
endclass
