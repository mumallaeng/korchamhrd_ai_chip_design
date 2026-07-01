# M4 Nucleo GCC Tool 설치 가이드

원본 위치: `/Users/mumallaeng/Library/CloudStorage/GoogleDrive-yonnmilk@gmail.com/My Drive/Classroom/대한상공회의소_반도체설계/김-/C_M4_Python_툴_설치가이드/2.M4_Nucleo_GCC_TOOL_설치_가이드(STLink_VSCode).pdf`

## 핵심 용도

`M4-Nucleo` 보드 실습을 위해 ARM GCC 툴체인, `STM32CubeProgrammer`, `ST-LINK`, `Tera Term`, `VSCode`를 연결하는 환경 구축 절차다. 최종 확인은 `2.ARM_LAB/0001.COMPILE_TEST` 예제에서 `make`와 `make run`으로 진행한다.

## 설치 흐름

| 단계 | 내용 | 확인 포인트 |
|---|---|---|
| 보드 연결 | `M4-Nucleo` 보드와 USB 케이블 연결 | 전원 LED 점등 |
| ARM GCC 배치 | `01.GCC_Compiler` 안의 툴체인 폴더를 `C:` 드라이브로 복사 | 폴더가 이중 중첩되지 않게 배치 |
| `ST-LINK` 설치 | `SetupSTM32CubeProgrammer_win64.exe` 실행 | 기본 설치 경로 유지 |
| 환경변수 설정 | GCC와 `STM32CubeProgrammer`의 `bin` 경로를 `Path`에 추가 | 사용자/시스템 `Path` 모두 확인 |
| `Tera Term` 설치 | `teraterm-4.85.exe` 실행 | Serial 연결용 |
| 가상 COM 확인 | 장치 관리자 `Ports (COM & LPT)` 확인 | `STMicroelectronics STLink Virtual COM Port` |
| 터미널 설정 | `Tera Term`에서 Serial, baud rate `115200` 설정 | 설정 저장 시 `TERATERM.INI` 반영 |
| 예제 실행 | `0001.COMPILE_TEST`에서 빌드와 다운로드 | 터미널 출력 확인 |

## 주요 경로와 명령

| 항목 | 값 |
|---|---|
| ARM GCC `bin` | `C:\arm-gnu-toolchain-15.2.rel1-mingw-w64-i686-arm-none-eabi\bin` |
| CubeProgrammer `bin` | `C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin` |
| 실습 폴더 | `2.ARM_LAB/0001.COMPILE_TEST` |
| 빌드 | `make` |
| 보드 다운로드 | `make run` |
| 빌드 산출물 정리 | `make clean` |
| UART 속도 | `115200` |

## 실습 체크리스트

- 보드가 PC에 연결되어 전원이 들어오는지 먼저 확인한다.
- `Path`가 틀리면 ARM GCC 또는 `STM32_Programmer_CLI` 계열 실행 문제가 발생한다.
- `Tera Term`은 보드 출력 확인용이라, 다운로드 성공만 보고 끝내지 말고 UART 출력까지 본다.
- `make run`은 생성된 `.elf`를 보드에 다운로드하는 단계로 이해한다.
- COM 포트 번호는 PC마다 달라질 수 있으므로 장치 관리자 기준으로 고른다.
