[English](README.md) | 한국어

# G51 Robot Arm — Cortex-M4 Bare-Metal PWM/UART/ADC Control

김연우

2026.07.23~2026.07.27

## 1. 개요 (Overview)

### 1.1 목적 및 목표

이 프로젝트의 목적은 NUCLEO-F411RE(STM32F411RE, Cortex-M4) 위에서 HAL 없이 register-level bare-metal firmware를 작성해, G51 6자유도(6-DoF) 로봇팔 testudines의 여섯 관절을 PWM으로 동시에 구동하고, PC UART 키 입력과 조이스틱 ADC 입력 두 경로로 관절 목표를 실시간으로 조정하는 것이다.

최종 목표는 여섯 servo channel의 PWM을 하나의 timer/GPIO 초기화 흐름으로 통합하고, USART2 콘솔과 ADC1 joystick polling을 하나의 제어 loop 위에서 함께 동작시키며, 각 입력 경로의 결과를 UART echo로 즉시 확인할 수 있게 만드는 것이다.

핵심 목표는 아래와 같다.

- CMSIS-Device register 접근만으로 startup, timer PWM, USART2, ADC1을 구현한다.
- 여섯 관절의 pin/timer/channel 배정을 한 header에서 관리해 배선 오류를 줄인다.
- UART 키 입력과 joystick ADC 입력이 같은 Servo_AdjustPulse() 경로로 합류하도록 구성한다.
- 관절별 raw pulse 기반 안전 범위와 초기 자세를 calibration table로 분리해 관리한다.

### 1.2 설계 범위

설계 범위에는 startup/linker/Makefile 빌드 기반, TIM1/TIM2/TIM3/TIM4를 사용한 6채널 servo PWM, interrupt 기반 USART2 콘솔, ADC1 polling 기반 3-axis 조이스틱 입력, raw pulse 기반 관절 보정과 초기 자세 제어가 포함된다.

관절 물리 각도로의 일반화된 변환, B10K 가변저항 기반 outer-loop PID feedback, ADC1의 DMA 연동은 이번 산출물 범위에서 제외한다. 이 항목들은 초기 설계 단계에서 계획했으나, 실제 구현에서는 5일 개발 기간에 맞춰 명시적으로 축소했다. 최종적으로 raw pulse 기반 직접 제어와 ADC1 polling만으로 완료했다.

### 1.3 프로젝트 요약

여섯 개의 독립적인 servo channel과 다중 입력 경로가 동시에 존재하는 하나의 로봇팔 제어 시스템이다.

최종 실행 구조는 testudines() 진입점 아래에서 SysTick millisecond tick, 여섯 채널 servo PWM, USART2 interrupt 기반 콘솔, ADC1 polling 기반 조이스틱을 하나의 foreground loop로 묶는다. 핵심 키워드는 register-level PWM, USART2 interrupt/ring buffer, ADC1 single-conversion polling, raw pulse calibration이다.

### 1.4 설계 사양 요약 (Specification Summary)

| 항목 | 내용 |
|---|---|
| 대상 보드 | NUCLEO-F411RE (STM32F411RE, Cortex-M4), Sensor Shield v5.0 |
| 로봇팔 | G51 6-DoF 프레임, MG966R RC 서보 6개 |
| PWM 주기 | 50 Hz (20 ms), timer tick 1 µs (PSC 15, HSI 16 MHz 기준) |
| 사용 timer | TIM1_CH2, TIM2_CH2/CH3, TIM3_CH1/CH2, TIM4_CH1 |
| UART | USART2 (ST-LINK virtual COM), interrupt 기반 RX ring buffer |
| ADC | ADC1 12-bit, 6채널 single-conversion polling, 10 ms 주기 |
| 빌드 도구 | arm-none-eabi-gcc, Makefile, make build/make flash |

### 1.5 AS-IS / TO-BE

