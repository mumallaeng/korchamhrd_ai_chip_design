English | [한국어](README.ko.md)

# G51 Robot Arm — Cortex-M4 Bare-Metal PWM/UART/ADC Control

Kim Yeonwoo

2026.07.23~2026.07.27

## 1. Overview (Overview)

### 1.1 Purpose and Objectives

The purpose of this project is to write register-level bare-metal firmware without HAL on the NUCLEO-F411RE (STM32F411RE, Cortex-M4) to simultaneously drive the six joints of the G51 6-DoF robot arm testudines using PWM, and adjust joint targets in real time via two paths: PC UART key input and joystick ADC input.

The ultimate goal is to integrate the PWM for all six servo channels into a single timer/GPIO initialization flow, operate both the USART2 console and ADC1 joystick polling on a single control loop, and enable immediate verification of results from each input path via UART echo.

The core objectives are as follows:

- Implement startup, timer PWM, USART2, and ADC1 using only CMSIS-Device register access.
- Manage pin/timer/channel assignments for all six joints in a single header to reduce wiring errors.
- Configure UART key input and joystick ADC input to converge on the same Servo_AdjustPulse() path.
- Separate safety ranges and initial postures based on raw pulse per joint into calibration tables.

### 1.2 Design Scope

The design scope includes startup/linker/Makefile build foundations, 6-channel servo PWM using TIM1/TIM2/TIM3/TIM4, interrupt-based USART2 console, ADC1 polling-based 3-axis joystick input, and raw pulse-based joint correction and initial posture control.

Generalized conversion to joint physical angles, outer-loop PID feedback based on B10K variable resistors, and ADC1 DMA integration are excluded from this deliverable's scope. These items were planned in the initial design phase but explicitly scaled down to fit a 5-day development period during actual implementation. The project was ultimately completed using raw pulse-based direct control and ADC1 polling only.

### 1.3 Project Summary

This is a single robot arm control system featuring six independent servo channels and multiple input paths operating simultaneously.

The final execution structure bundles the SysTick millisecond tick, six-channel servo PWM, USART2 interrupt-based console, and ADC1 polling-based joystick into a single foreground loop below the testudines() entry point. Key keywords are register-level PWM, USART2 interrupt/ring buffer, ADC1 single-conversion polling, and raw pulse calibration.

### 1.4 Design Specification Summary (Specification Summary)

| Item | Content |
|---|---|
| Target Board | NUCLEO-F411RE (STM32F411RE, Cortex-M4), Sensor Shield v5.0 |
| Robot Arm | G51 6-DoF frame, 6x MG966R RC servos |
| PWM Period | 50 Hz (20 ms), timer tick 1 µs (based on PSC 15, HSI 16 MHz) |
| Used Timers | TIM1_CH2, TIM2_CH2/CH3, TIM3_CH1/CH2, TIM4_CH1 |
| UART | USART2 (ST-LINK virtual COM), interrupt-based RX ring buffer |
| ADC | ADC1 12-bit, 6-channel single-conversion polling, 10 ms period |
| Build Tools | arm-none-eabi-gcc, Makefile, make build/make flash |

### 1.5 AS-IS / TO-BE

| Category | AS-IS (Day 1, 07-23) | TO-BE (Day 5, 07-27) |
|---|---|---|
| PWM | Single channel bring-up of TIM4_CH1, USER LED blinking verification level | Simultaneous driving of six channels using TIM1/TIM2/TIM3/TIM4, application of joint-specific calibration tables |
| Input | No input paths, only fixed initial pulse output | Convergence of 6 types of USART2 key inputs and 6-axis ADC1 joystick into the same pulse adjustment path |
| Execution Structure | Simple polling initialization code | Separated foreground loop with SysTick 10 ms tick, USART2 RX interrupt/ring buffer, and ADC1 polling |
| Verification | Flash recording and LED blinking only | Demonstration of simultaneous torque for 6 joints, UART pulse echo, and joystick operation video |

