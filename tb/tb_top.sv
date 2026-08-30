// class imem_transaction;

//     rand bit [31:0] program[];
//     int size;

//     function new(int n = 0);
//         size = n;
//         program = new[n];
//     endfunction

//     function void set_instr(int index, bit [31:0] instr);
//         if (index < program.size())
//             program[index] = instr;
//     endfunction

//     function bit [31:0] get_instr(int index);
//         if (index < program.size())
//             return program[index];
//         return 32'h00000013;
//     endfunction

//     function void print();
//         foreach (program[i])
//             $display("[IMEM_TXN] [%0d] = %08h", i, program[i]);
//     endfunction

// endclass




// class cpu_commit_txn;

//     bit [31:0] pc;
//     bit [31:0] instr;

//     bit         rd_we;
//     bit [4:0]   rd;
//     bit [31:0]  rd_wdata;

//     bit         mem_we;
//     bit [31:0]  mem_addr;
//     bit [31:0]  mem_wdata;

//     function new();
//         pc       = 0;
//         instr    = 0;
//         rd_we    = 0;
//         rd       = 0;
//         rd_wdata = 0;
//         mem_we   = 0;
//         mem_addr = 0;
//         mem_wdata = 0;
//     endfunction

// endclass



// class cpu_ref_model;

//     bit [31:0] regs [0:31];
//     bit [31:0] mem  [0:4095];

//     bit [31:0] pc;

//     function new();
//         reset();
//     endfunction

//     function void reset();
//         pc = 0;

//         for (int i = 0; i < 32; i++)
//             regs[i] = 0;

//         for (int i = 0; i < 4096; i++)
//             mem[i] = 0;

//         regs[0] = 0;
//     endfunction

//     function bit [31:0] load_word(bit [31:0] addr);
//         return mem[addr[13:2]];
//     endfunction

//     function void store_word(
//         bit [31:0] addr,
//         bit [31:0] data
//     );
//         mem[addr[13:2]] = data;
//     endfunction

//     function automatic bit signed_lt(
//         bit [31:0] a,
//         bit [31:0] b
//     );
//         return $signed(a) < $signed(b);
//     endfunction

//     function automatic bit unsigned_lt(
//         bit [31:0] a,
//         bit [31:0] b
//     );
//         return a < b;
//     endfunction

//     function void execute(
//         bit [31:0] instr,
//         output cpu_commit_txn exp
//     );

//         bit [6:0] opcode;
//         bit [2:0] funct3;
//         bit [6:0] funct7;

//         bit [4:0] rd;
//         bit [4:0] rs1;
//         bit [4:0] rs2;

//         bit [31:0] a;
//         bit [31:0] b;
//         bit [31:0] result;

//         bit signed [31:0] simm;

//         bit [31:0] next_pc;

//         exp = new();

//         exp.pc    = pc;
//         exp.instr = instr;

//         opcode = instr[6:0];
//         funct3 = instr[14:12];
//         funct7 = instr[31:25];

//         rd  = instr[11:7];
//         rs1 = instr[19:15];
//         rs2 = instr[24:20];

//         a = regs[rs1];
//         b = regs[rs2];

//         next_pc = pc + 32'd4;

//         case (opcode)

//             //======================================================
//             // R-TYPE
//             //======================================================

//             7'b0110011: begin

//                 case (funct3)

//                     3'b000:
//                         result = (funct7 == 7'b0100000)
//                                ? a - b
//                                : a + b;

//                     3'b001:
//                         result = a << b[4:0];

//                     3'b010:
//                         result = signed_lt(a,b) ? 32'd1 : 32'd0;

//                     3'b011:
//                         result = unsigned_lt(a,b) ? 32'd1 : 32'd0;

//                     3'b100:
//                         result = a ^ b;

//                     3'b101:
//                         result = (funct7 == 7'b0100000)
//                                ? $signed(a) >>> b[4:0]
//                                : a >> b[4:0];

//                     3'b110:
//                         result = a | b;

//                     3'b111:
//                         result = a & b;

//                     default:
//                         result = 0;

//                 endcase

