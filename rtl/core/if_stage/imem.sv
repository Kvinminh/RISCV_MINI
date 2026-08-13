

`timescale 1ns/1ps
module imem
import core_pkg::*;
(
    input logic [XLEN-1:0] pc_cur_i,
    output logic [XLEN-1:0] ins_o
);

   
    parameter IMEM_DEPTH = 1024;
     localparam int ADDR_W = $clog2(IMEM_DEPTH); // = 10
    logic [XLEN-1:0] memory[0:IMEM_DEPTH-1];

    // Tải chương trình vào bộ nhớ từ file hex (dùng cho mô phỏng)
    initial begin
    $readmemh("program.mem", memory);
    end
    // Đọc lệnh bất đồng bộ (tổ hợp)
    // Lưu ý: PC (Program Counter) thường đánh địa chỉ theo byte (byte-addressable).
    // Do mỗi lệnh có kích thước 4 byte (32-bit), ta cần dịch phải 2 bit (chia cho 4)
    // để trỏ đúng vào chỉ số (index) của mảng memory (word-addressable).
    assign ins_o = memory[pc_cur_i[ADDR_W+1:2]]; // = pc_cur_i[11:2]

endmodule
