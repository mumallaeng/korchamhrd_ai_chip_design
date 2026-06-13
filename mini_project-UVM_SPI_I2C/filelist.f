// VCS compile filelist
//
// 최상위 Makefile에서 아래처럼 읽는다.
// vcs ... -f filelist.f
//
// compile order:
// 1. board setting package
// 2. SPI RTL
// 3. I2C RTL
// 4. UVM smoke TB interface/package/top

+incdir+src/tb/tb_SPI_I2C_UVM

src/rtl/serial_protocol_pkg.sv

src/rtl/spi/SPI_controller.sv
src/rtl/spi/SPI_target.sv

src/rtl/i2c/I2C_controller.sv
src/rtl/i2c/I2C_target.sv
src/rtl/i2c/I2C.sv

src/tb/tb_SPI_I2C_UVM/serial_smoke_if.sv
src/tb/tb_SPI_I2C_UVM/serial_uvm_pkg.sv
src/tb/tb_SPI_I2C_UVM/tb_SPI_I2C_UVM.sv
