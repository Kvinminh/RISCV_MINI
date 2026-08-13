
module sram
    import ctrl_pkg::*;
#(
    parameter DEPTH = 1024 // 1024 words = 4KB
)
(
    input  logic        clk,
    input  logic [31:0] addr,
    input  logic [31:0] sram_wdata_i,
    input  logic [3:0]  sram_mask_i,
    input  logic        sram_we_i,    // Write Enable cho SRAM
    input  dev_sel_e    dev_sel_i,    // Tín hiệu chọn thiết bị từ Address Decoder (đã sửa: đúng kiểu enum)
 
    output logic [31:0] rdata_o
);
 
    // Mảng bộ nhớ
    logic [31:0] mem [0:DEPTH-1];
 
    // Chuyển đổi địa chỉ Byte (CPU) sang địa chỉ Word (SRAM)
    localparam int ADDR_W = $clog2(DEPTH); // DEPTH=1024 -> ADDR_W=10

    logic [ADDR_W-1:0] word_addr;
    assign word_addr = addr[ADDR_W+1:2]; // = addr[11:2], lấy đúng 10 bit
    // --------------------------------------------------------
    // ĐỌC LÝ TƯỞNG (Combinational Read)
    // Dữ liệu tuôn ra ngay lập tức mà không cần chờ clock.
    // Chỉ đọc khi SRAM thực sự được chọn (dev_sel_i == DEV_SRAM),
    // tránh phụ thuộc ngầm vào giá trị bit thấp của enum.
    // --------------------------------------------------------
    assign rdata_o = (dev_sel_i == DEV_SRAM) ? mem[word_addr] : 32'h0000_0000;
 
    // --------------------------------------------------------
    // GHI (Synchronous Write)
    // sram_we_i đã được store_unit gate theo dev_sel_i == DEV_SRAM rồi,
    // nên ở đây chỉ cần dùng thẳng sram_we_i.
    // --------------------------------------------------------
    always_ff @(posedge clk) begin
        if (sram_we_i) begin
            if (sram_mask_i[0]) mem[word_addr][7:0]   <= sram_wdata_i[7:0];
            if (sram_mask_i[1]) mem[word_addr][15:8]  <= sram_wdata_i[15:8];
            if (sram_mask_i[2]) mem[word_addr][23:16] <= sram_wdata_i[23:16];
            if (sram_mask_i[3]) mem[word_addr][31:24] <= sram_wdata_i[31:24];
        end
    end
 
endmodule
 
