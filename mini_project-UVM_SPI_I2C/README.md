English | [한국어](README.ko.md)

# SPI/I2C Serial Communication IP UVM Verification

Kim Yeonwoo

2026.06.11 ~ 2026.06.18

## 1. Overview (Overview)

### 1.1 Purpose and Objectives

This project aims to directly implement SPI and I2C serial communication RTL and automatically verify it using a UVM 1.2 testbench. In the UVM structure, the roles of driver, monitor, scoreboard, coverage, and collector are divided to trace verification evidence.

- **SPI**: 1 Controller : 1 Target, MODE0, 1-byte MSB-first full-duplex operation verification
- **I2C**: 1 Controller : 1 Target, 7-bit address 0x12, 1-byte write, ACK and target receive confirmation
- **UVM**: smoke, basic, boundary, random, back-to-back, regression sequence configuration
- **Evidence**: scoreboard pass/fail, functional coverage, collector report, Verdi waveform acquisition

### 1.2 Design Scope

| Category | In-Scope | Out-of-Scope |
|---|---|---|
| SPI | 1:1 topology, MODE0, 1-byte, MSB-first, controller/target bidirectional data path | multi-target, CPOL/CPHA full modes, burst transfer |
| I2C | 7-bit address 0x12, write-only, ACK, target receive | read transaction, arbitration, clock stretching, address mismatch recovery |
| Verification | UVM transaction, sequence, driver, monitor, scoreboard, coverage, collector | protocol-specific independent agent extension, formal verification |
| Board demo | board-visible results and Logic Analyzer evidence are separated as separate materials | UVM pass/fail evidence and board demo evidence are not treated as the same result |

**Table 1. Project Design and Verification Scope**

### 1.3 Project Summary

The SPI/I2C communication IP was configured as educational RTL, and operation was confirmed in UVM through expected/actual comparison and coverage hits. The document is structured in the order of RTL structure, FSM/ASM, waveforms, UVM architecture, VCS/Verdi/coverage evidence.

### 1.4 Design Specification Summary (Specification Summary)

| Item | Content |
|---|---|
| RTL Language | SystemVerilog |
| Verification Framework | UVM 1.2 |
| Simulator / Debug | Synopsys VCS W-2024.09-SP2, Verdi X-2025.06-1 |
| FPGA Tool / Board | Vivado 2020.2, Digilent Basys3 Artix-7 |
| SPI PASS Criteria | ctrl_rx_data == target_tx_data, target_rx_data == ctrl_tx_data |
| I2C PASS Criteria | ack_seen == 1, target_rx_seen == 1, target_rx_data == ctrl_tx_data |

**Table 2. Design Specification Summary**

### 1.5 AS-IS / TO-BE

| Category | AS-IS | TO-BE |
|---|---|---|
| Learning Perspective | Understood SPI/I2C as targets using pre-made communication IPs or example code. | Learned how SCLK, CS, controller/target data lines, SCL/SDA, and ACK connect to RTL state transitions. |
| Design Perspective | Was limited to guessing operation based on waveforms or demo results first. | Directly implemented Controller/Target, FSM/ASM, shift register, open-drain ACK structures to confirm operation flow. |
| Verification Perspective | Viewed testbench as a procedure of putting values in and checking waveforms only. | Divided UVM sequence, driver, monitor, scoreboard, coverage roles and established expected/actual comparison criteria. |
| Evidence Perspective | Explained results centered on captured images. | Connected VCS log, scoreboard pass/fail, coverage, and FSDB sections to use as report and presentation evidence. |

**Table 3. AS-IS / TO-BE Comparison**

The improvement effect is that SPI/I2C and UVM, which felt distant before the class, can now be directly explained through RTL implementation, transaction comparison, and coverage evidence.

## 2. Project Management (Project Management)

### 2.1 Schedule Planning (Schedule)

| Phase | Duration | Key Tasks |
|---|---|---|
| Requirements Confirmation | 2026.06.11 | Confirm implementation scope, deliverables, and criteria for separating board demo from UVM evidence |
| Structure Design | 2026.06.11 - 2026.06.13 | SPI/I2C block diagram, FSM/ASM, verification scenarios, scoreboard criteria establishment |
| RTL Implementation | 2026.06.11 - 2026.06.13 | Implement SPI/I2C controller, target, wrapper, and board top |
| UVM Verification | 2026.06.12 - 2026.06.16 | Write sequence, driver, monitor, scoreboard, coverage, collector and execute VCS |
| Presentation and Submission Preparation | 2026.06.16 - 2026.06.18 | PPT, report, waveform/coverage explanation, submission file check |

**Table 4. Project Schedule Summary**

### 2.2 Development Environment (Development Environment)

