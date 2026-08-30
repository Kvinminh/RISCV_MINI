module id_ex_reg
    import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;
(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       id_ex_flush,

    input  id_ex_reg_t id_reg_i,
    output id_ex_reg_t ex_reg_o
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ex_reg_o <= '0;
        else if (id_ex_flush)
            ex_reg_o <= '0;
        else
            ex_reg_o <= id_reg_i;
    end

endmodule
