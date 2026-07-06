
module alu 
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input  logic [31:0] a,
    input  logic [31:0] b,
    // Ví dụ một kiểu dữ liệu enum điều khiển ALU lấy từ ctrl_pkg
    input  ctrl_pkg::alu_op_e alu_control, 
    output logic [31:0] result,
    output logic        zero
);

    // Hoặc có thể import toàn bộ vào bên trong module để dùng ngắn gọn
    

    always_comb begin
        // Logic tính toán của ALU dựa trên các định nghĩa từ package
    end

endmodule
