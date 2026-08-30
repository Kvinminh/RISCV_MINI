
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
