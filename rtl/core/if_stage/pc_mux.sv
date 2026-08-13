`timescale 1ns/1ps
module pc_mux
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input jump_t jump_id_i,
    input logic [XLEN-1:0] pc4_i,
    output logic [XLEN-1:0] pc_next_o
);
    logic jal,jalr,br_en,br_taken;
    logic [XLEN-1:0]     jump_addr;

    always_comb begin : unpack_jump
        br_taken =      jump_id_i.br_taken;
        br_en =         jump_id_i.br_en;
        jal =           jump_id_i.jal;
        jalr  =         jump_id_i.jalr;
        jump_addr =     jump_id_i.jump_addr;
    end

    pc_sel_e pc_sel;
    assign pc_sel =  pc_sel_e'(( br_taken && br_en) || jal || jalr);

    always_comb begin : sel_jump_addr
        pc_next_o = pc4_i;
        case( pc_sel)
            PC4: begin
                pc_next_o = pc4_i;
            end 
            PC_JUMP: begin
                pc_next_o = jump_addr;
            end 
            default: pc_next_o = pc4_i;
        endcase
    end 
endmodule
