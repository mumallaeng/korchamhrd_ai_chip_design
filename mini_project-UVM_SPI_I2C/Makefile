VCS_OPTS = -full64 -sverilog
VCS_OPTS += -ntb_opts uvm-1.2
VCS_OPTS += -timescale=1ns/1ps
VCS_OPTS += -debug_access+all -kdb -lca
VCS_OPTS += -cm line+cond+fsm+tgl+branch+assert
WAVE_VCS_OPTS = $(VCS_OPTS) +define+USE_FSDB
DIRECTED_VCS_OPTS = -full64 -sverilog
DIRECTED_VCS_OPTS += -timescale=1ns/1ps
DIRECTED_VCS_OPTS += -debug_access+all -kdb -lca
DIRECTED_VCS_OPTS += +define+USE_FSDB

VCS_FILELIST ?= filelist.f
VCS_SRC_FILES = -f $(VCS_FILELIST)
VCS_OUTPUT ?= -o simv
WAVE_SIMV ?= simv_wave

TOP ?= tb_SPI_I2C_UVM
TEST ?= serial_smoke_test
SEED ?= 1234
INFO_LEVEL ?= UVM_MEDIUM
CM_NAME ?= serial_smoke
VERDI_DISPLAY ?= :7
WAVE_DIR ?= wave
REMOTE_HOST ?= korcham-server-pedu07
REMOTE_PROJECT_DIR ?= /home/pedu07/projects/SPI_I2C_UVM
REMOTE_MAKE ?= tools/pedu07_remote_make.sh
REMOTE_SYNC ?= tools/pedu07_sync_project.sh

SIMV_OPTS = +UVM_TESTNAME=$(TEST)
SIMV_OPTS += +UVM_VERBOSITY=$(INFO_LEVEL)
SIMV_OPTS += +ntb_random_seed=$(SEED)
SIMV_OPTS += -cm line+cond+fsm+tgl+branch+assert
SIMV_OPTS += -cm_name $(CM_NAME)

SPI_CONTROLLER_BOARD_TOP = top_SPI_controller_board
SPI_CONTROLLER_BOARD_OUTPUT = -o simv_spi_controller_board
SPI_CONTROLLER_BOARD_SRC_FILES = \
	src/rtl/serial_protocol_pkg.sv \
	src/rtl/board/custom_ip_master.sv \
	src/rtl/board/fnd_status_display.sv \
	src/rtl/spi/SPI_controller.sv \
	src/rtl/$(SPI_CONTROLLER_BOARD_TOP).sv

SPI_TARGET_BOARD_TOP = top_SPI_target_board
SPI_TARGET_BOARD_OUTPUT = -o simv_spi_target_board
SPI_TARGET_BOARD_SRC_FILES = \
	src/rtl/serial_protocol_pkg.sv \
	src/rtl/board/custom_ip_slave.sv \
	src/rtl/board/fnd_status_display.sv \
	src/rtl/spi/SPI_target.sv \
	src/rtl/$(SPI_TARGET_BOARD_TOP).sv

I2C_CONTROLLER_BOARD_TOP = top_I2C_controller_board
I2C_CONTROLLER_BOARD_OUTPUT = -o simv_i2c_controller_board
I2C_CONTROLLER_BOARD_SRC_FILES = \
	src/rtl/serial_protocol_pkg.sv \
	src/rtl/i2c/I2C_controller.sv \
	src/rtl/$(I2C_CONTROLLER_BOARD_TOP).sv

I2C_TARGET_BOARD_TOP = top_I2C_target_board
I2C_TARGET_BOARD_OUTPUT = -o simv_i2c_target_board
I2C_TARGET_BOARD_SRC_FILES = \
	src/rtl/serial_protocol_pkg.sv \
	src/rtl/i2c/I2C_target.sv \
	src/rtl/$(I2C_TARGET_BOARD_TOP).sv

SPI_TOP = tb_SPI
SPI_SIMV = simv_spi
SPI_SRC_FILES = \
	src/rtl/spi/SPI_controller.sv \
	src/rtl/spi/SPI_target.sv \
	src/tb/tb_SPI.sv

I2C_TOP = tb_I2C
I2C_SIMV = simv_i2c
I2C_SRC_FILES = \
	src/rtl/i2c/I2C_controller.sv \
	src/rtl/i2c/I2C_target.sv \
	src/rtl/i2c/I2C.sv \
	src/tb/tb_I2C.sv

.PHONY: all comp compile simv cov wave-comp wave verdi-src sim-diagram spi-comp spi-sim spi-verdi i2c-comp i2c-sim i2c-verdi spi-controller-board-comp spi-target-board-comp spi-board-comp i2c-controller-board-comp i2c-target-board-comp i2c-board-comp board-comp remote-check remote-sync remote-make simv-remote cov-remote wave-remote board-comp-remote help clean

all: simv

comp compile:
	vcs $(VCS_OPTS) $(VCS_SRC_FILES) -top $(TOP) $(VCS_OUTPUT)
	@echo "타겟 [$@]"

