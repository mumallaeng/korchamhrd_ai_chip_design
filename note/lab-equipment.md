# 실습 장비 목록

Korcham 과정에서 사용했거나 사용 예정인 실습 장비를 모아 기록한다. 아래 장비는 개인 구매 보유품과 분리하여 교육과정 기간의 대여·반납 대상으로 관리한다. 장비별 상세 사양이 필요하면 개별 장비 노트에 정리하고 이 목록에서 링크한다.

| 장비 | 분류 | 사용 영역 | 상태 | 상세 노트 |
| :--- | :--- | :--- | :--- | :--- |
| Arduino Full Kit `EK100` | MCU 입문 kit | 전자회로·embedded 기초 실습 | 대여 중 | 반납 정책 미확정. 반납 대상으로 관리 |
| Digilent Basys3 | Artix-7 FPGA board | Verilog HDL 설계·합성 실습 | 대여 중 | 교육과정 기간 대여·반납 대상 |
| STM32 NUCLEO-F411RE | Cortex-M4 개발 보드 | M4/Embedded 영역 (GPIO, UART, timer, interrupt) | **반납 완료** | 교육과정 기간 대여·반납 대상. 사양은 아래 장비 메모에 보존 |
| NVIDIA Jetson Orin Nano Developer Kit | 온-디바이스 AI platform | AI 영역 (향후 수업) | **반납 완료** | 2026-08-19까지 사용 가능한 대여·반납 대상, [장비 기록](jetson-orin-nano-developer-kit.md)(사양 보존) |

## 장비 메모

- Arduino Full Kit `EK100`: breadboard, sensor, actuator류를 포함한 구성 kit. 전자회로 배선 실습의 부품 공급원으로도 사용한다. 반납 정책을 확인하기 전까지 키트 구성품을 개인 보유품과 섞지 않는다.
- Basys3: Verilog HDL 과정에서 XDC constraint 기반 pin mapping과 FND·UART 실습에 사용했다. 관련 정리는 [Basys3 XDC constraints 복습 노트](260406-260529-복습노트-03-basys3-xdc-constraints.md) 참고.
- STM32 development tools (반납 완료): M4/Embedded 영역의 register 직접 제어 실습 환경으로 사용했다. GPIO·clock·UART 실습 흐름은 날짜별 노트(`2607xx-*.md`) 참고. 사양은 나중에 다시 필요할 수 있어 삭제하지 않고 여기 보존한다.
- Jetson Orin Nano (반납 완료): AI 영역 실습용 대여 장비였다. 식별 정보와 사양은 [장비 기록](jetson-orin-nano-developer-kit.md)에 그대로 보존한다.

## 원격 컴퓨팅 환경

아래 사양은 2026-08-10에 각 host에 직접 접속하여 확인한 값이다. Korcham 교육과정 기간에 사용하는 공용 환경이며, 계정·접속 정보는 별도로 관리한다.

### Windows 접속 host

| 항목 | 확인값 |
| :--- | :--- |
| 제품 | LG Electronics `27V70Q-GA70K` |
| OS | Windows 11 Pro |
| CPU | 12th Gen Intel Core i7-1260P, 12 cores / 16 threads |
| Memory | 15.7 GiB |
| GPU | Intel Iris Xe Graphics |
| NVIDIA CUDA | 지원 장치 없음 |
| 역할 | Tailscale 원격 접속 및 UVM Linux 서버 연결 경유 |

### UVM Linux 서버

| 항목 | 확인값 |
| :--- | :--- |
| Hostname | `kccipangyo1` |
| OS | Red Hat Enterprise Linux 8.10 |
| CPU | Intel Xeon Gold 6526Y, 2 sockets, 32 cores / 64 threads |
| Memory | 1.0 TiB |
| Root filesystem | 4.8 TiB, 확인 당시 여유 3.1 TiB |
| Display adapter | Matrox G200eW3 |
| NVIDIA CUDA | 지원 장치 없음 |
| 사용 범위 | Korcham 교육과정 기간 공용 UVM 실습 |
| 사용자 권한 | `pedu07` 일반 사용자, `sudo` 권한 없음 |

외부 `20022` 접속은 Windows host의 port forwarding을 거쳐 UVM Linux 서버로 연결된다. 서버 자체는 동작 중이었고 Windows host 내부에서는 접속에 성공했다. 외부 접속 실패 시 서버 중지로 단정하지 않고 port forwarding과 방화벽 상태를 함께 확인한다.