The core of this change is starting from a single channel bring-up while separating input paths into two branches (UART, ADC), yet converging them into a single common API for joint pulse adjustment. Thanks to this structure, the same Servo_AdjustPulse() path can be reused when adding B10K feedback or PID later.

## 2. Project Management (Project Management)

### 2.1 Schedule Plan (Schedule)

| Date | Work Type | Key Tasks |
|---|---|---|
| 07-23 | Design + Coding + Verification | Setup startup/linker/Makefile, single PWM channel bring-up of TIM4_CH1, USER LED verification |
| 07-24 | Design + Coding + Verification | Confirm 6-joint timer/channel mapping, introduce calibration table structure, confirm 6-channel simultaneous PWM·torque |
| 07-25 | Coding + Verification | Implement USART2 byte send/receive/echo, raw pulse adjustment via q/a~y/h key mapping, pin mux correction |
| 07-26 | Design + Coding + Verification | ADC1 polling and joystick 6-axis mapping, separate SysTick/USART2 RX into interrupts, remove unused DMA/PID stubs |
| 07-27 | Verification + Documentation | Record UART 6-axis adjustment demo, organize completed scope/follow-up correction items, document servo hunting phenomenon as a work hypothesis |

### 2.2 Development Environment (Development Environment)

| Category | Technology |
|---|---|
| Version Control | Git |
| Build | arm-none-eabi-gcc, GNU Make |
| Upload/Debug | ST-LINK (Flash recording, virtual COM) |
| Documentation | Markdown, Word |

### 2.3 Design Environment (Design Environment)

| Category | Content |
|---|---|
| Language | C (bare-metal, no HAL), ARM assembly (startup) |
| MCU/Board | STM32F411RE, NUCLEO-F411RE, Sensor Shield v5.0 |
| Peripheral Access | Direct setting of CMSIS-Device register structures·bit macros |
| Robot Arm | G51 6-DoF frame, 6x MG966R RC servos |

## 3. System & Control Architecture (System & Control Architecture)

### 3.1 Hardware Configuration

**Servo Signal Wiring**

| Joint | Shield signal | STM32 pin | AF | timer/channel |
|---|---|---|---|---|
| Base | D10.S | PB6 | AF2 | TIM4_CH1 |
| Shoulder | D9.S | PC7 | AF2 | TIM3_CH2 |
| Elbow | D8.S | PA9 | AF1 | TIM1_CH2 |
| Wrist Pitch | D6.S | PB10 | AF1 | TIM2_CH3 |
| Wrist Yaw | D5.S | PB4 | AF2 | TIM3_CH1 |
| Gripper | D3.S | PB3 | AF1 | TIM2_CH2 |

**Joystick ADC Wiring**

| Axis | Joint | MCU pin | ADC1 channel |
|---|---|---|---|
| A0/A1 | Base / Shoulder | PA0 / PA1 | IN0 / IN1 |
| A2/A3 | Elbow / Gripper(test) | PA4 / PB0 | IN4 / IN8 |
| A4/A5 | Wrist Pitch / Wrist Yaw | PC1 / PC0 | IN11 / IN10 |
The Shoulder, Elbow, Wrist Pitch axes (A1, A2, A4) are mounted vertically; therefore, their delta signs are inverted in the firmware because they oppose the left-right axes and steering sign. The Gripper toggles open/close via button 3 on joystick 3, while analog axis A3 remains reserved for test wiring only and is not used in the actual product wiring.

### 3.2 Control Data Flow

<img width="2352" height="1035" alt="image1" src="https://github.com/user-attachments/assets/18696054-ef33-47ec-928c-9d9a21404b18" />

UART key input and joystick ADC input originate from different drivers (uart2.c, adc1.c+joystick.c) but both normalize by joint ID and pulse increment/decrement amount (delta_us) before converging to a single entry point: Servo_AdjustPulse(). After this point, the input path is not distinguished, and they share the same clamp·PWM update logic.

## 4. Detailed Firmware Design

### 4.1 Boot and Build Structure

<img width="2352" height="651" alt="image2" src="https://github.com/user-attachments/assets/4756721c-9dfc-4ae8-8ac7-f94e80dce853" />

