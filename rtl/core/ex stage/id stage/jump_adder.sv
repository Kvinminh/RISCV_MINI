module jump_adder 
import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input  logic [31:0] jump_adder_a,
    input  logic [31:0] jump_adder_b,
    output logic [31:0] addr_if_jump
);

   assign addr_if_jump = jump_adder_a + jump_adder_b;

endmodule