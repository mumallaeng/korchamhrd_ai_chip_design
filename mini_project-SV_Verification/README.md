English | [한국어](README.ko.md)

# Verification of UART FIFO Loopback Using SystemVerilog

Kim Yeonwoo

2026.05.12 ~ 2026.05.17

## 1. Overview (Overview)

### 1.1 Purpose and Objectives

The purpose of this project is to rewrite the existing UART loopback structure (UART RX -> FIFO -> UART TX), which was within the original Verilog learning scope, using SystemVerilog, and to verify how design and verification become clearer during this process. The goal is not merely to change syntax but to confirm through implementation results how the expression of design intent and the separation of verification roles differ between actual RTL and testbench. The core objectives are as follows:

- Implement a buffered loopback path that restores incoming serial UART data from an external RX into bytes, stores it in a FIFO, and then outputs it via serial TX.
- Improve issues such as the conflation of wire/reg, always blocks, state representation, and TB roles evident in Verilog-style expressions to meet SystemVerilog standards.
- Configure three module testbenches and one top-level testbench in a self-checking structure with clearly defined PASS/FAIL criteria.

The key change in this project lies not so much in the functional structure itself, but in reorganizing previously learned content according to SystemVerilog standards and clarifying verification criteria.

### 1.2 Disadvantages of Verilog

| Item | Verilog Expression | Drawback |
|---|---|---|
| Sequential/Combinational block distinction | always @(posedge clk), always @(*) | Both start with `always`, requiring simultaneous review of sensitivity lists and internal code to judge block intent |
| Signal declaration distinction | wire, reg | Separated based on `assign` and procedural blocks; difficult to determine roles by looking at declarations alone |
| Meaning of `reg` | reg state;, reg y; | Although named after registers, they can be declared in combinational logic blocks, making it hard to immediately identify whether they are flip-flops |
| FSM state representation | 2'b00, 2'b01, parameter IDLE = 0 | Numbers and names are separated, making it difficult to read state meanings directly from the code |
| Data grouping expression | Declaring multiple signals separately | Becomes cumbersome as the number of related fields increases |
| Array representation | mem[0:255] centered | Simple memory representation is possible, but methods for storing verification data are limited |
| TB role separation | Directly configured using module, task, and variables | Input generation, DUT driving, output observation, and result comparison tend to be mixed in one place |

While design and verification are fully achievable with Verilog alone, as code size grows, there are many parts that require human interpretation: whether a block is sequential or combinational logic, the role of a signal, or the value of a state. These inconveniences become even more pronounced in collaboration.

### 1.3 Improvements in SystemVerilog - Design/Verification Commonalities

| Element | Meaning | Expected Effect |
|---|---|---|
| `logic` | General single-driver RTL signal declaration | Reduces the burden of choosing between `wire` and `reg` first |
| `bit`, `int`, `string` | Purpose-specific data types | Distinguishes calculation, flags, and message representation more clearly |
| `typedef enum` | Naming value sets | Makes it easier to read states by meaning rather than numbers |
| `struct` | Grouping related fields into one unit | Structurally expresses data meaning |
| `queue` | Ordered variable data structure | Useful for storing expected/actual data |
| `dynamic array` | Array with size determined at runtime | Useful for storing data with varying lengths |
| `associative array` | Key-based array | Useful for storing results or states by key |
| `interface` | Definition of signal bundles | Organizes the DUT-TB connection perspective |

Because each object can be expressed more intuitively, even when implementing the same functionality as Verilog, it becomes more natural to understand meaning from the code and connect the flow.

### 1.4 Improvements in SystemVerilog - Design

| Element | Difference from Verilog-style expression | Improvement in Design |
|---|---|---|
| `always_ff` | Separates `always @(posedge clk)` by intent | State storage blocks can be read immediately |
| `always_comb` | Separates `always @(*)` by intent | Next-state and combinational logic blocks can be read immediately |
| `logic` | Reduced burden of distinguishing wire/reg | Reset, register, and next-state signals are declared more consistently |
| `typedef enum logic` | Defines state values as named value sets | IDLE, START, DATA, STOP flows can be read by meaning instead of numbers |
| `interface` | Connects related signals in one place | Enables organization of both top-level module connections and DUT-TB connections |

From a design perspective, the core improvement is that state transitions and timing are much more intuitive in code; therefore, it becomes faster to identify "where state storage occurs and where combinational logic occurs."

### 1.5 Improvements in SystemVerilog - Verification