main() does not follow the typical structure where the C runtime calls it. Instead, startup/crt0.s performs .data copy and .bss clear after the vector table, then directly calls testudines(). The linker/rom_0x08000000.lds defines Flash/RAM regions and section placement, while the Makefile handles arm-none-eabi-gcc build and 0x08000000 Flash recording via make flash.

### 4.2 Timer PWM Design

All four timers (TIM1~TIM4) are prescaled to 1 µs ticks based on HSI 16 MHz with PSC=15, and ARR=19999 is set to create a 20 ms (50 Hz) period. Each channel is configured in PWM mode 1 (OCxM = 110) with preload (OCxPE); after forcing an update event via EGR.UG, the desired pulse width (µs) is directly loaded into CCR.

TIM1 is an advanced-control timer; unlike other timers, BDTR.MOE (main output enable) must be set separately for channel output to appear. Missing this distinction leaves the Elbow channel in a no-output state. This issue was identified during 07-24 work and resolved by adding `TIM1->BDTR |= TIM_BDTR_MOE`.

Channels with initial_us = 0 have their corresponding CCxE bit in CCER cleared via ServoPwm_DisableOutput(), completely disabling PWM output. This output gate prevents uncalibrated joints from driving servos with arbitrary pulses.

Joint-specific safe_min_us, neutral_us, safe_max_us, initial_us, and direction are managed in a single ServoCalibration table. Joints with initial_us = 0 indicate that the safety range is not yet finalized; in such cases, PWM output itself is disabled. Wrist Yaw and Gripper have their safety ranges finalized, so pulses are clamped within those ranges, while remaining joints are left with only initial_us confirmed.

### 4.3 UART Control Design

USART2 is bound to the ST-LINK virtual COM port; PA2 (TX)/PA3 (RX) are set to AF7, BRR and CR1 (UE/TE/RE/RXNEIE) are initialized, and NVIC_EnableIRQ(USART2_IRQn) activates interrupts. The RX byte is filled into a 32-byte ring buffer by USART2_IRQHandler(), while the foreground loop performs non-blocking checks via Uart2_TryReceiveByte(). This structure resulted from switching from polling to interrupt/ring buffer mode during 07-26 work.

| Key | Joint | Increment/Decrement |
|---|---|---|
| q / a | Base | +8 µs / -8 µs |
| w / s | Shoulder | +8 µs / -8 µs |
| e / d | Elbow | +8 µs / -8 µs |
| r / f | Wrist Pitch | +8 µs / -8 µs |
| t / g | Wrist Yaw | +8 µs / -8 µs |
| y / h | Gripper | +8 µs / -8 µs |

After each adjustment, Servo_EchoPulse() immediately outputs the joint abbreviation (BS, SH, EL, WP, WY, GR) and current pulse value via UART, allowing real-time verification of raw pulse-based calibration status without re-flashing.

### 4.4 ADC/Joystick Control Design

ADC1 is configured as a 12-bit single-conversion polling mode. Adc1_ReadChannel() writes the channel number to SQR3, starts conversion with SWSTART, then reads DR after confirming the EOC flag via busy-wait. Joystick pot channels (0, 1, 4, 8, 10, 11) use longer sample times in SMPR1/SMPR2 to ensure stable readings.

Joystick_PollAndApply() iterates through six axes every 10 ms based on SysTick. A fixed step of ±2 µs is applied to joints only when the deviation from the ADC center value (2048, the midpoint for 12-bit) exceeds the deadzone (±250). During 07-26 work, it was confirmed that the mounting direction of vertical axes (A1/A2/A4) opposes horizontal axes; therefore, delta signs were inverted only for these three axes. The gripper button detects a press after a 20 ms debounce and toggles open/close pulses.

## 5. Verification and Demo

### 5.1 Verification Items

