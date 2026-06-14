package serial_uvm_pkg;
    import uvm_pkg::*;

    `include "uvm_macros.svh"

    `include "serial_seq_item.sv"
    `include "serial_sequence.sv"
    `include "serial_driver.sv"
    `include "serial_monitor.sv"
    `include "serial_agent.sv"
    `include "serial_scoreboard.sv"
    `include "serial_coverage.sv"
    `include "serial_protocol_collector.sv"
    `include "serial_env.sv"
    `include "serial_test.sv"
endpackage