simv: comp
	./simv $(SIMV_OPTS)
	@echo "의존 타겟 [$<]"
	@echo "타겟 [$@]"

cov: simv
	urg -full64 -dir simv.vdb -report cov_report
	@echo ""
	@echo "==> 리포트: cov_report/dashboard.html"

wave-comp:
	vcs $(WAVE_VCS_OPTS) $(VCS_SRC_FILES) -top $(TOP) -o $(WAVE_SIMV)
	@echo "타겟 [$@]"

wave: wave-comp
	mkdir -p $(WAVE_DIR)
	./$(WAVE_SIMV) $(SIMV_OPTS) +DUMP_FSDB +DUMP_VCD +WAVE_BASENAME=$(CM_NAME)
	@echo "파형: $(WAVE_DIR)/$(CM_NAME).fsdb"
	@echo "보조 파형: $(WAVE_DIR)/$(CM_NAME).vcd"

verdi-src:
	DISPLAY=$(VERDI_DISPLAY) verdi -sv $(VCS_SRC_FILES) -top $(TOP) &

sim-diagram:
	python3 tools/gen_sim_structure_diagram.py
	@echo "구조도: docs/diagrams/sim_structure.html"
	@echo "보조 SVG: docs/diagrams/sim_structure.svg"

spi-comp:
	vcs $(DIRECTED_VCS_OPTS) $(SPI_SRC_FILES) -top $(SPI_TOP) -o $(SPI_SIMV)
	@echo "타겟 [$@]"

spi-sim: spi-comp
	mkdir -p $(WAVE_DIR)
	./$(SPI_SIMV) +DUMP_FSDB +DUMP_VCD
	@echo "파형: $(WAVE_DIR)/tb_SPI.fsdb"
	@echo "보조 파형: $(WAVE_DIR)/tb_SPI.vcd"

spi-verdi: spi-sim
	DISPLAY=$(VERDI_DISPLAY) verdi -sv $(SPI_SRC_FILES) -top $(SPI_TOP) -ssf $(WAVE_DIR)/tb_SPI.fsdb &

i2c-comp:
	vcs $(DIRECTED_VCS_OPTS) $(I2C_SRC_FILES) -top $(I2C_TOP) -o $(I2C_SIMV)
	@echo "타겟 [$@]"

i2c-sim: i2c-comp
	mkdir -p $(WAVE_DIR)
	./$(I2C_SIMV) +DUMP_FSDB +DUMP_VCD
	@echo "파형: $(WAVE_DIR)/tb_I2C.fsdb"
	@echo "보조 파형: $(WAVE_DIR)/tb_I2C.vcd"

i2c-verdi: i2c-sim
	DISPLAY=$(VERDI_DISPLAY) verdi -sv $(I2C_SRC_FILES) -top $(I2C_TOP) -ssf $(WAVE_DIR)/tb_I2C.fsdb &

spi-controller-board-comp:
	vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb -lca $(SPI_CONTROLLER_BOARD_SRC_FILES) -top $(SPI_CONTROLLER_BOARD_TOP) $(SPI_CONTROLLER_BOARD_OUTPUT)
	@echo "타겟 [$@]"

spi-target-board-comp:
	vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb -lca $(SPI_TARGET_BOARD_SRC_FILES) -top $(SPI_TARGET_BOARD_TOP) $(SPI_TARGET_BOARD_OUTPUT)
	@echo "타겟 [$@]"

spi-board-comp: spi-controller-board-comp spi-target-board-comp
	@echo "SPI Controller/Target board top compile 확인 완료"

i2c-controller-board-comp:
	vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb -lca $(I2C_CONTROLLER_BOARD_SRC_FILES) -top $(I2C_CONTROLLER_BOARD_TOP) $(I2C_CONTROLLER_BOARD_OUTPUT)
	@echo "타겟 [$@]"

i2c-target-board-comp:
	vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb -lca $(I2C_TARGET_BOARD_SRC_FILES) -top $(I2C_TARGET_BOARD_TOP) $(I2C_TARGET_BOARD_OUTPUT)
	@echo "타겟 [$@]"

i2c-board-comp: i2c-controller-board-comp i2c-target-board-comp
	@echo "I2C Controller/Target board top compile 확인 완료"

board-comp: spi-board-comp i2c-board-comp
	@echo "SPI/I2C 보드 top compile 확인 완료"

remote-check:
	REMOTE_HOST=$(REMOTE_HOST) REMOTE_PROJECT_DIR=$(REMOTE_PROJECT_DIR) $(REMOTE_MAKE) check

remote-sync:
	REMOTE_HOST=$(REMOTE_HOST) REMOTE_PROJECT_DIR=$(REMOTE_PROJECT_DIR) $(REMOTE_SYNC)

remote-make:
	REMOTE_HOST=$(REMOTE_HOST) REMOTE_PROJECT_DIR=$(REMOTE_PROJECT_DIR) $(REMOTE_MAKE) $(REMOTE_TARGET)