| ID | Target | Procedure | PASS Criteria | Status as of 07-27 |
|---|---|---|---|---|
| TC-01 | firmware build | make clean && make build | .elf/.bin generation, no warnings | Verified |
| TC-02 | board bring-up | Check USER LED after make flash | Verify Flash recording and LED blinking | Verified |
| TC-03 | PWM channel init | Verify timer·GPIO AF settings | Activate timer channels on designated 6 D pins | 6-channel torque verified |
| TC-04 | output gate | Boot with initial_us = 0 | Disable PWM for corresponding channel | Implemented |
| TC-05 | 6-joint initial pose | Observe after external servo power-on and simultaneous check | Observe torque and initial pose from initial pulse | Verified |
| TC-06 | UART pulse control | Input q/a~y/h from terminal | Change target without re-flash, echo output | Implemented and demonstrated |
| TC-07 | joystick ADC control | Compare axis deviation and target | Designated joint target changes when deadzone exceeded | Implemented and demonstrated |
| TC-08 | Mechanical safety range | Adjust raw pulse in small intervals | Record joint-specific safe_min/max/direction | Wrist Yaw·Gripper completed |
| TC-09 | B10K feedback/PID | Execute joint linkage with B10K and outer loop | Feedback error converges to target | Not implemented (excluded from this scope) |

Table 1. Verification Test Cases

### 5.2 Demo Results

| <img alt="UART_시연_x2" src="https://github.com/user-attachments/assets/56c92ac6-aeb6-40dc-9957-612330413db7" /> | <img alt="04-full-joint-operation-run_x2" src="https://github.com/user-attachments/assets/21451fbc-f939-4713-9644-71db28565c1f" /> |
|:---:|:---:|
**UART Demonstration**: Captured the process of verifying the ST-LINK virtual COM port, the Servo key console, and the 6-joint key mapping banner, along with the real-time echo of joint pulse values (BS, SH, WP, WY, EL, etc.) in response to a~y/h inputs (UART_Demo.mp4, Kim_Yeongwoo_20260727_Cortex-M4_UART_Demo_Capture.png).

| <img width="400" height="712" alt="01-wrist-pitch-yaw-gripper-uart-check_x2" src="https://github.com/user-attachments/assets/e61233bd-d53a-488f-8f6c-8b7ca1dcb49c" /> | <img width="400" height="712" alt="02-wrist-pitch-yaw-gripper-servo-hunting-repro_x2" src="https://github.com/user-attachments/assets/f3920a25-1afe-404c-8148-22ab44799e5e" /> | <img width="400" height="712" alt="03-elbow-base-check-servo-hunting_x2" src="https://github.com/user-attachments/assets/fd52352c-a759-482d-bbd7-0c6af3836525" /> |
|:---:|:---:|:---:|

**Joystick Demonstration**: The process of operating the wrist pitch/yaw/gripper axes and elbow/base axes with a joystick, and full joint operation driving all six joints simultaneously.

| <img width="400" height="712" alt="05-servo-hunting-recurrence_x2" src="https://github.com/user-attachments/assets/0ba40216-86dc-4d30-ac4d-38c5e12408af" /> | <img width="400" height="712" alt="06-joystick-operation-check_x2" src="https://github.com/user-attachments/assets/aae3fefc-f085-40de-90ad-835fefde9422" /> | <img width="400" height="712" alt="07-joystick-operation-check-2_x2" src="https://github.com/user-attachments/assets/f12238a5-193c-4911-a970-4afa4235ad36" /> |
|:---:|:---:|:---:|

**Servo Hunting Reproduction**: The hunting phenomenon observed in the wrist pitch/yaw/gripper and elbow/base joints.

### 5.3 Verification Results Summary Table

| Item | Target (Spec) | 07-27 Result | Achievement Status |
|---|---|---|---|
| 6-channel simultaneous PWM | Simultaneous torque and initial posture for six joints | Confirmed 6-channel simultaneous operation | Achieved |
| UART pulse control | Key input → pulse adjustment → echo | Completed demonstration of all 6 joints | Achieved |
| Joystick control | ADC deviation → pulse adjustment | Completed demonstration of all 6 axes | Achieved |
| Joint safe range confirmation | 6-joint safe_min/max, direction | Confirmed only Wrist Yaw and Gripper | Partially achieved |
| B10K PID feedback | Outer loop error convergence | Not implemented | Not met (excluding range) |

