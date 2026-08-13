module immgen 
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic [XLEN-1:0] ins_i,
    input immgen_sel_e imm_sel_i,
    output logic [XLEN-1:0] imm_out_o
);
instr_fomat_u ins;
assign ins = instr_fomat_u'(ins_i);

always_comb begin 
    imm_out_o = '0;
    case(imm_sel_i) 
        IMMGEN_I: imm_out_o = { {20{ins.i_type.imm_11_0[11]}}, ins.i_type.imm_11_0 };    
        IMMGEN_S: imm_out_o = { {20{ins.s_type.imm_11_5[6]}}, ins.s_type.imm_11_5, ins.s_type.imm_4_0 };      
        IMMGEN_B: imm_out_o = { {19{ins.b_type.imm_12}}, ins.b_type.imm_12, ins.b_type.imm_11, ins.b_type.imm_10_5, ins.b_type.imm_4_1, 1'b0 };
        IMMGEN_U: imm_out_o = { ins.u_type.imm_31_12, 12'b0 };
        IMMGEN_J: imm_out_o = { {11{ins.j_type.imm_20}}, ins.j_type.imm_20, ins.j_type.imm_19_12, ins.j_type.imm_11, ins.j_type.imm_10_1, 1'b0 };      
        default:  imm_out_o = '0;
    endcase
end

endmodule