simv-remote: remote-sync
	REMOTE_HOST=$(REMOTE_HOST) REMOTE_PROJECT_DIR=$(REMOTE_PROJECT_DIR) $(REMOTE_MAKE) simv TEST=$(TEST) SEED=$(SEED) INFO_LEVEL=$(INFO_LEVEL) CM_NAME=$(CM_NAME)

cov-remote: remote-sync
	REMOTE_HOST=$(REMOTE_HOST) REMOTE_PROJECT_DIR=$(REMOTE_PROJECT_DIR) $(REMOTE_MAKE) cov TEST=$(TEST) SEED=$(SEED) INFO_LEVEL=$(INFO_LEVEL) CM_NAME=$(CM_NAME)

wave-remote: remote-sync
	REMOTE_HOST=$(REMOTE_HOST) REMOTE_PROJECT_DIR=$(REMOTE_PROJECT_DIR) $(REMOTE_MAKE) wave TEST=$(TEST) SEED=$(SEED) INFO_LEVEL=$(INFO_LEVEL) CM_NAME=$(CM_NAME)

board-comp-remote: remote-sync
	REMOTE_HOST=$(REMOTE_HOST) REMOTE_PROJECT_DIR=$(REMOTE_PROJECT_DIR) $(REMOTE_MAKE) board-comp

help:
	@echo "make comp        : UVM testbench compile"
	@echo "make simv        : compile 후 UVM smoke simulation 실행"
	@echo "make cov         : simv.vdb coverage report 생성"
	@echo "make wave        : UVM test 전체 FSDB/VCD 파형 저장"
	@echo "make verdi-src   : filelist.f 기준으로 Verdi source browser 실행"
	@echo "make sim-diagram : simulation 구조도 SVG 생성"
	@echo "make spi-sim     : SPI directed TB 실행 후 FSDB/VCD 생성"
	@echo "make spi-verdi   : SPI directed TB FSDB를 Verdi로 열기"
	@echo "make i2c-sim     : I2C directed TB 실행 후 FSDB/VCD 생성"
	@echo "make i2c-verdi   : I2C directed TB FSDB를 Verdi로 열기"
	@echo "make spi-controller-board-comp : SPI Controller board top compile 확인"
	@echo "make spi-target-board-comp     : SPI Target board top compile 확인"
	@echo "make spi-board-comp            : SPI Controller/Target board top 둘 다 compile 확인"
	@echo "make i2c-controller-board-comp : I2C Controller board top compile 확인"
	@echo "make i2c-target-board-comp     : I2C Target board top compile 확인"
	@echo "make i2c-board-comp            : I2C Controller/Target board top 둘 다 compile 확인"
	@echo "make board-comp                : SPI/I2C FPGA board top compile 확인"
	@echo "make remote-check              : pedu07 원격 프로젝트/VCS/Make 경로 확인"
	@echo "make remote-sync               : 로컬 source를 pedu07 프로젝트로 동기화"
	@echo "make simv-remote               : remote-sync 후 pedu07에서 make simv 실행"
	@echo "make cov-remote                : remote-sync 후 pedu07에서 make cov 실행"
	@echo "make wave-remote               : remote-sync 후 pedu07에서 UVM FSDB/VCD 파형 저장"
	@echo "make board-comp-remote         : remote-sync 후 pedu07에서 make board-comp 실행"
	@echo "make remote-make REMOTE_TARGET=target : 동기화 없이 pedu07에서 임의 make target 실행"
	@echo "make clean       : VCS/coverage 생성물 정리"
	@echo ""
	@echo "override 예:"
	@echo "  make simv TEST=serial_smoke_test SEED=1 INFO_LEVEL=UVM_MEDIUM"
	@echo "  make simv-remote TEST=serial_smoke_test SEED=1 INFO_LEVEL=UVM_MEDIUM"
	@echo "  make wave-remote TEST=serial_smoke_test SEED=260618 CM_NAME=serial_smoke_full"
	@echo "  make remote-make REMOTE_TARGET=spi-sim"
	@echo "  make verdi-src VERDI_DISPLAY=:7"

clean:
	rm -rf simv simv.daidir simv.vdb simv_wave simv_wave.daidir simv_spi simv_spi.daidir simv_i2c simv_i2c.daidir
	rm -rf simv_spi_board simv_spi_board.daidir simv_spi_controller_board simv_spi_controller_board.daidir
	rm -rf simv_spi_target_board simv_spi_target_board.daidir simv_i2c_controller_board simv_i2c_controller_board.daidir
	rm -rf simv_i2c_target_board simv_i2c_target_board.daidir simv_i2c_board simv_i2c_board.daidir
	rm -rf simv_board simv_board.daidir csrc cov_report $(WAVE_DIR)
	rm -rf *.log *.key *.h DVEfiles ucli.key novas.* verdiLog
	@echo "결과물 정리 중 ..."