| Category | Technology |
|---|---|
| Remote Execution | Linux SSH, VCS/UVM license, Verdi GUI |
| Automation | Makefile, filelist.f, simv-remote, cov-remote, wave-remote |
| Deliverables | Powerpoint, Excel, Word, Markdown |

**Table 6. Development Environment**

### 2.3 Design Environment (Design Environment)

| Category | Content |
|---|---|
| HDL | SystemVerilog, Verilog |
| Verification | UVM 1.2, Synopsys VCS W-2024.09-SP2 |
| Debug | Synopsys Verdi X-2025.06-1, FSDB/VCD |
| FPGA | Digilent Basys3 Artix-7 |
| FPGA Tool | Vivado 2020.2 |

**Table 7. Design Environment**

## 3. Architecture Design (Architecture)

### 3.1 System Structure

The DUT implements SPI and I2C separately, and the UVM testbench selects drive/observe/compare operations based on the protocol field. The board demo structure is maintained as separate evidence, and the PASS/FAIL criteria in this report are based on the UVM testbench results.

### 3.2 Design Theory and Background (Theory & Background)

<img width="300" alt="image4" src="https://github.com/user-attachments/assets/e02ebcb3-2b91-4d60-b0d3-682af2ccd54f" />
<img width="500" alt="image5" src="https://github.com/user-attachments/assets/ba428e6d-8f8e-4d83-925b-097c49ce36ab" />

SPI involves the Controller generating SCLK and CS, exchanging bytes with the Target simultaneously via ctrl_sdo/tgt_sdi and tgt_sdo/ctrl_sdi paths. I2C constructs transactions on the shared SCL/SDA bus under START, address, ACK, data, and STOP conditions. UVM is not a tool for evaluating protocol selection costs but a verification environment to confirm whether defined transactions match expected values in the DUT.

In this report, we do not use Master/Slave terminology commonly found in general literature as primary terms; instead, we uniformly use Controller/Target. MOSI/MISO are listed only when explaining standard signal names, and RTL/UVM descriptions are linked to project-specific signal names.
| Common Term | Technical Term | Signal / Target | Meaning |
|---|---|---|---|
| Master | Controller | SPI_controller, I2C_controller | Initiates a transaction and generates the clock, select, address/write sequence. |
| Slave | Target | SPI_target, I2C_target | Receives data and responds when selected or when the address matches. |
| MOSI | ctrl_sdo / tgt_sdi | SPI Controller to Target data | Serial data path from Controller to Target. |
| MISO | tgt_sdo / ctrl_sdi | SPI Target to Controller data | Serial data path for Target response arriving at the Controller. |
| SS/CS | cs_n | SPI target select | Indicates an active-low frame interval and ensures only the selected Target participates in the transaction. |
| SCL/SDA | scl / sda | I2C shared bus | SCL serves as the timing reference; SDA transmits address/data/ACK signals using open-drain logic. |

Table 8. SPI/I2C Terminology Comparison

| protocol | Characteristics | Role in This Project |
|---|---|---|
| UART | Full-duplex communication based on baud timing without a shared clock | Reference protocol for comparison |
| SPI | Full-duplex communication using SCLK/CS and bidirectional data lines between controller/target | MODE0 1-byte full-duplex verification target |
| I2C | Communication based on SCL/SDA shared bus, address, and ACK | Verification target for address 0x12 write path |

Table 9. UART/SPI/I2C Comparison

## 4. Detailed Design (Detailed Design)

### 4.1 RTL Design

| Category | Major Modules | Function |
|---|---|---|
| SPI | SPI_controller, SPI_target, SPI wrapper | Generates SCLK/CS; shifts ctrl_sdo/tgt_sdi and tgt_sdo/ctrl_sdi; outputs rx_valid/done |
| I2C | I2C_controller, I2C_target, I2C wrapper | Handles START/STOP, address/write, ACK, and target receive processing |
| Common | board top, result path | Connects board display results with internal communication results |
| UVM top | tb_SPI_I2C_UVM | Connects dedicated UVM SPI 1:1 + I2C 1:1 DUT |

Table 10. RTL Configuration

### 4.2 FSM and ASM

The SPI defines state transitions using FSMs for both Controller and Target, linking datapath operations per state via ASM. The I2C verifies the sequence of START, address, ACK, DATA, and STOP based on Controller/Target FSMs.

#### 4.2.1 SPI

SPI follows a 1 Controller : 1 Target structure based on MODE0, where the Controller and Target synchronize CS, SCLK, and MOSI/MISO shift operations within the same frame.

**SPI Controller FSM**
<img width="2812" height="956" alt="SPI Controller FSM" src="https://github.com/user-attachments/assets/a149dd8c-c229-4e93-98cd-96c084848f3d" />

