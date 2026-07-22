module read_data_mux
import isa_pkg ::*;
import ctrl_pkg ::*;
import core_pkg ::*;


 (
    input  logic [31:0] sram_rdata,
    input  logic [31:0] status_rdata, // Rdata từ UART (VD: thanh ghi trạng thái)
    input  dev_sel_e    dev_sel,
    
    output logic [31:0] mem_rdata_raw // Dữ liệu thô chưa qua xử lý
);

    always_comb begin
        case (dev_sel)
            DEV_SRAM: mem_rdata_raw = sram_rdata;
            DEV_UART: mem_rdata_raw = status_rdata;
            
            // Nếu truy cập vùng nhớ trống hoặc dev_sel = DEV_NONE, trả về 0
            default:  mem_rdata_raw = 32'h0000_0000; 
        endcase
    end

endmodule