//                 if (rd != 0) begin
//                     regs[rd] = result;
//                     exp.rd_we = 1;
//                     exp.rd = rd;
//                     exp.rd_wdata = result;
//                 end
//             end

//             //======================================================
//             // I-TYPE ALU
//             //======================================================

//             7'b0010011: begin

//                 simm = $signed(instr[31:20]);

//                 case (funct3)

//                     3'b000:
//                         result = a + simm;

//                     3'b010:
//                         result = signed_lt(a,simm) ? 1 : 0;

//                     3'b011:
//                         result = unsigned_lt(a,instr[31:20]) ? 1 : 0;

//                     3'b100:
//                         result = a ^ instr[31:20];

//                     3'b110:
//                         result = a | instr[31:20];

//                     3'b111:
//                         result = a & instr[31:20];

//                     3'b001:
//                         result = a << instr[24:20];

//                     3'b101:
//                         result = (funct7 == 7'b0100000)
//                                ? $signed(a) >>> instr[24:20]
//                                : a >> instr[24:20];

//                     default:
//                         result = 0;

//                 endcase

//                 if (rd != 0) begin
//                     regs[rd] = result;
//                     exp.rd_we = 1;
//                     exp.rd = rd;
//                     exp.rd_wdata = result;
//                 end
//             end

//             //======================================================
//             // LOAD
//             //======================================================

//             7'b0000011: begin

//                 bit [31:0] addr;

//                 addr = a + $signed(instr[31:20]);

//                 case (funct3)

//                     3'b010: begin
//                         result = load_word(addr);

//                         if (rd != 0) begin
//                             regs[rd] = result;
//                             exp.rd_we = 1;
//                             exp.rd = rd;
//                             exp.rd_wdata = result;
//                         end
//                     end

//                     default: begin
//                         // Có thể mở rộng LB/LH/LBU/LHU
//                     end

//                 endcase
//             end

//             //======================================================
//             // STORE
//             //======================================================

//             7'b0100011: begin

//                 bit [31:0] addr;
//                 bit [31:0] imm_s;

//                 imm_s = {
//                     {20{instr[31]}},
//                     instr[31:25],
//                     instr[11:7]
//                 };

//                 addr = a + imm_s;

//                 if (funct3 == 3'b010) begin
//                     store_word(addr,b);

//                     exp.mem_we = 1;
//                     exp.mem_addr = addr;
//                     exp.mem_wdata = b;
//                 end
//             end

//             //======================================================
//             // BRANCH
//             //======================================================

//             7'b1100011: begin

//                 bit [31:0] imm_b;

//                 imm_b = {
//                     {19{instr[31]}},
//                     instr[31],
//                     instr[7],
//                     instr[30:25],
//                     instr[11:8],
//                     1'b0
//                 };

//                 case (funct3)

//                     3'b000:
//                         if (a == b)
//                             next_pc = pc + imm_b;

//                     3'b001:
//                         if (a != b)
//                             next_pc = pc + imm_b;

//                     3'b100:
//                         if (signed_lt(a,b))
//                             next_pc = pc + imm_b;

//                     3'b101:
//                         if (!signed_lt(a,b))
//                             next_pc = pc + imm_b;

//                     3'b110:
//                         if (unsigned_lt(a,b))
//                             next_pc = pc + imm_b;

//                     3'b111:
//                         if (!unsigned_lt(a,b))
//                             next_pc = pc + imm_b;

//                 endcase
//             end

//             //======================================================
//             // LUI
//             //======================================================

//             7'b0110111: begin

//                 result = {instr[31:12],12'b0};

//                 if (rd != 0) begin
//                     regs[rd] = result;
//                     exp.rd_we = 1;
//                     exp.rd = rd;
//                     exp.rd_wdata = result;
//                 end
//             end

//             //======================================================
//             // AUIPC
//             //======================================================

//             7'b0010111: begin

//                 result = pc + {instr[31:12],12'b0};

//                 if (rd != 0) begin
//                     regs[rd] = result;
//                     exp.rd_we = 1;
//                     exp.rd = rd;
//                     exp.rd_wdata = result;
//                 end
//             end

