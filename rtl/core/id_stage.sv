module id_stage
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input  logic clk,
    input  logic rst_n,

    // ---- từ if_id_reg ----
    input  logic [XLEN-1:0] pc_cur_id,
    input  logic [XLEN-1:0] pc4_id,
    input  logic [XLEN-1:0] ins_id,

    // ---- writeback từ WB stage ----
    input  logic                  reg_en_wb,
    input  logic [REG_ADDR_W-1:0] rd_addr_wb,
    input  logic [XLEN-1:0]       rd_data_wb,

    // ---- forward từ EX stage ----
    input  logic [REG_ADDR_W-1:0] rd_ex,
    input  logic                  reg_en_ex,
    input  logic                  mem_re_ex,
    input  logic [XLEN-1:0]       alu_result_ex,

    // ---- forward từ MEM stage ----
    input  logic [REG_ADDR_W-1:0] rd_mem,
    input  logic                  reg_en_mem,
    input  logic                  mem_re_mem,
    input  logic [XLEN-1:0]       wb_data_mem,

    // ---- output ngược ra IF stage (qua pc_mux) ----
    output logic              br_taken_id,
    output logic              jal_id,
    output logic              jalr_id,
    output logic [XLEN-1:0]   pc_jump_id,

    // ---- output control cho PC / if_id_reg / id_ex_reg ----
    output logic stall_pc,
    output logic stall_if_id,
    output logic flush_if_id,
    output logic flush_id_ex,

    // ---- output đi vào id_ex_reg ----
    output logic [2:0]            f3_id,
    output logic                  f7_5_id,
    output logic [XLEN-1:0]       pc_cur_ex,
    output logic [XLEN-1:0]       pc4_ex,
    output logic [XLEN-1:0]       imm_ex,
    output logic [REG_ADDR_W-1:0] rd_addr_ex,
    output logic [REG_ADDR_W-1:0] rs1_addr_ex,
    output logic [REG_ADDR_W-1:0] rs2_addr_ex,
    output logic [XLEN-1:0]       rs1_data_ex,
    output logic [XLEN-1:0]       rs2_data_ex,
    output ex_ctrl_s              ex_ctrl_id,
    output mem_ctrl_s             mem_ctrl_id,
    output logic                  extension_id,
    output wb_ctrl_s              wb_ctrl_id
);

    // ---- tách rs1/rs2/rd trực tiếp từ instruction ----
    logic [REG_ADDR_W-1:0] rs1_addr_id, rs2_addr_id, rd_addr_id;
    assign rs1_addr_id = ins_id[19:15];
    assign rs2_addr_id = ins_id[24:20];
    assign rd_addr_id  = ins_id[11:7];

    // ---- decode ----
    decode_s deco;
    logic rs1_used_id, rs2_used_id, take_jump_id, extension;

    decode u_decode (
        .ins          (ins_id),
        .deco         (deco),
        .rs1_used_id  (rs1_used_id),
        .rs2_used_id  (rs2_used_id),
        .take_jump_id (take_jump_id),
        .extension_ex (extension_ex)
    );

    // ---- regfile ----
    logic [XLEN-1:0] rs1_data_id, rs2_data_id;

    regfile u_regfile (
        .clk         (clk),
        .rst_n       (rst_n),
        .rs1_addr_id (rs1_addr_id),
        .rs2_addr_id (rs2_addr_id),
        .reg_en_wb   (reg_en_wb),
        .rd_addr_wb  (rd_addr_wb),
        .rd_data_wb  (rd_data_wb),
        .rs1_data_id (rs1_data_id),
        .rs2_data_id (rs2_data_id)
    );

    // ---- immgen ----
    logic [XLEN-1:0] imm_out_id;

    immgen u_immgen (
        .ins_id     (ins_id),
        .imm_sel    (deco.imm_sel),
        .imm_out_id (imm_out_id)
    );

    // ---- forward_id: chọn nguồn operand cho branch/jump ----
    for_sel_e forward_id_a, forward_id_b;

    forward_id u_forward_id (
        .rs1_addr_id  (rs1_addr_id),
        .rs2_addr_id  (rs2_addr_id),
        .rd_ex        (rd_ex),
        .reg_en_ex    (reg_en_ex),
        .rd_mem       (rd_mem),
        .reg_en_mem   (reg_en_mem),
        .forward_id_a (forward_id_a),
        .forward_id_b (forward_id_b)
    );

    // ---- mux_br_compare: operand đã forward cho branch ----
    logic [XLEN-1:0] operand_a_id, operand_b_id;

    mux_br_compare u_mux_br_compare (
        .rs1_data_id   (rs1_data_id),
        .rs2_data_id   (rs2_data_id),
        .alu_result_ex (alu_result_ex),
        .wb_data_mem   (wb_data_mem),
        .forward_id_a  (forward_id_a),
        .forward_id_b  (forward_id_b),
        .operand_a_id  (operand_a_id),
        .operand_b_id  (operand_b_id)
    );

    // ---- br_compare ----
    b_type_f3_e f3_br;
    assign f3_br = b_type_f3_e'(ins_id[14:12]);

    br_compare u_br_compare (
        .operand_a_id (operand_a_id),
        .operand_b_id (operand_b_id),
        .f3_br           (f3_br),
        .br_en        (deco.br_en),
        .br_taken     (br_taken_id)
    );

    // ---- mux_base_jump_adder: base cho JAL/JALR ----
    logic [XLEN-1:0] jump_adder_a, jump_adder_b;

    mux_base_jump_adder u_mux_base_jump_adder (
        .rs1_data_id   (rs1_data_id),
        .pc_cur_id     (pc_cur_id),
        .imm_id        (imm_out_id),
        .jalr_id       (deco.jalr_en),
        .alu_result_ex (alu_result_ex),
        .wb_data_mem   (wb_data_mem),
        .forward_id_a  (forward_id_a),
        .jump_adder_a  (jump_adder_a),
        .jump_adder_b  (jump_adder_b)
    );

    jump_adder u_jump_adder (
        .jump_adder_a (jump_adder_a),
        .jump_adder_b (jump_adder_b),
        .pc_jump_id   (pc_jump_id)
    );

    assign jal_id  = deco.jal_en;
    assign jalr_id = deco.jalr_en;

    // ---- hazzard ----
    hazzard u_hazzard (
        .rs1_addr_id  (rs1_addr_id),
        .rs2_addr_id  (rs2_addr_id),
        .rs1_used_id  (rs1_used_id),
        .rs2_used_id  (rs2_used_id),
        
        .take_jump_id (take_jump_id),
        .br_en_id     (deco.br_en),
        .br_taken     (br_taken_id),

        .rd_ex        (rd_ex),
        .reg_en_ex    (reg_en_ex),
        .mem_re_ex    (mem_re_ex),

        .rd_mem       (rd_mem),
        .reg_en_mem   (reg_en_mem),
        .mem_re_mem   (mem_re_mem),

        .stall_pc     (stall_pc),
        .stall_if_id  (stall_if_id),
        .flush_if_id  (flush_if_id),
        .flush_id_ex  (flush_id_ex) 
    );

    // ---- output đi vào id_ex_reg ----
    assign f3_id        = ins_id[14:12];
    assign f7_5_id       = ins_id[30];
    assign pc_cur_ex     = pc_cur_id;
    assign pc4_ex        = pc4_id;
    assign imm_ex        = imm_out_id;
    assign rd_addr_ex    = rd_addr_id;
    assign rs1_addr_ex   = rs1_addr_id;
    assign rs2_addr_ex   = rs2_addr_id;
    assign rs1_data_ex   = rs1_data_id;
    assign rs2_data_ex   = rs2_data_id;
    assign ex_ctrl_id    = deco.ex_ctrl;
    assign mem_ctrl_id   = deco.mem_ctrl;
    assign extension_id  = extension;
    assign wb_ctrl_id    = deco.wb_ctrl;

endmodule