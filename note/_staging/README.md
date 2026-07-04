# _staging - 수업 선행 메모

`_staging`은 날짜별 수업메모에 병합하기 전, 자료별 핵심을 잠시 정리해 두는 공간이다. `staging`은 최종 노트에 반영하기 전의 준비/대기 상태라는 뜻이라, 선행 메모 폴더 이름으로 자연스럽다.

## 자료별 정리 파일

| 정리 파일 | 원본 자료 | 주 용도 |
|---|---|---|
| `m4-nucleo-tool-install.md` | `C_M4_Python_툴_설치가이드/2.M4_Nucleo_GCC_TOOL_설치_가이드(STLink_VSCode).pdf` | M4 Nucleo GCC, ST-LINK, Tera Term 환경 |
| `python-practice-tool-install.md` | `C_M4_Python_툴_설치가이드/3.파이썬_실습툴_설치가이드.pdf` | Python IDLE, VSCode 실습 환경 |
| `260702-python-lab-source-outline.md` | `상공회의소_KDT_실습자료(C_Python_M4)/2.Python/Py_Lab_for_VS_Code.py` | Python 전체 예제 본문 초안 |
| `260702-m4-arm-lab-source-outline.md` | `상공회의소_KDT_실습자료(C_Python_M4)/3.ARM_Lab` | M4/ARM 보드 실습 폴더 본문 초안 |
| `stm32f411re-datasheet.md` | `참고자료(Cortex-M4)/1.DataSheet_stm32f411re.pdf` | STM32F411RE 하드웨어 특성, 핀, 전기적 조건 |
| `stm32f411re-reference-manual.md` | `참고자료(Cortex-M4)/2.Reference_Manual_stm32f411re.pdf` | STM32F411 레지스터와 주변장치 동작 |
| `nucleo64-schematic.md` | `참고자료(Cortex-M4)/3.Nucleo64_Schematic.pdf` | Nucleo-64 보드 회로 연결 |
| `extension-board-schematic.md` | `참고자료(Cortex-M4)/4.Extension_Board_Schematic.pdf` | 확장 보드 회로와 외부 소자 연결 |
| `sc16is752-datasheet.md` | `참고자료(Cortex-M4)/5.SC16IS752_Datasheet.pdf` | I2C/SPI to dual UART 브리지 |
| `ws2812b-datasheet.md` | `참고자료(Cortex-M4)/6.WS2812B_Datasheet.pdf` | 단선식 RGB LED 구동 타이밍 |
| `msp2402-spi-schematic.md` | `참고자료(Cortex-M4)/7.MSP2402-2.4-SPI_Schematic.pdf` | SPI TFT, 터치, SD 카드 모듈 회로 |
| `vga-crt-display-timing.md` | VGA 사전 강의자료, 파일명 확인 필요 | CRT/VGA 타이밍과 FPGA 화면 출력 |

## 병합 기준

| 상황 | 처리 |
|---|---|
| 날짜별 수업에서 직접 사용 | 해당 날짜 메모로 핵심 흐름만 이동 |
| 실습 중 경로, 명령어, 핀맵 확인 필요 | 이 폴더의 자료별 노트를 참조 |
| 개념 설명으로 재사용 가능 | `Vault/domains` 쪽 개념 노트 후보로 분리 |
| 보고서나 발표에 들어갈 내용 | 출처 확인 후 사람 대상 문장으로 재작성 |