**SPI Controller ASM**
<img width="3360" height="2508" alt="SPI Controller ASM" src="https://github.com/user-attachments/assets/18b9f72e-b5de-4086-b85c-f88d41178eec" />

**SPI Target FSM**
<img width="2876" height="988" alt="SPI Target FSM" src="https://github.com/user-attachments/assets/aa5dd0b3-f3ab-4ad7-81ba-aa868f06bf13" />

**SPI Target ASM**
<img width="4652" height="3324" alt="SPI Target ASM" src="https://github.com/user-attachments/assets/ea694c41-151d-4fd0-aa43-1874cdd9659c" />

| Step | Controller FSM/ASM | Target FSM/ASM | Check point |
|---|---|---|---|
| IDLE | Wait for start, SCLK=CPOL, cs_n=High | Deselected, sdo idle | No frame |
| START | Mode/data latch, selected CS assert | Detect frame via cs_start | Target selected |
| SETUP | CPHA0 preload, response sample preparation | CPOL/CPHA latch, target_tx_data preparation | Setup timing |
| TRANSFER | SCLK toggle, MISO sample, MOSI shift | MOSI sample, MISO shift | 8-bit MSB-first |
| DONE | rx_data/done/rx_valid, CS release | target_rx_data/rx_valid, cs_stop release | Byte match |

Table 11. SPI Controller/Target FSM-ASM Connection

#### 4.2.2 I2C

I2C establishes START/STOP conditions based on open-drain SDA and SCL, verifying ACK and target receive during a target address 0x12 write transaction.

| Segment | Controller FSM | Target FSM | Check point |
|---|---|---|---|
| IDLE/START | After start input, SDA High->Low | Detect SDA falling while SCL High | START condition |
| ADDR | Transmit 0x12 + write bit MSB-first | Shift address bits and compare target_addr | Target selected |
| ACK | Sample ACK after SDA release | Drive SDA Low on matched address/data | ack_seen=1 |
| DATA | Transmit ctrl_tx_data 8-bit | Shift-in target_rx_data | target_rx_seen=1 |
| STOP/DONE | Generate STOP condition, done pulse | Detect STOP and return to IDLE | target_rx_data == ctrl_tx_data |

Table 12. I2C Controller/Target FSM Observation Points

**IIC Controller FSM**
<img width="2704" height="1544" alt="IIC Controller FSM" src="https://github.com/user-attachments/assets/b47ec65f-81dc-4e07-a81d-581e0ce039f7" />

**IIC Target FSM**
<img width="2928" height="1544" alt="IIC Target FSM" src="https://github.com/user-attachments/assets/65bc2192-2559-4489-ba60-222cecd772f6" />

### 4.3 Timing Design

For SPI (MODE0), verify the SCLK idle low state, rising edge sample, falling edge shift, and rx_valid pulse timing after an 8-bit transfer.

For I2C, determine START/STOP based on SDA edges while SCL is High, and verify the ACK phase following the byte and the target_rx_seen pulse timing.

The UVM monitor converts DUT results into transaction items, and the scoreboard compares expected fields with observed fields.
Timing verification is based on when the signal becomes valid and when the completion pulse occurs, rather than the waveform shape itself. For SPI, verify that sampling occurs at the rising edge and shifting at the falling edge while SCLK is idle low, repeating for 8 bits. For I2C, verify that START/STOP conditions are formed within the SCL High period and that ACK/receive pulses follow.

| Category | Timing Criterion | Observation Point in Waveform |
|---|---|---|
| SPI edge | MODE0: SCLK is idle low; sample occurs at rising edge, shift at falling edge, repeating. | SCLK clock row and MOSI/MISO 8-bit data line transitions |
| SPI completion | After 8-bit transmission ends, controller/target received value is confirmed, and done/rx_valid pulses high. | done / rx_valid 1-cycle pulse after last bit |
| I2C condition | START/STOP are determined when SDA falls or rises while SCL is High. | SCLK clock row and SDA address/data/ACK bit pattern |
| I2C ACK/RX | ACK phase follows ADDR/DATA byte; upon target receive completion, ack_seen and target_rx_seen pulse high. | SDA ACK=0 interval and ack_seen, target_rx_seen pulses |

Table 13. Timing Observation Criteria

<img width="940" height="272" alt="image12" src="https://github.com/user-attachments/assets/d0f44c60-d6ec-4173-9cca-42ba8224a541" />

<img width="1500" height="212" alt="image13" src="https://github.com/user-attachments/assets/5eb20101-59d8-450c-8b6c-196a45a9668a" />

### 4.4 Design Strategy

