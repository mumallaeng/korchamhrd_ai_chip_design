# WS2812B Datasheet

원본 위치: `/Users/mumallaeng/Library/CloudStorage/GoogleDrive-yonnmilk@gmail.com/My Drive/Classroom/대한상공회의소_반도체설계/김-/참고자료(Cortex-M4)/6.WS2812B_Datasheet.pdf`

## 핵심 용도

`WS2812B`는 제어 회로와 RGB LED가 5050 패키지에 통합된 단선식 RGB LED다. MCU는 `DIN`에 정해진 타이밍의 직렬 데이터를 넣고, 각 LED는 24-bit 색상 데이터를 받아 체인 방식으로 다음 LED에 전달한다.

## 주요 특징

| 항목 | 내용 |
|---|---|
| 패키지 | 5050 RGB LED integrated controller |
| 통신 방식 | single-wire NZR protocol |
| 데이터 방향 | `DIN` 입력, `DOUT` 출력 |
| 색상 데이터 | 24-bit per pixel |
| 데이터 순서 | `G7..G0`, `R7..R0`, `B7..B0` |
| 동작 전압 | 약 `3.5 V` to `5.3 V` |
| 데이터 속도 | 약 `800 Kbps` |
| 캐스케이드 | 30 fps 기준 1024개 이상 가능 조건 |
| 입력 임계값 | HIGH 약 `0.7VDD`, LOW 약 `0.3VDD` |

## 타이밍

| 항목 | 값 |
|---|---|
| 전체 bit period | `1.25 us +/- 150 ns` |
| `T0H` | 약 `0.4 us` |
| `T0L` | 약 `0.85 us` |
| `T1H` | 약 `0.85 us` |
| `T1L` | 약 `0.4 us` |
| reset low time | `> 50 us` |

## 수업 연결

- 일반적인 UART/SPI/I2C처럼 주변장치 레지스터만 설정하면 끝나는 소자가 아니라, 파형 타이밍이 핵심이다.
- PWM, timer, DMA, 또는 정밀 delay 기반 bit-banging 구현 후보가 된다.
- 색상 순서가 RGB가 아니라 GRB이므로, 색상 값 배열을 만들 때 순서를 주의한다.
- `DOUT`이 다음 LED의 `DIN`으로 이어지는 체인 구조라 첫 번째 LED 데이터 이후의 24-bit들이 순서대로 뒤 LED로 전달된다.
- `VDD`가 5V 계열이면 MCU의 3.3V 출력이 입력 HIGH 조건을 만족하는지 보드 조건을 확인해야 한다.
