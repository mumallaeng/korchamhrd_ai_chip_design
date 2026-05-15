`timescale 1ns / 1ps

interface uart_fifo_loopback_if;
    logic clk;
    logic rst;
    logic baud_tick;
    logic rx;
    logic tx;
    logic tx_busy;
endinterface

bit loopback_tb_failed = 1'b0;

task automatic loopback_log_fail(input string tag, input string msg);
    if (!loopback_tb_failed) begin
        loopback_tb_failed = 1'b1;
        $display("[%s] FAIL: %s", tag, msg);
    end
    $finish;
endtask

task automatic loopback_log_pass(input string tag, input string msg);
    if (!loopback_tb_failed) begin
        $display("[%s] PASS: %s", tag, msg);
    end
endtask

class top_item;
    // payload_len: 이번 입력 묶음에서 실제로 전송할 byte 개수
    rand int       payload_len;
    // payload0~3: 이번 입력 묶음에 들어가는 실제 byte 데이터
    rand bit [7:0] payload0;
    rand bit [7:0] payload1;
    rand bit [7:0] payload2;
    rand bit [7:0] payload3;
    // byte12_gap_sel: 1번 byte와 2번 byte 사이 간격 선택
    rand bit [1:0] byte12_gap_sel;
    // byte23_gap_sel: 2번 byte와 3번 byte 사이 간격 선택
    rand bit [1:0] byte23_gap_sel;
    // byte34_gap_sel: 3번 byte와 4번 byte 사이 간격 선택
    rand bit [1:0] byte34_gap_sel;

    bit [7:0]      expected_q[$];
    bit [1:0]      byte_gap_sel_q[$];
    bit [7:0]      actual_q[$];
    bit            stop_bit_ok;
    bit            busy_seen;

    constraint rand_c {
        payload_len dist { 1 := 1, 2 := 1, 3 := 1, 4 := 1 };
        payload0 dist { [8'h00:8'hFF] :/ 256 };
        payload1 dist { [8'h00:8'hFF] :/ 256 };
        payload2 dist { [8'h00:8'hFF] :/ 256 };
        payload3 dist { [8'h00:8'hFF] :/ 256 };
        byte12_gap_sel dist { 2'd0 := 1, 2'd1 := 1, 2'd2 := 1, 2'd3 := 1 };
        byte23_gap_sel dist { 2'd0 := 1, 2'd1 := 1, 2'd2 := 1, 2'd3 := 1 };
        byte34_gap_sel dist { 2'd0 := 1, 2'd1 := 1, 2'd2 := 1, 2'd3 := 1 };
    }

    function void build_expected();
        expected_q.delete();
        byte_gap_sel_q.delete();

        expected_q.push_back(payload0);
        if (payload_len >= 2) begin
            expected_q.push_back(payload1);
            byte_gap_sel_q.push_back(byte12_gap_sel);
        end
        if (payload_len >= 3) begin
            expected_q.push_back(payload2);
            byte_gap_sel_q.push_back(byte23_gap_sel);
        end
        if (payload_len >= 4) begin
            expected_q.push_back(payload3);
            byte_gap_sel_q.push_back(byte34_gap_sel);
        end
    endfunction

    function top_item clone_item();
        top_item item;

        item = new();
        item.payload_len = payload_len;
        item.payload0 = payload0;
        item.payload1 = payload1;
        item.payload2 = payload2;
        item.payload3 = payload3;
        item.byte12_gap_sel = byte12_gap_sel;
        item.byte23_gap_sel = byte23_gap_sel;
        item.byte34_gap_sel = byte34_gap_sel;
        item.stop_bit_ok = stop_bit_ok;
        item.busy_seen = busy_seen;

        item.expected_q.delete();
        foreach (expected_q[idx]) begin
            item.expected_q.push_back(expected_q[idx]);
        end
        item.byte_gap_sel_q.delete();
        foreach (byte_gap_sel_q[idx]) begin
            item.byte_gap_sel_q.push_back(byte_gap_sel_q[idx]);
        end
        item.actual_q.delete();
        foreach (actual_q[idx]) begin
            item.actual_q.push_back(actual_q[idx]);
        end
        return item;
    endfunction

    function string payload_string();
        string s;

        s = "";
        foreach (expected_q[idx]) begin
            if (idx > 0) s = {s, ","};
            s = {s, $sformatf("%02h", expected_q[idx])};
        end
        return s;
    endfunction

    function void debug_print(string prefix);
        $display(
            "Time: %0t [%s] len=%0d exp=%s stop=%0b busy=%0b",
            $time,
            prefix,
            payload_len,
            payload_string(),
            stop_bit_ok,
            busy_seen
        );
    endfunction
endclass

class top_generator;
    top_item              tr;
    mailbox #(top_item)   gen2drv_mbox;
    // top monitor는 trial별 payload_len을 알아야 몇 byte까지 한 묶음으로 받을지 결정할 수 있다.
    mailbox #(top_item)   gen2mon_mbox;
    mailbox #(top_item)   gen2scb_mbox;
    // variable-length random trial이 섞여 있으므로 현재 trial 판정이 끝난 뒤 다음 item을 내보내도록 pacing한다.
    event                       event_gen_next;
    int                         random_seed;

    function new(
        mailbox #(top_item) gen2drv_mbox,
        mailbox #(top_item) gen2mon_mbox,
        mailbox #(top_item) gen2scb_mbox,
        event                     event_gen_next,
        input int                 random_seed
    );
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen2mon_mbox = gen2mon_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.event_gen_next = event_gen_next;
        this.random_seed = random_seed;
    endfunction

    task run(int repeat_count);
        for (int idx = 0; idx < repeat_count; idx++) begin
            tr = new();
            tr.srandom(random_seed + idx);
            assert (tr.randomize())
            else $error("tb_uart_fifo_loopback generator randomization failed");
            tr.build_expected();

            gen2drv_mbox.put(tr);
            gen2mon_mbox.put(tr.clone_item());
            gen2scb_mbox.put(tr.clone_item());
            tr.debug_print("GEN");
            @(event_gen_next);
        end
        $display("GEN end task");
    endtask
endclass

class top_driver;
    top_item              tr;
    virtual uart_fifo_loopback_if loopback_vif;
    mailbox #(top_item)   gen2drv_mbox;

    function new(
        mailbox #(top_item) gen2drv_mbox,
        virtual uart_fifo_loopback_if loopback_vif
    );
        this.gen2drv_mbox = gen2drv_mbox;
        this.loopback_vif = loopback_vif;
    endfunction

    task automatic wait_baud_ticks(input int count);
        repeat (count) @(posedge loopback_vif.baud_tick);
    endtask

    task preset();
        loopback_vif.rst <= 1'b1;
        loopback_vif.rx  <= 1'b1;
        repeat (4) @(posedge loopback_vif.clk);
        loopback_vif.rst <= 1'b0;
        @(posedge loopback_vif.clk);
    endtask

    // byte12_gap_sel, byte23_gap_sel, byte34_gap_sel은 0, 8, 16, 32 baud_tick 간격
    function automatic int gap_ticks(input bit [1:0] gap_sel);
        case (gap_sel)
            2'd0: return 0;
            2'd1: return 8;
            2'd2: return 16;
            default: return 32;
        endcase
    endfunction

    task automatic send_uart_byte(
        input bit [7:0] send_data,
        input int       gap_after_ticks
    );
        int bit_idx;

        loopback_vif.rx <= 1'b0;
        repeat (16) @(posedge loopback_vif.baud_tick);

        for (bit_idx = 0; bit_idx < 8; bit_idx++) begin
            loopback_vif.rx <= send_data[bit_idx];
            repeat (16) @(posedge loopback_vif.baud_tick);
        end

        loopback_vif.rx <= 1'b1;
        repeat (16) @(posedge loopback_vif.baud_tick);

        if (gap_after_ticks > 0) begin
            wait_baud_ticks(gap_after_ticks);
        end
    endtask

    task automatic wait_final_idle();
        while (loopback_vif.tx_busy) begin
            @(posedge loopback_vif.clk);
        end
        wait_baud_ticks(16);
    endtask

    task loopback_only(int repeat_count);
        int gap_after_ticks;

        $display("uart_fifo_loopback random loopback test start");
        repeat (repeat_count) begin
            gen2drv_mbox.get(tr);
            for (int idx = 0; idx < tr.expected_q.size(); idx++) begin
                if (idx < tr.byte_gap_sel_q.size()) begin
                    gap_after_ticks = gap_ticks(tr.byte_gap_sel_q[idx]);
                end else begin
                    gap_after_ticks = 0;
                end
                send_uart_byte(tr.expected_q[idx], gap_after_ticks);
            end
            tr.debug_print("DRV");
        end
    endtask
endclass

class top_monitor;
    top_item              tr;
    top_item              exp_tr;
    virtual uart_fifo_loopback_if loopback_vif;
    mailbox #(top_item)   gen2mon_mbox;
    mailbox #(top_item)   mon2scb_mbox;

    function new(
        mailbox #(top_item) gen2mon_mbox,
        mailbox #(top_item) mon2scb_mbox,
        virtual uart_fifo_loopback_if loopback_vif
    );
        this.gen2mon_mbox = gen2mon_mbox;
        this.mon2scb_mbox = mon2scb_mbox;
        this.loopback_vif = loopback_vif;
    endfunction

    task automatic wait_baud_ticks(input int count);
        repeat (count) @(posedge loopback_vif.baud_tick);
    endtask

    task automatic receive_uart_byte(
        output bit [7:0] recv_data,
        output bit       stop_ok
    );
        int bit_idx;

        recv_data      = '0;
        stop_ok        = 1'b0;

        @(negedge loopback_vif.tx);
        wait_baud_ticks(24);

        for (bit_idx = 0; bit_idx < 8; bit_idx++) begin
            recv_data[bit_idx] = loopback_vif.tx;
            wait_baud_ticks(16);
        end

        stop_ok = (loopback_vif.tx === 1'b1);
    endtask

    task automatic capture_trial(input int payload_len);
        bit [7:0] recv_data;
        bit       recv_stop_ok;
        bit       frame_done;

        tr = new();
        tr.actual_q.delete();
        tr.stop_bit_ok = 1'b1;
        frame_done = 1'b0;

        // payload 수집과 tx_busy 관찰이 모두 끝나야 한 trial 결과가 완성되므로 plain join으로 묶는다.
        fork
            begin : capture_frames
                for (int idx = 0; idx < payload_len; idx++) begin
                    receive_uart_byte(recv_data, recv_stop_ok);
                    tr.actual_q.push_back(recv_data);
                    tr.stop_bit_ok &= recv_stop_ok;
                end
                frame_done = 1'b1;
            end
            begin : watch_busy
                while (!frame_done || loopback_vif.tx_busy) begin
                    @(posedge loopback_vif.clk);
                    if (loopback_vif.tx_busy) begin
                        tr.busy_seen = 1'b1;
                    end
                end
            end
        join

        mon2scb_mbox.put(tr);
        tr.debug_print("MON");
    endtask

    task run(int repeat_count);
        repeat (repeat_count) begin
            gen2mon_mbox.get(exp_tr);
            capture_trial(exp_tr.payload_len);
        end
    endtask
endclass

class top_scoreboard;
    top_item              exp_tr;
    top_item              act_tr;
    mailbox #(top_item)   gen2scb_mbox;
    mailbox #(top_item)   mon2scb_mbox;
    event                       event_gen_next;
    int                         random_seed;
    bit [3:0]                   len_seen;
    bit [3:0]                   byte12_gap_seen;
    bit [3:0]                   byte23_gap_seen;
    bit [3:0]                   byte34_gap_seen;
    bit                         done;

    function new(
        mailbox #(top_item) gen2scb_mbox,
        mailbox #(top_item) mon2scb_mbox,
        event                     event_gen_next,
        input int                 random_seed
    );
        this.gen2scb_mbox = gen2scb_mbox;
        this.mon2scb_mbox = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
        this.random_seed = random_seed;
    endfunction

    task run(int repeat_count);
        len_seen = '0;
        byte12_gap_seen = '0;
        byte23_gap_seen = '0;
        byte34_gap_seen = '0;
        done = 1'b0;

        repeat (repeat_count) begin
            gen2scb_mbox.get(exp_tr);
            mon2scb_mbox.get(act_tr);

            if (act_tr.actual_q.size() != exp_tr.expected_q.size()) begin
                loopback_log_fail(
                    "TC-LOOP-001",
                    $sformatf("payload size mismatch: expected=%0d got=%0d", exp_tr.expected_q.size(), act_tr.actual_q.size())
                );
            end
            foreach (exp_tr.expected_q[idx]) begin
                if (act_tr.actual_q[idx] != exp_tr.expected_q[idx]) begin
                    loopback_log_fail(
                        "TC-LOOP-001",
                        $sformatf("ordering/data mismatch at idx=%0d: expected=%02h got=%02h", idx, exp_tr.expected_q[idx], act_tr.actual_q[idx])
                    );
                end
            end
            if (!act_tr.stop_bit_ok) begin
                loopback_log_fail("TC-LOOP-002", "stop bit must stay high");
            end
            if (!act_tr.busy_seen) begin
                loopback_log_fail("TC-LOOP-003", "tx_busy must be observed for every trial");
            end

            len_seen[exp_tr.payload_len-1] = 1'b1;
            if (exp_tr.payload_len >= 2) begin
                byte12_gap_seen[exp_tr.byte12_gap_sel] = 1'b1;
            end
            if (exp_tr.payload_len >= 3) begin
                byte23_gap_seen[exp_tr.byte23_gap_sel] = 1'b1;
            end
            if (exp_tr.payload_len >= 4) begin
                byte34_gap_seen[exp_tr.byte34_gap_sel] = 1'b1;
            end
            ->event_gen_next;
        end

        if (len_seen != 4'b1111) begin
            loopback_log_fail("TC-LOOP-004", "payload_len 1,2,3,4 must all be observed");
        end
        if ((byte12_gap_seen != 4'b1111) || (byte23_gap_seen != 4'b1111) || (byte34_gap_seen != 4'b1111)) begin
            loopback_log_fail("TC-LOOP-005", "1->2, 2->3, 3->4 byte gap must each observe 0,1,2,3");
        end

        loopback_log_pass("TC-LOOP-001", $sformatf("ordering matched %0d end-to-end random trials", repeat_count));
        loopback_log_pass("TC-LOOP-002", "stop bit stayed high across all random trials");
        loopback_log_pass("TC-LOOP-003", "tx_busy observed for every end-to-end trial");
        loopback_log_pass("TC-LOOP-004", "payload_len 1,2,3,4 all observed");
        loopback_log_pass("TC-LOOP-005", $sformatf("1->2, 2->3, 3->4 byte gap all observed with repeat=%0d seed=%08x", repeat_count, random_seed));
        done = 1'b1;
    endtask
endclass

class top_environment;
    top_generator            gen;
    top_driver               drv;
    top_monitor              mon;
    top_scoreboard           scb;
    virtual uart_fifo_loopback_if  loopback_vif;

    mailbox #(top_item) gen2drv_mbox;
    mailbox #(top_item) gen2mon_mbox;
    mailbox #(top_item) gen2scb_mbox;
    mailbox #(top_item) mon2scb_mbox;
    event                            event_gen_next;

    function new(
        virtual uart_fifo_loopback_if loopback_vif,
        input int                     random_seed
    );
        gen2drv_mbox = new();
        gen2mon_mbox = new();
        gen2scb_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen2mon_mbox, gen2scb_mbox, event_gen_next, random_seed);
        drv = new(gen2drv_mbox, loopback_vif);
        mon = new(gen2mon_mbox, mon2scb_mbox, loopback_vif);
        scb = new(gen2scb_mbox, mon2scb_mbox, event_gen_next, random_seed);
        this.loopback_vif = loopback_vif;
    endfunction

    task run(int repeat_count);
        // driver/monitor/scoreboard는 background에서 병렬로 두고, generator가 foreground에서 trial pacing을 맡는다.
        // wait(scb.done)은 PASS/FAIL 판정이 모두 끝난 뒤에만 종료하도록 하기 위한 명시적 완료 조건이다.
        drv.preset();

        fork
            drv.loopback_only(repeat_count);
            mon.run(repeat_count);
            scb.run(repeat_count);
        join_none

        gen.run(repeat_count);
        wait (scb.done);
        disable fork;

        drv.wait_final_idle();
        if ((loopback_vif.tx !== 1'b1) || (loopback_vif.tx_busy !== 1'b0)) begin
            loopback_log_fail("TC-LOOP-006", "final idle restore must end at tx=1 and tx_busy=0");
        end
        loopback_log_pass("TC-LOOP-006", "final idle restore ended at tx=1 and tx_busy=0");
        loopback_log_pass("tb_uart_fifo_loopback", "completed");
    endtask
endclass

module tb_uart_fifo_loopback;
    localparam int CLK_FREQ_HZ   = 100_000_000;
    localparam int BAUD_HZ       = 9600;
    // Scenario: random 1~4 byte 묶음을 입력해서 RX->FIFO->TX 전체 경로를 확인
    // 1) 1, 2, 3, 4 byte 입력 묶음을 모두 확인
    // 2) 1->2, 2->3, 3->4 byte gap 4종을 모두 확인
    // 가장 드문 제어 경우 miss 상계 4*(15/16)^N 기준으로 N=256이면 충분
    // 이에 따라 repeat=256
    // transaction마다 RANDOM_SEED + idx를 사용하여
    // 동일한 seed면 같은 입력 묶음을 재현하도록 함
    // gap은 0, 8, 16, 32 baud_tick
    localparam int RANDOM_REPEAT = 256;
    localparam int RANDOM_SEED   = 32'h0522_C0DE;
    localparam int TIMEOUT_NS    = 1_200_000_000;

    uart_fifo_loopback_if tb_if ();
    top_environment env;

    uart_fifo_loopback #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_HZ    (BAUD_HZ)
    ) dut (
        .clk    (tb_if.clk),
        .rst    (tb_if.rst),
        .rx     (tb_if.rx),
        .tx     (tb_if.tx),
        .tx_busy(tb_if.tx_busy)
    );

    assign tb_if.baud_tick = dut.w_baud_tick;

    always #5 tb_if.clk = ~tb_if.clk;

    initial begin
        #TIMEOUT_NS;
        $display("[tb_uart_fifo_loopback] FAIL: timeout");
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