| Element | Role | Improvement in Verification |
|---|---|---|
| `virtual interface` | Access actual DUT signal bundles inside a class | Naturally connects the class with DUT pins |
| `class` | Defines roles such as generator, driver, monitor, scoreboard | Separates input generation, DUT driving, output observation, and result comparison by role |
| `mailbox` | Data transfer between classes | Explicitly structures verification data flow |
| `event` | Synchronization at execution points | Reduces race conditions and aligns transition points |
| `fork ... join` family | Parallel thread execution and termination control | Clearly expresses structures like simultaneous sending/receiving |
| `randomize()`, `constraint` | Automatic stimulus generation and constraint conditions | Makes it easy to systematically mix boundary values and exception values |
| `queue`, `dynamic array`, `associative array` | Expected model, temporary buffers, key-based storage | Structurally organizes comparison targets and observation results |
| `simple assert` | Quick basic condition check | Briefly checks basic contracts such as states immediately after reset |
| `coverage` | Checks occurrence of predefined verification conditions and states | Organizes the scope of verification items separately from PASS/FAIL |
| `covergroup` | Definition and measurement of coverage items | Measures verification items directly in code |

From a verification perspective, the core of SystemVerilog is that input generation, DUT driving, output observation, result comparison, parallel execution, and coverage checks can be structurally connected and expressed within a single language. In other words, the verification flow can be organized more clearly based on "what goes in, what is observed, and on what criteria PASS/FAIL is judged."

### 1.6 AS-IS / TO-BE

| Category | AS-IS | TO-BE |
|---|---|---|
| Implementation Standard | UART+FIFO+SENSOR+Watch_Stopwatch implemented in Verilog | Among them, UART RX -> FIFO -> UART TX is re-implemented in SystemVerilog |
| Functional Structure | The functionality of uart_rx -> fifo -> uart_tx already exists | The adjusted scope is redesigned as SystemVerilog RTL and verification testbench |
| Design Expression | Verilog-style expression: wire/reg, always, etc. | SystemVerilog-style expression: logic, always_ff, always_comb, enum, etc. |
| Verification Description | Waveform observation focused | Scenarios, criteria, and results can be structured |

This learning flow expanded in the order of Watch_Stopwatch -> UART -> FIFO -> SENSOR. In this sequence, Watch_Stopwatch is good for reading state transitions and time control, but it has limitations in explaining at once where data enters, passes through, and exits. SENSOR has a high proportion of external protocol descriptions, making SystemVerilog structural improvements easily obscure. Conversely, UART+FIFO presents the following four aspects simultaneously.
- The process of reconstructing serial input into bytes
- The process of storing the reconstructed bytes in the FIFO
- The process of retransmitting the stored bytes in the same order
- The process of verifying this entire path through driver/monitor/scoreboard role separation

Therefore, within the entire learning sequence, the UART+FIFO section was selected as the area where SystemVerilog improvements are most clearly demonstrated.

### 1.7 Design Specification Summary (Specification Summary)

| Item | Content |
|---|---|
| System Clock | 100 MHz |
| Baud rate | 9600 bps |
| Oversampling | 16x |
| UART frame | 8 data bits, no parity, 1 stop bit |
| FIFO depth | 16 |
| top module | uart_fifo_loopback |
| Design Goal | Implementation of buffered loopback path and completion of self-checking verification |

## 2. Project Management (Project Management)

### 2.1 Schedule Planning (Schedule)

| Phase | Duration | Key Tasks |
|---|---|---|
| Requirements Definition | 2026.05.12 | Purpose and goal scope confirmation, TB direction confirmation |
| Architecture Design | 2026.05.13 | UART RX -> FIFO -> UART TX design |
| RTL | 2026.05.13 | Design code written in SystemVerilog for RTL verification |
| Verification | 2026.05.14 ~ 2026.05.15 | Verification scenario confirmation and code writing |
| Deliverables Compilation | 2026.05.16 ~ 2026.05.17 | Presentation materials, completion report, schedule table, and log compilation |

### 2.2 Design Environment (Design Environment)

| Category | Content |
|---|---|
| Language | SystemVerilog |
| EDA | Vivado 2020.2 |
| Target FPGA Board | Digilent Basys 3 |

## 3. Architecture Design

### 3.1 Design Theory and Background

#### 3.1.1 UART

<img width="1672" height="941" alt="image3" src="https://github.com/user-attachments/assets/acdd297e-f309-4a3b-b81e-5e31be9a9740" />

