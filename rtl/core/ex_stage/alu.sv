module alu
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input  alu_ctrl_e   alu_ctrl_i,
    input  logic [31:0] A,
    input  logic [31:0] B,
    output logic [31:0] alu_result_o
);
 
    always_comb begin
        unique case (alu_ctrl_i)
            ALU_ADD:  alu_result_o = A + B;
            ALU_SUB:  alu_result_o = A - B;
            ALU_SLL:  alu_result_o = A << B[4:0];
            ALU_SLT:  alu_result_o = {31'b0, ($signed(A) < $signed(B))};
            ALU_SLTU: alu_result_o = {31'b0, (A < B)};
            ALU_XOR:  alu_result_o = A ^ B;
            ALU_SRL:  alu_result_o = A >> B[4:0];
            ALU_SRA:  alu_result_o = $signed(A) >>> B[4:0];
            ALU_OR:   alu_result_o = A | B;
            ALU_AND:  alu_result_o = A & B;
            default:  alu_result_o = 32'b0;
        endcase
    end
 
endmodule
