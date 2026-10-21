# korchamhrd_ai_chip_design

한국어 | [English](README.en.md)

> *[컨소시엄] 온디바이스AI 시스템반도체 설계 2기* 교육과정에서 모은 수업 노트, 개인 미니 프로젝트, Classroom 운영 도구를 모아두는 작업 저장소입니다.

## 미니 프로젝트

| 프로젝트 | 기간 | 수업 | 구분 |
| --- | --- | --- | --- |
| [KorchamLogis](KorchamLogis) | 2026.03.24 ~ 04.03 | Arduino | 팀 (submodule) |
| [Timepiecer](Timepiecer) | 2026.04.16 ~ 04.20 | Verilog | 팀 (submodule) |
| [UART LOOPBACK](mini_project-UART_FIFO) | 2026.04.22 ~ 04.27 | Verilog | 개인 |
| [ascii-uart-sensor-pipeline](ascii-uart-sensor-pipeline) | 2026.05.01 ~ 05.06 | Verilog | 팀 (submodule) |
| [SystemVerilog UART·FIFO 검증](mini_project-SV_Verification) | 2026.05.12 ~ 05.17 | SystemVerilog | 개인 |
| [RV32I Single-Cycle CPU](mini_project-RV32I) | 2026.05.22 ~ 05.27 | RISC-V CPU | 개인 |
| [SPI/I2C UVM 검증](mini_project-UVM_SPI_I2C) | 2026.06.11 ~ 06.18 | UVM | 개인 |
| [AXI_Peripheral](AXI_Peripheral) | 2026.06.22 ~ 06.30 | AXI·MicroBlaze | 팀 (submodule) |
| [G51 Robot Arm Cortex-M4 제어](mini_project-Cortex-M4) | 2026.07.23 ~ 07.27 | Embedded | 개인 |
| [Wardy](wardy) | 2026.08.05 ~ 08.19 | On-Device AI | 팀 (submodule) |
| [VGA Pan-Tilt Vision Tracker](VGA-Pan-Tilt-CCTV) | 2026.08.31 ~ 09.08 | VGA | 팀 (submodule) |
| [LightLetter](LightLetter) | 2026.09.09 ~ 10.15 | 파이널 프로젝트 | 팀 (submodule) |

팀 프로젝트는 각각 별도 저장소에서 관리하고, 이 저장소에는 git submodule로 연결해 두었습니다.

## 수업 노트

날짜별 노트는 [`note/`](note)에 있고, 수업별로 묶으면 다음과 같습니다.

| 수업 | 기간 | 주요 노트 |
| --- | --- | --- |
| Verilog HDL | 2026.04.06 ~ 04.16 | [OT](note/260406-ot.md), [Adder와 FND](note/260407-adder와-첫-fnd-표시.md), [FSM](note/260414-fsm-moore-mealy-버튼입력.md), [Stopwatch datapath](note/260416-stopwatch-datapath-tick-counter.md) |
| UART·FIFO | 2026.04.21 ~ 04.30 | [UART TX](note/260421-uart-tx-fsm.md), [UART TX/RX](note/260422-uart-tx-rx.md), [FIFO와 센서](note/260430-fifo-sensor-interface.md) |
| SystemVerilog 검증 | 2026.05.07 ~ 05.12 | [검증 입문](note/260507-systemverilog-검증입문.md), [검증 심화](note/260508-systemverilog-검증심화.md), [FIFO 검증](note/260512-systemverilog-fifo-검증.md) |
| RISC-V CPU | 2026.05.14 ~ 05.29 | [CPU 구조](note/260514-cpu-구조.md), [RV32I datapath](note/260519-rv32i-datapath.md), [Multicycle](note/260527-rv32i-multicycle.md), [APB](note/260529-apb-master-slave.md) |
| UVM | 2026.06.01 ~ 06.15 | [UVM OT](note/260601-uvm-ot.md), [UVM](note/260609-uvm.md), [SPI master](note/260611-spi-master.md), [SPI/I2C 보드 검증](note/260615-spi-i2c-board-validation.md) |
| AXI·MicroBlaze | 2026.06.18 ~ 06.30 | [AXI](note/260618-axi.md), [AXI4-Lite IP](note/260619-axi4-lite-ip-packaging.md), [MicroBlaze GPIO](note/260622-microblaze-gpio.md), [Timer·UART 인터럽트](note/260626-axi-timer-uart-microblaze-interrupt.md) |
| C·Python | 2026.07.01 ~ 07.10 | [C 기초](note/260701-vscode-gnu-c-basics.md), [Python 문법](note/260706-python-basic-syntax.md), [과정 개요](note/kdt-c-python-m4-ai-course-outline.md) |
| Embedded Cortex-M4 | 2026.07.13 ~ 07.24 | [Device programming](note/260713-arm-cortex-m4-device-programming.md), [Timer](note/260720-timer-control.md), [Interrupt](note/260721-interrupt-event-driven.md), [I2C·SPI](note/260722-i2c-spi-interface.md), [수업 지도](note/cortex-m4-firmware-course-map.md) |
| On-Device AI | 2026.07.28 ~ 08.04 | [딥러닝 1](note/260728-on-device-ai-deep-learning-1.md), [CNN](note/260729-on-device-ai-deep-learning-2-cnn.md), [Jetson 원격 개발](note/260730-jetson-remote-development-and-opencv-face-detection.md), [TensorRT](note/260803-on-device-ai-tensorrt-deployment-and-rps-camera-preprocessing.md), [수업 지도](note/embedded-linux-jetson-on-device-ai-course-map.md) |

## 구성

- `note/`: 수업 노트, 실습 정리, 다이어그램
- `mini_project-*`: 수업별 개인 미니 프로젝트
- `classroom/deliverable-share/`: Google Classroom 제출물 검증, Drive 폴더 공유, 비공개 댓글 copybook 생성
- `classroom/project-packager/`: 보고서·일정표·일지·미디어·소스를 제출 폴더 규칙에 맞춰 묶는 도구
- `clear-spreadsheet/`: Google Sheets에서 의도하지 않은 표·테마 배경색이 보이는 `.xlsx` 정리

인증 정보, OAuth 토큰, `config.local.json`, 생성된 제출물 리포트, virtualenv는 커밋하지 않습니다.

## 도구 실행

각 도구는 자기 디렉터리에 setup/run 스크립트가 있습니다.

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
