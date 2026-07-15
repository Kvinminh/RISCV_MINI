module br_compare
 import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input logic [XLEN-1:0]      operand_a_id,
    input logic [XLEN-1:0]      operand_b_id,
    input b_type_f3_e [F3-1:0]  f3,
    input logic                 br_en,
    output logic                be_taken
);

logic equal ;
logic less ;
logic less_unsign ;
logic taken;


assign equal        =  (operand_a_id == operand_b_id);
assign less         =  ($signed(operand_a_id) < $signed(operand_b_id));
assign less_unsign  =  (operand_a_id < operand_b_id);

always_comb begin
        case (br_type)
            F3_BEQ:  taken = equal;
            F3_BNE:  taken = !equal;
            F3_BLT:  taken = less_signed;
            F3_BGE:  taken = !less_signed;
            F3_BLTU: taken = less_unsigned;
            F3_BGEU: taken = !less_unsigned;
            default: taken = 1'b0;
        endcase
    end

    assign br_taken = br_en && taken;


endmodule