



module tb_ex_stage
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
();

  

initial begin
`ifdef DUMP
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_ex_stage.u_ex_stage.u_forward_ex);
    $dumpvars(0, tb_ex_stage.u_ex_stage.u_alu_mux);
    $dumpvars(0, tb_ex_stage.u_ex_stage.u_alu_ctrl);
    $dumpvars(0, tb_ex_stage.u_ex_stage.u_alu);
`endif
end

logic clk;
logic rst_n;


    id_ex_reg_t reg_ex_i;
    for_info_t  for_info_mem_i; // hazzard forwward
    for_info_t  for_info_wb_i;// hazzard forwward
    logic [XLEN-1:0]        alu_mem_i;
    logic [XLEN-1:0]        alu_wb_i;

    ex_mem_reg_t ex_reg_o;

ex_stage u_ex_stage(.*);

int pass_cnt= 0;
int fail_cnt= 0;
 
always #5 clk = ~clk;
initial begin
    clk = 0;
    rst_n = 0;
     #20 rst_n = 1;
end




function automatic void ref_model_ex_stage(
    input  id_ex_reg_t  reg_ex_i,
    input  for_info_t   for_info_mem_i,
    input  for_info_t   for_info_wb_i,
    input  logic [XLEN-1:0] alu_mem_i,
    input  logic [XLEN-1:0] alu_wb_i,
    output ex_mem_reg_t ex_reg_o
);
    logic [1:0]      for_ex_a, for_ex_b;
    logic [XLEN-1:0] rs1_fwd, rs2_fwd, A, B;
    logic [3:0]      alu_ctrl;
    logic [XLEN-1:0] alu_result;

    // =====================================================
    // forward_ex: TODO - cần đúng thuật toán thật của module forward_ex
    // Bên dưới là PLACEHOLDER giả định (MEM ưu tiên hơn WB, so rd_addr
    // với rs1_addr/rs2_addr). Bạn PHẢI thay bằng logic thật, nếu không
    // ref model sẽ mismatch với DUT.
    // =====================================================
    if (for_info_mem_i.reg_en && (for_info_mem_i.rd_addr == reg_ex_i.rs1_addr) && (reg_ex_i.rs1_addr != '0))
        for_ex_a = 2'd1; // RD_MEM (encode giả định)
    else if (for_info_wb_i.reg_en && (for_info_wb_i.rd_addr == reg_ex_i.rs1_addr) && (reg_ex_i.rs1_addr != '0))
        for_ex_a = 2'd2; // RD_WB (encode giả định)
    else
        for_ex_a = 2'd0; // RD_EX / no-forward

    if (for_info_mem_i.reg_en && (for_info_mem_i.rd_addr == reg_ex_i.rs2_addr) && (reg_ex_i.rs2_addr != '0))
        for_ex_b = 2'd1;
    else if (for_info_wb_i.reg_en && (for_info_wb_i.rd_addr == reg_ex_i.rs2_addr) && (reg_ex_i.rs2_addr != '0))
        for_ex_b = 2'd2;
    else
        for_ex_b = 2'd0;

    // =====================================================
    // alu_mux: chọn nguồn forward cho rs1/rs2
    // =====================================================
    unique case (for_ex_a)
        2'd1:    rs1_fwd = alu_mem_i;
        2'd2:    rs1_fwd = alu_wb_i;
        2'd0:    rs1_fwd = reg_ex_i.rs1_data;
        default: rs1_fwd = reg_ex_i.rs1_data;
    endcase

    unique case (for_ex_b)
        2'd1:    rs2_fwd = alu_mem_i;
        2'd2:    rs2_fwd = alu_wb_i;
        2'd0:    rs2_fwd = reg_ex_i.rs2_data;
        default: rs2_fwd = reg_ex_i.rs2_data;
    endcase

    // ---- chọn toán hạng A/B đưa vào ALU
    unique case (reg_ex_i.ex_ctrl.sel_a)
        RS1_EX:    A = rs1_fwd;
        PC_CUR_EX: A = reg_ex_i.pc_cur;
        ZERO_EX:   A = '0;
        default:   A = rs1_fwd;
    endcase

    unique case (reg_ex_i.ex_ctrl.sel_b)
        RS2_EX:  B = rs2_fwd;
        IMM_EX:  B = reg_ex_i.imm_out;
        default: B = rs2_fwd;
    endcase

    // =====================================================
    // alu_ctrl: giải mã alu_op + f3 + f7[5] -> alu_ctrl
    // =====================================================
    alu_ctrl = ALU_ADD; // default an toàn

    unique case (reg_ex_i.ex_ctrl.alu_op)
        ALU_ADD_SUB: begin
            alu_ctrl = ALU_ADD;
        end

        ALU_RTYPE: begin
            unique case (reg_ex_i.f3)
                F3_ADD_SUB: alu_ctrl = reg_ex_i.f7_5 ? ALU_SUB : ALU_ADD;
                F3_SLL:     alu_ctrl = ALU_SLL;
                F3_SLT:     alu_ctrl = ALU_SLT;
                F3_SLTU:    alu_ctrl = ALU_SLTU;
                F3_XOR:     alu_ctrl = ALU_XOR;
                F3_SRL_SRA: alu_ctrl = reg_ex_i.f7_5 ? ALU_SRA : ALU_SRL;
                F3_OR:      alu_ctrl = ALU_OR;
                F3_AND:     alu_ctrl = ALU_AND;
                default:    alu_ctrl = ALU_ADD;
            endcase
        end

        ALU_ITYPE: begin
            unique case (reg_ex_i.f3)
                F3_ADDI:      alu_ctrl = ALU_ADD;
                F3_SLLI:      alu_ctrl = ALU_SLL;
                F3_SLTI:      alu_ctrl = ALU_SLT;
                F3_SLTIU:     alu_ctrl = ALU_SLTU;
                F3_XORI:      alu_ctrl = ALU_XOR;
                F3_SRLI_SRAI: alu_ctrl = reg_ex_i.f7_5 ? ALU_SRA : ALU_SRL;
                F3_ORI:       alu_ctrl = ALU_OR;
                F3_ANDI:      alu_ctrl = ALU_AND;
                default:      alu_ctrl = ALU_ADD;
            endcase
        end

        default: alu_ctrl = ALU_ADD;
    endcase

    // =====================================================
    // alu: tính kết quả cuối cùng
    // =====================================================
    unique case (alu_ctrl)
        ALU_ADD:  alu_result = A + B;
        ALU_SUB:  alu_result = A - B;
        ALU_SLL:  alu_result = A << B[4:0];
        ALU_SLT:  alu_result = {{(XLEN-1){1'b0}}, ($signed(A) < $signed(B))};
        ALU_SLTU: alu_result = {{(XLEN-1){1'b0}}, (A < B)};
        ALU_XOR:  alu_result = A ^ B;
        ALU_SRL:  alu_result = A >> B[4:0];
        ALU_SRA:  alu_result = $signed(A) >>> B[4:0];
        ALU_OR:   alu_result = A | B;
        ALU_AND:  alu_result = A & B;
        default:  alu_result = '0;
    endcase

    // =====================================================
    // pack output đúng theo ex_mem_reg_t của DUT
    // =====================================================
    ex_reg_o.pc_4      = reg_ex_i.pc_4;
    ex_reg_o.alu       = alu_result;
    ex_reg_o.rs2_data  = reg_ex_i.rs2_data;  // theo RTL hiện tại, KHÔNG forward
    ex_reg_o.rd_addr   = reg_ex_i.rd_addr;
    ex_reg_o.extension = reg_ex_i.extension;
    ex_reg_o.mem_ctrl  = reg_ex_i.mem_ctrl;
    ex_reg_o.wb_ctrl   = reg_ex_i.wb_ctrl;
    ex_reg_o.f3        = reg_ex_i.f3;
endfunction





task automatic check(string name, logic [31:0] actual, logic [31:0] expected);
    if (actual !== expected) begin
      fail_cnt++;
      $error("[FAIL] %s: actual=%0h expected=%0h", name, actual, expected);
    end else begin
      pass_cnt++;
      $display("[PASS] %s: %0h", name, actual);
    end
  endtask


  task automatic idle_control();
    reg_ex_i         = 0;
    for_info_mem_i   = 0; 
    for_info_wb_i    = 0;
    alu_mem_i        = 0;
    alu_wb_i         = 0;

endtask


task automatic test_one_ex_stage(string name);
    // input structs cho DUT
    // id_ex_reg_t  reg_ex_i;
    // for_info_t   for_info_mem_i;
    // for_info_t   for_info_wb_i;
    // logic [XLEN-1:0] alu_mem_i;
    // logic [XLEN-1:0] alu_wb_i;

    // expected output từ ref model
    ex_mem_reg_t exp_ex_reg_o;

    idle_control();
    @(posedge clk);

    // ----- random input -----
    reg_ex_i.rs1_addr        = 5'($urandom_range(0, 31));
    reg_ex_i.rs2_addr        = 5'($urandom_range(0, 31));
    reg_ex_i.rs1_data        = $urandom;
    reg_ex_i.rs2_data        = $urandom;
    reg_ex_i.pc_cur          = $urandom;
    reg_ex_i.imm_out         = $urandom;
   
    
    
    reg_ex_i.f3              = 3'($urandom_range(0, 7));
    reg_ex_i.f7_5            = 1'(($urandom_range(0, 1)));
    reg_ex_i.ex_ctrl.sel_a   = sel_a_decode_e'($urandom_range(0, 2));   // RS1_EX / PC_CUR_EX / ZERO_EX
    reg_ex_i.ex_ctrl.sel_b   = sel_a_decode_e'($urandom_range(0, 2));   // RS2_EX / IMM_EX
    reg_ex_i.ex_ctrl.alu_op  = alu_op_e'($urandom_range(0, 2)); // ALU_ADD_SUB/RTYPE/ITYPE


    // reg_ex_i.mem_ctrl / .wb_ctrl : random hoặc để mặc định tuỳ struct thật
    // reg_ex_i.mem_ctrl = ...
    // reg_ex_i.wb_ctrl  = ...
    // reg_ex_i.extension       = $urandom;
    // reg_ex_i.rd_addr         = $urandom_range(0, 31);
    //  reg_ex_i.pc_4            = $urandom;





    for_info_mem_i.reg_en  = 1'($urandom_range(0, 1));
    for_info_mem_i.rd_addr = 5'($urandom_range(0, 31));
    for_info_wb_i.reg_en   = 1'($urandom_range(0, 1));
    for_info_wb_i.rd_addr  = 5'($urandom_range(0, 31));

    alu_mem_i = $urandom;
    alu_wb_i  = $urandom;

    #1;

    // ----- ref model -----
    ref_model_ex_stage(
        .reg_ex_i       (reg_ex_i),
        .for_info_mem_i (for_info_mem_i),
        .for_info_wb_i  (for_info_wb_i),
        .alu_mem_i      (alu_mem_i),
        .alu_wb_i       (alu_wb_i),
        .ex_reg_o       (exp_ex_reg_o)
    );

    // ----- check DUT vs ref model -----
    $display("---- %s ----", name);
    check("alu",       ex_reg_o.alu,       exp_ex_reg_o.alu);
   
endtask


initial begin
    wait(rst_n == 1);
    #1;

    for (int i = 0; i < 200; i++) begin
        test_one_ex_stage($sformatf("random_%0d", i));
    end

    $display("==== SUMMARY: PASS=%0d FAIL=%0d ====", pass_cnt, fail_cnt);
    $finish;
end


endmodule


