`timescale 1ns/1ps

import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;

interface id_stage_if ( input logic clk);
    logic               rst_n;
    
    if_id_reg_t         reg_id;
    regfile_wb          wb;
    for_info_t          for_info_ex;
    for_info_t          for_info_mem;
    logic [XLEN-1:0]    alu_ex;
    logic [XLEN-1:0]    alu_mem;

    jump_t              jump;
    hzd_ctrl_t          hzd_ctrl;
    id_ex_reg_t         id_reg;

    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output rst_n,reg_id,wb,for_info_ex,for_info_mem,alu_ex,alu_mem;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #1;
        input rst_n,reg_id,wb,for_info_ex,for_info_mem,alu_ex,alu_mem;
        input jump,hzd_ctrl,id_reg;
    endclocking

    modport DRV(clocking drv_cb, input clk);
    modport MON(clocking mon_cb, input clk);
endinterface


class id_stage_transaction;
    rand logic rst_n;
    rand if_id_reg_t         reg_id;
    rand regfile_wb          wb;
    rand for_info_t          for_info_ex;
    rand for_info_t          for_info_mem;
    rand logic [XLEN-1:0]    alu_ex;
    rand logic [XLEN-1:0]    alu_mem;

    logic br_taken;

    jump_t                  jump;
    hzd_ctrl_t              hzd_ctrl;
    id_ex_reg_t             id_reg;

    // =========================================================
    // REFERENCE MODEL
    // =========================================================
    jump_t                  expected_jump;
    hzd_ctrl_t              expected_hzd_ctrl;
    id_ex_reg_t             expected_id_reg;

    // =========================================================
    // CONSTRAINT
    // =========================================================

        constraint c_reg_id {
        reg_id.pc_4 == reg_id.pc_cur + 32'd4;
        reg_id.ins[1:0] == 2'b11;
        reg_id.ins[6:2] inside {5'b01100,5'b00100,5'b00000,5'b01000,5'b11000,5'b11011,5'b11001,5'b01101,5'b00101};
        reg_id.ins[11:7] inside {[0:31]};
        reg_id.ins[19:15] inside {[0:31]};
        reg_id.ins[24:20] inside {[0:31]};
        reg_id.ins[14:12] inside {[0:7]};
        reg_id.ins[31:25] inside {[0:127]};
    }

    constraint c_wb {
        wb.reg_en dist {
            1'b0 := 2,
            1'b1 := 8
        };

        wb.rd_addr inside {[0:31]};
        wb.rd_data dist {
            32'h00000000 := 2,
            [32'h00000001:32'hFFFFFFFF] := 8
        };
    }

    constraint c_for_info_ex {
        for_info_ex.rd_addr inside {[0:31]};

        for_info_ex.mem_re dist {
            1'b0 := 8,
            1'b1 := 2
        };

        for_info_ex.reg_en dist {
            1'b0 := 2,
            1'b1 := 8
        };

        if (!for_info_ex.reg_en)
            for_info_ex.rd_addr == 5'd0;
    }

    constraint c_for_info_mem {
        for_info_mem.rd_addr inside {[0:31]};

        for_info_mem.mem_re dist {
            1'b0 := 8,
            1'b1 := 2
        };

        for_info_mem.reg_en dist {
            1'b0 := 2,
            1'b1 := 8
        };

        if (!for_info_mem.reg_en)
            for_info_mem.rd_addr == 5'd0;
    }

    constraint c_alu_ex {
        alu_ex dist {
            32'h00000000 := 2,
            32'hFFFFFFFF := 2,
            32'h00000001 := 2,
            32'h80000000 := 2,
            32'h7FFFFFFF := 2,
            [32'h00000002:32'hFFFFFFFE] := 10
        };
    }

    constraint c_alu_mem {
        alu_mem dist {
            32'h00000000 := 2,
            32'hFFFFFFFF := 2,
            32'h00000001 := 2,
            32'h80000000 := 2,
            32'h7FFFFFFF := 2,
            [32'h00000002:32'hFFFFFFFE] := 10
        };
    }

    constraint c_forwarding {
        if (for_info_ex.reg_en && (for_info_ex.rd_addr != 5'd0))
            for_info_ex.rd_addr inside {[1:31]};

        if (for_info_mem.reg_en && (for_info_mem.rd_addr != 5'd0))
            for_info_mem.rd_addr inside {[1:31]};
    }

    constraint c_x0 {
        wb.rd_addr != 5'd0;
        for_info_ex.rd_addr != 5'd0;
        for_info_mem.rd_addr != 5'd0;
    }

    constraint c_priority {
        if (for_info_ex.reg_en && for_info_mem.reg_en)
            for_info_ex.rd_addr != for_info_mem.rd_addr;
    }


    
    // =========================================================
    // COPY
    // =========================================================
    function void copy(id_stage_transaction rhs);
        if (rhs == null) return;

        reg_id      = rhs.reg_id;
        wb          = rhs.wb;
        for_info_ex = rhs.for_info_ex;
        for_info_mem= rhs.for_info_mem;
        alu_ex      = rhs.alu_ex;
        alu_mem     = rhs.alu_mem;
    endfunction

    function id_stage_transaction clone();
        id_stage_transaction t = new();
        t.copy(this);
        return t;
    endfunction

    function string convert2string();
        return $sformatf("PC=%08h PC4=%08h INS=%08h | WB_EN=%0d WB_RD=%0d WB_DATA=%08h | EX_RD=%0d EX_MEM_RE=%0d EX_REG_EN=%0d EX_ALU=%08h | MEM_RD=%0d MEM_MEM_RE=%0d MEM_REG_EN=%0d MEM_ALU=%08h",
            reg_id.pc_cur,
            reg_id.pc_4,
            reg_id.ins,
            wb.reg_en,
            wb.rd_addr,
            wb.rd_data,
            for_info_ex.rd_addr,
            for_info_ex.mem_re,
            for_info_ex.reg_en,
            alu_ex,
            for_info_mem.rd_addr,
            for_info_mem.mem_re,
            for_info_mem.reg_en,
            alu_mem
        );
    endfunction

endclass

class id_stage_generator;
    mailbox #(id_stage_transaction) gen2drv;
    int num_txn;
    event done;

    function new ( 
        mailbox #( id_stage_transaction ) gen2drv,
        int num_txn
                );
                    this.gen2drv = gen2drv;
                    this.num_txn = num_txn;
    endfunction

    task run();
        id_stage_transaction txn;
        repeat ( num_txn) begin
            txn = new();
            if(txn.randomize() == 0) 
              $fatal(1, "[GEN] IF transaction randomization failed");
            gen2drv.put(txn);
        end
        -> done;
    endtask
endclass

class id_stage_driver;

    virtual id_stage_if.DRV vif;
    mailbox #(id_stage_transaction) gen2drv;

    function new(
        virtual id_stage_if.DRV vif,
        mailbox #(id_stage_transaction) gen2drv
    );
        this.vif = vif;
        this.gen2drv = gen2drv;
    endfunction

    task reset_dut();
        vif.reg_id = '0;
        vif.wb = '0;
        vif.for_info_ex = '0;
        vif.for_info_mem = '0;
        vif.alu_ex = '0;
        vif.alu_mem = '0;
        repeat(3) @(negedge vif.clk);
    endtask

    task run();
        id_stage_transaction txn;

        forever begin
            gen2drv.get(txn);

            @(negedge vif.clk);

            vif.reg_id = txn.reg_id;
            vif.wb = txn.wb;
            vif.for_info_ex = txn.for_info_ex;
            vif.for_info_mem = txn.for_info_mem;
            vif.alu_ex = txn.alu_ex;
            vif.alu_mem = txn.alu_mem;
        end
    endtask

endclass

class id_stage_ref_model;
    deco_imm_ref_model deco_model;
    regfile_ref_model regfile_model;

    jump_t model_jump;
    hzd_ctrl_t model_hzd_ctrl;
    id_ex_reg_t model_id_reg;

    decode_s model_decode;
    bit model_rs1_used;
    bit model_rs2_used;
    bit model_jump_en;
    logic [XLEN-1:0] model_imm;
    logic [XLEN-1:0] model_rs1_data;
    logic [XLEN-1:0] model_rs2_data;

    function new();
        deco_model = new();
        regfile_model = new();
        model_jump = '0;
        model_hzd_ctrl = '0;
        model_id_reg = '0;
        model_decode = '0;
        model_rs1_used = 1'b0;
        model_rs2_used = 1'b0;
        model_jump_en = 1'b0;
        model_imm = '0;
        model_rs1_data = '0;
        model_rs2_data = '0;
    endfunction

    function void reset();
        deco_model.reset();
        regfile_model.reset();
        model_jump = '0;
        model_hzd_ctrl = '0;
        model_id_reg = '0;
        model_decode = '0;
        model_rs1_used = 1'b0;
        model_rs2_used = 1'b0;
        model_jump_en = 1'b0;
        model_imm = '0;
        model_rs1_data = '0;
        model_rs2_data = '0;
    endfunction

    function void predict(id_stage_transaction txn);
        regfile_transaction reg_txn;
        if (txn == null) return;

        if (!txn.rst_n) begin
            reset();
            txn.expected_jump = '0;
            txn.expected_hzd_ctrl = '0;
            txn.expected_id_reg = '0;
            return;
        end

        deco_model.predict(txn.reg_id.ins,model_decode,model_rs1_used,model_rs2_used,model_jump_en,model_imm);

        reg_txn = new();
        reg_txn.rst_n = txn.rst_n;
        reg_txn.rs1_addr = txn.reg_id.ins[19:15];
        reg_txn.rs2_addr = txn.reg_id.ins[24:20];
        reg_txn.wb = txn.wb;
        regfile_model.predict(reg_txn,model_rs1_data,model_rs2_data);

        model_jump = '0;
        model_jump.jal = model_decode.jal_en;
        model_jump.jalr = model_decode.jalr_en;
        model_jump.br_en = model_decode.br_en;
        model_jump.br_taken = txn.br_taken;

        model_id_reg = '0;
        model_id_reg.f3 = txn.reg_id.ins[14:12];
        model_id_reg.f7_5 = txn.reg_id.ins[30];
        model_id_reg.pc_cur = txn.reg_id.pc_cur;
        model_id_reg.pc_4 = txn.reg_id.pc_4;
        model_id_reg.imm_out = model_imm;
        model_id_reg.rd_addr = txn.reg_id.ins[11:7];
        model_id_reg.rs1_addr = txn.reg_id.ins[19:15];
        model_id_reg.rs2_addr = txn.reg_id.ins[24:20];
        model_id_reg.rs1_data = model_rs1_data;
        model_id_reg.rs2_data = model_rs2_data;
        model_id_reg.ex_ctrl = model_decode.ex_ctrl;
        model_id_reg.mem_ctrl = model_decode.mem_ctrl;
        model_id_reg.extension = model_decode.extension;
        model_id_reg.wb_ctrl = model_decode.wb_ctrl;

        hazard_predict(txn);

        txn.expected_jump = model_jump;
        txn.expected_hzd_ctrl = model_hzd_ctrl;
        txn.expected_id_reg = model_id_reg;
    endfunction

    function void hazard_predict(id_stage_transaction txn);
        logic take_jump;
        logic rs1_ex;
        logic rs2_ex;
        logic rs1_mem;
        logic rs2_mem;
        logic br2alu_ex;
        logic br2load_ex;
        logic br2load_mem;
        logic alu2load;
        logic need_stall;

        take_jump = model_jump_en || (txn.br_taken && model_decode.br_en);

        rs1_ex = model_rs1_used && txn.for_info_ex.reg_en && (txn.for_info_ex.rd_addr != '0) && (txn.for_info_ex.rd_addr == model_id_reg.rs1_addr);
        rs2_ex = model_rs2_used && txn.for_info_ex.reg_en && (txn.for_info_ex.rd_addr != '0) && (txn.for_info_ex.rd_addr == model_id_reg.rs2_addr);
        rs1_mem = model_rs1_used && txn.for_info_mem.reg_en && (txn.for_info_mem.rd_addr != '0) && (txn.for_info_mem.rd_addr == model_id_reg.rs1_addr);
        rs2_mem = model_rs2_used && txn.for_info_mem.reg_en && (txn.for_info_mem.rd_addr != '0) && (txn.for_info_mem.rd_addr == model_id_reg.rs2_addr);

        br2alu_ex = (rs1_ex || rs2_ex) && model_decode.br_en && !txn.for_info_ex.mem_re;
        br2load_ex = (rs1_ex || rs2_ex) && model_decode.br_en && txn.for_info_ex.mem_re;
        br2load_mem = (rs1_mem || rs2_mem) && model_decode.br_en && txn.for_info_mem.mem_re;
        alu2load = (rs1_ex || rs2_ex) && txn.for_info_ex.mem_re && !model_decode.br_en;

        need_stall = br2alu_ex || br2load_ex || br2load_mem || alu2load;

        model_hzd_ctrl = '0;
        model_hzd_ctrl.stall_pc = need_stall;
        model_hzd_ctrl.stall_if_id = need_stall;
        model_hzd_ctrl.flush_id_ex = need_stall;
        model_hzd_ctrl.flush_if_id = take_jump && !need_stall;
    endfunction
endclass
class id_stage_monitor;

    virtual id_stage_if.MON vif;
    mailbox #(id_stage_transaction) mon2sb;
    mailbox #(id_stage_transaction) mon2cov;
    id_stage_ref_model ref_model;

    int num_txn;
    event done;

    function new(
        virtual id_stage_if.MON vif,
        mailbox #(id_stage_transaction) mon2sb,
        mailbox #(id_stage_transaction) mon2cov,
        id_stage_ref_model ref_model,
        int num_txn
    );
        this.vif = vif;
        this.mon2sb = mon2sb;
        this.mon2cov = mon2cov;
        this.ref_model = ref_model;
        this.num_txn = num_txn;
    endfunction

    task run();
        id_stage_transaction txn;

        for (int i = 0; i < num_txn; i++) begin
            @(posedge vif.clk);
            #1;

            txn = new();

            // =================================================
            // INPUT
            // =================================================

            txn.reg_id = vif.mon_cb.reg_id;
            txn.wb = vif.mon_cb.wb;

            txn.for_info_ex = vif.mon_cb.for_info_ex;
            txn.for_info_mem = vif.mon_cb.for_info_mem;

            txn.alu_ex = vif.mon_cb.alu_ex;
            txn.alu_mem = vif.mon_cb.alu_mem;

            // =================================================
            // DUT OUTPUT
            // =================================================

            txn.jump = vif.mon_cb.jump;
            txn.hzd_ctrl = vif.mon_cb.hzd_ctrl;
            txn.id_reg = vif.mon_cb.id_reg;

            // =================================================
            // REFERENCE MODEL
            // =================================================

            ref_model.predict(txn);

            // =================================================
            // SEND TO SCOREBOARD / COVERAGE
            // =================================================

            mon2sb.put(txn);
            mon2cov.put(txn);
        end

        -> done;

    endtask

endclass

class id_stage_scoreboard;

    mailbox #(id_stage_transaction) mon2sb;

    int pass_cnt = 0;
    int fail_cnt = 0;

    function new(mailbox #(id_stage_transaction) mon2sb);
        this.mon2sb = mon2sb;
    endfunction

    task run();

        id_stage_transaction txn;

        forever begin
            mon2sb.get(txn);

            // =========================================================
            // 1. JUMP
            // =========================================================

            if (txn.jump === txn.expected_jump)
                pass_cnt++;
            else begin
                fail_cnt++;

                $error("[SB][FAIL] JUMP\nACTUAL={jal=%0b jalr=%0b br_en=%0b br_taken=%0b jump_addr=%08h} EXPECTED={jal=%0b jalr=%0b br_en=%0b br_taken=%0b jump_addr=%08h}\nPC=%08h PC4=%08h INS=%08h",
                    txn.jump.jal,
                    txn.jump.jalr,
                    txn.jump.br_en,
                    txn.jump.br_taken,
                    txn.jump.jump_addr,
                    txn.expected_jump.jal,
                    txn.expected_jump.jalr,
                    txn.expected_jump.br_en,
                    txn.expected_jump.br_taken,
                    txn.expected_jump.jump_addr,
                    txn.reg_id.pc_cur,
                    txn.reg_id.pc_4,
                    txn.reg_id.ins);
            end

            // =========================================================
            // 2. HAZARD CONTROL
            // =========================================================

            if (txn.hzd_ctrl === txn.expected_hzd_ctrl)
                pass_cnt++;
            else begin
                fail_cnt++;

                $error("[SB][FAIL] HZD_CTRL\nACTUAL={stall_pc=%0b stall_if_id=%0b flush_if_id=%0b flush_id_ex=%0b} EXPECTED={stall_pc=%0b stall_if_id=%0b flush_if_id=%0b flush_id_ex=%0b}\nPC=%08h INS=%08h",
                    txn.hzd_ctrl.stall_pc,
                    txn.hzd_ctrl.stall_if_id,
                    txn.hzd_ctrl.flush_if_id,
                    txn.hzd_ctrl.flush_id_ex,
                    txn.expected_hzd_ctrl.stall_pc,
                    txn.expected_hzd_ctrl.stall_if_id,
                    txn.expected_hzd_ctrl.flush_if_id,
                    txn.expected_hzd_ctrl.flush_id_ex,
                    txn.reg_id.pc_cur,
                    txn.reg_id.ins);
            end

            // =========================================================
            // 3. ID / EX REGISTER
            // =========================================================

            if (txn.id_reg === txn.expected_id_reg)
                pass_cnt++;
            else begin
                fail_cnt++;

                $error("[SB][FAIL] ID_REG\nACTUAL={F3=%0h F7_5=%0b PC=%08h PC4=%08h IMM=%08h RD=%0d RS1=%0d RS2=%0d RS1_DATA=%08h RS2_DATA=%08h EXT=%0b} EXPECTED={F3=%0h F7_5=%0b PC=%08h PC4=%08h IMM=%08h RD=%0d RS1=%0d RS2=%0d RS1_DATA=%08h RS2_DATA=%08h EXT=%0b}\nINS=%08h",
                    txn.id_reg.f3,
                    txn.id_reg.f7_5,
                    txn.id_reg.pc_cur,
                    txn.id_reg.pc_4,
                    txn.id_reg.imm_out,
                    txn.id_reg.rd_addr,
                    txn.id_reg.rs1_addr,
                    txn.id_reg.rs2_addr,
                    txn.id_reg.rs1_data,
                    txn.id_reg.rs2_data,
                    txn.id_reg.extension,
                    txn.expected_id_reg.f3,
                    txn.expected_id_reg.f7_5,
                    txn.expected_id_reg.pc_cur,
                    txn.expected_id_reg.pc_4,
                    txn.expected_id_reg.imm_out,
                    txn.expected_id_reg.rd_addr,
                    txn.expected_id_reg.rs1_addr,
                    txn.expected_id_reg.rs2_addr,
                    txn.expected_id_reg.rs1_data,
                    txn.expected_id_reg.rs2_data,
                    txn.expected_id_reg.extension,
                    txn.reg_id.ins);
            end
        end
    endtask

    function void report();
        $display("\n[SB] PASS=%0d FAIL=%0d RESULT=%s",
            pass_cnt,
            fail_cnt,
            (fail_cnt == 0) ? "PASS" : "FAIL");
    endfunction

endclass

class id_stage_coverage;

    mailbox #(id_stage_transaction) mon2cov;

    // =========================================================
    // 1. JUMP OUTPUT
    // =========================================================

    covergroup cg_jump with function sample(id_stage_transaction t);

        cp_jal : coverpoint t.jump.jal {
            bins no_jal = {0};
            bins jal    = {1};
        }

        cp_jalr : coverpoint t.jump.jalr {
            bins no_jalr = {0};
            bins jalr    = {1};
        }

        cp_br_en : coverpoint t.jump.br_en {
            bins disabled = {0};
            bins enabled  = {1};
        }

        cp_br_taken : coverpoint t.jump.br_taken {
            bins not_taken = {0};
            bins taken     = {1};
        }

        cp_jump_addr : coverpoint t.jump.jump_addr {
            bins zero    = {32'h0000_0000};
            bins one     = {32'h0000_0001};
            bins int_max = {32'h7FFF_FFFF};
            bins int_min = {32'h8000_0000};
            bins max     = {32'hFFFF_FFFF};
        }

        jal_jalr : cross cp_jal, cp_jalr;
        br_result : cross cp_br_en, cp_br_taken;

    endgroup

    // =========================================================
    // 2. HAZARD CONTROL
    // =========================================================

    covergroup cg_hazard with function sample(id_stage_transaction t);

        cp_stall_pc : coverpoint t.hzd_ctrl.stall_pc {
            bins no_stall = {0};
            bins stall    = {1};
        }

        cp_stall_if_id : coverpoint t.hzd_ctrl.stall_if_id {
            bins no_stall = {0};
            bins stall    = {1};
        }

        cp_flush_if_id : coverpoint t.hzd_ctrl.flush_if_id {
            bins no_flush = {0};
            bins flush    = {1};
        }

        cp_flush_id_ex : coverpoint t.hzd_ctrl.flush_id_ex {
            bins no_flush = {0};
            bins flush    = {1};
        }

        stall_flush : cross cp_stall_pc, cp_flush_if_id;
        stall_id_ex : cross cp_stall_pc, cp_flush_id_ex;

    endgroup

    // =========================================================
    // 3. HAZARD CONDITION
    // =========================================================

    covergroup cg_hazard_condition with function sample(id_stage_transaction t);

        cp_rs1_used : coverpoint t.reg_id.ins[19:15] {
            bins x0  = {5'd0};
            bins x1  = {5'd1};
            bins x31 = {5'd31};
        }

        cp_rs2_used : coverpoint t.reg_id.ins[24:20] {
            bins x0  = {5'd0};
            bins x1  = {5'd1};
            bins x31 = {5'd31};
        }

        cp_ex_reg_en : coverpoint t.for_info_ex.reg_en {
            bins disabled = {0};
            bins enabled  = {1};
        }

        cp_ex_mem_re : coverpoint t.for_info_ex.mem_re {
            bins no_load = {0};
            bins load    = {1};
        }

        cp_mem_reg_en : coverpoint t.for_info_mem.reg_en {
            bins disabled = {0};
            bins enabled  = {1};
        }

        cp_mem_mem_re : coverpoint t.for_info_mem.mem_re {
            bins no_load = {0};
            bins load    = {1};
        }

        cp_ex_rd : coverpoint t.for_info_ex.rd_addr {
            bins x0  = {5'd0};
            bins x1  = {5'd1};
            bins x31 = {5'd31};
        }

        cp_mem_rd : coverpoint t.for_info_mem.rd_addr {
            bins x0  = {5'd0};
            bins x1  = {5'd1};
            bins x31 = {5'd31};
        }

        ex_hazard : cross cp_ex_reg_en, cp_ex_mem_re, cp_ex_rd;
        mem_hazard : cross cp_mem_reg_en, cp_mem_mem_re, cp_mem_rd;

    endgroup

    // =========================================================
    // 4. ID / EX REGISTER CONTROL
    // =========================================================

    covergroup cg_id_reg with function sample(id_stage_transaction t);

        cp_alu_op : coverpoint t.id_reg.ex_ctrl.alu_op;

        cp_sel_a : coverpoint t.id_reg.ex_ctrl.sel_a;

        cp_sel_b : coverpoint t.id_reg.ex_ctrl.sel_b;

        cp_mem_re : coverpoint t.id_reg.mem_ctrl.dmem_re {
            bins disabled = {0};
            bins enabled  = {1};
        }

        cp_mem_wri : coverpoint t.id_reg.mem_ctrl.dmem_wri {
            bins disabled = {0};
            bins enabled  = {1};
        }

        cp_reg_en : coverpoint t.id_reg.wb_ctrl.reg_en {
            bins disabled = {0};
            bins enabled  = {1};
        }

        cp_wb_sel : coverpoint t.id_reg.wb_ctrl.sel_wb;

        cp_extension : coverpoint t.id_reg.extension {
            bins disabled = {0};
            bins enabled  = {1};
        }

        control_a : cross cp_sel_a, cp_sel_b;
        control_mem : cross cp_mem_re, cp_mem_wri;
        control_wb : cross cp_reg_en, cp_wb_sel;

    endgroup

    // =========================================================
    // 5. ID / EX DATA
    // =========================================================

    covergroup cg_id_data with function sample(id_stage_transaction t);

        cp_rd : coverpoint t.id_reg.rd_addr {
            bins x0  = {5'd0};
            bins x1  = {5'd1};
            bins x31 = {5'd31};
        }

        cp_rs1 : coverpoint t.id_reg.rs1_addr {
            bins x0  = {5'd0};
            bins x1  = {5'd1};
            bins x31 = {5'd31};
        }

        cp_rs2 : coverpoint t.id_reg.rs2_addr {
            bins x0  = {5'd0};
            bins x1  = {5'd1};
            bins x31 = {5'd31};
        }

        cp_rs1_data : coverpoint t.id_reg.rs1_data {
            bins zero    = {32'h0000_0000};
            bins one     = {32'h0000_0001};
            bins int_max = {32'h7FFF_FFFF};
            bins int_min = {32'h8000_0000};
            bins max     = {32'hFFFF_FFFF};
        }

        cp_rs2_data : coverpoint t.id_reg.rs2_data {
            bins zero    = {32'h0000_0000};
            bins one     = {32'h0000_0001};
            bins int_max = {32'h7FFF_FFFF};
            bins int_min = {32'h8000_0000};
            bins max     = {32'hFFFF_FFFF};
        }

        cp_imm : coverpoint t.id_reg.imm_out {
            bins zero      = {32'h0000_0000};
            bins one       = {32'h0000_0001};
            bins minus_one = {32'hFFFF_FFFF};
            bins int_max   = {32'h7FFF_FFFF};
            bins int_min   = {32'h8000_0000};
        }

    endgroup

    // =========================================================
    // 6. CROSS - IMPORTANT INTEGRATION CASES
    // =========================================================

    covergroup cg_cross with function sample(id_stage_transaction t);

        cp_jal : coverpoint t.jump.jal {
            bins no_jal = {0};
            bins jal    = {1};
        }

        cp_jalr : coverpoint t.jump.jalr {
            bins no_jalr = {0};
            bins jalr    = {1};
        }

        cp_br_en : coverpoint t.jump.br_en {
            bins disabled = {0};
            bins enabled  = {1};
        }

        cp_br_taken : coverpoint t.jump.br_taken {
            bins not_taken = {0};
            bins taken     = {1};
        }

        cp_stall : coverpoint t.hzd_ctrl.stall_pc {
            bins no_stall = {0};
            bins stall    = {1};
        }

        cp_flush : coverpoint t.hzd_ctrl.flush_if_id {
            bins no_flush = {0};
            bins flush    = {1};
        }
        cp_sel_a : coverpoint t.id_reg.ex_ctrl.sel_a;
        cp_sel_b : coverpoint t.id_reg.ex_ctrl.sel_b;
        jump_stall : cross cp_jal, cp_jalr, cp_stall;
        branch_stall : cross cp_br_en, cp_br_taken, cp_stall;
        branch_flush : cross cp_br_en, cp_br_taken, cp_flush;
        stall_flush : cross cp_stall, cp_flush;
        sel_a_stall : cross cp_sel_a, cp_stall;
        sel_b_stall : cross cp_sel_b, cp_stall;
    endgroup
    // =========================================================
    // CONSTRUCTOR
    // =========================================================

    function new(mailbox #(id_stage_transaction) mon2cov);
        this.mon2cov = mon2cov;
        cg_jump = new();
        cg_hazard = new();
        cg_hazard_condition = new();
        cg_id_reg = new();
        cg_id_data = new();
        cg_cross = new();
    endfunction
    // =========================================================
    // RUN
    // =========================================================
    task run();
        id_stage_transaction txn;
        forever begin
            mon2cov.get(txn);
            cg_jump.sample(txn);
            cg_hazard.sample(txn);
            cg_hazard_condition.sample(txn);
            cg_id_reg.sample(txn);
            cg_id_data.sample(txn);
            cg_cross.sample(txn);
        end
    endtask

    // =========================================================
    // REPORT
    // =========================================================

    function void report();
        $display("\n============================================================");
        $display("ID STAGE COVERAGE");
        $display("============================================================");
        $display("[COV] JUMP              = %0.2f%%", cg_jump.get_inst_coverage());
        $display("[COV] HAZARD            = %0.2f%%", cg_hazard.get_inst_coverage());
        $display("[COV] HAZARD CONDITION  = %0.2f%%", cg_hazard_condition.get_inst_coverage());
        $display("[COV] ID REG             = %0.2f%%", cg_id_reg.get_inst_coverage());
        $display("[COV] ID DATA            = %0.2f%%", cg_id_data.get_inst_coverage());
        $display("[COV] CROSS              = %0.2f%%", cg_cross.get_inst_coverage());
        $display("[COV] TOTAL = %0.2f%%", (cg_jump.get_inst_coverage() + cg_hazard.get_inst_coverage() + cg_hazard_condition.get_inst_coverage() + cg_id_reg.get_inst_coverage() + cg_id_data.get_inst_coverage() + cg_cross.get_inst_coverage()) / 6.0);
        $display("============================================================");
    endfunction

    // =========================================================
    // DIRECT SAMPLE
    // =========================================================

    function void sample_direct(id_stage_transaction t);
        cg_jump.sample(t);
        cg_hazard.sample(t);
        cg_hazard_condition.sample(t);
        cg_id_reg.sample(t);
        cg_id_data.sample(t);
        cg_cross.sample(t);
    endfunction
endclass

class id_stage_agent;
    virtual id_stage_if vif;

    mailbox #(id_stage_transaction) gen2drv;
    mailbox #(id_stage_transaction) mon2sb;
    mailbox #(id_stage_transaction) mon2cov;

    id_stage_generator generator;
    id_stage_driver driver;
    id_stage_monitor monitor;
    id_stage_ref_model ref_model;

    function new(
        virtual id_stage_if vif,
        int num_txn
    );
        this.vif = vif;
        gen2drv = new();
        mon2sb  = new();
        mon2cov = new();

        ref_model = new();

        generator = new(gen2drv,num_txn);
        driver = new(vif.DRV,gen2drv);
        monitor = new(vif.MON,mon2sb,mon2cov,ref_model,num_txn);
    endfunction

    task run();
        fork
            generator.run();
            driver.run();
            monitor.run();
        join_none
    endtask
endclass

class id_stage_env;
    id_stage_agent agent;
    id_stage_scoreboard scoreboard;
    id_stage_coverage coverage;

    function new(
        virtual id_stage_if vif,
        int num_txn
    );
        agent = new(vif,num_txn);
        scoreboard = new(agent.mon2sb);
        coverage = new(agent.mon2cov);
    endfunction

    task run();
        fork
            agent.run();
            scoreboard.run();
            coverage.run();
        join_none
    endtask
endclass



class id_stage_test;

    virtual id_stage_if vif;
    id_stage_env env;

    int direct_pass = 0;
    int direct_fail = 0;
    int num_random_txn;

    function new(virtual id_stage_if vif, int num_random_txn);
        this.vif = vif;
        this.num_random_txn = num_random_txn;
        env = new(vif, num_random_txn);
    endfunction

    // ========================================================================
    // DIRECT CHECK
    // ========================================================================

    task direct_check_bit(string name, logic actual, logic expected);
        if (actual !== expected) begin
            direct_fail++;
            $error("[DIRECT][FAIL] %s actual=%0b expected=%0b", name, actual, expected);
        end
        else begin
            direct_pass++;
            $display("[DIRECT][PASS] %s value=%0b", name, actual);
        end
    endtask

    task direct_check(string name, logic [XLEN-1:0] actual, logic [XLEN-1:0] expected);
        if (actual !== expected) begin
            direct_fail++;
            $error("[DIRECT][FAIL] %s actual=%08h expected=%08h", name, actual, expected);
        end
        else begin
            direct_pass++;
            $display("[DIRECT][PASS] %s value=%08h", name, actual);
        end
    endtask

    task direct_check_jump(string name, jump_t actual, jump_t expected);
        if (actual !== expected) begin
            direct_fail++;
            $error("[DIRECT][FAIL] %s\nACTUAL=%p\nEXPECTED=%p", name, actual, expected);
        end
        else begin
            direct_pass++;
            $display("[DIRECT][PASS] %s PASS", name);
        end
    endtask

    task direct_check_hzd(string name, hzd_ctrl_t actual, hzd_ctrl_t expected);
        if (actual !== expected) begin
            direct_fail++;
            $error("[DIRECT][FAIL] %s\nACTUAL=%p\nEXPECTED=%p", name, actual, expected);
        end
        else begin
            direct_pass++;
            $display("[DIRECT][PASS] %s PASS", name);
        end
    endtask

    task direct_check_id_reg(string name, id_ex_reg_t actual, id_ex_reg_t expected);
        if (actual !== expected) begin
            direct_fail++;
            $error("[DIRECT][FAIL] %s\nACTUAL=%p\nEXPECTED=%p", name, actual, expected);
        end
        else begin
            direct_pass++;
            $display("[DIRECT][PASS] %s PASS", name);
        end
    endtask

    // ========================================================================
    // DIRECT -> COVERAGE
    // ========================================================================

    task direct_sample_cov();
        id_stage_transaction t = new();

        t.reg_id = vif.reg_id;
        t.wb = vif.wb;
        t.for_info_ex = vif.for_info_ex;
        t.for_info_mem = vif.for_info_mem;
        t.alu_ex = vif.alu_ex;
        t.alu_mem = vif.alu_mem;

        t.jump = vif.jump;
        t.hzd_ctrl = vif.hzd_ctrl;
        t.id_reg = vif.id_reg;

        env.coverage.sample_direct(t);
    endtask

    // ========================================================================
    // IDLE
    // ========================================================================

    task direct_idle();

        vif.reg_id = '0;
        vif.wb = '0;
        vif.for_info_ex = '0;
        vif.for_info_mem = '0;
        vif.alu_ex = '0;
        vif.alu_mem = '0;

        @(posedge vif.clk);
        #1;

    endtask

    // ========================================================================
    // 1. NORMAL - NO HAZARD / NO JUMP
    // ========================================================================

    task direct_normal();

        jump_t exp_jump;
        hzd_ctrl_t exp_hzd;

        vif.reg_id.pc_cur = 32'h0000_1000;
        vif.reg_id.pc_4 = 32'h0000_1004;
        vif.reg_id.ins = 32'h0010_0093;

        vif.wb.reg_en = 1'b0;
        vif.wb.rd_addr = 5'd0;
        vif.wb.rd_data = 32'h0;

        vif.for_info_ex = '0;
        vif.for_info_mem = '0;
        vif.alu_ex = 32'h0;
        vif.alu_mem = 32'h0;

        @(posedge vif.clk);
        #1;

        exp_jump = '0;
        exp_hzd = '0;

        direct_check_jump("NORMAL JUMP", vif.jump, exp_jump);
        direct_check_hzd("NORMAL HAZARD", vif.hzd_ctrl, exp_hzd);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 2. JAL
    // ========================================================================

    task direct_jal();

        jump_t exp_jump;
        hzd_ctrl_t exp_hzd;

        vif.reg_id.pc_cur = 32'h0000_1000;
        vif.reg_id.pc_4 = 32'h0000_1004;
        vif.reg_id.ins = 32'h0000_00EF;

        vif.wb = '0;
        vif.for_info_ex = '0;
        vif.for_info_mem = '0;
        vif.alu_ex = '0;
        vif.alu_mem = '0;

        @(posedge vif.clk);
        #1;

        exp_jump = '0;
        exp_jump.jal = 1'b1;
        exp_jump.jalr = 1'b0;
        exp_jump.br_en = 1'b0;
        exp_jump.br_taken = 1'b0;

        exp_hzd = '0;
        exp_hzd.flush_if_id = 1'b1;

        direct_check_jump("JAL", vif.jump, exp_jump);
        direct_check_hzd("JAL HAZARD", vif.hzd_ctrl, exp_hzd);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 3. JALR
    // ========================================================================

    task direct_jalr();

        jump_t exp_jump;
        hzd_ctrl_t exp_hzd;

        vif.reg_id.pc_cur = 32'h0000_2000;
        vif.reg_id.pc_4 = 32'h0000_2004;
        vif.reg_id.ins = 32'h0000_8067;

        vif.wb = '0;
        vif.for_info_ex = '0;
        vif.for_info_mem = '0;
        vif.alu_ex = '0;
        vif.alu_mem = '0;

        @(posedge vif.clk);
        #1;

        exp_jump = '0;
        exp_jump.jal = 1'b0;
        exp_jump.jalr = 1'b1;
        exp_jump.br_en = 1'b0;
        exp_jump.br_taken = 1'b0;

        exp_hzd = '0;
        exp_hzd.flush_if_id = 1'b1;

        direct_check_jump("JALR", vif.jump, exp_jump);
        direct_check_hzd("JALR HAZARD", vif.hzd_ctrl, exp_hzd);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 4. BRANCH NOT TAKEN
    // ========================================================================

    task direct_branch_not_taken();

        jump_t exp_jump;
        hzd_ctrl_t exp_hzd;

        vif.reg_id.pc_cur = 32'h0000_3000;
        vif.reg_id.pc_4 = 32'h0000_3004;
        vif.reg_id.ins = 32'h0000_0063;

        vif.wb = '0;
        vif.for_info_ex = '0;
        vif.for_info_mem = '0;
        vif.alu_ex = '0;
        vif.alu_mem = '0;

        @(posedge vif.clk);
        #1;

        exp_jump = '0;
        exp_jump.br_en = 1'b1;
        exp_jump.br_taken = 1'b0;

        exp_hzd = '0;

        direct_check_jump("BRANCH NOT TAKEN", vif.jump, exp_jump);
        direct_check_hzd("BRANCH NOT TAKEN HAZARD", vif.hzd_ctrl, exp_hzd);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 5. BRANCH TAKEN
    // ========================================================================

    task direct_branch_taken();

        jump_t exp_jump;
        hzd_ctrl_t exp_hzd;

        vif.reg_id.pc_cur = 32'h0000_3000;
        vif.reg_id.pc_4 = 32'h0000_3004;
        vif.reg_id.ins = 32'h0000_0063;

        vif.wb = '0;
        vif.for_info_ex = '0;
        vif.for_info_mem = '0;
        vif.alu_ex = '0;
        vif.alu_mem = '0;

        @(posedge vif.clk);
        #1;

        exp_jump = '0;
        exp_jump.br_en = 1'b1;
        exp_jump.br_taken = 1'b1;

        exp_hzd = '0;
        exp_hzd.flush_if_id = 1'b1;

        direct_check_jump("BRANCH TAKEN", vif.jump, exp_jump);
        direct_check_hzd("BRANCH TAKEN HAZARD", vif.hzd_ctrl, exp_hzd);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 6. ALU FORWARD -> NO BRANCH
    // ========================================================================

    task direct_alu_forward_ex();

        jump_t exp_jump;
        hzd_ctrl_t exp_hzd;

        vif.reg_id.pc_cur = 32'h0000_4000;
        vif.reg_id.pc_4 = 32'h0000_4004;
        vif.reg_id.ins = 32'h0000_0093;

        vif.wb = '0;

        vif.for_info_ex.rd_addr = 5'd5;
        vif.for_info_ex.reg_en = 1'b1;
        vif.for_info_ex.mem_re = 1'b0;

        vif.for_info_mem = '0;

        vif.alu_ex = 32'h1234_5678;
        vif.alu_mem = '0;

        @(posedge vif.clk);
        #1;

        exp_jump = '0;

        exp_hzd = '0;
        exp_hzd.stall_pc = 1'b1;
        exp_hzd.stall_if_id = 1'b1;
        exp_hzd.flush_id_ex = 1'b1;

        direct_check_hzd("ALU FORWARD EX", vif.hzd_ctrl, exp_hzd);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 7. LOAD-USE HAZARD
    // ========================================================================

    task direct_load_use_ex();

        jump_t exp_jump;
        hzd_ctrl_t exp_hzd;

        vif.reg_id.pc_cur = 32'h0000_5000;
        vif.reg_id.pc_4 = 32'h0000_5004;
        vif.reg_id.ins = 32'h0000_0093;

        vif.wb = '0;

        vif.for_info_ex.rd_addr = 5'd5;
        vif.for_info_ex.reg_en = 1'b1;
        vif.for_info_ex.mem_re = 1'b1;

        vif.for_info_mem = '0;

        vif.alu_ex = 32'h1111_1111;
        vif.alu_mem = '0;

        @(posedge vif.clk);
        #1;

        exp_jump = '0;

        exp_hzd = '0;
        exp_hzd.stall_pc = 1'b1;
        exp_hzd.stall_if_id = 1'b1;
        exp_hzd.flush_id_ex = 1'b1;

        direct_check_hzd("LOAD USE EX", vif.hzd_ctrl, exp_hzd);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 8. LOAD FORWARD FROM MEM
    // ========================================================================

    task direct_load_forward_mem();

        jump_t exp_jump;
        hzd_ctrl_t exp_hzd;

        vif.reg_id.pc_cur = 32'h0000_6000;
        vif.reg_id.pc_4 = 32'h0000_6004;
        vif.reg_id.ins = 32'h0000_0093;

        vif.wb = '0;

        vif.for_info_ex = '0;

        vif.for_info_mem.rd_addr = 5'd5;
        vif.for_info_mem.reg_en = 1'b1;
        vif.for_info_mem.mem_re = 1'b1;

        vif.alu_ex = '0;
        vif.alu_mem = 32'h2222_2222;

        @(posedge vif.clk);
        #1;

        exp_jump = '0;

        exp_hzd = '0;
        exp_hzd.stall_pc = 1'b1;
        exp_hzd.stall_if_id = 1'b1;
        exp_hzd.flush_id_ex = 1'b1;

        direct_check_hzd("LOAD FORWARD MEM", vif.hzd_ctrl, exp_hzd);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 9. BRANCH + EX ALU FORWARD
    // ========================================================================

    task direct_branch_ex_hazard();

        jump_t exp_jump;
        hzd_ctrl_t exp_hzd;

        vif.reg_id.pc_cur = 32'h0000_7000;
        vif.reg_id.pc_4 = 32'h0000_7004;
        vif.reg_id.ins = 32'h0000_0063;

        vif.wb = '0;

        vif.for_info_ex.rd_addr = 5'd5;
        vif.for_info_ex.reg_en = 1'b1;
        vif.for_info_ex.mem_re = 1'b0;

        vif.for_info_mem = '0;

        vif.alu_ex = 32'h3333_3333;
        vif.alu_mem = '0;

        @(posedge vif.clk);
        #1;

        exp_jump = '0;
        exp_jump.br_en = 1'b1;
        exp_jump.br_taken = 1'b0;

        exp_hzd = '0;
        exp_hzd.stall_pc = 1'b1;
        exp_hzd.stall_if_id = 1'b1;
        exp_hzd.flush_id_ex = 1'b1;

        direct_check_jump("BRANCH EX HAZARD JUMP", vif.jump, exp_jump);
        direct_check_hzd("BRANCH EX HAZARD", vif.hzd_ctrl, exp_hzd);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 10. BRANCH + LOAD IN EX
    // ========================================================================

    task direct_branch_load_ex();

        jump_t exp_jump;
        hzd_ctrl_t exp_hzd;

        vif.reg_id.pc_cur = 32'h0000_8000;
        vif.reg_id.pc_4 = 32'h0000_8004;
        vif.reg_id.ins = 32'h0000_0063;

        vif.wb = '0;

        vif.for_info_ex.rd_addr = 5'd5;
        vif.for_info_ex.reg_en = 1'b1;
        vif.for_info_ex.mem_re = 1'b1;

        vif.for_info_mem = '0;

        vif.alu_ex = 32'h4444_4444;
        vif.alu_mem = '0;

        @(posedge vif.clk);
        #1;

        exp_jump = '0;
        exp_jump.br_en = 1'b1;
        exp_jump.br_taken = 1'b0;

        exp_hzd = '0;
        exp_hzd.stall_pc = 1'b1;
        exp_hzd.stall_if_id = 1'b1;
        exp_hzd.flush_id_ex = 1'b1;

        direct_check_jump("BRANCH LOAD EX", vif.jump, exp_jump);
        direct_check_hzd("BRANCH LOAD EX HAZARD", vif.hzd_ctrl, exp_hzd);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 11. BRANCH + LOAD IN MEM
    // ========================================================================

    task direct_branch_load_mem();

        jump_t exp_jump;
        hzd_ctrl_t exp_hzd;

        vif.reg_id.pc_cur = 32'h0000_9000;
        vif.reg_id.pc_4 = 32'h0000_9004;
        vif.reg_id.ins = 32'h0000_0063;

        vif.wb = '0;

        vif.for_info_ex = '0;

        vif.for_info_mem.rd_addr = 5'd5;
        vif.for_info_mem.reg_en = 1'b1;
        vif.for_info_mem.mem_re = 1'b1;

        vif.alu_ex = '0;
        vif.alu_mem = 32'h5555_5555;

        @(posedge vif.clk);
        #1;

        exp_jump = '0;
        exp_jump.br_en = 1'b1;
        exp_jump.br_taken = 1'b0;

        exp_hzd = '0;
        exp_hzd.stall_pc = 1'b1;
        exp_hzd.stall_if_id = 1'b1;
        exp_hzd.flush_id_ex = 1'b1;

        direct_check_jump("BRANCH LOAD MEM", vif.jump, exp_jump);
        direct_check_hzd("BRANCH LOAD MEM HAZARD", vif.hzd_ctrl, exp_hzd);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 12. JUMP + HAZARD
    // ========================================================================

    task direct_jump_hazard();

        jump_t exp_jump;
        hzd_ctrl_t exp_hzd;

        vif.reg_id.pc_cur = 32'h0000_A000;
        vif.reg_id.pc_4 = 32'h0000_A004;
        vif.reg_id.ins = 32'h0000_0067;

        vif.wb = '0;

        vif.for_info_ex.rd_addr = 5'd5;
        vif.for_info_ex.reg_en = 1'b1;
        vif.for_info_ex.mem_re = 1'b1;

        vif.for_info_mem = '0;

        vif.alu_ex = 32'h6666_6666;
        vif.alu_mem = '0;

        @(posedge vif.clk);
        #1;

        exp_jump = '0;
        exp_jump.jalr = 1'b1;

        exp_hzd = '0;
        exp_hzd.stall_pc = 1'b1;
        exp_hzd.stall_if_id = 1'b1;
        exp_hzd.flush_id_ex = 1'b1;
        exp_hzd.flush_if_id = 1'b0;

        direct_check_jump("JALR HAZARD", vif.jump, exp_jump);
        direct_check_hzd("JALR HAZARD", vif.hzd_ctrl, exp_hzd);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 13. X0 - NO HAZARD
    // ========================================================================

    task direct_x0();

        jump_t exp_jump;
        hzd_ctrl_t exp_hzd;

        vif.reg_id.pc_cur = 32'h0000_B000;
        vif.reg_id.pc_4 = 32'h0000_B004;
        vif.reg_id.ins = 32'h0000_0093;

        vif.wb = '0;

        vif.for_info_ex.rd_addr = 5'd0;
        vif.for_info_ex.reg_en = 1'b1;
        vif.for_info_ex.mem_re = 1'b1;

        vif.for_info_mem.rd_addr = 5'd0;
        vif.for_info_mem.reg_en = 1'b1;
        vif.for_info_mem.mem_re = 1'b1;

        vif.alu_ex = 32'hFFFF_FFFF;
        vif.alu_mem = 32'hAAAA_AAAA;

        @(posedge vif.clk);
        #1;

        exp_jump = '0;
        exp_hzd = '0;

        direct_check_hzd("X0 NO HAZARD", vif.hzd_ctrl, exp_hzd);

        direct_sample_cov();

    endtask

    // ========================================================================
    // DIRECT TEST SUITE
    // ========================================================================

    task run_direct_tests();

        $display("");
        $display("============================================================");
        $display("                  ID STAGE DIRECT TESTS");
        $display("============================================================");

        direct_idle();

        direct_normal();

        direct_jal();
        direct_jalr();

        direct_branch_not_taken();
        direct_branch_taken();

        direct_alu_forward_ex();
        direct_load_use_ex();
        direct_load_forward_mem();

        direct_branch_ex_hazard();
        direct_branch_load_ex();
        direct_branch_load_mem();

        direct_jump_hazard();

        direct_x0();

        $display("[DIRECT] PASS=%0d FAIL=%0d", direct_pass, direct_fail);

    endtask

    // ========================================================================
    // OOP RANDOM
    // ========================================================================

    task run_oop_test();

        $display("");
        $display("============================================================");
        $display("                   ID STAGE OOP TEST");
        $display("============================================================");

        env.run();

        repeat(5) @(posedge vif.clk);
        #1;

        $display("[OOP] Random generation completed.");

    endtask

    // ========================================================================
    // REPORT
    // ========================================================================

    task report();

        $display("");
        $display("============================================================");
        $display("                  ID STAGE FINAL REPORT");
        $display("============================================================");

        $display("[DIRECT] PASS=%0d FAIL=%0d", direct_pass, direct_fail);

        $display("[OOP] SCOREBOARD PASS=%0d FAIL=%0d",
                 env.scoreboard.pass_cnt,
                 env.scoreboard.fail_cnt);

        env.coverage.report();

        if ((direct_fail == 0) &&
            (env.scoreboard.fail_cnt == 0))
            $display("[FINAL] ID STAGE FUNCTIONAL CHECKING = PASS");
        else
            $display("[FINAL] ID STAGE FUNCTIONAL CHECKING = FAIL");

        $display("============================================================");

    endtask

    // ========================================================================
    // RUN
    // ========================================================================

    task run();

        run_direct_tests();
        run_oop_test();
        report();

    endtask

endclass

module tb_id_stage;

import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;

logic clk;
logic rst_n;

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// ============================================================
// Interface
// ============================================================

id_stage_if vif(clk);

// ============================================================
// DUT
// ============================================================

id_stage dut(
    .clk            (clk),
    .rst_n          (rst_n),
    .reg_id_i       (vif.reg_id),
    .wb_i           (vif.wb),
    .for_info_ex_i  (vif.for_info_ex),
    .for_info_mem_i (vif.for_info_mem),
    .alu_ex_i       (vif.alu_ex),
    .alu_mem_i      (vif.alu_mem),
    .jump_o         (vif.jump),
    .hzd_ctrl_o     (vif.hzd_ctrl),
    .id_reg_i       (vif.id_reg)
);

// ============================================================
// Waveform
// ============================================================

initial begin
    $dumpfile("id_stage.vcd");
    $dumpvars(0,tb_id_stage);
end

// ============================================================
// Test
// ============================================================

initial begin
    id_stage_test test;

    rst_n = 1'b0;

    test = new(vif,100);

    repeat(2) @(posedge clk);
    rst_n = 1'b1;

    test.run();

    $display("");
    $display("============================================================");
    $display("                 ID STAGE SIMULATION FINISHED");
    $display("============================================================");

    $finish;
end

// ============================================================
// Timeout
// ============================================================

initial begin
    #100000;

    $error("[TB] TIMEOUT");
    $finish;
end

endmodule