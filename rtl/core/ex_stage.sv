// module ex_stage
// import isa_pkg::*;
// import ctrl_pkg::*;
// import core_pkg::*;
// (
//     input  logic [2:0]            f3_ex,
//     input  logic                  f7_5_ex,
//     input  logic [XLEN-1:0]       pc4_ex,
//     input  logic [REG_ADDR_W-1:0] rd_addr_ex,
//     input  logic [REG_ADDR_W-1:0] rs1_addr_ex,
//     input  logic [REG_ADDR_W-1:0] rs2_addr_ex,
//     input  logic [XLEN-1:0]       rs1_data_ex,
//     input  logic [XLEN-1:0]       rs2_data_ex,
//     input  logic [XLEN-1:0]       pc_cur_ex,
//     input  logic [XLEN-1:0]       imm_ex,
//     input  ex_ctrl_s              ex_ctrl_ex,
//     input  mem_ctrl_s             mem_ctrl_ex,
//     input  wb_ctrl_s              wb_ctrl_ex,

//     input  logic [REG_ADDR_W-1:0] rd_mem_ex,
//     input  logic                  reg_en_mem_fwd,
//     input  logic [XLEN-1:0]       alu_mem_fwd,

//     input  logic [REG_ADDR_W-1:0] rd_wb_ex,
//     input  logic                  reg_en_wb_fwb,
//     input  logic [XLEN-1:0]       alu_wb_fwd,

//     output logic [XLEN-1:0]       pc4_mem,
//     output logic [XLEN-1:0]       alu_result_mem,
//     output logic [XLEN-1:0]       rs2_data_mem,
//     output logic [REG_ADDR_W-1:0] rd_addr_mem,
//     output logic                  extension_mem;
//     output mem_ctrl_s             mem_ctrl_mem,
//     output wb_ctrl_s              wb_ctrl_mem
// );

//     forward_e for_ex_a, for_ex_b;

//     forward_ex u_forward_ex (
//         .rs1_addr_ex (rs1_addr_ex),
//         .rs2_addr_ex (rs2_addr_ex),
//         .rd_mem_ex   (rd_mem_ex),
//         .reg_en_mem  (reg_en_mem),
//         .rd_wb_ex    (rd_wb_ex),
//         .reg_en_wb   (reg_en_wb),
//         .for_ex_a    (for_ex_a),
//         .for_ex_b    (for_ex_b)
//     );

//     logic [XLEN-1:0] alu_a, alu_b;

//     alu_mux u_alu_mux (
//         .forward_a (for_ex_a),
//         .forward_b (for_ex_b),
//         .sel_a     (ex_ctrl_ex.sel_a),
//         .sel_b     (ex_ctrl_ex.sel_b),
//         .rs1_data  (rs1_data_ex),
//         .rs2_data  (rs2_data_ex),
//         .immgen    (imm_ex),
//         .pc_cur    (pc_cur_ex),
//         .alu_mem   (alu_mem_fwd),
//         .alu_wb    (alu_wb_fwd),
//         .A         (alu_a),
//         .B         (alu_b)
//     );

//     alu_ctrl_e alu_ctrl_sel;

//     alu_ctrl u_alu_ctrl (
//         .alu_op     (ex_ctrl_ex.alu_op),
//         .f3         (f3_ex),
//         .f7_5       (f7_5_ex),
//         .alu_ctrl_o (alu_ctrl_sel)
//     );

//     alu u_alu (
//         .alu_ctrl      (alu_ctrl_sel),
//         .A             (alu_a),
//         .B             (alu_b),
//         .alu_result_ex (alu_result_mem)
//     );

//     // mux riêng cho store data (rs2 forward) — KHÔNG dùng chung với sel_b của ALU
//     logic [XLEN-1:0] rs2_fwd_store;

//     always_comb begin
//         unique case (for_ex_b)
//             RD_MEM_EX: rs2_fwd_store = alu_mem_fwd;
//             RD_WB_EX:  rs2_fwd_store = alu_wb_fwd;
//             RS_EX_EX:  rs2_fwd_store = rs2_data_ex;
//             default:   rs2_fwd_store = rs2_data_ex;
//         endcase
//     end

//     assign pc4_mem      = pc4_ex;
//     assign rs2_data_mem = rs2_fwd_store;
//     assign rd_addr_mem  = rd_addr_ex;
//     assign mem_ctrl_mem = mem_ctrl_ex;
//     assign wb_ctrl_mem  = wb_ctrl_ex;

// endmodule




module ex_stage
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input id_ex_reg_t reg_ex_i,
    input for_info_t  for_info_mem_i, // hazzard forwward
    input for_info_t  for_info_wb_i,// hazzard forwward
    input   logic [XLEN-1:0]        alu_mem_i,
    input   logic [XLEN-1:0]        alu_wb_i,

    output ex_mem_reg_t ex_reg_o
);


    //=========================================================
    // forward_ex
    //=========================================================

    
    logic [1:0]            for_ex_a,for_ex_b;

    forward_ex u_forward_ex(
        .rs1_addr_i(reg_ex_i.rs1_addr),
        .rs2_addr_i(reg_ex_i.rs2_addr),
        .for_info_mem_i(for_info_mem_i),
        .for_info_wb_i(for_info_wb_i),
        .for_ex_a_o(for_ex_a),
        .for_ex_b_o(for_ex_b)
    );


    //=========================================================
    // alu_ctrl
    //=========================================================
   
    logic [3:0] alu_ctrl;

    alu_ctrl u_alu_ctrl(
        .alu_op_i(reg_ex_i.ex_ctrl.alu_op),
        .f3_i(reg_ex_i.f3),
        .f7_5_i(reg_ex_i.f7_5),
        .alu_ctrl_o(alu_ctrl)
    );




    //=========================================================
    // alu_mux
    //=========================================================
    logic [XLEN-1:0] A, B;
    alu_mux u_alu_mux(
        .for_ex_a_i(for_ex_a),
        .for_ex_b_i(for_ex_b),
        .rs1_data_i(reg_ex_i.rs1_data),
        .rs2_data_i(reg_ex_i.rs2_data),
        .sel_a_i(reg_ex_i.ex_ctrl.sel_a),
        .sel_b_i(reg_ex_i.ex_ctrl.sel_b),
        .pc_cur_i(reg_ex_i.pc_cur),
        .immgen_i(reg_ex_i.imm_out),
        .alu_mem_i(alu_mem_i),
        .alu_wb_i(alu_wb_i),
        .A_o(A),
        .B_o(B)
    );

    //=========================================================
    // alu
    //=========================================================
     logic [XLEN-1:0] alu_result;

    alu u_alu(
        .alu_ctrl_i(alu_ctrl),
        .A(A),
        .B(B),
        .alu_result_o(alu_result)
    );


    always_comb begin : pack
        ex_reg_o.pc_4      = reg_ex_i.pc_4;
        ex_reg_o.alu       = alu_result;
        ex_reg_o.rs2_data  = reg_ex_i.rs2_data;
        ex_reg_o.rd_addr   = reg_ex_i.rd_addr;
        ex_reg_o.extension = reg_ex_i.extension;
        ex_reg_o.mem_ctrl  = reg_ex_i.mem_ctrl;
        ex_reg_o.wb_ctrl   = reg_ex_i.wb_ctrl;
        ex_reg_o.f3         = reg_ex_i.f3;
    end


endmodule
