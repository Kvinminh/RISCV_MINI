`timescale 1ns/1ps
import core_pkg::*;
import ctrl_pkg::*;
import isa_pkg::*;

// =====================================================================
// Directed test vectors - RV32I core instruction set (37 lệnh)
// =====================================================================
// R-type (10)
  localparam logic [31:0] ADD = 32'b00000000001000001000000110110011; // add  x3, x1, x2
  localparam logic [31:0] SUB = 32'b01000000011000101000001110110011; // sub  x7, x5, x6
  localparam logic [31:0] SLL = 32'b00000000101001001001010110110011; // sll  x11, x9, x10
  localparam logic [31:0] SLT = 32'b00000000111001101010011110110011; // slt  x15, x13, x14
  localparam logic [31:0] SLTU = 32'b00000001001010001011100110110011; // sltu x19, x17, x18
  localparam logic [31:0] XOR = 32'b00000001011010101100101110110011; // xor  x23, x21, x22
  localparam logic [31:0] SRL = 32'b00000001101011001101110110110011; // srl  x27, x25, x26
  localparam logic [31:0] SRA = 32'b01000001111011101101111110110011; // sra  x31, x29, x30
  localparam logic [31:0] OR = 32'b00000000010000011110010000110011; // or   x8,  x3, x4
  localparam logic [31:0] AND = 32'b00000000110001011111100000110011; // and  x16, x11, x12

  // I-type ALU (9)
  localparam logic [31:0] ADDI = 32'b00000110010000001000000100010011; // addi  x2, x1, 100
  localparam logic [31:0] SLTI = 32'b11111111101100100010001010010011; // slti  x5, x4, -5
  localparam logic [31:0] SLTIU = 32'b00001100100000110011001110010011; // sltiu x7, x6, 200
  localparam logic [31:0] XORI = 32'b00000000111101000100010010010011; // xori  x9, x8, 0x0F
  localparam logic [31:0] ORI = 32'b00001111000001010110010110010011; // ori   x11, x10, 0xF0
  localparam logic [31:0] ANDI = 32'b00001010101001100111011010010011; // andi  x13, x12, 0xAA
  localparam logic [31:0] SLLI = 32'b00000000010101110001011110010011; // slli  x15, x14, 5
  localparam logic [31:0] SRLI = 32'b00000000001110000101100010010011; // srli  x17, x16, 3
  localparam logic [31:0] SRAI = 32'b01000000011110010101100110010011; // srai  x19, x18, 7

  // Load (5)
  localparam logic [31:0] LB = 32'b00000000010000001000000100000011; // lb  x2, 4(x1)
  localparam logic [31:0] LH = 32'b00000000100000011001001000000011; // lh  x4, 8(x3)
  localparam logic [31:0] LW = 32'b11111111010000101010001100000011; // lw  x6, -12(x5)
  localparam logic [31:0] LBU = 32'b00000001000000111100010000000011; // lbu x8, 16(x7)
  localparam logic [31:0] LHU = 32'b00000001010001001101010100000011; // lhu x10, 20(x9)

  // Store (3)
  localparam logic [31:0] SB = 32'b00000000001000001000001000100011; // sb x2, 4(x1)
  localparam logic [31:0] SH = 32'b11111110010000011001110000100011; // sh x4, -8(x3)
  localparam logic [31:0] SW = 32'b00000000011000101010011000100011; // sw x6, 12(x5)

  // Branch (6)
  localparam logic [31:0] BEQ = 32'b00000000001000001000010001100011; // beq  x1, x2, +8
  localparam logic [31:0] BNE = 32'b00000000010000011001100001100011; // bne  x3, x4, +16
  localparam logic [31:0] BLT = 32'b11111110011000101100111011100011; // blt  x5, x6, -4
  localparam logic [31:0] BGE = 32'b00000000100000111101101001100011; // bge  x7, x8, +20
  localparam logic [31:0] BLTU = 32'b00000000101001001110110001100011; // bltu x9, x10, +24
  localparam logic [31:0] BGEU = 32'b11111110110001011111100011100011; // bgeu x11, x12, -16

  // Jump (2)
  localparam logic [31:0] JAL = 32'b00000010000000000000001011101111; // jal  x5, +32
  localparam logic [31:0] JALR = 32'b00000001000000011000001001100111; // jalr x4, 16(x3)

  // Upper immediate (2)
  localparam logic [31:0] LUI = 32'b00010010001101000101001010110111; // lui   x5, 0x12345
  localparam logic [31:0] AUIPC = 32'b10101011110011011110001100010111; // auipc x6, 0xABCDE


interface deco_imm_if( input logic clk);
    logic [31:0] ins;
    decode_s decode;
    logic rs1_used;
    logic rs2_used;
    logic jump_en;
    logic [31:0] imm_out;

    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output  ins;
    endclocking

    clocking mon_cb @(posedge clk );
        default input #1step output #1;
        input ins, decode, rs1_used, rs2_used, jump_en, imm_out;
    endclocking
    
    modport DRV ( clocking drv_cb, input clk);
    modport MON ( clocking mon_cb, input clk);

endinterface //deco_imm_if( ipnut logic clk)


class deco_imm_transaction;
    rand bit  [ 31:0] ins;

    // -------------------------
    // DUT outputs observed
    // -------------------------
    bit [31:0] imm_out;
    decode_s   decode;
    bit rs1_used;
    bit rs2_used;
    bit jump_en;

    // -------------------------
    // Reference expected value
    // -------------------------
    bit [31:0] expected_imm_out;
    decode_s   expected_decode;
    bit expected_rs1_used;
    bit expected_rs2_used;
    bit expected_jump_en;

     // -------------------------
    // Copy
    // -------------------------
    function void copy(deco_imm_transaction rhs);
        if (rhs == null)
            return;
        ins      = rhs.ins;
        decode   = rhs.decode;
        rs1_used = rhs.rs1_used;
        rs2_used = rhs.rs2_used;
        jump_en  = rhs.jump_en;
        imm_out  = rhs.imm_out;

    endfunction


    // -------------------------
    // Clone
    // -------------------------
    function deco_imm_transaction clone();
        deco_imm_transaction t = new();
        t.copy(this);
        return t;
    endfunction


    // -------------------------
    // String conversion
    // -------------------------
    function string convert2string();

    return $sformatf(
    "\nins=0x%08h\n imm_sel=%0d imm=0x%08h\nrs1_used=%0b rs2_used=%0b jump_en=%0b",
    ins,
    decode.imm_sel,
    imm_out,
    rs1_used,
    rs2_used,
    jump_en
    );
    endfunction
endclass

class deco_imm_generator;
    mailbox #(deco_imm_transaction ) gen2drv;

    function new(
        mailbox #(deco_imm_transaction ) gen2drv
    );
        this.gen2drv = gen2drv;
    endfunction
    
    task send(logic [31:0] ins);
        deco_imm_transaction txn;
        txn = new();
        txn.ins = ins;
        gen2drv.put(txn);
    endtask

    task run();

        send(ADD);
        send(SUB);
        send(SLL);
        send(SLT);
        send(SLTU);
        send(XOR);
        send(SRL);
        send(SRA);
        send(OR);
        send(AND);

        send(ADDI);
        send(SLTI);
        send(SLTIU);
        send(XORI);
        send(ORI);
        send(ANDI);
        send(SLLI);
        send(SRLI);
        send(SRAI);

        send(LB);
        send(LH);
        send(LW);
        send(LBU);
        send(LHU);

        send(SB);
        send(SH);
        send(SW);

        send(BEQ);
        send(BNE);
        send(BLT);
        send(BGE);
        send(BLTU);
        send(BGEU);

        send(JAL);
        send(JALR);

        send(LUI);
        send(AUIPC);
    endtask
endclass


class deco_imm_driver;
    virtual deco_imm_if.DRV vif;
    mailbox #(deco_imm_transaction ) gen2drv;

    function new(
        virtual deco_imm_if.DRV vif,
        mailbox #(deco_imm_transaction ) gen2drv
    );
        this.vif = vif;
        this.gen2drv =gen2drv;
    endfunction

    task reset_dut();
        vif.ins = 32'b0;
        repeat(3) @(negedge vif.clk);
    endtask

    task run();
    deco_imm_transaction txn;
        forever begin  
            gen2drv.get(txn);
            @(negedge vif.clk);
            vif.ins = txn.ins;
        end
    endtask
endclass




class deco_imm_ref_model;
    decode_s model_decode;
    bit model_rs1_used = 1'b0;
    bit model_rs2_used = 1'b0;
    bit model_jump_en  = 1'b0;
    bit [31:0] model_imm_out;

    function new();
        model_decode    = '0;
        model_rs1_used = 1'b0;
        model_rs2_used = 1'b0;
        model_jump_en  = 1'b0;
        model_imm_out  = 32'h0;
    endfunction


    function void reset();
        model_decode    = '0;
        model_rs1_used = 1'b0;
        model_rs2_used = 1'b0;
        model_jump_en  = 1'b0;
        model_imm_out  = 32'h0;
    endfunction

    
    // ============================================================
    // Decode + ImmGen reference model
    // ============================================================
    function void predict(
        input  bit [31:0] ins,
 
        output decode_s   exp_decode,
        output bit        exp_rs1_used,
        output bit        exp_rs2_used,
        output bit        exp_jump_en,
        output bit [31:0] exp_imm_out
    );
 
        logic [6:0] opcode;
        opcode = ins[6:0];
 
        // --------------------------------------------------------
        // Defaults (also cover unimplemented / illegal opcodes)
        // --------------------------------------------------------
        // exp_imm_out = '0;
        exp_decode = '0;
 
        exp_decode.imm_sel        = IMMGEN_I;
        exp_decode.ex_ctrl.alu_op = ALU_ADD_SUB;
        exp_decode.ex_ctrl.sel_a  = RS1_EX;
        exp_decode.ex_ctrl.sel_b  = RS2_EX;
        exp_decode.wb_ctrl.sel_wb = ALU_MEM;
 
        exp_rs1_used = 1'b0;
        exp_rs2_used = 1'b0;
        exp_jump_en  = 1'b0;
        exp_imm_out  = 32'h0;
 
 
        // ========================================================
        // Control decode
        // ========================================================
case (opcode)
 
            // ------------------------------------------------
            // R-type
            // ------------------------------------------------
            OPCODE_OP: begin
                exp_decode.ex_ctrl.sel_a  = RS1_EX;
                exp_decode.ex_ctrl.sel_b  = RS2_EX;
                exp_decode.ex_ctrl.alu_op = ALU_RTYPE;
 
                exp_decode.wb_ctrl.reg_en = 1'b1;
                exp_decode.wb_ctrl.sel_wb = ALU_MEM;
            end
 
            // ------------------------------------------------
            // I-type ALU
            // ------------------------------------------------
            OPCODE_OP_IMM: begin
                exp_decode.imm_sel        = IMMGEN_I;
 
                exp_decode.ex_ctrl.sel_a  = RS1_EX;
                exp_decode.ex_ctrl.sel_b  = IMM_EX;
                exp_decode.ex_ctrl.alu_op = ALU_ITYPE;
 
                exp_decode.wb_ctrl.reg_en = 1'b1;
                exp_decode.wb_ctrl.sel_wb = ALU_MEM;
            end
 
            // ------------------------------------------------
            // Load
            // ------------------------------------------------
            OPCODE_LOAD: begin
                exp_decode.imm_sel          = IMMGEN_I;
 
                exp_decode.ex_ctrl.sel_a    = RS1_EX;
                exp_decode.ex_ctrl.sel_b    = IMM_EX;
                exp_decode.ex_ctrl.alu_op   = ALU_ADD_SUB;
 
                exp_decode.mem_ctrl.dmem_re = 1'b1;
 
                exp_decode.wb_ctrl.reg_en   = 1'b1;
                exp_decode.wb_ctrl.sel_wb   = MEM_RDATA;
            end
 
            // ------------------------------------------------
            // Store
            // ------------------------------------------------
            OPCODE_STORE: begin
                exp_decode.imm_sel            = IMMGEN_S;
 
                exp_decode.ex_ctrl.sel_a      = RS1_EX;
                exp_decode.ex_ctrl.sel_b      = IMM_EX;
                exp_decode.ex_ctrl.alu_op     = ALU_ADD_SUB;
 
                exp_decode.mem_ctrl.dmem_wri  = 1'b1;
            end
 
            // ------------------------------------------------
            // Branch
            // ------------------------------------------------
            OPCODE_BRANCH: begin
                exp_decode.imm_sel        = IMMGEN_B;
 
                exp_decode.ex_ctrl.sel_a  = RS1_EX;
                exp_decode.ex_ctrl.sel_b  = RS2_EX;
                exp_decode.ex_ctrl.alu_op = ALU_ADD_SUB;
 
                exp_decode.br_en          = 1'b1;
            end
 
            // ------------------------------------------------
            // JAL
            // ------------------------------------------------
            OPCODE_JAL: begin
                exp_decode.imm_sel        = IMMGEN_J;
                exp_decode.jal_en         = 1'b1;
 
                exp_decode.ex_ctrl.sel_a  = PC_CUR_EX;
                exp_decode.ex_ctrl.sel_b  = IMM_EX;
                exp_decode.ex_ctrl.alu_op = ALU_ADD_SUB;
 
                exp_decode.wb_ctrl.reg_en = 1'b1;
                exp_decode.wb_ctrl.sel_wb = PC4_MEM;
            end
 
            // ------------------------------------------------
            // JALR
            // ------------------------------------------------
            OPCODE_JALR: begin
                exp_decode.imm_sel        = IMMGEN_I;
 
                exp_decode.ex_ctrl.sel_a  = RS1_EX;
                exp_decode.ex_ctrl.sel_b  = IMM_EX;
                exp_decode.ex_ctrl.alu_op = ALU_ADD_SUB;
 
                exp_decode.jalr_en        = 1'b1;
 
                exp_decode.wb_ctrl.reg_en = 1'b1;
                exp_decode.wb_ctrl.sel_wb = PC4_MEM;
            end
 
            // ------------------------------------------------
            // LUI
            // ------------------------------------------------
            OPCODE_LUI: begin
                exp_decode.imm_sel        = IMMGEN_U;
 
                exp_decode.ex_ctrl.sel_a  = ZERO_EX;
                exp_decode.ex_ctrl.sel_b  = IMM_EX;
                exp_decode.ex_ctrl.alu_op = ALU_ADD_SUB;
 
                exp_decode.wb_ctrl.reg_en = 1'b1;
                exp_decode.wb_ctrl.sel_wb = ALU_MEM;
            end
 
            // ------------------------------------------------
            // AUIPC
            // ------------------------------------------------
            OPCODE_AUIPC: begin
                exp_decode.imm_sel        = IMMGEN_U;
 
                exp_decode.ex_ctrl.sel_a  = PC_CUR_EX;
                exp_decode.ex_ctrl.sel_b  = IMM_EX;
                exp_decode.ex_ctrl.alu_op = ALU_ADD_SUB;
 
                exp_decode.wb_ctrl.reg_en = 1'b1;
                exp_decode.wb_ctrl.sel_wb = ALU_MEM;
            end
 
            // ------------------------------------------------
            // Unimplemented / illegal opcode -> NOP-like
            // ------------------------------------------------
            default: begin
                // keep defaults set above
            end
 
endcase
 
 
        // ========================================================
        // rs1_used / rs2_used
        // ========================================================
case (opcode)
 
            OPCODE_OP,
            OPCODE_BRANCH,
            OPCODE_STORE: begin
                exp_rs1_used = 1'b1;
                exp_rs2_used = 1'b1;
            end
 
            OPCODE_OP_IMM,
            OPCODE_LOAD,
            OPCODE_JALR: begin
                exp_rs1_used = 1'b1;
            end
 
            default: begin
                exp_rs1_used = 1'b0;
                exp_rs2_used = 1'b0;
            end
 
endcase
 
 
        // ========================================================
        // jump_en
        // ========================================================
        exp_jump_en = exp_decode.jal_en || exp_decode.jalr_en;
 
 
        // ========================================================
        // extension (sign/zero-extend select for loads)
        // See NOTE at top of file regarding polarity assumption.
        // ========================================================
        exp_decode.extension = (opcode == OPCODE_LOAD) && !ins[14];
 
 
        // ========================================================
        // ImmGen
        // ========================================================
        exp_imm_out = 32'h0000_0000;
        case (exp_decode.imm_sel)
 
            IMMGEN_I: begin
                exp_imm_out = {{20{ins[31]}}, ins[31:20]};
            end
 
            IMMGEN_S: begin
                exp_imm_out = {{20{ins[31]}}, ins[31:25], ins[11:7]};
            end
 
            IMMGEN_B: begin
                exp_imm_out = {{19{ins[31]}}, ins[31], ins[7],
                               ins[30:25], ins[11:8], 1'b0};
            end
 
            IMMGEN_U: begin
                exp_imm_out = {ins[31:12], 12'b0};
            end
 
            IMMGEN_J: begin
                exp_imm_out = {{11{ins[31]}}, ins[31], ins[19:12],
                               ins[20], ins[30:21], 1'b0};
            end
 
            default: begin
                exp_imm_out = 32'h0;
            end
 
        endcase
 
 
        // --------------------------------------------------------
        // Save model state
        // --------------------------------------------------------
        model_decode   = exp_decode;
        model_rs1_used = exp_rs1_used;
        model_rs2_used = exp_rs2_used;
        model_jump_en  = exp_jump_en;
        model_imm_out  = exp_imm_out;
 
    endfunction

endclass




class deco_imm_monitor;
    virtual deco_imm_if.MON vif;

    mailbox #(deco_imm_transaction) mon2sb;
    mailbox #(deco_imm_transaction) mon2cov;
   
    deco_imm_ref_model ref_model;

    function new(
        virtual deco_imm_if.MON vif,
        mailbox #(deco_imm_transaction) mon2sb,
        mailbox #(deco_imm_transaction) mon2cov,
        deco_imm_ref_model ref_model
    );
        this.vif       = vif;
        this.mon2sb    = mon2sb;
        this.mon2cov   = mon2cov;
        this.ref_model = ref_model;
    endfunction

    task run();

    deco_imm_transaction txn;

    forever begin

        @(posedge vif.clk);
        #1;

        txn = new();

        // -------------------------
        // DUT input
        // -------------------------
        txn.ins = vif.ins;

        // -------------------------
        // DUT outputs
        // -------------------------
        txn.decode    = vif.decode;
        txn.rs1_used  = vif.rs1_used;
        txn.rs2_used  = vif.rs2_used;
        txn.jump_en   = vif.jump_en;
        txn.imm_out   = vif.imm_out;

        // -------------------------
        // Reference model
        // -------------------------
        ref_model.predict(
            txn.ins,
            txn.expected_decode,
            txn.expected_rs1_used,
            txn.expected_rs2_used,
            txn.expected_jump_en,
            txn.expected_imm_out
        );

        mon2sb.put(txn.clone());
        mon2cov.put(txn.clone());
    end
endtask
endclass


class deco_imm_scoreboard;

    mailbox #(deco_imm_transaction) mon2sb;

    deco_imm_ref_model ref_model;

    int pass_cnt = 0;
    int fail_cnt = 0;

    function new(
        mailbox #(deco_imm_transaction) mon2sb
    );

        this.mon2sb = mon2sb;
        this.ref_model = new();

    endfunction


    task run();

        deco_imm_transaction txn;

        decode_s   exp_decode;
        bit        exp_rs1_used;
        bit        exp_rs2_used;
        bit        exp_jump_en;
        bit [31:0] exp_imm_out;

        forever begin

            mon2sb.get(txn);
            // --------------------------------
            // Reference model
            // --------------------------------
            ref_model.predict(
                txn.ins,
                exp_decode,
                exp_rs1_used,
                exp_rs2_used,
                exp_jump_en,
                exp_imm_out
            );


            // --------------------------------
            // Compare Decode
            // --------------------------------
            if (txn.decode !== exp_decode) begin
                fail_cnt++;
                $error(
                    "[SB][FAIL] DECODE | ins=%08h",
                    txn.ins
                );
            end

            // --------------------------------
            // Compare rs1_used
            // --------------------------------
            else if (txn.rs1_used !== exp_rs1_used) begin
                fail_cnt++;
                $error(
                    "[SB][FAIL] RS1_USED | actual=%0b expected=%0b | ins=%08h",
                    txn.rs1_used,
                    exp_rs1_used,
                    txn.ins
                );
            end


            // --------------------------------
            // Compare rs2_used
            // --------------------------------
            else if (txn.rs2_used !== exp_rs2_used) begin
                fail_cnt++;
                $error(
                    "[SB][FAIL] RS2_USED | actual=%0b expected=%0b | ins=%08h",
                    txn.rs2_used,
                    exp_rs2_used,
                    txn.ins
                );
            end
            // --------------------------------
            // Compare jump_en
            // --------------------------------
            else if (txn.jump_en !== exp_jump_en) begin
                fail_cnt++;
                $error(
                    "[SB][FAIL] JUMP_EN | actual=%0b expected=%0b | ins=%08h",
                    txn.jump_en,
                    exp_jump_en,
                    txn.ins
                );
            end
            // --------------------------------
            // Compare ImmGen
            // --------------------------------
            else if (txn.imm_out !== exp_imm_out) begin
                fail_cnt++;
                $error(
                    "[SB][FAIL] IMM_OUT | actual=%08h expected=%08h | ins=%08h",
                    txn.imm_out,
                    exp_imm_out,
                    txn.ins
                );
            end
            // --------------------------------
            // PASS
            // --------------------------------
            else begin
                pass_cnt++;
                $display(
                    "[SB][PASS] ins=%08h imm=%08h",
                    txn.ins,
                    txn.imm_out
                );
            end
        end
    endtask
endclass


class deco_imm_coverage;

    mailbox #(deco_imm_transaction) mon2cov;

    // ============================================================
    // Decode control coverage
    // ============================================================
    covergroup cg_decode with function sample(
        deco_imm_transaction t
    );
        cp_opcode : coverpoint t.ins[6:0] {
            bins R_TYPE  = {7'b0110011};
            bins I_ALU   = {7'b0010011};
            bins LOAD    = {7'b0000011};
            bins STORE   = {7'b0100011};
            bins BRANCH  = {7'b1100011};
            bins JALR    = {7'b1100111};
            bins JAL     = {7'b1101111};
            bins LUI     = {7'b0110111};
            bins AUIPC   = {7'b0010111};
            bins OTHER = default;
        }

        cp_imm_sel : coverpoint t.decode.imm_sel {
            bins I_TYPE = {IMMGEN_I};
            bins S_TYPE = {IMMGEN_S};
            bins B_TYPE = {IMMGEN_B};
            bins U_TYPE = {IMMGEN_U};
            bins J_TYPE = {IMMGEN_J};
        }

        cp_rs1_used : coverpoint t.rs1_used {

            bins unused = {0};
            bins used   = {1};
        }

        cp_rs2_used : coverpoint t.rs2_used {
            bins unused = {0};
            bins used   = {1};
        }

        cp_jump_en : coverpoint t.jump_en {
            bins no_jump = {0};
            bins jump    = {1};
        }

        cp_br_en : coverpoint t.decode.br_en {
            bins disabled = {0};
            bins enabled  = {1};
        }

        cp_jal : coverpoint t.decode.jal_en {
            bins no_jal = {0};
            bins jal    = {1};
        }

        cp_jalr : coverpoint t.decode.jalr_en {
            bins no_jalr = {0};
            bins jalr    = {1};
        }

        // Quan trọng:
        // opcode nào sử dụng immediate format nào
        cross_opcode_imm :
            cross cp_opcode, cp_imm_sel;

        // Kiểm tra instruction type và rs usage
        cross_opcode_rs1 :
            cross cp_opcode, cp_rs1_used;

        cross_opcode_rs2 :
            cross cp_opcode, cp_rs2_used;
    endgroup

    // ============================================================
    // Immediate coverage
    // ============================================================
    covergroup cg_imm with function sample(
        deco_imm_transaction t
    );
        cp_imm_sel : coverpoint t.decode.imm_sel {
            bins I_TYPE = {IMMGEN_I};
            bins S_TYPE = {IMMGEN_S};
            bins B_TYPE = {IMMGEN_B};
            bins U_TYPE = {IMMGEN_U};
            bins J_TYPE = {IMMGEN_J};
        }

        // Immediate = 0
        cp_imm_zero : coverpoint (t.imm_out == 32'h0) {
            bins zero    = {1};
            bins nonzero = {0};
        }

        // Sign của immediate
        cp_imm_sign : coverpoint t.imm_out[31] {
            bins positive = {0};
            bins negative = {1};
        }

        // Một số giá trị đặc biệt
        cp_imm_special : coverpoint t.imm_out {
            bins zero = {32'h0000_0000};

            bins plus_4  = {32'h0000_0004};
            bins plus_8  = {32'h0000_0008};
            bins plus_16 = {32'h0000_0010};

            bins minus_4  = {32'hFFFF_FFFC};
            bins minus_8  = {32'hFFFF_FFF8};
            bins minus_16 = {32'hFFFF_FFF0};

            bins other = default;
        }
        cross_imm_format_sign :
            cross cp_imm_sel, cp_imm_sign;
    endgroup


    // ============================================================
    // Decode control structure
    // ============================================================
    covergroup cg_control with function sample(
    deco_imm_transaction t
);

    cp_alu_op : coverpoint t.decode.ex_ctrl.alu_op {
        bins ADD_SUB = {ALU_ADD_SUB};
        bins RTYPE   = {ALU_RTYPE};
        bins ITYPE   = {ALU_ITYPE};
    }

    cp_imm_sel_control : coverpoint t.decode.imm_sel {
        bins I_TYPE = {IMMGEN_I};
        bins S_TYPE = {IMMGEN_S};
        bins B_TYPE = {IMMGEN_B};
        bins U_TYPE = {IMMGEN_U};
        bins J_TYPE = {IMMGEN_J};
    }

    cp_sel_a : coverpoint t.decode.ex_ctrl.sel_a {
        bins RS1  = {RS1_EX};
        bins PC   = {PC_CUR_EX};
        bins ZERO = {ZERO_EX};
    }

    cp_sel_b : coverpoint t.decode.ex_ctrl.sel_b {
        bins RS2 = {RS2_EX};
        bins IMM = {IMM_EX};
    }

    cp_reg_en : coverpoint t.decode.wb_ctrl.reg_en {
        bins disabled = {0};
        bins enabled  = {1};
    }

    cp_mem_read : coverpoint t.decode.mem_ctrl.dmem_re {
        bins no_read = {0};
        bins read    = {1};
    }

    cp_mem_write : coverpoint t.decode.mem_ctrl.dmem_wri {
        bins no_write = {0};
        bins write    = {1};
    }

    cross_alu_imm :
        cross cp_alu_op, cp_imm_sel_control;

endgroup

    // ============================================================
    // Constructor
    // ============================================================
    function new(
        mailbox #(deco_imm_transaction) mon2cov
    );
        this.mon2cov = mon2cov;
        cg_decode  = new();
        cg_imm     = new();
        cg_control = new();
    endfunction

    // ============================================================
    // Run
    // ============================================================
    task run();
        deco_imm_transaction txn;
        forever begin
            mon2cov.get(txn);
            cg_decode.sample(txn);
            cg_imm.sample(txn);
            cg_control.sample(txn);
        end
    endtask

    function void report();

    real total_cov;

    total_cov = (
        cg_decode.get_inst_coverage() +
        cg_imm.get_inst_coverage() +
        cg_control.get_inst_coverage()
    ) / 3.0;

    $display("");
    $display("============================================================");
    $display("              DECODE + IMMGEN COVERAGE REPORT");
    $display("============================================================");

    $display(
        "[COV] Decode        = %0.2f%%",
        cg_decode.get_inst_coverage()
    );

    $display(
        "[COV] Immediate     = %0.2f%%",
        cg_imm.get_inst_coverage()
    );

    $display(
        "[COV] Control       = %0.2f%%",
        cg_control.get_inst_coverage()
    );

    $display(
        "[COV] TOTAL         = %0.2f%%",
        total_cov
    );

    $display("============================================================");

endfunction
endclass



class deco_imm_agent;

    mailbox #(deco_imm_transaction) gen2drv;
    mailbox #(deco_imm_transaction) mon2sb;
    mailbox #(deco_imm_transaction) mon2cov;

    deco_imm_generator generator;
    deco_imm_driver    driver;
    deco_imm_monitor   monitor;
    deco_imm_coverage  coverage;
    deco_imm_ref_model ref_model;

    function new(virtual deco_imm_if vif);

        gen2drv = new();
        mon2sb  = new();
        mon2cov = new();
        ref_model = new();

        generator = new(gen2drv);
        driver    = new(vif, gen2drv);
        monitor   = new(vif, mon2sb, mon2cov, ref_model);
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



class deco_imm_env;

    deco_imm_agent      agent;
    deco_imm_scoreboard scoreboard;

    function new(virtual deco_imm_if vif);

        agent      = new(vif);
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
        $display("             DECODE + IMMGEN SCOREBOARD");
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


class deco_imm_test;

    virtual deco_imm_if vif;

    deco_imm_env env;

    function new(virtual deco_imm_if vif);

        this.vif = vif;
        env = new(vif);

    endfunction


    task run();

        env.run();

        // Chờ generator chạy hết 37 instruction
        #1000;

        env.report();

        $finish;

    endtask

endclass

module deco_immgen_tb_top;

    logic clk;

    deco_imm_if vif(clk);

    // ============================================================
    // Clock
    // ============================================================
    initial begin

        clk = 1'b0;

        forever
            #5 clk = ~clk;

    end

    // ------------------------------------------------------------
    // Waveform
    // ------------------------------------------------------------
    initial begin
        $dumpfile("if_stage.vcd");
        $dumpvars(0,deco_immgen_tb_top );
    end
    // ============================================================
    // DUT
    // ============================================================
    decode u_decode (
        .ins_i       (vif.ins),
        .deco_o      (vif.decode),
        .rs1_used_o  (vif.rs1_used),
        .rs2_used_o  (vif.rs2_used),
        .jump_en_o   (vif.jump_en)
    );

    immgen u_immgen (
        .ins_i       (vif.ins),
        .imm_sel_i   (vif.decode.imm_sel),
        .imm_out_o   (vif.imm_out)
    );


    // ============================================================
    // Test
    // ============================================================
    initial begin
        deco_imm_test test;
        test = new(vif);
        test.run();

          $display("");
        $display("============================================================");
        $display("                 SIMULATION FINISHED");
        $display("============================================================");

        $finish;
    end

endmodule



