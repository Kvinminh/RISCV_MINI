module decode
  import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input  logic [XLEN-1:0] ins,
    output decode_s         deco,
    output logic rs1_used_id,
    output logic rs2_used_id
    output logic is_br_jalr_id
);
  logic [6:0] opcode;
  assign opcode = ins[6:0];
  always_comb begin
    // Default an toàn, tránh latch inference
    deco = '0;
    deco.imm_sel          = IMMGEN_I;
    deco.ex_ctrl.alu_op    = ALU_ADD_SUB;
    deco.ex_ctrl.sel_a     = RS1_EX;
    deco.ex_ctrl.sel_b     = RS2_EX;
    deco.wb_ctrl.sel_wb    = ALU_MEM;
    case (opcode)
      // R-type: rd = rs1 OP rs2 (funct3/funct7 forward xuống EX để tính alu_ctrl_e)
      OPCODE_OP: begin
        deco.ex_ctrl.sel_a  = RS1_EX;
        deco.ex_ctrl.sel_b  = RS2_EX;
        deco.ex_ctrl.alu_op = ALU_RTYPE;
        deco.wb_ctrl.reg_en = 1'b1;
        deco.wb_ctrl.sel_wb = ALU_MEM;
      end
      // I-type ALU: rd = rs1 OP imm
      OPCODE_OP_IMM: begin
        deco.imm_sel        = IMMGEN_I;
        deco.ex_ctrl.sel_a  = RS1_EX;
        deco.ex_ctrl.sel_b  = IMM_EX;
        deco.ex_ctrl.alu_op = ALU_ITYPE;
        deco.wb_ctrl.reg_en = 1'b1;
        deco.wb_ctrl.sel_wb = ALU_MEM;
      end
      // Load: addr = rs1 + imm
      OPCODE_LOAD: begin
        deco.imm_sel                = IMMGEN_I;
        deco.ex_ctrl.sel_a          = RS1_EX;
        deco.ex_ctrl.sel_b          = IMM_EX;
        deco.ex_ctrl.alu_op         = ALU_ADD_SUB;
        deco.mem_ctrl.dmem_re       = 1'b1;
        deco.mem_ctrl.extension_mem = 1'b1; // funct3 (lb/lh/lw) cần forward riêng xuống MEM
        deco.wb_ctrl.reg_en         = 1'b1;
        deco.wb_ctrl.sel_wb         = MEM_RDATA;
      end
      // Store: addr = rs1 + imm
      OPCODE_STORE: begin
        deco.imm_sel           = IMMGEN_S;
        deco.ex_ctrl.sel_a     = RS1_EX;
        deco.ex_ctrl.sel_b     = IMM_EX;
        deco.ex_ctrl.alu_op    = ALU_ADD_SUB;
        deco.mem_ctrl.dmem_wri = 1'b1;
      end
      // Branch: br_compare xử lý riêng ở EX, decode chỉ báo br_en
      OPCODE_BRANCH: begin
        deco.imm_sel        = IMMGEN_B;
        deco.ex_ctrl.sel_a  = RS1_EX;
        deco.ex_ctrl.sel_b  = RS2_EX;
        deco.ex_ctrl.alu_op = ALU_ADD_SUB;
        deco.br_en          = 1'b1;
      end
      // JAL: rd = pc+4, target = pc + imm (tính qua ALU dùng chung)
      OPCODE_JAL: begin
        deco.imm_sel        = IMMGEN_J;
        deco.jal_en         = 1'b1;
        deco.ex_ctrl.sel_a  = PC_CUR_EX;   // fixed: cần cho tính target = pc + imm
        deco.ex_ctrl.sel_b  = IMM_EX;      // fixed
        deco.ex_ctrl.alu_op = ALU_ADD_SUB; // fixed
        deco.wb_ctrl.reg_en = 1'b1;
        deco.wb_ctrl.sel_wb = PC4_MEM;
      end
      // JALR: rd = pc+4, target = rs1+imm (LSB clear xử lý ở pc_mux/IF theo spec bạn đã chốt)
      OPCODE_JALR: begin
        deco.imm_sel        = IMMGEN_I;
        deco.ex_ctrl.sel_a  = RS1_EX;
        deco.ex_ctrl.sel_b  = IMM_EX;
        deco.ex_ctrl.alu_op = ALU_ADD_SUB;
        deco.jalr_en        = 1'b1;
        deco.wb_ctrl.reg_en = 1'b1;
        deco.wb_ctrl.sel_wb = PC4_MEM;
      end
      // LUI: rd = 0 + (imm << 12)
      OPCODE_LUI: begin
        deco.imm_sel        = IMMGEN_U;
        deco.ex_ctrl.sel_a  = ZERO_EX;   // fixed: không dùng rs1, dùng hằng 0
        deco.ex_ctrl.sel_b  = IMM_EX;
        deco.ex_ctrl.alu_op = ALU_ADD_SUB;
        deco.wb_ctrl.reg_en = 1'b1;
        deco.wb_ctrl.sel_wb = ALU_MEM;
        
      end
      // AUIPC: rd = pc + (imm << 12)
      OPCODE_AUIPC: begin
        deco.imm_sel        = IMMGEN_U;
        deco.ex_ctrl.sel_a  = PC_CUR_EX;
        deco.ex_ctrl.sel_b  = IMM_EX;
        deco.ex_ctrl.alu_op = ALU_ADD_SUB;
        deco.wb_ctrl.reg_en = 1'b1;
        deco.wb_ctrl.sel_wb = ALU_MEM;
      end
      default: begin
        // opcode lạ -> giữ nguyên default NOP-safe
      end
    endcase
  end



  always_comb begin
    rs1_used_id = 0;
    rs2_used_id = 0;
    case(opcode)
    OPCODE_OP,      // R-type (add, sub, and,...)
    OPCODE_BRANCH,  // B-type (beq, bne,...)
    OPCODE_STORE:   // S-type (sw, sh,...)
    begin
      rs1_used_id = 1'b1;
      rs2_used_id = 1'b1;
    end

    // 3. Nhóm CHỈ dùng rs1 (rs2 giữ nguyên mặc định là 0)
    OPCODE_OP_IMM,  // I-type ALU (addi, slli,...)
    OPCODE_LOAD,    // I-type Load (lw, lh,...)
    OPCODE_JALR:    // Lệnh nhảy JALR
    begin
      rs1_used_id = 1'b1;
    end

    // 4. Nhóm KHÔNG dùng cả rs1 lẫn rs2 (LUI, AUIPC, JAL)
    // Các lệnh này tự động rơi vào trường hợp mặc định (=0 ở đầu)
    // Nên bạn không cần phải liệt kê ra nữa, hoặc nếu muốn rõ ràng thì viết:
    /*
    OPCODE_LUI, OPCODE_AUIPC, OPCODE_JAL: begin
      rs1_used_id = 1'b0;
      rs2_used_id = 1'b0;
    end5
    */
    
    default: begin
      rs1_used_id = 1'b0;
      rs2_used_id = 1'b0;
    end
    endcase
  end



  assign take_jump_id = ( deco.jalr_en || deco.jal_en );

endmodule