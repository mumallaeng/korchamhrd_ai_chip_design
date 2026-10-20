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

팀 프로젝트는 각각 별도 저장소에서 관리하고, 이 저장소에는 git submodule로 연결해 두었습니다.

## 구성

- `note/`: 수업 노트, 실습 정리, 다이어그램
- `mini_project-*`: 수업별 개인 미니 프로젝트
- `final/vibro-acoustic-fault-diagnosis/`: 파이널 프로젝트 주제를 검토할 때 만든 진동·음향 고장 진단 software golden model 실험
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