UART is an asynchronous serial communication protocol that operates based on baud rate agreements without a separate clock line. This design uses 9600 bps, 8N1, and 16x oversampling as the baseline.

#### 3.1.2 FIFO

FIFO stands for First In, First Out; it is a buffer where data entered first is retrieved first. In this design, the internal structure was maintained as two blocks.

#### 3.1.3 Rationale for UART + FIFO Scope Selection

The criterion for scope selection is identifying sections where SystemVerilog makes both design and verification more readable simultaneously. The UART + FIFO combination features a clear data flow of receive -> store -> retransmit, allowing Testbenches (TB) to naturally accommodate an input generation -> DUT drive -> output observation -> result comparison structure.

### 3.2 System Structure

<img width="2048" height="1537" alt="image4" src="https://github.com/user-attachments/assets/5befa2b4-4c40-425b-a072-e14a3230513f" />

| Module | Role | Key Signals |
|---|---|---|
| baud_tick_gen | Common RX/TX baud_tick generation | o_baud_tick |
| uart_rx | Reconstructs serial input into bytes and completion pulse | rx_data, rx_done |
| fifo | Temporary storage of received bytes and order maintenance | push_data, pop_data, full, empty |
| uart_tx | Retransmits bytes as UART frames | tx, tx_busy |
| uart_fifo_loopback | Controls transmission start based on RX completion and FIFO status | w_tx_start |

## 4. Detailed Design

### 4.1 RTL Design

<img width="1600" height="271" alt="image5" src="https://github.com/user-attachments/assets/850b41d0-afb2-4c9b-87d9-395f61030dfc" />

| File | Description |
|---|---|
| baud_tick_gen.sv | Generates 9600 x 16 baud_ticks based on 100 MHz clock |
| uart_rx.sv | RX FSM: IDLE -> START -> DATA -> STOP |
| fifo.sv | Separated register_file + control_unit FIFO |
| uart_tx.sv | TX FSM: IDLE -> START -> DATA -> STOP |
| uart_fifo_loopback.sv | Single FIFO top connection and w_tx_start control |

### 4.2 Datapath / Control

| Category | Content |
|---|---|
| Datapath | rx serial input is reconstructed to bytes by uart_rx, passed through FIFO, and converted back to serial tx by uart_tx |
| RX control | Start bit detection, center sampling, rx_done generation |
| FIFO control | push, pop, wptr, rptr, full, empty control |
| TX control | tx_start detection, tx_busy maintenance, start/data/stop transmission |
| top control | push on rx_done; pop and transmission start when !empty && !tx_busy |

## 5. Simulation and Verification

### 5.1 Verification Theory and Background

As SoC scale and complexity increase, a greater variety of operating conditions must be thoroughly verified, thereby increasing the proportion of verification work. Existing Verilog-based verification environments faced limitations in systematically expanding complex testbench construction, object-oriented verification modeling, constraint-based random testing, and coverage measurement. To address this, SystemVerilog was expanded to include not only design syntax but also verification capabilities, becoming a hardware design and verification language.

However, even when using SystemVerilog, verification structures may vary by project and tool; therefore, a standard methodology is needed to maintain more consistent role separation and reusability. In this context, Accellera's UVM has established itself as the SystemVerilog-based standard verification methodology, enabling verification environments to be described based on hierarchy and roles. The representative components from the UVM perspective are as follows:

| Component | General Role | Element Mapped in This Implementation |
|---|---|---|
| test | Unit of verification execution, environment setup, and scenario selection | Execution flow of each TB module and env.run() call |
| environment | Connection of lower-level verification components and termination control | environment class |
| agent | Bundle of stimuli and observations based on a specific interface | Simplified to generator, driver, monitor without separate agent class |
| driver | Converts transactions into DUT pin stimuli | driver class |
| monitor | Observes DUT output and reconstructs into transactions | monitor class |
| scoreboard | Compares expected vs. actual results | scoreboard class |
| coverage collector | Collects occurrence of scenarios/conditions | Repeated observation items included in PASS criteria and cumulative checks |

