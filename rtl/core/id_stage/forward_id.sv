module forward_id
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic [REG_ADDR_W-1:0]   rs1_addr_i,
    input logic [REG_ADDR_W-1:0]   rs2_addr_i,
    input for_info_t               for_info_ex_i,
    input for_info_t               for_info_mem_i,

    output for_sel_e               for_id_a_o,
    output for_sel_e               for_id_b_o
);

    always_comb begin : sel_for_id_a_o
        for_id_a_o = RS1_DATA_ID;
        if (rs1_addr_i != '0) begin
            if((for_info_ex_i.reg_en) && (rs1_addr_i == for_info_ex_i.rd_addr)) begin
                  for_id_a_o = RD_DATA_EX;
            end     
            else if ( (for_info_mem_i.reg_en ) && (rs1_addr_i == for_info_mem_i.rd_addr)) begin
               for_id_a_o = RD_DATA_MEM;
            end 
        end
    end





    always_comb begin : sel_for_id_b_o
        for_id_b_o = RS2_DATA_ID;
        if (rs2_addr_i != '0) begin
            if   ((for_info_ex_i.reg_en)  && (rs2_addr_i == for_info_ex_i.rd_addr))   begin
                  for_id_b_o = RD_DATA_EX;
            end
            else if ((for_info_mem_i.reg_en ) && (rs2_addr_i == for_info_mem_i.rd_addr)) begin
                 for_id_b_o = RD_DATA_MEM;
            end 
        end
    end

endmodule