- Separated the board demo structure from the UVM automated verification structure to prevent mixing evidence criteria.
- Treated SPI and I2C as a single serial transaction format, branching driver/monitor operations via protocol fields.
- Coverage was structured around protocol, test_kind, data class, I2C addr/ACK/RX, and latency.

## 5. Simulation & Verification

### 5.1 Testbench

Verification first confirmed basic RTL operation in protocol-specific directed TBs, then expanded the same DUT combination to UVM TB using sequence-based regression verification. Individual TBs serve as a basic check step for quickly identifying waveforms and mismatches, while UVM TBs constitute the final automated verification criteria including scoreboard, coverage, and collector.

| Verification Stage | Target/Command | Check Content | Role |
|---|---|---|---|
| SPI individual TB | tb_SPI.sv / make spi-sim | Verify RX mismatch after A5<->3C, 5A<->C3 transmission | SPI full-duplex unit check |
| I2C individual TB | tb_I2C.sv / make i2c-sim | Verify ACK/RX mismatch after addr 0x12 write A5/5A | I2C write/bus unit check |
| UVM TB | tb_SPI_I2C_UVM.sv / make simv-remote | Check sequence pass/fail, coverage, report summary | Regression verification evidence criteria |

Table 14. Testbench Verification Stages

<img width="3124" height="2084" alt="image14" src="https://github.com/user-attachments/assets/95ef9ea1-6d9c-4dc5-aa66-eee541407454" />

| UVM Component | Role | Project Connection |
|---|---|---|
| serial_seq_item | Store protocol, test_kind, expected/observed fields | SPI/I2C common transaction |
| serial_driver | Drive DUT interface | SPI start/data, I2C address/write start |
| serial_monitor | Convert DUT results to observed items | SPI done, I2C done/ack/rx_seen |
| serial_scoreboard | Compare expected/actual | SPI byte match, I2C ACK/RX match |
| serial_coverage | Record coverpoint/cross hits | protocol, test_kind, data class, addr/ACK/RX, latency |
| serial_protocol_collector | Generate execution summary for reports | Per-protocol count, test_kind distribution, average latency |

Table 15. UVM Components

Scoreboard, coverage, and collector do not directly judge each other. The monitor observes transactions, and each component independently generates pass/fail, coverage hits, and report summaries.

### 5.2 Simulation Scenarios

Section 5.2 organizes scenarios by separating individual directed TBs from UVM sequences. Individual TBs serve as a step for quickly verifying basic RTL transactions, while UVM sequences expand the same DUT operation with automated judgment and coverage criteria.

| Category | Execution Target | Input Scenario | Verification Criteria |
|---|---|---|---|
| SPI individual TB | tb_SPI.sv / make spi-sim | A5<->3C, 5A<->C3 | No RX mismatch, verify done/rx_valid |
| I2C individual TB | tb_I2C.sv / make i2c-sim | addr 0x12 write A5, 5A | ACK/RX match, verify target_rx_valid |
| UVM smoke/basic | serial_smoke_test, serial_basic_test | SPI A5/5A, I2C A5/5A | driver-monitor-scoreboard PASS |
| UVM regression | serial_regression_test | Includes boundary/random/B2B | SPI 78 cases + I2C 78 cases, pass 156/fail 0 |

Table 16. Individual TB and UVM Simulation Scenarios

| Test | SPI Stimulus | I2C Stimulus | PASS Criteria |
|---|---|---|---|
| serial_smoke_test | A5 <-> 3C | addr 12, write A5 | pass 2/fail 0 |
| serial_basic_test | 5A <-> C3 | addr 12, write 5A | byte/data match |
| serial_boundary_test | 00/FF, FF/00, AA/55, 55/AA | 00, FF, AA, 55 | boundary match |
| serial_random_test | random 64 cases | random 64 cases | all match |
| serial_back_to_back_test | continuous 8 cases | continuous 8 cases | no dropped item |
| serial_regression_test | total 78 cases | total 78 cases | pass 156/fail 0 |

Table 17. UVM Sequence Detailed Scenarios

Individual TB waveforms were used to verify SPI/I2C unit operations during RTL bring-up, while UVM waveforms served as auxiliary evidence to confirm whether smoke transactions connected to DUT signals.

### 5.3 Waveform Analysis

Waveform analysis is structured by first verifying individual TB waveforms and then confirming UVM smoke tests with Verdi using SPI/I2C representative transactions at the end. However, the final pass/fail judgment for UVM is based on logs and scoreboard results in Section 5.4, not waveforms.
Individual TB waveforms serve as evidence that the basic RTL functionality for each protocol has been verified first. For SPI, we confirmed the shift direction and completion signal; for I2C, we confirmed data reception completion after address ACK.

