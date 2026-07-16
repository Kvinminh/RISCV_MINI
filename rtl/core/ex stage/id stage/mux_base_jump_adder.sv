module mux_jump_adder
  import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input  logic [XLEN-1:0] rs1_data_id,   // raw từ regfile
    input  logic [XLEN-1:0] pc_cur_id,
    input  logic [XLEN-1:0] imm_id,

    input  logic             jalr_id,       // chỉ JALR mới cần rs1

    input  logic [XLEN-1:0] alu_result_ex,  // data forward từ EX
    input  logic [XLEN-1:0] wb_data_mem,    // data forward từ MEM
    input  for_sel_e         forward_id_a,  // dùng chung kết quả từ forward_id

    output logic [XLEN-1:0] jump_adder_a,
    output logic [XLEN-1:0] jump_adder_b
);

    logic [XLEN-1:0] rs1_data_fwd;

    always_comb begin : mux_rs1_jump
        case (forward_id_a)
            RD_EX  : rs1_data_fwd = alu_result_ex;
            RD_MEM : rs1_data_fwd = wb_data_mem;
            default: rs1_data_fwd = rs1_data_id;   // RS_ID
        endcase
    end

    // JALR dùng rs1 (đã forward), JAL/branch dùng PC
    assign jump_adder_a = jalr_id ? rs1_data_fwd : pc_cur_id;
    assign jump_adder_b = imm_id;

endmodule