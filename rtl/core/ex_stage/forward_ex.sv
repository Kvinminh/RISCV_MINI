module forward_ex
import ctrl_pkg::*;
import core_pkg::*;
(
    input  logic [REG_ADDR_W-1:0] rs1_addr_i,
    input  logic [REG_ADDR_W-1:0] rs2_addr_i,

    // input  logic [REG_ADDR_W-1:0] for_info_mem_i.rd_addr,      // lệnh liền trước (đang ở MEM)
    // input  logic                  for_info_mem_i.reg_en,

    // input  logic [REG_ADDR_W-1:0] for_info_wb_i.rd_addr,       // lệnh trước nữa (đang ở WB)
    // input  logic                  for_info_wb_i.rd_addr,

    input for_info_t            for_info_mem_i,
    input for_info_t            for_info_wb_i,


    output forward_e            for_ex_a_o,
    output forward_e            for_ex_b_o
);

    // ---- operand A (rs1) ----
    always_comb begin : sel_for_ex_a_o
        for_ex_a_o = RD_EX;
        if (rs1_addr_i != '0) begin
            if      (for_info_mem_i.reg_en && (rs1_addr_i == for_info_mem_i.rd_addr)) for_ex_a_o = RD_MEM;
            else if (for_info_wb_i.reg_en  && (rs1_addr_i == for_info_wb_i.rd_addr)) for_ex_a_o = RD_WB;
        end
    end

    // ---- operand B (rs2) ----
    always_comb begin : sel_for_ex_b_o
        for_ex_b_o = RD_EX;
        if (rs2_addr_i != '0) begin
            if      (for_info_mem_i.reg_en && (rs2_addr_i == for_info_mem_i.rd_addr)) for_ex_b_o = RD_MEM;
            else if (for_info_wb_i.reg_en  && (rs2_addr_i == for_info_wb_i.rd_addr)) for_ex_b_o = RD_WB;
        end
    end

endmodule
