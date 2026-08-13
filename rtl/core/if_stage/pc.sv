`timescale 1ns/1ps
module pc

import core_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input logic stall_pc_i,
    input logic [XLEN-1:0] pc_next_i,
    output logic [XLEN-1:0] pc_cur_o

);
   

    always_ff @( posedge clk or negedge rst_n) begin 
        if ( !rst_n) pc_cur_o <= '0;
        else if ( !stall_pc_i) pc_cur_o <= pc_next_i;
    end

endmodule
