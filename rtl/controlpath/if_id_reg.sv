module if_id_reg
    import core_pkg::*;
(
    input  logic         clk,
    input  logic         rst_n,
    input  logic         flush_if_id_i,
    input  logic         stall_if_id_i,
    input  if_id_reg_t   if_reg_i,
    output if_id_reg_t   id_reg_o
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            id_reg_o <= '0;
        else if (flush_if_id_i)
            id_reg_o <= '0;
        else if (!stall_if_id_i)
            id_reg_o <= if_reg_i;
    end
endmodule
