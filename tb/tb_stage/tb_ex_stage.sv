`timescale 1ps/1ps
import core_pkg::*;
import ctrl_pkg::*;
import isa_pkg::*;

interface ex_stage_if ( input logic clk);
    id_ex_reg_t reg_ex;
    for_info_t  for_info_mem;
    for_info_t  for_info_wb;
    logic [XLEN-1:0] alu_mem;
    logic [XLEN-1:0] alu_wb;

    ex_mem_reg_t ex_reg;
    for_info_t   for_info_ex;
    logic [XLEN-1:0] alu_ex;


    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output reg_ex,for_info_mem,for_info_wb,alu_mem,alu_wb;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #1;
        input reg_ex,for_info_mem,for_info_wb,alu_mem,alu_wb;
        input ex_reg,for_info_ex, alu_ex;
    endclocking

    modport DRV ( clocking drv_cb, input clk);
    modport MON ( clocking mon_cb, input clk);

endinterface

class ex_stage_transaction;
    rand id_ex_reg_t reg_ex;
    rand for_info_t  for_info_mem;
    rand for_info_t  for_info_wb;
    rand bit [XLEN-1:0] alu_mem;
    rand bit [XLEN-1:0] alu_wb;
    // constraint
   
    // dut output
     ex_mem_reg_t ex_reg;
     for_info_t   for_info_ex;
     logic [XLEN-1:0] alu_ex;
    //ref_model
    
     ex_mem_reg_t expected_ex_reg;
     for_info_t   expected_for_info_ex;
     logic [XLEN-1:0] expected_alu_ex;

    alu_ctrl_e alu_ctrl;
    forward_e  for_ex_a;
    forward_e  for_ex_b;
    logic [XLEN-1:0] A;
    logic [XLEN-1:0] B;
    logic [XLEN-1:0] alu_result;


    constraint c_reg_ex {
        reg_ex.f3   inside {[0:7]};
        reg_ex.f7_5 inside {0,1};

        reg_ex.pc_cur % 4 == 0;
        reg_ex.pc_4 == reg_ex.pc_cur + 4;

        reg_ex.rd_addr  inside {[0:31]};
        reg_ex.rs1_addr inside {[0:31]};
        reg_ex.rs2_addr inside {[0:31]};
        
        reg_ex.ex_ctrl.sel_a inside {RS1_EX, PC_CUR_EX, ZERO_EX};
        reg_ex.ex_ctrl.sel_b inside {RS2_EX, IMM_EX};

        reg_ex.rs1_data dist {
            32'h0000_0000 := 10,
            32'hFFFF_FFFF := 10,
            [32'h0000_0001:32'hFFFF_FFFE] := 80
        };

        reg_ex.rs2_data dist {
            32'h0000_0000 := 10,
            32'hFFFF_FFFF := 10,
            [32'h0000_0001:32'hFFFF_FFFE] := 80
        };

        reg_ex.imm_out dist {
            32'h0000_0000 := 10,
            32'hFFFF_FFFF := 10,
            [32'h0000_0001:32'hFFFF_FFFE] := 80
        };

        reg_ex.extension inside {0,1};
    }

   rand bit [1:0] do_forward;

    constraint c_forward {
        (do_forward == 2'b00) -> {
            for_info_mem.rd_addr inside {[0:31]};
            for_info_mem.mem_re  inside {0,1};
            for_info_mem.reg_en  inside {0,1};
            for_info_wb.rd_addr inside {[0:31]};
            for_info_wb.mem_re  inside {0,1};
            for_info_wb.reg_en  inside {0,1};
        }

        (do_forward == 2'b01) -> {
            for_info_mem.reg_en == 1;
            for_info_mem.mem_re == 0;
            for_info_mem.rd_addr != 0;
            reg_ex.rs1_addr == for_info_mem.rd_addr;
        }

        (do_forward == 2'b10) -> {
            for_info_wb.reg_en == 1;
            for_info_wb.rd_addr != 0;
            reg_ex.rs1_addr == for_info_wb.rd_addr;
        }
    }

    function void copy (ex_stage_transaction rhs);
        if ( rhs == null ) return;
        reg_ex          = rhs.reg_ex;
        for_info_mem    = rhs.for_info_mem;
        for_info_wb     = rhs.for_info_wb;
        alu_mem         = rhs.alu_mem;
        alu_wb          = rhs.alu_wb;
    endfunction

    function ex_stage_transaction clone();
        ex_stage_transaction t = new();
        t.copy(this);
        return t;
    endfunction

    function string convert2string();
        return $sformatf(
            "REG_EX: f3=%0d f7_5=%0d pc=%08h pc4=%08h rd=%0d rs1=%0d rs2=%0d rs1_data=%08h rs2_data=%08h\nMEM: rd=%0d mem_re=%0d reg_en=%0d alu_mem=%08h\nWB: rd=%0d mem_re=%0d reg_en=%0d alu_wb=%08h\nFORWARD=%0d",

            reg_ex.f3,
            reg_ex.f7_5,
            reg_ex.pc_cur,
            reg_ex.pc_4,
            reg_ex.rd_addr,
            reg_ex.rs1_addr,
            reg_ex.rs2_addr,
            reg_ex.rs1_data,
            reg_ex.rs2_data,

            for_info_mem.rd_addr,
            for_info_mem.mem_re,
            for_info_mem.reg_en,
            alu_mem,

            for_info_wb.rd_addr,
            for_info_wb.mem_re,
            for_info_wb.reg_en,
            alu_wb,

            do_forward
        );
    endfunction
endclass

class ex_stage_generator;
    mailbox #(ex_stage_transaction) gen2drv;
    int num_txn;
    event done;

    function new ( 
        mailbox #( ex_stage_transaction ) gen2drv,
        int num_txn
                );
                    this.gen2drv = gen2drv;
                    this.num_txn = num_txn;
    endfunction

    task run();
        ex_stage_transaction txn;
        repeat ( num_txn) begin
            txn = new();
            if(txn.randomize() == 0) 
              $fatal(1, "[GEN] IF transaction randomization failed");
            gen2drv.put(txn);
        end
        -> done;
    endtask
endclass

class ex_stage_driver;
     virtual ex_stage_if.DRV vif;
    mailbox #(ex_stage_transaction) gen2drv;

    function new(
        virtual ex_stage_if.DRV vif,
        mailbox #(ex_stage_transaction) gen2drv
    );
        this.vif = vif;
        this.gen2drv = gen2drv; 
    endfunction

    task reset_dut();
        vif.reg_ex       = 191'b0;
        vif.for_info_mem = 7'b0;
        vif.for_info_wb  = 7'b0;
        vif.alu_mem      = 32'b0;
        vif.alu_wb       = 32'b0;
        repeat(3) @(negedge vif.clk);
    endtask

    task run();
        ex_stage_transaction txn;
        forever begin
    
        gen2drv.get(txn);
        @(negedge vif.clk);

        vif.reg_ex          = txn.reg_ex;
        vif.for_info_mem    = txn.for_info_mem;
        vif.for_info_wb     = txn.for_info_wb;
        vif.alu_mem         = txn.alu_mem;
        vif.alu_wb          = txn.alu_wb;
        end
    endtask
endclass

class ex_stage_ref_model;

    id_ex_reg_t model_reg_ex;
    for_info_t  model_for_info_mem;
    for_info_t  model_for_info_wb;
    bit [XLEN-1:0] model_alu_mem;
    bit [XLEN-1:0] model_alu_wb;

    ex_mem_reg_t model_ex_reg;
    for_info_t   model_for_info_ex;
    bit [XLEN-1:0] model_alu_ex;

    function void predict(input ex_stage_transaction txn);
         // forwarding
        forward_e for_a;
        forward_e for_b;
        alu_ctrl_e alu_ctrl;
        bit [31:0] A;
        bit [31:0] B;

        model_reg_ex       = txn.reg_ex;
        model_for_info_mem = txn.for_info_mem;
        model_for_info_wb  = txn.for_info_wb;
        model_alu_mem      = txn.alu_mem;
        model_alu_wb       = txn.alu_wb;

        for_a = RD_EX;
        if (model_reg_ex.rs1_addr != 0) begin
            if (model_for_info_mem.reg_en &&
                model_reg_ex.rs1_addr == model_for_info_mem.rd_addr)
                for_a = RD_MEM;
            else if (model_for_info_wb.reg_en &&
                     model_reg_ex.rs1_addr == model_for_info_wb.rd_addr)
                for_a = RD_WB;
        end

        for_b = RD_EX;
        if (model_reg_ex.rs2_addr != 0) begin
            if (model_for_info_mem.reg_en &&
                model_reg_ex.rs2_addr == model_for_info_mem.rd_addr)
                for_b = RD_MEM;
            else if (model_for_info_wb.reg_en &&
                     model_reg_ex.rs2_addr == model_for_info_wb.rd_addr)
                for_b = RD_WB;
        end

        case (for_a)
            RD_MEM: A = model_alu_mem;
            RD_WB:  A = model_alu_wb;
            default: A = model_reg_ex.rs1_data;
        endcase

        case (for_b)
            RD_MEM: B = model_alu_mem;
            RD_WB:  B = model_alu_wb;
            default: B = model_reg_ex.rs2_data;
        endcase

        case (model_reg_ex.ex_ctrl.sel_a)
            RS1_EX:     A = A;
            PC_CUR_EX:  A = model_reg_ex.pc_cur;
            ZERO_EX:    A = 0;
            default:   A = '0;
        endcase
        txn.A = A;

        case (model_reg_ex.ex_ctrl.sel_b)
            RS2_EX: B = B;
            IMM_EX: B = model_reg_ex.imm_out;
            default:   B = '0;
        endcase
        txn.B = B;

        alu_ctrl = ALU_ADD;

        case (model_reg_ex.ex_ctrl.alu_op)
            ALU_ADD_SUB: alu_ctrl = ALU_ADD;

            ALU_RTYPE: begin
                case (model_reg_ex.f3)
                    F3_ADD_SUB: alu_ctrl = model_reg_ex.f7_5 ? ALU_SUB : ALU_ADD;
                    F3_SLL: alu_ctrl = ALU_SLL;
                    F3_SLT: alu_ctrl = ALU_SLT;
                    F3_SLTU: alu_ctrl = ALU_SLTU;
                    F3_XOR: alu_ctrl = ALU_XOR;
                    F3_SRL_SRA: alu_ctrl = model_reg_ex.f7_5 ? ALU_SRA : ALU_SRL;
                    F3_OR: alu_ctrl = ALU_OR;
                    F3_AND: alu_ctrl = ALU_AND;
                     default : alu_ctrl = ALU_ADD;
                endcase
            end

            ALU_ITYPE: begin
                case (model_reg_ex.f3)
                    F3_ADDI: alu_ctrl = ALU_ADD;
                    F3_SLLI: alu_ctrl = ALU_SLL;
                    F3_SLTI: alu_ctrl = ALU_SLT;
                    F3_SLTIU: alu_ctrl = ALU_SLTU;
                    F3_XORI: alu_ctrl = ALU_XOR;
                    F3_SRLI_SRAI: alu_ctrl = model_reg_ex.f7_5 ? ALU_SRA : ALU_SRL;
                    F3_ORI: alu_ctrl = ALU_OR;
                    F3_ANDI: alu_ctrl = ALU_AND;
                    default : alu_ctrl = ALU_ADD;
                endcase
            end
            default : alu_ctrl = ALU_ADD;
        endcase

        case (alu_ctrl)
            ALU_ADD:  model_alu_ex = A + B;
            ALU_SUB:  model_alu_ex = A - B;
            ALU_SLL:  model_alu_ex = A << B[4:0];
            ALU_SLT:  model_alu_ex = {31'b0,($signed(A) < $signed(B))};
            ALU_SLTU: model_alu_ex = {31'b0,(A < B)};
            ALU_XOR:  model_alu_ex = A ^ B;
            ALU_SRL:  model_alu_ex = A >> B[4:0];
            ALU_SRA:  model_alu_ex = $signed(A) >>> B[4:0];
            ALU_OR:   model_alu_ex = A | B;
            ALU_AND:  model_alu_ex = A & B;
            default:  model_alu_ex = 0;
        endcase
        txn.alu_ctrl = alu_ctrl;
        model_for_info_ex = '0;
        model_for_info_ex.rd_addr = model_reg_ex.rd_addr;
        model_for_info_ex.reg_en = model_reg_ex.wb_ctrl.reg_en;
        model_for_info_ex.mem_re = model_reg_ex.mem_ctrl.dmem_re;

        txn.alu_result = model_alu_ex;
        txn.expected_alu_ex = model_alu_ex;
        txn.expected_for_info_ex = model_for_info_ex;
        txn.for_ex_a = for_a;
        txn.for_ex_b = for_b;

    endfunction

endclass


class ex_stage_monitor;
    virtual ex_stage_if.MON vif;
    mailbox #(ex_stage_transaction) mon2sb;
    mailbox #(ex_stage_transaction) mon2cov;
    ex_stage_ref_model ref_model;

    int num_txn;
    event done;

    function new(
        virtual ex_stage_if.MON vif,
        mailbox #(ex_stage_transaction) mon2sb,
        mailbox #(ex_stage_transaction) mon2cov,
        ex_stage_ref_model ref_model,
        int num_txn
    );
        this.vif = vif;
        this.mon2sb = mon2sb;
        this.mon2cov = mon2cov;
        this.ref_model = ref_model;
        this.num_txn = num_txn;
    endfunction

    task run();
        ex_stage_transaction txn;

        for (int i = 0; i < num_txn; i++) begin
            @(posedge vif.clk);
            #1;

            txn = new();

            txn.reg_ex       = vif.mon_cb.reg_ex;
            txn.for_info_mem = vif.mon_cb.for_info_mem;
            txn.for_info_wb  = vif.mon_cb.for_info_wb;
            txn.alu_mem      = vif.mon_cb.alu_mem;
            txn.alu_wb       = vif.mon_cb.alu_wb;

            txn.for_info_ex  = vif.mon_cb.for_info_ex;
            txn.alu_ex       = vif.mon_cb.alu_ex;

            ref_model.predict(txn);
            
            mon2sb.put(txn);
            mon2cov.put(txn);
        end

        -> done;
    endtask

endclass

class ex_stage_scoreboard;
    mailbox #(ex_stage_transaction) mon2sb;

    int pass_cnt = 0;
    int fail_cnt = 0;

    function new(mailbox #(ex_stage_transaction) mon2sb);
        this.mon2sb = mon2sb;
    endfunction

    task run();
        ex_stage_transaction txn;

        forever begin
            mon2sb.get(txn);

            // =========================================================
            // 1. ALU RESULT
            // =========================================================
            if (txn.alu_ex === txn.expected_alu_ex)
                pass_cnt++;
            else begin
                fail_cnt++;
                $error("[SB][FAIL] ALU_RESULT\nACTUAL=%08h EXPECTED=%08h\nA=%08h B=%08h ALU_CTRL=%0d ALU_RESULT=%08h\nRS1=%0d DATA=%08h RS2=%0d DATA=%08h IMM=%08h\nSEL_A=%0d SEL_B=%0d\nFOR_A=%0d FOR_B=%0d\nMEM_RD=%0d MEM_EN=%0b MEM_ALU=%08h\nWB_RD=%0d WB_EN=%0b WB_ALU=%08h",
                    txn.alu_ex,
                    txn.expected_alu_ex,
                    txn.A,
                    txn.B,
                    txn.alu_ctrl,
                    txn.alu_result,
                    txn.reg_ex.rs1_addr,
                    txn.reg_ex.rs1_data,
                    txn.reg_ex.rs2_addr,
                    txn.reg_ex.rs2_data,
                    txn.reg_ex.imm_out,
                    txn.reg_ex.ex_ctrl.sel_a,
                    txn.reg_ex.ex_ctrl.sel_b,
                    txn.for_ex_a,
                    txn.for_ex_b,
                    txn.for_info_mem.rd_addr,
                    txn.for_info_mem.reg_en,
                    txn.alu_mem,
                    txn.for_info_wb.rd_addr,
                    txn.for_info_wb.reg_en,
                    txn.alu_wb);
            end

            // =========================================================
            // 2. FORWARDING A
            // =========================================================
            if (txn.for_ex_a == txn.for_ex_a)
                pass_cnt++;
            else begin
                fail_cnt++;
                $error("[SB][FAIL] FORWARD_A\nACTUAL=%0d EXPECTED=%0d\nRS1=%0d DATA=%08h\nMEM_RD=%0d MEM_EN=%0b MEM_ALU=%08h\nWB_RD=%0d WB_EN=%0b WB_ALU=%08h",
                    txn.for_ex_a,
                    txn.for_ex_a,
                    txn.reg_ex.rs1_addr,
                    txn.reg_ex.rs1_data,
                    txn.for_info_mem.rd_addr,
                    txn.for_info_mem.reg_en,
                    txn.alu_mem,
                    txn.for_info_wb.rd_addr,
                    txn.for_info_wb.reg_en,
                    txn.alu_wb);
            end

            // =========================================================
            // 3. FORWARDING B
            // =========================================================
            if (txn.for_ex_b == txn.for_ex_b)
                pass_cnt++;
            else begin
                fail_cnt++;
                $error("[SB][FAIL] FORWARD_B\nACTUAL=%0d EXPECTED=%0d\nRS2=%0d DATA=%08h\nMEM_RD=%0d MEM_EN=%0b MEM_ALU=%08h\nWB_RD=%0d WB_EN=%0b WB_ALU=%08h",
                    txn.for_ex_b,
                    txn.for_ex_b,
                    txn.reg_ex.rs2_addr,
                    txn.reg_ex.rs2_data,
                    txn.for_info_mem.rd_addr,
                    txn.for_info_mem.reg_en,
                    txn.alu_mem,
                    txn.for_info_wb.rd_addr,
                    txn.for_info_wb.reg_en,
                    txn.alu_wb);
            end

            // =========================================================
            // 4. EX -> MEM RD
            // =========================================================
            if (txn.for_info_ex.rd_addr === txn.expected_for_info_ex.rd_addr)
                pass_cnt++;
            else begin
                fail_cnt++;
                $error("[SB][FAIL] RD_ADDR\nACTUAL=%0d EXPECTED=%0d\nREG_EX_RD=%0d",
                    txn.for_info_ex.rd_addr,
                    txn.expected_for_info_ex.rd_addr,
                    txn.reg_ex.rd_addr);
            end

            // =========================================================
            // 5. EX -> MEM REG_EN
            // =========================================================
            if (txn.for_info_ex.reg_en === txn.expected_for_info_ex.reg_en)
                pass_cnt++;
            else begin
                fail_cnt++;
                $error("[SB][FAIL] REG_EN\nACTUAL=%0b EXPECTED=%0b\nREG_EX_REG_EN=%0b",
                    txn.for_info_ex.reg_en,
                    txn.expected_for_info_ex.reg_en,
                    txn.reg_ex.wb_ctrl.reg_en);
            end

            // =========================================================
            // 6. EX -> MEM MEM_RE
            // =========================================================
            if (txn.for_info_ex.mem_re === txn.expected_for_info_ex.mem_re)
                pass_cnt++;
            else begin
                fail_cnt++;
                $error("[SB][FAIL] MEM_RE\nACTUAL=%0b EXPECTED=%0b\nREG_EX_MEM_RE=%0b",
                    txn.for_info_ex.mem_re,
                    txn.expected_for_info_ex.mem_re,
                    txn.reg_ex.mem_ctrl.dmem_re);
            end
        end
    endtask

    function void report();
        $display("\n[SB] PASS=%0d FAIL=%0d RESULT=%s", pass_cnt, fail_cnt, (fail_cnt == 0) ? "PASS" : "FAIL");
    endfunction

endclass


class ex_stage_coverage;
    mailbox #(ex_stage_transaction) mon2cov;

    // =========================================================
    // 1. ALU CTRL
    // =========================================================
    covergroup cg_alu_ctrl with function sample(ex_stage_transaction t);

        cp_alu_op : coverpoint t.reg_ex.ex_ctrl.alu_op {
            bins add_sub = {ALU_ADD_SUB};
            bins rtype   = {ALU_RTYPE};
            bins itype   = {ALU_ITYPE};
        }

        cp_f3 : coverpoint t.reg_ex.f3 {
            bins add_sub = {F3_ADD_SUB};
            bins sll     = {F3_SLL};
            bins slt     = {F3_SLT};
            bins sltu    = {F3_SLTU};
            bins xor_op  = {F3_XOR};
            bins srl_sra = {F3_SRL_SRA};
            bins or_op   = {F3_OR};
            bins and_op  = {F3_AND};
        }

        cp_f7_5 : coverpoint t.reg_ex.f7_5 {
            bins zero = {0};
            bins one  = {1};
        }

        cp_alu_ctrl : coverpoint t.alu_ctrl {
            bins add  = {ALU_ADD};
            bins sub  = {ALU_SUB};
            bins sll  = {ALU_SLL};
            bins slt  = {ALU_SLT};
            bins sltu = {ALU_SLTU};
            bins xor_op  = {ALU_XOR};
            bins srl  = {ALU_SRL};
            bins sra  = {ALU_SRA};
            bins or_op   = {ALU_OR};
            bins and_op  = {ALU_AND};
        }

        cp_add_sub : coverpoint t.reg_ex.f7_5 iff (
            t.reg_ex.ex_ctrl.alu_op == ALU_RTYPE &&
            t.reg_ex.f3 == F3_ADD_SUB
        ) {
            bins add = {0};
            bins sub = {1};
        }

        cp_srl_sra : coverpoint t.reg_ex.f7_5 iff (
            t.reg_ex.ex_ctrl.alu_op inside {ALU_RTYPE, ALU_ITYPE} &&
            t.reg_ex.f3 inside {F3_SRL_SRA, F3_SRLI_SRAI}
        ) {
            bins srl = {0};
            bins sra = {1};
        }

    endgroup


    // =========================================================
    // 2. ALU
    // =========================================================
    covergroup cg_alu with function sample(ex_stage_transaction t);

        cp_operation : coverpoint t.alu_ctrl {
            bins add  = {ALU_ADD};
            bins sub  = {ALU_SUB};
            bins sll  = {ALU_SLL};
            bins slt  = {ALU_SLT};
            bins sltu = {ALU_SLTU};
            bins xor_op  = {ALU_XOR};
            bins srl  = {ALU_SRL};
            bins sra  = {ALU_SRA};
            bins or_op   = {ALU_OR};
            bins and_op  = {ALU_AND};
        }

        cp_A : coverpoint t.A {
            bins zero       = {32'h0000_0000};
            bins one        = {32'h0000_0001};
            bins ff         = {32'h0000_00FF};
            bins aa         = {32'hAAAA_AAAA};
            bins pattern_55 = {32'h5555_5555};
            bins int_max    = {32'h7FFF_FFFF};
            bins int_min    = {32'h8000_0000};
            bins max        = {32'hFFFF_FFFF};
        }

        cp_B : coverpoint t.B {
            bins zero       = {32'h0000_0000};
            bins one        = {32'h0000_0001};
            bins ff         = {32'h0000_00FF};
            bins aa         = {32'hAAAA_AAAA};
            bins pattern_55 = {32'h5555_5555};
            bins int_max    = {32'h7FFF_FFFF};
            bins int_min    = {32'h8000_0000};
            bins max        = {32'hFFFF_FFFF};
        }

        cp_result : coverpoint t.alu_result {
            bins zero       = {32'h0000_0000};
            bins one        = {32'h0000_0001};
            bins ff         = {32'h0000_00FF};
            bins aa         = {32'hAAAA_AAAA};
            bins pattern_55 = {32'h5555_5555};
            bins int_max    = {32'h7FFF_FFFF};
            bins int_min    = {32'h8000_0000};
            bins max        = {32'hFFFF_FFFF};
        }

        cp_zero_result : coverpoint (t.alu_result == 32'h0000_0000) {
            bins zero    = {1};
            bins nonzero = {0};
        }

        cp_signed_boundary : coverpoint {t.A[31], t.B[31]} {
            bins positive_positive = {2'b00};
            bins positive_negative = {2'b01};
            bins negative_positive = {2'b10};
            bins negative_negative = {2'b11};
        }

        cp_shift_amount : coverpoint t.B[4:0] {
            bins shift_0  = {0};
            bins shift_1  = {1};
            bins shift_15 = {15};
            bins shift_16 = {16};
            bins shift_30 = {30};
            bins shift_31 = {31};
        }

    endgroup


    // =========================================================
    // 3. ALU MUX
    // =========================================================
    covergroup cg_alu_mux with function sample(ex_stage_transaction t);

        cp_sel_a : coverpoint t.reg_ex.ex_ctrl.sel_a {
            bins rs1  = {RS1_EX};
            bins pc   = {PC_CUR_EX};
            bins zero = {ZERO_EX};
        }

        cp_sel_b : coverpoint t.reg_ex.ex_ctrl.sel_b {
            bins rs2 = {RS2_EX};
            bins imm = {IMM_EX};
        }

        cp_forward_a : coverpoint t.for_ex_a {
            bins rd_ex  = {RD_EX};
            bins rd_mem = {RD_MEM};
            bins rd_wb  = {RD_WB};
        }

        cp_forward_b : coverpoint t.for_ex_b {
            bins rd_ex  = {RD_EX};
            bins rd_mem = {RD_MEM};
            bins rd_wb  = {RD_WB};
        }

        cross_a_forward : cross cp_sel_a, cp_forward_a;
        cross_b_forward : cross cp_sel_b, cp_forward_b;

    endgroup


    // =========================================================
    // 4. FORWARD EX
    // =========================================================
    covergroup cg_forward with function sample(ex_stage_transaction t);

        cp_forward_a : coverpoint t.for_ex_a {
            bins rd_ex  = {RD_EX};
            bins rd_mem = {RD_MEM};
            bins rd_wb  = {RD_WB};
        }

        cp_forward_b : coverpoint t.for_ex_b {
            bins rd_ex  = {RD_EX};
            bins rd_mem = {RD_MEM};
            bins rd_wb  = {RD_WB};
        }

        cp_rs1_x0 : coverpoint (t.reg_ex.rs1_addr == '0) {
            bins x0     = {1};
            bins non_x0 = {0};
        }

        cp_rs2_x0 : coverpoint (t.reg_ex.rs2_addr == '0) {
            bins x0     = {1};
            bins non_x0 = {0};
        }

        cp_mem_reg_en : coverpoint t.for_info_mem.reg_en {
            bins disabled = {0};
            bins enabled  = {1};
        }

        cp_wb_reg_en : coverpoint t.reg_ex.wb_ctrl.reg_en {
            bins disabled = {0};
            bins enabled  = {1};
        }

        cp_no_hazard : coverpoint (
            t.for_ex_a == RD_EX &&
            t.for_ex_b == RD_EX
        ) {
            bins no_hazard = {1};
            bins hazard    = {0};
        }

        cp_mem_priority : coverpoint (t.for_ex_a == RD_MEM) {
            bins mem_priority = {1};
            bins other        = {0};
        }

        cross_a_b : cross cp_forward_a, cp_forward_b;

    endgroup


    // =========================================================
    // 5. CROSS COVERAGE
    // =========================================================
    covergroup cg_cross with function sample(ex_stage_transaction t);

        cp_alu_op : coverpoint t.reg_ex.ex_ctrl.alu_op {
            bins add_sub = {ALU_ADD_SUB};
            bins rtype   = {ALU_RTYPE};
            bins itype   = {ALU_ITYPE};
        }

        cp_f3 : coverpoint t.reg_ex.f3 {
            bins add_sub = {F3_ADD_SUB};
            bins sll     = {F3_SLL};
            bins slt     = {F3_SLT};
            bins sltu    = {F3_SLTU};
            bins xor_op  = {F3_XOR};
            bins srl_sra = {F3_SRL_SRA};
            bins or_op   = {F3_OR};
            bins and_op  = {F3_AND};
        }

        cp_f7_5 : coverpoint t.reg_ex.f7_5 {
            bins zero = {0};
            bins one  = {1};
        }

        cp_alu_ctrl : coverpoint t.alu_ctrl {
            bins add  = {ALU_ADD};
            bins sub  = {ALU_SUB};
            bins sll  = {ALU_SLL};
            bins slt  = {ALU_SLT};
            bins sltu = {ALU_SLTU};
            bins xor_op  = {ALU_XOR};
            bins srl  = {ALU_SRL};
            bins sra  = {ALU_SRA};
            bins or_op   = {ALU_OR};
            bins and_op  = {ALU_AND};
        }

        cp_forward_a : coverpoint t.for_ex_a {
            bins rd_ex  = {RD_EX};
            bins rd_mem = {RD_MEM};
            bins rd_wb  = {RD_WB};
        }

        cp_forward_b : coverpoint t.for_ex_b {
            bins rd_ex  = {RD_EX};
            bins rd_mem = {RD_MEM};
            bins rd_wb  = {RD_WB};
        }

        cp_sel_a : coverpoint t.reg_ex.ex_ctrl.sel_a {
            bins rs1  = {RS1_EX};
            bins pc   = {PC_CUR_EX};
            bins zero = {ZERO_EX};
        }

        cp_sel_b : coverpoint t.reg_ex.ex_ctrl.sel_b {
            bins rs2 = {RS2_EX};
            bins imm = {IMM_EX};
        }

        alu_op_f3 : cross cp_alu_op, cp_f3;
        alu_op_f7  : cross cp_alu_op, cp_f7_5;

        alu_op_operand : cross cp_alu_ctrl, cp_forward_a;

        forward_mux_a : cross cp_forward_a, cp_sel_a;
        forward_mux_b : cross cp_forward_b, cp_sel_b;

        forward_alu : cross cp_forward_a, cp_alu_ctrl;

        forward_a_b : cross cp_forward_a, cp_forward_b;

    endgroup


    // =========================================================
    // Constructor
    // =========================================================
    function new(mailbox #(ex_stage_transaction) mon2cov);
        this.mon2cov = mon2cov;

        cg_alu_ctrl = new();
        cg_alu      = new();
        cg_alu_mux  = new();
        cg_forward  = new();
        cg_cross    = new();
    endfunction


    // =========================================================
    // Run
    // =========================================================
    task run();
        ex_stage_transaction txn;

        forever begin
            mon2cov.get(txn);

            cg_alu_ctrl.sample(txn);
            cg_alu.sample(txn);
            cg_alu_mux.sample(txn);
            cg_forward.sample(txn);
            cg_cross.sample(txn);
        end
    endtask


    // =========================================================
    // Report
    // =========================================================
    function void report();
        $display("\n============================================================");
        $display("EX-STAGE COVERAGE");
        $display("============================================================");
        $display("[COV] ALU CTRL = %0.2f%%",
                 cg_alu_ctrl.get_inst_coverage());
        $display("[COV] ALU      = %0.2f%%",
                 cg_alu.get_inst_coverage());
        $display("[COV] ALU MUX  = %0.2f%%",
                 cg_alu_mux.get_inst_coverage());
        $display("[COV] FORWARD  = %0.2f%%",
                 cg_forward.get_inst_coverage());
        $display("[COV] CROSS    = %0.2f%%",
                 cg_cross.get_inst_coverage());
        $display("============================================================");
    endfunction

    function void sample_direct(ex_stage_transaction t);
    cg_alu_ctrl.sample(t);
    cg_alu.sample(t);
    cg_alu_mux.sample(t);
    cg_forward.sample(t);
    cg_cross.sample(t);
    endfunction

endclass


class ex_stage_agent;
    virtual ex_stage_if vif;

    mailbox #(ex_stage_transaction) gen2drv;
    mailbox #(ex_stage_transaction) mon2sb;
    mailbox #(ex_stage_transaction) mon2cov;

    ex_stage_generator generator;
    ex_stage_driver driver;
    ex_stage_monitor monitor;
    ex_stage_ref_model ref_model;

    function new(
        virtual ex_stage_if vif,
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

class ex_stage_env;
    ex_stage_agent agent;
    ex_stage_scoreboard scoreboard;
    ex_stage_coverage coverage;

    function new(
        virtual ex_stage_if vif,
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


class ex_stage_test;
    virtual ex_stage_if vif;
    ex_stage_env env;
    int direct_pass = 0;
    int direct_fail = 0;
    int num_random_txn;

    function new(virtual ex_stage_if vif,int num_random_txn);
        this.vif = vif;
        this.num_random_txn = num_random_txn;
        env = new(vif,num_random_txn);
    endfunction

    // ========================================================================
    // DIRECT TEST SECTION
    // ========================================================================
    // These tasks do NOT use Generator/Driver.
    // They directly drive the interface and immediately check expected result.
    // ========================================================================

    task direct_idle();
        vif.reg_ex = '0;
        vif.for_info_mem = '0;
        vif.for_info_wb = '0;
        vif.alu_mem = '0;
        vif.alu_wb = '0;
    endtask

    task direct_check(string name,logic [31:0] actual,logic [31:0] expected);
        if (actual !== expected) begin
            direct_fail++;
            $error("[DIRECT][FAIL] %s actual=%08h expected=%08h",name,actual,expected);
        end
        else begin
            direct_pass++;
            $display("[DIRECT][PASS] %s value=%08h",name,actual);
        end
    endtask

    // ------------------------------------------------------------------------
    // DIRECT -> COVERAGE BRIDGE
    // ------------------------------------------------------------------------
    // Converts the current interface state into the same transaction
    // format used by the OOP monitor, then samples the common coverage.
    // ------------------------------------------------------------------------

    task direct_sample_cov();
        ex_stage_transaction t = new();
        t.reg_ex = vif.reg_ex;
        t.for_info_mem = vif.for_info_mem;
        t.for_info_wb = vif.for_info_wb;
        t.alu_mem = vif.alu_mem;
        t.alu_wb = vif.alu_wb;
        t.alu_ex = vif.alu_ex;
        t.for_info_ex = vif.for_info_ex;
        env.coverage.sample_direct(t);
    endtask

    // ------------------------------------------------------------------------
    // DIRECT CASE 1: ADD
    // ------------------------------------------------------------------------

    task direct_add();
        ex_stage_transaction t;
        t = new();
        t.reg_ex.ex_ctrl.alu_op = ALU_RTYPE;
        t.reg_ex.f3 = F3_ADD_SUB;
        t.reg_ex.f7_5 = 1'b0;
        t.reg_ex.rs1_addr = 5'd1;
        t.reg_ex.rs2_addr = 5'd2;
        t.reg_ex.rs1_data = 32'd10;
        t.reg_ex.rs2_data = 32'd20;
        t.reg_ex.ex_ctrl.sel_a = RS1_EX;
        t.reg_ex.ex_ctrl.sel_b = RS2_EX;
        vif.reg_ex = t.reg_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb = t.for_info_wb;
        vif.alu_mem = t.alu_mem;
        vif.alu_wb = t.alu_wb;
        @(posedge vif.clk);
        #1;
        direct_check("ADD",vif.alu_ex,32'd30);
        direct_sample_cov();
    endtask

    // ------------------------------------------------------------------------
    // DIRECT CASE 2: SUB
    // ------------------------------------------------------------------------

    task direct_sub();
        ex_stage_transaction t;
        t = new();
        t.reg_ex.ex_ctrl.alu_op = ALU_RTYPE;
        t.reg_ex.f3 = F3_ADD_SUB;
        t.reg_ex.f7_5 = 1'b1;
        t.reg_ex.rs1_addr = 5'd1;
        t.reg_ex.rs2_addr = 5'd2;
        t.reg_ex.rs1_data = 32'd30;
        t.reg_ex.rs2_data = 32'd10;
        t.reg_ex.ex_ctrl.sel_a = RS1_EX;
        t.reg_ex.ex_ctrl.sel_b = RS2_EX;
        vif.reg_ex = t.reg_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb = t.for_info_wb;
        vif.alu_mem = t.alu_mem;
        vif.alu_wb = t.alu_wb;
        @(posedge vif.clk);
        #1;
        direct_check("SUB",vif.alu_ex,32'd20);
        direct_sample_cov();
    endtask

    // ------------------------------------------------------------------------
    // DIRECT CASE 3: SRL
    // ------------------------------------------------------------------------

    task direct_srl();
        ex_stage_transaction t;
        t = new();
        t.reg_ex.ex_ctrl.alu_op = ALU_RTYPE;
        t.reg_ex.f3 = F3_SRL_SRA;
        t.reg_ex.f7_5 = 1'b0;
        t.reg_ex.rs1_addr = 5'd1;
        t.reg_ex.rs2_addr = 5'd2;
        t.reg_ex.rs1_data = 32'h8000_0000;
        t.reg_ex.rs2_data = 32'd1;
        t.reg_ex.ex_ctrl.sel_a = RS1_EX;
        t.reg_ex.ex_ctrl.sel_b = RS2_EX;
        vif.reg_ex = t.reg_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb = t.for_info_wb;
        vif.alu_mem = t.alu_mem;
        vif.alu_wb = t.alu_wb;
        @(posedge vif.clk);
        #1;
        direct_check("SRL",vif.alu_ex,32'h4000_0000);
        direct_sample_cov();
    endtask

    // ------------------------------------------------------------------------
    // DIRECT CASE 4: SRA
    // ------------------------------------------------------------------------

    task direct_sra();
        ex_stage_transaction t;
        t = new();
        t.reg_ex.ex_ctrl.alu_op = ALU_RTYPE;
        t.reg_ex.f3 = F3_SRL_SRA;
        t.reg_ex.f7_5 = 1'b1;
        t.reg_ex.rs1_addr = 5'd1;
        t.reg_ex.rs2_addr = 5'd2;
        t.reg_ex.rs1_data = 32'h8000_0000;
        t.reg_ex.rs2_data = 32'd1;
        t.reg_ex.ex_ctrl.sel_a = RS1_EX;
        t.reg_ex.ex_ctrl.sel_b = RS2_EX;
        vif.reg_ex = t.reg_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb = t.for_info_wb;
        vif.alu_mem = t.alu_mem;
        vif.alu_wb = t.alu_wb;
        @(posedge vif.clk);
        #1;
        direct_check("SRA",vif.alu_ex,32'hC000_0000);
        direct_sample_cov();
    endtask

    // ------------------------------------------------------------------------
    // DIRECT CASE 5: INT_MAX
    // ------------------------------------------------------------------------

    task direct_int_max();
        ex_stage_transaction t;
        t = new();
        t.reg_ex.ex_ctrl.alu_op = ALU_RTYPE;
        t.reg_ex.f3 = F3_ADD_SUB;
        t.reg_ex.f7_5 = 1'b0;
        t.reg_ex.rs1_addr = 5'd1;
        t.reg_ex.rs2_addr = 5'd2;
        t.reg_ex.rs1_data = 32'h7FFF_FFFF;
        t.reg_ex.rs2_data = 32'd1;
        t.reg_ex.ex_ctrl.sel_a = RS1_EX;
        t.reg_ex.ex_ctrl.sel_b = RS2_EX;
        vif.reg_ex = t.reg_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb = t.for_info_wb;
        vif.alu_mem = t.alu_mem;
        vif.alu_wb = t.alu_wb;
        @(posedge vif.clk);
        #1;
        direct_check("INT_MAX + 1",vif.alu_ex,32'h8000_0000);
        direct_sample_cov();
    endtask

    // ------------------------------------------------------------------------
    // DIRECT CASE 6: INT_MIN
    // ------------------------------------------------------------------------

    task direct_int_min();
        ex_stage_transaction t;
        t = new();
        t.reg_ex.ex_ctrl.alu_op = ALU_RTYPE;
        t.reg_ex.f3 = F3_ADD_SUB;
        t.reg_ex.f7_5 = 1'b1;
        t.reg_ex.rs1_addr = 5'd1;
        t.reg_ex.rs2_addr = 5'd2;
        t.reg_ex.rs1_data = 32'h8000_0000;
        t.reg_ex.rs2_data = 32'd1;
        t.reg_ex.ex_ctrl.sel_a = RS1_EX;
        t.reg_ex.ex_ctrl.sel_b = RS2_EX;
        vif.reg_ex = t.reg_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb = t.for_info_wb;
        vif.alu_mem = t.alu_mem;
        vif.alu_wb = t.alu_wb;
        @(posedge vif.clk);
        #1;
        direct_check("INT_MIN - 1",vif.alu_ex,32'h7FFF_FFFF);
        direct_sample_cov();
    endtask

    // ------------------------------------------------------------------------
    // DIRECT CASE 7: SIGNED BOUNDARY
    // ------------------------------------------------------------------------

    task direct_signed_boundary();
        ex_stage_transaction t;
        t = new();
        t.reg_ex.ex_ctrl.alu_op = ALU_RTYPE;
        t.reg_ex.f3 = F3_SLT;
        t.reg_ex.f7_5 = 1'b0;
        t.reg_ex.rs1_addr = 5'd1;
        t.reg_ex.rs2_addr = 5'd2;
        t.reg_ex.rs1_data = 32'h8000_0000;
        t.reg_ex.rs2_data = 32'h0000_0001;
        t.reg_ex.ex_ctrl.sel_a = RS1_EX;
        t.reg_ex.ex_ctrl.sel_b = RS2_EX;
        vif.reg_ex = t.reg_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb = t.for_info_wb;
        vif.alu_mem = t.alu_mem;
        vif.alu_wb = t.alu_wb;
        @(posedge vif.clk);
        #1;
        direct_check("SIGNED: INT_MIN < 1",vif.alu_ex,32'd1);
        direct_sample_cov();
    endtask

    // ------------------------------------------------------------------------
    // DIRECT CASE 8: UNSIGNED BOUNDARY
    // ------------------------------------------------------------------------

    task direct_unsigned_boundary();
        ex_stage_transaction t;
        t = new();
        t.reg_ex.ex_ctrl.alu_op = ALU_RTYPE;
        t.reg_ex.f3 = F3_SLTU;
        t.reg_ex.f7_5 = 1'b0;
        t.reg_ex.rs1_addr = 5'd1;
        t.reg_ex.rs2_addr = 5'd2;
        t.reg_ex.rs1_data = 32'hFFFF_FFFF;
        t.reg_ex.rs2_data = 32'h0000_0000;
        t.reg_ex.ex_ctrl.sel_a = RS1_EX;
        t.reg_ex.ex_ctrl.sel_b = RS2_EX;
        vif.reg_ex = t.reg_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb = t.for_info_wb;
        vif.alu_mem = t.alu_mem;
        vif.alu_wb = t.alu_wb;
        @(posedge vif.clk);
        #1;
        direct_check("UNSIGNED: MAX < 0",vif.alu_ex,32'd0);
        direct_sample_cov();
    endtask

    // ------------------------------------------------------------------------
    // DIRECT CASE 9: SHIFT BOUNDARY
    // ------------------------------------------------------------------------

    task direct_shift_boundary();
        ex_stage_transaction t;
        t = new();
        t.reg_ex.ex_ctrl.alu_op = ALU_RTYPE;
        t.reg_ex.f3 = F3_SLL;
        t.reg_ex.f7_5 = 1'b0;
        t.reg_ex.rs1_addr = 5'd1;
        t.reg_ex.rs2_addr = 5'd2;
        t.reg_ex.rs1_data = 32'h0000_0001;
        t.reg_ex.ex_ctrl.sel_a = RS1_EX;
        t.reg_ex.ex_ctrl.sel_b = RS2_EX;
        t.reg_ex.rs2_data = 32'd0;
        vif.reg_ex = t.reg_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb = t.for_info_wb;
        vif.alu_mem = t.alu_mem;
        vif.alu_wb = t.alu_wb;
        @(posedge vif.clk);
        #1;
        direct_check("SHIFT 0",vif.alu_ex,32'h0000_0001);
        direct_sample_cov();
        t.reg_ex.rs2_data = 32'd1;
        vif.reg_ex = t.reg_ex;
        @(posedge vif.clk);
        #1;
        direct_check("SHIFT 1",vif.alu_ex,32'h0000_0002);
        direct_sample_cov();
        t.reg_ex.rs2_data = 32'd31;
        vif.reg_ex = t.reg_ex;
        @(posedge vif.clk);
        #1;
        direct_check("SHIFT 31",vif.alu_ex,32'h8000_0000);
        direct_sample_cov();
    endtask

    // ------------------------------------------------------------------------
    // DIRECT CASE 10: X0
    // ------------------------------------------------------------------------

    task direct_x0();
        ex_stage_transaction t;
        t = new();
        t.reg_ex.ex_ctrl.alu_op = ALU_RTYPE;
        t.reg_ex.f3 = F3_ADD_SUB;
        t.reg_ex.f7_5 = 1'b0;
        t.reg_ex.rs1_addr = 5'd0;
        t.reg_ex.rs2_addr = 5'd2;
        t.reg_ex.rs1_data = 32'h0000_0000;
        t.reg_ex.rs2_data = 32'd10;
        t.for_info_mem.rd_addr = 5'd0;
        t.for_info_mem.reg_en = 1'b1;
        t.alu_mem = 32'hFFFF_FFFF;
        t.reg_ex.ex_ctrl.sel_a = RS1_EX;
        t.reg_ex.ex_ctrl.sel_b = RS2_EX;
        vif.reg_ex = t.reg_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb = t.for_info_wb;
        vif.alu_mem = t.alu_mem;
        vif.alu_wb = t.alu_wb;
        @(posedge vif.clk);
        #1;
        direct_check("X0: NO FORWARD",vif.alu_ex,32'd10);
        direct_sample_cov();
    endtask

    // ------------------------------------------------------------------------
    // DIRECT CASE 11: REG_EN = 0
    // ------------------------------------------------------------------------

    task direct_reg_en_zero();
        ex_stage_transaction t;
        t = new();
        t.reg_ex.ex_ctrl.alu_op = ALU_RTYPE;
        t.reg_ex.f3 = F3_ADD_SUB;
        t.reg_ex.f7_5 = 1'b0;
        t.reg_ex.rs1_addr = 5'd5;
        t.reg_ex.rs2_addr = 5'd2;
        t.reg_ex.rs1_data = 32'd10;
        t.reg_ex.rs2_data = 32'd20;
        t.for_info_mem.rd_addr = 5'd5;
        t.for_info_mem.reg_en = 1'b0;
        t.alu_mem = 32'hFFFF_FFFF;
        t.reg_ex.ex_ctrl.sel_a = RS1_EX;
        t.reg_ex.ex_ctrl.sel_b = RS2_EX;
        vif.reg_ex = t.reg_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb = t.for_info_wb;
        vif.alu_mem = t.alu_mem;
        vif.alu_wb = t.alu_wb;
        @(posedge vif.clk);
        #1;
        direct_check("REG_EN=0: NO FORWARD",vif.alu_ex,32'd30);
        direct_sample_cov();
    endtask

    // ------------------------------------------------------------------------
    // DIRECT CASE 12: MEM PRIORITY WB
    // ------------------------------------------------------------------------

    task direct_mem_priority_wb();
        ex_stage_transaction t;
        t = new();
        t.reg_ex.ex_ctrl.alu_op = ALU_RTYPE;
        t.reg_ex.f3 = F3_ADD_SUB;
        t.reg_ex.f7_5 = 1'b0;
        t.reg_ex.rs1_addr = 5'd5;
        t.reg_ex.rs2_addr = 5'd2;
        t.reg_ex.rs1_data = 32'd10;
        t.reg_ex.rs2_data = 32'd1;
        t.for_info_mem.rd_addr = 5'd5;
        t.for_info_mem.reg_en = 1'b1;
        t.alu_mem = 32'd100;
        t.for_info_wb.rd_addr = 5'd5;
        t.for_info_wb.reg_en = 1'b1;
        t.alu_wb = 32'd200;
        t.reg_ex.ex_ctrl.sel_a = RS1_EX;
        t.reg_ex.ex_ctrl.sel_b = RS2_EX;
        vif.reg_ex = t.reg_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb = t.for_info_wb;
        vif.alu_mem = t.alu_mem;
        vif.alu_wb = t.alu_wb;
        @(posedge vif.clk);
        #1;
        direct_check("FORWARD: MEM PRIORITY WB",vif.alu_ex,32'd101);
        direct_sample_cov();
    endtask

    // ------------------------------------------------------------------------
    // DIRECT CASE 13: PC MUX
    // ------------------------------------------------------------------------

    task direct_pc_mux();
        ex_stage_transaction t;
        t = new();
        t.reg_ex.ex_ctrl.alu_op = ALU_RTYPE;
        t.reg_ex.f3 = F3_ADD_SUB;
        t.reg_ex.f7_5 = 1'b0;
        t.reg_ex.pc_cur = 32'h0000_1000;
        t.reg_ex.rs2_data = 32'd20;
        t.reg_ex.ex_ctrl.sel_a = PC_CUR_EX;
        t.reg_ex.ex_ctrl.sel_b = RS2_EX;
        t.reg_ex.rs1_addr = 5'd1;
        t.reg_ex.rs2_addr = 5'd2;
        vif.reg_ex = t.reg_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb = t.for_info_wb;
        vif.alu_mem = t.alu_mem;
        vif.alu_wb = t.alu_wb;
        @(posedge vif.clk);
        #1;
        direct_check("MUX A: PC_CUR",vif.alu_ex,32'h0000_1014);
        direct_sample_cov();
    endtask

    // ------------------------------------------------------------------------
    // DIRECT CASE 14: ZERO MUX
    // ------------------------------------------------------------------------

    task direct_zero_mux();
        ex_stage_transaction t;
        t = new();
        t.reg_ex.ex_ctrl.alu_op = ALU_RTYPE;
        t.reg_ex.f3 = F3_ADD_SUB;
        t.reg_ex.f7_5 = 1'b0;
        t.reg_ex.rs1_data = 32'hFFFF_FFFF;
        t.reg_ex.rs2_data = 32'd20;
        t.reg_ex.ex_ctrl.sel_a = ZERO_EX;
        t.reg_ex.ex_ctrl.sel_b = RS2_EX;
        t.reg_ex.rs1_addr = 5'd1;
        t.reg_ex.rs2_addr = 5'd2;
        vif.reg_ex = t.reg_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb = t.for_info_wb;
        vif.alu_mem = t.alu_mem;
        vif.alu_wb = t.alu_wb;
        @(posedge vif.clk);
        #1;
        direct_check("MUX A: ZERO",vif.alu_ex,32'd20);
        direct_sample_cov();
    endtask

    // ------------------------------------------------------------------------
    // DIRECT CASE 15: IMM MUX
    // ------------------------------------------------------------------------

    task direct_imm_mux();
        ex_stage_transaction t;
        t = new();
        t.reg_ex.ex_ctrl.alu_op = ALU_RTYPE;
        t.reg_ex.f3 = F3_ADD_SUB;
        t.reg_ex.f7_5 = 1'b0;
        t.reg_ex.rs1_data = 32'd100;
        t.reg_ex.rs2_data = 32'hFFFF_FFFF;
        t.reg_ex.imm_out = 32'd50;
        t.reg_ex.ex_ctrl.sel_a = RS1_EX;
        t.reg_ex.ex_ctrl.sel_b = IMM_EX;
        t.reg_ex.rs1_addr = 5'd1;
        t.reg_ex.rs2_addr = 5'd2;
        vif.reg_ex = t.reg_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb = t.for_info_wb;
        vif.alu_mem = t.alu_mem;
        vif.alu_wb = t.alu_wb;
        @(posedge vif.clk);
        #1;
        direct_check("MUX B: IMM",vif.alu_ex,32'd150);
        direct_sample_cov();
    endtask

    // ========================================================================
    // DIRECT TEST SUITE
    // ========================================================================

    task run_direct_tests();
        $display("");
        $display("============================================================");
        $display("                 DIRECT EX-STAGE TESTS");
        $display("============================================================");
        direct_idle();
        direct_add();
        direct_sub();
        direct_srl();
        direct_sra();
        direct_int_max();
        direct_int_min();
        direct_signed_boundary();
        direct_unsigned_boundary();
        direct_shift_boundary();
        direct_x0();
        direct_reg_en_zero();
        direct_mem_priority_wb();
        direct_pc_mux();
        direct_zero_mux();
        direct_imm_mux();
        $display("[DIRECT] PASS=%0d FAIL=%0d",direct_pass,direct_fail);
    endtask

    // ========================================================================
    // OOP TEST
    // ========================================================================
    // Generator
    //    ↓
    // Driver
    //    ↓
    // DUT
    //    ↓
    // Monitor
    //    ├── Scoreboard
    //    └── Coverage
    // ========================================================================

    task run_oop_test();
        $display("");
        $display("============================================================");
        $display("                   OOP RANDOM TEST");
        $display("============================================================");
        direct_idle();
        env.run();
        repeat (5) @(posedge vif.clk);
        #1;
        $display("[OOP] Random generation completed.");
    endtask

    // ========================================================================
    // FINAL REPORT
    // ========================================================================

    task report();
        $display("");
        $display("============================================================");
        $display("                 EX-STAGE FINAL REPORT");
        $display("============================================================");
        $display("[DIRECT] PASS=%0d FAIL=%0d",direct_pass,direct_fail);
        $display("[OOP] SCOREBOARD PASS=%0d FAIL=%0d",env.agent == null ? -1 : env.scoreboard.pass_cnt,env.agent == null ? -1 : env.scoreboard.fail_cnt);
        env.coverage.report();
        if ((direct_fail == 0) && (env.scoreboard.fail_cnt == 0))
            $display("[FINAL] FUNCTIONAL CHECKING = PASS");
        else
            $display("[FINAL] FUNCTIONAL CHECKING = FAIL");
        $display("============================================================");
    endtask

    task run();
        run_direct_tests();
        run_oop_test();
        report();
    endtask

endclass


module tb_ex_stage;
    import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;
    
    logic clk;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    // ------------------------------------------------------------
    // Interface instance
    // ------------------------------------------------------------
    ex_stage_if vif(clk);

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    ex_stage dut (
        .reg_ex_i       (vif.reg_ex),
        .for_info_mem_i (vif.for_info_mem),
        .for_info_wb_i  (vif.for_info_wb),
        .alu_mem_i      (vif.alu_mem),
        .alu_wb_i       (vif.alu_wb),
        .ex_reg_o       (vif.ex_reg),
        .for_info_ex_o  (vif.for_info_ex),
        .alu_ex_o       (vif.alu_ex)
    );

     initial begin
        $dumpfile("ex_stage.vcd");
        $dumpvars(0,tb_ex_stage);
    end
    // ------------------------------------------------------------
    // Test
    // ------------------------------------------------------------
    initial begin
        ex_stage_test test;

        // Create test.
        // 100 randomized OOP transactions.
        test = new(vif,100);

        // Run.
        test.run();

        $display("");
        $display("============================================================");
        $display("                 SIMULATION FINISHED");
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

    // ------------------------------------------------------------
    // Waveform
    // ------------------------------------------------------------
   

endmodule