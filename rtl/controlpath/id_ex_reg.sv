module id_ex_reg
import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input logic             clk,
    input logic             rst_n,
    input id_ex_reg_t       id,
    input id_ex_reg_t       ex,
);

always_ff @( posedge clk  or negedge rst_n)begin
    if(!rst_n) ex <= '0;
    else ex <= id;
end


endmodule