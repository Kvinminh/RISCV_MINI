`timescale 1ns/1ps
module pc_4
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic [XLEN-1:0] pc_cur_i,
    output logic [XLEN-1:0] pc4_o
);

assign pc4_o = pc_cur_i + 32'd4;

endmodule