<img width="1498" height="752" alt="image15" src="https://github.com/user-attachments/assets/df068cc4-390e-4946-a8df-1ea1b881cc3e" />

<img width="1688" height="771" alt="image16" src="https://github.com/user-attachments/assets/38653672-0c69-45f0-ac20-f5a4ba966057" />

| Category | Representative Interval | Waveform Check | Result |
|---|---|---|---|
| SPI Directed TB | MSB-first transfer | Verify that ctrl_sdo/tgt_sdo shift on SCLK edges while cs_n is active and that the received byte matches the expected value | PASS |
| I2C Directed TB | ACK and DATA done | Verify that ACK is observed after the address 0x12 write and that target_rx_data receives A5/5A | PASS |
| UVM Verdi | serial_smoke_test | Verify that SPI A5<->3C and I2C address 0x12 write A5 are transferred from the UVM sequence to DUT signals | Linked to log |

Table 18. Waveform verification items

The following Verdi waveform displays the FSDB generated after running an individual TB; rather, it is linked to the UVM smoke test execution. The waveform is for representative transaction confirmation, and UVM verification results are judged via log analysis in the next section.

<img width="1656" height="729" alt="image17" src="https://github.com/user-attachments/assets/b238d1b1-e89e-4ed5-b02c-6244754df868" />

controller tx_data 1010_0101(0xA5) enters target rx_data, and target tx_data 11_1100(0x3C) returns to controller rx_data, confirming normal full-duplex exchange.

<img width="1711" height="599" alt="image18" src="https://github.com/user-attachments/assets/ce2a93e1-8c7b-432f-b0ac-504d37d246aa" />

After the controller transmits addr 1_0010(0x12) write and data 1010_0101(0xA5), ACK is observed, and target_rx_data is updated to 0xA5, confirming target receive.

| Item | Value |
|---|---|
| Execution Command | make wave-remote TEST=serial_smoke_test SEED=260618 CM_NAME=serial_smoke_full |
| SPI Interval | 90 ns - 805 ns, controller A5, target 3C, full-duplex byte exchange |
| I2C Interval | 800 ns - 3995 ns, address 12, write A5, ACK, target receive |
| Result Context | 3985 ns - 4505 ns, scoreboard/coverage/collector report |

Table 19. UVM Verdi waveform evidence location

### 5.4 UVM log analysis

UVM verification focused primarily on confirming the sequence of sequence execution, driver operation, monitor observation, scoreboard judgment, and collector/coverage report in the logs rather than waveform inspection. The following log serves as evidence showing the UVM structure, transaction flow during regression execution, and final pass/fail summary along with coverage overview.

<img width="1008" height="471" alt="image19" src="https://github.com/user-attachments/assets/e4d6a368-e734-40c1-b15d-ee1fc1a7329e" />

It is evident that topology generated uvm_test_top, env, and agt with drv/mon/sqr underneath, and placed collector, coverage, and scoreboard as separate components within the env. This UVM structure, where the monitor sends observed transactions to scoreboard, coverage, and collector respectively, represents the actual built evidence.

<img width="1716" height="109" alt="image20" src="https://github.com/user-attachments/assets/3d7a8e3f-842e-40a8-bc3b-350491b00600" />

In the RANDOM test log, the driver drives SPI/I2C transactions at each test stage, the monitor observes ctrl_rx_data, target_rx_data, ack_seen, target_rx_seen, and latency, and the scoreboard outputs PASS. While waveforms show signal changes, this log directly shows how expected values are compared against actual values based on specific criteria.

<img width="1397" height="705" alt="image21" src="https://github.com/user-attachments/assets/d9b5ed76-7428-467f-9d53-919d4e056d0b" />

The collector outputted SPI 78 cases, I2C 78 cases, test kind distribution SMOKE 2, BASIC 2, BOUNDARY 8, RANDOM 128, BACK_TO_BACK 16, and average latency SPI 68 cycles, I2C 315 cycles. Since the scoreboard final result is pass 156, fail 0, no transactions observed by the monitor were missing or mismatched.

<img width="282" height="440" alt="image22" src="https://github.com/user-attachments/assets/b8ca8eb4-bb3a-4f65-9244-5883fb796ce3" />

UVM_WARNING, UVM_ERROR, and UVM_FATAL all terminated at 0. The report counts for serial_driver, serial_monitor, and serial_scoreboard matched at 156, confirming consistency between operation, observation, and judgment numbers. Each report_phase item count was interpreted as collector 12, coverage 16, and scoreboard 7.

