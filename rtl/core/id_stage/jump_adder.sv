module jump_adder 
import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input  logic [XLEN-1:0] jump_a_i,
    input  logic [XLEN-1:0] jump_b_i,
    output  logic [XLEN-1:0] jump_adder_o
    
);

   assign jump_adder_o = jump_a_i + jump_b_i;

endmodule
