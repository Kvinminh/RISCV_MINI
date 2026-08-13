module br_compare
  import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input  logic [XLEN-1:0] compare_a_i,
    input  logic [XLEN-1:0] compare_b_i,
    input  b_type_f3_e      f3_i,
    input  logic            br_en_i,
    output logic            br_taken_o
);

    logic equal;
    logic less_signed;
    logic less_unsigned;
    logic taken;

    assign equal         = (compare_a_i == compare_b_i);
    assign less_signed   = ($signed(compare_a_i)   < $signed(compare_b_i));
    assign less_unsigned = (compare_a_i < compare_b_i);

    always_comb begin
        case (f3_i)
            F3_BEQ:  taken = equal;
            F3_BNE:  taken = !equal;
            F3_BLT:  taken = less_signed;
            F3_BGE:  taken = !less_signed;
            F3_BLTU: taken = less_unsigned;
            F3_BGEU: taken = !less_unsigned;
            default: taken = 1'b0;
        endcase
    end

    assign br_taken_o = br_en_i && taken;

endmodule
