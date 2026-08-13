module ex_mem_reg
import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input logic             clk,
    input logic             rst_n,
    input ex_mem_reg_t       reg_i,
    output ex_mem_reg_t      reg_o
);

always_ff @( posedge clk  or negedge rst_n)begin
    if(!rst_n) reg_o <= '0;
    else reg_o <= reg_i;
end


endmodule
