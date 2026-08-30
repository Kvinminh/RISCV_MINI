module ex_stage
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input  id_ex_reg_t reg_ex_i,
    input  for_info_t  for_info_mem_i,
    input  for_info_t  for_info_wb_i,
    input logic [XLEN-1:0] alu_mem_i,
    input logic [XLEN-1:0] alu_wb_i,

    output ex_mem_reg_t ex_reg_o
    // output for_info_t   for_info_ex_o,
    // output logic [XLEN-1:0] alu_ex_o
);

    logic [1:0] for_ex_a, for_ex_b;
    logic [XLEN-1:0] A, B;
    logic [XLEN-1:0] rs2_fwd;
    alu_ctrl_e alu_ctrl;

    //=========================================================
    // Forwarding
    //=========================================================
    forward_ex u_forward_ex(
        .rs1_addr_i     (reg_ex_i.rs1_addr),
        .rs2_addr_i     (reg_ex_i.rs2_addr),
        .for_info_mem_i (for_info_mem_i),
        .for_info_wb_i  (for_info_wb_i),
        .for_ex_a_o     (for_ex_a),
        .for_ex_b_o     (for_ex_b)
    );

    //=========================================================
    // ALU Control
    //=========================================================
    alu_ctrl u_alu_ctrl(
        .alu_op_i   (reg_ex_i.ex_ctrl.alu_op),
        .f3_i       (reg_ex_i.f3),
        .f7_5_i     (reg_ex_i.f7_5),
        .alu_ctrl_o (alu_ctrl)
    );

    //=========================================================
    // ALU MUX
    //=========================================================
    alu_mux u_alu_mux(
        .for_ex_a_i (for_ex_a),
        .for_ex_b_i (for_ex_b),
        .rs1_data_i (reg_ex_i.rs1_data),
        .rs2_data_i (reg_ex_i.rs2_data),
        .sel_a_i    (reg_ex_i.ex_ctrl.sel_a),
        .sel_b_i    (reg_ex_i.ex_ctrl.sel_b),
        .pc_cur_i   (reg_ex_i.pc_cur),
        .immgen_i   (reg_ex_i.imm_out),
        .alu_mem_i  (alu_mem_i),
        .alu_wb_i   (alu_wb_i),
        .A_o        (A),
        .B_o        (B)
    );

    //=========================================================
    // ALU
    //=========================================================
    logic [XLEN-1:0] alu_result;
    alu u_alu(
        .alu_ctrl_i   (alu_ctrl),
        .A            (A),
        .B            (B),
        .alu_result_o (alu_result)
    );

    //=========================================================
    // Store Data Forwarding
    //=========================================================
    always_comb begin
        unique case (for_ex_b)
            RD_MEM: rs2_fwd = alu_mem_i;
            RD_WB : rs2_fwd = alu_wb_i;
            RD_EX : rs2_fwd = reg_ex_i.rs2_data;
            default: rs2_fwd = reg_ex_i.rs2_data;
        endcase
    end

    //=========================================================
    // EX -> MEM
    //=========================================================
    always_comb begin
        ex_reg_o = '0;
        ex_reg_o.pc_4      = reg_ex_i.pc_4;
        ex_reg_o.alu       = alu_result;
        ex_reg_o.rs2_data  = rs2_fwd;
        ex_reg_o.rd_addr   = reg_ex_i.rd_addr;
        ex_reg_o.extension = reg_ex_i.extension;
        ex_reg_o.mem_ctrl  = reg_ex_i.mem_ctrl;
        ex_reg_o.wb_ctrl   = reg_ex_i.wb_ctrl;
        ex_reg_o.f3        = reg_ex_i.f3;
    end

    //=========================================================
    // EX -> Forwarding
    //=========================================================
    // always_comb begin
    //     for_info_ex_o = '0;
    //     for_info_ex_o.rd_addr = reg_ex_i.rd_addr;
    //     for_info_ex_o.reg_en  = reg_ex_i.wb_ctrl.reg_en;
    //     for_info_ex_o.mem_re  = reg_ex_i.mem_ctrl.dmem_re;
    // end

endmodule
