`timescale 1ns / 1ps

interface uart_tx_if;
    logic       clk;
    logic       rst;
    logic       baud_tick;
    logic       tx_start;
    logic [7:0] tx_data;
    logic       tx_busy;
    logic       tx;
endinterface

bit uart_tx_tb_failed = 1'b0;

task automatic uart_tx_log_fail(input string tag, input string msg);
    if (!uart_tx_tb_failed) begin
        uart_tx_tb_failed = 1'b1;
        $display("[%s] FAIL: %s", tag, msg);
    end
    $finish;
endtask

task automatic uart_tx_log_pass(input string tag, input string msg);
    if (!uart_tx_tb_failed) begin
        $display("[%s] PASS: %s", tag, msg);
    end
endtask

class uart_tx_item;
    rand bit [7:0] send_byte;
    rand bit [1:0] clk_gap_sel;

    bit [7:0]      observed_byte;
    bit            idle_before_start;
    bit            start_bit_ok;
    bit            stop_bit_ok;
    bit            busy_seen;
    bit            idle_restored;

    constraint rand_c {
        send_byte dist { [8'h00:8'hFF] :/ 256 };
        clk_gap_sel dist { 2'd0 := 1, 2'd1 := 1, 2'd2 := 1, 2'd3 := 1 };
    }

    function uart_tx_item clone_item();
        uart_tx_item item;

        item                   = new();
        item.send_byte         = send_byte;
        item.clk_gap_sel       = clk_gap_sel;
        item.observed_byte     = observed_byte;
        item.idle_before_start = idle_before_start;
        item.start_bit_ok      = start_bit_ok;
        item.stop_bit_ok       = stop_bit_ok;
        item.busy_seen         = busy_seen;
        item.idle_restored     = idle_restored;
        return item;
    endfunction

    function void debug_print(string prefix);
        $display(
            "Time: %0t [%s] send=%02h clk_gap_sel=%0d observed=%02h idle=%0b start=%0b stop=%0b busy=%0b restore=%0b",
            $time,
            prefix,
            send_byte,
            clk_gap_sel,
            observed_byte,
            idle_before_start,
            start_bit_ok,
            stop_bit_ok,
            busy_seen,
            idle_restored
        );
    endfunction
endclass

class uart_tx_generator;
    uart_tx_item                tr;
    mailbox #(uart_tx_item)     gen2drv_mbox;
    mailbox #(uart_tx_item)     gen2scb_mbox;
    // TX는 monitor와 scoreboard가 현재 frame을 다 소비한 뒤 다음 trial로 넘어가야 해서 pacing event를 둔다.
    event                       event_gen_next;
    int                         random_seed;

    function new(
        mailbox #(uart_tx_item) gen2drv_mbox,
        mailbox #(uart_tx_item) gen2scb_mbox,
        event                   event_gen_next,
        input int               random_seed
    );
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.event_gen_next = event_gen_next;
        this.random_seed = random_seed;
    endfunction

    task run(int repeat_count);
        for (int idx = 0; idx < repeat_count; idx++) begin
            tr = new();
            tr.srandom(random_seed + idx);
            assert (tr.randomize())
            else $error("tb_uart_tx generator randomization failed");

            gen2drv_mbox.put(tr);
            gen2scb_mbox.put(tr.clone_item());
            tr.debug_print("GEN");
            @(event_gen_next);
        end
        $display("GEN end task");
    endtask
endclass

class uart_tx_driver;
    uart_tx_item                tr;
    virtual uart_tx_if          uart_tx_vif;
    mailbox #(uart_tx_item)     gen2drv_mbox;

    function new(
        mailbox #(uart_tx_item) gen2drv_mbox,
        virtual uart_tx_if      uart_tx_vif
    );
        this.gen2drv_mbox = gen2drv_mbox;
        this.uart_tx_vif = uart_tx_vif;
    endfunction

    task preset();
        uart_tx_vif.rst      <= 1'b1;
        uart_tx_vif.tx_start <= 1'b0;
        uart_tx_vif.tx_data  <= '0;
        repeat (4) @(posedge uart_tx_vif.clk);
        uart_tx_vif.rst <= 1'b0;
        @(posedge uart_tx_vif.clk);
    endtask

    // clk_gap_sel 0,1,2,3은 0, 8, 16, 32 baud_tick 간격
    function automatic int gap_ticks(input bit [1:0] clk_gap_sel);
        case (clk_gap_sel)
            2'd0: return 0;
            2'd1: return 8;
            2'd2: return 16;
            default: return 32;
        endcase
    endfunction

    task automatic launch_frame(
        input bit [7:0] send_data,
        input int       gap_tick_count
    );
        if (gap_tick_count > 0) begin
            repeat (gap_tick_count) @(posedge uart_tx_vif.baud_tick);
        end

        while (uart_tx_vif.tx_busy) begin
            @(posedge uart_tx_vif.clk);
        end

        @(posedge uart_tx_vif.baud_tick);
        @(negedge uart_tx_vif.clk);
        uart_tx_vif.tx_data  <= send_data;
        uart_tx_vif.tx_start <= 1'b1;
        @(negedge uart_tx_vif.clk);
        uart_tx_vif.tx_start <= 1'b0;
    endtask

    task transmit_only(int repeat_count);
        $display("uart_tx random transmit test start");
        repeat (repeat_count) begin
            gen2drv_mbox.get(tr);
            launch_frame(tr.send_byte, gap_ticks(tr.clk_gap_sel));
            tr.debug_print("DRV");
        end
    endtask
endclass

class uart_tx_monitor;
    uart_tx_item                tr;
    virtual uart_tx_if          uart_tx_vif;
    mailbox #(uart_tx_item)     mon2scb_mbox;

    function new(
        mailbox #(uart_tx_item) mon2scb_mbox,
        virtual uart_tx_if      uart_tx_vif
    );
        this.mon2scb_mbox = mon2scb_mbox;
        this.uart_tx_vif = uart_tx_vif;
    endfunction

    task automatic wait_baud_ticks(input int count);
        repeat (count) @(posedge uart_tx_vif.baud_tick);
    endtask

    task automatic capture_frame();
        int bit_idx;
        int oversample;
        bit frame_done;

        tr = new();
        oversample = 16;
        frame_done = 1'b0;

        while (!((uart_tx_vif.tx === 1'b1) && (uart_tx_vif.tx_busy === 1'b0))) begin
            @(posedge uart_tx_vif.clk);
        end
        tr.idle_before_start = 1'b1;

        // bit decode와 tx_busy 관찰이 모두 끝나야 한 frame의 결과가 완성되므로 여기서는 plain join을 사용한다.
        fork
            begin : capture_bits
                @(negedge uart_tx_vif.tx);
                tr.start_bit_ok = (uart_tx_vif.tx === 1'b0);

                wait_baud_ticks(oversample + (oversample / 2));
                for (bit_idx = 0; bit_idx < 8; bit_idx++) begin
                    tr.observed_byte[bit_idx] = uart_tx_vif.tx;
                    wait_baud_ticks(oversample);
                end

                tr.stop_bit_ok = (uart_tx_vif.tx === 1'b1);
                wait_baud_ticks(oversample);
                frame_done = 1'b1;
            end
            begin : watch_busy
                while (!frame_done || uart_tx_vif.tx_busy) begin
                    @(posedge uart_tx_vif.clk);
                    if (uart_tx_vif.tx_busy) begin
                        tr.busy_seen = 1'b1;
                    end
                end
            end
        join

        tr.idle_restored = ((uart_tx_vif.tx === 1'b1) && (uart_tx_vif.tx_busy === 1'b0));

        mon2scb_mbox.put(tr);
        tr.debug_print("MON");
    endtask

    task run(int repeat_count);
        repeat (repeat_count) begin
            capture_frame();
        end
    endtask
endclass

class uart_tx_scoreboard;
    uart_tx_item                exp_tr;
    uart_tx_item                act_tr;
    mailbox #(uart_tx_item)     gen2scb_mbox;
    mailbox #(uart_tx_item)     mon2scb_mbox;
    event                       event_gen_next;
    int                         random_seed;
    bit [3:0]                   gap_seen;
    bit                         done;

    function new(
        mailbox #(uart_tx_item) gen2scb_mbox,
        mailbox #(uart_tx_item) mon2scb_mbox,
        event                   event_gen_next,
        input int               random_seed
    );
        this.gen2scb_mbox = gen2scb_mbox;
        this.mon2scb_mbox = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
        this.random_seed = random_seed;
    endfunction

    task run(int repeat_count);
        gap_seen = '0;
        done     = 1'b0;

        repeat (repeat_count) begin
            gen2scb_mbox.get(exp_tr);
            mon2scb_mbox.get(act_tr);

            if (!act_tr.idle_before_start) begin
                uart_tx_log_fail("TC-TX-001", "tx must start from idle state");
            end
            if (!act_tr.start_bit_ok) begin
                uart_tx_log_fail("TC-TX-002", "start bit must be low");
            end
            if (act_tr.observed_byte != exp_tr.send_byte) begin
                uart_tx_log_fail(
                    "TC-TX-003",
                    $sformatf("data mismatch: expected=%02h got=%02h", exp_tr.send_byte, act_tr.observed_byte)
                );
            end
            if (!act_tr.stop_bit_ok) begin
                uart_tx_log_fail("TC-TX-004", "stop bit must stay high");
            end
            if (!act_tr.busy_seen || !act_tr.idle_restored) begin
                uart_tx_log_fail("TC-TX-005", "tx_busy/idle restore contract");
            end

            gap_seen[exp_tr.clk_gap_sel] = 1'b1;
            ->event_gen_next;
        end

        if (gap_seen != 4'b1111) begin
            uart_tx_log_fail("TC-TX-006", "random test must observe clk_gap_sel 0,1,2,3");
        end

        uart_tx_log_pass("TC-TX-001", $sformatf("idle start condition held across %0d random frames", repeat_count));
        uart_tx_log_pass("TC-TX-002", "start bit stayed low across all random frames");
        uart_tx_log_pass("TC-TX-003", $sformatf("random frames matched %0d 8-bit bytes", repeat_count));
        uart_tx_log_pass("TC-TX-004", "stop bit stayed high across all random frames");
        uart_tx_log_pass("TC-TX-005", "tx_busy observed and idle restored across all random frames");
        uart_tx_log_pass("TC-TX-006", $sformatf("clk_gap_sel 0,1,2,3 all observed with repeat=%0d seed=%08x", repeat_count, random_seed));
        uart_tx_log_pass("tb_uart_tx", "completed");
        done = 1'b1;
    endtask
endclass

class uart_tx_environment;
    uart_tx_generator              gen;
    uart_tx_driver                 drv;
    uart_tx_monitor                mon;
    uart_tx_scoreboard             scb;
    virtual uart_tx_if             uart_tx_vif;

    mailbox #(uart_tx_item) gen2drv_mbox;
    mailbox #(uart_tx_item) gen2scb_mbox;
    mailbox #(uart_tx_item) mon2scb_mbox;
    event                   event_gen_next;

    function new(
        virtual uart_tx_if uart_tx_vif,
        input int          random_seed
    );
        gen2drv_mbox = new();
        gen2scb_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen2scb_mbox, event_gen_next, random_seed);
        drv = new(gen2drv_mbox, uart_tx_vif);
        mon = new(mon2scb_mbox, uart_tx_vif);
        scb = new(gen2scb_mbox, mon2scb_mbox, event_gen_next, random_seed);
        this.uart_tx_vif = uart_tx_vif;
    endfunction

    task run(int repeat_count);
        // generator가 foreground에서 trial 순서를 조절하고, background worker는 scoreboard done까지 병렬 실행한다.
        drv.preset();
        fork
            drv.transmit_only(repeat_count);
            mon.run(repeat_count);
            scb.run(repeat_count);
        join_none

        gen.run(repeat_count);
        wait (scb.done);
        disable fork;
    endtask
endclass

module tb_uart_tx;
    localparam int CLK_FREQ_HZ   = 100_000_000;
    localparam int BAUD_HZ       = 9600;
    localparam int OVERSAMPLE    = 16;
    // Scenario: random byte를 반복 송신해서 start/data/stop과 tx_busy 동작을 확인
    // 1) 바이트 사이 간격 4종을 모두 확인
    // 2) 8개 data bit의 0/1 조합을 충분히 반복
    // gap case miss 상계 4*(3/4)^N 기준으로 N=64면 충분
    // 이에 따라 repeat=64
    // transaction마다 RANDOM_SEED + idx를 사용하여
    // 동일한 seed면 같은 입력 순서를 재현하도록 함
    localparam int RANDOM_REPEAT = 64;
    localparam int RANDOM_SEED   = 32'h0522_BEE5;
    localparam int TIMEOUT_NS    = 120_000_000;

    uart_tx_if tb_if ();
    uart_tx_environment env;

    uart_tx dut (
        .clk      (tb_if.clk),
        .rst      (tb_if.rst),
        .baud_tick(tb_if.baud_tick),
        .tx_start (tb_if.tx_start),
        .tx_data  (tb_if.tx_data),
        .tx_busy  (tb_if.tx_busy),
        .tx       (tb_if.tx)
    );

    baud_tick_gen #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_HZ    (BAUD_HZ),
        .OVERSAMPLE (OVERSAMPLE)
    ) tb_baud_tick_gen (
        .clk        (tb_if.clk),
        .rst        (tb_if.rst),
        .o_baud_tick(tb_if.baud_tick)
    );

    always #5 tb_if.clk = ~tb_if.clk;

    initial begin
        #TIMEOUT_NS;
        $display("[tb_uart_tx] FAIL: timeout");
        $finish;
    end

    initial begin
        tb_if.clk      = 1'b0;
        tb_if.rst      = 1'b0;
        tb_if.tx_start = 1'b0;
        tb_if.tx_data  = '0;

        env = new(tb_if, RANDOM_SEED);
        env.run(RANDOM_REPEAT);

        #20;
        $finish;
    end
endmodule
