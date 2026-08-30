module read_data_mux
import isa_pkg ::*;
import ctrl_pkg ::*;
import core_pkg ::*;


 (
    input  logic [31:0] sram_rdata_i,
    input  logic [31:0] uart_rdata_i, 
    input  dev_sel_e    dev_sel_i,
    
    output logic [31:0] mem_rdata_raw_o 
);

    always_comb begin
        case (dev_sel_i)
            DEV_SRAM: mem_rdata_raw_o = sram_rdata_i;
            DEV_UART: mem_rdata_raw_o = uart_rdata_i;                    
            default:  mem_rdata_raw_o = 32'h0000_0000; 
        endcase
    end

endmodule
