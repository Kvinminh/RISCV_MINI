module store_unit 
import isa_pkg ::*;
import ctrl_pkg ::*;
import core_pkg ::*;
(
    // Inputs từ CPU Pipeline
    input  logic [31:0] rs2_data_i,   // data caanf ghi 
    // input  logic [2:0]  f3_i,         
    input  logic [31:0] alu_result_i, // Địa chỉ ghi
    input  logic        mem_wri_i,    
    input  logic [3:0]  mask_i,           
    input  dev_sel_e    dev_sel_i,        // Tín hiệu chọn thiết bị (từ Address Decoder)

    // Outputs cho SRAM
    output logic [31:0] sram_wdata_o,
    output logic [3:0]  sram_mask_o,
    output logic        sram_we_o,

    // Outputs cho UART
    output logic [7:0]  uart_tx_data_o,
    output logic        uart_tx_valid_o
);

    always_comb begin
        case (alu_result_i[1:0])
            2'b00: sram_wdata_o = rs2_data_i;                           
            2'b01: sram_wdata_o = {rs2_data_i[23:0], 8'h00};            
            2'b10: sram_wdata_o = {rs2_data_i[15:0], 16'h0000};         
            2'b11: sram_wdata_o = {rs2_data_i[7:0],  24'h000000};      
        endcase 
    end

    
    
    // Kênh SRAM:
    assign sram_we_o   = (dev_sel_i == DEV_SRAM) ? mem_wri_i : 1'b0;
    assign sram_mask_o = (dev_sel_i == DEV_SRAM) ? mask_i : 4'b0000;

    // Kênh UART:
    assign uart_tx_valid_o = (dev_sel_i == DEV_UART) ? mem_wri_i : 1'b0;
    assign uart_tx_data_o  = rs2_data_i[7:0]; 

endmodule
