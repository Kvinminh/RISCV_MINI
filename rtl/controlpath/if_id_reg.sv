module if_id_reg
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input logic stall_if_id,
    input if_id_reg_t if_i,
    output if_id_reg_t id_o
);
    always_ff @(posedge clk or negedge rst_n) begin 
        if ( !rst_n) id_o <= '0;
        else if ( !stall_if_id) id_o <= if_i;
    end
endmodule
