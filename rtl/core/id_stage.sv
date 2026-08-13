// module id_stage
// import isa_pkg::*;
// import ctrl_pkg::*;
// import core_pkg::*;
// (
//     input  logic clk,
//     input  logic rst_n,

//     // ---- từ if_id_reg ----
//     input  logic [XLEN-1:0] pc_cur_id,
//     input  logic [XLEN-1:0] pc4_id,
//     input  logic [XLEN-1:0] ins_id,

//     // ---- writeback từ WB stage ----
//     input  logic                  reg_en_wb,
//     input  logic [REG_ADDR_W-1:0] rd_addr_wb,
//     input  logic [XLEN-1:0]       rd_data_wb,

//     // ---- forward từ EX stage ----
//     input  logic [REG_ADDR_W-1:0] rd_ex,
//     input  logic                  reg_en_ex,
//     input  logic                  mem_re_ex,
//     input  logic [XLEN-1:0]       alu_result_ex,

//     // ---- forward từ MEM stage ----
//     input  logic [REG_ADDR_W-1:0] rd_mem,
//     input  logic                  reg_en_mem,
//     input  logic                  mem_re_mem,
//     input  logic [XLEN-1:0]       wb_data_mem,

//     // ---- output ngược ra IF stage (qua pc_mux) ----
//     output logic              br_taken_id,
//     output logic              jal_id,
//     output logic              jalr_id,
//     output logic [XLEN-1:0]   pc_jump_id,

//     // ---- output control cho PC / if_id_reg / id_ex_reg ----
//     output logic stall_pc,
//     output logic stall_if_id,
//     output logic flush_if_id,
//     output logic flush_id_ex,

//     // ---- output đi vào id_ex_reg ----
//     output logic [2:0]            f3_id,
//     output logic                  f7_5_id,
//     output logic [XLEN-1:0]       pc_cur_ex,
//     output logic [XLEN-1:0]       pc4_ex,
//     output logic [XLEN-1:0]       imm_ex,
//     output logic [REG_ADDR_W-1:0] rd_addr_ex,
//     output logic [REG_ADDR_W-1:0] rs1_addr_ex,
//     output logic [REG_ADDR_W-1:0] rs2_addr_ex,
//     output logic [XLEN-1:0]       rs1_data_ex,
//     output logic [XLEN-1:0]       rs2_data_ex,
//     output ex_ctrl_s              ex_ctrl_id,
//     output mem_ctrl_s             mem_ctrl_id,
//     output logic                  extension_id,
//     output wb_ctrl_s              wb_ctrl_id
// );

//     // ---- tách rs1/rs2/rd trực tiếp từ instruction ----
//     logic [REG_ADDR_W-1:0] rs1_addr_id, rs2_addr_id, rd_addr_id;
//     assign rs1_addr_id = ins_id[19:15];
//     assign rs2_addr_id = ins_id[24:20];
//     assign rd_addr_id  = ins_id[11:7];

//     // ---- decode ----
//     decode_s deco;
//     logic rs1_used_id, rs2_used_id, take_jump_id, extension;

//     decode u_decode (
//         .ins          (ins_id),
//         .deco         (deco),
//         .rs1_used_id  (rs1_used_id),
//         .rs2_used_id  (rs2_used_id),
//         .take_jump_id (take_jump_id),
//         .extension_ex (extension_ex)
//     );

//     // ---- regfile ----
//     logic [XLEN-1:0] rs1_data_id, rs2_data_id;

//     regfile u_regfile (
//         .clk         (clk),
//         .rst_n       (rst_n),
//         .rs1_addr_id (rs1_addr_id),
//         .rs2_addr_id (rs2_addr_id),
//         .reg_en_wb   (reg_en_wb),
//         .rd_addr_wb  (rd_addr_wb),
//         .rd_data_wb  (rd_data_wb),
//         .rs1_data_id (rs1_data_id),
//         .rs2_data_id (rs2_data_id)
//     );

//     // ---- immgen ----
//     logic [XLEN-1:0] imm_out_id;

//     immgen u_immgen (
//         .ins_id     (ins_id),
//         .imm_sel    (deco.imm_sel),
//         .imm_out_id (imm_out_id)
//     );

//     // ---- forward_id: chọn nguồn operand cho branch/jump ----
//     for_sel_e forward_id_a, forward_id_b;

//     forward_id u_forward_id (
//         .rs1_addr_id  (rs1_addr_id),
//         .rs2_addr_id  (rs2_addr_id),
//         .rd_ex        (rd_ex),
//         .reg_en_ex    (reg_en_ex),
//         .rd_mem       (rd_mem),
//         .reg_en_mem   (reg_en_mem),
//         .forward_id_a (forward_id_a),
//         .forward_id_b (forward_id_b)
//     );

//     // ---- mux_br_compare: operand đã forward cho branch ----
//     logic [XLEN-1:0] operand_a_id, operand_b_id;

