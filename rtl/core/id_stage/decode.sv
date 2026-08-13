module decode
  import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input  logic [XLEN-1:0] ins_i,
    output decode_s         deco_o,
    output logic rs1_used_o,
    output logic rs2_used_o,
    output logic jump_en_o
    
);
  logic [6:0] opcode;
  //logic [2:0] f3;
  assign opcode = ins_i[6:0];
  //assign f3 = ins_i[14:12];
  always_comb begin
    // Default an toàn, tránh latch inference
    deco_o = '0;
    deco_o.imm_sel          = IMMGEN_I;
    deco_o.ex_ctrl.alu_op    = ALU_ADD_SUB;
    deco_o.ex_ctrl.sel_a     = RS1_EX;
    deco_o.ex_ctrl.sel_b     = RS2_EX;
    deco_o.wb_ctrl.sel_wb    = ALU_MEM;
    case (opcode)
      // R-type: rd = rs1 OP rs2 (funct3/funct7 forward xuống EX để tính alu_ctrl_e)
      OPCODE_OP: begin
        deco_o.ex_ctrl.sel_a  = RS1_EX;
        deco_o.ex_ctrl.sel_b  = RS2_EX;
        deco_o.ex_ctrl.alu_op = ALU_RTYPE;
        deco_o.wb_ctrl.reg_en = 1'b1;
        deco_o.wb_ctrl.sel_wb = ALU_MEM;
      end
      // I-type ALU: rd = rs1 OP imm
      OPCODE_OP_IMM: begin
        deco_o.imm_sel        = IMMGEN_I;
        deco_o.ex_ctrl.sel_a  = RS1_EX;
        deco_o.ex_ctrl.sel_b  = IMM_EX;
        deco_o.ex_ctrl.alu_op = ALU_ITYPE;
        deco_o.wb_ctrl.reg_en = 1'b1;
        deco_o.wb_ctrl.sel_wb = ALU_MEM;
      end
      // Load: addr = rs1 + imm
      OPCODE_LOAD: begin
        deco_o.imm_sel                = IMMGEN_I;
        deco_o.ex_ctrl.sel_a          = RS1_EX;
        deco_o.ex_ctrl.sel_b          = IMM_EX;
        deco_o.ex_ctrl.alu_op         = ALU_ADD_SUB;
        deco_o.mem_ctrl.dmem_re       = 1'b1;
        //deco_o.mem_ctrl.extension_ex_mem = 1'b1; // funct3 (lb/lh/lw) cần forward riêng xuống MEM
        deco_o.wb_ctrl.reg_en         = 1'b1;
        deco_o.wb_ctrl.sel_wb         = MEM_RDATA;
      end
      // Store: addr = rs1 + imm
      OPCODE_STORE: begin
        deco_o.imm_sel           = IMMGEN_S;
        deco_o.ex_ctrl.sel_a     = RS1_EX;
        deco_o.ex_ctrl.sel_b     = IMM_EX;
        deco_o.ex_ctrl.alu_op    = ALU_ADD_SUB;
        deco_o.mem_ctrl.dmem_wri = 1'b1;
      end
      // Branch: br_compare xử lý riêng ở EX, deco_ode chỉ báo br_en
      OPCODE_BRANCH: begin
        deco_o.imm_sel        = IMMGEN_B;
        deco_o.ex_ctrl.sel_a  = RS1_EX;
        deco_o.ex_ctrl.sel_b  = RS2_EX;
        deco_o.ex_ctrl.alu_op = ALU_ADD_SUB;
        deco_o.br_en          = 1'b1;
      end
      // JAL: rd = pc+4, target = pc + imm (tính qua ALU dùng chung)
      OPCODE_JAL: begin
        deco_o.imm_sel        = IMMGEN_J;
        deco_o.jal_en         = 1'b1;
        deco_o.ex_ctrl.sel_a  = PC_CUR_EX;   // fixed: cần cho tính target = pc + imm
        deco_o.ex_ctrl.sel_b  = IMM_EX;      // fixed
        deco_o.ex_ctrl.alu_op = ALU_ADD_SUB; // fixed
        deco_o.wb_ctrl.reg_en = 1'b1;
        deco_o.wb_ctrl.sel_wb = PC4_MEM;
      end
      // JALR: rd = pc+4, target = rs1+imm (LSB clear xử lý ở pc_mux/IF theo spec bạn đã chốt)
      OPCODE_JALR: begin
        deco_o.imm_sel        = IMMGEN_I;
        deco_o.ex_ctrl.sel_a  = RS1_EX;
        deco_o.ex_ctrl.sel_b  = IMM_EX;
        deco_o.ex_ctrl.alu_op = ALU_ADD_SUB;
        deco_o.jalr_en        = 1'b1;
        deco_o.wb_ctrl.reg_en = 1'b1;
        deco_o.wb_ctrl.sel_wb = PC4_MEM;
      end
      // LUI: rd = 0 + (imm << 12)
      OPCODE_LUI: begin
        deco_o.imm_sel        = IMMGEN_U;
        deco_o.ex_ctrl.sel_a  = ZERO_EX;   // fixed: không dùng rs1, dùng hằng 0
        deco_o.ex_ctrl.sel_b  = IMM_EX;
        deco_o.ex_ctrl.alu_op = ALU_ADD_SUB;
        deco_o.wb_ctrl.reg_en = 1'b1;
        deco_o.wb_ctrl.sel_wb = ALU_MEM;
        
      end
      // AUIPC: rd = pc + (imm << 12)
      OPCODE_AUIPC: begin
        deco_o.imm_sel        = IMMGEN_U;
        deco_o.ex_ctrl.sel_a  = PC_CUR_EX;
        deco_o.ex_ctrl.sel_b  = IMM_EX;
        deco_o.ex_ctrl.alu_op = ALU_ADD_SUB;
        deco_o.wb_ctrl.reg_en = 1'b1;
        deco_o.wb_ctrl.sel_wb = ALU_MEM;
      end
      default: begin
        // opcode lạ -> giữ nguyên default NOP-safe
      end
    endcase
  end



  always_comb begin
    rs1_used_o = 0;
    rs2_used_o = 0;
    case(opcode)
    OPCODE_OP,      // R-type (add, sub, and,...)
    OPCODE_BRANCH,  // B-type (beq, bne,...)
    OPCODE_STORE:   // S-type (sw, sh,...)
    begin
      rs1_used_o = 1'b1;
      rs2_used_o = 1'b1;
    end

    // 3. Nhóm CHỈ dùng rs1 (rs2 giữ nguyên mặc định là 0)
    OPCODE_OP_IMM,  // I-type ALU (addi, slli,...)
    OPCODE_LOAD,    // I-type Load (lw, lh,...)
    OPCODE_JALR:    // Lệnh nhảy JALR
    begin
      rs1_used_o = 1'b1;
    end

    // 4. Nhóm KHÔNG dùng cả rs1 lẫn rs2 (LUI, AUIPC, JAL)
    // Các lệnh này tự động rơi vào trường hợp mặc định (=0 ở đầu)
    // Nên bạn không cần phải liệt kê ra nữa, hoặc nếu muốn rõ ràng thì viết:
    /*
    OPCODE_LUI, OPCODE_AUIPC, OPCODE_JAL: begin
      rs1_used_o = 1'b0;
      rs2_used_o = 1'b0;
    end5
    */
    
    default: begin
      rs1_used_o = 1'b0;
      rs2_used_o = 1'b0;
    end
    endcase
  end


 
  assign jump_en_o = ( deco_o.jalr_en || deco_o.jal_en );

  
  
  assign deco_o.extension = ( opcode == OPCODE_LOAD) && !ins_i[14];

endmodule