The TB structure is not a direct import of the UVM Class Library but was organized around item, generator, driver, monitor, scoreboard, and environment-centered self-checking principles, referencing UVM's role separation viewpoint. Subsequently, each TB section will specifically explain the rationale for selecting mailbox, event, fork/join, and wait() in accordance with DUT characteristics and trial boundaries.
| TB | Core PASS Criteria |
|---|---|
| tb_fifo.sv | reset flags, full entry and overflow protection, empty entry and underflow protection, push/pop behavior in full/empty/partially-filled states, total_steps=68 |
| tb_uart_rx | Early rx_done prohibited, exactly one occurrence in stop window, 1-cycle pulse, data byte match, observation of 4 gap types |
| tb_uart_tx | idle start, start bit=0, data byte match, last value of frame=1, observation of tx_busy and idle restore, observation of 4 gap types |
| tb_uart_fifo_loopback | ordering/data match, last value of frame=1, tx_busy observed in all trials, payload_len=1,2,3,4 observed, 1->2/2->3/3->4 gap 4 types observed, final idle restore |

### 5.2 tb_fifo.sv

#### 5.2.1 Scenarios and PASS Criteria

| Step | Scenario | Repeat Count | PASS Criteria |
|---|---|---|---|
| 1 | Verify initial flag state immediately after reset | 1 | empty=1, full=0 |
| 2 | Verify full entry and overflow protection using push_only | DEPTH + 1 = 17 | Confirm full entry and overflow protection |
| 3 | Verify simultaneous push/pop in full state using push_pop(full) | 1 | In full state, pop takes precedence and level decreases by 1 |
| 4 | Verify empty entry and underflow protection using pop_only | DEPTH = 16 | Confirm empty entry and underflow protection |
| 5 | Verify simultaneous push/pop in empty state using push_pop(empty) | 1 | In empty state, push is reflected and level increases by 1 |
| 6 | Prepare partially-filled state interval using refill | HALF_DEPTH - 1 = 7 | Prepare partially-filled state interval |
| 7 | Verify level maintenance and data circulation in partially-filled state using push_pop(mid) | DEPTH = 16 | Confirm level maintenance and data circulation in partially-filled state |
| 8 | Verify final empty return and re-verify underflow using final pop_only | HALF_DEPTH + 1 = 9 | Confirm final empty entry and re-verify underflow |

| TestCase | Meaning | PASS Criteria |
|---|---|---|
| TC-FIFO-001 | reset flags | Immediately after reset, empty must be 1 and full must be 0 |
| TC-FIFO-002 | full entry and overflow protection | After full entry, overflow protection must be maintained even with additional pushes |
| TC-FIFO-003 | empty entry and underflow protection | After empty entry, underflow protection must be maintained even with additional pops |
| TC-FIFO-004 | push_pop contract in full/empty/partially-filled states | The intended level change for simultaneous push/pop must be correct in each state |
| TC-FIFO-005 | total_steps verification | Scoreboard must complete without missing steps up to total_steps=68 |

The repeat counts for the FIFO TB are all directly derived from depth.

| Item | Value | Reason |
|---|---|---|
| PUSH_ONLY_REPEAT | DEPTH + 1 | To observe full entry once and overflow protection once in a single iteration. |
| PUSH_POP_FULL_REPEAT | 1 | Observing the meaning of simultaneous push/pop in full state once is sufficient. |
| POP_ONLY_REPEAT | DEPTH | Since level becomes DEPTH-1 in the previous step, exactly DEPTH iterations are needed to observe empty entry and underflow together. |
| PUSH_POP_EMPTY_REPEAT | 1 | Observing the meaning of simultaneous push/pop in empty state once is sufficient. |
| REFILL_REPEAT | HALF_DEPTH - 1 | Since level is 1 in the previous step, HALF_DEPTH-1 iterations are needed to raise level to half depth. |
| PUSH_POP_MID_REPEAT | DEPTH | Repeatedly verified for sufficient duration whether level maintenance holds in partially-filled state. |
| FINAL_POP_REPEAT | HALF_DEPTH + 1 | To empty back to empty from partially-filled state and include the final underflow. |
| TOTAL_STEPS | 68 | Scoreboard verifies that no steps are missing up to this value. |

#### 5.2.2 Structure and Selection Rationale

<img width="1590" height="955" alt="image6" src="https://github.com/user-attachments/assets/517ef38b-c8be-44e7-a82d-dc084a1d0246" />

| Element | Reason |
|---|---|
| gen2drv_mbox | Required for the driver to apply step information generated by the generator in a cycle-accurate manner. |
| gen2scb_mbox | Required because the scoreboard must receive expected flags and expected data for the same step. |
| mon2scb_mbox | Required because the monitor must deliver actual full, empty, and pop_data to the scoreboard. |
| event_mon_next | Since FIFO semantics require reading immediately after DUT update in a single step, a barrier is placed so the monitor samples right after the driver updates the DUT. |

