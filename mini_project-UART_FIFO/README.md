English | [한국어](README.ko.md)

# UART LOOPBACK

Kim Yeonwoo
2026.04.22 ~ 2026.04.27

## 1. Overview (Overview)

### 1.1 Purpose and Objectives

- Based on the limitations revealed in the Timepiecer project, explain the necessity of a UART structure for exchanging data with external boards.
- Organize the flow from UART theory, loopback structure, FSM/ASM/RTL, simulation, implementation, to the final presentation, connecting it to subsequent lessons.

The purpose of this project is to expand the values previously verified only via 7-Segment in the prior Timepiecer project into a form that allows direct exchange with a PC. To achieve this, we configured the UART communication path between the Basys3 board and the PC, aiming to directly explain and verify the core elements of asynchronous serial communication: baud rate, frame, start/stop bits, bit order, and sampling timing.

### 1.2 Design Scope

- **In Scope**: Summary of prior project limitations, UART basic theory, bit/byte and serial concepts, shift register, UART frame, block diagram, RX/TX FSM/ASM/RTL, simulation, implementation results
- **Out of Scope**: parity bit, multi-byte buffering, actual FIFO implementation, high-speed protocol optimization

### 1.3 Project Summary

- A loopback system connecting Basys3 and a PC via UART to retransmit received 1 byte
- Key keywords: Timepiecer extension, UART 8N1, serial communication, shift register, RX/TX FSM, stop bit troubleshooting

### 1.4 Design Specification Summary (Specification Summary)

The main design and presentation parameters are as follows:

- System Clock: 100 MHz
- Baud rate: 9600 bps
- Sampling: 16x oversampling, start bit center re-check
- Frame: 8 data bits, no parity, 1 stop bit (8N1)
- Goal: Expand the limitations of the prior project into a communication structure and verify that received data matches retransmitted data

### 1.5 AS-IS / TO-BE (Optional)

- **AS-IS**: Timepiecer is a board-centric display structure, lacking a communication path for direct data exchange with external devices.
- **TO-BE**: Connect to the PC via USB-UART and establish a loopback structure that immediately retransmits received values, creating the starting point for external communication.
- **Key Improvements**: Presentation of communication necessity, learning of UART basic theory, organization of RX/TX FSM, comparison of stop bit criteria, derivation of directions for future lesson expansion

## 2. Project Management (Project Management)

### 2.1 Schedule Planning (Schedule)

| Stage | Duration | Key Tasks |
|---|---|---|
| Problem Identification/Theory Organization | 2026.04.22 ~ 2026.04.23 | Timepiecer limitations, Basys3 communication necessity, UART basic concepts organization |
| Structure Design | 2026.04.23 ~ 2026.04.24 | UART frame, block diagram, RX/TX FSM/ASM organization |
| RTL/Simulation | 2026.04.24 ~ 2026.04.25 | RTL structure verification, testbench, ASCII 0x30 loopback waveform verification |
| Troubleshooting/Implementation | 2026.04.26 | 23 tick stop bit comparison, board implementation verification |
| Final Presentation/Organization | 2026.04.27 | Final presentation, schedule table/journal/completion report organization |

### 2.2 Development Environment (Development Environment)

| Category | Technology |
|---|---|
| Learning Materials | Class materials, presentation slides, board practice results |
| Documents | Microsoft PowerPoint, Word, Excel, Markdown |

### 2.3 Design Environment (Design Environment)

| Category | Content |
|---|---|
| Language | Verilog HDL |
| FPGA | Digilent Basys 3 (Artix-7 XC7A35T) |
| EDA | Vivado 2020.2 |
| Simulator | Vivado XSim, Icarus Verilog |

## 3. Architecture Design (Architecture)

### 3.1 System Structure

<img width="1812" height="466" alt="image3" src="https://github.com/user-attachments/assets/8fcb8c6a-b307-449d-9a1e-79f4bb688b69" />

- **Block Diagram**: Advanced one step beyond the prior project's display-centric structure, defining a flow connecting to the PC with `clk/rst -> baud_tick_gen -> {uart_rx, uart_tx}`, `rx -> uart_rx`, `rx_data -> tx_data`, `rx_done -> tx_start`, and `uart_tx -> tx`.
- **Data Flow Definition**: The serial input `rx` entering from the PC or testbench is assembled by the receiver into 8-bit parallel data; upon completion of reception, the same value is retransmitted as serial `tx`.

### 3.2 Design Theory and Background (Theory & Background)

- Early in the presentation, communication was defined as "exchanging bits under the same agreement." This agreement includes speed, start and end conditions, and bit order.
- Subsequently, the structure where bits aggregate to form bytes, the difference between parallel and serial, and the role of the shift register were explained, concluding that UART operates as asynchronous serial communication functioning via baud rate agreements without separate clocks.
- This design is configured based on 9600 8N1, LSB-first, and 16x oversampling; RX reconfirms the start bit near the center before sampling data.

Related theory was organized based on the final presentation slide flow of "`Timepiecer Limitations -> UART Basic Theory -> UART Structure`" and the UART frame explanation used during class.

- RX FSM
<img width="1283" height="641" alt="image4" src="https://github.com/user-attachments/assets/028f4381-7feb-4f94-88e8-cc863f6238ba" />

- TX FSM
<img width="1609" height="818" alt="image5" src="https://github.com/user-attachments/assets/a962c407-da4f-466c-b22a-98c0e5c1fd74" />

- RX ASM
<img width="1124" height="781" alt="image6" src="https://github.com/user-attachments/assets/57af01bc-a188-4fac-b952-7b078ece25af" />

- TX ASM
<img width="955" height="790" alt="image7" src="https://github.com/user-attachments/assets/06ba3ac5-dfe0-4de9-b653-ee571a461619" />

