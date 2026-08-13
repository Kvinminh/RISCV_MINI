// module top
//   import isa_pkg::*;
//   import ctrl_pkg::*;
//   import core_pkg::*;
// (
//     input clk,
//     input rst_n
// );




// //=========================================================
// // IF stage
// //=========================================================
//     hzd_ctrl_t hzd_ctrl;
//     jump_t     jump_id_if;
//     if_id_reg_t if_reg ;

//     if_stage u_if_stage (
//         .clk(clk),
//         .rst_n(rst_n),
//         .hzd_i(hzd),
//         .jump_id_i(jump_id_if),
//         .if_o(if_reg)
//     );

// //=========================================================
// // IF/ID pipeline reg
// //=========================================================
//     //if_id_reg_t if;
    
//     //hzd_ctrl_t hzd;
//     if_id_reg_t reg_id;

//     if_id_reg u_if_id_reg (
//         .clk(clk),
//         .rst_n(rst_n),
//         .hzd_i(hzd),
//         .if_i(if_reg),
//         .id_o(reg_id)
//     );


// //=========================================================
// // ID stage
// //=========================================================
// // unpack id_o -> input rời cho id_stage

// regfile_wb regfile_wb_id; // data để regfile
// for_info_t  ex_id; // forward ex
// for_info_t  mem2id_ex; // forward id 

// id_ex_reg_t id_reg;

//     id_stage u_id_stage(
//         .clk(clk),
//         .rst_n(rst_n),
        
//         .id_i(reg_id),
//         .wb_i(regfile_wb_id),
//         .ex_i(ex_id),
//         .mem_i(mem2id_ex),

//         .jump_o(jump_id_if),
//         .hzd_ctrl_o(hzd_ctrl),
//         .id_o(id_reg)
//     );





//     //=========================================================
//     // id_ex_reg
//     //=========================================================

//     id_ex_reg_t reg_ex;
//     id_ex_reg u_id_ex_reg(
//         .clk(clk),
//         .rst_n(rst_n),
//         .id_ex_flush(hzd_ctrl),
//         .id_i(id_reg),
//         .ex_o(reg_ex)
//     );



//     //=========================================================
//     // ex_stage
//     //=========================================================

//     for_info_t mem_ex; // dataa forwar từ mem
//     for_info_t wb_ex; // dataa forwar từ wb
//     ex_mem_reg_t ex_reg;


//     ex_stage u_ex_stage(
//         .ex_i(reg_ex),
//         .mem_i(mem2id_ex),
//         .wb_i(wb_ex),
//         .ex_o(ex_reg)
//     );


//     //=========================================================
//     // ex_mem_reg
//     //=========================================================

//     ex_mem_reg_t reg_mem;

//     ex_mem_reg u_ex_mem_reg(
//         .clk(clk),
//         .rst_n(rst_n),
//         .reg_i(ex_reg),
//         .reg_o(reg_mem)
//     );



//     //=========================================================
//     // mem_stage
//     //=========================================================
//     ex_mem_reg_t mem_reg;
//     mem_stage u_mem_stage(
//         .clk(clk),
//         .mem_i(reg_mem),
//         .mem_o(mem_reg),
//         .for_mem_o(mem2id_ex)
//     );

//     //=========================================================
//     // mem_wb_reg
//     //=========================================================
//     mem_wb_reg_t reg_wb;

//     mem_wb_reg u_mem_wb_reg(
//         .clk(clk),
//         .rst_n(rst_n),
//         .reg_i(mem_reg),
//         .reg_o(reg_wb)
//     );

//     //=========================================================
//     // wb_stage
//     //=========================================================
     
//      wb_stage u_wb_stage(
//         .wb_i(reg_wb),
//         .wb_o(regfile_wb_id)
//      );





// endmodule


module top
  import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input logic clk,
    input logic rst_n
);

//=========================================================
// IF stage
//=========================================================
    logic       stall_pc;
    jump_t      jump_id_if;
    if_id_reg_t if_reg;

    if_stage u_if_stage (
        .clk        (clk),
        .rst_n      (rst_n),
        .stall_pc_i (stall_pc),
        .jump_id_i  (jump_id_if),
        .if_reg_o   (if_reg)
    );

