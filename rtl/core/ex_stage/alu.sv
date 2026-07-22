module alu
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input  alu_ctrl_e   alu_ctrl,
    input  logic [31:0] A,
    input  logic [31:0] B,
    output logic [31:0] alu_result_ex
);
 
    always_comb begin
        unique case (alu_ctrl)
            ALU_ADD:  alu_result_ex = A + B;
            ALU_SUB:  alu_result_ex = A - B;
            ALU_SLL:  alu_result_ex = A << B[4:0];
            ALU_SLT:  alu_result_ex = {31'b0, ($signed(A) < $signed(B))};
            ALU_SLTU: alu_result_ex = {31'b0, (A < B)};
            ALU_XOR:  alu_result_ex = A ^ B;
            ALU_SRL:  alu_result_ex = A >> B[4:0];
            ALU_SRA:  alu_result_ex = $signed(A) >>> B[4:0];
            ALU_OR:   alu_result_ex = A | B;
            ALU_AND:  alu_result_ex = A & B;
            default:  alu_result_ex = 32'b0;
        endcase
    end
 
endmodule
