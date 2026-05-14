`timescale 1ns / 1ps

interface uart_rx_if;
    logic       clk;
    logic       rst;
    logic       baud_tick;
    logic       rx;
    logic       rx_done;
    logic [7:0] rx_data;
endinterface

bit uart_rx_tb_failed = 1'b0;

task automatic uart_rx_log_fail(input string tag, input string msg);
    if (!uart_rx_tb_failed) begin
        uart_rx_tb_failed = 1'b1;
        $display("[%s] FAIL: %s", tag, msg);
    end
    $finish;
endtask

task automatic uart_rx_log_pass(input string tag, input string msg);
    if (!uart_rx_tb_failed) begin
        $display("[%s] PASS: %s", tag, msg);
    end
endtask

class uart_rx_item;
    rand bit [7:0] send_byte;
    rand bit [1:0] clk_gap_sel;

    bit [7:0]      observed_byte;
    bit            early_done_seen;
    bit            done_seen_in_stop;
    int            done_hits_in_stop;
    int            done_pulse_cycles;

    constraint rand_c {
        send_byte dist { [8'h00:8'hFF] :/ 256 };
        clk_gap_sel dist { 2'd0 := 1, 2'd1 := 1, 2'd2 := 1, 2'd3 := 1 };
    }

    function uart_rx_item clone_item();
        uart_rx_item item;

        item                    = new();
        item.send_byte          = send_byte;
        item.clk_gap_sel        = clk_gap_sel;
        item.observed_byte      = observed_byte;
        item.early_done_seen    = early_done_seen;
        item.done_seen_in_stop  = done_seen_in_stop;
        item.done_hits_in_stop  = done_hits_in_stop;
        item.done_pulse_cycles  = done_pulse_cycles;
        return item;
    endfunction

    function void debug_print(string prefix);
        $display(
            "Time: %0t [%s] send=%02h clk_gap_sel=%0d observed=%02h early_done=%0b stop_hits=%0d pulse_cycles=%0d",
            $time,
            prefix,
            send_byte,
            clk_gap_sel,
            observed_byte,
            early_done_seen,
            done_hits_in_stop,
            done_pulse_cycles
        );
    endfunction
endclass

class uart_rx_generator;
    uart_rx_item                tr;
    mailbox #(uart_rx_item)     gen2drv_mbox;
    mailbox #(uart_rx_item)     gen2scb_mbox;
    int                          random_seed;

    function new(
        mailbox #(uart_rx_item)       gen2drv_mbox,
        mailbox #(uart_rx_item)       gen2scb_mbox,
        input int                     random_seed
    );
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.random_seed = random_seed;
    endfunction

    task run(int repeat_count);
        for (int idx = 0; idx < repeat_count; idx++) begin
            tr = new();
            tr.srandom(random_seed + idx);
            assert (tr.randomize())
            else $error("tb_uart_rx generator randomization failed");

            gen2drv_mbox.put(tr);
            gen2scb_mbox.put(tr.clone_item());
            tr.debug_print("GEN");
        end
        $display("GEN end task");
    endtask
endclass

class uart_rx_driver;
    uart_rx_item                tr;
    virtual uart_rx_if          uart_rx_vif;
    mailbox #(uart_rx_item)     gen2drv_mbox;

    function new(
        mailbox #(uart_rx_item) gen2drv_mbox,
        virtual uart_rx_if      uart_rx_vif
    );
        this.gen2drv_mbox = gen2drv_mbox;
        this.uart_rx_vif = uart_rx_vif;
    endfunction

    task preset();
        uart_rx_vif.rst <= 1'b1;
        uart_rx_vif.rx  <= 1'b1;
        repeat (4) @(posedge uart_rx_vif.clk);
        uart_rx_vif.rst <= 1'b0;
        @(posedge uart_rx_vif.clk);
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

    task automatic send_uart_frame(
        input bit [7:0] send_data,
        input int       gap_tick_count
    );
        int bit_idx;
        int oversample;

        oversample = 16;

        uart_rx_vif.rx <= 1'b0;
        repeat (oversample) @(posedge uart_rx_vif.baud_tick);

        for (bit_idx = 0; bit_idx < 8; bit_idx++) begin
            uart_rx_vif.rx <= send_data[bit_idx];
            repeat (oversample) @(posedge uart_rx_vif.baud_tick);
        end

        uart_rx_vif.rx <= 1'b1;
        repeat (oversample + (oversample / 2)) @(posedge uart_rx_vif.baud_tick);
        if (gap_tick_count > 0) begin
            repeat (gap_tick_count) @(posedge uart_rx_vif.baud_tick);
        end
        repeat (8) @(posedge uart_rx_vif.clk);
    endtask

    task receive_only(int repeat_count);
        $display("uart_rx random receive test start");
        repeat (repeat_count) begin
            gen2drv_mbox.get(tr);
            send_uart_frame(tr.send_byte, gap_ticks(tr.clk_gap_sel));
            tr.debug_print("DRV");
        end
    endtask
endclass

class uart_rx_monitor;
    uart_rx_item                tr;
    virtual uart_rx_if          uart_rx_vif;
    mailbox #(uart_rx_item)     mon2scb_mbox;

    function new(
        mailbox #(uart_rx_item) mon2scb_mbox,
        virtual uart_rx_if      uart_rx_vif
    );
        this.mon2scb_mbox = mon2scb_mbox;
        this.uart_rx_vif = uart_rx_vif;
    endfunction

    task automatic capture_frame();
        int baud_tick_seen;
        int early_limit;
        int stop_limit;
        int oversample;

        tr         = new();
        oversample = 16;
        early_limit = (oversample / 2) + (8 * oversample);
        stop_limit  = early_limit + (oversample * 2);

        @(negedge uart_rx_vif.rx);
        baud_tick_seen = 0;

        while (baud_tick_seen < early_limit) begin
            @(posedge uart_rx_vif.clk);
            if (uart_rx_vif.rx_done) begin
                tr.early_done_seen = 1'b1;
            end
            if (uart_rx_vif.baud_tick) begin
                baud_tick_seen++;
            end
        end

        while (baud_tick_seen < stop_limit) begin
            @(posedge uart_rx_vif.clk);
            if (uart_rx_vif.rx_done) begin
                tr.done_seen_in_stop = 1'b1;
                tr.done_hits_in_stop++;
                tr.observed_byte = uart_rx_vif.rx_data;
            end
            if (uart_rx_vif.baud_tick) begin
                baud_tick_seen++;
            end
        end

        if (tr.done_seen_in_stop) begin
            tr.done_pulse_cycles = 1;
            @(posedge uart_rx_vif.clk);
            while (uart_rx_vif.rx_done) begin
                tr.done_pulse_cycles++;
                @(posedge uart_rx_vif.clk);
            end
        end

        mon2scb_mbox.put(tr);
        tr.debug_print("MON");
    endtask

    task run(int repeat_count);
        repeat (repeat_count) begin
            capture_frame();
        end
    endtask
endclass

class uart_rx_scoreboard;
    uart_rx_item                exp_tr;
    uart_rx_item                act_tr;
    mailbox #(uart_rx_item)     gen2scb_mbox;
    mailbox #(uart_rx_item)     mon2scb_mbox;
    int                         random_seed;
    int                         total_cnt;
    int                         pass_cnt;
    int                         fail_cnt;
    bit [3:0]                   gap_seen;
    bit                         done;

    function new(
        mailbox #(uart_rx_item) gen2scb_mbox,
        mailbox #(uart_rx_item) mon2scb_mbox,
        input int               random_seed
    );
        this.gen2scb_mbox = gen2scb_mbox;
        this.mon2scb_mbox = mon2scb_mbox;
        this.random_seed = random_seed;
    endfunction

    task run(int repeat_count);
        total_cnt = 0;
        pass_cnt  = 0;
        fail_cnt  = 0;
        gap_seen  = '0;
        done      = 1'b0;

        repeat (repeat_count) begin
            gen2scb_mbox.get(exp_tr);
            mon2scb_mbox.get(act_tr);

            if (act_tr.early_done_seen) begin
                uart_rx_log_fail("TC-RX-001", "rx_done rose before the stop window");
            end
            if (!act_tr.done_seen_in_stop || (act_tr.done_hits_in_stop != 1)) begin
                uart_rx_log_fail("TC-RX-002", "rx_done must appear exactly once in the stop window");
            end
            if (act_tr.done_pulse_cycles != 1) begin
                uart_rx_log_fail("TC-RX-003", "rx_done pulse width must stay 1 cycle");
            end
            if (act_tr.observed_byte != exp_tr.send_byte) begin
                uart_rx_log_fail(
                    "TC-RX-004",
                    $sformatf("data mismatch: expected=%02h got=%02h", exp_tr.send_byte, act_tr.observed_byte)
                );
            end

            gap_seen[exp_tr.clk_gap_sel] = 1'b1;
            pass_cnt++;
            total_cnt++;
        end

        if (gap_seen != 4'b1111) begin
            uart_rx_log_fail("TC-RX-005", "random test must observe clk_gap_sel 0,1,2,3");
        end

        uart_rx_log_pass("TC-RX-001", $sformatf("no early rx_done across %0d random frames", repeat_count));
        uart_rx_log_pass("TC-RX-002", "rx_done appeared exactly once in the stop window");
        uart_rx_log_pass("TC-RX-003", "rx_done pulse width stayed 1 cycle");
        uart_rx_log_pass("TC-RX-004", $sformatf("random frames matched %0d 8-bit bytes", repeat_count));
        uart_rx_log_pass("TC-RX-005", $sformatf("clk_gap_sel 0,1,2,3 all observed with repeat=%0d seed=%08x", repeat_count, random_seed));
        uart_rx_log_pass("tb_uart_rx", "completed");
        done = 1'b1;
    endtask
endclass

class uart_rx_environment;
    uart_rx_generator              gen;
    uart_rx_driver                 drv;
    uart_rx_monitor                mon;
    uart_rx_scoreboard             scb;
    virtual uart_rx_if             uart_rx_vif;

    mailbox #(uart_rx_item) gen2drv_mbox;
    mailbox #(uart_rx_item) gen2scb_mbox;
    mailbox #(uart_rx_item) mon2scb_mbox;

    function new(
        virtual uart_rx_if uart_rx_vif,
        input int          random_seed
    );
        gen2drv_mbox = new();
        gen2scb_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen2scb_mbox, random_seed);
        drv = new(gen2drv_mbox, uart_rx_vif);
        mon = new(mon2scb_mbox, uart_rx_vif);
        scb = new(gen2scb_mbox, mon2scb_mbox, random_seed);
        this.uart_rx_vif = uart_rx_vif;
    endfunction

    task run(int repeat_count);
        // driver/monitor/scoreboard는 동시에 돌아야 하고, foreground의 generator가 trial pacing을 맡는다.
        // join_none 뒤 wait(scb.done)을 사용해 scoreboard가 모든 비교를 끝낸 시점을 종료 기준으로 삼는다.
        drv.preset();
        fork
            drv.receive_only(repeat_count);
            mon.run(repeat_count);
            scb.run(repeat_count);
        join_none

        gen.run(repeat_count);
        wait (scb.done);
        disable fork;
    endtask
endclass

module tb_uart_rx;
    localparam int CLK_FREQ_HZ   = 100_000_000;
    localparam int BAUD_HZ       = 9600;
    localparam int OVERSAMPLE    = 16;
    // Scenario: random serial frame을 반복 입력해서 RX 수신과 rx_done timing을 확인
    // 1) 입력 사이 간격 4종을 모두 확인
    // 2) 8개 data bit의 0/1 조합을 충분히 반복
    // gap case miss 상계 4*(3/4)^N 기준으로 N=64면 충분
    // 이에 따라 repeat=64
    // transaction마다 RANDOM_SEED + idx를 사용하여
    // 동일한 seed면 같은 입력 순서를 재현하도록 함
    localparam int RANDOM_REPEAT = 64;
    localparam int RANDOM_SEED   = 32'h0522_52A5;
    localparam int TIMEOUT_NS    = 120_000_000;

    uart_rx_if tb_if ();
    uart_rx_environment env;

    uart_rx dut (
        .clk      (tb_if.clk),
        .rst      (tb_if.rst),
        .baud_tick(tb_if.baud_tick),
        .rx       (tb_if.rx),
        .rx_done  (tb_if.rx_done),
        .rx_data  (tb_if.rx_data)
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
        $display("[tb_uart_rx] FAIL: timeout");
        $finish;
    end

    initial begin
        tb_if.clk = 1'b0;
        tb_if.rst = 1'b0;
        tb_if.rx  = 1'b1;

        env = new(tb_if, RANDOM_SEED);
        env.run(RANDOM_REPEAT);

        #20;
        $finish;
    end
endmodule
