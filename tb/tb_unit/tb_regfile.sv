`timescale 1ns/1ps

import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;

interface regfile_if(input logic clk);

    logic rst_n;
    logic [REG_ADDR_W-1:0] rs1_addr;
    logic [REG_ADDR_W-1:0] rs2_addr;
    regfile_wb wb;

    logic [XLEN-1:0] rs1_data;
    logic [XLEN-1:0] rs2_data;

    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output rst_n, rs1_addr, rs2_addr, wb;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #1;
        input rst_n, rs1_addr, rs2_addr, wb, rs1_data, rs2_data;
    endclocking

    modport DRV (clocking drv_cb, input clk);
    modport MON (clocking mon_cb, input clk);
endinterface


class regfile_transaction;

    rand bit rst_n;
    rand bit [REG_ADDR_W-1:0] rs1_addr;
    rand bit [REG_ADDR_W-1:0] rs2_addr;
    rand regfile_wb wb;

    bit [XLEN-1:0] rs1_data;
    bit [XLEN-1:0] rs2_data;

    bit [XLEN-1:0] expected_rs1_data;
    bit [XLEN-1:0] expected_rs2_data;

    function void copy(regfile_transaction rhs);
        if (rhs == null)
            return;

        rst_n = rhs.rst_n;
        rs1_addr = rhs.rs1_addr;
        rs2_addr = rhs.rs2_addr;
        wb = rhs.wb;
        rs1_data = rhs.rs1_data;
        rs2_data = rhs.rs2_data;
        expected_rs1_data = rhs.expected_rs1_data;
        expected_rs2_data = rhs.expected_rs2_data;
    endfunction

    function regfile_transaction clone();
        regfile_transaction t = new();
        t.copy(this);
        return t;
    endfunction

    function string convert2string();
        return $sformatf(
            "rst_n=%0b rs1=x%0d rs2=x%0d reg_en=%0b rd=x%0d rd_data=%08h rs1_data=%08h rs2_data=%08h",
            rst_n, rs1_addr, rs2_addr,
            wb.reg_en, wb.rd_addr, wb.rd_data,
            rs1_data, rs2_data
        );
    endfunction

endclass


class regfile_generator;

    mailbox #(regfile_transaction) gen2drv;

    function new(mailbox #(regfile_transaction) gen2drv);
        this.gen2drv = gen2drv;
    endfunction

    // task send_random();
    //     regfile_transaction txn = new();

    //     if (!txn.randomize())
    //         $error("[GEN][ERROR] Randomization failed");
    //     else
    //         gen2drv.put(txn);
    // endtask

    task send_random();
    regfile_transaction txn = new();
    void'(txn.randomize());
    gen2drv.put(txn);

endtask
    task run();
        repeat (1000)
            send_random();
    endtask
endclass


class regfile_driver;

    virtual regfile_if.DRV vif;
    mailbox #(regfile_transaction) gen2drv;

    function new(
        virtual regfile_if.DRV vif,
        mailbox #(regfile_transaction) gen2drv
    );
        this.vif = vif;
        this.gen2drv = gen2drv;
    endfunction

    task reset_dut();
        vif.drv_cb.rst_n <= 1'b0;
        vif.drv_cb.rs1_addr <= '0;
        vif.drv_cb.rs2_addr <= '0;
        vif.drv_cb.wb.reg_en <= 1'b0;
        vif.drv_cb.wb.rd_addr <= '0;
        vif.drv_cb.wb.rd_data <= '0;

        repeat (3)
            @(vif.drv_cb);

        vif.drv_cb.rst_n <= 1'b1;

    endtask

    task run();

        regfile_transaction txn;

        forever begin
            gen2drv.get(txn);

            @(vif.drv_cb);

            vif.drv_cb.rst_n <= txn.rst_n;
            vif.drv_cb.rs1_addr <= txn.rs1_addr;
            vif.drv_cb.rs2_addr <= txn.rs2_addr;
            vif.drv_cb.wb <= txn.wb;
        end
    endtask
endclass


class regfile_ref_model;

    logic [XLEN-1:0] model_reg [0:31];

    function new();
        reset();
    endfunction

    function void reset();
        for (int i = 0; i < 32; i++)
            model_reg[i] = '0;
    endfunction

    // function void predict(
    //     input regfile_transaction txn,
    //     output logic [XLEN-1:0] exp_rs1_data,
    //     output logic [XLEN-1:0] exp_rs2_data
    // );
    //     if (!txn.rst_n) begin
    //         reset();
    //     end
    //     else if (txn.wb.reg_en && (txn.wb.rd_addr != '0)) begin
    //         model_reg[txn.wb.rd_addr] = txn.wb.rd_data;
    //     end

    //     model_reg[0] = '0;
    //     if (txn.rs1_addr == '0)
    //         exp_rs1_data = '0;
    //     else
    //         exp_rs1_data = model_reg[txn.rs1_addr];
    //     if (txn.rs2_addr == '0)
    //         exp_rs2_data = '0;
    //     else
    //         exp_rs2_data = model_reg[txn.rs2_addr];
    // endfunction


            function void predict(
            input  regfile_transaction txn,
            output logic [XLEN-1:0] exp_rs1_data,
            output logic [XLEN-1:0] exp_rs2_data
        );
            if (!txn.rst_n) begin
                reset();
            end

            // ĐỌC TRƯỚC — dùng model_reg còn nguyên giá trị cũ (giống always_comb của DUT
            // đọc mem_reg trước khi non-blocking assign có hiệu lực)
            exp_rs1_data = (txn.rs1_addr == '0) ? '0 : model_reg[txn.rs1_addr];
            exp_rs2_data = (txn.rs2_addr == '0) ? '0 : model_reg[txn.rs2_addr];

            // UPDATE SAU — mô phỏng always_ff, giá trị này chỉ "thấy được" ở transaction kế tiếp
            if (txn.rst_n && txn.wb.reg_en && (txn.wb.rd_addr != '0)) begin
                model_reg[txn.wb.rd_addr] = txn.wb.rd_data;
            end
        endfunction
endclass

class regfile_monitor;

    virtual regfile_if.MON vif;
    mailbox #(regfile_transaction) mon2sb;
    mailbox #(regfile_transaction) mon2cov;
    regfile_ref_model ref_model;

    function new(
        virtual regfile_if.MON vif,
        mailbox #(regfile_transaction) mon2sb,
        mailbox #(regfile_transaction) mon2cov,
        regfile_ref_model ref_model
    );
        this.vif = vif;
        this.mon2sb = mon2sb;
        this.mon2cov = mon2cov;
        this.ref_model = ref_model;
    endfunction

    task run();
        regfile_transaction txn;
        forever begin
            @(vif.mon_cb);

            txn = new();

            txn.rst_n = vif.mon_cb.rst_n;
            txn.rs1_addr = vif.mon_cb.rs1_addr;
            txn.rs2_addr = vif.mon_cb.rs2_addr;
            txn.wb = vif.mon_cb.wb;

            txn.rs1_data = vif.mon_cb.rs1_data;
            txn.rs2_data = vif.mon_cb.rs2_data;

            ref_model.predict(
                txn,
                txn.expected_rs1_data,
                txn.expected_rs2_data
            );
            mon2sb.put(txn.clone());
            mon2cov.put(txn.clone());
        end
    endtask
endclass

class regfile_scoreboard;

    mailbox #(regfile_transaction) mon2sb;
    int pass_cnt = 0;
    int fail_cnt = 0;

    function new(mailbox #(regfile_transaction) mon2sb);
        this.mon2sb = mon2sb;
    endfunction

    task run();
        regfile_transaction txn;
        forever begin
            mon2sb.get(txn);
            if (txn.rs1_data !== txn.expected_rs1_data) begin
                fail_cnt++;
                $error(
                    "[SB][FAIL] RS1 | addr=x%0d actual=%08h expected=%08h",
                    txn.rs1_addr,
                    txn.rs1_data,
                    txn.expected_rs1_data
                );
            end
            else if (txn.rs2_data !== txn.expected_rs2_data) begin
                fail_cnt++;
                $error(
                    "[SB][FAIL] RS2 | addr=x%0d actual=%08h expected=%08h",
                    txn.rs2_addr,
                    txn.rs2_data,
                    txn.expected_rs2_data
                );
            end
            else begin
                pass_cnt++;
            end
        end
    endtask

endclass


class regfile_coverage;

    mailbox #(regfile_transaction) mon2cov;

    // ============================================================
    // WRITE COVERAGE
    // ============================================================

    covergroup cg_write with function sample(regfile_transaction t);
        cp_reg_en : coverpoint t.wb.reg_en {
            bins disabled = {0};
            bins enabled  = {1};
        }
        cp_rd_addr : coverpoint t.wb.rd_addr {
            bins x0        = {0};
            bins low_regs  = {[1:7]};
            bins mid_regs  = {[8:23]};
            bins high_regs = {[24:31]};
        }
        cp_rd_x0 : coverpoint (t.wb.rd_addr == 0) {
            bins x0     = {1};
            bins non_x0 = {0};
        }
        cp_rd_data_zero : coverpoint (t.wb.rd_data == '0) {
            bins zero    = {1};
            bins nonzero = {0};
        }
        cp_rd_data_sign : coverpoint t.wb.rd_data[XLEN-1] {
            bins positive = {0};
            bins negative = {1};
        }
        cp_rd_data_special : coverpoint t.wb.rd_data {
            bins zero          = {32'h0000_0000};
            bins ones          = {32'hFFFF_FFFF};
            bins max_positive  = {32'h7FFF_FFFF};
            bins min_negative  = {32'h8000_0000};
            bins other         = default;
        }
        cross_reg_en_rd_addr :
            cross cp_reg_en, cp_rd_addr;
        cross_write_x0 :
            cross cp_reg_en, cp_rd_x0;
    endgroup


    // ============================================================
    // READ COVERAGE
    // ============================================================

    covergroup cg_read with function sample(regfile_transaction t);
        cp_rs1_addr : coverpoint t.rs1_addr {
            bins x0        = {0};
            bins low_regs  = {[1:7]};
            bins mid_regs  = {[8:23]};
            bins high_regs = {[24:31]};
        }
        cp_rs2_addr : coverpoint t.rs2_addr {
            bins x0        = {0};
            bins low_regs  = {[1:7]};
            bins mid_regs  = {[8:23]};
            bins high_regs = {[24:31]};
        }
        cp_rs1_data_zero : coverpoint (t.rs1_data == '0) {
            bins zero    = {1};
            bins nonzero = {0};
        }
        cp_rs2_data_zero : coverpoint (t.rs2_data == '0) {
            bins zero    = {1};
            bins nonzero = {0};
        }
        cp_rs1_x0 : coverpoint (t.rs1_addr == 0) {
            bins x0     = {1};
            bins non_x0 = {0};
        }
        cp_rs2_x0 : coverpoint (t.rs2_addr == 0) {
            bins x0     = {1};
            bins non_x0 = {0};
        }
        cross_rs1_addr_data :
            cross cp_rs1_addr, cp_rs1_data_zero;
        cross_rs2_addr_data :
            cross cp_rs2_addr, cp_rs2_data_zero;
        cross_both_x0 :
            cross cp_rs1_x0, cp_rs2_x0;
    endgroup


    // ============================================================
    // READ / WRITE INTERACTION COVERAGE
    // ============================================================

    covergroup cg_read_write with function sample(regfile_transaction t);
        cp_rs1_addr : coverpoint t.rs1_addr {
            bins x0   = {0};
            bins low  = {[1:7]};
            bins mid  = {[8:23]};
            bins high = {[24:31]};
        }
        cp_rs2_addr : coverpoint t.rs2_addr {
            bins x0   = {0};
            bins low  = {[1:7]};
            bins mid  = {[8:23]};
            bins high = {[24:31]};
        }
        cp_rd_addr : coverpoint t.wb.rd_addr {
            bins x0   = {0};
            bins low  = {[1:7]};
            bins mid  = {[8:23]};
            bins high = {[24:31]};
        }
        cp_reg_en : coverpoint t.wb.reg_en {
            bins disabled = {0};
            bins enabled  = {1};
        }
        cross_rs1_rd :
            cross cp_rs1_addr, cp_rd_addr, cp_reg_en;
        cross_rs2_rd :
            cross cp_rs2_addr, cp_rd_addr, cp_reg_en;
    endgroup


    function new(mailbox #(regfile_transaction) mon2cov);
        this.mon2cov = mon2cov;
        cg_write = new();
        cg_read = new();
        cg_read_write = new();
    endfunction

    task run();
        regfile_transaction txn;
        forever begin
            mon2cov.get(txn);

            cg_write.sample(txn);
            cg_read.sample(txn);
            cg_read_write.sample(txn);
        end
    endtask

    function void report();

        real total_cov;

        total_cov = (
            cg_write.get_inst_coverage() +
            cg_read.get_inst_coverage() +
            cg_read_write.get_inst_coverage()
        ) / 3.0;

        $display("");
        $display("============================================================");
        $display("                  REGFILE COVERAGE REPORT");
        $display("============================================================");
        $display(
            "[COV] Write        = %0.2f%%",
            cg_write.get_inst_coverage()
        );
        $display(
            "[COV] Read         = %0.2f%%",
            cg_read.get_inst_coverage()
        );
        $display(
            "[COV] Read/Write   = %0.2f%%",
            cg_read_write.get_inst_coverage()
        );
        $display(
            "[COV] TOTAL        = %0.2f%%",
            total_cov
        );
        $display("============================================================");
    endfunction
endclass


class regfile_agent;

    mailbox #(regfile_transaction) gen2drv;
    mailbox #(regfile_transaction) mon2sb;
    mailbox #(regfile_transaction) mon2cov;

    regfile_generator generator;
    regfile_driver driver;
    regfile_monitor monitor;
    regfile_coverage coverage;
    regfile_ref_model ref_model;

    function new(virtual regfile_if vif);

        gen2drv = new();
        mon2sb = new();
        mon2cov = new();

        ref_model = new();

        generator = new(gen2drv);
        driver = new(vif, gen2drv);
        monitor = new(vif, mon2sb, mon2cov, ref_model);
        coverage = new(mon2cov);
    endfunction


    task run();
        fork
            generator.run();
            driver.run();
            monitor.run();
            coverage.run();
        join_none
    endtask


    function void report();
        coverage.report();
    endfunction
endclass


class regfile_env;

    regfile_agent agent;
    regfile_scoreboard scoreboard;

    function new(virtual regfile_if vif);
        agent = new(vif);
        scoreboard = new(agent.mon2sb);
    endfunction


    task run();
        fork
            agent.run();
            scoreboard.run();
        join_none
    endtask

    function void report();
        agent.report();

        $display("");
        $display("============================================================");
        $display("                    REGFILE SCOREBOARD");
        $display("============================================================");

        $display(
            "[SB] PASS = %0d",
            scoreboard.pass_cnt
        );

        $display(
            "[SB] FAIL = %0d",
            scoreboard.fail_cnt
        );
        $display("============================================================");
    endfunction
endclass


class regfile_test;

    virtual regfile_if vif;
    regfile_env env;

    function new(virtual regfile_if vif);
        this.vif = vif;
        env = new(vif);
    endfunction

    task run();
        env.run();
        #11000;
        env.report();
        $finish;
    endtask
endclass


module regfile_tb_top;
    logic clk;
    regfile_if vif(clk);

    // ============================================================
    // Clock
    // ============================================================

    initial begin
        clk = 1'b0;
        forever
            #5 clk = ~clk;
    end

    // ============================================================
    // Waveform
    // ============================================================
    initial begin
        $dumpfile("regfile.vcd");
        $dumpvars(0, regfile_tb_top);
    end

    // ============================================================
    // DUT
    // ============================================================

    regfile u_regfile (
        .clk        (clk),
        .rst_n      (vif.rst_n),
        .rs1_addr_i (vif.rs1_addr),
        .rs2_addr_i (vif.rs2_addr),
        .wb_i       (vif.wb),
        .rs1_data_o (vif.rs1_data),
        .rs2_data_o (vif.rs2_data)

    );
    // ============================================================
    // Test
    // ============================================================
    initial begin
        regfile_test test;
        test = new(vif);
        test.run();
    end
endmodule


