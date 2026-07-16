# NVIDIA Jetson Orin Nano Developer Kit - 수업 장비 기록

> 상태: 반납 완료. 아래 식별 정보·사양은 추후 참고용으로 보존한다.

온-디바이스 AI 실습에 사용했던 개발 전용(for development use only) kit이며, 2026년 8월 19일까지 사용 가능했던 Korcham 대여·반납 대상 장비였다.

## 장비 식별 정보

| 항목 | 값 |
| :--- | :--- |
| 제품명 | NVIDIA Jetson Orin Nano Developer Kit |
| 탑재 module | NVIDIA Jetson Orin Nano 8GB Module |
| Model | `P3766` |
| Part Number | `945-13766-0005-000` |
| Serial Number | `1794325040810` |
| 전원 입력 | DC 9-19V, 5A MAX |
| 제조 | Made in Vietnam |
| 사용 가능 기한 | 2026-08-19 |

## 주요 사양

| 항목 | 사양 |
| :--- | :--- |
| GPU | 1024-core NVIDIA Ampere architecture, 32 Tensor Cores |
| CPU | 6-core Arm Cortex-A78AE v8.2 64-bit |
| Memory | 8GB 128-bit LPDDR5 |
| Storage | microSD card slot, M.2 Key M NVMe 확장 |

## I/O 구성

| 분류 | 구성 |
| :--- | :--- |
| Display | DisplayPort |
| USB | 4x USB 3.2 Gen2 Type-A, USB Type-C UFP |
| M.2 | Key M 2280, Key M 2230, Key E (WLAN module 장착됨) |
| Network | Gigabit Ethernet, 802.11ac WLAN + Bluetooth 5.0 (Key E module) |
| Expansion | 40-pin header (UART, SPI, I2S, I2C, PWM, GPIO) |
| Camera | 2x MIPI CSI-2 22-pin connector |
| 전원 | 1x DC jack |

## 구성품과 준비물

- 포함: DC power supply
- 별도 준비 필요: microSD card (system 부팅에 필수, 미포함)

40-pin expansion header가 UART, SPI, I2C, GPIO를 제공하므로 M4 영역에서 다룬 peripheral 지식을 Linux 기반 환경에서 재사용하는 실습 연결점이 될 수 있다.

## 참고

- 제품 정보: https://www.nvidia.com/jetson-orin
- 보증 조건: https://www.nvidia.com/warranty