The execution structure is fork ... join_none followed by wait(scb.done) and disable fork. Since both the monitor and driver remain as live workers, binding them with join would prevent the run from closing immediately even if the generator finishes; using join_any could cause step loss if only one thread finishes first. Therefore, waiting for wait(scb.done) until the scoreboard verifies all steps and raises done, followed by thread cleanup, is the most natural approach.

#### 5.2.3 Simulation Verification

<img width="1597" height="287" alt="image7" src="https://github.com/user-attachments/assets/8af2a066-7ad2-4f08-87b3-a598c1cfd6e8" />

Initial empty/full state immediately after reset, push_only start interval, overflow protection after full entry, and push_pop(full) verification interval.

<img width="1600" height="291" alt="image8" src="https://github.com/user-attachments/assets/c3c2a3c0-8c58-4227-b2d3-4792c9e20121" />

Underflow protection after empty entry and push_pop(mid) verification in partially-filled state.

<img width="1599" height="279" alt="image9" src="https://github.com/user-attachments/assets/04fdc14e-5210-4c28-a5aa-68efe5637c14" />

Complete operation waveform.

### 5.3 tb_uart_rx

#### 5.3.1 Scenarios and PASS Criteria

| Step | Scenario | PASS Criteria |
|---|---|---|
| 1 | Repeat input of random serial frames 64 times to verify byte restoration | Observed byte must match sent byte |
| 2 | Verify occurrence of early rx_done in data interval | Early rx_done must not occur in the data interval |
| 3 | Verify timing of rx_done occurrence in stop window | rx_done must occur exactly once only in the stop window |
| 4 | Verify rx_done pulse width | rx_done pulse width must be 1 cycle |
| 5 | Verify observation of 4 clk_gap_sel types | All values of clk_gap_sel = 0,1,2,3 must be observed at least once |
| TestCase | Meaning | PASS Criteria |
|---|---|---|
| TC-RX-001 | Early rx_done prohibition | No early rx_done must occur in the data section. |
| TC-RX-002 | Stop window rx_done verification | rx_done must occur exactly once within the stop window. |
| TC-RX-003 | rx_done pulse width verification | The rx_done pulse width must be 1 cycle. |
| TC-RX-004 | Byte restoration verification | The observed byte must match the sent byte. |
| TC-RX-005 | clk_gap_sel full verification | clk_gap_sel = 0,1,2,3 must each be observed at least once. |

| Item | Value |
|---|---|
| RANDOM_REPEAT | 64 |
| RANDOM_SEED | 32'h0522_52A5 |
| Gap selection | clk_gap_sel = 0,1,2,3 |
| Actual gap | 0, 8, 16, 32 baud_tick |

The reason for setting RANDOM_REPEAT = 64 is to balance the observation coverage and runtime.

- The probability that all four gap types appear at least once must be sufficiently high; with N=64, this miss bound becomes very small.
- Simultaneously, a larger number of frames allows for more diverse observation of 8-bit data combinations than would be possible with too few frames.

#### 5.3.2 Structure and Rationale

<img width="1582" height="950" alt="image10" src="https://github.com/user-attachments/assets/6b7b1b62-e018-4cca-8319-ebae81de5808" />

| Element | Reason |
|---|---|
| gen2drv_mbox | Because the driver must convert the random frame information generated by the generator into actual UART rx stimuli. |
| gen2scb_mbox | Because the scoreboard needs to know the expected byte and the expected gap selection value. |
| mon2scb_mbox | Because the monitor must pass observed_byte, early_done_seen, and done_hits_in_stop to the scoreboard. |

The execution structure is fork ... join_none followed by wait(scb.done) and disable fork. The RX driver, monitor, and scoreboard must run concurrently, while the generator supplies 64 trials sequentially from the foreground. Because join involves a long-lived worker, the termination criterion becomes ambiguous; similarly, join_any may prematurely exit before frame comparison is complete if only one thread finishes first. Therefore, wait(scb.done) was chosen because it most clearly indicates whether the scoreboard has finished comparing all frames.

### 5.4 tb_uart_tx

#### 5.4.1 Scenarios and PASS Criteria

