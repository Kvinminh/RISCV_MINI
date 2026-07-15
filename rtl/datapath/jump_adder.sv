module jump_adder 
import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input  logic [31:0] base_addr,
    input  logic [31:0] imm_out,
    input  logic         is_jalr,
    output logic [31:0] addr_if_jump
);

    logic [31:0] sum;
    assign sum = base_addr + imm_out;

    // spec JALR: bit0 của kết quả phải bị clear về 0
    assign addr_if_jump = is_jalr ? {sum[31:1], 1'b0} : sum;

endmodule