## 6. Results Analysis and Troubleshooting (Analysis & troubleshooting)

### 6.1 Key Issues Resolved by Date

The major issues identified and resolved during the five days of work are as follows:

| Date | Issue | Resolution |
|---|---|---|
| 07-23 | ARM GCC toolchain path not recognized in new terminal | Verified toolchain path and reconfirmed arm-none-eabi-size and flash recording |
| 07-23 | Organized the 50 Hz period and pulse width criteria required for servo control | Unified to 1 MHz timer tick by dividing HSI 16 MHz with PSC=15 |
| 07-24 | TIM1, unlike other timers, requires a separate main output enable | Activated channel output after setting BDTR.MOE |
| 07-24 | Assembled neutral position may not match the typical 1~2 ms range | Used individual initial_us based on raw pulse per joint |
| 07-25 | Arduino header notation cannot be directly equated to STM32 alternate functions | Compared source and pin map in order: D pin → GPIO → timer channel |
| 07-25 | Mechanical neutral values differ per joint | Stored individual initial_us per joint and fine-tuned via UART |
| 07-26 | Joystick vertical axis mounting direction is opposite to horizontal axes | Applied opposite sign only to A1/A2/A4 axes |
| 07-26 | Polling and UART reception combined in one flow makes control response judgment difficult | Separated SysTick 10 ms period from USART2 RX interrupt |

### 6.2 Servo Hunting Phenomenon Analysis (Unresolved)

A hunting phenomenon was observed where some joints oscillate repeatedly, returning to the original target position after being lightly touched by hand. As of 07-27, this was recorded only as a working hypothesis rather than a confirmed cause, and a diagnostic plan to isolate the cause was left for the next step in the following order:

- Verify reproducibility under fixed pulse/no-input conditions
- Test individual servo with horn/linkage separated
- Compare power supply conditions between single servo operation and 6-axis simultaneous operation
- Record both UART pulse echo and ADC raw values to check for input jitter

Adjustments to deadzone, low-pass filter, and pulse step were planned only if the cause was confirmed as input jitter. Before the cause is confirmed, it was decided not to widen the pulse range. This is because arbitrarily widening the safe range while the cause remains unclear increases the risk of mechanical damage.

### 6.3 Improvement Plan

- Isolate the servo hunting phenomenon according to the diagnostic sequence in 6.2 to confirm the actual cause among power supply issues, mechanical linkage issues, and input jitter.
- Measure safe_min_us/safe_max_us/direction for Base, Shoulder, Elbow, and Wrist Pitch joints in situ to remove uncertain items from the calibration table.
- Re-adjust joystick deadzone, low-pass filtering, and per-joint pulse step based on actual measurements to improve operability.
- Mechanically link the B10K potentiometer and add outer-loop PID feedback while maintaining the current structure.

## 7. Conclusion and Reflections

- Integrated six independent timer PWM channels, interrupt-based USART2 console, and polling-based ADC1 joystick input into a single register-level bare-metal firmware. It merged the UART and joystick two input paths via a common API named Servo_AdjustPulse(), enabling real-time control of the robot arm's 6 joints without re-flashing.
- Within this 5-day scope, implementation of PWM, UART, and ADC/joystick control was completed. Joint physical angle conversion, B10K feedback-based PID, and DMA integration were intentionally excluded from the initial plan and explicitly stated as outside the scope of this deliverable. The remaining tasks—confirming per-joint safe ranges and isolating servo hunting causes—are planned to proceed in the order of confirming the cause first, then widening the range.

## References

[0] STMicroelectronics, STM32F411xC/xE Reference Manual (RM0383)

[1] STMicroelectronics, NUCLEO-F411RE User Manual (UM1724)

[2] ARM, Cortex-M4 Technical Reference Manual, CMSIS-Core headers

[3] Terasic, Servo Motor Kit (MG966R specifications), https://www.crowdsupply.com/terasic/terasic-servo-motor-kit
