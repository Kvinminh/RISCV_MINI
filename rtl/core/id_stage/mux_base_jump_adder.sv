module mux_base_jump_adder
  import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input  logic [XLEN-1:0] rs1_data_i,   // raw từ regfile
    input  logic [XLEN-1:0] pc_cur_i,
    input  logic [XLEN-1:0] imm_out_i,

    input  logic            jalr_i,       // chỉ JALR mới cần rs1

    // input  logic [XLEN-1:0] alu_result_ex,  // data forward từ EX
    // input  logic [XLEN-1:0] wb_data_mem,    // data forward từ MEM

    // input   for_info_t               for_info_ex_i,
    // input   for_info_t               for_info_mem_i,
    input   logic [XLEN-1:0]        alu_ex_i,
    input   logic [XLEN-1:0]        alu_mem_i,
    input   for_sel_e                for_id_a_i,  // dùng chung kết quả từ forward_id

    output logic [XLEN-1:0] jump_a_o,
    output logic [XLEN-1:0] jump_b_o
);

    logic [XLEN-1:0] rs1_data_fwd;

    always_comb begin : mux_rs1_jump
        case (for_id_a_i)
            RD_DATA_EX  : rs1_data_fwd = alu_ex_i;
            RD_DATA_MEM : rs1_data_fwd = alu_mem_i;
            default: rs1_data_fwd = rs1_data_i;   // RS_ID
        endcase
    end

    // JALR dùng rs1 (đã forward), JAL/branch dùng PC
    assign jump_a_o = jalr_i ? rs1_data_fwd : pc_cur_i;
    assign jump_b_o = imm_out_i;

endmodule
