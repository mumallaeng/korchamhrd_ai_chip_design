# MSP2402 2.4 inch SPI Schematic

원본 위치: `/Users/mumallaeng/Library/CloudStorage/GoogleDrive-yonnmilk@gmail.com/My Drive/Classroom/대한상공회의소_반도체설계/김-/참고자료(Cortex-M4)/7.MSP2402-2.4-SPI_Schematic.pdf`

## 핵심 용도

2.4 inch SPI TFT 모듈의 LCD, 터치 컨트롤러, SD 카드, 백라이트, 전원 선택 회로를 확인하는 회로도다. SPI 버스를 여러 장치가 공유할 때 각 장치의 chip select와 신호 분리를 확인하는 데 사용한다.

## 주요 블록

| 블록 | 내용 | 관련 신호 |
|---|---|---|
| TFT LCD FPC | LCD 패널 연결 | `TFT_RESET`, `TFT_SCK`, `TFT_RS`, `TFT_CS`, `TFT_SDI`, `TFT_SDO`, `TFT_BL` |
| 터치 컨트롤러 | `XPT2046` 터치 샘플링 회로 | `TP_CLK`, `TP_CS`, `TP_DIN`, `TP_OUT`, `TP_IRQ` |
| SD 카드 | microSD SPI 인터페이스 | `SD_CS`, `SD_MOSI`, `SD_MISO`, `SD_CLK` |
| 백라이트 | LCD backlight 제어 | `TFT_BL`, high active, IO/PWM 제어 가능 |
| 전원 선택 | 5V/3.3V 입력 선택 | `J1`, `XC6206` regulator |
| 확장 커넥터 | 모듈 외부 연결 | `J2`, VCC/GND/TFT/TP/SD 신호 |

## SPI 버스 관점

| 장치 | 공유 가능 신호 | 분리해야 할 신호 |
|---|---|---|
| TFT LCD | `SCK`, `MOSI`, `MISO` | `TFT_CS`, `TFT_RS`, `TFT_RESET` |
| Touch | `TP_CLK`, `TP_DIN`, `TP_OUT` | `TP_CS`, `TP_IRQ` |
| SD card | `SD_CLK`, `SD_MOSI`, `SD_MISO` | `SD_CS` |

## 수업 연결

- LCD, 터치, SD 카드가 모두 SPI 계열 신호를 쓰기 때문에 CS 라인 관리가 중요하다.
- `TFT_RS`는 데이터/명령 구분 신호로, 단순 chip select와 역할이 다르다.
- `TFT_BL`은 화면 표시 데이터와 별개로 백라이트 밝기를 제어하는 신호다.
- 터치 입력은 `TP_IRQ`로 이벤트를 받고, 실제 좌표는 `XPT2046`를 SPI로 읽는 구조다.
- 전원을 5V로 넣는지 3.3V로 넣는지에 따라 `J1` 설정과 레귤레이터 경로를 확인해야 한다.
