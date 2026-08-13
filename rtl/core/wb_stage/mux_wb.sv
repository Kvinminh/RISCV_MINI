module mux_wb 
import ctrl_pkg::*;
import core_pkg::*;

  (
    input  logic [XLEN-1:0]      pc4_i,
    input  logic [XLEN-1:0]      mem_rdata_i,
    input  logic [XLEN-1:0]      alu_i,
    input  ctrl_pkg::wb_sel_e    wb_sel_i,
    output logic [XLEN-1:0]      wb_data_o
);
   
    always_comb begin
        wb_data_o = '0;
        case(wb_sel_i)
        PC4_MEM: wb_data_o = pc4_i;
        ALU_MEM: wb_data_o = alu_i;
        MEM_RDATA: wb_data_o = mem_rdata_i;
        default: wb_data_o ='0;
        endcase
    end

endmodule


