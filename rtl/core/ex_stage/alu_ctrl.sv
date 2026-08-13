module alu_ctrl
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input  alu_op_e     alu_op_i,
    input  logic [2:0] f3_i,
    input  logic        f7_5_i,
    output alu_ctrl_e   alu_ctrl_o
);
 
    always_comb begin
        alu_ctrl_o = ALU_ADD; // default an toàn
 
        unique case (alu_op_i)
 
            // Load, Store, JAL, JALR, AUIPC, LUI -> luôn cộng địa chỉ/toán hạng
            ALU_ADD_SUB: begin
                alu_ctrl_o = ALU_ADD;
            end
 
            // R-type thật: cần f3 + f7[5] đầy đủ
            ALU_RTYPE: begin
                unique case (f3_i)
                    F3_ADD_SUB: alu_ctrl_o = alu_ctrl_e'(f7_5_i ? ALU_SUB : ALU_ADD);
                    F3_SLL:     alu_ctrl_o = ALU_SLL;
                    F3_SLT:     alu_ctrl_o = ALU_SLT;
                    F3_SLTU:    alu_ctrl_o = ALU_SLTU;
                    F3_XOR:     alu_ctrl_o = ALU_XOR;
                    F3_SRL_SRA: alu_ctrl_o = alu_ctrl_e'(f7_5_i ? ALU_SRA : ALU_SRL);
                    F3_OR:      alu_ctrl_o = ALU_OR;
                    F3_AND:     alu_ctrl_o = ALU_AND;
                    default:    alu_ctrl_o = ALU_ADD;
                endcase
            end
 
            // I-type ALU thật: chỉ dùng f3, f7[5] chỉ xét khi f3 = 101 (SRLI/SRAI)
            ALU_ITYPE: begin
                unique case (f3_i)
                    F3_ADDI:      alu_ctrl_o = ALU_ADD;
                    F3_SLLI:      alu_ctrl_o = ALU_SLL;
                    F3_SLTI:      alu_ctrl_o = ALU_SLT;
                    F3_SLTIU:     alu_ctrl_o = ALU_SLTU;
                    F3_XORI:      alu_ctrl_o = ALU_XOR;
                    F3_SRLI_SRAI: alu_ctrl_o = alu_ctrl_e'(f7_5_i ? ALU_SRA : ALU_SRL);
                    F3_ORI:       alu_ctrl_o = ALU_OR;
                    F3_ANDI:      alu_ctrl_o = ALU_AND;
                    default:      alu_ctrl_o = ALU_ADD;
                endcase
            end
 
            default: alu_ctrl_o = ALU_ADD;
        endcase
    end
 
endmodule
