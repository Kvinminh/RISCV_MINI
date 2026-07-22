module store_unit 
import isa_pkg ::*;
import ctrl_pkg ::*;
import core_pkg ::*;
(
    // Inputs từ CPU Pipeline
    input  logic [31:0] rs2_data_mem,   // data caanf ghi 
    input  logic [2:0]  f3_mem,         
    input  logic [31:0] alu_result_mem, // Địa chỉ ghi
    input  logic        mem_wri_mem,    
    input  logic [3:0]  mask,           
    input  dev_sel_e    dev_sel,        // Tín hiệu chọn thiết bị (từ Address Decoder)

    // Outputs cho SRAM
    output logic [31:0] sram_wdata,
    output logic [3:0]  sram_mask,
    output logic        sram_we,

    // Outputs cho UART
    output logic [7:0]  uart_tx_data,
    output logic        uart_tx_valid
);

    // --------------------------------------------------------
    // 1. DATA ALIGNMENT CHO SRAM (Căn chỉnh dữ liệu)
    // --------------------------------------------------------
    // Khi ghi 1 byte (SB) hoặc nửa word (SH), dữ liệu nằm ở các bit thấp của rs2.
    // Ta phải dịch (shift) dữ liệu này đến đúng vị trí byte tương ứng trên bộ nhớ
    // dựa vào 2 bit cuối của địa chỉ (alu_result_mem[1:0]).
    always_comb begin
        case (alu_result_mem[1:0])
            2'b00: sram_wdata = rs2_data_mem;                           // Byte 0 (Không dịch)
            2'b01: sram_wdata = {rs2_data_mem[23:0], 8'h00};            // Byte 1 (Dịch trái 8 bit)
            2'b10: sram_wdata = {rs2_data_mem[15:0], 16'h0000};         // Byte 2 (Dịch trái 16 bit)
            2'b11: sram_wdata = {rs2_data_mem[7:0],  24'h000000};       // Byte 3 (Dịch trái 24 bit)
        endcase
        
        // Mẹo viết gọn: sram_wdata = rs2_data_mem << {alu_result_mem[1:0], 3'b000};
        
    end

    //     always_comb begin
    //     // Khởi tạo mặc định đề phòng sinh Latch
    //     sram_wdata = 32'h0; 

    //     case (alu_result_mem[1:0])
    //         // Địa chỉ chia hết cho 4 -> Dữ liệu nằm đúng Làn 0 (Không đẩy)
    //         2'b00: sram_wdata = rs2_data_mem;        
            
    //         // Địa chỉ dư 1 -> Đẩy dữ liệu sang Làn 1 (Dịch 8 bit)
    //         2'b01: sram_wdata = rs2_data_mem << 8;   
            
    //         // Địa chỉ dư 2 -> Đẩy dữ liệu sang Làn 2 (Dịch 16 bit)
    //         2'b10: sram_wdata = rs2_data_mem << 16;  
            
    //         // Địa chỉ dư 3 -> Đẩy dữ liệu sang Làn 3 (Dịch 24 bit)
    //         2'b11: sram_wdata = rs2_data_mem << 24;  
            
    //         default: sram_wdata = 32'h0;
    //     endcase
    // end

    // --------------------------------------------------------
    // 2. ĐỊNH TUYẾN TÍN HIỆU ĐIỀU KHIỂN (Routing)
    // --------------------------------------------------------
    // Chỉ kích hoạt tín hiệu Ghi (WE/Valid) cho thiết bị đang được chọn.

    // Kênh SRAM:
    assign sram_we   = (dev_sel == DEV_SRAM) ? mem_wri_mem : 1'b0;
    assign sram_mask = (dev_sel == DEV_SRAM) ? mask : 4'b0000;

    // Kênh UART:
    // UART thường nhận data theo từng Byte, nên ta chỉ lấy 8 bit thấp của rs2_data.
    assign uart_tx_valid = (dev_sel == DEV_UART) ? mem_wri_mem : 1'b0;
    assign uart_tx_data  = rs2_data_mem[7:0]; 

endmodule
