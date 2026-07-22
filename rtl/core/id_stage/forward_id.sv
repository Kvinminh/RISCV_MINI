module forward_id
import ctrl_pkg::*;
import core_pkg::*;
(
    input  logic [REG_ADDR_W-1:0] rs1_addr_id,
    input  logic [REG_ADDR_W-1:0] rs2_addr_id,
    input  logic [REG_ADDR_W-1:0] rd_ex,
    input  logic                  reg_en_ex,
    input  logic [REG_ADDR_W-1:0] rd_mem,
    input  logic                  reg_en_mem,

    output for_sel_e               forward_id_a,
    output for_sel_e               forward_id_b
);

    always_comb begin : sel_forward_id_a
        forward_id_a = RS1_ID;
        if (rs1_addr_id != '0) begin
            if      (reg_en_ex  && (rs1_addr_id == rd_ex))  forward_id_a = RD_EX;
            else if (reg_en_mem && (rs1_addr_id == rd_mem)) forward_id_a = RD_MEM;
        end
    end

    always_comb begin : sel_forward_id_b
        forward_id_b = RS2_ID;
        if (rs2_addr_id != '0) begin
            if      (reg_en_ex  && (rs2_addr_id == rd_ex))  forward_id_b = RD_EX;
            else if (reg_en_mem && (rs2_addr_id == rd_mem)) forward_id_b = RD_MEM;
        end
    end

endmodule