| Log Category | Observed Value/Message | Result |
|---|---|---|
| Topology | Agent, collector, coverage, and scoreboard created under env | Monitor transaction broadcast structure confirmed |
| Transaction | Flow of 156 driver/monitor/scoreboard log entries confirmed | Drive, observation, and comparison flows match |
| Collector | 78 SPI and 78 I2C items, 156 test-kind items, average latency SPI=68 and I2C=315 cycles | Execution summary generated correctly for reporting |
| Scoreboard | pass 156, fail 0 | No planned transaction mismatch |
| Severity | UVM_WARNING 0, UVM_ERROR 0, UVM_FATAL 0 | Simulation completed without errors |
| Coverage log | protocol, test_kind, SPI data/cross, I2C address/ACK/RX, and latency output | Coverage items confirmed in the regression log |

Table 20. UVM log analysis items

### 5.5 Simulation results and Coverage analysis
| Item | Target (Spec) | Measured (Sim Result) | Result |
|---|---|---|---|
| serial_smoke_test | SPI 1 + I2C 1 PASS | scoreboard pass 2, fail 0 | Achieved |
| serial_regression_test | Full sequence PASS | SPI count 78, I2C count 78, pass 156, fail 0 | Achieved |
| UVM severity | UVM_ERROR/FATAL 0 | UVM_WARNING=0, UVM_ERROR=0, UVM_FATAL=0 | Achieved |
| Functional coverage | planned covergroup 100% | Testbench Group Score 100% | Achieved |
| spi-sim directed TB | SPI basic frame 2 PASS | tb_SPI.sv: A5<->3C, 5A<->C3 no mismatch | Achieved |
| i2c-sim directed TB | I2C write 2 PASS | tb_I2C.sv: addr 0x12 write A5/5A, ACK and target RX no mismatch | Achieved |

Table 21. Simulation Result Summary

<img width="738" height="565" alt="image23" src="https://github.com/user-attachments/assets/52730893-c677-459d-8915-346dbe50ad45" />

The overall score is 50.81, with detailed metrics of Line 43.27, Condition 53.81, Toggle 51.81, FSM 43.33, Branch 30.13, Assert 33.33, and Group 100.00. The Group score of 100.00 indicates that all functional coverage items defined in this UVM plan—protocol, test_kind, SPI data class, I2C ACK/RX, etc.—have been hit. The lower code coverage is attributed to the limited scope of SPI MODE0, 1-byte frame, and I2C write-only, combined with aggregation from tool and UVM library code.

<img width="1020" height="294" alt="image24" src="https://github.com/user-attachments/assets/cb2c73be-436f-48d7-9acb-e71f299df3d9" />

The score and instance score for `serial_uvm_pkg::serial_coverage::serial_cg` are both displayed as 100.00. AUTO BIN MAX 64 and PRINT MISSING 64 are covergroup report settings, used here as the basis for functional coverage to verify whether planned coverpoints and crosses within this scope were hit.

<img width="487" height="262" alt="image25" src="https://github.com/user-attachments/assets/dbaea470-98b8-4d83-808c-93026e003ebf" />

One test is included, and the database name is `simv/serial_regression`. The "1 test" here does not mean one UVM sequence; rather, it means one simulation run included in the coverage report. Since this report reflects a single regression execution containing multiple sequences, it serves as evidence of functional achievement but is not a merged coverage result from repeated runs with different random seeds. Therefore, since the rand test data occurs only once, future work should merge multiple seed regression databases to more rigorously verify random data combinations and cross coverage.

<img width="1302" height="847" alt="image26" src="https://github.com/user-attachments/assets/3fde0b22-04cf-40f7-bb85-52d8162a595b" />

Assertions show 1 success, 2 uncovered and without attempts, and 0 failures out of a total of 3. The successful item is the UVM component name check, while the missed items are assertions related to reg map read/write in `uvm_pkg`. Thus, it is interpreted as an improvement point that SVA directly verifying SPI/I2C operations for this project is insufficient.

<img width="3680" height="2380" alt="image27" src="https://github.com/user-attachments/assets/2f2ad487-7292-4d0f-ac3d-2d5b7d0a940e" />

The `tb_SPI_I2C_UVM` module appears to have scores of 83.42, Line 73.68, Condition 100.00, Toggle 100.00, and Branch 60.00. The reason Line coverage is not 100% is that some paths in testbench option code (such as waveform basename plusarg and FSDB dump option) were not executed; this should be interpreted separately from DUT transaction mismatch.

<img width="3592" height="2292" alt="image28" src="https://github.com/user-attachments/assets/e15f8dd9-742b-4530-97e5-a711bbdf9206" />

The condition displayed in `tb_SPI_I2C_UVM` shows 5 covered out of 5, totaling 100.00. Since example conditions such as `spi_ctrl_cs_n == 0` and `spi_tgt_sdo_oe` were observed in both true/false combinations, the selection region conditions at the top interface can be considered sufficiently toggled.

