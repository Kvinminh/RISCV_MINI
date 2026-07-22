module pc

import core_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input logic stall_pc,
    input logic [XLEN-1:0] pc_next_if,
    output logic [XLEN-1:0] pc_cur_if

);

always_ff @( posedge clk or negedge rst_n) begin 
    if ( !rst_n) pc_cur_if <= '0;
    else if ( !stall_pc) pc_cur_if <= pc_next_if;
end

endmodule
