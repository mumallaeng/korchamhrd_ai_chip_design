# korchamhrd_ai_chip_design

[한국어](README.md) | English

> Working repository for the class notes, personal mini projects, and Classroom operations tools from *[Consortium] On-Device AI System Semiconductor Design, 2nd Cohort*.

## Mini Projects

| Project | Period | Class | Type |
| --- | --- | --- | --- |
| [KorchamLogis](KorchamLogis) | 2026.03.24 ~ 04.03 | Arduino | Team (submodule) |
| [Timepiecer](Timepiecer) | 2026.04.16 ~ 04.20 | Verilog | Team (submodule) |
| [UART LOOPBACK](mini_project-UART_FIFO) | 2026.04.22 ~ 04.27 | Verilog | Personal |
| [ascii-uart-sensor-pipeline](ascii-uart-sensor-pipeline) | 2026.05.01 ~ 05.06 | Verilog | Team (submodule) |
| [SystemVerilog UART FIFO Verification](mini_project-SV_Verification) | 2026.05.12 ~ 05.17 | SystemVerilog | Personal |
| [RV32I Single-Cycle CPU](mini_project-RV32I) | 2026.05.22 ~ 05.27 | RISC-V CPU | Personal |
| [SPI/I2C UVM Verification](mini_project-UVM_SPI_I2C) | 2026.06.11 ~ 06.18 | UVM | Personal |
| [AXI_Peripheral](AXI_Peripheral) | 2026.06.22 ~ 06.30 | AXI and MicroBlaze | Team (submodule) |
| [G51 Robot Arm Cortex-M4 Control](mini_project-Cortex-M4) | 2026.07.23 ~ 07.27 | Embedded | Personal |
| [Wardy](wardy) | 2026.08.05 ~ 08.19 | On-Device AI | Team (submodule) |

Team projects live in their own repositories and are linked here as git submodules.

## Layout

- `note/`: class notes, lab writeups, and diagrams
- `mini_project-*`: personal mini projects, one per class
- `final/vibro-acoustic-fault-diagnosis/`: software golden-model experiments for vibro-acoustic fault diagnosis, made while choosing the final project topic
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