//     mux_br_compare u_mux_br_compare (
//         .rs1_data_id   (rs1_data_id),
//         .rs2_data_id   (rs2_data_id),
//         .alu_result_ex (alu_result_ex),
//         .wb_data_mem   (wb_data_mem),
//         .forward_id_a  (forward_id_a),
//         .forward_id_b  (forward_id_b),
//         .operand_a_id  (operand_a_id),
//         .operand_b_id  (operand_b_id)
//     );

//     // ---- br_compare ----
//     b_type_f3_e f3_br;
//     assign f3_br = b_type_f3_e'(ins_id[14:12]);

//     br_compare u_br_compare (
//         .operand_a_id (operand_a_id),
//         .operand_b_id (operand_b_id),
//         .f3_br           (f3_br),
//         .br_en        (deco.br_en),
//         .br_taken     (br_taken_id)
//     );

//     // ---- mux_base_jump_adder: base cho JAL/JALR ----
//     logic [XLEN-1:0] jump_adder_a, jump_adder_b;

//     mux_base_jump_adder u_mux_base_jump_adder (
//         .rs1_data_id   (rs1_data_id),
//         .pc_cur_id     (pc_cur_id),
//         .imm_id        (imm_out_id),
//         .jalr_id       (deco.jalr_en),
//         .alu_result_ex (alu_result_ex),
//         .wb_data_mem   (wb_data_mem),
//         .forward_id_a  (forward_id_a),
//         .jump_adder_a  (jump_adder_a),
//         .jump_adder_b  (jump_adder_b)
//     );

//     jump_adder u_jump_adder (
//         .jump_adder_a (jump_adder_a),
//         .jump_adder_b (jump_adder_b),
//         .pc_jump_id   (pc_jump_id)
//     );

//     assign jal_id  = deco.jal_en;
//     assign jalr_id = deco.jalr_en;

//     // ---- hazzard ----
//     hazzard u_hazzard (
//         .rs1_addr_id  (rs1_addr_id),
//         .rs2_addr_id  (rs2_addr_id),
//         .rs1_used_id  (rs1_used_id),
//         .rs2_used_id  (rs2_used_id),
        
//         .take_jump_id (take_jump_id),
//         .br_en_id     (deco.br_en),
//         .br_taken     (br_taken_id),

//         .rd_ex        (rd_ex),
//         .reg_en_ex    (reg_en_ex),
//         .mem_re_ex    (mem_re_ex),

//         .rd_mem       (rd_mem),
//         .reg_en_mem   (reg_en_mem),
//         .mem_re_mem   (mem_re_mem),

//         .stall_pc     (stall_pc),
//         .stall_if_id  (stall_if_id),
//         .flush_if_id  (flush_if_id),
//         .flush_id_ex  (flush_id_ex) 
//     );

//     // ---- output đi vào id_ex_reg ----
//     assign f3_id        = ins_id[14:12];
//     assign f7_5_id       = ins_id[30];
//     assign pc_cur_ex     = pc_cur_id;
//     assign pc4_ex        = pc4_id;
//     assign imm_ex        = imm_out_id;
//     assign rd_addr_ex    = rd_addr_id;
//     assign rs1_addr_ex   = rs1_addr_id;
//     assign rs2_addr_ex   = rs2_addr_id;
//     assign rs1_data_ex   = rs1_data_id;
//     assign rs2_data_ex   = rs2_data_id;
//     assign ex_ctrl_id    = deco.ex_ctrl;
//     assign mem_ctrl_id   = deco.mem_ctrl;
//     assign extension_id  = extension;
//     assign wb_ctrl_id    = deco.wb_ctrl;

// endmodule



