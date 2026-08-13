module mux_br_compare // dùng forward
import ctrl_pkg::*;
import core_pkg::*;
import isa_pkg::*;   // để dùng XLEN
(
    input  logic [XLEN-1:0]   rs1_data_i,
    input  logic [XLEN-1:0]   rs2_data_i,
    // input  logic [XLEN-1:0]   alu_result_ex,
    // input  logic [XLEN-1:0]   wb_data_mem,
    
    input   logic [XLEN-1:0]        alu_ex_i,
    input   logic [XLEN-1:0]        alu_mem_i,

    input  for_sel_e          for_id_a_i,
    input  for_sel_e          for_id_b_i,

    output logic [XLEN-1:0]   compare_a_o,
    output logic [XLEN-1:0]   compare_b_o
);

    // Mux chọn nguồn cho operand A (rs1)
    always_comb begin : mux_compare_a
         case (for_id_a_i)
            RS1_DATA_ID  : compare_a_o = rs1_data_i;
            RD_DATA_EX  : compare_a_o = alu_ex_i;
            RD_DATA_MEM : compare_a_o = alu_mem_i;
            default: compare_a_o = rs1_data_i;
        endcase
    end

    // Mux chọn nguồn cho operand B (rs2)
    always_comb begin : mux_compare_b
         case (for_id_b_i)
            RS2_DATA_ID  : compare_b_o = rs2_data_i;
            RD_DATA_EX  : compare_b_o =  alu_ex_i;
            RD_DATA_MEM : compare_b_o =  alu_mem_i;
            default: compare_b_o = rs2_data_i;
        endcase
    end

endmodule