//             //======================================================
//             // JAL
//             //======================================================

//             7'b1101111: begin

//                 bit [31:0] imm_j;

//                 imm_j = {
//                     {11{instr[31]}},
//                     instr[31],
//                     instr[19:12],
//                     instr[20],
//                     instr[30:21],
//                     1'b0
//                 };

//                 result = pc + 4;
//                 next_pc = pc + imm_j;

//                 if (rd != 0) begin
//                     regs[rd] = result;
//                     exp.rd_we = 1;
//                     exp.rd = rd;
//                     exp.rd_wdata = result;
//                 end
//             end

//             //======================================================
//             // JALR
//             //======================================================

//             7'b1100111: begin

//                 bit [31:0] imm_i;

//                 imm_i = {{20{instr[31]}},instr[31:20]};

//                 result = pc + 4;
//                 next_pc = (a + imm_i) & ~32'd1;

//                 if (rd != 0) begin
//                     regs[rd] = result;
//                     exp.rd_we = 1;
//                     exp.rd = rd;
//                     exp.rd_wdata = result;
//                 end
//             end

//             default: begin
//             end

//         endcase

//         regs[0] = 0;
//         pc = next_pc;

//     endfunction

// endclass


// module cpu_bind_probe(
//     input logic        clk,
//     input logic        rst_n,

//     input logic [31:0] wb_pc,
//     input logic [31:0] wb_instr,
//     input logic        wb_rd_we,
//     input logic [4:0]  wb_rd,
//     input logic [31:0] wb_data
// );

//     cpu_commit_txn txn;

//     always @(posedge clk) begin
//         if (rst_n) begin

//             txn = new();

//             txn.pc       = wb_pc;
//             txn.instr    = wb_instr;
//             txn.rd_we    = wb_rd_we;
//             txn.rd       = wb_rd;
//             txn.rd_wdata = wb_data;

//             cpu_bind_mailbox.put(txn);

//         end
//     end

// endmodule



// bind top_module cpu_bind_probe u_cpu_bind_probe(
//     .clk      (clk),
//     .rst_n    (rst_n),
//     .wb_pc    (wb_stage_inst.wb_i.pc),
//     .wb_instr (wb_stage_inst.wb_i.instr),
//     .wb_rd_we (wb_stage_inst.wb_o.reg_we),
//     .wb_rd    (wb_stage_inst.wb_o.rd),
//     .wb_data  (wb_stage_inst.wb_o.data)
// );




// class cpu_scoreboard;

//     mailbox #(cpu_commit_txn) dut_mb;

//     cpu_ref_model ref;

//     function new(
//         mailbox #(cpu_commit_txn) dut_mb
//     );
//         this.dut_mb = dut_mb;
//         this.ref = new();
//     endfunction

//     task run(imem_transaction program);

//         cpu_commit_txn dut_txn;
//         cpu_commit_txn exp_txn;

//         int instr_count = 0;

//         forever begin

//             dut_mb.get(dut_txn);

//             if (instr_count >= program.program.size()) begin
//                 $display("[SB] Program finished");
//                 return;
//             end

//             ref.execute(
//                 program.program[instr_count],
//                 exp_txn
//             );

//             if (dut_txn.pc !== exp_txn.pc) begin
//                 $error(
//                     "[SB][FAIL] PC | DUT=%08h REF=%08h",
//                     dut_txn.pc,
//                     exp_txn.pc
//                 );
//             end

//             if (dut_txn.instr !== exp_txn.instr) begin
//                 $error(
//                     "[SB][FAIL] INSTR | DUT=%08h REF=%08h",
//                     dut_txn.instr,
//                     exp_txn.instr
//                 );
//             end

//             if (dut_txn.rd_we !== exp_txn.rd_we) begin
//                 $error(
//                     "[SB][FAIL] RD_WE | DUT=%0b REF=%0b",
//                     dut_txn.rd_we,
//                     exp_txn.rd_we
//                 );
//             end

//             if (exp_txn.rd_we) begin