| 구분 | AS-IS (Day 1, 07-23) | TO-BE (Day 5, 07-27) |
|---|---|---|
| PWM | TIM4_CH1 단일 channel bring-up, USER LED 점멸 확인 수준 | TIM1/TIM2/TIM3/TIM4 여섯 channel 동시 구동, 관절별 calibration table 적용 |
| 입력 | 입력 경로 없음, 고정 초기 pulse만 출력 | USART2 키 입력 6종 + ADC1 joystick 6축이 같은 pulse 조정 경로로 합류 |
| 실행 구조 | 단순 polling 초기화 코드 | SysTick 10 ms tick, USART2 RX interrupt/ring buffer, ADC1 polling이 분리된 foreground loop |
| 검증 | Flash 기록과 LED 점멸만 확인 | 6관절 동시 torque, UART pulse echo, joystick 조작 영상까지 시연 |

이 변화의 핵심은 단일 채널 bring-up에서 시작해, 입력 경로를 두 갈래(UART, ADC)로 분리하면서도 관절 pulse 조정이라는 하나의 공통 API로 합류시켰다는 점이다. 이 구조 덕분에 이후 B10K feedback이나 PID를 추가할 때도 동일한 Servo_AdjustPulse() 경로를 재사용할 수 있다.

## 2. 프로젝트 관리 (Project Management)

### 2.1 일정 계획 (Schedule)

| 일자 | 작업 유형 | 주요 작업 |
|---|---|---|
| 07-23 | 설계 + 코딩 + 검증 | startup/linker/Makefile 구성, TIM4_CH1 단일 PWM 채널 bring-up, USER LED 확인 |
| 07-24 | 설계 + 코딩 + 검증 | 6관절 timer/channel 매핑 확정, calibration table 구조 도입, 6채널 동시 PWM·torque 확인 |
| 07-25 | 코딩 + 검증 | USART2 byte 송수신/echo 구현, q/a~y/h 키 매핑으로 raw pulse 조정, pin mux 수정 |
| 07-26 | 설계 + 코딩 + 검증 | ADC1 polling과 joystick 6축 매핑, SysTick/USART2 RX를 interrupt로 분리, 미사용 DMA/PID stub 제거 |
| 07-27 | 검증 + 문서 | UART 6축 조정 시연 기록, 완료 범위/후속 보정 항목 정리, servo hunting 현상을 작업 가설로 기록 |

### 2.2 개발 환경 (Development Environment)

| 분류 | 기술 |
|---|---|
| 형상관리 | Git |
| 빌드 | arm-none-eabi-gcc, GNU Make |
| 업로드/디버그 | ST-LINK (Flash 기록, virtual COM) |
| 문서 | Markdown, Word |

### 2.3 설계 환경 (Design Environment)

| 분류 | 내용 |
|---|---|
| 언어 | C (bare-metal, HAL 미사용), ARM assembly (startup) |
| MCU/보드 | STM32F411RE, NUCLEO-F411RE, Sensor Shield v5.0 |
| Peripheral 접근 | CMSIS-Device register 구조체·bit macro 직접 설정 |
| 로봇팔 | G51 6-DoF 프레임, MG966R RC 서보 6개 |

## 3. 시스템 구성 및 제어 아키텍처 (System & Control Architecture)

### 3.1 하드웨어 구성

**servo 신호 배선**

| 관절 | Shield signal | STM32 pin | AF | timer/channel |
|---|---|---|---|---|
| Base | D10.S | PB6 | AF2 | TIM4_CH1 |
| Shoulder | D9.S | PC7 | AF2 | TIM3_CH2 |
| Elbow | D8.S | PA9 | AF1 | TIM1_CH2 |
| Wrist Pitch | D6.S | PB10 | AF1 | TIM2_CH3 |
| Wrist Yaw | D5.S | PB4 | AF2 | TIM3_CH1 |
| Gripper | D3.S | PB3 | AF1 | TIM2_CH2 |

**조이스틱 ADC 배선**

