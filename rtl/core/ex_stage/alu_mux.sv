module alu_mux
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input  forward_e      forward_a,
    input  forward_e      forward_b,
    input  sel_a_decode_e sel_a,
    input  sel_b_decode_e sel_b,
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    input  logic [31:0] immgen,
    input  logic [31:0] pc_cur,
    input  logic [31:0] alu_mem,
    input  logic [31:0] alu_wb,
    output logic [31:0] A,
    output logic [31:0] B
);
    logic [31:0] rs1_fwd;
    logic [31:0] rs2_fwd;

    always_comb begin
        unique case (forward_a)
            RD_MEM_EX: rs1_fwd = alu_mem;
            RD_WB_EX:  rs1_fwd = alu_wb;
            RS_EX_EX:  rs1_fwd = rs1_data;
            default:   rs1_fwd = rs1_data;
        endcase
    end

    always_comb begin
        unique case (forward_b)
            RD_MEM_EX: rs2_fwd = alu_mem;
            RD_WB_EX:  rs2_fwd = alu_wb;
            RS_EX_EX:  rs2_fwd = rs2_data;
            default:   rs2_fwd = rs2_data;
        endcase
    end

    always_comb begin
        unique case (sel_a)
            RS1_EX:    A = rs1_fwd;
            PC_CUR_EX: A = pc_cur;
            ZERO_EX:   A = 32'b0;
            default:   A = rs1_fwd;
        endcase
    end

    always_comb begin
        unique case (sel_b)
            RS2_EX:  B = rs2_fwd;
            IMM_EX:  B = immgen;
            default: B = rs2_fwd;
        endcase
    end
endmodule