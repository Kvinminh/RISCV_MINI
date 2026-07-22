module mem_wb_reg
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input mem_wb_reg_t mem,
    output mem_wb_reg_t wb
);


always_ff @(posedge clk or negedge rst_n) begin
    if ( !rst_n) begin
        wb <= '0;
    end
    else begin
        wb <= mem;
    end
end
endmodule