| 축 | 관절 | MCU pin | ADC1 channel |
|---|---|---|---|
| A0/A1 | Base / Shoulder | PA0 / PA1 | IN0 / IN1 |
| A2/A3 | Elbow / Gripper(test) | PA4 / PB0 | IN4 / IN8 |
| A4/A5 | Wrist Pitch / Wrist Yaw | PC1 / PC0 | IN11 / IN10 |

Shoulder, Elbow, Wrist Pitch 축(A1, A2, A4)은 상하 방향으로 장착되어 좌우 축과 조향 부호가 반대이므로, firmware에서 이 세 축의 delta 부호를 반전한다. Gripper는 조이스틱 3의 버튼으로 열림/닫힘을 토글하며, 아날로그 축(A3)은 test 배선으로만 남기고 실제 product 배선에서는 사용하지 않는다.

### 3.2 제어 데이터 흐름

<img width="2352" height="1035" alt="image1" src="https://github.com/user-attachments/assets/18696054-ef33-47ec-928c-9d9a21404b18" />

UART 키 입력과 joystick ADC 입력은 서로 다른 driver(uart2.c, adc1.c+joystick.c)에서 시작하지만, 둘 다 관절 ID와 pulse 증감량(delta_us)으로 정규화된 뒤 Servo_AdjustPulse()라는 하나의 진입점으로 합류한다. 이 지점 이후로는 입력 경로를 구분하지 않고 동일한 clamp·PWM 갱신 로직을 공유한다.

## 4. 상세 설계 (Detailed Firmware Design)

### 4.1 Boot 및 Build 구조

<img width="2352" height="651" alt="image2" src="https://github.com/user-attachments/assets/4756721c-9dfc-4ae8-8ac7-f94e80dce853" />

main()을 C runtime이 호출하는 일반적인 구조가 아니라, startup/crt0.s가 vector table 이후 .data copy, .bss clear를 수행하고 testudines()를 direct call한다. linker/rom_0x08000000.lds가 Flash/RAM 영역과 section 배치를 정의하고, Makefile이 arm-none-eabi-gcc 빌드와 make flash를 통한 0x08000000 Flash 기록을 담당한다.

### 4.2 Timer PWM 설계

네 개의 timer(TIM1~TIM4)를 모두 HSI 16 MHz 기준 PSC=15로 분주해 1 µs tick으로 통일하고, ARR=19999로 20 ms(50 Hz) 주기를 만든다. 각 channel은 PWM mode 1(OCxM = 110)과 preload(OCxPE)를 설정하고, EGR.UG로 update event를 강제한 뒤 CCR에 원하는 pulse width(µs)를 그대로 대입한다.

TIM1은 advanced-control timer라서 다른 timer와 달리 BDTR.MOE(main output enable)를 별도로 설정해야 channel 출력이 나온다. 이 차이를 놓치면 Elbow channel만 무출력 상태가 되는데, 07-24 작업에서 이 문제를 확인하고 `TIM1->BDTR |= TIM_BDTR_MOE`를 추가해 해결했다.

initial_us가 0인 channel은 ServoPwm_DisableOutput()으로 CCER의 해당 CCxE bit를 꺼서 PWM 출력을 아예 비활성화한다. 이 output gate 덕분에 보정되지 않은 관절이 임의의 pulse로 서보를 구동하는 상황을 막는다.

관절별 safe_min_us, neutral_us, safe_max_us, initial_us, direction을 하나의 ServoCalibration table로 관리한다. initial_us가 0인 관절은 안전 범위가 아직 확정되지 않았다는 뜻이며, 이 경우 PWM 출력 자체를 비활성화한다. Wrist Yaw와 Gripper는 안전 범위까지 확정되어 pulse가 그 범위로 clamp되고, 나머지 관절은 initial_us만 확정된 상태로 마무리했다.

### 4.3 UART 제어 설계

