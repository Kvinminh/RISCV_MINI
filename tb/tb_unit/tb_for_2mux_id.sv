`timescale 1ns/1ps

import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;



module id_control
  import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input  logic [XLEN-1:0] rs1_data_i,
    input  logic [XLEN-1:0] rs2_data_i,
    input  logic [XLEN-1:0] alu_ex_i,
    input  logic [XLEN-1:0] alu_mem_i,
    input  for_sel_e        for_id_a_i,
    input  for_sel_e        for_id_b_i,
    input  b_type_f3_e      f3_i,
    input  logic            br_en_i,
    input  logic [XLEN-1:0] pc_cur_i,
    input  logic [XLEN-1:0] imm_out_i,
    input  logic            jalr_i,
    output logic [XLEN-1:0] compare_a_o,
    output logic [XLEN-1:0] compare_b_o,
    output logic            br_taken_o,
    output logic [XLEN-1:0] jump_a_o,
    output logic [XLEN-1:0] jump_b_o,
    output logic [XLEN-1:0] jump_addr_o
);

    mux_br_compare u_mux_br_compare (
        .rs1_data_i    (rs1_data_i),
        .rs2_data_i    (rs2_data_i),
        .alu_ex_i      (alu_ex_i),
        .alu_mem_i     (alu_mem_i),
        .for_id_a_i    (for_id_a_i),
        .for_id_b_i    (for_id_b_i),
        .compare_a_o   (compare_a_o),
        .compare_b_o   (compare_b_o)
    );

    br_compare u_br_compare (
        .compare_a_i   (compare_a_o),
        .compare_b_i   (compare_b_o),
        .f3_i          (f3_i),
        .br_en_i       (br_en_i),
        .br_taken_o    (br_taken_o)
    );

    mux_base_jump_adder u_mux_base_jump_adder (
        .rs1_data_i    (rs1_data_i),
        .pc_cur_i      (pc_cur_i),
        .imm_out_i     (imm_out_i),
        .jalr_i        (jalr_i),
        .alu_ex_i      (alu_ex_i),
        .alu_mem_i     (alu_mem_i),
        .for_id_a_i    (for_id_a_i),
        .jump_a_o      (jump_a_o),
        .jump_b_o      (jump_b_o)
    );

    jump_adder u_jump_adder (
        .jump_a_i      (jump_a_o),
        .jump_b_i      (jump_b_o),
        .jump_adder_o  (jump_addr_o)
    );

endmodule

interface control_if (input logic clk);

    // =========================================================
    // INPUT
    // =========================================================

    logic [XLEN-1:0] rs1_data;
    logic [XLEN-1:0] rs2_data;
    logic [XLEN-1:0] pc_cur;
    logic [XLEN-1:0] imm_out;

    logic [XLEN-1:0] alu_ex;
    logic [XLEN-1:0] alu_mem;

    b_type_f3_e f3;
    logic       br_en;
    logic       jalr;

    for_sel_e for_id_a;
    for_sel_e for_id_b;

    // =========================================================
    // OUTPUT
    // =========================================================

    logic [XLEN-1:0] compare_a;
    logic [XLEN-1:0] compare_b;

    logic [XLEN-1:0] jump_a;
    logic [XLEN-1:0] jump_b;

    logic [XLEN-1:0] jump_adder;

    logic br_taken;

    // =========================================================
    // DRIVER CLOCKING BLOCK
    // =========================================================

    clocking drv_cb @(posedge clk);
        default input #1step output #1;

        output rs1_data;
        output rs2_data;
        output pc_cur;
        output imm_out;

        output alu_ex;
        output alu_mem;

        output f3;
        output br_en;
        output jalr;

        output for_id_a;
        output for_id_b;
    endclocking

    // =========================================================
    // MONITOR CLOCKING BLOCK
    // =========================================================

    clocking mon_cb @(posedge clk);
        default input #1step output #1;

        input rs1_data;
        input rs2_data;
        input pc_cur;
        input imm_out;

        input alu_ex;
        input alu_mem;

        input f3;
        input br_en;
        input jalr;

        input for_id_a;
        input for_id_b;

        input compare_a;
        input compare_b;

        input jump_a;
        input jump_b;

        input jump_adder;
        input br_taken;
    endclocking

    // =========================================================
    // MODPORT
    // =========================================================

    modport DRV ( clocking drv_cb, input clk);
    modport MON ( clocking mon_cb, input clk);


endinterface


class control_transaction;

    // =========================================================
    // INPUT
    // =========================================================

    rand bit [XLEN-1:0] rs1_data;
    rand bit [XLEN-1:0] rs2_data;
    rand bit [XLEN-1:0] pc_cur;
    rand bit [XLEN-1:0] imm_out;
    rand bit [XLEN-1:0] alu_ex;
    rand bit [XLEN-1:0] alu_mem;

    rand b_type_f3_e f3;
    rand bit br_en;
    rand bit jalr;

    rand for_sel_e for_id_a;
    rand for_sel_e for_id_b;

    // =========================================================
    // DUT OUTPUT
    // =========================================================

    logic [XLEN-1:0] compare_a;
    logic [XLEN-1:0] compare_b;
    logic [XLEN-1:0] jump_a;
    logic [XLEN-1:0] jump_b;
    logic [XLEN-1:0] jump_adder;
    logic br_taken;

    // =========================================================
    // REFERENCE MODEL
    // =========================================================

    logic [XLEN-1:0] expected_compare_a;
    logic [XLEN-1:0] expected_compare_b;
    logic [XLEN-1:0] expected_jump_a;
    logic [XLEN-1:0] expected_jump_b;
    logic [XLEN-1:0] expected_jump_adder;
    logic expected_br_taken;

    // =========================================================
    // CONSTRAINT
    // =========================================================

    constraint c_basic {
        pc_cur % 4 == 0;

        for_id_a inside {
            RS1_DATA_ID,
            RD_DATA_EX,
            RD_DATA_MEM
        };

        for_id_b inside {
            RS2_DATA_ID,
            RD_DATA_EX,
            RD_DATA_MEM
        };
    }

    constraint c_rs1 {
        rs1_data dist {
            32'h0000_0000 := 10,
            32'h0000_0001 := 5,
            32'h7FFF_FFFF := 5,
            32'h8000_0000 := 5,
            32'hFFFF_FFFF := 5,
            [32'h0000_0002:32'hFFFF_FFFE] := 70
        };
    }

    constraint c_rs2 {
        rs2_data dist {
            32'h0000_0000 := 10,
            32'h0000_0001 := 5,
            32'h7FFF_FFFF := 5,
            32'h8000_0000 := 5,
            32'hFFFF_FFFF := 5,
            [32'h0000_0002:32'hFFFF_FFFE] := 70
        };
    }

    constraint c_imm {
        imm_out dist {
            32'h0000_0000 := 10,
            32'h0000_0001 := 5,
            32'hFFFF_FFFF := 5,
            [32'h0000_0002:32'hFFFF_FFFE] := 80
        };
    }

    constraint c_alu {
        alu_ex dist {
            32'h0000_0000 := 10,
            32'hFFFF_FFFF := 5,
            [32'h0000_0001:32'hFFFF_FFFE] := 85
        };

        alu_mem dist {
            32'h0000_0000 := 10,
            32'hFFFF_FFFF := 5,
            [32'h0000_0001:32'hFFFF_FFFE] := 85
        };
    }

    constraint c_f3 {
        f3 inside {
            F3_BEQ,
            F3_BNE,
            F3_BLT,
            F3_BGE,
            F3_BLTU,
            F3_BGEU
        };
    }

    constraint c_control {
        br_en dist {
            1 := 80,
            0 := 20
        };

        jalr dist {
            0 := 50,
            1 := 50
        };
    }

    // =========================================================
    // COPY
    // =========================================================

    function void copy(control_transaction rhs);
        if (rhs == null) return;

        rs1_data = rhs.rs1_data;
        rs2_data = rhs.rs2_data;
        pc_cur   = rhs.pc_cur;
        imm_out  = rhs.imm_out;
        alu_ex   = rhs.alu_ex;
        alu_mem  = rhs.alu_mem;

        f3       = rhs.f3;
        br_en    = rhs.br_en;
        jalr     = rhs.jalr;

        for_id_a = rhs.for_id_a;
        for_id_b = rhs.for_id_b;
    endfunction

    // =========================================================
    // CLONE
    // =========================================================

    function control_transaction clone();
        control_transaction t = new();
        t.copy(this);
        return t;
    endfunction

    // =========================================================
    // DISPLAY
    // =========================================================

    function string convert2string();
        return $sformatf("RS1=%08h RS2=%08h PC=%08h IMM=%08h EX=%08h MEM=%08h F3=%0d BR_EN=%0d JALR=%0d FOR_A=%0d FOR_B=%0d | CMP_A=%08h CMP_B=%08h BR_TAKEN=%0d | JUMP_A=%08h JUMP_B=%08h JUMP=%08h", rs1_data, rs2_data, pc_cur, imm_out, alu_ex, alu_mem, f3, br_en, jalr, for_id_a, for_id_b, compare_a, compare_b, br_taken, jump_a, jump_b, jump_adder);
    endfunction

endclass

class control_generator;
    mailbox #(control_transaction) gen2drv;
    int num_txn;
    event done;

    function new ( 
        mailbox #( control_transaction ) gen2drv,
        int num_txn
                );
                    this.gen2drv = gen2drv;
                    this.num_txn = num_txn;
    endfunction

    task run();
        control_transaction txn;
        repeat ( num_txn) begin
            txn = new();
            if(txn.randomize() == 0) 
              $fatal(1, "[GEN] IF transaction randomization failed");
            gen2drv.put(txn);
        end
        -> done;
    endtask
endclass

class control_driver;

    virtual control_if.DRV vif;
    mailbox #(control_transaction) gen2drv;

    function new(
        virtual control_if.DRV vif,
        mailbox #(control_transaction) gen2drv
    );
        this.vif = vif;
        this.gen2drv = gen2drv;
    endfunction

    task reset_dut();
        vif.rs1_data = '0;
        vif.rs2_data = '0;
        vif.pc_cur   = '0;
        vif.imm_out  = '0;

        vif.alu_ex  = '0;
        vif.alu_mem = '0;

        vif.f3 = F3_BEQ;
        vif.br_en = 1'b0;
        vif.jalr = 1'b0;

        vif.for_id_a = RS1_DATA_ID;
        vif.for_id_b = RS2_DATA_ID;
        repeat(3) @(negedge vif.clk);
    endtask

    task run();
        control_transaction txn;
        forever begin
            gen2drv.get(txn);

            @(negedge vif.clk);
            vif.rs1_data = txn.rs1_data;
            vif.rs2_data = txn.rs2_data;
            vif.pc_cur   = txn.pc_cur;
            vif.imm_out  = txn.imm_out;

            vif.alu_ex  = txn.alu_ex;
            vif.alu_mem = txn.alu_mem;

            vif.f3    = txn.f3;
            vif.br_en = txn.br_en;
            vif.jalr  = txn.jalr;

            vif.for_id_a = txn.for_id_a;
            vif.for_id_b = txn.for_id_b;
        end
    endtask
endclass


class control_ref_model;

    bit [XLEN-1:0] model_rs1_data;
    bit [XLEN-1:0] model_rs2_data;
    bit [XLEN-1:0] model_pc_cur;
    bit [XLEN-1:0] model_imm_out;
    bit [XLEN-1:0] model_alu_ex;
    bit [XLEN-1:0] model_alu_mem;

    bit [XLEN-1:0] model_compare_a;
    bit [XLEN-1:0] model_compare_b;
    bit [XLEN-1:0] model_jump_a;
    bit [XLEN-1:0] model_jump_b;
    bit [XLEN-1:0] model_jump_adder;
    bit model_br_taken;

    function void predict(input control_transaction txn);

        bit equal;
        bit less_signed;
        bit less_unsigned;
        bit  [XLEN-1:0] model_rs1_fwd;

        model_rs1_data = txn.rs1_data;
        model_rs2_data = txn.rs2_data;
        model_pc_cur   = txn.pc_cur;
        model_imm_out  = txn.imm_out;
        model_alu_ex   = txn.alu_ex;
        model_alu_mem  = txn.alu_mem;


        // =====================================================
        // 1. BRANCH COMPARE FORWARD
        // =====================================================

        case (txn.for_id_a)
            RD_DATA_EX:  model_compare_a = model_alu_ex;
            RD_DATA_MEM: model_compare_a = model_alu_mem;
            default:     model_compare_a = model_rs1_data;
        endcase

        case (txn.for_id_b)
            RD_DATA_EX:  model_compare_b = model_alu_ex;
            RD_DATA_MEM: model_compare_b = model_alu_mem;
            default:     model_compare_b = model_rs2_data;
        endcase

        txn.expected_compare_a = model_compare_a;
        txn.expected_compare_b = model_compare_b;

        // =====================================================
        // 2. BRANCH COMPARE
        // =====================================================

        equal         = (model_compare_a == model_compare_b);
        less_signed   = ($signed(model_compare_a) < $signed(model_compare_b));
        less_unsigned = (model_compare_a < model_compare_b);

        case (txn.f3)
            F3_BEQ:  model_br_taken = equal;
            F3_BNE:  model_br_taken = !equal;
            F3_BLT:  model_br_taken = less_signed;
            F3_BGE:  model_br_taken = !less_signed;
            F3_BLTU: model_br_taken = less_unsigned;
            F3_BGEU: model_br_taken = !less_unsigned;
            default: model_br_taken = 1'b0;
        endcase

        model_br_taken = txn.br_en && model_br_taken;

        txn.expected_br_taken = model_br_taken;

        // =====================================================
        // 3. JUMP BASE MUX
        // =====================================================

        case (txn.for_id_a)
            RD_DATA_EX:
                model_rs1_fwd = model_alu_ex;

            RD_DATA_MEM:
                model_rs1_fwd = model_alu_mem;

            default:
                model_rs1_fwd = model_rs1_data;
        endcase

            if (txn.jalr)
                model_jump_a = model_rs1_fwd;
            else
                model_jump_a = model_pc_cur;

        // =====================================================
        // 4. JUMP IMM
        // =====================================================

        model_jump_b = model_imm_out;

        // =====================================================
        // 5. JUMP ADDER
        // =====================================================

        model_jump_adder = model_jump_a + model_jump_b;

        txn.expected_jump_a     = model_jump_a;
        txn.expected_jump_b     = model_jump_b;
        txn.expected_jump_adder = model_jump_adder;
    endfunction
endclass

class control_monitor;

    virtual control_if.MON vif;
    mailbox #(control_transaction) mon2sb;
    mailbox #(control_transaction) mon2cov;
    control_ref_model ref_model;

    int num_txn;
    event done;

    function new(
        virtual control_if.MON vif,
        mailbox #(control_transaction) mon2sb,
        mailbox #(control_transaction) mon2cov,
        control_ref_model ref_model,
        int num_txn
    );
        this.vif = vif;
        this.mon2sb = mon2sb;
        this.mon2cov = mon2cov;
        this.ref_model = ref_model;
        this.num_txn = num_txn;
    endfunction

    task run();
        control_transaction txn;
        for (int i = 0; i < num_txn; i++) begin
            @(posedge vif.clk);
            #1;

            txn = new();
            // =================================================
            // INPUT
            // =================================================

            txn.rs1_data = vif.mon_cb.rs1_data;
            txn.rs2_data = vif.mon_cb.rs2_data;
            txn.pc_cur   = vif.mon_cb.pc_cur;
            txn.imm_out  = vif.mon_cb.imm_out;

            txn.alu_ex  = vif.mon_cb.alu_ex;
            txn.alu_mem = vif.mon_cb.alu_mem;

            txn.f3    = vif.mon_cb.f3;
            txn.br_en = vif.mon_cb.br_en;
            txn.jalr  = vif.mon_cb.jalr;

            txn.for_id_a = vif.mon_cb.for_id_a;
            txn.for_id_b = vif.mon_cb.for_id_b;

            // =================================================
            // DUT OUTPUT
            // =================================================

            txn.compare_a = vif.mon_cb.compare_a;
            txn.compare_b = vif.mon_cb.compare_b;

            txn.jump_a = vif.mon_cb.jump_a;
            txn.jump_b = vif.mon_cb.jump_b;

            txn.jump_adder = vif.mon_cb.jump_adder;
            txn.br_taken   = vif.mon_cb.br_taken;

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

class control_scoreboard;

    mailbox #(control_transaction) mon2sb;

    int pass_cnt = 0;
    int fail_cnt = 0;

    function new(mailbox #(control_transaction) mon2sb);
        this.mon2sb = mon2sb;
    endfunction

    task run();

        control_transaction txn;

        forever begin
            mon2sb.get(txn);

            // =========================================================
            // 1. MUX BR COMPARE - A
            // =========================================================

            if (txn.compare_a === txn.expected_compare_a)
                pass_cnt++;
            else begin
                fail_cnt++;

                $error("[SB][FAIL] COMPARE_A\nACTUAL=%08h EXPECTED=%08h\nRS1_DATA=%08h\nFOR_A=%0d\nALU_EX=%08h ALU_MEM=%08h",
                    txn.compare_a,
                    txn.expected_compare_a,
                    txn.rs1_data,
                    txn.for_id_a,
                    txn.alu_ex,
                    txn.alu_mem);
            end

            // =========================================================
            // 2. MUX BR COMPARE - B
            // =========================================================

            if (txn.compare_b === txn.expected_compare_b)
                pass_cnt++;
            else begin
                fail_cnt++;

                $error("[SB][FAIL] COMPARE_B\nACTUAL=%08h EXPECTED=%08h\nRS2_DATA=%08h\nFOR_B=%0d\nALU_EX=%08h ALU_MEM=%08h",
                        txn.compare_b,
                        txn.expected_compare_b,
                        txn.rs2_data,
                        txn.for_id_b,
                        txn.alu_ex,
                        txn.alu_mem);
            end

            // =========================================================
            // 3. BRANCH COMPARE / BR TAKEN
            // =========================================================

            if (txn.br_taken === txn.expected_br_taken)
                pass_cnt++;
            else begin
                fail_cnt++;

                $error("[SB][FAIL] BR_TAKEN\nACTUAL=%0b EXPECTED=%0b\nCOMPARE_A=%08h COMPARE_B=%08h\nF3=%0d BR_EN=%0b",
                    txn.br_taken,
                    txn.expected_br_taken,
                    txn.compare_a,
                    txn.compare_b,
                    txn.f3,
                    txn.br_en);
            end

            // =========================================================
            // 4. JUMP MUX - A
            // =========================================================

            if (txn.jump_a === txn.expected_jump_a)
                pass_cnt++;
            else begin
                fail_cnt++;

                $error("[SB][FAIL] JUMP_A\nACTUAL=%08h EXPECTED=%08h\nRS1=%08h PC=%08h\nIMM=%08h JALR=%0b\nFOR_A=%0d\nALU_EX=%08h ALU_MEM=%08h",
                    txn.jump_a,
                    txn.expected_jump_a,
                    txn.rs1_data,
                    txn.pc_cur,
                    txn.imm_out,
                    txn.jalr,
                    txn.for_id_a,
                    txn.alu_ex,
                    txn.alu_mem);
            end

            // =========================================================
            // 5. JUMP MUX - B
            // =========================================================

            if (txn.jump_b === txn.expected_jump_b)
                pass_cnt++;
            else begin
                fail_cnt++;

                $error("[SB][FAIL] JUMP_B\nACTUAL=%08h EXPECTED=%08h\nIMM=%08h",
                    txn.jump_b,
                    txn.expected_jump_b,
                    txn.imm_out);
            end

            // =========================================================
            // 6. JUMP ADDER
            // =========================================================

            if (txn.jump_adder === txn.expected_jump_adder)
                pass_cnt++;
            else begin
                fail_cnt++;

                $error("[SB][FAIL] JUMP_ADDER\nACTUAL=%08h EXPECTED=%08h\nJUMP_A=%08h JUMP_B=%08h\nPC=%08h RS1=%08h IMM=%08h JALR=%0b FOR_A=%0d",
                    txn.jump_adder,
                    txn.expected_jump_adder,
                    txn.jump_a,
                    txn.jump_b,
                    txn.pc_cur,
                    txn.rs1_data,
                    txn.imm_out,
                    txn.jalr,
                    txn.for_id_a);
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

class control_coverage;

    mailbox #(control_transaction) mon2cov;

    // =========================================================
    // 1. BRANCH COMPARE
    // =========================================================

    covergroup cg_branch_compare with function sample(control_transaction t);

        cp_f3 : coverpoint t.f3 {
            bins beq  = {F3_BEQ};
            bins bne  = {F3_BNE};
            bins blt  = {F3_BLT};
            bins bge  = {F3_BGE};
            bins bltu = {F3_BLTU};
            bins bgeu = {F3_BGEU};
        }

        cp_br_en : coverpoint t.br_en {
            bins disabled = {0};
            bins enabled  = {1};
        }

        cp_br_taken : coverpoint t.br_taken {
            bins not_taken = {0};
            bins taken     = {1};
        }

        cp_equal : coverpoint (t.rs1_data == t.rs2_data) {
            bins equal     = {1};
            bins not_equal = {0};
        }

        cp_sign : coverpoint {t.rs1_data[31], t.rs2_data[31]} {
            bins positive_positive = {2'b00};
            bins positive_negative = {2'b01};
            bins negative_positive = {2'b10};
            bins negative_negative = {2'b11};
        }

        f3_taken : cross cp_f3, cp_br_taken;
        f3_equal : cross cp_f3, cp_equal;

    endgroup

    // =========================================================
    // 2. BRANCH VALUE
    // =========================================================

    covergroup cg_branch_value with function sample(control_transaction t);

        cp_rs1 : coverpoint t.rs1_data {
            bins zero     = {32'h0000_0000};
            bins one      = {32'h0000_0001};
            bins int_max  = {32'h7FFF_FFFF};
            bins int_min  = {32'h8000_0000};
            bins max      = {32'hFFFF_FFFF};
        }

        cp_rs2 : coverpoint t.rs2_data {
            bins zero     = {32'h0000_0000};
            bins one      = {32'h0000_0001};
            bins int_max  = {32'h7FFF_FFFF};
            bins int_min  = {32'h8000_0000};
            bins max      = {32'hFFFF_FFFF};
        }

        cp_equal : coverpoint (t.rs1_data == t.rs2_data) {
            bins equal     = {1};
            bins not_equal = {0};
        }

    endgroup

    // =========================================================
    // 3. FORWARD
    // =========================================================

    covergroup cg_forward with function sample(control_transaction t);

        cp_forward_a : coverpoint t.for_id_a {
            bins id  = {RS1_DATA_ID};
            bins ex  = {RD_DATA_EX};
            bins mem = {RD_DATA_MEM};
        }

        cp_forward_b : coverpoint t.for_id_b {
            bins id  = {RS2_DATA_ID};
            bins ex  = {RD_DATA_EX};
            bins mem = {RD_DATA_MEM};
        }

        cp_alu_ex : coverpoint t.alu_ex {
            bins zero    = {32'h0000_0000};
            bins one     = {32'h0000_0001};
            bins int_max = {32'h7FFF_FFFF};
            bins int_min = {32'h8000_0000};
            bins max     = {32'hFFFF_FFFF};
        }

        cp_alu_mem : coverpoint t.alu_mem {
            bins zero    = {32'h0000_0000};
            bins one     = {32'h0000_0001};
            bins int_max = {32'h7FFF_FFFF};
            bins int_min = {32'h8000_0000};
            bins max     = {32'hFFFF_FFFF};
        }

        forward_a_b : cross cp_forward_a, cp_forward_b;

    endgroup

    // =========================================================
    // 4. JUMP
    // =========================================================

    covergroup cg_jump with function sample(control_transaction t);

        cp_jalr : coverpoint t.jalr {
            bins jal  = {0};
            bins jalr = {1};
        }

        cp_imm : coverpoint t.imm_out {
            bins zero      = {32'h0000_0000};
            bins one       = {32'h0000_0001};
            bins minus_one = {32'hFFFF_FFFF};
        }

        cp_jump_result : coverpoint t.jump_adder {
            bins zero    = {32'h0000_0000};
            bins one     = {32'h0000_0001};
            bins int_max = {32'h7FFF_FFFF};
            bins int_min = {32'h8000_0000};
            bins max     = {32'hFFFF_FFFF};
        }

        jalr_imm : cross cp_jalr, cp_imm;

    endgroup

    // =========================================================
    // 5. JUMP MUX
    // =========================================================

    covergroup cg_jump_mux with function sample(control_transaction t);

        cp_jalr : coverpoint t.jalr {
            bins jal  = {0};
            bins jalr = {1};
        }

        cp_forward_a : coverpoint t.for_id_a {
            bins id  = {RS1_DATA_ID};
            bins ex  = {RD_DATA_EX};
            bins mem = {RD_DATA_MEM};
        }

        jalr_forward : cross cp_jalr, cp_forward_a;

    endgroup

    // =========================================================
    // 6. CROSS
    // =========================================================

    covergroup cg_cross with function sample(control_transaction t);

        cp_f3 : coverpoint t.f3 {
            bins beq  = {F3_BEQ};
            bins bne  = {F3_BNE};
            bins blt  = {F3_BLT};
            bins bge  = {F3_BGE};
            bins bltu = {F3_BLTU};
            bins bgeu = {F3_BGEU};
        }

        cp_forward_a : coverpoint t.for_id_a {
            bins id  = {RS1_DATA_ID};
            bins ex  = {RD_DATA_EX};
            bins mem = {RD_DATA_MEM};
        }

        cp_forward_b : coverpoint t.for_id_b {
            bins id  = {RS2_DATA_ID};
            bins ex  = {RD_DATA_EX};
            bins mem = {RD_DATA_MEM};
        }

        cp_jalr : coverpoint t.jalr {
            bins jal  = {0};
            bins jalr = {1};
        }

        branch_forward_a : cross cp_f3, cp_forward_a;
        branch_forward_b : cross cp_f3, cp_forward_b;
        forward_a_b      : cross cp_forward_a, cp_forward_b;
        jump_forward     : cross cp_jalr, cp_forward_a;
    endgroup

    // =========================================================
    // CONSTRUCTOR
    // =========================================================

    function new(mailbox #(control_transaction) mon2cov);
        this.mon2cov = mon2cov;

        cg_branch_compare = new();
        cg_branch_value   = new();
        cg_forward        = new();
        cg_jump           = new();
        cg_jump_mux       = new();
        cg_cross          = new();
    endfunction

    // =========================================================
    // RUN
    // =========================================================

    task run();
        control_transaction txn;
        forever begin
            mon2cov.get(txn);

            cg_branch_compare.sample(txn);
            cg_branch_value.sample(txn);
            cg_forward.sample(txn);
            cg_jump.sample(txn);
            cg_jump_mux.sample(txn);
            cg_cross.sample(txn);
        end
    endtask

    // =========================================================
    // REPORT
    // =========================================================

    function void report();
        $display("\n============================================================");
        $display("BRANCH / JUMP COVERAGE");
        $display("============================================================");
        $display("[COV] BRANCH COMPARE = %0.2f%%", cg_branch_compare.get_inst_coverage());
        $display("[COV] BRANCH VALUE   = %0.2f%%", cg_branch_value.get_inst_coverage());
        $display("[COV] FORWARD        = %0.2f%%", cg_forward.get_inst_coverage());
        $display("[COV] JUMP           = %0.2f%%", cg_jump.get_inst_coverage());
        $display("[COV] JUMP MUX       = %0.2f%%", cg_jump_mux.get_inst_coverage());
        $display("[COV] CROSS          = %0.2f%%", cg_cross.get_inst_coverage());
        $display("============================================================");
    endfunction

    // =========================================================
    // DIRECT SAMPLE
    // =========================================================

    function void sample_direct(control_transaction t);

        cg_branch_compare.sample(t);
        cg_branch_value.sample(t);
        cg_forward.sample(t);
        cg_jump.sample(t);
        cg_jump_mux.sample(t);
        cg_cross.sample(t);
    endfunction
endclass

class control_agent;
    virtual control_if vif;

    mailbox #(control_transaction) gen2drv;
    mailbox #(control_transaction) mon2sb;
    mailbox #(control_transaction) mon2cov;

    control_generator generator;
    control_driver driver;
    control_monitor monitor;
    control_ref_model ref_model;

    function new(
        virtual control_if vif,
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

class control_env;
    control_agent agent;
    control_scoreboard scoreboard;
    control_coverage coverage;

    function new(
        virtual control_if vif,
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


class control_test;

    virtual control_if vif;
    control_env env;

    int direct_pass = 0;
    int direct_fail = 0;
    int num_random_txn;

    function new(virtual control_if vif, int num_random_txn);
        this.vif = vif;
        this.num_random_txn = num_random_txn;
        env = new(vif, num_random_txn);
    endfunction

    // ========================================================================
    // DIRECT TEST
    // ========================================================================

    task direct_idle();
        vif.rs1_data = '0;
        vif.rs2_data = '0;
        vif.pc_cur = '0;
        vif.imm_out = '0;
        vif.alu_ex = '0;
        vif.alu_mem = '0;
        vif.f3 = F3_BEQ;
        vif.br_en = 1'b0;
        vif.jalr = 1'b0;
        vif.for_id_a = RS1_DATA_ID;
        vif.for_id_b = RS2_DATA_ID;
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

    // ========================================================================
    // DIRECT -> COVERAGE
    // ========================================================================

    task direct_sample_cov();
        control_transaction t = new();

        t.rs1_data = vif.rs1_data;
        t.rs2_data = vif.rs2_data;
        t.pc_cur = vif.pc_cur;
        t.imm_out = vif.imm_out;
        t.alu_ex = vif.alu_ex;
        t.alu_mem = vif.alu_mem;

        t.f3 = vif.f3;
        t.br_en = vif.br_en;
        t.jalr = vif.jalr;

        t.for_id_a = vif.for_id_a;
        t.for_id_b = vif.for_id_b;

        t.compare_a = vif.compare_a;
        t.compare_b = vif.compare_b;
        t.jump_a = vif.jump_a;
        t.jump_b = vif.jump_b;
        t.jump_adder = vif.jump_adder;
        t.br_taken = vif.br_taken;

        env.coverage.sample_direct(t);
    endtask

    // ========================================================================
    // 1. BEQ - EQUAL
    // ========================================================================

    task direct_beq_equal();

        vif.rs1_data = 32'h1234_5678;
        vif.rs2_data = 32'h1234_5678;
        vif.f3 = F3_BEQ;
        vif.br_en = 1'b1;
        vif.for_id_a = RS1_DATA_ID;
        vif.for_id_b = RS2_DATA_ID;

        @(posedge vif.clk);
        #1;

        direct_check_bit("BEQ EQUAL", vif.br_taken, 1'b1);
        direct_sample_cov();

    endtask

    // ========================================================================
    // 2. BEQ - NOT EQUAL
    // ========================================================================

    task direct_beq_not_equal();

        vif.rs1_data = 32'h1234_5678;
        vif.rs2_data = 32'h8765_4321;
        vif.f3 = F3_BEQ;
        vif.br_en = 1'b1;

        @(posedge vif.clk);
        #1;

        direct_check_bit("BEQ NOT EQUAL", vif.br_taken, 1'b0);
        direct_sample_cov();

    endtask

    // ========================================================================
    // 3. BNE - EQUAL
    // ========================================================================

    task direct_bne_equal();

        vif.rs1_data = 32'hAAAA_AAAA;
        vif.rs2_data = 32'hAAAA_AAAA;
        vif.f3 = F3_BNE;
        vif.br_en = 1'b1;

        @(posedge vif.clk);
        #1;

        direct_check_bit("BNE EQUAL", vif.br_taken, 1'b0);
        direct_sample_cov();

    endtask

    // ========================================================================
    // 4. BLT - SIGNED BOUNDARY
    // ========================================================================

    task direct_blt_signed_boundary();

        vif.rs1_data = 32'h8000_0000;
        vif.rs2_data = 32'h0000_0000;
        vif.f3 = F3_BLT;
        vif.br_en = 1'b1;

        @(posedge vif.clk);
        #1;

        direct_check_bit("BLT INT_MIN < 0", vif.br_taken, 1'b1);
        direct_sample_cov();

    endtask

    // ========================================================================
    // 5. BGE - SIGNED BOUNDARY
    // ========================================================================

    task direct_bge_signed_boundary();

        vif.rs1_data = 32'h7FFF_FFFF;
        vif.rs2_data = 32'h8000_0000;
        vif.f3 = F3_BGE;
        vif.br_en = 1'b1;

        @(posedge vif.clk);
        #1;

        direct_check_bit("BGE INT_MAX >= INT_MIN", vif.br_taken, 1'b1);
        direct_sample_cov();

    endtask

    // ========================================================================
    // 6. BLTU - UNSIGNED BOUNDARY
    // ========================================================================

    task direct_bltu_unsigned_boundary();

        vif.rs1_data = 32'h0000_0000;
        vif.rs2_data = 32'hFFFF_FFFF;
        vif.f3 = F3_BLTU;
        vif.br_en = 1'b1;

        @(posedge vif.clk);
        #1;

        direct_check_bit("BLTU 0 < UINT_MAX", vif.br_taken, 1'b1);
        direct_sample_cov();

    endtask

    // ========================================================================
    // 7. BGEU - UNSIGNED BOUNDARY
    // ========================================================================

    task direct_bgeu_unsigned_boundary();

        vif.rs1_data = 32'hFFFF_FFFF;
        vif.rs2_data = 32'h0000_0000;
        vif.f3 = F3_BGEU;
        vif.br_en = 1'b1;

        @(posedge vif.clk);
        #1;

        direct_check_bit("BGEU UINT_MAX >= 0", vif.br_taken, 1'b1);
        direct_sample_cov();

    endtask

    // ========================================================================
    // 8. BR_EN = 0
    // ========================================================================

    task direct_branch_disable();

        vif.rs1_data = 32'h1111_1111;
        vif.rs2_data = 32'h1111_1111;
        vif.f3 = F3_BEQ;
        vif.br_en = 1'b0;

        @(posedge vif.clk);
        #1;

        direct_check_bit("BR_EN=0", vif.br_taken, 1'b0);
        direct_sample_cov();

    endtask

    // ========================================================================
    // 9. JAL -> PC + IMM
    // ========================================================================

    task direct_jal();

        vif.pc_cur = 32'h0000_1000;
        vif.imm_out = 32'h0000_0100;
        vif.jalr = 1'b0;

        @(posedge vif.clk);
        #1;

        direct_check("JAL JUMP_A", vif.jump_a, 32'h0000_1000);
        direct_check("JAL JUMP_B", vif.jump_b, 32'h0000_0100);
        direct_check("JAL TARGET", vif.jump_adder, 32'h0000_1100);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 10. JALR -> RS1 + IMM
    // ========================================================================

    task direct_jalr();

        vif.rs1_data = 32'h0000_2000;
        vif.pc_cur = 32'h0000_1000;
        vif.imm_out = 32'h0000_0020;
        vif.jalr = 1'b1;
        vif.for_id_a = RS1_DATA_ID;

        @(posedge vif.clk);
        #1;

        direct_check("JALR JUMP_A", vif.jump_a, 32'h0000_2000);
        direct_check("JALR JUMP_B", vif.jump_b, 32'h0000_0020);
        direct_check("JALR TARGET", vif.jump_adder, 32'h0000_2020);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 11. JALR + EX FORWARD
    // ========================================================================

    task direct_jalr_ex_forward();

        vif.rs1_data = 32'h0000_1111;
        vif.alu_ex = 32'h0000_3000;
        vif.imm_out = 32'h0000_0020;
        vif.jalr = 1'b1;
        vif.for_id_a = RD_DATA_EX;

        @(posedge vif.clk);
        #1;

        direct_check("JALR EX FORWARD A", vif.jump_a, 32'h0000_3000);
        direct_check("JALR EX FORWARD TARGET", vif.jump_adder, 32'h0000_3020);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 12. JALR + MEM FORWARD
    // ========================================================================

    task direct_jalr_mem_forward();

        vif.rs1_data = 32'h0000_1111;
        vif.alu_mem = 32'h0000_4000;
        vif.imm_out = 32'h0000_0020;
        vif.jalr = 1'b1;
        vif.for_id_a = RD_DATA_MEM;

        @(posedge vif.clk);
        #1;

        direct_check("JALR MEM FORWARD A", vif.jump_a, 32'h0000_4000);
        direct_check("JALR MEM FORWARD TARGET", vif.jump_adder, 32'h0000_4020);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 13. MEM PRIORITY
    // ========================================================================

    task direct_mem_priority();

        vif.rs1_data = 32'h0000_1111;
        vif.alu_ex = 32'h0000_2000;
        vif.alu_mem = 32'h0000_3000;

        vif.for_id_a = RD_DATA_MEM;
        vif.jalr = 1'b1;
        vif.imm_out = 32'h0000_0010;

        @(posedge vif.clk);
        #1;

        direct_check("MEM FORWARD PRIORITY", vif.jump_a, 32'h0000_3000);
        direct_check("MEM FORWARD TARGET", vif.jump_adder, 32'h0000_3010);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 14. X0 - NO FORWARD
    // ========================================================================

    task direct_x0();

        vif.rs1_data = 32'h0000_0000;
        vif.alu_ex = 32'hFFFF_FFFF;
        vif.alu_mem = 32'hAAAA_AAAA;

        vif.for_id_a = RS1_DATA_ID;
        vif.jalr = 1'b1;
        vif.imm_out = 32'h0000_0010;

        @(posedge vif.clk);
        #1;

        direct_check("X0 NO FORWARD", vif.jump_a, 32'h0000_0000);
        direct_check("X0 TARGET", vif.jump_adder, 32'h0000_0010);

        direct_sample_cov();

    endtask

    // ========================================================================
    // 15. JUMP OFFSET BOUNDARY
    // ========================================================================

    task direct_jump_offset_boundary();

        // Positive offset
        vif.pc_cur = 32'h0000_1000;
        vif.imm_out = 32'h0000_0004;
        vif.jalr = 1'b0;

        @(posedge vif.clk);
        #1;

        direct_check("JUMP OFFSET +4", vif.jump_adder, 32'h0000_1004);
        direct_sample_cov();

        // Negative offset
        vif.pc_cur = 32'h0000_1000;
        vif.imm_out = 32'hFFFF_FFFC;
        vif.jalr = 1'b0;

        @(posedge vif.clk);
        #1;

        direct_check("JUMP OFFSET -4", vif.jump_adder, 32'h0000_0FFC);
        direct_sample_cov();

    endtask

    // ========================================================================
    // DIRECT TEST SUITE
    // ========================================================================

    task run_direct_tests();

        $display("");
        $display("============================================================");
        $display("             DIRECT BRANCH/JUMP TESTS");
        $display("============================================================");

        direct_idle();

        direct_beq_equal();
        direct_beq_not_equal();
        direct_bne_equal();

        direct_blt_signed_boundary();
        direct_bge_signed_boundary();
        direct_bltu_unsigned_boundary();
        direct_bgeu_unsigned_boundary();

        direct_branch_disable();

        direct_jal();
        direct_jalr();

        direct_jalr_ex_forward();
        direct_jalr_mem_forward();
        direct_mem_priority();

        direct_x0();

        direct_jump_offset_boundary();

        $display("[DIRECT] PASS=%0d FAIL=%0d", direct_pass, direct_fail);

    endtask

    // ========================================================================
    // OOP RANDOM TEST
    // ========================================================================

    task run_oop_test();

        $display("");
        $display("============================================================");
        $display("              OOP RANDOM BRANCH/JUMP TEST");
        $display("============================================================");

        direct_idle();

        env.run();

        repeat(5) @(posedge vif.clk);
        #1;

        $display("[OOP] Random generation completed.");

    endtask

    // ========================================================================
    // FINAL REPORT
    // ========================================================================

    task report();

        $display("");
        $display("============================================================");
        $display("             BRANCH/JUMP FINAL REPORT");
        $display("============================================================");

        $display("[DIRECT] PASS=%0d FAIL=%0d",
                 direct_pass,
                 direct_fail);

        $display("[OOP] SCOREBOARD PASS=%0d FAIL=%0d",
                 env.scoreboard.pass_cnt,
                 env.scoreboard.fail_cnt);

        env.coverage.report();

        if ((direct_fail == 0) &&
            (env.scoreboard.fail_cnt == 0))
            $display("[FINAL] FUNCTIONAL CHECKING = PASS");
        else
            $display("[FINAL] FUNCTIONAL CHECKING = FAIL");

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


module tb_id_control;

    import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;

    logic clk;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Interface
    // ------------------------------------------------------------

    control_if vif(clk);

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    id_control dut (
        .rs1_data_i   (vif.rs1_data),
        .rs2_data_i   (vif.rs2_data),
        .alu_ex_i     (vif.alu_ex),
        .alu_mem_i    (vif.alu_mem),
        .for_id_a_i   (vif.for_id_a),
        .for_id_b_i   (vif.for_id_b),
        .f3_i         (vif.f3),
        .br_en_i      (vif.br_en),
        .pc_cur_i     (vif.pc_cur),
        .imm_out_i    (vif.imm_out),
        .jalr_i       (vif.jalr),
        .compare_a_o  (vif.compare_a),
        .compare_b_o  (vif.compare_b),
        .br_taken_o   (vif.br_taken),
        .jump_a_o     (vif.jump_a),
        .jump_b_o     (vif.jump_b),
        .jump_addr_o  (vif.jump_adder)
    );

    // ------------------------------------------------------------
    // Waveform
    // ------------------------------------------------------------

    initial begin
        $dumpfile("id_control.vcd");
        $dumpvars(0,tb_id_control);
    end

    // ------------------------------------------------------------
    // Test
    // ------------------------------------------------------------

    initial begin
        control_test test;

        test = new(vif,100);

        test.run();

        $display("");
        $display("============================================================");
        $display("              ID CONTROL SIMULATION FINISHED");
        $display("============================================================");

        $finish;
    end

    // ------------------------------------------------------------
    // Timeout
    // ------------------------------------------------------------

    initial begin
        #100000;

        $error("[TB] TIMEOUT");
        $finish;
    end

endmodule