<img width="3592" height="2292" alt="image29" src="https://github.com/user-attachments/assets/cb06b7c5-54b0-46ec-ab91-674e5f190ae4" />

Clock toggles in `tb_SPI_I2C_UVM` show 0->1 and 1->0 both covered, totaling 100.00, but the overall dashboard toggle is 51.81. Signals like top clock that are always active yield high scores, while unused modes, read/error paths, and signals on the UVM recorder side remain low, causing the overall toggle score to decrease.

<img width="3592" height="2292" alt="image29" src="https://github.com/user-attachments/assets/cb06b7c5-54b0-46ec-ab91-674e5f190ae4" />

Analysis: The branch in `tb_SPI_I2C_UVM` shows 6 covered out of 10, totaling 60.00. Specifically, branches such as the WAVE_BASENAME plusarg missing input path and DUMP_FSDB option, where only one side executed, remain as missing else branches. Some of these are not due to DUT functionality limitations but result from using only a single testbench execution option.

<img width="1066" height="588" alt="image31" src="https://github.com/user-attachments/assets/fc714d26-a82e-4163-b9fe-ab5a30bf0bab" />

In the Verdi GUI, both average group score and group instance score are displayed as 100.00, with U+C 29, C 29, and U 0. This screen confirms via GUI that protocol, test_kind, SPI MODE0, SPI full-duplex cross, I2C addr, ACK/RX, and latency coverpoints were all hit in the same database as the HTML report.

<img width="936" height="372" alt="image32" src="https://github.com/user-attachments/assets/72bc5204-807d-4529-ac20-bf882ec2b6ed" />
The hierarchy/detail screen displays module-wise code coverage differences similar to I2C controller 60.45, I2C target 66.19, SPI controller 78.22, and SPI target 86.75. The SPI target is currently high as it aligns well with the current scenario, while I2C and FSM/toggle items remain low due to scenarios centered on write-only operations and normal ACKs. Additionally, uvm_custom_install_verdi_recording and uvm_pkg must be separated distinctly due to tool/library influences.

The summary of results for this simulation is as follows:

| Classification | Key Metrics | Cause Analysis | Improvement Link |
|---|---|---|---|
| Functional group | Group 100.00, serial_cg 100.00 | All planned protocol/test_kind/SPI/I2C coverpoints were hit | Add negative/read/mode coverage in the next iteration |
| Code coverage | Total 50.81, Branch 30.13, FSM 43.33 | Focused on normal writes and MODE0, leaving unused modes, option branches, and tool/library code uncovered | Expand scenarios for CPOL/CPHA, read, NACK, timeout, and option paths |
| Assertions | Total 3, success 1, failure 0, without attempts 2 | Aggregated primarily around UVM package assertions rather than project SVA | Add start-to-done, ACK, reset, and CS/frame bound assertions |
| Tests page | 1 DB: simv/serial_regression | Single regression run result; seed variance could not be verified | Perform multi-seed regression, merge coverage, and verify per-test contribution |
| Verdi GUI | Group U+C 29, C 29, U 0 | Verified same functional coverage hits in HTML report and Verdi | Repeat coverage verification starting from the sequence writing stage, not just at the end |

Table 22. Coverage report screen-by-screen verification contents

Detailed information regarding improvements is included in the result analysis section.

## 6. Result Analysis

### 6.1 Result Interpretation

Synthesizing results from Chapter 5 requires separating functional verification from coverage interpretation. Individual SPI/I2C top-level testbenches passed without basic transaction mismatches, and the UVM regression terminated with scoreboard pass 156, fail 0, and UVM_ERROR/FATAL 0, confirming that all planned normal transactions were successful.

In contrast, the total score of 50.81 on the coverage dashboard reflects a difference in verification scope and collection targets rather than functional failures. A Group score of 100.00 indicates that all functional coverpoints directly defined by this project were hit. Low code/assertion metrics such as Branch 30.13, FSM 43.33, and Assert 33.33 are interpreted as results stemming from the combination of SPI MODE0, I2C write-only operations, a single normal ACK flow, testbench option branches, and aggregated UVM/tool library code.

### 6.2 Problem Cause Analysis

