module lsu_ctrl
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input i_type_load_f3_e f3_mem,
    input logic  [1:0]    alu_result_mem, // byte offfset
    output logic [3:0]    mask
);

always_comb begin
    mask = '0;
    case(f3_mem)
        F3_LB, F3_LBU: begin
            case(alu_result_mem)
            2'b00: mask = 4'b0001;
            2'b01: mask = 4'b0010;
            2'b10: mask = 4'b0100;
            2'b11: mask = 4'b1000;
            endcase
        end 
        F3_LB,F3_LHU: begin
            // Chỉ xét bit [1] vì mặc định bit [0] = 0 (Aligned)
            case (alu_result_mem[1])
                1'b0: mask = 4'b0011; // alu_result = 2'b00
                1'b1: mask = 4'b1100; // alu_result = 2'b10
            endcase
        end
        F3_LW: mask = 4'b1111;
        default: mask = '0;
    endcase
end
endmodule