//=========================================================
// IF/ID pipeline reg
//=========================================================
    hzd_ctrl_t  hzd_ctrl;
    if_id_reg_t reg_id;

    if_reg_id_reg u_if_id_reg (
        .clk      (clk),
        .rst_n    (rst_n),
        .flush_if_id_i (hzd_ctrl.flush_if_id),
        .stall_if_id_i (hzd_ctrl.stall_if_id),
        .if_reg_i (if_reg),
        .id_reg_o (reg_id)
    );

    assign stall_pc = hzd_ctrl.stall_pc;

//=========================================================
// ID stage
//=========================================================
    regfile_wb regfile_wb_id;  // bypass ghi + forward từ wb
    for_info_t ex_id;          // forward info: instr đang ở EX
    for_info_t mem2id_ex;      // forward info: instr đang ở MEM (dùng chung cho id & ex)
    logic [XLEN-1:0] alu_ex_val;
    logic [XLEN-1:0] alu_mem_val;

    id_ex_reg_t id_reg;

    id_stage u_id_stage (
        .clk            (clk),
        .rst_n          (rst_n),
        .reg_id_i       (reg_id),
        .wb_i           (regfile_wb_id),
        .for_info_ex_i  (ex_id),
        .for_info_mem_i (mem2id_ex),
        .alu_ex_i       (alu_ex_val),
        .alu_mem_i      (alu_mem_val),
        .jump_o         (jump_id_if),
        .hzd_ctrl_o     (hzd_ctrl),
        .id_reg_i       (id_reg)
    );

//=========================================================
// id_ex_reg
//=========================================================
    id_ex_reg_t reg_ex;

    id_ex_reg u_id_ex_reg (
        .clk         (clk),
        .rst_n       (rst_n),
        .id_ex_flush (hzd_ctrl.flush_id_ex),
        .id_reg_i    (id_reg),
        .ex_reg_o    (reg_ex)
    );

    // instr đang thực sự ở EX = reg_ex (đã latch), không phải id_reg
    assign ex_id.rd_addr = reg_ex.rd_addr;
    assign ex_id.mem_re  = reg_ex.mem_ctrl.dmem_re;
    assign ex_id.reg_en  = reg_ex.wb_ctrl.reg_en;

//=========================================================
// ex_stage
//=========================================================
    for_info_t   wb_ex;        // forward info từ WB
    logic [XLEN-1:0] alu_wb_val;
    ex_mem_reg_t ex_reg;

    ex_stage u_ex_stage (
        .reg_ex_i       (reg_ex),
        .for_info_mem_i (mem2id_ex),
        .for_info_wb_i  (wb_ex),
        .alu_mem_i      (alu_mem_val),
        .alu_wb_i       (alu_wb_val),
        .ex_reg_o       (ex_reg)
    );

    assign alu_ex_val = ex_reg.alu;

//=========================================================
// ex_mem_reg
//=========================================================
    ex_mem_reg_t reg_mem;

    ex_mem_reg u_ex_mem_reg (
        .clk   (clk),
        .rst_n (rst_n),
        .reg_i (ex_reg),
        .reg_o (reg_mem)
    );

//=========================================================
// mem_stage
//=========================================================
    mem_wb_reg_t mem_reg;  // FIX: phải là mem_wb_reg_t, không phải ex_mem_reg_t

    mem_stage u_mem_stage (
        .clk           (clk),
        .reg_mem_i     (reg_mem),
        .mem_reg_o     (mem_reg),
        .for_mem_reg_o (mem2id_ex)
    );

    assign alu_mem_val = mem_reg.alu_result;

//=========================================================
// mem_wb_reg
//=========================================================
    mem_wb_reg_t reg_wb;

    mem_wb_reg u_mem_wb_reg (
        .clk   (clk),
        .rst_n (rst_n),
        .reg_i (mem_reg),
        .reg_o (reg_wb)
    );

//=========================================================
// wb_stage
//=========================================================
    wb_stage u_wb_stage (
        .wb_i (reg_wb),
        .wb_o (regfile_wb_id)
    );

    // forward EX <- WB
    assign wb_ex.rd_addr = regfile_wb_id.rd_addr;
    assign wb_ex.reg_en  = regfile_wb_id.reg_en;
    assign wb_ex.mem_re  = 1'b0;
    assign alu_wb_val     = regfile_wb_id.rd_data;

endmodule