module id_stage
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic clk,
    input logic rst_n,

    input if_id_reg_t reg_id_i, // pipeline
    input regfile_wb  wb_i, // 
    input for_info_t  for_info_ex_i, // hazzard forwward
    input for_info_t  for_info_mem_i,// hazzard forwward
    input   logic [XLEN-1:0]        alu_ex_i,
    input   logic [XLEN-1:0]        alu_mem_i,

    output jump_t     jump_o,
    output hzd_ctrl_t hzd_ctrl_o,
    output id_ex_reg_t id_reg_i
);

    logic [REG_ADDR_W-1:0] rs1_addr, rs2_addr, rd_addr;
    assign rs1_addr = reg_id_i.ins[19:15];
    assign rs2_addr = reg_id_i.ins[24:20];
    assign rd_addr  = reg_id_i.ins[11:7];

    logic [F3-1:0]      f3 ;
    assign f3 = reg_id_i.ins[14:12];

    logic f7_5;
    assign f7_5 = reg_id_i.ins[30];

    b_type_f3_e f3_br;
    assign f3_br = b_type_f3_e'(reg_id_i.ins[14:12]);

    //=========================================================
    // decode
    //=========================================================
    logic rs1_used, rs2_used, jump_en;
    decode_s deco;

    decode u_decode(
        .ins_i(reg_id_i.ins),
        .deco_o(deco),
        .rs1_used_o(rs1_used),
        .rs2_used_o(rs2_used),
        .jump_en_o(jump_en)
    );

     //=========================================================
    // regfile
    //=========================================================
    // logic [REG_ADDR_W-1:0] rs1_addr,rs2_addr;
    logic [XLEN-1:0]    rs1_data,rs2_data;

    regfile u_regfile(
        .clk(clk),
        .rst_n(rst_n),
        .rs1_addr_i(rs1_addr),
        .rs2_addr_i(rs2_addr),
        .wb_i(wb_i),
        .rs1_data_o(rs1_data),
        .rs2_data_o(rs2_data)
    );


    //=========================================================
    // immgen
    //=========================================================
    logic [XLEN-1:0] imm_out;
    immgen u_immgen(
        .ins_i(reg_id_i.ins),
        .imm_sel_i(deco.imm_sel),
        .imm_out_o(imm_out)
    );


    //=========================================================
    // hazard
    //=========================================================

    
    // logic be_en;
    
    // logic rs1_used, rs2_used;
    hzd_ctrl_t hzd_ctrl;
    hazzard u_hazzard(
        .rs1_addr_i(rs1_addr),
        .rs2_addr_i(rs2_addr),
        .rs1_used_i(rs1_used),
        .rs2_used_i(rs2_used),

        .jump_en_i(jump_en),
        .br_en_i(deco.br_en),
        .br_taken_i(br_taken),

        .for_info_ex_i(for_info_ex_i),
        .for_info_mem_i(for_info_mem_i),

        .hzd_ctrl_o(hzd_ctrl)
    );



    //=========================================================
    // forward_id
    //=========================================================
    logic [1:0] for_id_a,for_id_b;

    forward_id u_forward_id(
        .rs1_addr_i(rs1_addr),
        .rs2_addr_i(rs2_addr),
        .for_info_ex_i(for_info_ex_i),
        .for_info_mem_i(for_info_mem_i),
        .for_id_a_o(for_id_a),
        .for_id_b_o(for_id_b)
    );


    //=========================================================
    // mux_br_compare
    //=========================================================
    logic [XLEN-1:0] compare_a,compare_b;    

    mux_br_compare u_mux_br_compare(
        .rs1_data_i(rs1_data),
        .rs2_data_i(rs2_data),
        
        .alu_ex_i(alu_ex_i),
        .alu_mem_i(alu_mem_i),
        .for_id_a_i(for_id_a),
        .for_id_b_i(for_id_b),
        .compare_a_o(compare_a),
        .compare_b_o(compare_b)
    );


    //=========================================================
    // br_compare
    //=========================================================
        logic br_taken;
    br_compare u_br_compare(
        .compare_a_i(compare_a),
        .compare_b_i(compare_b),
        .f3_i(f3_br),
        .br_en_i(deco.br_en),
        .br_taken_o(br_taken)
    );



    //=========================================================
    // mux_base_jump_adder
    //=========================================================

    logic [XLEN-1:0] jump_a,jump_b;
    mux_base_jump_adder u_mux_base_jump_adder(
        .rs1_data_i(rs1_data),
        .pc_cur_i(reg_id_i.pc_cur),
        .imm_out_i(imm_out),
        .jalr_i(deco.jalr_en),
       
        .alu_ex_i(alu_ex_i),
        .alu_mem_i(alu_mem_i),
        .for_id_a_i(for_id_a),
        .jump_a_o(jump_a),
        .jump_b_o(jump_b)
    );



    //=========================================================
    // jump_adder
    //=========================================================
    logic [XLEN-1:0] jump_adder;

    jump_adder u_jump_adder(
        .jump_a_i(jump_a),
        .jump_b_i(jump_b),
        .jump_adder_o(jump_adder)
    );
    

    always_comb begin  : pack_jump
        jump_o.jal = deco.jal_en;
        jump_o.jalr = deco.jalr_en;
        jump_o.br_en = deco.br_en;
        jump_o.br_taken = br_taken;
        jump_o.jump_addr = jump_adder;
    end


    always_comb begin : pack_hzd
        hzd_ctrl_o = hzd_ctrl;
    end


    always_comb begin : pack_id_reg_i
        id_reg_i.f3 = f3;
        id_reg_i.f7_5 = f7_5;

        id_reg_i.pc_cur = reg_id_i.pc_cur;
        id_reg_i.pc_4 = reg_id_i.pc_4;

        id_reg_i.imm_out = imm_out;
        id_reg_i.rd_addr = rd_addr;
        id_reg_i.rs1_addr = rs1_addr;
        id_reg_i.rs2_addr = rs2_addr;
        id_reg_i.rs1_data = rs1_data;
        id_reg_i.rs2_data = rs2_data;

        id_reg_i.ex_ctrl = deco.ex_ctrl;
        id_reg_i.mem_ctrl = deco.mem_ctrl;
        id_reg_i.extension = deco.extension;
        id_reg_i.wb_ctrl  = deco.wb_ctrl;
    end


endmodule
