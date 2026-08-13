module wb_stage
  import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input  mem_wb_reg_t     wb_i,          // struct nhận từ mem_wb_reg
    output regfile_wb       wb_o
);

logic [XLEN-1:0] wb_data;


    mux_wb u_mux_wb( 
        .pc4_i(wb_i.pc_4),
        .mem_rdata_i(wb_i.alu_result),
        .alu_i(wb_i.mem_rdata),
        .wb_sel_i(wb_i.wb_ctrl.sel_wb),
        .wb_data_o(wb_data)
    );
    
    always_comb begin : pack_wb
        wb_o.reg_en = wb_i.wb_ctrl.reg_en;
        wb_o.rd_addr = wb_i.rd_addr;
        wb_o.rd_data = wb_data;
    end

endmodule