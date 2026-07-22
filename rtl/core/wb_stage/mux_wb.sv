module mux_wb 
import ctrl_pkg::*;
import core_pkg::*;

  (
    input  logic [XLEN-1:0]      pc4_mem,
    input  logic [XLEN-1:0]      mem_rdata,
    input  logic [XLEN-1:0]      alu_mem,
    input  ctrl_pkg::wb_sel_e    wb_sel,
    output logic [XLEN-1:0]      wb_data
);
   
    always_comb begin
        wb_data = '0;
        case(wb_sel)
        PC4_MEM: wb_data = pc4_mem;
        ALU_MEM: wb_data = alu_mem;
        MEM_RDATA: wb_data = mem_rdata;
        default: wb_data ='0;
        endcase
    end

endmodule


