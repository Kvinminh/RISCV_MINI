module addres_decodet
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic [XLEN-1:0]  alu_result_i,
    input logic             mem_re,
    input logic             mem_wri,
    output dev_sel_e            dev_sel_o
);

logic valid_req;
assign valid_req = mem_re || mem_wri;

    always_comb begin
        dev_sel_o = DEV_NONE; 

        if (valid_req) begin
           
            case (alu_result_i[31:28])
                
               
                4'h0: dev_sel_o = DEV_SRAM; 
                
                
                4'h4: begin 
                    
                    case (alu_result_i[15:12])
                        4'h0: dev_sel_o = DEV_UART; // 0x4000_0...
                        4'h1: dev_sel_o = DEV_GPIO; // 0x4000_1...
                        default: dev_sel_o = DEV_NONE;
                    endcase
                end
                
                default: dev_sel_o = DEV_NONE;
            endcase
        end
    end
endmodule
