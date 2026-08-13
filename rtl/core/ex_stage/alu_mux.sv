module alu_mux
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input  forward_e      for_ex_a_i,
    input  forward_e      for_ex_b_i,
    input  [XLEN-1:0]      rs1_data_i,
    input  [XLEN-1:0]      rs2_data_i,
    // 
    input logic [1:0] sel_a_i,
    input logic [1:0] sel_b_i,
    input logic [XLEN-1:0] pc_cur_i,
    input  logic [31:0] immgen_i,




    // input  logic [31:0] rs1_data,
    // input  logic [31:0] rs2_data,
    // input  logic [31:0] immgen,
    // input  logic [31:0] pc_cur,


    // input  logic [31:0] mem_i.alu,
    // input  logic [31:0] wb_i.alu,

    // input for_info_t mem_i,
    // input for_info_t wb_i,
    input   logic [XLEN-1:0]        alu_mem_i,
    input   logic [XLEN-1:0]        alu_wb_i,

    output logic [31:0] A_o,
    output logic [31:0] B_o
);
    logic [31:0] rs1_fwd;
    logic [31:0] rs2_fwd;

    always_comb begin
        unique case (for_ex_a_i)
            RD_MEM: rs1_fwd = alu_mem_i;
            RD_WB:  rs1_fwd = alu_wb_i;
            RD_EX:  rs1_fwd = rs1_data_i;
            default:   rs1_fwd = rs1_data_i;
        endcase
    end

    always_comb begin
        unique case (for_ex_b_i)
            RD_MEM: rs2_fwd = alu_mem_i;
            RD_WB:  rs2_fwd = alu_wb_i;
            RD_EX:  rs2_fwd = rs2_data_i;
            default:   rs2_fwd = rs2_data_i;
        endcase
    end

    always_comb begin
        unique case (sel_a_i)
            RS1_EX:    A_o = rs1_fwd;
            PC_CUR_EX: A_o = pc_cur_i;
            ZERO_EX:   A_o = 32'b0;
            default:   A_o = rs1_fwd;
        endcase
    end

    always_comb begin
        unique case (sel_b_i)
            RS2_EX:  B_o = rs2_fwd;
            IMM_EX:  B_o = immgen_i;
            default: B_o = rs2_fwd;
        endcase
    end
endmodule
