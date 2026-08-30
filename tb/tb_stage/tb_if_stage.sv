`timescale 1ns/1ps
import core_pkg::*;
import ctrl_pkg::*;
import isa_pkg::*;

interface if_stage_if ( input logic clk, input logic rst_n );
   

    logic stall_pc_i;
    jump_t jump_id_i;
    if_id_reg_t if_reg_o; 


    clocking drv_cb @(posedge clk );
        default input #1step output #1;
        output  stall_pc_i, jump_id_i;
    endclocking

     clocking mon_cb @(posedge clk);
        default input #1step output #1;
        input stall_pc_i, jump_id_i, if_reg_o;
    endclocking

    modport DRV (clocking drv_cb, input clk, input rst_n );
    modport MON (clocking mon_cb, input clk, input rst_n);

endinterface


// ============================================================================
// 1. TRANSACTION CLASS
// ============================================================================
// Purpose:
//   One object = one IF-stage cycle/scenario.
//
// This is the data packet passed through:
//   Generator -> Driver -> Monitor -> Scoreboard/Coverage
// ============================================================================

class if_stage_transaction;


    rand bit        stall_pc_i;
    rand bit        jal;
    rand bit        jalr;
    rand bit        br_en;
    rand bit        br_taken;
    rand bit [31:0] jump_addr;

    // -------------------------
    // DUT outputs observed
    // -------------------------
    bit [31:0] pc_cur;
    bit [31:0] pc_4;
    bit [31:0] ins;

    // -------------------------
    // Reference expected value
    // -------------------------
    bit [31:0] expected_pc;


    constraint c_jump_addr {
        jump_addr inside {
            [32'h0000_0100 : 32'h0000_4000]
        };

        jump_addr[1:0] == 2'b00;
    }

    // function copy 
    function void copy (if_stage_transaction rhs);
        if( rhs == null) return;
        stall_pc_i  = rhs.stall_pc_i;
        jal         = rhs.jal;
        jalr        = rhs.jalr;
        br_en       = rhs.br_en;
        br_taken    = rhs.br_taken;
        jump_addr   = rhs.jump_addr;

        pc_cur      = rhs.pc_cur;
        pc_4        = rhs.pc_4;
        ins         = rhs.ins;
        expected_pc = rhs.expected_pc;
    endfunction

    // -------------------------
    // Clone
    // -------------------------
    function if_stage_transaction clone();
        if_stage_transaction t = new();
        t.copy(this);
        return t;
    endfunction

    // -------------------------
    // String conversion
    // -------------------------
  function string convert2string();
    return $sformatf(
        "\ntall=%0b br_en=%0b br_taken=%0b jal=%0b jalr=%0b\njump=0x%08h pc=0x%08h pc4=0x%08h exp=0x%08h ins=0x%08h",
        stall_pc_i, br_en, br_taken, jal, jalr,
        jump_addr, pc_cur, pc_4, expected_pc, ins
    );
endfunction


endclass    

// ============================================================
// 2.IF-STAGE IMEM MODEL
// - OOP random instruction generation
// - Direct instruction insertion
// ============================================================
class if_stage_imem;
    bit [31:0] mem [bit [31:0]];
    
    function new();
        clear();
    endfunction

    // ========================================================
    // Clear IMEM
    // ========================================================
    function void clear();
        mem.delete();
    endfunction

    // ========================================================
    // Direct insert
    //
    // Example:
    //   imem.write(32'h0000_0100, 32'h0050_0093);
    // ========================================================
    function void write(
        bit [31:0] addr,
        bit [31:0] ins
    );
        mem[addr] = ins;
    endfunction


    // ========================================================
    // Read instruction
    //
    // Example:
    //   ins = imem.read(32'h0000_0100);
    // ========================================================
    function bit [31:0] read(
        bit [31:0] addr
    );
        if (mem.exists(addr))
            return mem[addr];
        return NOP;
    endfunction


    // ========================================================
    // Random valid instruction
    //
    // Đây là random instruction hợp lệ đơn giản,
    // không random 32-bit rác.
    // ========================================================
    function bit [31:0] random_instruction();
        case ($urandom_range(0, 7))
            // ADDI x1, x0, 1
            0: return 32'h0010_0093;
            // ADDI x2, x0, 2
            1: return 32'h0020_0113;
            // ADDI x3, x0, 3
            2: return 32'h0030_0193;
            // ADDI x4, x0, 4
            3: return 32'h0040_0213;
            // ADDI x5, x0, 5
            4: return 32'h0050_0293;
            // ADD x1, x2, x3
            5: return 32'h0031_00B3;
            // SUB x1, x2, x3
            6: return 32'h4031_00B3;
            // NOP
            7: return NOP;
            default: return NOP;
        endcase
    endfunction

    // ========================================================
    // Randomize one address
    // ========================================================
    function void randomize_at(
        bit [31:0] addr
    );
        mem[addr] = random_instruction();
    endfunction

    // ========================================================
    // Randomize a range of addresses
    //
    // Example:
    //   imem.randomize_range(
    //       32'h0000_0100,
    //       32'h0000_0200
    //   );
    // ========================================================
    function void randomize_range(
        bit [31:0] start_addr,
        bit [31:0] end_addr
    );
        for (bit [31:0] addr = start_addr;
             addr <= end_addr;
             addr += 32'd4) begin
            mem[addr] = random_instruction();
        end
    endfunction


    // ========================================================
    // Randomize the addresses normally used by IF-stage test
    // ========================================================
    function void randomize_default_region();
        randomize_range(
            32'h0000_0100,
            32'h0000_0400
        );
    endfunction


    // ========================================================
    // Print IMEM contents
    // ========================================================
    function void print();
        bit [31:0] addr;
        foreach (mem[addr]) begin
            $display(
                "[IMEM] addr=0x%08h ins=0x%08h",
                addr,
                mem[addr]
            );
        end
    endfunction

//     | # | Hàm                           | Chức năng                                    |
// | - | ----------------------------- | -------------------------------------------- |
// | 1 | `new()`                       | Constructor, tạo object và clear IMEM        |
// | 2 | `clear()`                     | Xóa toàn bộ nội dung IMEM                    |
// | 3 | `write(addr, ins)`            | Ghi instruction vào địa chỉ                  |
// | 4 | `read(addr)`                  | Đọc instruction từ địa chỉ                   |
// | 5 | `random_instruction()`        | Sinh ngẫu nhiên 1 instruction hợp lệ         |
// | 6 | `randomize_at(addr)`          | Random instruction tại 1 địa chỉ             |
// | 7 | `randomize_range(start, end)` | Random instruction cho cả một vùng địa chỉ   |
// | 8 | `randomize_default_region()`  | Random vùng địa chỉ mặc định `0x100 → 0x400` |
// | 9 | `print()`                     | In toàn bộ nội dung IMEM                     |


endclass


// ============================================================================
// 2. GENERATOR CLASS
// ============================================================================
// Purpose:
//   Create randomized transactions and put them into gen2drv mailbox.
// ============================================================================

class if_stage_generator;
    mailbox #(if_stage_transaction) gen2drv;
    int num_txn;
    event done;

    function new ( 
        mailbox #( if_stage_transaction ) gen2drv,
        int num_txn
                );
                    this.gen2drv = gen2drv;
                    this.num_txn = num_txn;
    endfunction

    task run();
        if_stage_transaction txn;
        repeat ( num_txn) begin
            txn = new();
            if(txn.randomize() == 0) 
              $fatal(1, "[GEN] IF transaction randomization failed");
            gen2drv.put(txn);
        end
        -> done;
    endtask
endclass


// ============================================================================
// 3. DRIVER CLASS
// ============================================================================
// Purpose:
//   Take transactions from generator and drive DUT inputs.
//
// Timing:
//   Drive on negedge so values are stable before next posedge.
// ============================================================================

class if_stage_driver;
    virtual if_stage_if.DRV vif;
    mailbox #(if_stage_transaction) gen2drv;

    function new(
        virtual if_stage_if.DRV vif,
        mailbox #(if_stage_transaction) gen2drv
    );
        this.vif = vif;
        this.gen2drv = gen2drv; 
    endfunction

    task reset_dut();
        //vif.stall_pc_i  = 1'b0;

        vif.jump_id_i.jal       = 1'b0;
        vif.jump_id_i.jalr      = 1'b0;
        vif.jump_id_i.br_en     = 1'b0;
        vif.jump_id_i.br_taken  = 1'b0;
        vif.jump_id_i.jump_addr = '0;

        repeat(3) @(negedge vif.clk);
    endtask
    
    task run();
     if_stage_transaction txn;
     forever begin
        
     
        gen2drv.get(txn);
        @(negedge vif.clk);

        vif.stall_pc_i         = txn.stall_pc_i;
        vif.jump_id_i.jal      = txn.jal;
        vif.jump_id_i.jalr     = txn.jalr;
        vif.jump_id_i.br_en    = txn.br_en;
        vif.jump_id_i.br_taken = txn.br_taken;
        vif.jump_id_i.jump_addr = txn.jump_addr;
        end
    endtask
endclass


// ============================================================================
// Reference Model Class — IF Stage
// ============================================================================
// Purpose:
//   Independently model the IF stage.
//
// Model:
//   current PC, next PC, PC+4, instruction fetched from IMEM
//
// PC update priority:
//   if reset:        PC = 0
//   else if stall:    PC = PC
//   else if jump:      PC = jump_addr
//   else:            PC = PC + 4
//
// Jump condition: (br_taken && br_en) || jal || jalr
// ============================================================================

class if_stage_ref_model;

    bit [31:0] model_pc;

    function new();
        model_pc = 32'h0;
    endfunction

    function void reset();
        model_pc = 32'h0;
    endfunction

    function bit [31:0] predict(
        bit        rst_n,
        bit        stall_pc_i,
        bit        jal,
        bit        jalr,
        bit        br_en,
        bit        br_taken,
        bit [31:0] jump_addr
    );

        if (!rst_n)
            model_pc = 32'h0;
        else if (stall_pc_i)
            model_pc = model_pc;
        else if ((br_en && br_taken) || jal || jalr)
            model_pc = jump_addr;
        else
            model_pc = model_pc + 32'd4;

        return model_pc;
    endfunction
endclass




// ============================================================================
// 5. MONITOR CLASS
// ============================================================================
// Purpose:
//   Observe the real DUT and convert DUT activity into transactions.
//
// Outputs:
//   mon2sb  -> scoreboard
//   mon2cov -> coverage
// ============================================================================


class if_stage_monitor;
    virtual if_stage_if.MON vif;

    mailbox #(if_stage_transaction) mon2sb;
    mailbox #(if_stage_transaction) mon2cov;
   
    if_stage_ref_model ref_model;

    function new(
        virtual if_stage_if.MON vif,
        mailbox #(if_stage_transaction) mon2sb,
        mailbox #(if_stage_transaction) mon2cov,
        if_stage_ref_model ref_model
    );
        this.vif       = vif;
        this.mon2sb    = mon2sb;
        this.mon2cov   = mon2cov;
        this.ref_model = ref_model;
    endfunction
    
   task run();
        if_stage_transaction txn;

        forever begin
            @(posedge vif.clk);
            #1;

            txn = new();

            txn.stall_pc_i = vif.stall_pc_i;

            txn.jal        = vif.jump_id_i.jal;
            txn.jalr       = vif.jump_id_i.jalr;
            txn.br_en      = vif.jump_id_i.br_en;
            txn.br_taken   = vif.jump_id_i.br_taken;
            txn.jump_addr  = vif.jump_id_i.jump_addr;

            txn.pc_cur     = vif.if_reg_o.pc_cur;
            txn.pc_4       = vif.if_reg_o.pc_4;
            txn.ins        = vif.if_reg_o.ins;

            txn.expected_pc = ref_model.predict(
                vif.rst_n,
                txn.stall_pc_i,
                txn.jal,
                txn.jalr,
                txn.br_en,
                txn.br_taken,
                txn.jump_addr
            );

            mon2sb.put(txn.clone());
            mon2cov.put(txn.clone());
        end
    endtask

endclass


// ============================================================================
// 6. SCOREBOARD CLASS
// ============================================================================
// Purpose:
//   Compare actual DUT PC against independent reference model result.
//
// This is the actual PASS/FAIL checker for the OOP environment.
// ============================================================================

class if_stage_scoreboard;

    mailbox #(if_stage_transaction) mon2sb;

    int pass_cnt = 0;
    int fail_cnt = 0;

    function new(mailbox #(if_stage_transaction) mon2sb);
        this.mon2sb = mon2sb;
    endfunction

    task run();
        if_stage_transaction txn;

        forever begin
            mon2sb.get(txn);

            // During reset, DUT PC must be zero.
            if (txn.expected_pc== 0 ) begin
                if (txn.pc_cur === 32'h0) begin
                    pass_cnt++;
                    $display("[SB][PASS] RESET pc=0");
                end
                else begin
                    fail_cnt++;
                    $error(
                        "[SB][FAIL] RESET pc actual=%08h expected=00000000",
                        txn.pc_cur
                    );
                end
            end
            else if (txn.pc_cur === txn.expected_pc) begin
                pass_cnt++;
                $display(
                    "[SB][PASS] %s",
                    txn.convert2string()
                );
            end
            else begin
                fail_cnt++;
                $display("[SB] time=%0t checking transaction", $time);
                $error(
                    "[SB][FAIL] actual_pc=%08h expected_pc=%08h | %s",
                    txn.pc_cur,
                    txn.expected_pc,
                    txn.convert2string()
                );
            end
        end
    endtask
endclass



class if_stage_coverage;

    mailbox #(if_stage_transaction) mon2cov;

    // ------------------------------------------------------------
    // Covergroup: control behavior
    // ------------------------------------------------------------
    covergroup cg_control with function sample(if_stage_transaction t);

        cp_stall : coverpoint t.stall_pc_i {
            bins no_stall = {0};
            bins stall    = {1};
        }

        cp_branch_enable : coverpoint t.br_en {
            bins disabled = {0};
            bins enabled  = {1};
        }

        cp_branch_taken : coverpoint t.br_taken {
            bins not_taken = {0};
            bins taken     = {1};
        }

        cp_jal : coverpoint t.jal {
            bins no_jal = {0};
            bins jal    = {1};
        }

        cp_jalr : coverpoint t.jalr {
            bins no_jalr = {0};
            bins jalr    = {1};
        }

        cp_redirect : coverpoint
            ((t.br_en && t.br_taken) || t.jal || t.jalr) {
            bins sequential = {0};
            bins redirect   = {1};
        }

        // Important IF-stage combinations.
        cross_stall_redirect :
            cross cp_stall, cp_redirect;

        cross_branch :
            cross cp_branch_enable, cp_branch_taken;

    endgroup


    // ------------------------------------------------------------
    // Covergroup: redirect source
    // ------------------------------------------------------------
    covergroup cg_redirect with function sample(if_stage_transaction t);

        cp_redirect_source : coverpoint
            ((t.jalr) ? 2 :
             (t.jal)  ? 1 :
             ((t.br_en && t.br_taken) ? 0 : 3)) {

            bins branch = {0};
            bins jal    = {1};
            bins jalr   = {2};
            bins normal = {3};
        }

        cp_jump_target : coverpoint t.jump_addr {
            bins target_0100 = {32'h0000_0100};
            bins target_0200 = {32'h0000_0200};
            bins target_1000 = {32'h0000_1000};
            bins target_2000 = {32'h0000_2000};
            bins target_3000 = {32'h0000_3000};
            bins target_4000 = {32'h0000_4000};
        }

        cross_redirect_target :
            cross cp_redirect_source, cp_jump_target;

    endgroup


    // ------------------------------------------------------------
    // Covergroup: instruction fetch
    //
    // Current imem is asynchronous and returns memory[pc[11:2]].
    // Full ISA coverage belongs to core-level verification.
    // Here we only measure IF fetch opcode classes.
    // ------------------------------------------------------------
    covergroup cg_instruction with function sample(if_stage_transaction t);

        cp_opcode : coverpoint t.ins[6:0] {

            bins LOAD   = {7'b0000011};
            bins STORE  = {7'b0100011};
            bins OP_IMM = {7'b0010011};
            bins OP     = {7'b0110011};
            bins BRANCH = {7'b1100011};
            bins JALR   = {7'b1100111};
            bins JAL    = {7'b1101111};
            bins LUI    = {7'b0110111};
            bins AUIPC  = {7'b0010111};
            bins SYSTEM = {7'b1110011};

            bins OTHER = default;
        }

        cp_nop : coverpoint t.ins {
            bins NOP     = {32'h0000_0013};
            bins NON_NOP = default;
        }

    endgroup


    // ------------------------------------------------------------
    // Covergroup: PC properties
    // ------------------------------------------------------------
    covergroup cg_pc with function sample(if_stage_transaction t);

        cp_pc_alignment : coverpoint t.pc_cur[1:0] {
            bins aligned = {2'b00};
        }

        cp_pc4_relation : coverpoint
            (t.pc_4 == (t.pc_cur + 32'd4)) {
            bins correct = {1};
            bins wrong   = {0};
        }

        cp_pc_target : coverpoint
            (t.pc_cur == t.jump_addr) {

            bins jump_target_hit = {1};
            bins not_jump_target = {0};
        }

    endgroup


    function new(mailbox #(if_stage_transaction) mon2cov);
        this.mon2cov = mon2cov;

        cg_control    = new();
        cg_redirect   = new();
        cg_instruction = new();
        cg_pc         = new();
    endfunction


    task run();
        if_stage_transaction txn;

        forever begin
            mon2cov.get(txn);

            cg_control.sample(txn);
            cg_redirect.sample(txn);
            cg_instruction.sample(txn);
            cg_pc.sample(txn);
        end
    endtask


    // ------------------------------------------------------------
    // Direct-test sampling
    // ------------------------------------------------------------
    // Direct tests do not pass through the OOP monitor, so they are
    // explicitly sampled here. This makes DIRECT + OOP contribute
    // to the SAME functional coverage model.
    // ------------------------------------------------------------
    function void sample_direct(if_stage_transaction t);
        cg_control.sample(t);
        cg_redirect.sample(t);
        cg_instruction.sample(t);
        cg_pc.sample(t);
    endfunction

    // ------------------------------------------------------------
    // Coverage report
    // ------------------------------------------------------------
    function void report();

        $display("");
        $display("============================================================");
        $display("                 IF-STAGE COVERAGE REPORT");
        $display("============================================================");

        $display(
            "[COV] Control       = %0.2f%%",
            cg_control.get_inst_coverage()
        );

        $display(
            "[COV] Redirect      = %0.2f%%",
            cg_redirect.get_inst_coverage()
        );

        $display(
            "[COV] Instruction   = %0.2f%%",
            cg_instruction.get_inst_coverage()
        );

        $display(
            "[COV] PC            = %0.2f%%",
            cg_pc.get_inst_coverage()
        );

        $display(
            "[COV] TOTAL         = %0.2f%%",
            (
                cg_control.get_inst_coverage() +
                cg_redirect.get_inst_coverage() +
                cg_instruction.get_inst_coverage() +
                cg_pc.get_inst_coverage()
            ) / 4.0
        );

        $display("============================================================");
    endfunction

endclass





// ============================================================================
// 8. AGENT CLASS
// ============================================================================
// Purpose:
//   Package Generator + Driver + Monitor + mailboxes.
// ============================================================================

class if_stage_agent;

    virtual if_stage_if vif;

    mailbox #(if_stage_transaction) gen2drv;
    mailbox #(if_stage_transaction) mon2sb;
    mailbox #(if_stage_transaction) mon2cov;

    if_stage_generator generator;
    if_stage_driver    driver;
    if_stage_monitor   monitor;
    if_stage_ref_model ref_model;

    function new(
        virtual if_stage_if vif,
        int num_txn
    );

        this.vif = vif;

        gen2drv = new();
        mon2sb  = new();
        mon2cov = new();

        ref_model = new();

        generator = new(gen2drv, num_txn);
        driver    = new(vif.DRV, gen2drv);
        monitor   = new(vif.MON, mon2sb, mon2cov, ref_model);

    endfunction

    task run();
        fork
            generator.run();
            driver.run();
            monitor.run();
        join_none
    endtask

endclass



// ============================================================================
// 9. ENVIRONMENT CLASS
// ============================================================================
// Purpose:
//   Connect Agent + Scoreboard + Coverage.
// ============================================================================

class if_stage_env;

    if_stage_agent      agent;
    if_stage_scoreboard scoreboard;
    if_stage_coverage   coverage;

    function new(
        virtual if_stage_if vif,
        int num_txn
    );

        agent = new(vif, num_txn);

        scoreboard = new(agent.mon2sb);
        coverage   = new(agent.mon2cov);

    endfunction

    task run();
        fork
            agent.run();
            scoreboard.run();
            coverage.run();
        join_none
    endtask

endclass



// ============================================================================
// 10. TEST CLASS
// ============================================================================
// Purpose:
//   Combine:
//
//   A) DIRECT TESTS
//      Explicit cases written by engineer.
//
//   B) OOP/RANDOM TESTS
//      Generator -> Driver -> DUT -> Monitor -> Scoreboard/Coverage.
//
// This demonstrates that direct and class-based verification can coexist.
// ============================================================================

class if_stage_test;
    virtual if_stage_if vif;

    if_stage_env env;

    int direct_pass = 0;
    int direct_fail = 0;

    function new(
        virtual if_stage_if vif,
        int num_random_txn
    );
        this.vif  = vif;
        env = new(vif,num_random_txn);
    endfunction

    // ========================================================================
    // DIRECT TEST SECTION
    // ========================================================================
    // These tasks do NOT use Generator/Driver.
    // They directly drive the interface and immediately check expected result.
    // ========================================================================

    task direct_idle();
        vif.stall_pc_i          = 1'b0;
        vif.jump_id_i.jal       = 1'b0;
        vif.jump_id_i.jalr      = 1'b0;
        vif.jump_id_i.br_en     = 1'b0;
        vif.jump_id_i.br_taken  = 1'b0;
        vif.jump_id_i.jump_addr = '0;
    endtask

     task direct_check(
        string name,
        logic [31:0] actual,
        logic [31:0] expected
    );

        if (actual !== expected) begin
            direct_fail++;

            $error(
                "[DIRECT][FAIL] %s actual=%08h expected=%08h",
                name,
                actual,
                expected
            );
        end
        else begin
            direct_pass++;

            $display(
                "[DIRECT][PASS] %s value=%08h",
                name,
                actual
            );
        end
    endtask


     // ------------------------------------------------------------------------
    // DIRECT -> COVERAGE BRIDGE
    // ------------------------------------------------------------------------
    // Converts the current interface state into the same transaction
    // format used by the OOP monitor, then samples the common coverage.
    // ------------------------------------------------------------------------
    task direct_sample_cov();
        if_stage_transaction t = new();

        t.stall_pc_i = vif.stall_pc_i;
        t.jal        = vif.jump_id_i.jal;
        t.jalr       = vif.jump_id_i.jalr;
        t.br_en      = vif.jump_id_i.br_en;
        t.br_taken   = vif.jump_id_i.br_taken;
        t.jump_addr  = vif.jump_id_i.jump_addr;

        t.pc_cur     = vif.if_reg_o.pc_cur;
        t.pc_4       = vif.if_reg_o.pc_4;
        t.ins        = vif.if_reg_o.ins;

        env.coverage.sample_direct(t);
    endtask


    // ------------------------------------------------------------------------
    // DIRECT CASE 1: RESET
    // ------------------------------------------------------------------------
    task direct_reset();
        vif.rst_n = 1'b0;
        direct_idle();

        repeat (2) @(posedge vif.clk);
        #1;

        direct_check(
            "RESET: PC must be zero",
            vif.if_reg_o.pc_cur,
            32'h0
        );

        direct_sample_cov();

        vif.rst_n = 1'b1;
    endtask


    // ------------------------------------------------------------------------
    // DIRECT CASE 2: NORMAL SEQUENTIAL FETCH
    // ------------------------------------------------------------------------
    task direct_sequential();
        logic [31:0] pc_before;

        direct_idle();

        @(negedge vif.clk);
        pc_before = vif.if_reg_o.pc_cur;

        @(posedge vif.clk);
        #1;

        direct_check(
            "SEQUENTIAL: PC = old PC + 4",
            vif.if_reg_o.pc_cur,
            pc_before + 32'd4
        );

        direct_check(
            "SEQUENTIAL: PC4 = PC + 4",
            vif.if_reg_o.pc_4,
            vif.if_reg_o.pc_cur + 32'd4
        );

        direct_sample_cov();
    endtask


    // ------------------------------------------------------------------------
    // DIRECT CASE 3: STALL
    // ------------------------------------------------------------------------
    task direct_stall();
        logic [31:0] pc_before;

        direct_idle();

        @(negedge vif.clk);
        pc_before = vif.if_reg_o.pc_cur;

        vif.stall_pc_i = 1'b1;

        @(posedge vif.clk);
        #1;

        direct_check(
            "STALL: PC must hold",
            vif.if_reg_o.pc_cur,
            pc_before
        );

        direct_sample_cov();

        vif.stall_pc_i = 1'b0;
    endtask


    // ------------------------------------------------------------------------
    // DIRECT CASE 4: BRANCH TAKEN
    // ------------------------------------------------------------------------
    task direct_branch_taken();
        vif.stall_pc_i          = 1'b0;
        vif.jump_id_i.jal       = 1'b0;
        vif.jump_id_i.jalr      = 1'b0;
        vif.jump_id_i.br_en     = 1'b1;
        vif.jump_id_i.br_taken  = 1'b1;
        vif.jump_id_i.jump_addr = 32'h0000_1000;

        @(posedge vif.clk);
        #1;

        direct_check(
            "BRANCH TAKEN: PC = jump_addr",
            vif.if_reg_o.pc_cur,
            32'h0000_1000
        );

        direct_sample_cov();
        direct_idle();
    endtask


    // ------------------------------------------------------------------------
    // DIRECT CASE 5: BRANCH NOT TAKEN
    // ------------------------------------------------------------------------
    task direct_branch_not_taken();
        logic [31:0] pc_before;

        direct_idle();

        vif.jump_id_i.br_en    = 1'b1;
        vif.jump_id_i.br_taken = 1'b0;
        vif.jump_id_i.jump_addr = 32'h0000_5000;

        @(negedge vif.clk);
        pc_before = vif.if_reg_o.pc_cur;

        @(posedge vif.clk);
        #1;

        direct_check(
            "BRANCH NOT TAKEN: PC = old PC + 4",
            vif.if_reg_o.pc_cur,
            pc_before + 32'd4
        );

        direct_sample_cov();
        direct_idle();
    endtask


    // ------------------------------------------------------------------------
    // DIRECT CASE 6: JAL
    // ------------------------------------------------------------------------
    task direct_jal();
        vif.jump_id_i.jal       = 1'b1;
        vif.jump_id_i.jalr      = 1'b0;
        vif.jump_id_i.br_en     = 1'b0;
        vif.jump_id_i.br_taken  = 1'b0;
        vif.jump_id_i.jump_addr = 32'h0000_2000;
        vif.stall_pc_i          = 1'b0;

        @(posedge vif.clk);
        #1;

        direct_check(
            "JAL: PC = jump_addr",
            vif.if_reg_o.pc_cur,
            32'h0000_2000
        );

        direct_sample_cov();
        direct_idle();
    endtask


    // ------------------------------------------------------------------------
    // DIRECT CASE 7: JALR
    // ------------------------------------------------------------------------
    task direct_jalr();
        vif.jump_id_i.jal       = 1'b0;
        vif.jump_id_i.jalr      = 1'b1;
        vif.jump_id_i.br_en     = 1'b0;
        vif.jump_id_i.br_taken  = 1'b0;
        vif.jump_id_i.jump_addr = 32'h0000_3000;
        vif.stall_pc_i          = 1'b0;

        @(posedge vif.clk);
        #1;

        direct_check(
            "JALR: PC = jump_addr",
            vif.if_reg_o.pc_cur,
            32'h0000_3000
        );

        direct_sample_cov();
        direct_idle();
    endtask


    // ========================================================================
    // DIRECT TEST SUITE
    // ========================================================================

    task run_direct_tests();

        $display("");
        $display("============================================================");
        $display("                 DIRECT IF-STAGE TESTS");
        $display("============================================================");

        direct_reset();

        direct_sequential();
        direct_stall();
        direct_branch_taken();
        direct_branch_not_taken();
        direct_jal();
        direct_jalr();

        $display(
            "[DIRECT] PASS=%0d FAIL=%0d",
            direct_pass,
            direct_fail
        );

    endtask

    // ========================================================================
    // OOP TEST
    // ========================================================================
    // Start:
    //
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

//    task run_oop_test();

//     $display("");
//     $display("============================================================");
//     $display("                   OOP RANDOM TEST");
//     $display("============================================================");

//     // Reset DUT
//     vif.rst_n = 1'b0;

//     vif.stall_pc_i          = 1'b0;
//     vif.jump_id_i.jal       = 1'b0;
//     vif.jump_id_i.jalr      = 1'b0;
//     vif.jump_id_i.br_en     = 1'b0;
//     vif.jump_id_i.br_taken  = 1'b0;
//     vif.jump_id_i.jump_addr = '0;

//     // Reset reference model
//     env.agent.ref_model.reset();

//     repeat (2) @(posedge vif.clk);
//     #1;

//     // Release reset
//     vif.rst_n = 1'b1;

//     // Start OOP environment
    

//     @env.agent.generator.done;

//     repeat (5) @(posedge vif.clk);
//     #1;

//     $display("[OOP] Random generation completed.");

// endtask

task run_oop_test();

    $display("");
    $display("============================================================");
    $display("                   OOP RESET DEBUG");
    $display("============================================================");

    // Reset DUT
    vif.rst_n = 1'b0;

    vif.stall_pc_i          = 1'b0;
    vif.jump_id_i.jal       = 1'b0;
    vif.jump_id_i.jalr      = 1'b0;
    vif.jump_id_i.br_en     = 1'b0;
    vif.jump_id_i.br_taken  = 1'b0;
    vif.jump_id_i.jump_addr = '0;

    // Reset reference
    env.agent.ref_model.reset();

    $display("[DEBUG] BEFORE RESET PC = %08h",
             vif.if_reg_o.pc_cur);

    repeat (3) @(posedge vif.clk);
    #1;

    $display("[DEBUG] AFTER RESET PC = %08h",
             vif.if_reg_o.pc_cur);

    $display("[DEBUG] REF MODEL PC = %08h",
             env.agent.ref_model.model_pc);

    vif.rst_n = 1'b1;

    repeat (1) @(posedge vif.clk);
    #1;

    $display("[DEBUG] AFTER RELEASE PC = %08h",
             vif.if_reg_o.pc_cur);

endtask

     // ========================================================================
    // FINAL REPORT
    // ========================================================================

    task report();

        $display("");
        $display("============================================================");
        $display("                 IF-STAGE FINAL REPORT");
        $display("============================================================");

        $display(
            "[DIRECT] PASS=%0d FAIL=%0d",
            direct_pass,
            direct_fail
        );

        $display(
            "[OOP] SCOREBOARD PASS=%0d FAIL=%0d",
            env.agent == null ? -1 : env.scoreboard.pass_cnt,
            env.agent == null ? -1 : env.scoreboard.fail_cnt
        );

        env.coverage.report();

        if ((direct_fail == 0) &&
            (env.scoreboard.fail_cnt == 0)) begin

            $display("[FINAL] FUNCTIONAL CHECKING = PASS");
        end
        else begin

            $display("[FINAL] FUNCTIONAL CHECKING = FAIL");
        end

        $display("============================================================");
    endtask


    task run();
        run_direct_tests();
        run_oop_test();
        report();
    endtask

endclass




// ============================================================================
// 11. TOP MODULE
// ============================================================================
// Purpose:
//   Actual simulation top.
//
//   - Clock/reset
//   - Interface
//   - DUT
//   - Test object
//   - VCD waveform
// ============================================================================

module tb_if_stage;
    import core_pkg::*;

    logic clk;
    logic rst_n;

    // ------------------------------------------------------------
    // Interface instance
    // ------------------------------------------------------------
    if_stage_if vif(clk,rst_n);

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    if_stage dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .stall_pc_i  (vif.stall_pc_i),
        .jump_id_i   (vif.jump_id_i),
        .if_reg_o     (vif.if_reg_o)
    );

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------
    always #5 clk = ~clk;
    initial begin
        clk = 0;
        rst_n = 0;
        #20 rst_n = 1;
    end
    // ------------------------------------------------------------
    // Waveform
    // ------------------------------------------------------------
    initial begin
        $dumpfile("if_stage.vcd");
        $dumpvars(0, if_stage);
    end

    // ------------------------------------------------------------
    // Test
    // ------------------------------------------------------------
    initial begin

        if_stage_test test;

        // Reset starts low.
        rst_n = 1'b0;

        // Create test.
        // 100 randomized OOP transactions.
        test = new(vif, 100);

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
        #10000;

        $error("[TB] TIMEOUT");
        $finish;
    end

endmodule