## 4. Detailed Design (Detailed Design)

### 4.1 RTL

<img width="1225" height="577" alt="image8" src="https://github.com/user-attachments/assets/f4e17ad6-aa46-4213-9eda-a78b50eb1545" />

- **Module Composition**: `uart_loopback.v`(top), `uart.v`(internally containing `baud_tick_gen`, `uart_rx`, `uart_tx`), `tb_uart_loopback.v`(basic loopback verification)
- **Main Structure Description**: During the presentation, RX FSM, TX FSM, RX ASM, TX ASM, and RTL were explained in sequence following the block diagram to maintain a flow moving from high-level structure to lower-level operations.

### 4.2 Datapath / Control

- **Operation Structure Definition**: The RX shifts serial input in to assemble parallel data, while the TX shifts parallel data out to output serial data again; this process constitutes the core datapath of the loopback.
- **State Control Logic**: A 1-byte echo was configured without separate buffers by connecting `rx_done -> tx_start` and `rx_data -> tx_data`.

### 4.3 Timing Design
- The core of timing design lies in baud tick generation and the sampling point. The 100MHz system clock was divided into 16x oversampling ticks for 9600bps, and both RX/TX were configured to use this tick as a common reference.
- Key timing points emphasized in the presentation were re-verifying the center of the start bit, data sampling at 16-tick intervals, and determining when the done point occurs within the stop bit period.

### 4.4 Design Strategy

- Design strategy: Instead of adding complex features, the loopback structure was kept simple to align with course content while clearly demonstrating the principles of UART.
- Therefore, this design focused on an educational structure that clarifies serial communication principles and state transition structures, rather than low power or high-speed performance.
- From a stability perspective, procedures for re-verifying the start bit, checking the stop bit, synchronizing RX input, and troubleshooting via waveform comparison were utilized.

## 5. Simulation & Verification

### 5.1 Testbench

| Signal Name | Signal Description |
|---|---|
| clk | 100MHz main clock. Serves as the reference for overall UART timing. |
| rst | Reset signal that returns state registers and counters to their initial state. |
| rx | UART serial input received from PC or testbench. |
| tx | UART serial output that re-transmits received values. |
| b_tick | Reference signal generated by the baud tick generator (16x oversampling). |
| rx_data[7:0] | 8-bit parallel data assembled by RX. |
| rx_done | Control signal occurring at the reception completion point. Connected to tx_start in loopback mode. |
| tx_start | TX start signal. In this structure, it is directly connected to rx_done. |

Table 1. Major signal definitions confirmed from the final presentation and simulation waveforms.

| State Name | State Description |
|---|---|
| RX_IDLE | Waits until a start bit arrives while in line idle state. |
| RX_START | Detects the start bit and re-verifies it near the center. |
| RX_DATA | Samples 1 bit every 16 ticks to assemble 8 bits. |
| RX_STOP | Verifies the stop bit period and finalizes reception completion. |
| TX_IDLE | Maintains tx=1 in the transmit idle state. |
| TX_START | Outputs start bit 0 and begins transmission. |
| TX_DATA | Transmits data from data_reg[0] in LSB-first order. |
| TX_STOP | Outputs stop bit 1 and prepares for the next transmission. |

Table 2. Summary of state meanings used in the RX/TX FSM.

### 5.2 Simulation Scenarios

- Simulation Scenario 1: Verify that when `8'h30` (ASCII "0") is input, the UART frame is received and the same value is re-output via tx.
- Simulation Scenario 2: Align with troubleshooting on slides 19~21 to compare the done point in the stop bit period based on 15 ticks versus 23 ticks.

## 6. Analysis & Troubleshooting

<img width="1380" height="427" alt="image9" src="https://github.com/user-attachments/assets/648d33e3-14d5-4ce7-927a-fbb1e315ee16" />

Waveform analysis focused on observing the process where data bits move in LSB-first order after the start bit, the linkage between `rx_done` and `tx_start`, and the stop bit processing point.

The key waveforms involve comparing `rx_23_b_tick_cnt`, `rx_15_b_tick_cnt`, and `rx15_data`, thereby explaining the perspective of ensuring the stop bit.

<img width="1379" height="556" alt="image10" src="https://github.com/user-attachments/assets/b3f4b545-3323-4d4b-b852-ca1221f7579e" />

In the basic loopback waveform, it was confirmed that input and re-transmitted values match. In the additional comparison waveform, it was concluded that delaying the done point further after the stop bit period is more advantageous for boundary explanation.

## 7. Conclusion

Through this UART loopback presentation, limitations of previous projects were expanded into communication structures, allowing a unified overview from bits/bytes, serial, protocol, FSM, RTL, waveforms, to implementation.

By connecting Basys3 and PC via micro-USB to explain the UART loopback structure, an echo-like implementation result was presented where values input on the PC are returned.

This result is significant as it represents a step beyond the previous Timepiecer project, which ended with internal board display, extending to external communication.

Additionally, the presentation was structured to connect UART theory explanation, FSM/RTL explanation, simulation waveforms, and implementation results into a single flow for organizing learning content.

From a trade-off perspective, extended features such as FIFO or error flags were excluded, but this allowed for an intuitive demonstration of basic UART concepts and state transition structures.

The primary issue identified was "How far should the STOP bit be verified to more stably explain reception completion?" Accordingly, comparisons were made between 15-tick and 23-tick references, concluding that observing done after sufficiently passing the stop bit is more suitable from both presentation and explanation perspectives.

Improvement plan: In future iterations, FIFO will be added to create a data loss prevention structure, and sensor values will be output via UART to directly verify actual measurement data.