USART2는 ST-LINK virtual COM에 물려 있으며, PA2(TX)/PA3(RX)를 AF7로 설정하고 BRR, CR1(UE/TE/RE/RXNEIE)을 초기화한 뒤 NVIC_EnableIRQ(USART2_IRQn)로 interrupt를 활성화한다. RX byte는 USART2_IRQHandler()가 32-byte ring buffer에 채우고, foreground loop는 Uart2_TryReceiveByte()로 non-blocking 조회만 수행한다. 이 구조는 07-26 작업에서 polling 방식에서 interrupt/ring buffer 방식으로 전환한 결과다.

| 키 | 관절 | 증감 |
|---|---|---|
| q / a | Base | +8 µs / -8 µs |
| w / s | Shoulder | +8 µs / -8 µs |
| e / d | Elbow | +8 µs / -8 µs |
| r / f | Wrist Pitch | +8 µs / -8 µs |
| t / g | Wrist Yaw | +8 µs / -8 µs |
| y / h | Gripper | +8 µs / -8 µs |

각 조정 뒤에는 Servo_EchoPulse()가 관절 약어(BS, SH, EL, WP, WY, GR)와 현재 pulse 값을 UART로 즉시 출력해, 재Flash 없이 raw pulse 기반 보정 상태를 실시간으로 확인할 수 있다.

### 4.4 ADC/Joystick 제어 설계

ADC1은 12-bit 단일 변환 polling 방식으로 구성했다. Adc1_ReadChannel()이 SQR3에 채널 번호를 쓰고 SWSTART로 변환을 시작한 뒤 EOC flag를 busy-wait로 확인하고 DR을 읽는다. joystick pot 채널(0, 1, 4, 8, 10, 11)은 SMPR1/SMPR2에서 더 긴 sample time을 사용해 안정적인 읽기를 확보했다.

Joystick_PollAndApply()는 SysTick 기준 10 ms마다 6축을 순회하며, ADC 중심값(2048, 12-bit 중간값) 대비 편차가 deadzone(±250)을 넘을 때만 ±2 µs의 고정 step을 관절에 적용한다. 07-26 작업에서 상하축(A1/A2/A4)의 장착 방향이 좌우축과 반대인 것을 확인하고, 세 축에 대해서만 delta 부호를 반전했다. gripper 버튼은 20 ms debounce 뒤 눌림을 감지해 열림/닫힘 pulse를 토글한다.

## 5. 검증 및 시연 (Verification & Demo)

### 5.1 검증 항목

| ID | 대상 | 절차 | PASS 기준 | 07-27 기준 상태 |
|---|---|---|---|---|
| TC-01 | firmware build | make clean && make build | .elf/.bin 생성, warning 없음 | 확인 완료 |
| TC-02 | board bring-up | make flash 후 USER LED 확인 | Flash 기록과 LED 점멸 확인 | 확인 완료 |
| TC-03 | PWM channel init | timer·GPIO AF 설정 확인 | 지정 6개 D pin의 timer channel 활성화 | 6채널 torque 확인 완료 |
| TC-04 | output gate | initial_us = 0으로 boot | 해당 channel PWM 비활성 | 구현 완료 |
| TC-05 | 6관절 초기 자세 | 외부 servo 전원 인가 후 동시 확인 | initial pulse에서 torque·초기 자세 관찰 | 확인 완료 |
| TC-06 | UART pulse 제어 | terminal에서 q/a~y/h 입력 | 재Flash 없이 target 변경, echo 출력 | 구현 및 시연 완료 |
| TC-07 | joystick ADC 제어 | 축 편차와 target 비교 | deadzone 초과 시 지정 joint target 변화 | 구현 및 시연 완료 |
| TC-08 | 기계적 안전 범위 | raw pulse를 작은 간격으로 조정 | 관절별 safe_min/max/direction 기록 | Wrist Yaw·Gripper 완료 |
| TC-09 | B10K feedback/PID | 관절 연동 B10K와 outer loop 실행 | target 대비 feedback error 수렴 | 미구현 (이번 범위 제외) |

표 1. 검증 항목 (Verification Test Cases)

### 5.2 시연 결과

