module if_stage
import core_pkg::*;
(
    input  logic clk,
    input  logic rst_n,
    input  logic stall_pc,

    input  logic              br_taken_id,
    input  logic              br_en_id,
    input  logic              jal_id,
    input  logic              jalr_id,
    input  logic [XLEN-1:0]   pc_jump_id,

    output logic [XLEN-1:0]   pc_cur_if,
    output logic [XLEN-1:0]   pc4_if,
    output logic [XLEN-1:0]   ins_if
);

    logic [XLEN-1:0] pc_next_if;

    pc_4 u_pc_4 (
        .pc_cur_if (pc_cur_if),
        .pc4_if    (pc4_if)
    );

    pc_mux u_pc_mux (
        .br_taken_id (br_taken_id),
        .br_en_id    (br_en_id),
        .jal_id      (jal_id),
        .jalr_id     (jalr_id),
        .pc4_if      (pc4_if),
        .pc_jump_id  (pc_jump_id),
        .pc_next_if  (pc_next_if)
    );

    pc u_pc (
        .clk        (clk),
        .rst_n      (rst_n),
        .stall_pc   (stall_pc),
        .pc_next_if (pc_next_if),
        .pc_cur_if  (pc_cur_if)
    );

    imem u_imem (
        .pc_cur_if (pc_cur_if),
        .ins_if      (ins_if)
    );

endmodule
