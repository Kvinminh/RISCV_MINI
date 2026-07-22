module forward_ex
import ctrl_pkg::*;
import core_pkg::*;
(
    input  logic [REG_ADDR_W-1:0] rs1_addr_ex,
    input  logic [REG_ADDR_W-1:0] rs2_addr_ex,

    input  logic [REG_ADDR_W-1:0] rd_mem_ex,      // lệnh liền trước (đang ở MEM)
    input  logic                  reg_en_mem,

    input  logic [REG_ADDR_W-1:0] rd_wb_ex,       // lệnh trước nữa (đang ở WB)
    input  logic                  reg_en_wb,

    output forward_e            for_ex_a,
    output forward_e            for_ex_b
);

    // ---- operand A (rs1) ----
    always_comb begin : sel_for_ex_a
        for_ex_a = RS_EX_EX;
        if (rs1_addr_ex != '0) begin
            if      (reg_en_mem && (rs1_addr_ex == rd_mem_ex)) for_ex_a = RD_MEM_EX;
            else if (reg_en_wb  && (rs1_addr_ex == rd_wb_ex))  for_ex_a = RD_WB_EX;
        end
    end

    // ---- operand B (rs2) ----
    always_comb begin : sel_for_ex_b
        for_ex_b = RS_EX_EX;
        if (rs2_addr_ex != '0) begin
            if      (reg_en_mem && (rs2_addr_ex == rd_mem_ex)) for_ex_b = RD_MEM_EX;
            else if (reg_en_wb  && (rs2_addr_ex == rd_wb_ex))  for_ex_b = RD_WB_EX;
        end
    end

endmodule
