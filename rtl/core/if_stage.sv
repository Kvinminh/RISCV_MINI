


`timescale 1ns/1ps


module if_stage
import core_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input logic stall_pc_i,
    input jump_t    jump_id_i,
    output if_id_reg_t if_reg_o
);
    // //stall
    // logic stall_pc;
    // assign stall_pc = hzd_i.stall_pc;

    // // jump 
    // logic jal,jalr,br_en,br_taken;
    // logic [XLEN-1:0]     jump_addr;
    // always_comb begin : unpack_jump
    //     br_taken =      jump_id_i.br_taken;
    //     br_en =         jump_id_i.br_en;
    //     jal =           jump_id_i.jal;
    //     jalr  =         jump_id_i.jalr;
    // end

    //nội bộ 
    logic [XLEN-1:0] pc_next;
    logic [XLEN-1:0] pc_cur, pc4, ins;  

    pc_4 u_pc_4(
        .pc_cur_i(pc_cur),
        .pc4_o(pc4)
    );

    pc_mux u_pc_mux(
        .jump_id_i(jump_id_i),
        .pc4_i(pc4),
        .pc_next_o(pc_next)
    );


    pc u_pc(
        .clk(clk),
        .rst_n(rst_n),
        .stall_pc_i(stall_pc_i),
        .pc_next_i(pc_next),
        .pc_cur_o(pc_cur)
    );

    imem u_imem(
        .pc_cur_i(pc_cur),
        .ins_o(ins)
    );

    always_comb begin : packed_if
        if_reg_o.pc_cur = pc_cur;
        if_reg_o.pc_4   = pc4;
        if_reg_o.ins    = ins;
    end


endmodule
