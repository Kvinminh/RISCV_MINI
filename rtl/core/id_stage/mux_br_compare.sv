module mux_br_compare // dùng forward
import ctrl_pkg::*;
import core_pkg::*;
import isa_pkg::*;   // để dùng XLEN
(
    input  logic [XLEN-1:0]   rs1_data_id,
    input  logic [XLEN-1:0]   rs2_data_id,
    input  logic [XLEN-1:0]   alu_result_ex,
    input  logic [XLEN-1:0]   wb_data_mem,

    input  for_sel_e          forward_id_a,
    input  for_sel_e          forward_id_b,

    output logic [XLEN-1:0]   operand_a_id,
    output logic [XLEN-1:0]   operand_b_id
);

    // Mux chọn nguồn cho operand A (rs1)
    always_comb begin : mux_operand_a
         case (forward_id_a)
            RS1_ID  : operand_a_id = rs1_data_id;
            RD_EX  : operand_a_id = alu_result_ex;
            RD_MEM : operand_a_id = wb_data_mem;
            default: operand_a_id = rs1_data_id;
        endcase
    end

    // Mux chọn nguồn cho operand B (rs2)
    always_comb begin : mux_operand_b
         case (forward_id_b)
            RS2_ID  : operand_b_id = rs2_data_id;
            RD_EX  : operand_b_id = alu_result_ex;
            RD_MEM : operand_b_id = wb_data_mem;
            default: operand_b_id = rs2_data_id;
        endcase
    end

endmodule
