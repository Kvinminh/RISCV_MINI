module uart (
    input  logic       clk,
    input  logic [7:0] tx_data_i,
    input  logic       tx_valid_i, // Tín hiệu kích hoạt từ store_unit
    
    output logic [31:0] uart_rdata_o  // Vẫn giữ output rdata để khớp với Load Unit
);

    // --------------------------------------------------------
    // IN KẾT QUẢ RA CONSOLE (Không có delay)
    // --------------------------------------------------------
    always_ff @(posedge clk) begin
        // Bất cứ khi nào CPU ghi vào UART, in thẳng ký tự ra log mô phỏng
        if (tx_valid_i) begin
            $write("%c", tx_data_i); // %c in mã ASCII tương ứng của tx_data
        end
    end

    // Vì UART lý tưởng không cần thanh ghi trạng thái (Status Register),
    // nó luôn trả về rdata = 0 nếu CPU vô tình đọc nó.
    assign uart_rdata_o = 32'h0000_0000;

endmodule
