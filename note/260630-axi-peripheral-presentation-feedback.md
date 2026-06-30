# 26-06-30 - AXI Peripheral 발표 피드백

이 메모는 AXI Peripheral 발표 자료를 다듬을 때 반영할 피드백과 수정 방향을 정리한 것이다. 일반 수업 내용 정리라기보다 발표 자료 수정 기준으로 사용한다.

## 핵심 수정 방향

- 발표 자료의 구조 그림은 `Application`, `Driver`, `HAL`, `Hardware` 계층이 명확히 보이도록 다시 정리한다.
- `IIC`, `SPI`, 외부 target board가 구조 그림의 하위 장치처럼 떨어져 보이면 안 된다. 발표에서는 통신 IP와 외부 target 장치의 위치가 system architecture 안에서 자연스럽게 드러나야 한다.
- `Driver`는 driver 계층에 두고, `HAL`은 GPIO/MMIO/register access처럼 hardware register에 가까운 제어 계층으로 분리한다.
- `FND`는 board-visible output 장치이고, 실제 제어는 GPIO 또는 custom peripheral register를 거쳐 이루어진다. 따라서 `FND Driver`와 `GPIO HAL`을 같은 계층으로 섞지 않는다.
- `SPI`와 `IIC`도 동일하게 application이 직접 register를 만지는 그림이 아니라, driver/HAL/MMIO/register interface를 거쳐 peripheral에 접근하는 흐름으로 표현한다.

## 계층 구조 수정 메모

발표 그림에서 계층이 섞이면 코드 구조를 통으로 만든 것처럼 보인다. 계층이 분리되어 있으면 hardware나 HAL이 바뀌어도 driver 또는 HAL 일부만 수정하면 되지만, 계층이 섞인 구조에서는 application, driver, HAL을 모두 다시 봐야 한다. 발표에서는 이 차이를 설명할 수 있어야 한다.

권장 설명 흐름은 다음과 같다.

```text
Application
-> Device Driver
-> HAL / MMIO Access
-> AXI4-Lite Register Interface
-> Custom IP / Board I/O
```

`Application`은 무엇을 할지 결정하고, `Driver`는 장치 단위 기능 API를 제공하며, `HAL/MMIO`는 base address와 offset을 이용해 register를 읽고 쓴다. `Custom IP`는 AXI4-Lite subordinate peripheral로 register request를 받아 실제 LED, FND, IIC, SPI 관련 동작으로 연결한다.

## 그림별 점검 항목

| 그림 | 수정 기준 |
| :--- | :--- |
| System Architecture | MicroBlaze, AXI Interconnect, custom IP, board I/O의 위치를 먼저 분명히 표시 |
| Firmware Layer | application, driver, HAL, MMIO/register access를 계층별로 분리 |
| IIC Board-to-Board Flow | firmware register write가 IIC transaction을 만들고 두 번째 Basys3 target board로 전달되는 흐름 표시 |
| SPI Flow | SPI가 포함될 경우 IIC와 같은 레벨의 custom IP 또는 appendix 구현 파트로 분리 |
| FND/GPIO | FND Driver와 GPIO HAL을 섞지 않고, FND가 GPIO/register를 통해 구동됨을 표시 |

## 발표에서 방어해야 할 질문

| 질문 | 답변 방향 |
| :--- | :--- |
| 왜 C code를 설명하는가 | MicroBlaze SoC는 firmware가 register map을 제어해야 peripheral demo가 동작하기 때문 |
| Driver와 HAL을 왜 나누는가 | 장치 기능 API와 hardware register access 책임을 분리해 수정 범위를 줄이기 위함 |
| IIC target board는 어디에 위치하는가 | IIC controller는 custom IP 내부 또는 연결 peripheral이고, 두 번째 Basys3 보드는 IIC target 장치 |
| UVM은 무엇을 검증하는가 | firmware가 아니라 RTL/IP interface behavior와 register transaction을 검증 |
| 보드 증거는 무엇을 보여주는가 | serial log, Logic2 decode, target board LED 출력은 서로 다른 evidence class임 |

## 수정 우선순위

1. Firmware layer 그림을 다시 작성해 `Application -> Driver -> HAL/MMIO -> AXI Register -> Custom IP` 흐름으로 정리
2. IIC, SPI, target board, FND, GPIO의 위치를 system architecture와 firmware flow에서 일관되게 수정
3. Memory map과 register map을 발표 자료에 반드시 포함
4. UVM 설명은 RTL/IP 검증 근거로 짧게 배치하고, firmware/board demo와 섞지 않기
5. 수정한 발표 자료를 다음 발표 전까지 다시 업로드

## 발표 태도 메모

피드백은 자료를 공격하려는 목적이 아니라, 기술 면접이나 외부 발표에서 구조가 흔들리지 않게 만들기 위한 수정 기회로 본다. 발표 자료는 보기 좋게 꾸미는 것보다 계층, 책임, 검증 근거가 정확해야 한다. 질문을 받았을 때 `왜 이렇게 나누었는지`, `어떤 evidence로 확인했는지`, `내가 직접 수정한 부분이 무엇인지`를 짧게 답할 수 있어야 한다.
