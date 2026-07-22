module load_unit (
    input  logic [31:0] mem_rdata_raw,
    input  logic [3:0]  mask,
    input  logic        extension_mem, // 1: Sign Extend, 0: Zero Extend
    
    output logic [31:0] mem_rdata
);

    logic [31:0] aligned_data; // Dữ liệu đã dịch về đúng vị trí (nhưng chưa mở rộng)

    // Bước 1: Trích xuất và dịch dữ liệu về vị trí bit [0] dựa vào mask
    always_comb begin
        case (mask)
            // Load Byte (Cắt 8 bit)
            4'b0001: aligned_data = {24'h0, mem_rdata_raw[7:0]};
            4'b0010: aligned_data = {24'h0, mem_rdata_raw[15:8]};
            4'b0100: aligned_data = {24'h0, mem_rdata_raw[23:16]};
            4'b1000: aligned_data = {24'h0, mem_rdata_raw[31:24]};
            
            // Load Halfword (Cắt 16 bit)
            4'b0011: aligned_data = {16'h0, mem_rdata_raw[15:0]};
            4'b1100: aligned_data = {16'h0, mem_rdata_raw[31:16]};
            
            // Load Word (Lấy cả 32 bit)
            4'b1111: aligned_data = mem_rdata_raw;
            
            // Default
            default: aligned_data = 32'h0;
        endcase
    end

    // Bước 2: Xử lý Sign Extension / Zero Extension
    always_comb begin
        // Mặc định là Zero Extension (Vì bước 1 ta đã chèn số 0 vào các bit cao)
        mem_rdata = aligned_data; 

        // Nếu CPU yêu cầu Sign Extension (các lệnh lb, lh)
        if (extension_mem == 1'b1) begin
            case (mask)
                // Các trường hợp Load Byte -> Kiểm tra bit dấu ở vị trí bit [7]
                4'b0001, 4'b0010, 4'b0100, 4'b1000: begin
                    if (aligned_data[7]) 
                        mem_rdata = {24'hFF_FFFF, aligned_data[7:0]};
                end
                
                // Các trường hợp Load Halfword -> Kiểm tra bit dấu ở vị trí bit [15]
                4'b0011, 4'b1100: begin
                    if (aligned_data[15]) 
                        mem_rdata = {16'hFFFF, aligned_data[15:0]};
                end
                
                // Load Word thì không cần mở rộng dấu
                default: mem_rdata = aligned_data;
            endcase
        end
    end

endmodule
