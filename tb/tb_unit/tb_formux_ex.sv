`timescale 1ns/1ps

import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
module formux_ex_top
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input  logic [REG_ADDR_W-1:0] rs1_addr_i,
    input  logic [REG_ADDR_W-1:0] rs2_addr_i,

    input  for_info_t             for_info_mem_i,
    input  for_info_t             for_info_wb_i,

    input  logic [XLEN-1:0]       rs1_data_i,
    input  logic [XLEN-1:0]       rs2_data_i,

    input  logic [1:0]            sel_a_i,
    input  logic [1:0]            sel_b_i,
    input  logic [XLEN-1:0]       pc_cur_i,
    input  logic [31:0]           immgen_i,

    input  logic [XLEN-1:0]       alu_mem_i,
    input  logic [XLEN-1:0]       alu_wb_i,

    // Output cuối cùng (từ alu_mux)
    output logic [31:0]           A_o,
    output logic [31:0]           B_o,

    // Xuất luôn tín hiệu trung gian ra ngoài để monitor quan sát (layered checking)
    output forward_e              for_ex_a_o,
    output forward_e              for_ex_b_o
);

    // Tín hiệu nội bộ nối forward_ex -> alu_mux
    forward_e for_ex_a_w;
    forward_e for_ex_b_w;

    forward_ex u_forward_ex (
        .rs1_addr_i     (rs1_addr_i),
        .rs2_addr_i     (rs2_addr_i),
        .for_info_mem_i (for_info_mem_i),
        .for_info_wb_i  (for_info_wb_i),
        .for_ex_a_o     (for_ex_a_w),
        .for_ex_b_o     (for_ex_b_w)
    );

    alu_mux u_alu_mux (
        .for_ex_a_i (for_ex_a_w),
        .for_ex_b_i (for_ex_b_w),
        .rs1_data_i (rs1_data_i),
        .rs2_data_i (rs2_data_i),
        .sel_a_i    (sel_a_i),
        .sel_b_i    (sel_b_i),
        .pc_cur_i   (pc_cur_i),
        .immgen_i   (immgen_i),
        .alu_mem_i  (alu_mem_i),
        .alu_wb_i   (alu_wb_i),
        .A_o        (A_o),
        .B_o        (B_o)
    );

    // Xuất tín hiệu trung gian ra port top-level
    assign for_ex_a_o = for_ex_a_w;
    assign for_ex_b_o = for_ex_b_w;

endmodule

interface formux_ex_if( logic clk);
    logic rst_n;
    logic [REG_ADDR_W-1:0] rs1_addr;
    logic [REG_ADDR_W-1:0] rs2_addr;
    for_info_t            for_info_mem;
    for_info_t            for_info_wb;

    forward_e            for_ex_a;
    forward_e            for_ex_b;


    // forward_e      for_ex_a;
    // forward_e      for_ex_b;
    logic [XLEN-1:0]      rs1_data;
    logic [XLEN-1:0]      rs2_data;

    logic [1:0] sel_a;
    logic [1:0] sel_b;
    logic [XLEN-1:0] pc_cur;
    logic [31:0] immgen;

    logic [XLEN-1:0]        alu_mem;
    logic [XLEN-1:0]        alu_wb;

    logic [31:0] A;
    logic [31:0] B;

    clocking drv_cb @(posedge clk);
        default input #1step output #1;
         output rs1_addr,rs2_addr,for_info_mem, for_info_wb,
            rs1_data,rs2_data,sel_a,sel_b,pc_cur,immgen,alu_mem,alu_wb,A,B;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #1;
        input rs1_addr,rs2_addr,for_info_mem, for_info_wb,for_ex_a,for_ex_b,
            rs1_data,rs2_data,sel_a,sel_b,pc_cur,immgen,alu_mem,alu_wb,A,B;
    endclocking

    modport DRV ( clocking drv_cb, input clk);
    modport MON ( clocking mon_cb, input clk);

endinterface //formux_ex_if( logic clk)


class formux_ex_transaction;
    // -------------------------
    // Inputs (drive vào DUT forward_ex + alu_mux)
    // -------------------------
    rand bit [REG_ADDR_W-1:0] rs1_addr;
    rand bit [REG_ADDR_W-1:0] rs2_addr;

    rand for_info_t for_info_mem;
    rand for_info_t for_info_wb;

    rand bit [XLEN-1:0] rs1_data;
    rand bit [XLEN-1:0] rs2_data;
    rand bit [XLEN-1:0] pc_cur;
    rand bit [XLEN-1:0] immgen;

    rand bit [1:0] sel_a;   // cần đổi sang enum thật khi bạn cho mình biết tên
    rand bit [1:0] sel_b;

    rand bit [XLEN-1:0] alu_mem;
    rand bit [XLEN-1:0] alu_wb;

    // -------------------------
    // Internal signal (output của forward_ex, input của alu_mux)
    // KHÔNG rand — DUT tự tính ra, testbench chỉ QUAN SÁT qua monitor
    // -------------------------
    forward_e for_ex_a;
    forward_e for_ex_b;

    // -------------------------
    // DUT outputs observed (A_o, B_o của alu_mux)
    // -------------------------
    bit [XLEN-1:0] A;
    bit [XLEN-1:0] B;

    // -------------------------
    // Reference expected value
    // -------------------------
    forward_e      expected_for_ex_a;   // nên check luôn cả tín hiệu trung gian
    forward_e      expected_for_ex_b;
    bit [XLEN-1:0] expected_A;
    bit [XLEN-1:0] expected_B;

    // -------------------------
    // Constraints
    // -------------------------
    constraint c_addr_valid {
        rs1_addr inside {[0:31]};
        rs2_addr inside {[0:31]};
    }

    constraint c_sel_valid {
        sel_a inside {[0:2]};   // chỉnh lại theo đúng range hợp lệ của enum thật
        sel_b inside {[0:1]};
    }

    // -------------------------
    // Copy
    // -------------------------
    function void copy(formux_ex_transaction rhs);
        if (rhs == null) return;
        this.rs1_addr     = rhs.rs1_addr;
        this.rs2_addr     = rhs.rs2_addr;
        this.for_info_mem = rhs.for_info_mem;
        this.for_info_wb  = rhs.for_info_wb;
        this.rs1_data     = rhs.rs1_data;
        this.rs2_data     = rhs.rs2_data;
        this.pc_cur       = rhs.pc_cur;
        this.immgen       = rhs.immgen;
        this.sel_a        = rhs.sel_a;
        this.sel_b        = rhs.sel_b;
        this.alu_mem      = rhs.alu_mem;
        this.alu_wb       = rhs.alu_wb;
        this.for_ex_a     = rhs.for_ex_a;
        this.for_ex_b     = rhs.for_ex_b;
        this.A            = rhs.A;
        this.B            = rhs.B;
        this.expected_for_ex_a = rhs.expected_for_ex_a;
        this.expected_for_ex_b = rhs.expected_for_ex_b;
        this.expected_A   = rhs.expected_A;
        this.expected_B   = rhs.expected_B;
    endfunction

    function formux_ex_transaction clone();
        formux_ex_transaction t = new();
        t.copy(this);
        return t;
    endfunction

    // -------------------------
    // Compare actual vs expected
    // -------------------------
    function bit compare();
        bit pass;
        pass = (for_ex_a === expected_for_ex_a) &&
               (for_ex_b === expected_for_ex_b) &&
               (A === expected_A) &&
               (B === expected_B);
        return pass;
    endfunction

endclass


class formux_ex_generator;
    mailbox #(formux_ex_transaction) gen2drv;

    int num_txn;   // số lượng transaction sẽ sinh, có thể set từ ngoài

    function new(
        mailbox #(formux_ex_transaction) gen2drv
    );
        this.gen2drv = gen2drv;
    endfunction

    task run();
        formux_ex_transaction txn;

        for (int i = 0; i < num_txn; i++) begin
            txn = new();
            if (txn.randomize() == 0) begin
                $error("[GEN] Randomization failed at txn #%0d", i);
                continue;
            end
            gen2drv.put(txn);
        //   $display("[GEN] Sent txn #%0d: rs1_addr=%0d rs2_addr=%0d sel_a=%0d sel_b=%0d",
        //   i, txn.rs1_addr, txn.rs2_addr, txn.sel_a, txn.sel_b);
        end
    endtask

endclass


class formux_ex_driver;
    virtual formux_ex_if.DRV vif;
    mailbox #(formux_ex_transaction) gen2drv;

    int txn_count = 0;
    event all_txn_done;
    int expected_txn = 0;   // set từ env/test trước khi run()

    function new(
        virtual formux_ex_if.DRV vif,
        mailbox #(formux_ex_transaction) gen2drv
    );
        this.vif = vif;
        this.gen2drv = gen2drv;
    endfunction

    task run();
        formux_ex_transaction txn;

        forever begin
            gen2drv.get(txn);
            drive(txn);

            txn_count++;
            if (expected_txn != 0 && txn_count == expected_txn) begin
                -> all_txn_done;
            end
        end
    endtask

    task drive(formux_ex_transaction txn);
        vif.drv_cb.rs1_addr     <= txn.rs1_addr;
        vif.drv_cb.rs2_addr     <= txn.rs2_addr;
        vif.drv_cb.for_info_mem <= txn.for_info_mem;
        vif.drv_cb.for_info_wb  <= txn.for_info_wb;
        vif.drv_cb.rs1_data     <= txn.rs1_data;
        vif.drv_cb.rs2_data     <= txn.rs2_data;
        vif.drv_cb.sel_a        <= txn.sel_a;
        vif.drv_cb.sel_b        <= txn.sel_b;
        vif.drv_cb.pc_cur       <= txn.pc_cur;
        vif.drv_cb.immgen       <= txn.immgen;
        vif.drv_cb.alu_mem      <= txn.alu_mem;
        vif.drv_cb.alu_wb       <= txn.alu_wb;

        @(vif.drv_cb);   // chỉ cần 1 lần chờ, để giá trị vừa gán có hiệu lực và DUT kịp sample
    endtask

    task reset();
        vif.rst_n = 0;
        repeat (2) @(vif.drv_cb);
        vif.rst_n = 1;
        @(vif.drv_cb);
    endtask
endclass


class formux_ex_ref_model;

    bit [REG_ADDR_W-1:0] model_rs1_addr;
    bit [REG_ADDR_W-1:0] model_rs2_addr;

    for_info_t model_for_info_mem;
    for_info_t model_for_info_wb;

    forward_e model_for_ex_a;
    forward_e model_for_ex_b;

    bit [XLEN-1:0]      model_rs1_data;
    bit [XLEN-1:0]      model_rs2_data;
    bit [XLEN-1:0]      model_pc_cur;
    bit [XLEN-1:0]      model_immgen;

    bit [1:0] model_sel_a;
    bit [1:0] model_sel_b;

    bit [XLEN-1:0]      model_alu_mem;
    bit [XLEN-1:0]      model_alu_wb;

    bit [XLEN-1:0] model_A;
    bit [XLEN-1:0] model_B;

    // -------------------------------------------------
    // predict: gộp lại logic của forward_ex + alu_mux
    // -------------------------------------------------
    function void predict(input formux_ex_transaction txn);

        bit [XLEN-1:0] rs1_fwd;
        bit [XLEN-1:0] rs2_fwd;

        // copy input vào state nội bộ (để debug/display nếu cần)
        model_rs1_addr     = txn.rs1_addr;
        model_rs2_addr     = txn.rs2_addr;
        model_for_info_mem = txn.for_info_mem;
        model_for_info_wb  = txn.for_info_wb;
        model_rs1_data     = txn.rs1_data;
        model_rs2_data     = txn.rs2_data;
        model_pc_cur       = txn.pc_cur;
        model_immgen       = txn.immgen;
        model_sel_a        = txn.sel_a;
        model_sel_b        = txn.sel_b;
        model_alu_mem      = txn.alu_mem;
        model_alu_wb       = txn.alu_wb;

    // ============================================================
    // DEBUG INPUT
    // ============================================================
    // $display(
    //     "[REF-IN] rs1=%0d | MEM(rd=%0d,en=%0b) | WB(rd=%0d,en=%0b)",
    //     model_rs1_addr,
    //     model_for_info_mem.rd_addr,
    //     model_for_info_mem.reg_en,
    //     model_for_info_wb.rd_addr,
    //     model_for_info_wb.reg_en
    // );
    // $display(
    // "[REF-OUT] rs1=%0d | MEM(rd=%0d,en=%0b) | model_for_ex_a=%s",
    // model_rs1_addr,
    // model_for_info_mem.rd_addr,
    // model_for_info_mem.reg_en,
    // model_for_ex_a.name()
    // );

        // ============ forward_ex logic ============
        model_for_ex_a = RD_EX;
        if (model_rs1_addr != '0) begin
            if (model_for_info_mem.reg_en && (model_rs1_addr == model_for_info_mem.rd_addr))
                model_for_ex_a = RD_MEM;
            else if (model_for_info_wb.reg_en && (model_rs1_addr == model_for_info_wb.rd_addr))
                model_for_ex_a = RD_WB;
        end
        // $display("model_for_ex_a = %0d", model_for_ex_a.name());
        model_for_ex_b = RD_EX;
        if (model_rs2_addr != '0) begin
            if (model_for_info_mem.reg_en && (model_rs2_addr == model_for_info_mem.rd_addr))
                model_for_ex_b = RD_MEM;
            else if (model_for_info_wb.reg_en && (model_rs2_addr == model_for_info_wb.rd_addr))
                model_for_ex_b = RD_WB;
        end

        // ============ alu_mux logic ============
        // tầng 1: chọn nguồn forward
        case (model_for_ex_a)
            RD_MEM:  rs1_fwd = model_alu_mem;
            RD_WB:   rs1_fwd = model_alu_wb;
            default: rs1_fwd = model_rs1_data;   // RD_EX
        endcase

        case (model_for_ex_b)
            RD_MEM:  rs2_fwd = model_alu_mem;
            RD_WB:   rs2_fwd = model_alu_wb;
            default: rs2_fwd = model_rs2_data;   // RD_EX
        endcase

        // tầng 2: chọn operand cuối cho ALU
        case (model_sel_a)
            RS1_EX:    model_A = rs1_fwd;
            PC_CUR_EX: model_A = model_pc_cur;
            ZERO_EX:   model_A = 32'b0;
            default:   model_A = rs1_fwd;
        endcase

        case (model_sel_b)
            RS2_EX:  model_B = rs2_fwd;
            IMM_EX:  model_B = model_immgen;
            default: model_B = rs2_fwd;
        endcase

        txn.expected_for_ex_a = model_for_ex_a;
        txn.expected_for_ex_b = model_for_ex_b;
        // ghi kết quả expected ngược lại transaction để so sánh
        txn.expected_A = model_A;
        txn.expected_B = model_B;
    endfunction

endclass


class formux_ex_monitor;
    virtual formux_ex_if.MON vif;
    mailbox #(formux_ex_transaction) mon2sb;
    mailbox #(formux_ex_transaction) mon2cov;
    formux_ex_ref_model ref_model;

    function new(
        virtual formux_ex_if.MON vif,
        mailbox #(formux_ex_transaction) mon2sb,
        mailbox #(formux_ex_transaction) mon2cov,
        formux_ex_ref_model ref_model
    );
        this.vif       = vif;
        this.mon2sb    = mon2sb;
        this.mon2cov   = mon2cov;
        this.ref_model = ref_model;
    endfunction

    task run();
        formux_ex_transaction txn;

        forever begin
            @(vif.mon_cb);
            txn = new();

            // -------------------------
            // Sample input đã drive
            // -------------------------
            txn.rs1_addr     = vif.mon_cb.rs1_addr;
            txn.rs2_addr     = vif.mon_cb.rs2_addr;
            txn.for_info_mem = vif.mon_cb.for_info_mem;
            txn.for_info_wb  = vif.mon_cb.for_info_wb;
            txn.rs1_data     = vif.mon_cb.rs1_data;
            txn.rs2_data     = vif.mon_cb.rs2_data;
            txn.sel_a        = vif.mon_cb.sel_a;
            txn.sel_b        = vif.mon_cb.sel_b;
            txn.pc_cur       = vif.mon_cb.pc_cur;
            txn.immgen       = vif.mon_cb.immgen;
            txn.alu_mem      = vif.mon_cb.alu_mem;
            txn.alu_wb       = vif.mon_cb.alu_wb;

            // -------------------------
            // Sample output/internal signal từ DUT
            // -------------------------
            txn.for_ex_a = vif.mon_cb.for_ex_a;
            txn.for_ex_b = vif.mon_cb.for_ex_b;
            txn.A        = vif.mon_cb.A;
            txn.B        = vif.mon_cb.B;

            // -------------------------
            // Gọi ref_model để tính expected
            // -------------------------
            ref_model.predict(txn);

            // -------------------------
            // Gửi đi cho scoreboard và coverage
            // -------------------------
            mon2sb.put(txn);
            mon2cov.put(txn);
        end
    endtask

endclass


// class formux_ex_scoreboard;
//     mailbox #(formux_ex_transaction) mon2sb;
//     int pass_cnt = 0;
//     int fail_cnt = 0;

//     function new(mailbox #(formux_ex_transaction) mon2sb);
//         this.mon2sb = mon2sb;
//     endfunction

//     task run();
//         formux_ex_transaction txn;

//         forever begin
//             mon2sb.get(txn);

//             if (txn.compare()) begin
//                 pass_cnt++;
//                $display("[SB][PASS] #%0d", pass_cnt + fail_cnt);
//             end
//             else begin
//                 fail_cnt++;
//                 $display("[SB] time=%0t checking transaction", $time);
//                 $error("[SB][FAIL] #%0d", pass_cnt + fail_cnt);
//                 $display("  rs1_addr=%0d rs2_addr=%0d",
//                          txn.rs1_addr, txn.rs2_addr);
//                 $display("  for_ex_a: actual=%s expected=%s",
//                          txn.for_ex_a.name(), txn.expected_for_ex_a.name());
//                 $display("  for_ex_b: actual=%s expected=%s",
//                          txn.for_ex_b.name(), txn.expected_for_ex_b.name());
//                 $display("  A: actual=%h expected=%h",
//                          txn.A, txn.expected_A);
//                 $display("  B: actual=%h expected=%h",
//                          txn.B, txn.expected_B);
//             end
//         end
//     endtask


    // function void report();
    //     $display("=====================================");
    //     $display("  SCOREBOARD REPORT");
    //     $display("  PASS = %0d", pass_cnt);
    //     $display("  FAIL = %0d", fail_cnt);
    //     $display("  TOTAL = %0d", pass_cnt + fail_cnt);
    //     $display("=====================================");
    //     if (fail_cnt == 0)
    //         $display("  RESULT: ALL TEST PASSED");
    //     else
    //         $display("  RESULT: TEST FAILED");
    // endfunction

//endclass
class formux_ex_scoreboard;

    mailbox #(formux_ex_transaction) mon2sb;

    int pass_cnt = 0;
    int fail_cnt = 0;

    function new(mailbox #(formux_ex_transaction) mon2sb);
        this.mon2sb = mon2sb;
    endfunction


    task run();

        formux_ex_transaction txn;

        forever begin

            mon2sb.get(txn);


            // ========================================================
            // FORWARD A
            // ========================================================
            if (txn.for_ex_a !== txn.expected_for_ex_a) begin

                fail_cnt++;

                $error(
                    "\n[SB][FAIL] FOR_EX_A\nrs1_addr       = %0d\nMEM.rd_addr    = %0d\nMEM.reg_en     = %0b\n WB.rd_addr     = %0d\nWB.reg_en      = %0b\nactual         = %s\nexpected       = %s\n",

                    txn.rs1_addr,

                    txn.for_info_mem.rd_addr,
                    txn.for_info_mem.reg_en,

                    txn.for_info_wb.rd_addr,
                    txn.for_info_wb.reg_en,

                    txn.for_ex_a.name(),
                    txn.expected_for_ex_a.name()
                );

            end
            else begin
                pass_cnt++;
            end


            // ========================================================
            // FORWARD B
            // ========================================================
            if (txn.for_ex_b !== txn.expected_for_ex_b) begin

                fail_cnt++;

                $error(
                    "\n[SB][FAIL] FOR_EX_B\nrs2_addr       = %0d\nMEM.rd_addr    = %0d\nMEM.reg_en     = %0b\nWB.rd_addr     = %0d\nWB.reg_en      = %0b\nactual         = %s\nexpected       = %s\n",

                    txn.rs2_addr,

                    txn.for_info_mem.rd_addr,
                    txn.for_info_mem.reg_en,

                    txn.for_info_wb.rd_addr,
                    txn.for_info_wb.reg_en,

                    txn.for_ex_b.name(),
                    txn.expected_for_ex_b.name()
                );

            end
            else begin
                pass_cnt++;
            end


            // ========================================================
            // A
            // ========================================================
            if (txn.A !== txn.expected_A) begin

                fail_cnt++;

                   $error(
        "[SB][FAIL] A | rs1_addr=%0d | MEM(rd=%0d,en=%0b) | WB(rd=%0d,en=%0b) | for=%s exp_for=%s | rs1_data=%08h alu_mem=%08h alu_wb=%08h | sel_a=%0d pc_cur=%08h | actual=%08h expected=%08h",

        txn.rs1_addr,

        txn.for_info_mem.rd_addr,
        txn.for_info_mem.reg_en,

        txn.for_info_wb.rd_addr,
        txn.for_info_wb.reg_en,

        txn.for_ex_a.name(),
        txn.expected_for_ex_a.name(),

        txn.rs1_data,
        txn.alu_mem,
        txn.alu_wb,

        txn.sel_a,
        txn.pc_cur,

        txn.A,
        txn.expected_A
    );

end
            else begin
                pass_cnt++;
            end


            // ========================================================
            // B
            // ========================================================
            if (txn.B !== txn.expected_B) begin

                fail_cnt++;

                $error(
                        "[SB][FAIL] B | rs2_addr=%0d | MEM(rd=%0d,en=%0b) | WB(rd=%0d,en=%0b) | for=%s exp_for=%s | rs2_data=%08h alu_mem=%08h alu_wb=%08h | sel_b=%0d immgen=%08h | actual=%08h expected=%08h",

                        txn.rs2_addr,

                        txn.for_info_mem.rd_addr,
                        txn.for_info_mem.reg_en,

                        txn.for_info_wb.rd_addr,
                        txn.for_info_wb.reg_en,

                        txn.for_ex_b.name(),
                        txn.expected_for_ex_b.name(),

                        txn.rs2_data,
                        txn.alu_mem,
                        txn.alu_wb,

                        txn.sel_b,
                        txn.immgen,

                        txn.B,
                        txn.expected_B
                    );

                end
            else begin
                pass_cnt++;
            end

        end

    endtask

endclass

// class formux_ex_coverage;

//     mailbox #(formux_ex_transaction) mon2cov;

//     // ============================================================
//     // 1. UNIT COVERAGE — forward_ex
//     // ============================================================
//     covergroup cg_forward_ex with function sample(formux_ex_transaction t);

//         // --------------------------------------------------------
//         // Forward A
//         // --------------------------------------------------------
//         cp_hazard_a : coverpoint t.for_ex_a {
//             bins no_hazard  = {RD_EX};
//             bins mem_hazard = {RD_MEM};
//             bins wb_hazard  = {RD_WB};
//         }

//         // --------------------------------------------------------
//         // Forward B
//         // --------------------------------------------------------
//         cp_hazard_b : coverpoint t.for_ex_b {
//             bins no_hazard  = {RD_EX};
//             bins mem_hazard = {RD_MEM};
//             bins wb_hazard  = {RD_WB};
//         }

//         // A/B cùng có forwarding
//         cross_dual_hazard :
//             cross cp_hazard_a, cp_hazard_b;

//         // --------------------------------------------------------
//         // Register boundary
//         // --------------------------------------------------------
//         cp_rs1_boundary : coverpoint t.rs1_addr {
//             bins x0  = {0};
//             bins x31 = {31};
//             bins mid = {[1:30]};
//         }

//         cp_rs2_boundary : coverpoint t.rs2_addr {
//             bins x0  = {0};
//             bins x31 = {31};
//             bins mid = {[1:30]};
//         }

//         // --------------------------------------------------------
//         // MEM has priority over WB
//         // --------------------------------------------------------
//         cp_priority_conflict_a : coverpoint (
//             t.for_info_mem.reg_en &&
//             t.for_info_wb.reg_en &&
//             (t.rs1_addr == t.for_info_mem.rd_addr) &&
//             (t.rs1_addr == t.for_info_wb.rd_addr)
//         ) {
//             bins conflict_case = {1};
//             bins normal_case   = {0};
//         }

//         cp_priority_conflict_b : coverpoint (
//             t.for_info_mem.reg_en &&
//             t.for_info_wb.reg_en &&
//             (t.rs2_addr == t.for_info_mem.rd_addr) &&
//             (t.rs2_addr == t.for_info_wb.rd_addr)
//         ) {
//             bins conflict_case = {1};
//             bins normal_case   = {0};
//         }

//         // --------------------------------------------------------
//         // rs1 == rs2
//         // --------------------------------------------------------
//         cp_rs1_eq_rs2 : coverpoint (
//             t.rs1_addr == t.rs2_addr
//         ) {
//             bins same_reg = {1};
//             bins diff_reg = {0};
//         }

//     endgroup


//     // ============================================================
//     // 2. UNIT COVERAGE — alu_mux
//     // ============================================================
//     covergroup cg_alu_mux with function sample(formux_ex_transaction t);

//         // --------------------------------------------------------
//         // Forwarding MUX — operand A
//         // --------------------------------------------------------
//         cp_for_a : coverpoint t.for_ex_a {
//             bins rs1_data = {RD_EX};
//             bins alu_mem  = {RD_MEM};
//             bins alu_wb   = {RD_WB};
//         }

//         // --------------------------------------------------------
//         // Forwarding MUX — operand B
//         // --------------------------------------------------------
//         cp_for_b : coverpoint t.for_ex_b {
//             bins rs2_data = {RD_EX};
//             bins alu_mem  = {RD_MEM};
//             bins alu_wb   = {RD_WB};
//         }

//         // --------------------------------------------------------
//         // Final MUX — A
//         // --------------------------------------------------------
//         cp_sel_a : coverpoint t.sel_a {
//             bins rs1_ex    = {RS1_EX};
//             bins pc_cur_ex = {PC_CUR_EX};
//             bins zero_ex   = {ZERO_EX};

//             illegal_bins invalid = default;
//         }

//         // --------------------------------------------------------
//         // Final MUX — B
//         // --------------------------------------------------------
//         cp_sel_b : coverpoint t.sel_b {
//             bins rs2_ex = {RS2_EX};
//             bins imm_ex = {IMM_EX};

//             illegal_bins invalid = default;
//         }

//         // --------------------------------------------------------
//         // Internal behavior of alu_mux
//         // --------------------------------------------------------
//         cross_mux_a :
//             cross cp_for_a, cp_sel_a;

//         cross_mux_b :
//             cross cp_for_b, cp_sel_b;

//     endgroup


//     // ============================================================
//     // 3. INTEGRATION COVERAGE
//     //    forward_ex -> alu_mux -> A_o/B_o
//     // ============================================================
//     covergroup cg_integration with function sample(formux_ex_transaction t);

//         // --------------------------------------------------------
//         // A path
//         // --------------------------------------------------------
//         cp_flow_a : coverpoint {
//             t.for_ex_a,
//             t.sel_a
//         } {

//             // Hazard thực sự đi tới A_o
//             bins mem_forward =
//                 ({RD_MEM}, {RS1_EX});

//             bins wb_forward =
//                 ({RD_WB}, {RS1_EX});

//             bins no_forward =
//                 ({RD_EX}, {RS1_EX});

//             // Forwarding bị mask bởi source khác
//             bins mem_to_zero =
//                 ({RD_MEM}, {ZERO_EX});

//             bins wb_to_zero =
//                 ({RD_WB}, {ZERO_EX});

//             bins mem_to_pc =
//                 ({RD_MEM}, {PC_CUR_EX});

//             bins wb_to_pc =
//                 ({RD_WB}, {PC_CUR_EX});
//         }

//         // --------------------------------------------------------
//         // B path
//         // --------------------------------------------------------
//         cp_flow_b : coverpoint {
//             t.for_ex_b,
//             t.sel_b
//         } {

//             // Hazard thực sự đi tới B_o
//             bins mem_forward =
//                 ({RD_MEM}, {RS2_EX});

//             bins wb_forward =
//                 ({RD_WB}, {RS2_EX});

//             bins no_forward =
//                 ({RD_EX}, {RS2_EX});

//             // Forwarding bị mask bởi immediate
//             bins mem_to_imm =
//                 ({RD_MEM}, {IMM_EX});

//             bins wb_to_imm =
//                 ({RD_WB}, {IMM_EX});
//         }

//     endgroup


//     // ============================================================
//     // Constructor
//     // ============================================================
//     function new(mailbox #(formux_ex_transaction) mon2cov);

//         this.mon2cov = mon2cov;

//         cg_forward_ex = new();
//         cg_alu_mux    = new();
//         cg_integration = new();

//     endfunction


//     // ============================================================
//     // RUN
//     // ============================================================
//     task run();

//         formux_ex_transaction txn;

//         forever begin

//             mon2cov.get(txn);

//             // Sample cả 3 scope
//             cg_forward_ex.sample(txn);
//             cg_alu_mux.sample(txn);
//             cg_integration.sample(txn);

//         end

//     endtask


    // // ============================================================
    // // REPORT
    // // ============================================================
    // function void report();

    //     $display("");
    //     $display("============================================================");
    //     $display("               FORMUX_EX COVERAGE REPORT");
    //     $display("============================================================");

    //     $display(
    //         "[COV] forward_ex  = %0.2f%%",
    //         cg_forward_ex.get_inst_coverage()
    //     );

    //     $display(
    //         "[COV] alu_mux     = %0.2f%%",
    //         cg_alu_mux.get_inst_coverage()
    //     );

    //     $display(
    //         "[COV] integration = %0.2f%%",
    //         cg_integration.get_inst_coverage()
    //     );

    //     $display("------------------------------------------------------------");

    //     $display(
    //         "[COV] Overall      = %0.2f%%",
    //         (
    //             cg_forward_ex.get_inst_coverage() +
    //             cg_alu_mux.get_inst_coverage() +
    //             cg_integration.get_inst_coverage()
    //         ) / 3.0
    //     );

    //     $display("============================================================");
    //     $display("");

    // endfunction

// endclass

// class formux_ex_coverage;

//     mailbox #(formux_ex_transaction) mon2cov;

//     // ============================================================
//     // 1. UNIT COVERAGE — forward_ex
//     // ============================================================
//     covergroup cg_forward_ex with function sample(formux_ex_transaction t);

//         // --------------------------------------------------------
//         // Forward A
//         // --------------------------------------------------------
//         cp_hazard_a : coverpoint t.for_ex_a {
//             bins no_hazard  = {RD_EX};
//             bins mem_hazard = {RD_MEM};
//             bins wb_hazard  = {RD_WB};
//         }

//         // --------------------------------------------------------
//         // Forward B
//         // --------------------------------------------------------
//         cp_hazard_b : coverpoint t.for_ex_b {
//             bins no_hazard  = {RD_EX};
//             bins mem_hazard = {RD_MEM};
//             bins wb_hazard  = {RD_WB};
//         }

//         // A/B cùng có forwarding
//         cross_dual_hazard :
//             cross cp_hazard_a, cp_hazard_b;

//         // --------------------------------------------------------
//         // Register boundary
//         // --------------------------------------------------------
//         cp_rs1_boundary : coverpoint t.rs1_addr {
//             bins x0  = {0};
//             bins x31 = {31};
//             bins mid = {[1:30]};
//         }

//         cp_rs2_boundary : coverpoint t.rs2_addr {
//             bins x0  = {0};
//             bins x31 = {31};
//             bins mid = {[1:30]};
//         }

//         // --------------------------------------------------------
//         // MEM has priority over WB
//         // --------------------------------------------------------
//         cp_priority_conflict_a : coverpoint (
//             t.for_info_mem.reg_en &&
//             t.for_info_wb.reg_en &&
//             (t.rs1_addr == t.for_info_mem.rd_addr) &&
//             (t.rs1_addr == t.for_info_wb.rd_addr)
//         ) {
//             bins conflict_case = {1};
//             bins normal_case   = {0};
//         }

//         cp_priority_conflict_b : coverpoint (
//             t.for_info_mem.reg_en &&
//             t.for_info_wb.reg_en &&
//             (t.rs2_addr == t.for_info_mem.rd_addr) &&
//             (t.rs2_addr == t.for_info_wb.rd_addr)
//         ) {
//             bins conflict_case = {1};
//             bins normal_case   = {0};
//         }

//         // --------------------------------------------------------
//         // rs1 == rs2
//         // --------------------------------------------------------
//         cp_rs1_eq_rs2 : coverpoint (
//             t.rs1_addr == t.rs2_addr
//         ) {
//             bins same_reg = {1};
//             bins diff_reg = {0};
//         }

//     endgroup


//     // ============================================================
//     // 2. UNIT COVERAGE — alu_mux
//     // ============================================================
//     covergroup cg_alu_mux with function sample(formux_ex_transaction t);

//         // --------------------------------------------------------
//         // Forwarding MUX — operand A
//         // --------------------------------------------------------
//         cp_for_a : coverpoint t.for_ex_a {
//             bins rs1_data = {RD_EX};
//             bins alu_mem  = {RD_MEM};
//             bins alu_wb   = {RD_WB};
//         }

//         // --------------------------------------------------------
//         // Forwarding MUX — operand B
//         // --------------------------------------------------------
//         cp_for_b : coverpoint t.for_ex_b {
//             bins rs2_data = {RD_EX};
//             bins alu_mem  = {RD_MEM};
//             bins alu_wb   = {RD_WB};
//         }

//         // --------------------------------------------------------
//         // Final MUX — A
//         // --------------------------------------------------------
//         cp_sel_a : coverpoint t.sel_a {
//             bins rs1_ex    = {RS1_EX};
//             bins pc_cur_ex = {PC_CUR_EX};
//             bins zero_ex   = {ZERO_EX};

//             illegal_bins invalid = default;
//         }

//         // --------------------------------------------------------
//         // Final MUX — B
//         // --------------------------------------------------------
//         cp_sel_b : coverpoint t.sel_b {
//             bins rs2_ex = {RS2_EX};
//             bins imm_ex = {IMM_EX};

//             illegal_bins invalid = default;
//         }

//         // --------------------------------------------------------
//         // Internal behavior of alu_mux
//         // --------------------------------------------------------
//         cross_mux_a :
//             cross cp_for_a, cp_sel_a;

//         cross_mux_b :
//             cross cp_for_b, cp_sel_b;

//     endgroup


//     // ============================================================
//     // 3. INTEGRATION COVERAGE
//     //    forward_ex -> alu_mux -> A_o/B_o
//     // ============================================================
//     covergroup cg_integration with function sample(formux_ex_transaction t);

//         // ========================================================
//         // A PATH
//         // ========================================================

//         cp_flow_a_for : coverpoint t.for_ex_a {
//             bins mem_forward = {RD_MEM};
//             bins wb_forward  = {RD_WB};
//             bins no_forward  = {RD_EX};
//         }

//         cp_flow_a_sel : coverpoint t.sel_a {
//             bins rs1_ex    = {RS1_EX};
//             bins zero_ex   = {ZERO_EX};
//             bins pc_cur_ex = {PC_CUR_EX};

//             illegal_bins invalid = default;
//         }

//         // --------------------------------------------------------
//         // Chỉ cover các combination có ý nghĩa
//         // --------------------------------------------------------
//         cross_flow_a :
//             cross cp_flow_a_for, cp_flow_a_sel {

//             // Hazard thực sự đi tới A_o
//             bins mem_forward =
//                 binsof(cp_flow_a_for.mem_forward) &&
//                 binsof(cp_flow_a_sel.rs1_ex);

//             bins wb_forward =
//                 binsof(cp_flow_a_for.wb_forward) &&
//                 binsof(cp_flow_a_sel.rs1_ex);

//             bins no_forward =
//                 binsof(cp_flow_a_for.no_forward) &&
//                 binsof(cp_flow_a_sel.rs1_ex);

//             // Forwarding bị mask bởi source khác
//             bins mem_to_zero =
//                 binsof(cp_flow_a_for.mem_forward) &&
//                 binsof(cp_flow_a_sel.zero_ex);

//             bins wb_to_zero =
//                 binsof(cp_flow_a_for.wb_forward) &&
//                 binsof(cp_flow_a_sel.zero_ex);

//             bins mem_to_pc =
//                 binsof(cp_flow_a_for.mem_forward) &&
//                 binsof(cp_flow_a_sel.pc_cur_ex);

//             bins wb_to_pc =
//                 binsof(cp_flow_a_for.wb_forward) &&
//                 binsof(cp_flow_a_sel.pc_cur_ex);
//         }


//         // ========================================================
//         // B PATH
//         // ========================================================

//         cp_flow_b_for : coverpoint t.for_ex_b {
//             bins mem_forward = {RD_MEM};
//             bins wb_forward  = {RD_WB};
//             bins no_forward  = {RD_EX};
//         }

//         cp_flow_b_sel : coverpoint t.sel_b {
//             bins rs2_ex = {RS2_EX};
//             bins imm_ex = {IMM_EX};

//             illegal_bins invalid = default;
//         }

//         // --------------------------------------------------------
//         // Chỉ cover các combination có ý nghĩa
//         // --------------------------------------------------------
//         cross_flow_b :
//             cross cp_flow_b_for, cp_flow_b_sel {

//             // Hazard thực sự đi tới B_o
//             bins mem_forward =
//                 binsof(cp_flow_b_for.mem_forward) &&
//                 binsof(cp_flow_b_sel.rs2_ex);

//             bins wb_forward =
//                 binsof(cp_flow_b_for.wb_forward) &&
//                 binsof(cp_flow_b_sel.rs2_ex);

//             bins no_forward =
//                 binsof(cp_flow_b_for.no_forward) &&
//                 binsof(cp_flow_b_sel.rs2_ex);

//             // Forwarding bị mask bởi immediate
//             bins mem_to_imm =
//                 binsof(cp_flow_b_for.mem_forward) &&
//                 binsof(cp_flow_b_sel.imm_ex);

//             bins wb_to_imm =
//                 binsof(cp_flow_b_for.wb_forward) &&
//                 binsof(cp_flow_b_sel.imm_ex);
//         }

//     endgroup


//     // ============================================================
//     // Constructor
//     // ============================================================
//     function new(mailbox #(formux_ex_transaction) mon2cov);

//         this.mon2cov = mon2cov;

//         cg_forward_ex  = new();
//         cg_alu_mux     = new();
//         cg_integration = new();

//     endfunction


//     // ============================================================
//     // RUN
//     // ============================================================
//     task run();

//         formux_ex_transaction txn;

//         forever begin

//             mon2cov.get(txn);

//             // Sample cả 3 scope
//             cg_forward_ex.sample(txn);
//             cg_alu_mux.sample(txn);
//             cg_integration.sample(txn);

//         end

//     endtask

//      // ============================================================
//     // REPORT
//     // ============================================================
//     function void report();

//         $display("");
//         $display("============================================================");
//         $display("               FORMUX_EX COVERAGE REPORT");
//         $display("============================================================");

//         $display(
//             "[COV] forward_ex  = %0.2f%%",
//             cg_forward_ex.get_inst_coverage()
//         );

//         $display(
//             "[COV] alu_mux     = %0.2f%%",
//             cg_alu_mux.get_inst_coverage()
//         );

//         $display(
//             "[COV] integration = %0.2f%%",
//             cg_integration.get_inst_coverage()
//         );

//         $display("------------------------------------------------------------");

//         $display(
//             "[COV] Overall      = %0.2f%%",
//             (
//                 cg_forward_ex.get_inst_coverage() +
//                 cg_alu_mux.get_inst_coverage() +
//                 cg_integration.get_inst_coverage()
//             ) / 3.0
//         );

//         $display("============================================================");
//         $display("");

//     endfunction
// endclass


class formux_ex_coverage;

    mailbox #(formux_ex_transaction) mon2cov;


    // ============================================================
    // 1. UNIT COVERAGE — forward_ex
    // ============================================================
    covergroup cg_forward_ex with function sample(
        formux_ex_transaction t
    );

        // --------------------------------------------------------
        // Forward A
        // --------------------------------------------------------
        cp_hazard_a : coverpoint t.for_ex_a {
            bins no_hazard  = {RD_EX};
            bins mem_hazard = {RD_MEM};
            bins wb_hazard  = {RD_WB};
        }

        // --------------------------------------------------------
        // Forward B
        // --------------------------------------------------------
        cp_hazard_b : coverpoint t.for_ex_b {
            bins no_hazard  = {RD_EX};
            bins mem_hazard = {RD_MEM};
            bins wb_hazard  = {RD_WB};
        }

        // --------------------------------------------------------
        // A/B cùng có forwarding
        // --------------------------------------------------------
        //
        // Không dùng cross để tránh phụ thuộc vào
        // functional coverage nâng cao của Verilator.
        //
        cp_dual_forward : coverpoint (
            (t.for_ex_a != RD_EX) &&
            (t.for_ex_b != RD_EX)
        ) {
            bins dual_forward = {1};
            bins not_dual     = {0};
        }

        // --------------------------------------------------------
        // Register boundary
        // --------------------------------------------------------
        cp_rs1_boundary : coverpoint t.rs1_addr {
            bins x0  = {0};
            bins x31 = {31};
            bins mid = {[1:30]};
        }

        cp_rs2_boundary : coverpoint t.rs2_addr {
            bins x0  = {0};
            bins x31 = {31};
            bins mid = {[1:30]};
        }

        // --------------------------------------------------------
        // MEM has priority over WB — operand A
        // --------------------------------------------------------
        cp_priority_conflict_a : coverpoint (
            t.for_info_mem.reg_en &&
            t.for_info_wb.reg_en &&
            (t.rs1_addr == t.for_info_mem.rd_addr) &&
            (t.rs1_addr == t.for_info_wb.rd_addr)
        ) {
            bins conflict_case = {1};
            bins normal_case   = {0};
        }

        // --------------------------------------------------------
        // MEM has priority over WB — operand B
        // --------------------------------------------------------
        cp_priority_conflict_b : coverpoint (
            t.for_info_mem.reg_en &&
            t.for_info_wb.reg_en &&
            (t.rs2_addr == t.for_info_mem.rd_addr) &&
            (t.rs2_addr == t.for_info_wb.rd_addr)
        ) {
            bins conflict_case = {1};
            bins normal_case   = {0};
        }

        // --------------------------------------------------------
        // rs1 == rs2
        // --------------------------------------------------------
        cp_rs1_eq_rs2 : coverpoint (
            t.rs1_addr == t.rs2_addr
        ) {
            bins same_reg = {1};
            bins diff_reg = {0};
        }

    endgroup


    // ============================================================
    // 2. UNIT COVERAGE — alu_mux
    // ============================================================
    covergroup cg_alu_mux with function sample(
        formux_ex_transaction t
    );

        // --------------------------------------------------------
        // Forwarding MUX — operand A
        // --------------------------------------------------------
        cp_for_a : coverpoint t.for_ex_a {
            bins rs1_data = {RD_EX};
            bins alu_mem  = {RD_MEM};
            bins alu_wb   = {RD_WB};
        }

        // --------------------------------------------------------
        // Forwarding MUX — operand B
        // --------------------------------------------------------
        cp_for_b : coverpoint t.for_ex_b {
            bins rs2_data = {RD_EX};
            bins alu_mem  = {RD_MEM};
            bins alu_wb   = {RD_WB};
        }

        // --------------------------------------------------------
        // Final MUX — A
        // --------------------------------------------------------
        cp_sel_a : coverpoint t.sel_a {
            bins rs1_ex    = {RS1_EX};
            bins pc_cur_ex = {PC_CUR_EX};
            bins zero_ex   = {ZERO_EX};
        }

        // --------------------------------------------------------
        // Final MUX — B
        // --------------------------------------------------------
        cp_sel_b : coverpoint t.sel_b {
            bins rs2_ex = {RS2_EX};
            bins imm_ex = {IMM_EX};
        }

        // --------------------------------------------------------
        // Forward A + select A
        // --------------------------------------------------------
        cp_mux_a_behavior : coverpoint (
            (t.for_ex_a == RD_EX)  && (t.sel_a == RS1_EX)
        ) {
            bins rs1_from_ex = {1};
        }

        cp_mux_a_mem : coverpoint (
            (t.for_ex_a == RD_MEM) && (t.sel_a == RS1_EX)
        ) {
            bins mem_to_rs1 = {1};
        }

        cp_mux_a_wb : coverpoint (
            (t.for_ex_a == RD_WB) && (t.sel_a == RS1_EX)
        ) {
            bins wb_to_rs1 = {1};
        }

        // --------------------------------------------------------
        // Forward B + select B
        // --------------------------------------------------------
        cp_mux_b_behavior : coverpoint (
            (t.for_ex_b == RD_EX) && (t.sel_b == RS2_EX)
        ) {
            bins rs2_from_ex = {1};
        }

        cp_mux_b_mem : coverpoint (
            (t.for_ex_b == RD_MEM) && (t.sel_b == RS2_EX)
        ) {
            bins mem_to_rs2 = {1};
        }

        cp_mux_b_wb : coverpoint (
            (t.for_ex_b == RD_WB) && (t.sel_b == RS2_EX)
        ) {
            bins wb_to_rs2 = {1};
        }

        // --------------------------------------------------------
        // Immediate selection
        // --------------------------------------------------------
        cp_b_imm : coverpoint (
            t.sel_b == IMM_EX
        ) {
            bins immediate = {1};
            bins register  = {0};
        }

        // --------------------------------------------------------
        // PC selection
        // --------------------------------------------------------
        cp_a_pc : coverpoint (
            t.sel_a == PC_CUR_EX
        ) {
            bins pc_selected = {1};
            bins not_pc      = {0};
        }

        // --------------------------------------------------------
        // ZERO selection
        // --------------------------------------------------------
        cp_a_zero : coverpoint (
            t.sel_a == ZERO_EX
        ) {
            bins zero_selected = {1};
            bins not_zero      = {0};
        }

    endgroup


    // ============================================================
    // 3. INTEGRATION COVERAGE
    //    forward_ex -> alu_mux -> A_o/B_o
    // ============================================================
    covergroup cg_integration with function sample(
        formux_ex_transaction t
    );

        // ========================================================
        // A PATH
        // ========================================================

        cp_flow_a_for : coverpoint t.for_ex_a {
            bins mem_forward = {RD_MEM};
            bins wb_forward  = {RD_WB};
            bins no_forward  = {RD_EX};
        }

        cp_flow_a_sel : coverpoint t.sel_a {
            bins rs1_ex    = {RS1_EX};
            bins zero_ex   = {ZERO_EX};
            bins pc_cur_ex = {PC_CUR_EX};
        }


        // ========================================================
        // A — REAL FORWARDING
        // ========================================================

        cp_a_mem_to_rs1 : coverpoint (
            (t.for_ex_a == RD_MEM) &&
            (t.sel_a    == RS1_EX)
        ) {
            bins hit = {1};
        }

        cp_a_wb_to_rs1 : coverpoint (
            (t.for_ex_a == RD_WB) &&
            (t.sel_a    == RS1_EX)
        ) {
            bins hit = {1};
        }

        cp_a_no_forward : coverpoint (
            (t.for_ex_a == RD_EX) &&
            (t.sel_a    == RS1_EX)
        ) {
            bins hit = {1};
        }


        // ========================================================
        // A — FORWARDING MASKED
        // ========================================================

        cp_a_mem_to_zero : coverpoint (
            (t.for_ex_a == RD_MEM) &&
            (t.sel_a    == ZERO_EX)
        ) {
            bins hit = {1};
        }

        cp_a_wb_to_zero : coverpoint (
            (t.for_ex_a == RD_WB) &&
            (t.sel_a    == ZERO_EX)
        ) {
            bins hit = {1};
        }

        cp_a_mem_to_pc : coverpoint (
            (t.for_ex_a == RD_MEM) &&
            (t.sel_a    == PC_CUR_EX)
        ) {
            bins hit = {1};
        }

        cp_a_wb_to_pc : coverpoint (
            (t.for_ex_a == RD_WB) &&
            (t.sel_a    == PC_CUR_EX)
        ) {
            bins hit = {1};
        }


        // ========================================================
        // B PATH
        // ========================================================

        cp_flow_b_for : coverpoint t.for_ex_b {
            bins mem_forward = {RD_MEM};
            bins wb_forward  = {RD_WB};
            bins no_forward  = {RD_EX};
        }

        cp_flow_b_sel : coverpoint t.sel_b {
            bins rs2_ex = {RS2_EX};
            bins imm_ex = {IMM_EX};
        }


        // ========================================================
        // B — REAL FORWARDING
        // ========================================================

        cp_b_mem_to_rs2 : coverpoint (
            (t.for_ex_b == RD_MEM) &&
            (t.sel_b    == RS2_EX)
        ) {
            bins hit = {1};
        }

        cp_b_wb_to_rs2 : coverpoint (
            (t.for_ex_b == RD_WB) &&
            (t.sel_b    == RS2_EX)
        ) {
            bins hit = {1};
        }

        cp_b_no_forward : coverpoint (
            (t.for_ex_b == RD_EX) &&
            (t.sel_b    == RS2_EX)
        ) {
            bins hit = {1};
        }


        // ========================================================
        // B — FORWARDING MASKED BY IMMEDIATE
        // ========================================================

        cp_b_mem_to_imm : coverpoint (
            (t.for_ex_b == RD_MEM) &&
            (t.sel_b    == IMM_EX)
        ) {
            bins hit = {1};
        }

        cp_b_wb_to_imm : coverpoint (
            (t.for_ex_b == RD_WB) &&
            (t.sel_b    == IMM_EX)
        ) {
            bins hit = {1};
        }

    endgroup


    // ============================================================
    // Constructor
    // ============================================================
    function new(
        mailbox #(formux_ex_transaction) mon2cov
    );

        this.mon2cov = mon2cov;

        cg_forward_ex  = new();
        cg_alu_mux     = new();
        cg_integration = new();

    endfunction


    // ============================================================
    // RUN
    // ============================================================
    task run();

        formux_ex_transaction txn;

        forever begin

            mon2cov.get(txn);

            cg_forward_ex.sample(txn);
            cg_alu_mux.sample(txn);
            cg_integration.sample(txn);

        end

    endtask


    // ============================================================
    // REPORT
    // ============================================================
    function void report();

        real cov_forward;
        real cov_alu;
        real cov_integration;
        real cov_overall;

        cov_forward     = cg_forward_ex.get_inst_coverage();
        cov_alu         = cg_alu_mux.get_inst_coverage();
        cov_integration = cg_integration.get_inst_coverage();

        cov_overall =
            (cov_forward +
             cov_alu +
             cov_integration) / 3.0;

        $display("");
        $display("============================================================");
        $display("               FORMUX_EX COVERAGE REPORT");
        $display("============================================================");

        $display(
            "[COV] forward_ex  = %0.2f%%",
            cov_forward
        );

        $display(
            "[COV] alu_mux     = %0.2f%%",
            cov_alu
        );

        $display(
            "[COV] integration = %0.2f%%",
            cov_integration
        );

        $display("------------------------------------------------------------");

        $display(
            "[COV] Overall      = %0.2f%%",
            cov_overall
        );

        $display("============================================================");
        $display("");

    endfunction

endclass

class formux_ex_agent;
    mailbox #(formux_ex_transaction) gen2drv;
    mailbox #(formux_ex_transaction) mon2sb;
    mailbox #(formux_ex_transaction) mon2cov;

    formux_ex_generator generator;
    formux_ex_driver    driver;
    formux_ex_monitor   monitor;
    formux_ex_coverage  coverage;
    formux_ex_ref_model ref_model;

    function new(virtual formux_ex_if vif);

        gen2drv = new();
        mon2sb  = new();
        mon2cov = new();

        ref_model = new();

        generator = new(gen2drv);
        driver    = new(vif.DRV, gen2drv);
        monitor   = new(vif.MON, mon2sb, mon2cov, ref_model);
        coverage  = new(mon2cov);
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


class formux_ex_env;
    formux_ex_agent      agent;
    formux_ex_scoreboard scoreboard;
    int num_random_txn;

    function new(virtual formux_ex_if vif, int num_random_txn);
        this.num_random_txn = num_random_txn;
        agent      = new(vif);
        scoreboard = new(agent.mon2sb);

        agent.generator.num_txn   = num_random_txn;
        agent.driver.expected_txn = num_random_txn;
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
        $display("                    FORMUX_EX SCOREBOARD");
        $display("============================================================");
        $display("[SB] PASS = %0d", scoreboard.pass_cnt);
        $display("[SB] FAIL = %0d", scoreboard.fail_cnt);
        $display("============================================================");
    endfunction
endclass

class formux_ex_test;

    virtual formux_ex_if vif;

    formux_ex_env env;

    int direct_pass = 0;
    int direct_fail = 0;

    function new(
        virtual formux_ex_if vif,
        int num_random_txn
    );
        this.vif = vif;
        env = new(vif, num_random_txn);
    endfunction

    // ========================================================
    // Helper: gửi 1 transaction trực tiếp xuống driver, bỏ qua generator
    // ========================================================
    task send(formux_ex_transaction txn);
        env.agent.gen2drv.put(txn);
    endtask

    // ========================================================
    // Directed case 1: MEM và WB cùng match rs1_addr -> MEM phải thắng
    // ========================================================
    task test_mem_wb_priority_a();
        formux_ex_transaction txn = new();
        txn.rs1_addr = 5;
        txn.rs2_addr = 10;
        txn.for_info_mem.rd_addr = 5;
        txn.for_info_mem.reg_en  = 1;
        txn.for_info_wb.rd_addr  = 5;
        txn.for_info_wb.reg_en   = 1;
        txn.sel_a = RS1_EX;
        txn.sel_b = RS2_EX;
        if (txn.randomize() with {
            rs1_addr == 5; rs2_addr == 10;
            for_info_mem.rd_addr == 5; for_info_mem.reg_en == 1;
            for_info_wb.rd_addr  == 5; for_info_wb.reg_en  == 1;
            sel_a == RS1_EX; sel_b == RS2_EX;
        }== 0 ) $error("[TEST] randomize with constraint failed - mem_wb_priority_a");
        send(txn);
    endtask

    // ========================================================
    // Directed case 2: rs1_addr = x0 -> không bao giờ forward, dù rd trùng 0
    // ========================================================
    task test_x0_never_hazard_a();
        formux_ex_transaction txn = new();
        if (txn.randomize()  with {
            rs1_addr == 0;
            for_info_mem.rd_addr == 0; for_info_mem.reg_en == 1;
            for_info_wb.rd_addr  == 0; for_info_wb.reg_en  == 1;
            sel_a == RS1_EX;
        }== 0) $error("[TEST] randomize with constraint failed - x0_never_hazard_a");
        send(txn);
    endtask

    // ========================================================
    // Directed case 3: có hazard nhưng bị "che" bởi sel_a = ZERO_EX
    // ========================================================
    task test_hazard_masked_by_zero_a();
        formux_ex_transaction txn = new();
        if (txn.randomize()  with {
            rs1_addr == 7;
            for_info_mem.rd_addr == 7; for_info_mem.reg_en == 1;
            sel_a == ZERO_EX;
        }== 0) $error("[TEST] randomize with constraint failed - hazard_masked_by_zero_a");
        send(txn);
    endtask

    // ========================================================
    // Directed case 4: rs1_addr == rs2_addr (đọc cùng thanh ghi)
    // ========================================================
    task test_rs1_eq_rs2();
        formux_ex_transaction txn = new();
        if (txn.randomize()  with {
            rs1_addr == rs2_addr;
            rs1_addr == 12;
            for_info_mem.rd_addr == 12; for_info_mem.reg_en == 1;
            sel_a == RS1_EX; sel_b == RS2_EX;
        }== 0) $error("[TEST] randomize with constraint failed - rs1_eq_rs2");
        send(txn);
    endtask

    // ========================================================
    // Directed case 5: regression - case bug x16 đã từng fail (thứ tự update/read)
    // ========================================================
    task test_regression_x16_wb_same_cycle();
        formux_ex_transaction txn = new();
        if (txn.randomize()  with {
            rs1_addr == 16;
            for_info_wb.rd_addr == 16; for_info_wb.reg_en == 1;
            for_info_mem.reg_en == 0;
            sel_a == RS1_EX;
        }== 0) $error("[TEST] randomize with constraint failed - regression_x16");
        send(txn);
    endtask

    // ========================================================
    // Run tất cả directed case, sau đó chạy random qua env
    // ========================================================
    task run();
        $display("[TEST] Running directed test cases...");
        test_mem_wb_priority_a();
        test_x0_never_hazard_a();
        test_hazard_masked_by_zero_a();
        test_rs1_eq_rs2();
        test_regression_x16_wb_same_cycle();

        $display("[TEST] Running random test (%0d transactions)...", env.num_random_txn);
        env.run();

        @(env.agent.driver.all_txn_done);
        #100;

        env.report();
        $finish;
    endtask

endclass



module tb_formux_ex;

    // -------------------------
    // Clock generation
    // -------------------------
    logic clk;
    initial clk = 0;
    always #5 clk = ~clk;   // 100MHz, chỉnh lại nếu project bạn dùng period khác

    // -------------------------
    // Interface instance
    // -------------------------
    formux_ex_if vif(clk);

    // -------------------------
    // DUT instance — dùng module top vừa ghép
    // -------------------------
    formux_ex_top dut (
        .rs1_addr_i     (vif.rs1_addr),
        .rs2_addr_i     (vif.rs2_addr),
        .for_info_mem_i (vif.for_info_mem),
        .for_info_wb_i  (vif.for_info_wb),
        .rs1_data_i     (vif.rs1_data),
        .rs2_data_i     (vif.rs2_data),
        .sel_a_i        (vif.sel_a),
        .sel_b_i        (vif.sel_b),
        .pc_cur_i       (vif.pc_cur),
        .immgen_i       (vif.immgen),
        .alu_mem_i      (vif.alu_mem),
        .alu_wb_i       (vif.alu_wb),
        .A_o            (vif.A),
        .B_o            (vif.B),
        .for_ex_a_o     (vif.for_ex_a),
        .for_ex_b_o     (vif.for_ex_b)
    );

    // -------------------------
    // Waveform dump — có guard, tránh sự cố file dump khổng lồ
    // -------------------------

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_formux_ex);
    end


    // -------------------------
    // Run test
    // -------------------------
    formux_ex_test test;

    initial begin
        vif.rst_n = 1;   // nếu DUT không dùng rst_n thì dòng này vô hại, giữ để tương thích interface

        test = new(vif, 500);   // 500 random transaction, cộng thêm directed case cố định
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
        #10000;

        $error("[TB] TIMEOUT");
        $finish;
    end
endmodule





