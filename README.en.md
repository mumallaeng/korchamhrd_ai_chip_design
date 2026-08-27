# korchamhrd_ai_chip_design

[한국어](README.md) | English

Workspace for class notes, personal mini projects, and Classroom operations tools from a Korcham HRD on-device AI chip design program.

The course context includes Gyeonggi Fabless Academy classes and the Korea Chamber of Commerce and Industry Seoul Technical Education Center operating workflow. The repository name uses the application/training domain `korchamhrd` and the course subject `ai_chip_design`.

This repository is intentionally course-facing. Keep class notes, Verilog/SystemVerilog/UVM/RISC-V mini projects, reusable classroom automation, assignment packaging helpers, deliverable templates, and shared materials here. Keep personal machine automation and unrelated operator tools in `~/git/tool`.

GitHub: <https://github.com/mumallaeng/korchamhrd_ai_chip_design>

## Layout

- `note/`: semiconductor design class notes, lab writeups, diagrams, and staging notes.
- `mini_project-*`: personal FPGA/RTL/verification/processor mini projects built during the course.
- `AXI_Peripheral/`, `ascii-uart-sensor-pipeline/`, `KorchamLogis/`, `wardy/`: projects tied to the course timeline whose implementation source lives in a separate GitHub repository, wired in as git submodules.
  - `AXI_Peripheral`: AXI peripheral design project from the `260618`-`260630` AXI/MicroBlaze class period.
  - `ascii-uart-sensor-pipeline`: Basys 3 UART sensor pipeline project from the `260421`-`260430` UART/FIFO class period. `mini_project-UART_FIFO` preserves the original commits for the early result in this repository; this project is the cleaned-up follow-up moved to its own repository.
  - `KorchamLogis`: team project (Team 8, "Paljo") building an autonomous-robot-based store logistics automation system.
  - `wardy`: team project (Team 9, "Jikyeojo") building a home care safety monitoring on-device AI platform.
- `clear-spreadsheet/`: clean `.xlsx` files whose Google Sheets view shows unintended table or theme background colors.
- `classroom/deliverable-share/`: validate Google Classroom deliverables, share Drive folders, and generate private-comment copybooks.
- `classroom/project-packager/`: build project submission folders from stable report, schedule, journal, media, and source-bundle patterns.

## Boundaries

- Course/classroom-specific notes, projects, automation, and templates belong here.
- Credentials, OAuth tokens, local `config.local.json`, generated submission reports, and virtualenvs stay out of Git.
- Personal utilities, session management, STT helpers, archive tooling, and non-course operator scripts stay in `~/git/tool`.

## Quick Start

Each tool keeps its own setup and run script.

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
