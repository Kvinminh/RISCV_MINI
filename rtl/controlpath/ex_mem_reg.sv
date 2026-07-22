module ex_mem_reg
import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input logic             clk,
    input logic             rst_n,
    input ex_mem_reg_t       ex,
    output ex_mem_reg_t      mem
);

always_ff @( posedge clk  or negedge rst_n)begin
    if(!rst_n) mem <= '0;
    else mem <= ex;
end


endmodule