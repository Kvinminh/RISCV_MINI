module lsu_ctrl
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input i_type_load_f3_e f3_mem_i,
    input logic  [1:0]    alu_result_i,
    output logic [3:0]    mask_o
);

always_comb begin
    mask_o = '0;
    case(f3_mem_i)
        F3_LB, F3_LBU: begin
            case(alu_result_i)
                2'b00: mask_o = 4'b0001;
                2'b01: mask_o = 4'b0010;
                2'b10: mask_o = 4'b0100;
                2'b11: mask_o = 4'b1000;
            endcase
        end
        F3_LH, F3_LHU: begin
           
            case (alu_result_i[1])
                1'b0: mask_o = 4'b0011; 
                1'b1: mask_o = 4'b1100; 
            endcase
        end
        F3_LW: mask_o = 4'b1111;
        default: mask_o = '0;
    endcase
end
endmodule
