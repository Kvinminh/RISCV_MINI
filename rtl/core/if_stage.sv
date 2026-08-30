
`timescale 1ns/1ps

module if_stage
import core_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input logic stall_pc_i,
    input jump_t    jump_id_i,

    // --- Instruction memory port (mới) ---
    input  logic [XLEN-1:0] ins_i,

    output if_id_reg_t if_reg_o
);

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

    // IMEM is instantiated at top level; feed its instruction word into IF.
    assign ins = ins_i;

    always_comb begin : packed_if
        if_reg_o.pc_cur = pc_cur;
        if_reg_o.pc_4   = pc4;
        if_reg_o.ins    = ins;
    end

endmodule