//                 if (dut_txn.rd !== exp_txn.rd) begin
//                     $error(
//                         "[SB][FAIL] RD | DUT=x%0d REF=x%0d",
//                         dut_txn.rd,
//                         exp_txn.rd
//                     );
//                 end

//                 if (dut_txn.rd_wdata !== exp_txn.rd_wdata) begin
//                     $error(
//                         "[SB][FAIL] RD_DATA | DUT=%08h REF=%08h",
//                         dut_txn.rd_wdata,
//                         exp_txn.rd_wdata
//                     );
//                 end
//             end

//             if (dut_txn.rd_we == exp_txn.rd_we &&
//                 dut_txn.rd == exp_txn.rd &&
//                 dut_txn.rd_wdata == exp_txn.rd_wdata &&
//                 dut_txn.pc == exp_txn.pc) begin

//                 $display(
//                     "[SB][PASS] #%0d PC=%08h INSTR=%08h",
//                     instr_count,
//                     dut_txn.pc,
//                     dut_txn.instr
//                 );
//             end

//             instr_count++;

//         end

//     endtask

// endclass




// class cpu_driver;

//     task automatic load_program(
//         imem_transaction program
//     );

//         for (int i = 0; i < program.program.size(); i++) begin

//             top_dut.if_stage_inst.imem_inst.memory[i]
//                 = program.program[i];

//             $display(
//                 "[DRV] IMEM[%0d] = %08h",
//                 i,
//                 program.program[i]
//             );

//         end

//     endtask

// endclass



// class cpu_test;

//     imem_transaction program;
//     cpu_driver drv;
//     cpu_scoreboard sb;

//     function new();

//         program = new(8);

//         drv = new();

//         sb = new(cpu_bind_mailbox);

//     endfunction

//     task build_program();

//         // ADDI x1,x0,10
//         program.set_instr(
//             0,
//             32'h00A00093
//         );

//         // ADDI x2,x0,20
//         program.set_instr(
//             1,
//             32'h01400113
//         );

//         // ADD x3,x1,x2
//         program.set_instr(
//             2,
//             32'h002081B3
//         );

//         // SUB x4,x3,x1
//         program.set_instr(
//             3,
//             32'h40118233
//         );

//         // AND x5,x3,x4
//         program.set_instr(
//             4,
//             32'h0041F2B3
//         );

//         // OR x6,x3,x4
//         program.set_instr(
//             5,
//             32'h0041E333
//         );

//         // XOR x7,x3,x4
//         program.set_instr(
//             6,
//             32'h0041C3B3
//         );

//         // ADDI x0,x0,0
//         program.set_instr(
//             7,
//             32'h00000013
//         );

//     endtask

//     task run();

//         build_program();

//         program.print();

//         fork
//             sb.run(program);
//         join_none

//         drv.load_program(program);

//     endtask

// endclass





// `timescale 1ns/1ps

// module tb_cpu_top;

//     logic clk;
//     logic rst_n;

//     mailbox #(cpu_commit_txn) cpu_bind_mailbox;

//     top_module top_dut(
//         .clk   (clk),
//         .rst_n (rst_n)
//     );

//     initial clk = 0;
//     always #5 clk = ~clk;

//     initial begin

//         rst_n = 0;

//         repeat (5)
//             @(posedge clk);

//         rst_n = 1;

//     end

//     initial begin

//         cpu_test test;

//         test = new();

//         wait(rst_n == 1);

//         test.run();

//         repeat (200)
//             @(posedge clk);

//         $display("======================================");
//         $display("           CPU TEST FINISH            ");
//         $display("======================================");

//         $finish;

//     end

// endmodule


