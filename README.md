# korchamhrd_ai_chip_design

[한국어](README.md) | [English](README.en.md)

대한상공회의소 HRD 계열 온디바이스 AI 반도체 설계 과정의 수업 노트, 개인 미니 프로젝트, Classroom 운영 도구를 모아두는 작업 저장소입니다.

이 과정은 경기도팹리스아카데미와 함께 진행되는 수업 맥락을 포함하며, 대한상공회의소 서울기술교육센터 운영 흐름 안에서 사용합니다. 저장소 이름은 신청/교육 도메인인 `korchamhrd`와 수업 중심 주제인 `ai_chip_design`을 기준으로 정리했습니다.

이 저장소는 과정/수업에 직접 연결되는 자료를 두는 곳입니다. 수업 노트, Verilog/SystemVerilog/UVM/RISC-V 기반 미니 프로젝트, 재사용 가능한 Classroom 자동화, 과제 패키징 도구, 산출물 템플릿, 공유 가능한 수업 운영 자료는 여기에 둡니다. 개인 장비 자동화나 수업과 직접 관련 없는 운영 도구는 `~/git/tool`에 둡니다.

GitHub: <https://github.com/mumallaeng/korchamhrd_ai_chip_design>

## 구성

- `note/`: 반도체 설계 수업 노트, 실습 정리, 다이어그램, 임시 staging 자료를 둡니다.
- `mini_project-*`: 수업 중 작성한 개인 FPGA/RTL/검증/프로세서 미니 프로젝트를 둡니다.
- `AXI_Peripheral/`, `ascii-uart-sensor-pipeline/`, `KorchamLogis/`, `testudines/`: 수업 기간과 맞물리지만 구현 소스를 별도 GitHub 저장소로 관리하는 프로젝트로, git submodule로 연결해둡니다.
  - `AXI_Peripheral`: `260618`~`260630` AXI/MicroBlaze 수업 기간에 진행한 AXI 주변장치 설계 프로젝트.
  - `ascii-uart-sensor-pipeline`: `260421`~`260430` UART/FIFO 수업 기간에 진행한 Basys 3 대상 UART 센서 파이프라인 프로젝트. `mini_project-UART_FIFO`가 이 저장소 안에 커밋 원본을 보존한 초기 결과물이라면, 이 프로젝트는 그 결과물을 정리해 별도 저장소로 옮긴 후속 버전입니다.
  - `KorchamLogis`: 8조(팔아조)로 진행한 자율주행 로봇 기반 매장 물류 자동화 시스템 팀 프로젝트.
  - `testudines`: `260723`~`260727` 진행한 G51 로봇팔 Cortex-M4 bare-metal PWM/UART/ADC 제어 프로젝트에서 시작해, 현재는 ROS2 + FPGA NPU 통합으로 이어지는 개인 장기 프로젝트.
- `clear-spreadsheet/`: Google Sheets에서 의도하지 않은 표/테마 배경색이 보이는 `.xlsx` 파일을 정리합니다.
- `classroom/deliverable-share/`: Google Classroom 산출물을 검증하고, Drive 폴더 공유와 비공개 댓글용 copybook 생성을 처리합니다.
- `classroom/project-packager/`: 과제 제출 폴더를 보고서, 일정표, 일지, 미디어, 소스 번들 규칙에 맞춰 구성합니다.

## 범위

- 과정/수업에 직접 연결되는 노트, 프로젝트, 자동화, 템플릿은 이 저장소에 둡니다.
- 인증 정보, OAuth 토큰, 로컬 `config.local.json`, 생성된 제출물 리포트, virtualenv는 Git에 커밋하지 않습니다.
- 개인 유틸리티, 세션 관리, STT 보조 도구, 아카이브 도구, 수업과 직접 관련 없는 운영 스크립트는 `~/git/tool`에 둡니다.

## 빠른 시작

각 도구는 자기 디렉터리 안에 setup/run 스크립트를 둡니다.

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