| Category | Cause | Resolution and Follow-up Actions |
|---|---|---|
| UVM scope | Initial structure mixed SPI target instances with board demo perspectives, blurring verification scope | Fixed UVM top as SPI 1:1 and I2C 1:1; separated board demo evidence from automated verification evidence |
| Coverage DB | Initially thought to be coverage.vdb, but actual Verdi/URG DB was simv.vdb | Verified using `verdi -cov -covdir simv.vdb` and `urg -dir simv.vdb -report cov_report` |
| Code coverage | Focused on normal writes, SPI MODE0, and 1-byte frames caused mode/read/error/option branches to not execute | Added tests for CPOL/CPHA 0~3, I2C read, repeated START, NACK, timeout, and dump option paths |
| Assertions | Coverage report assertions were primarily uvm_pkg items; project-owned operational assertions were insufficient | Add SPI start-to-done, CS frame bound, I2C ACK phase, and reset valid low SVA assertions |
| Coverage process | Screen-by-screen meaning of coverage was understood only on the last day; results captured but too late for closure planning | For the next project, create covergroup/coverage checklists before sequence writing and verify dashboard and group after every regression |
| Report evidence | Waveforms alone make it difficult to explain expected/actual judgments and transaction counts | Present UVM logs, collector counts, scoreboard pass/fail status, and coverage metrics together |

Table 23. Issue resolution process

### 6.3 Improvement Plan

| Improvement Item | Current Limitation | Implementation Plan | Expected Outcome |
|---|---|---|---|
| Coverage-driven flow | Currently learning UVM and coverage report features; screen meanings summarized at the end | Define coverpoints, crosspoints, and SVA goals before sequence implementation; verify dashboard, group, test, and verification screens after each regression | Simultaneously manage functional pass/fail status and coverage gaps |
| Scenario expansion | Focused on SPI MODE0, 1-byte full-duplex, and I2C addr 0x12 write-only normal flows | Add scenarios for SPI CPOL/CPHA 0~3, multi-target CS, I2C read, repeated START, address mismatch, NACK, and timeout/recovery | Increase Branch, FSM, and toggle coverage; strengthen exception scenario verification |
| Project SVA | Current assertion coverage is primarily UVM package items, failing to directly guarantee DUT protocol rules | Add assertions for SPI start-to-done latency, CS active frame bound, rx_valid conditions, I2C ACK position, and reset valid low | Strengthen clock-level timing rule enforcement that scoreboards might miss |
| Multi-seed merge | Coverage tests page used only the single simv/serial_regression DB | Execute seed-specific regressions and compare accumulated coverage and per-test contribution via URG merge | Verify random test variance and strengthen evidence for coverage closure |
| Report metrics | Collector summaries focused on count and average latency | Add latency min/max, timeout counts, protocol-specific fail summaries, and test_kind pass/fail tables | Enable more quantitative root cause analysis in presentations and completion reports |

Table 24. Future improvement plan

In summary, this project completed normal transaction verification based on scoreboard pass/fail status and planned functional coverage. However, reviewing code coverage and assertion coverage together revealed that scenarios centered solely on normal writes may leave gaps in branch, FSM, and assertion-based verification. For the next project, we plan to use coverage reports not just as post-verification artifacts but as criteria to refine verification plans, incorporating scenario expansion and protocol assertion additions at earlier stages.

## 7. Conclusion

In this project, SPI/I2C communication previously used in peripheral or library forms was directly constructed from RTL and UVM perspectives. We confirmed that a transaction is established only when the communication protocol correctly aligns clock, data, select, ACK, timing, and valid/done conditions.
I understood SPI as a full-duplex structure where the Controller and Target exchange bytes simultaneously within the same frame, and I2C as a write path that confirms Target reception on a shared bus via address and ACK. In UVM verification, by dividing roles into driver, monitor, scoreboard, coverage, and collector, it became possible to explain what conditions were verified.

Remaining items for improvement include expanding SPI mode, multi-target verification, I2C read transactions, address mismatch, error/recovery scenarios, and configuring protocol-specific independent agents. Additionally, including coverage reports and assertions in the initial verification plan allows tracking not only whether functionality passes but also which conditions remain unverified.

Through this work, the flow of designing and verifying communication IPs began to appear more concretely than before.

## References

[0] Accellera Systems Initiative, Universal Verification Methodology (UVM) 1.2 User's Guide - https://www.accellera.org/images/downloads/standards/uvm/uvm_users_guide_1.2.pdf

[1] IEEE Standards Association, IEEE Std 1800-2023, SystemVerilog--Unified Hardware Design, Specification, and Verification Language - https://standards.ieee.org/ieee/1800/7743/

[2] NXP Semiconductors, UM10204 I2C-bus specification and user manual - https://www.nxp.com/documents/user_manual/UM10204.pdf

[3] Texas Instruments, Understanding the SPI Bus - https://www.ti.com/lit/pdf/sboa621

[4] Digilent, Basys 3 Reference Manual - https://digilent.com/reference/programmable-logic/basys-3/reference-manual

[5] AMD, Vivado Design Suite User Guide: Using the Vivado IDE (UG893) - https://docs.amd.com/r/en-US/ug893-vivado-ide