`timescale 1ns/1ps

import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;

// ============================================================
// TRANSACTION
// ============================================================

typedef enum {R_TYPE,I_TYPE,S_TYPE,B_TYPE,U_TYPE,J_TYPE} instr_fmt_e;

class imem_transaction;
    rand instr_fmt_e fmt;
    rand bit [6:0] opcode;
    rand bit [4:0] rd,rs1,rs2;
    rand bit [2:0] f3;
    rand bit [6:0] f7;
    rand bit [31:0] imm;
    bit [31:0] addr;

    constraint c_opcode_valid {
        (fmt==R_TYPE)->opcode==7'b0110011;
        (fmt==I_TYPE)->opcode inside {7'b0010011,7'b0000011};
        (fmt==S_TYPE)->opcode==7'b0100011;
        (fmt==B_TYPE)->opcode==7'b1100011;
        (fmt==U_TYPE)->opcode inside {7'b0110111,7'b0010111};
        (fmt==J_TYPE)->opcode==7'b1101111;
    }

    constraint c_field_by_fmt {
        (fmt==U_TYPE||fmt==J_TYPE)->(rs1==0&&rs2==0&&f3==0&&f7==0);
        (fmt==B_TYPE||fmt==S_TYPE)->rd==0;
        (fmt==R_TYPE)->imm==0;
        (fmt==B_TYPE||fmt==J_TYPE)->imm[0]==0;
        (fmt==I_TYPE)->$signed(imm) inside {[-2048:2047]};
        (fmt==S_TYPE)->$signed(imm) inside {[-2048:2047]};
    }

    function bit [31:0] encode();
        case(fmt)
            R_TYPE: encode={f7,rs2,rs1,f3,rd,opcode};
            I_TYPE: encode={imm[11:0],rs1,f3,rd,opcode};
            S_TYPE: encode={imm[11:5],rs2,rs1,f3,imm[4:0],opcode};
            B_TYPE: encode={imm[12],imm[10:5],rs2,rs1,f3,imm[4:1],imm[11],opcode};
            U_TYPE: encode={imm[31:12],rd,opcode};
            J_TYPE: encode={imm[20],imm[10:1],imm[11],imm[19:12],rd,opcode};
        endcase
    endfunction
endclass


class program_generator;
    imem_transaction prog[$];

    function void gen_program(int num_instr);
        prog.delete();
        for(int i=0;i<num_instr;i++) begin
            imem_transaction txn=new();
            assert(txn.randomize() with {
                if(fmt==B_TYPE)
                    $signed(imm) inside {[-i*4:(num_instr-1-i)*4]};
                if(fmt==J_TYPE)
                    $signed(imm) inside {[-i*4:(num_instr-1-i)*4]};
            }) else $fatal("[GEN] randomize failed at %0d",i);
            txn.addr=i*4;
            prog.push_back(txn);
        end
    endfunction
endclass


class instr_txn;
    bit [31:0] pc;
    bit [31:0] instr;
    bit valid;

    function new(bit [31:0] pc='0,bit [31:0] instr='0,bit valid=0);
        this.pc=pc;
        this.instr=instr;
        this.valid=valid;
    endfunction
endclass


class wb_expected_txn;
    bit reg_en;
    bit [4:0] rd_addr;
    bit [31:0] rd_data;
    bit [31:0] next_pc;

    function new();
        reg_en=0;
        rd_addr=0;
        rd_data=0;
        next_pc=0;
    endfunction
endclass


class wb_actual_txn;
    bit reg_en;
    bit [4:0] rd_addr;
    bit [31:0] rd_data;

    function new();
        reg_en=0;
        rd_addr=0;
        rd_data=0;
    endfunction
endclass


// ============================================================
// SHARED MAILBOX
// ============================================================

mailbox #(instr_txn)       instr_mbx = new();
mailbox #(wb_expected_txn) expected_wb = new();
mailbox #(wb_actual_txn)   actual_wb = new();


// ============================================================
// INTERFACE
// ============================================================

interface top_if(input logic clk);
    logic rst_n;
endinterface


class core_driver;
    virtual top_if vif;

    function new(virtual top_if vif);
        this.vif=vif;
    endfunction

    task run();
        vif.rst_n<=0;
        repeat(5) @(posedge vif.clk);
        vif.rst_n<=1;
    endtask
endclass


// ============================================================
// IF MONITOR
// ============================================================

module if_monitor
import core_pkg::*;
(
    input logic clk,
    input if_id_reg_t if_reg
);
    instr_txn tr;
    logic [31:0] last_pc;
    initial last_pc='x;

    always @(posedge clk) begin
        $display("[IF_MON] pc_cur=%08h pc_4=%08h ins=%08h",if_reg.pc_cur,if_reg.pc_4,if_reg.ins);
        if((if_reg.ins!=32'b0)&&(if_reg.pc_cur!==last_pc)) begin
            tr=new(if_reg.pc_cur,if_reg.ins,1'b1);
            instr_mbx.put(tr);
            last_pc=if_reg.pc_cur;
        end
    end
endmodule

bind if_stage if_monitor u_if_mon(.clk(clk),.if_reg(if_reg_o));


// ============================================================
// ID MONITOR
// ============================================================

module id_monitor(
    input logic clk,
    input id_ex_reg_t id_reg
);
    always @(posedge clk) begin
        $display("[ID_MON]\n  f3=%0d f7_5=%b pc_cur=%08h pc_4=%08h imm_out=%08h rd_addr=%0d rs1_addr=%0d rs2_addr=%0d rs1_data=%08h rs2_data=%08h\n  ex_ctrl:\n    alu_op=%0d sel_a=%0d sel_b=%0d\n  mem_ctrl:\n    dmem_re=%b dmem_wri=%b\n  extension=%b\n  wb_ctrl:\n    reg_en=%b sel_wb=%0d",
        id_reg.f3,id_reg.f7_5,id_reg.pc_cur,id_reg.pc_4,id_reg.imm_out,
        id_reg.rd_addr,id_reg.rs1_addr,id_reg.rs2_addr,id_reg.rs1_data,id_reg.rs2_data,
        id_reg.ex_ctrl.alu_op,id_reg.ex_ctrl.sel_a,id_reg.ex_ctrl.sel_b,
        id_reg.mem_ctrl.dmem_re,id_reg.mem_ctrl.dmem_wri,id_reg.extension,
        id_reg.wb_ctrl.reg_en,id_reg.wb_ctrl.sel_wb);
    end
endmodule

bind id_stage id_monitor u_id_mon(.clk(clk),.id_reg(id_reg_o));


// ============================================================
// EX MONITOR
// ============================================================

module ex_monitor(
    input logic clk,
    input ex_mem_reg_t ex_reg
);
    always @(posedge clk) begin
        $display("[EX_MON]\n  f3=%0d pc_4=%08h alu=%08h rs2_data=%08h rd_addr=%0d extension=%b\n  mem_ctrl:\n    dmem_re=%b dmem_wri=%b\n  wb_ctrl:\n    reg_en=%b sel_wb=%0d",
        ex_reg.f3,ex_reg.pc_4,ex_reg.alu,ex_reg.rs2_data,ex_reg.rd_addr,ex_reg.extension,
        ex_reg.mem_ctrl.dmem_re,ex_reg.mem_ctrl.dmem_wri,
        ex_reg.wb_ctrl.reg_en,ex_reg.wb_ctrl.sel_wb);
    end
endmodule

bind ex_stage ex_monitor u_ex_mon(.clk(clk),.ex_reg(ex_reg_o));


// ============================================================
// MEM MONITOR
// ============================================================

module mem_monitor(
    input logic clk,
    input mem_wb_reg_t mem_reg
);
    always @(posedge clk) begin
        $display("[MEM_MON]\n  pc_4=%08h alu_result=%08h mem_rdata=%08h rd_addr=%0d\n  wb_ctrl:\n    reg_en=%b sel_wb=%0d",
            mem_reg.pc_4,mem_reg.alu_result,mem_reg.mem_rdata,mem_reg.rd_addr,
            mem_reg.wb_ctrl.reg_en,mem_reg.wb_ctrl.sel_wb);
    end
endmodule

bind mem_stage mem_monitor u_mem_mon(.clk(clk),.mem_reg(mem_reg_o));


// ============================================================
// WB MONITOR
// ============================================================

module wb_monitor(
    input logic clk,
    input regfile_wb wb_reg
);
    wb_actual_txn tr;

    always @(posedge clk) begin
        $display("[WB_MON]\n  reg_en=%b rd_addr=%0d rd_data=%08h",wb_reg.reg_en,wb_reg.rd_addr,wb_reg.rd_data);
        if(wb_reg.reg_en) begin
            tr=new();
            tr.reg_en=wb_reg.reg_en;
            tr.rd_addr=wb_reg.rd_addr;
            tr.rd_data=wb_reg.rd_data;
            actual_wb.put(tr);
        end
    end
endmodule

bind wb_stage wb_monitor u_wb_mon(.clk(clk),.wb_reg(wb_o));


// ============================================================
// REF MODEL
// ============================================================

class top_ref_model;
    bit [31:0] regs[32];
    bit [31:0] memory[1024];
    bit [31:0] pc;
    imem_transaction prog[$];
    mailbox #(wb_expected_txn) expected_wb;

    function new(imem_transaction prog_ref[$],mailbox #(wb_expected_txn) mbx);
        this.prog=prog_ref;
        this.expected_wb=mbx;
        this.pc='0;
        foreach(regs[i]) regs[i]='0;
        foreach(memory[i]) memory[i]='0;
    endfunction

    task run();
        while((pc>>2)<prog.size()) begin
            imem_transaction ins;
            wb_expected_txn wb_data;

            ins=prog[pc>>2];
            wb_data=predict(ins);
            if(wb_data.reg_en)
                expected_wb.put(wb_data);
            pc=wb_data.next_pc;
        end
    endtask

    function wb_expected_txn predict(imem_transaction ins);
        wb_expected_txn r;
        bit [31:0] rs1_v,rs2_v,addr;

        r=new();
        r.rd_addr=ins.rd;
        r.next_pc=pc+32'd4;
        rs1_v=regs[ins.rs1];
        rs2_v=regs[ins.rs2];

        case(ins.opcode)
            7'b0110011: begin
                r.reg_en=1'b1;
                case({ins.f7,ins.f3})
                    {7'b0000000,3'b000}:r.rd_data=rs1_v+rs2_v;
                    {7'b0100000,3'b000}:r.rd_data=rs1_v-rs2_v;
                    {7'b0000000,3'b001}:r.rd_data=rs1_v<<rs2_v[4:0];
                    {7'b0000000,3'b010}:r.rd_data=($signed(rs1_v)<$signed(rs2_v));
                    {7'b0000000,3'b011}:r.rd_data=(rs1_v<rs2_v);
                    {7'b0000000,3'b100}:r.rd_data=rs1_v^rs2_v;
                    {7'b0000000,3'b101}:r.rd_data=rs1_v>>rs2_v[4:0];
                    {7'b0100000,3'b101}:r.rd_data=$signed(rs1_v)>>>rs2_v[4:0];
                    {7'b0000000,3'b110}:r.rd_data=rs1_v|rs2_v;
                    {7'b0000000,3'b111}:r.rd_data=rs1_v&rs2_v;
                    default:r.reg_en=1'b0;
                endcase
            end

            7'b0010011: begin
                r.reg_en=1'b1;
                case(ins.f3)
                    3'b000:r.rd_data=rs1_v+$signed(ins.imm);
                    3'b010:r.rd_data=($signed(rs1_v)<$signed(ins.imm));
                    3'b011:r.rd_data=(rs1_v<ins.imm);
                    3'b100:r.rd_data=rs1_v^ins.imm;
                    3'b110:r.rd_data=rs1_v|ins.imm;
                    3'b111:r.rd_data=rs1_v&ins.imm;
                    3'b001:r.rd_data=rs1_v<<ins.imm[4:0];
                    3'b101:r.rd_data=ins.f7[5] ? $signed(rs1_v)>>>ins.imm[4:0] : rs1_v>>ins.imm[4:0];
                    default:r.reg_en=1'b0;
                endcase
            end

            7'b0000011: begin
                if(ins.f3==3'b010) begin
                    addr=rs1_v+$signed(ins.imm);
                    r.reg_en=1'b1;
                    r.rd_data=memory[addr[11:2]];
                end
            end

            7'b0100011: begin
                if(ins.f3==3'b010) begin
                    addr=rs1_v+$signed(ins.imm);
                    memory[addr[11:2]]=rs2_v;
                end
                r.reg_en=1'b0;
            end

            7'b1100011: begin
                r.reg_en=1'b0;
                case(ins.f3)
                    3'b000:if(rs1_v==rs2_v)r.next_pc=pc+$signed(ins.imm);
                    3'b001:if(rs1_v!=rs2_v)r.next_pc=pc+$signed(ins.imm);
                    3'b100:if($signed(rs1_v)<$signed(rs2_v))r.next_pc=pc+$signed(ins.imm);
                    3'b101:if($signed(rs1_v)>=$signed(rs2_v))r.next_pc=pc+$signed(ins.imm);
                    3'b110:if(rs1_v<rs2_v)r.next_pc=pc+$signed(ins.imm);
                    3'b111:if(rs1_v>=rs2_v)r.next_pc=pc+$signed(ins.imm);
                endcase
            end

            7'b1101111: begin
                r.reg_en=1'b1;
                r.rd_data=pc+32'd4;
                r.next_pc=pc+$signed(ins.imm);
            end

            7'b1100111: begin
                if(ins.f3==3'b000) begin
                    r.reg_en=1'b1;
                    r.rd_data=pc+32'd4;
                    r.next_pc=(rs1_v+$signed(ins.imm))&32'hffff_fffe;
                end
            end

            7'b0110111: begin
                r.reg_en=1'b1;
                r.rd_data=ins.imm;
            end

            7'b0010111: begin
                r.reg_en=1'b1;
                r.rd_data=pc+ins.imm;
            end

            default:r.reg_en=1'b0;
        endcase

        if(r.rd_addr==5'd0)
            r.reg_en=1'b0;

        if(r.reg_en)
            regs[r.rd_addr]=r.rd_data;

        regs[0]='0;
        return r;
    endfunction
endclass


// ============================================================
// SCOREBOARD
// ============================================================

class scoreboard;
    mailbox #(wb_expected_txn) expected_wb;
    mailbox #(wb_actual_txn) actual_wb;
    int pass_cnt;
    int fail_cnt;

    function new(mailbox #(wb_expected_txn) exp_mbx,mailbox #(wb_actual_txn) act_mbx);
        expected_wb=exp_mbx;
        actual_wb=act_mbx;
    endfunction

    task run();
        forever begin
            wb_expected_txn exp;
            wb_actual_txn act;

            actual_wb.get(act);
            expected_wb.get(exp);

            if((act.rd_addr!==exp.rd_addr)||(act.rd_data!==exp.rd_data)) begin
                fail_cnt++;
                $error("[SB][FAIL] ACT rd=%0d data=%08h | EXP rd=%0d data=%08h",
                    act.rd_addr,act.rd_data,exp.rd_addr,exp.rd_data);
            end
            else begin
                pass_cnt++;
                $display("[SB][PASS] rd=%0d data=%08h",act.rd_addr,act.rd_data);
            end
        end
    endtask
endclass


// ============================================================
// TB TOP
// ============================================================

module tb_top;
    logic clk=0;
    always #5 clk=~clk;

    logic rst_n;
    top_if vif(clk);

    program_generator gen;
    top_ref_model ref_model;
    scoreboard sb;
    core_driver drv;

    assign rst_n=vif.rst_n;

    // DUT của bạn
    // core_top dut(.clk(clk),.rst_n(vif.rst_n));

    initial begin
        gen=new();
        gen.gen_program(1024);

        // Load program vào IMEM DUT
        // foreach(gen.prog[i])
        //     dut.u_imem.memory[i]=gen.prog[i].encode();

        ref_model=new(gen.prog,expected_wb);
        sb=new(expected_wb,actual_wb);
        drv=new(vif);

        fork
            drv.run();
            ref_model.run();
            sb.run();
        join_none

        repeat(10000) @(posedge clk);

        $display("[TB] PASS=%0d FAIL=%0d",sb.pass_cnt,sb.fail_cnt);
        $finish;
    end
endmodule
