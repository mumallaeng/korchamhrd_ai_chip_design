`timescale 1ns / 1ps

interface fifo_if;
    logic       clk;
    logic       rst;
    logic [7:0] push_data;
    logic       push;
    logic       pop;
    logic [7:0] pop_data;
    logic       empty;
    logic       full;
endinterface

typedef enum logic [1:0] {
    FIFO_RESET,
    FIFO_PUSH_ONLY,
    FIFO_POP_ONLY,
    FIFO_PUSH_POP
} fifo_op_kind_t;

bit fifo_tb_failed = 1'b0;

task automatic fifo_log_fail(input string tag, input string msg);
    if (!fifo_tb_failed) begin
        fifo_tb_failed = 1'b1;
        $display("[%s] FAIL: %s", tag, msg);
    end
    $finish;
endtask

task automatic fifo_log_pass(input string tag, input string msg);
    if (!fifo_tb_failed) begin
        $display("[%s] PASS: %s", tag, msg);
    end
endtask

class fifo_item;
    string         tc_id;
    fifo_op_kind_t op_kind;
    int            step_idx;
    bit            push;
    bit            pop;
    bit [7:0]      push_data;
    int            pre_level;
    bit            pre_empty;
    bit            pre_full;
    bit            exp_full;
    bit            exp_empty;
    bit [7:0]      exp_pop_data;
    bit            check_pop_data;
    int            exp_level;

    function fifo_item clone_item();
        fifo_item item;

        item                = new();
        item.tc_id          = tc_id;
        item.op_kind        = op_kind;
        item.step_idx       = step_idx;
        item.push           = push;
        item.pop            = pop;
        item.push_data      = push_data;
        item.pre_level      = pre_level;
        item.pre_empty      = pre_empty;
        item.pre_full       = pre_full;
        item.exp_full       = exp_full;
        item.exp_empty      = exp_empty;
        item.exp_pop_data   = exp_pop_data;
        item.check_pop_data = check_pop_data;
        item.exp_level      = exp_level;
        return item;
    endfunction
endclass

class fifo_mon_item;
    bit            push;
    bit            pop;
    bit [7:0]      push_data;
    bit            full;
    bit            empty;
    bit [7:0]      pop_data;
endclass

class fifo_generator;
    mailbox #(fifo_item)  gen2drv_mbox;
    mailbox #(fifo_item)  gen2scb_mbox;
    int                   depth;
    int                   push_only_repeat;
    int                   push_pop_full_repeat;
    int                   pop_only_repeat;
    int                   push_pop_empty_repeat;
    int                   refill_repeat;
    int                   push_pop_mid_repeat;
    int                   final_pop_repeat;
    function new(
        mailbox #(fifo_item) gen2drv_mbox,
        mailbox #(fifo_item) gen2scb_mbox,
        input int            depth,
        input int            push_only_repeat,
        input int            push_pop_full_repeat,
        input int            pop_only_repeat,
        input int            push_pop_empty_repeat,
        input int            refill_repeat,
        input int            push_pop_mid_repeat,
        input int            final_pop_repeat
    );
        this.gen2drv_mbox          = gen2drv_mbox;
        this.gen2scb_mbox          = gen2scb_mbox;
        this.depth                 = depth;
        this.push_only_repeat      = push_only_repeat;
        this.push_pop_full_repeat  = push_pop_full_repeat;
        this.pop_only_repeat       = pop_only_repeat;
        this.push_pop_empty_repeat = push_pop_empty_repeat;
        this.refill_repeat         = refill_repeat;
        this.push_pop_mid_repeat   = push_pop_mid_repeat;
        this.final_pop_repeat      = final_pop_repeat;
    endfunction

    function automatic void fill_expected(ref fifo_item item, ref bit [7:0] model_q[$]);
        item.exp_level      = model_q.size();
        item.exp_empty      = (model_q.size() == 0);
        item.exp_full       = (model_q.size() == depth);
        item.check_pop_data = (model_q.size() > 0);
        item.exp_pop_data   = item.check_pop_data ? model_q[0] : 8'h00;
    endfunction

    task automatic emit_item(input fifo_item item);
        gen2drv_mbox.put(item.clone_item());
        gen2scb_mbox.put(item.clone_item());
    endtask

    task automatic make_push_only_step(
        ref bit [7:0] model_q[$],
        ref int       step_idx
    );
        fifo_item item;

        item              = new();
        item.tc_id        = "TC-FIFO-002";
        item.op_kind      = FIFO_PUSH_ONLY;
        item.step_idx     = step_idx;
        item.push         = 1'b1;
        item.pop          = 1'b0;
        item.pre_level    = model_q.size();
        item.pre_empty    = (model_q.size() == 0);
        item.pre_full     = (model_q.size() == depth);
        item.push_data    = 8'h20 + $urandom_range(0, 94);

        if (model_q.size() < depth) begin
            model_q.push_back(item.push_data);
        end

        fill_expected(item, model_q);
        emit_item(item);
        step_idx++;
    endtask

    task automatic make_pop_only_step(
        ref bit [7:0] model_q[$],
        ref int       step_idx
    );
        fifo_item item;

        item              = new();
        item.tc_id        = "TC-FIFO-003";
        item.op_kind      = FIFO_POP_ONLY;
        item.step_idx     = step_idx;
        item.push         = 1'b0;
        item.pop          = 1'b1;
        item.push_data    = 8'h00;
        item.pre_level    = model_q.size();
        item.pre_empty    = (model_q.size() == 0);
        item.pre_full     = (model_q.size() == depth);

        if (model_q.size() > 0) begin
            void'(model_q.pop_front());
        end

        fill_expected(item, model_q);
        emit_item(item);
        step_idx++;
    endtask

    task automatic make_push_pop_step(
        ref bit [7:0] model_q[$],
        ref int       step_idx
    );
        fifo_item item;

        item              = new();
        item.tc_id        = "TC-FIFO-004";
        item.op_kind      = FIFO_PUSH_POP;
        item.step_idx     = step_idx;
        item.push         = 1'b1;
        item.pop          = 1'b1;
        item.pre_level    = model_q.size();
        item.pre_empty    = (model_q.size() == 0);
        item.pre_full     = (model_q.size() == depth);
        item.push_data    = 8'h20 + $urandom_range(0, 94);

        if (model_q.size() == depth) begin
            void'(model_q.pop_front());
        end else if (model_q.size() == 0) begin
            model_q.push_back(item.push_data);
        end else begin
            void'(model_q.pop_front());
            model_q.push_back(item.push_data);
        end

        fill_expected(item, model_q);
        emit_item(item);
        step_idx++;
    endtask

    task run();
        fifo_item       item;
        bit [7:0]       model_q[$];
        int             step_idx;

        model_q.delete();
        step_idx = 1;

        item                = new();
        item.tc_id          = "TC-FIFO-001";
        item.op_kind        = FIFO_RESET;
        item.step_idx       = 0;
        item.push           = 1'b0;
        item.pop            = 1'b0;
        item.push_data      = 8'h00;
        item.pre_level      = 0;
        item.pre_empty      = 1'b1;
        item.pre_full       = 1'b0;
        item.exp_full       = 1'b0;
        item.exp_empty      = 1'b1;
        item.exp_pop_data   = 8'h00;
        item.check_pop_data = 1'b0;
        item.exp_level      = 0;
        emit_item(item);

        repeat (push_only_repeat) begin
            make_push_only_step(model_q, step_idx);
        end

        repeat (push_pop_full_repeat) begin
            make_push_pop_step(model_q, step_idx);
        end

        repeat (pop_only_repeat) begin
            make_pop_only_step(model_q, step_idx);
        end

        repeat (push_pop_empty_repeat) begin
            make_push_pop_step(model_q, step_idx);
        end

        repeat (refill_repeat) begin
            make_push_only_step(model_q, step_idx);
        end

        repeat (push_pop_mid_repeat) begin
            make_push_pop_step(model_q, step_idx);
        end

        repeat (final_pop_repeat) begin
            make_pop_only_step(model_q, step_idx);
        end
    endtask
endclass

class fifo_driver;
    virtual fifo_if       vif;
    mailbox #(fifo_item)  gen2drv_mbox;
    // FIFO는 같은 cycle의 DUT 갱신 직후를 샘플링해야 하므로 monitor와의 barrier를 event로 둔다.
    event                 event_mon_next;

    function new(
        virtual fifo_if      vif,
        mailbox #(fifo_item) gen2drv_mbox,
        event                event_mon_next
    );
        this.vif = vif;
        this.gen2drv_mbox = gen2drv_mbox;
        this.event_mon_next = event_mon_next;
    endfunction

    task automatic drive_reset();
        vif.push      <= 1'b0;
        vif.pop       <= 1'b0;
        vif.push_data <= '0;
        vif.rst       <= 1'b1;

        repeat (2) @(posedge vif.clk);

        vif.rst <= 1'b0;
        @(posedge vif.clk);
        #1ps;
        ->event_mon_next;
    endtask

    task automatic drive_step(input fifo_item item);
        @(negedge vif.clk);
        vif.push_data <= item.push_data;
        vif.push      <= item.push;
        vif.pop       <= item.pop;

        @(posedge vif.clk);
        #1ps;
        ->event_mon_next;

        @(negedge vif.clk);
        vif.push <= 1'b0;
        vif.pop  <= 1'b0;
    endtask

    task run();
        fifo_item item;

        forever begin
            gen2drv_mbox.get(item);
            unique case (item.op_kind)
                FIFO_RESET: drive_reset();
                FIFO_PUSH_ONLY,
                FIFO_POP_ONLY,
                FIFO_PUSH_POP: drive_step(item);
                default: fifo_log_fail("tb_fifo", "unsupported FIFO operation");
            endcase
        end
    endtask
endclass

class fifo_monitor;
    virtual fifo_if          vif;
    mailbox #(fifo_mon_item) mon2scb_mbox;
    event                    event_mon_next;

    function new(
        virtual fifo_if          vif,
        mailbox #(fifo_mon_item) mon2scb_mbox,
        event                    event_mon_next
    );
        this.vif = vif;
        this.mon2scb_mbox = mon2scb_mbox;
        this.event_mon_next = event_mon_next;
    endfunction

    task run();
        fifo_mon_item item;

        forever begin
            @(event_mon_next);
            item           = new();
            item.push      = vif.push;
            item.pop       = vif.pop;
            item.push_data = vif.push_data;
            item.full      = vif.full;
            item.empty     = vif.empty;
            item.pop_data  = vif.pop_data;
            mon2scb_mbox.put(item);
        end
    endtask
endclass

class fifo_scoreboard;
    mailbox #(fifo_item)      gen2scb_mbox;
    mailbox #(fifo_mon_item)  mon2scb_mbox;
    int                       depth;
    int                       total_steps;
    bit                       done;

    function new(
        mailbox #(fifo_item)      gen2scb_mbox,
        mailbox #(fifo_mon_item)  mon2scb_mbox,
        input int                 depth,
        input int                 total_steps
    );
        this.gen2scb_mbox = gen2scb_mbox;
        this.mon2scb_mbox = mon2scb_mbox;
        this.depth = depth;
        this.total_steps = total_steps;
        done = 1'b0;
    endfunction

    task automatic check_drive(
        input fifo_item     exp,
        input fifo_mon_item act
    );
        if (act.push !== exp.push) begin
            fifo_log_fail(exp.tc_id, $sformatf("step=%0d push mismatch: expected=%0b got=%0b", exp.step_idx, exp.push, act.push));
        end

        if (act.pop !== exp.pop) begin
            fifo_log_fail(exp.tc_id, $sformatf("step=%0d pop mismatch: expected=%0b got=%0b", exp.step_idx, exp.pop, act.pop));
        end

        if (act.push_data !== exp.push_data) begin
            fifo_log_fail(exp.tc_id, $sformatf("step=%0d push_data mismatch: expected=%02h got=%02h", exp.step_idx, exp.push_data, act.push_data));
        end
    endtask

    task automatic check_state(
        input fifo_item     exp,
        input fifo_mon_item act
    );
        if (act.full !== exp.exp_full) begin
            fifo_log_fail(exp.tc_id, $sformatf("step=%0d full mismatch: expected=%0b got=%0b", exp.step_idx, exp.exp_full, act.full));
        end

        if (act.empty !== exp.exp_empty) begin
            fifo_log_fail(exp.tc_id, $sformatf("step=%0d empty mismatch: expected=%0b got=%0b", exp.step_idx, exp.exp_empty, act.empty));
        end

        if (exp.check_pop_data && (act.pop_data !== exp.exp_pop_data)) begin
            fifo_log_fail(exp.tc_id, $sformatf("step=%0d pop_data mismatch: expected=%02h got=%02h", exp.step_idx, exp.exp_pop_data, act.pop_data));
        end
    endtask

    task run();
        fifo_item      exp;
        fifo_mon_item  act;
        int            step_count;
        bit            push_full_seen;
        bit            push_overflow_seen;
        bit            pop_empty_seen;
        bit            pop_underflow_seen;
        bit            push_pop_full_seen;
        bit            push_pop_empty_seen;
        bit            push_pop_mid_seen;

        step_count          = 0;
        push_full_seen      = 1'b0;
        push_overflow_seen  = 1'b0;
        pop_empty_seen      = 1'b0;
        pop_underflow_seen  = 1'b0;
        push_pop_full_seen  = 1'b0;
        push_pop_empty_seen = 1'b0;
        push_pop_mid_seen   = 1'b0;
        done                = 1'b0;

        repeat (total_steps) begin
            gen2scb_mbox.get(exp);
            mon2scb_mbox.get(act);

            check_drive(exp, act);
            check_state(exp, act);

            if (exp.op_kind == FIFO_RESET) begin
                fifo_log_pass("TC-FIFO-001", "reset flags");
            end else begin
                if ((exp.op_kind == FIFO_PUSH_ONLY) && (exp.pre_level == depth - 1) &&
                    act.full && !act.empty) begin
                    push_full_seen = 1'b1;
                end

                if ((exp.op_kind == FIFO_PUSH_ONLY) && exp.pre_full &&
                    act.full && !act.empty) begin
                    push_overflow_seen = 1'b1;
                end

                if ((exp.op_kind == FIFO_POP_ONLY) && (exp.pre_level == 1) &&
                    act.empty && !act.full) begin
                    pop_empty_seen = 1'b1;
                end

                if ((exp.op_kind == FIFO_POP_ONLY) && exp.pre_empty &&
                    act.empty && !act.full) begin
                    pop_underflow_seen = 1'b1;
                end

                if ((exp.op_kind == FIFO_PUSH_POP) && exp.pre_full &&
                    !act.full && !act.empty && (exp.exp_level == depth - 1)) begin
                    push_pop_full_seen = 1'b1;
                end

                if ((exp.op_kind == FIFO_PUSH_POP) && exp.pre_empty &&
                    !act.empty && !act.full && (exp.exp_level == 1)) begin
                    push_pop_empty_seen = 1'b1;
                end

                if ((exp.op_kind == FIFO_PUSH_POP) && !exp.pre_empty && !exp.pre_full &&
                    (exp.exp_level == exp.pre_level)) begin
                    push_pop_mid_seen = 1'b1;
                end
            end

            step_count++;
        end

        if (!(push_full_seen && push_overflow_seen)) begin
            fifo_log_fail("TC-FIFO-002", "push_only path must cover full entry and overflow protection");
        end

        if (!(pop_empty_seen && pop_underflow_seen)) begin
            fifo_log_fail("TC-FIFO-003", "pop_only path must cover empty entry and underflow protection");
        end

        if (!(push_pop_full_seen && push_pop_empty_seen && push_pop_mid_seen)) begin
            fifo_log_fail("TC-FIFO-004", "push_pop path must cover full, empty, and middle occupancy cases");
        end

        if (step_count != total_steps) begin
            fifo_log_fail("TC-FIFO-005", $sformatf("step count mismatch: expected=%0d got=%0d", total_steps, step_count));
        end

        done = 1'b1;
        fifo_log_pass("TC-FIFO-002", "push_only covered full entry and overflow protection");
        fifo_log_pass("TC-FIFO-003", "pop_only covered empty entry and underflow protection");
        fifo_log_pass("TC-FIFO-004", "push_pop covered full, empty, and middle occupancy cases");
        fifo_log_pass("TC-FIFO-005", $sformatf("total_steps=%0d", total_steps));
        fifo_log_pass("tb_fifo", "completed");
    endtask
endclass

class fifo_environment;
    fifo_generator           gen;
    fifo_driver              drv;
    fifo_monitor             mon;
    fifo_scoreboard          scb;
    mailbox #(fifo_item)     gen2drv_mbox;
    mailbox #(fifo_item)     gen2scb_mbox;
    mailbox #(fifo_mon_item) mon2scb_mbox;
    event                    event_mon_next;

    function new(
        virtual fifo_if      vif,
        input int            depth,
        input int            push_only_repeat,
        input int            push_pop_full_repeat,
        input int            pop_only_repeat,
        input int            push_pop_empty_repeat,
        input int            refill_repeat,
        input int            push_pop_mid_repeat,
        input int            final_pop_repeat,
        input int            total_steps
    );
        gen2drv_mbox = new();
        gen2scb_mbox = new();
        mon2scb_mbox = new();
        gen = new(
            gen2drv_mbox,
            gen2scb_mbox,
            depth,
            push_only_repeat,
            push_pop_full_repeat,
            pop_only_repeat,
            push_pop_empty_repeat,
            refill_repeat,
            push_pop_mid_repeat,
            final_pop_repeat
        );
        drv = new(vif, gen2drv_mbox, event_mon_next);
        mon = new(vif, mon2scb_mbox, event_mon_next);
        scb = new(gen2scb_mbox, mon2scb_mbox, depth, total_steps);
    endfunction

    task run();
        // driver/monitor는 background worker처럼 계속 살아 있어야 하므로 join_none으로 띄운다.
        // 완료 판정은 scoreboard 하나가 맡고, done 이후 disable fork로 worker thread를 정리한다.
        fork
            drv.run();
            mon.run();
            scb.run();
        join_none

        gen.run();
        wait (scb.done);
        disable fork;
    endtask
endclass

module tb_fifo;

    localparam int DEPTH                 = 16;
    localparam int HALF_DEPTH            = DEPTH / 2;
    // Scenario 1: push_only로 full과 overflow 보호를 확인
    // 이에 따라 repeat=DEPTH + 1
    localparam int PUSH_ONLY_REPEAT      = DEPTH + 1;
    // Scenario 2: full 상태에서 push_pop이면 pop만 처리되는지 확인
    localparam int PUSH_POP_FULL_REPEAT  = 1;
    // Scenario 3: pop_only로 empty와 underflow 보호를 확인
    // push_pop full 1회 뒤 level=DEPTH - 1이 되므로 repeat=DEPTH
    localparam int POP_ONLY_REPEAT       = DEPTH;
    // Scenario 4: empty 상태에서 push_pop이면 push만 처리되는지 확인
    localparam int PUSH_POP_EMPTY_REPEAT = 1;
    // Scenario 5: middle level push_pop 구간을 만들기 위해 half depth까지 다시 채움
    localparam int REFILL_REPEAT         = HALF_DEPTH - 1;
    // Scenario 6: middle level에서는 push_pop이 level을 유지하는지 확인
    localparam int PUSH_POP_MID_REPEAT   = DEPTH;
    // Scenario 7: 마지막에 다시 empty와 underflow까지 확인
    localparam int FINAL_POP_REPEAT      = HALF_DEPTH + 1;
    // push_data만 random
    // explicit seed 없이 simulator 기본 random 흐름을 사용
    localparam int TOTAL_STEPS           =
        1 +
        PUSH_ONLY_REPEAT +
        PUSH_POP_FULL_REPEAT +
        POP_ONLY_REPEAT +
        PUSH_POP_EMPTY_REPEAT +
        REFILL_REPEAT +
        PUSH_POP_MID_REPEAT +
        FINAL_POP_REPEAT;
    localparam int TIMEOUT_NS            = 200_000;

    fifo_if tb_if ();
    fifo_environment env;

    fifo #(
        .DEPTH(DEPTH)
    ) dut (
        .clk      (tb_if.clk),
        .rst      (tb_if.rst),
        .push_data(tb_if.push_data),
        .push     (tb_if.push),
        .pop      (tb_if.pop),
        .pop_data (tb_if.pop_data),
        .empty    (tb_if.empty),
        .full     (tb_if.full)
    );

    always #5 tb_if.clk = ~tb_if.clk;

    initial begin
        #TIMEOUT_NS;
        $display("[tb_fifo] FAIL: timeout");
        $finish;
    end

    initial begin
        tb_if.clk       = 1'b0;
        tb_if.rst       = 1'b0;
        tb_if.push_data = '0;
        tb_if.push      = 1'b0;
        tb_if.pop       = 1'b0;

        env = new(
            tb_if,
            DEPTH,
            PUSH_ONLY_REPEAT,
            PUSH_POP_FULL_REPEAT,
            POP_ONLY_REPEAT,
            PUSH_POP_EMPTY_REPEAT,
            REFILL_REPEAT,
            PUSH_POP_MID_REPEAT,
            FINAL_POP_REPEAT,
            TOTAL_STEPS
        );
        env.run();

        #20;
        $finish;
    end

endmodule