| Order | Scenario | PASS Criteria |
|---|---|---|
| 1 | Verify idle state before frame start | The state tx=1, tx_busy=0 must be maintained before the frame starts. |
| 2 | Verify start bit section | tx must be 0 during the start bit section. |
| 3 | Verify data byte decode result | The decoded data byte must match the expected byte. |
| 4 | Verify last value of frame | The last value of the frame must be 1. |
| 5 | Verify tx_busy and idle restore | tx_busy must be observed in every frame, and idle must be restored after termination. |
| 6 | Verify observation of all four clk_gap_sel types | clk_gap_sel = 0,1,2,3 must each be observed at least once. |

| TestCase | Meaning | PASS Criteria |
|---|---|---|
| TC-TX-001 | Verify idle state before frame start | The state tx=1, tx_busy=0 must be maintained before the frame starts. |
| TC-TX-002 | Verify start bit | tx must be 0 during the start bit section. |
| TC-TX-003 | Verify data byte decode | The decoded data byte must match the expected byte. |
| TC-TX-004 | Verify last value of frame | The last value of the frame must be 1. |
| TC-TX-005 | Verify tx_busy and idle restore | tx_busy must be observed in every frame, and idle must be restored after termination. |
| TC-TX-006 | Verify full clk_gap_sel observation | clk_gap_sel = 0,1,2,3 must each be observed at least once. |

| Item | Value |
|---|---|
| RANDOM_REPEAT | 64 |
| RANDOM_SEED | 32'h0522_BEE5 |
| Gap selection | clk_gap_sel = 0,1,2,3 |
| Actual gap | 0, 8, 16, 32 baud_tick |

The reason for setting RANDOM_REPEAT = 64 is the same as for RX. With N=64, the miss bound for four gap types is sufficiently small, and diverse combinations of 8-bit data can also be passed through.

#### 5.4.2 Structure and Rationale

<img width="1472" height="779" alt="image11" src="https://github.com/user-attachments/assets/46dee3dd-4d54-4af3-9676-8e798bf04cdf" />

| Element | Reason |
|---|---|
| gen2drv_mbox | Because the driver must convert the random byte and gap selection value generated by the generator into actual tx_start/tx_data stimuli. |
| gen2scb_mbox | Because the scoreboard needs to know the expected byte and the expected gap selection value. |
| mon2scb_mbox | Because the scoreboard must receive observed_byte, idle_before_start, busy_seen, and idle_restored observed by the monitor. |
| event_gen_next | In TX, if the next expected item is issued before the monitor and scoreboard have fully consumed the current frame, the expected/actual pairing may shift. To prevent this, the scoreboard was paced to wait until the current frame comparison is complete before the generator issues the next trial. |

The internal capture_frame() function in the monitor uses fork ... join. This is because the result of a frame is only complete when both the bit decode thread and the tx_busy observation thread finish. If either finishes prematurely, busy_seen or idle restore determination becomes invalid; therefore, plain join is correct, while join_any or join_none could result in an incomplete current frame determination.

The execution structure of the environment is fork ... join_none followed by wait(scb.done) and disable fork. Running the worker in the background and using scoreboard completion as the final termination criterion are consistent with other TBs. Here too, join makes termination control difficult because the worker remains alive, and join_any may exit prematurely while frames yet to be compared remain.

### 5.5 tb_uart_fifo_loopback (top)

#### 5.5.1 Scenarios and PASS Criteria

The top TB repeats random 1~4 byte input bundles 256 times to verify the entire RX -> FIFO -> TX path end-to-end.

For explanatory convenience, the top verification can also be grouped into the following four higher-level scenarios.

| Higher-Level Scenario | Description |
|---|---|
| 1 | Verify in reverse order payload_len=4,3,2,1 to confirm that input bundles of 4 bytes down to 1 byte are all transmitted normally end-to-end. |
| 2 | Accumulatively verify whether ordering/data, the last value of the frame, and tx_busy are normal in each trial within the same random 256-trial set. |
| 3 | Accumulate the entire same random 256-trial set to confirm that payload_len=1,2,3,4 and byte gap conditions have each occurred at least once. |
| 4 | After all trials end, verify whether the idle state is properly restored with tx=1, tx_busy=0. |