| <img alt="UART_시연_x2" src="https://github.com/user-attachments/assets/56c92ac6-aeb6-40dc-9957-612330413db7" /> | <img alt="04-full-joint-operation-run_x2" src="https://github.com/user-attachments/assets/21451fbc-f939-4713-9644-71db28565c1f" /> |
|:---:|:---:|

**UART 시연**: ST-LINK virtual COM에서 Servo key console과 6개 관절 키 매핑 배너를 확인하고, q/a~y/h 입력에 따라 BS, SH, WP, WY, EL 등 관절 pulse 값이 실시간으로 echo되는 과정을 영상으로 기록했다(UART_시연.mp4, 김연우_20260727_Cortex-M4_UART_시연_캡처.png).

| <img width="400" height="712" alt="01-wrist-pitch-yaw-gripper-uart-check_x2" src="https://github.com/user-attachments/assets/e61233bd-d53a-488f-8f6c-8b7ca1dcb49c" /> | <img width="400" height="712" alt="02-wrist-pitch-yaw-gripper-servo-hunting-repro_x2" src="https://github.com/user-attachments/assets/f3920a25-1afe-404c-8148-22ab44799e5e" /> | <img width="400" height="712" alt="03-elbow-base-check-servo-hunting_x2" src="https://github.com/user-attachments/assets/fd52352c-a759-482d-bbd7-0c6af3836525" /> |
|:---:|:---:|:---:|

**Joystick 시연**: wrist pitch/yaw/gripper 축과 elbow/base 축을 조이스틱으로 조작하는 과정과 6관절을 동시에 구동하는 full joint operation.

| <img width="400" height="712" alt="05-servo-hunting-recurrence_x2" src="https://github.com/user-attachments/assets/0ba40216-86dc-4d30-ac4d-38c5e12408af" /> | <img width="400" height="712" alt="06-joystick-operation-check_x2" src="https://github.com/user-attachments/assets/aae3fefc-f085-40de-90ad-835fefde9422" /> | <img width="400" height="712" alt="07-joystick-operation-check-2_x2" src="https://github.com/user-attachments/assets/f12238a5-193c-4911-a970-4afa4235ad36" /> |
|:---:|:---:|:---:|

**Servo hunting 재현**: wrist pitch/yaw/gripper 및 elbow/base 관절에서 관찰된 hunting 현상.

### 5.3 검증 결과 요약 테이블

| 항목 | 목표치 (Spec) | 07-27 결과 | 달성 여부 |
|---|---|---|---|
| 6채널 동시 PWM | 여섯 관절 동시 torque·초기 자세 | 6채널 동시 확인 | 달성 |
| UART pulse 제어 | 키 입력 → pulse 조정 → echo | 6관절 전부 시연 완료 | 달성 |
| Joystick 제어 | ADC 편차 → pulse 조정 | 6축 전부 시연 완료 | 달성 |
| 관절 안전 범위 확정 | 6관절 safe_min/max, direction | Wrist Yaw·Gripper만 확정 | 부분 달성 |
| B10K PID feedback | outer loop error 수렴 | 미구현 | 미달성 (범위 제외) |

## 6. 결과 분석 및 트러블슈팅 (Analysis & trouble shooting)

### 6.1 일자별 주요 이슈 해결

5일간 작업하며 확인·해결한 주요 이슈는 아래와 같다.

