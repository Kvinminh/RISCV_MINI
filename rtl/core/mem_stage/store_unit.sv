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

    // --------------------------------------------------------
    // 1. DATA ALIGNMENT CHO SRAM (Căn chỉnh dữ liệu)
    // --------------------------------------------------------
    // Khi ghi 1 byte (SB) hoặc nửa word (SH), dữ liệu nằm ở các bit thấp của rs2.
    // Ta phải dịch (shift) dữ liệu này đến đúng vị trí byte tương ứng trên bộ nhớ
    // dựa vào 2 bit cuối của địa chỉ (alu_result_i[1:0]).
    always_comb begin
        case (alu_result_i[1:0])
            2'b00: sram_wdata_o = rs2_data_i;                           // Byte 0 (Không dịch)
            2'b01: sram_wdata_o = {rs2_data_i[23:0], 8'h00};            // Byte 1 (Dịch trái 8 bit)
            2'b10: sram_wdata_o = {rs2_data_i[15:0], 16'h0000};         // Byte 2 (Dịch trái 16 bit)
            2'b11: sram_wdata_o = {rs2_data_i[7:0],  24'h000000};       // Byte 3 (Dịch trái 24 bit)
        endcase
        
        // Mẹo viết gọn: sram_wdata_o = rs2_data_i << {alu_result_i[1:0], 3'b000};
        
    end

    //     always_comb begin
    //     // Khởi tạo mặc định đề phòng sinh Latch
    //     sram_wdata_o = 32'h0; 

    //     case (alu_result_i[1:0])
    //         // Địa chỉ chia hết cho 4 -> Dữ liệu nằm đúng Làn 0 (Không đẩy)
    //         2'b00: sram_wdata_o = rs2_data_i;        
            
    //         // Địa chỉ dư 1 -> Đẩy dữ liệu sang Làn 1 (Dịch 8 bit)
    //         2'b01: sram_wdata_o = rs2_data_i << 8;   
            
    //         // Địa chỉ dư 2 -> Đẩy dữ liệu sang Làn 2 (Dịch 16 bit)
    //         2'b10: sram_wdata_o = rs2_data_i << 16;  
            
    //         // Địa chỉ dư 3 -> Đẩy dữ liệu sang Làn 3 (Dịch 24 bit)
    //         2'b11: sram_wdata_o = rs2_data_i << 24;  
            
    //         default: sram_wdata_o = 32'h0;
    //     endcase
    // end

    // --------------------------------------------------------
    // 2. ĐỊNH TUYẾN TÍN HIỆU ĐIỀU KHIỂN (Routing)
    // --------------------------------------------------------
    // Chỉ kích hoạt tín hiệu Ghi (WE/Valid) cho thiết bị đang được chọn.

    // Kênh SRAM:
    assign sram_we_o   = (dev_sel_i == DEV_SRAM) ? mem_wri_i : 1'b0;
    assign sram_mask_o = (dev_sel_i == DEV_SRAM) ? mask_i : 4'b0000;

    // Kênh UART:
    // UART thường nhận data theo từng Byte, nên ta chỉ lấy 8 bit thấp của rs2_data.
    assign uart_tx_valid_o = (dev_sel_i == DEV_UART) ? mem_wri_i : 1'b0;
    assign uart_tx_data_o  = rs2_data_i[7:0]; 

endmodule
