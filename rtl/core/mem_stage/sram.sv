
module sram_ideal
    import ctrl_pkg::*;
#(
    parameter DEPTH = 1024 // 1024 words = 4KB
)
(
    input  logic        clk,
    input  logic [31:0] addr,
    input  logic [31:0] sram_wdata,
    input  logic [3:0]  sram_mask,
    input  logic        sram_we,    // Write Enable cho SRAM
    input  dev_sel_e    dev_sel,    // Tín hiệu chọn thiết bị từ Address Decoder (đã sửa: đúng kiểu enum)
 
    output logic [31:0] rdata
);
 
    // Mảng bộ nhớ
    logic [31:0] mem [0:DEPTH-1];
 
    // Chuyển đổi địa chỉ Byte (CPU) sang địa chỉ Word (SRAM)
    logic [29:0] word_addr;
    assign word_addr = addr[31:2];
 
    // --------------------------------------------------------
    // ĐỌC LÝ TƯỞNG (Combinational Read)
    // Dữ liệu tuôn ra ngay lập tức mà không cần chờ clock.
    // Chỉ đọc khi SRAM thực sự được chọn (dev_sel == DEV_SRAM),
    // tránh phụ thuộc ngầm vào giá trị bit thấp của enum.
    // --------------------------------------------------------
    assign rdata = (dev_sel == DEV_SRAM) ? mem[word_addr] : 32'h0000_0000;
 
    // --------------------------------------------------------
    // GHI (Synchronous Write)
    // sram_we đã được store_unit gate theo dev_sel == DEV_SRAM rồi,
    // nên ở đây chỉ cần dùng thẳng sram_we.
    // --------------------------------------------------------
    always_ff @(posedge clk) begin
        if (sram_we) begin
            if (sram_mask[0]) mem[word_addr][7:0]   <= sram_wdata[7:0];
            if (sram_mask[1]) mem[word_addr][15:8]  <= sram_wdata[15:8];
            if (sram_mask[2]) mem[word_addr][23:16] <= sram_wdata[23:16];
            if (sram_mask[3]) mem[word_addr][31:24] <= sram_wdata[31:24];
        end
    end
 
endmodule
 