Representative simulation captures are organized in the order of payload_len=4,3,2,1.
| Step | Scenario | Pass Criteria |
|---|---|---|
| 1 | End-to-end ordering/data verification | The length of actual_q must match that of expected_q, and each byte must reappear in the same order and value. |
| 2 | Frame last value verification | The frame last value must be 1 in all received results. |
| 3 | tx_busy observation verification | tx_busy=1 must be observed in every trial. |
| 4 | Full payload_len verification (1,2,3,4) | During 256 random iterations, input bundles of 1~4 bytes must each be observed at least once. |
| 5 | Four types of byte gap verification (1->2, 2->3, 3->4) | At each position, intervals of 0, 8, 16, and 32 baud_tick must each be observed at least once. |
| 6 | Final idle restore verification | After all trials end, the state must conclude with tx=1 and tx_busy=0. |

| TestCase | Meaning | Pass Criteria |
|---|---|---|
| TC-LOOP-001 | ordering/data verification | The length of actual_q must match that of expected_q, and each byte must reappear in the same order and value. |
| TC-LOOP-002 | Frame last value verification | The frame last value must be 1 in all received results. |
| TC-LOOP-003 | tx_busy observation verification | tx_busy=1 must be observed in every trial. |
| TC-LOOP-004 | Full payload_len verification | payload_len values of 1, 2, and 3 must each be observed at least once. |
| TC-LOOP-005 | Full byte gap verification | For each of the 1->2, 2->3, and 3->4 byte gaps, intervals of 0, 8, 16, and 32 baud_tick must each be observed at least once. |
| TC-LOOP-006 | Final idle restore verification | After all trials end, the system must return to idle with tx=1 and tx_busy=0. |

| Item | Value |
|---|---|
| RANDOM_REPEAT | 256 |
| RANDOM_SEED | 32'h0522_C0DE |
| payload_len | Selected uniformly from 1, 2, 3, 4 |
| byte gap selection | byte12_gap_sel, byte23_gap_sel, byte34_gap_sel = 0, 1, 2, 3 |
| Actual gap | 0, 8, 16, 32 baud_tick |

The reason for setting RANDOM_REPEAT to 256 is to sufficiently reduce the probability of missing rare control cases. In this TB, the scenario where payload_len=4 and specific selection values at each gap position are simultaneously required is the rarest case.

Viewed as a miss count for observing all four types of gaps, N=256 is sufficiently small; this ensures stability in condition occurrence without excessively increasing runtime.

#### 5.5.2 Structure and Selection Rationale

<img width="2048" height="1076" alt="image12" src="https://github.com/user-attachments/assets/9d6335b2-a65e-489f-b1e8-d00d4e1af0dd" />

| Element | Reason |
|---|---|
| gen2drv_mbox | The generator creates a variable-length payload that the driver must convert into the actual UART rx stream. |
| gen2mon_mbox | The monitor needs to know how many bytes to receive in this trial. Without payload_len information, the termination boundary of capture_trial() cannot be determined, so it is required only in the top TB. |
| gen2scb_mbox | The scoreboard needs to know the expected payload and expected gap selection values. |
| mon2scb_mbox | The scoreboard must receive actual_q, stop_bit_ok, and busy_seen restored by the monitor. |
| event_gen_next | Since the top TB mixes variable-length trials, issuing the next item before the current trial's expected/actual comparison finishes could cause pairing mismatches. The scoreboard paced the generator to issue the next trial only after completing the current trial comparison. |

Inside capture_trial() in the monitor, fork ... join is used. One thread receives bytes according to payload_len to build actual_q, while another thread observes tx_busy during the same trial. Since both threads must finish for a trial's result to be complete, plain join is correct; join_any or join_none could result in incomplete variable-length trial results.

The execution structure of the environment is fork ... join_none followed by wait(scb.done) and disable fork. The driver, monitor, and scoreboard are run as background workers in parallel, while the generator handles trial pacing in the foreground. Join is inappropriate as a termination criterion due to long-lived workers, and join_any could prematurely exit while uncompleted trials remain. The most clear termination point is when the scoreboard finishes comparing all 256 trials, so wait(scb.done) was used.

Additionally, TC-LOOP-006 does not check immediately after the scoreboard completes; instead, it first calls drv.wait_final_idle() and then verifies. This is because the last byte may still be physically draining internally within the UART TX. Thus, "trial comparison completion" and "actual tx=1, tx_busy=0 return completion" are different points in time, so final idle restore was checked separately after draining.

#### 5.5.3 Simulation Verification

Representative simulation captures were organized by representative trials in payload_len order (4, 3, 2, 1), followed by random cumulative verification and final idle restore.

**payload_len=4**

<img width="918" height="294" alt="image13" src="https://github.com/user-attachments/assets/ef472edf-13ef-46e9-b204-53046c154c88" />

