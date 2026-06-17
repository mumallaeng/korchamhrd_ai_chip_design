set script_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ".."]]
set out_dir [file join $project_dir "build" "spi_bitstreams"]
file mkdir $out_dir

set part_name "xc7a35tcpg236-1"

proc build_spi_top {project_dir out_dir part_name top_name xdc_name} {
    puts "==> Building $top_name"

    create_project -in_memory -part $part_name

    read_verilog -sv [file join $project_dir "src/rtl/serial_protocol_pkg.sv"]
    read_verilog -sv [file join $project_dir "src/rtl/board/fnd_status_display.sv"]

    if {$top_name eq "top_SPI_controller_board"} {
        read_verilog -sv [file join $project_dir "src/rtl/board/custom_ip_master.sv"]
        read_verilog -sv [file join $project_dir "src/rtl/spi/SPI_controller.sv"]
        read_verilog -sv [file join $project_dir "src/rtl/top_SPI_controller_board.sv"]
    } else {
        read_verilog -sv [file join $project_dir "src/rtl/board/custom_ip_slave.sv"]
        read_verilog -sv [file join $project_dir "src/rtl/spi/SPI_target.sv"]
        read_verilog -sv [file join $project_dir "src/rtl/top_SPI_target_board.sv"]
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

build_spi_top $project_dir $out_dir $part_name "top_SPI_controller_board" "Basys3_SPI_controller.xdc"
build_spi_top $project_dir $out_dir $part_name "top_SPI_target_board" "Basys3_SPI_target.xdc"

puts "==> SPI bitstream build complete: $out_dir"