| 일자 | 문제 | 처리 |
|---|---|---|
| 07-23 | 새 터미널에서 ARM GCC toolchain 경로를 인식하지 못함 | toolchain 경로 확인 후 arm-none-eabi-size·flash 기록까지 재확인 |
| 07-23 | 서보 제어에 필요한 50 Hz 주기·pulse 폭 기준 정리 | HSI 16 MHz를 PSC=15로 분주해 1 MHz timer tick으로 통일 |
| 07-24 | TIM1은 다른 timer와 달리 main output enable이 별도로 필요함 | BDTR.MOE 설정 후 channel 출력 활성화 |
| 07-24 | 조립된 중립 위치가 일반적인 1~2 ms 범위와 일치하지 않을 수 있음 | 관절별 raw pulse 기반 initial_us를 개별 사용 |
| 07-25 | Arduino header 표기와 STM32 alternate function을 그대로 동일시할 수 없음 | D pin -> GPIO -> timer channel 순서로 source와 pin map을 대조 |
| 07-25 | 관절별 기계적 중립값이 서로 다름 | 관절별 initial_us를 개별 저장하고 UART로 미세 조정 |
| 07-26 | 조이스틱 상하축 장착 방향이 좌우축과 반대 | A1/A2/A4 축에만 반대 부호 적용 |
| 07-26 | polling과 UART 수신을 한 흐름에 묶으면 제어 응답 판단이 어려움 | SysTick 10 ms 주기와 USART2 RX interrupt를 분리 |

### 6.2 Servo Hunting 현상 분석 (미해결)

일부 관절에서 손으로 살짝 건드린 뒤 원래 목표 위치로 복귀하며 반복적으로 흔들리는(hunting) 현상이 관찰됐다. 07-27 시점에는 이를 확정된 원인이 아니라 작업 가설로만 기록하고, 아래 순서로 원인을 분리하는 진단 계획을 다음 단계로 남겼다.

- 고정 pulse·무입력 조건에서 재현 여부 확인
- horn/linkage를 분리한 단일 servo 단독 시험
- 단일 servo 구동과 6축 동시 구동의 전원 조건 비교
- UART pulse echo와 ADC raw 값을 함께 기록해 입력 흔들림 여부 확인

원인이 입력 흔들림으로 확인된 경우에만 deadzone, low-pass filter, pulse step을 조정하기로 했으며, 원인이 확정되기 전에는 pulse 범위를 넓히지 않기로 결정했다. 이는 원인이 불명확한 상태에서 안전 범위를 임의로 넓히면 기계적 손상 위험이 커지기 때문이다.

### 6.3 개선 방안

- Servo hunting 현상을 6.2의 진단 순서대로 분리해 전원 문제, 기구 결합 문제, 입력 흔들림 문제 중 실제 원인을 확정한다.
- Base, Shoulder, Elbow, Wrist Pitch 네 관절의 safe_min_us/safe_max_us/direction을 실측해 calibration table의 미확정 항목을 제거한다.
- joystick deadzone, low-pass filtering, 관절별 pulse step을 실측 기반으로 재조정해 조작감을 개선한다.
- B10K 가변저항을 기계적으로 연동한 뒤, 현재 구조를 유지한 채 outer-loop PID feedback을 추가한다.

## 7. 결론 및 고찰

- 여섯 개의 독립적인 timer PWM channel, interrupt 기반 USART2 콘솔, polling 기반 ADC1 joystick 입력을 하나의 register-level bare-metal firmware로 통합하고, UART와 joystick 두 입력 경로를 Servo_AdjustPulse()라는 공통 API로 합류시켜 재Flash 없이 로봇팔 6관절을 실시간으로 제어했다.
- 이번 5일 범위에서는 PWM·UART·ADC/joystick 제어까지 구현을 완료했고, 관절 물리 각도 변환, B10K feedback 기반 PID, DMA 연동은 초기 계획에서 의도적으로 축소해 이번 산출물의 범위 밖으로 명시했다. 남은 과제인 관절별 안전 범위 확정과 servo hunting 원인 분리는 원인을 먼저 확정한 뒤 범위를 넓히는 순서로 진행할 계획이다.

## 참고 문헌

[0] STMicroelectronics, STM32F411xC/xE Reference Manual (RM0383)

[1] STMicroelectronics, NUCLEO-F411RE User Manual (UM1724)

[2] ARM, Cortex-M4 Technical Reference Manual, CMSIS-Core headers

[3] Terasic, Servo Motor Kit (MG966R 사양), https://www.crowdsupply.com/terasic/terasic-servo-motor-kit