After reset, this shows the case where payload_len=4, meaning four bytes of data arrive consecutively. Checking c_state reveals that the DATA State is active four times. rx_done occurs for the number of input bytes, and it can be confirmed that this value reappears in the same order on the TX side.

**payload_len=3**

<img width="950" height="329" alt="image14" src="https://github.com/user-attachments/assets/fc582571-8d97-40b3-8b39-e1d348d26d8b" />

**payload_len=2**

<img width="946" height="328" alt="image15" src="https://github.com/user-attachments/assets/141a7fa1-14aa-47a4-9c11-4508ef8f77bb" />

**payload_len=1**

<img width="946" height="256" alt="image16" src="https://github.com/user-attachments/assets/e988cf0d-c6c9-43e8-80bc-59d790d078e4" />

**Verification of TC-LOOP-001 ~ 003 in the random 256 iterations cumulative section**

<img width="927" height="462" alt="image17" src="https://github.com/user-attachments/assets/41208b1e-e1fd-47c4-b2da-360cd8a3c171" />

This cumulatively verifies that ordering and data alignment are maintained throughout 256 repeated random trials.

Scenario 2 also checks whether the frame last value is 1 and tx_busy=1 is actually observed in each trial within this random section. This can be confirmed in the TC-LOOP-001, TC-LOOP-002, and TC-LOOP-003 PASS logs.

**Verification of TC-LOOP-004 and TC-LOOP-005 in the same random section**
<img width="961" height="431" alt="image18" src="https://github.com/user-attachments/assets/d5b0da8c-d2f2-4d89-95ce-c1e860f86a8a" />

Scenario 3 verifies whether the baud_tick intervals of 1 to 2 (0~8), 2 to 3 (8~16), and 3 to 4 (16~32 bytes) all appeared within the same random interval as in the preceding scenario, with payload_len ranging from 1 to 4.

The accumulated TC-LOOP-004 and TC-LOOP-005 PASS logs on the Scoreboard allow for quick verification.

**After all trials are completed, verify TC-LOOP-006 final idle restore.**

<img width="931" height="426" alt="image19" src="https://github.com/user-attachments/assets/31cfa5d2-7c5f-44fd-b24e-9b527017cf7b" />

In the final scenario 4, TC-LOOP-006 verifies whether the idle state normally returns with tx=1 and tx_busy=0 after all trials are completed, marking the end of the entire TestCase.

## 6. Conclusion and Discussion

### 6.1 Conclusion

In this project, we directly implemented the design-to-verification process for a loopback path structured as UART RX -> FIFO -> UART TX using SystemVerilog. Through this process, it was confirmed that compared to Verilog-based development, SystemVerilog allows for a more structured organization of design intent and verification flow based on roles.

Additionally, by configuring three module TBs and one top TB in a self-checking structure targeting the UART + FIFO loopback, we applied SystemVerilog features such as class, mailbox, event, and virtual interface, along with the role separation structure of the UVM methodology, to actual code. Particularly during the process of concretely organizing verification scenarios and PASS criteria, it was confirmed that it is important to align the design structure and verification results so they can be read under the same criteria.

### 6.2 Discussion and Future Directions

This verification environment proceeded by directly configuring structures corresponding to generator, driver, monitor, scoreboard, and environment instead of directly importing and using the UVM Class Library. Through this, it was confirmed that understanding the internal structure of each component—such as roles, data flow, and synchronization methods—is more important than simply learning how to use the library if one wishes to utilize standard methodologies.

Furthermore, in the process of writing verification scenarios more concretely, we had to carefully re-examine the design content, confirming that design and verification are not independent procedures but rather complementary relationships. Moving forward, based on this experience, we aim to expand the scope to include SystemVerilog features not yet used and the actual UVM Class Library, developing more diverse verification structures and reusable testbench configurations.

## References

- IEEE Std 1800, SystemVerilog Unified Hardware Design, Specification, and Verification Language
- Accellera UVM User's Guide 1.2
- IEEE 1800.2 series UVM Reference Implementation / Class Reference
- Accellera UVM Download (https://www.accellera.org/downloads/standards/uvm)
- Accellera UVM 1.0 Class Reference (https://www.accellera.org/images/downloads/standards/uvm/UVM_Class_Reference_Manual_1.0.pdf)
- MathWorks UVM Overview (https://www.mathworks.com/discovery/uvm-verification.html)
- Course Lab Code and Lecture Notes
