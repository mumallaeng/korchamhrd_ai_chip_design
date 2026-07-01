# Nucleo64 Schematic

원본 위치: `/Users/mumallaeng/Library/CloudStorage/GoogleDrive-yonnmilk@gmail.com/My Drive/Classroom/대한상공회의소_반도체설계/김-/참고자료(Cortex-M4)/3.Nucleo64_Schematic.pdf`

## 핵심 용도

STMicroelectronics `Nucleo-64` 보드의 전원, MCU, `STLINK/V2-1`, 확장 커넥터 연결을 확인하는 회로도다. 외부 확장 보드나 모듈을 붙일 때 MCU 핀과 보드 커넥터 사이의 실제 연결을 추적하는 데 사용한다.

## 시트 구성

| 시트 | 내용 |
|---|---|
| Project overview | 전체 회로 블록 개요 |
| Top and Power | 전원 입력, 레귤레이터, 보드 전원 선택 |
| MCU | STM32 MCU 핀 연결 |
| STLINK/V2-1 | 디버그, 다운로드, Virtual COM 관련 회로 |
| Extension connectors | Arduino/Morpho 계열 확장 커넥터 |

## 확인 포인트

| 주제 | 볼 내용 |
|---|---|
| 전원 | USB 전원, 외부 전원, `3V3`, `5V`, 전원 선택 점퍼 |
| 디버그 | `SWDIO`, `SWCLK`, reset, `ST-LINK` 연결 |
| Virtual COM | `ST-LINK`와 MCU USART 연결 |
| 확장 커넥터 | Arduino header, Morpho header 핀 이름 |
| GPIO/AF | MCU 핀 이름과 커넥터 핀 사이의 대응 |
| 보드 버튼/LED | 사용자 버튼, 사용자 LED 연결 핀 |

## 수업 연결

- `Tera Term`으로 UART 출력이 보이지 않을 때 Virtual COM 연결과 MCU USART 핀을 확인한다.
- 외부 확장 보드 연결 전에는 Nucleo 커넥터 핀 이름과 MCU 실제 핀을 분리해서 확인한다.
- `Datasheet`의 핀/AF 정보와 이 회로도를 같이 봐야 실습 핀 선택이 정확해진다.
- 다운로드 문제가 있으면 `STLINK/V2-1`, reset, SWD 연결을 먼저 점검한다.
