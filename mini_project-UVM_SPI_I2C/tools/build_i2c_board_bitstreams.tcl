set script_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ".."]]
set out_dir [file join $project_dir "build" "i2c_bitstreams"]
file mkdir $out_dir

set part_name "xc7a35tcpg236-1"

proc build_i2c_top {project_dir out_dir part_name top_name xdc_name} {
    puts "==> Building $top_name"

    create_project -in_memory -part $part_name

    read_verilog -sv [file join $project_dir "src/rtl/serial_protocol_pkg.sv"]

    if {$top_name eq "top_I2C_controller_board"} {
        read_verilog -sv [file join $project_dir "src/rtl/i2c/I2C_controller.sv"]
        read_verilog -sv [file join $project_dir "src/rtl/top_I2C_controller_board.sv"]
    } else {
        read_verilog -sv [file join $project_dir "src/rtl/i2c/I2C_target.sv"]
        read_verilog -sv [file join $project_dir "src/rtl/top_I2C_target_board.sv"]
    }

    read_xdc [file join $project_dir "constraints" $xdc_name]

    synth_design -top $top_name -part $part_name
    opt_design
    place_design
    route_design

    report_timing_summary -file [file join $out_dir "${top_name}_timing_summary.rpt"]
    report_utilization -file [file join $out_dir "${top_name}_utilization.rpt"]
    report_drc -file [file join $out_dir "${top_name}_drc.rpt"]

    write_bitstream -force [file join $out_dir "${top_name}.bit"]
    close_project

    puts "==> Wrote [file join $out_dir "${top_name}.bit"]"
}

build_i2c_top $project_dir $out_dir $part_name "top_I2C_controller_board" "Basys3_I2C_controller.xdc"
build_i2c_top $project_dir $out_dir $part_name "top_I2C_target_board" "Basys3_I2C_target.xdc"

puts "==> I2C bitstream build complete: $out_dir"
