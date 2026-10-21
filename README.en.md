# korchamhrd_ai_chip_design

[한국어](README.md) | English

> Working repository for the class notes, personal mini projects, and Classroom operations tools from *[Consortium] On-Device AI System Semiconductor Design, 2nd Cohort*.

## Mini Projects

| Project | Period | Class | Type |
| --- | --- | --- | --- |
| [KorchamLogis](KorchamLogis) | 2026.03.24 ~ 04.03 | Arduino | Team |
| [Timepiecer](Timepiecer) | 2026.04.16 ~ 04.20 | Verilog | Team |
| [UART LOOPBACK](mini_project-UART_FIFO) | 2026.04.22 ~ 04.27 | Verilog | Personal |
| [ascii-uart-sensor-pipeline](ascii-uart-sensor-pipeline) | 2026.05.01 ~ 05.06 | Verilog | Team |
| [SystemVerilog UART FIFO Verification](mini_project-SV_Verification) | 2026.05.12 ~ 05.17 | SystemVerilog | Personal |
| [RV32I Single-Cycle CPU](mini_project-RV32I) | 2026.05.22 ~ 05.27 | RISC-V CPU | Personal |
| [SPI/I2C UVM Verification](mini_project-UVM_SPI_I2C) | 2026.06.11 ~ 06.18 | UVM | Personal |
| [AXI_Peripheral](AXI_Peripheral) | 2026.06.22 ~ 06.30 | AXI and MicroBlaze | Team |
| [G51 Robot Arm Cortex-M4 Control](mini_project-Cortex-M4) | 2026.07.23 ~ 07.27 | Embedded | Personal |
| [Wardy](wardy) | 2026.08.05 ~ 08.19 | On-Device AI | Team |
| [VGA Pan-Tilt Vision Tracker](VGA-Pan-Tilt-CCTV) | 2026.08.31 ~ 09.08 | VGA | Team |
| [LightLetter](LightLetter) | 2026.09.09 ~ 10.15 | Final project | Team |

Team projects live in their own repositories and are linked here as git submodules.

## Class Notes

Dated notes live in [`note/`](note). Grouped by class:

| Class | Period | Main notes |
| --- | --- | --- |
| Verilog HDL | 2026.04.06 ~ 04.16 | [OT](note/260406-ot.md), [Adder and FND](note/260407-adder와-첫-fnd-표시.md), [FSM](note/260414-fsm-moore-mealy-버튼입력.md), [Stopwatch datapath](note/260416-stopwatch-datapath-tick-counter.md) |
| UART and FIFO | 2026.04.21 ~ 04.30 | [UART TX](note/260421-uart-tx-fsm.md), [UART TX/RX](note/260422-uart-tx-rx.md), [FIFO and sensor](note/260430-fifo-sensor-interface.md) |
| SystemVerilog verification | 2026.05.07 ~ 05.12 | [Intro](note/260507-systemverilog-검증입문.md), [Advanced](note/260508-systemverilog-검증심화.md), [FIFO verification](note/260512-systemverilog-fifo-검증.md) |
| RISC-V CPU | 2026.05.14 ~ 05.29 | [CPU structure](note/260514-cpu-구조.md), [RV32I datapath](note/260519-rv32i-datapath.md), [Multicycle](note/260527-rv32i-multicycle.md), [APB](note/260529-apb-master-slave.md) |
| UVM | 2026.06.01 ~ 06.15 | [UVM OT](note/260601-uvm-ot.md), [UVM](note/260609-uvm.md), [SPI master](note/260611-spi-master.md), [SPI/I2C board validation](note/260615-spi-i2c-board-validation.md) |
| AXI and MicroBlaze | 2026.06.18 ~ 06.30 | [AXI](note/260618-axi.md), [AXI4-Lite IP](note/260619-axi4-lite-ip-packaging.md), [MicroBlaze GPIO](note/260622-microblaze-gpio.md), [Timer and UART interrupt](note/260626-axi-timer-uart-microblaze-interrupt.md) |
| C and Python | 2026.07.01 ~ 07.10 | [C basics](note/260701-vscode-gnu-c-basics.md), [Python syntax](note/260706-python-basic-syntax.md), [Course outline](note/kdt-c-python-m4-ai-course-outline.md) |
| Embedded Cortex-M4 | 2026.07.13 ~ 07.24 | [Device programming](note/260713-arm-cortex-m4-device-programming.md), [Timer](note/260720-timer-control.md), [Interrupt](note/260721-interrupt-event-driven.md), [I2C and SPI](note/260722-i2c-spi-interface.md), [Course map](note/cortex-m4-firmware-course-map.md) |
| On-Device AI | 2026.07.28 ~ 08.04 | [Deep learning 1](note/260728-on-device-ai-deep-learning-1.md), [CNN](note/260729-on-device-ai-deep-learning-2-cnn.md), [Jetson remote development](note/260730-jetson-remote-development-and-opencv-face-detection.md), [TensorRT](note/260803-on-device-ai-tensorrt-deployment-and-rps-camera-preprocessing.md), [Course map](note/embedded-linux-jetson-on-device-ai-course-map.md) |

## Layout

- `note/`: class notes, lab writeups, and diagrams
- `mini_project-*`: personal mini projects, one per class
- `classroom/deliverable-share/`: validates Google Classroom deliverables, shares Drive folders, and generates private-comment copybooks
- `classroom/project-packager/`: bundles reports, schedules, journals, media, and source into the submission folder layout
- `clear-spreadsheet/`: cleans `.xlsx` files whose Google Sheets view shows unintended table or theme background colors

Credentials, OAuth tokens, `config.local.json`, generated submission reports, and virtualenvs stay out of Git.

## Running the Tools

Each tool has its own setup and run script.

```sh
cd clear-spreadsheet
./setup.sh
./run.sh /path/to/workbook.xlsx
```

```sh
cd classroom/deliverable-share
./setup.sh
./run.sh scan --config config.local.json --scope all
```

```sh
cd classroom/project-packager
./setup.sh
./run.sh build examples/uart_loopback/config.json
```
