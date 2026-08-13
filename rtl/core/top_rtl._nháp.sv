// module top
//   import isa_pkg::*;
//   import ctrl_pkg::*;
//   import core_pkg::*;
// (
//     input clk,
//     input rst_n
// );
//     // if_stage 
//     //input 
     
//       logic stall_pc;

//       logic              br_taken_id;
//       logic              br_en_id;
//       logic              jal_id;
//       logic              jalr_id;
//       logic [XLEN-1:0]   pc_jump_id;

//     // output
//      logic [XLEN-1:0]   pc_cur_if;
//      logic [XLEN-1:0]   pc4_if;
//      logic [XLEN-1:0]   ins_if;


//      if_stage      u_if_stage    (.*);





//      // if_id_pipeline
//      //input
//       logic stall_if_id;
//      if_id_reg_t if_i;

//      // output
//     output if_id_reg_t id_o;

//     if_id_reg u_if_id_reg(.*);




//     // id_stage 
//     //input 
//      // ---- từ if_id_reg ----
//       logic [XLEN-1:0] pc_cur_id;
//       logic [XLEN-1:0] pc4_id;
//       logic [XLEN-1:0] ins_id;

//     // ---- writeback từ WB stage ----
//       logic                  reg_en_wb;
//       logic [REG_ADDR_W-1:0] rd_addr_wb;
//       logic [XLEN-1:0]       rd_data_wb;

//     // ---- forward từ EX stage ----
//       logic [REG_ADDR_W-1:0] rd_ex;
//       logic                  reg_en_ex;
//       logic                  mem_re_ex;
//       logic [XLEN-1:0]       alu_result_ex;

//     // ---- forward từ MEM stage ----
//       logic [REG_ADDR_W-1:0] rd_mem;
//       logic                  reg_en_mem;
//       logic                  mem_re_mem;
//       logic [XLEN-1:0]       wb_data_mem;

//     // ---- output ngược ra IF stage (qua pc_mux) ----
//      logic              br_taken_id;
//      logic              jal_id;
//      logic              jalr_id;
//      logic [XLEN-1:0]   pc_jump_id;



//     // ---- output control cho PC / if_id_reg / id_ex_reg ----
//      logic stall_pc;
//      logic stall_if_id;
//      logic flush_if_id;
//      logic flush_id_ex;

//     // ---- output đi vào id_ex_reg ----
//      logic [2:0]            f3_id;
//      logic                  f7_5_id;
//      logic [XLEN-1:0]       pc_cur_ex;
//      logic [XLEN-1:0]       pc4_ex;
//      logic [XLEN-1:0]       imm_ex;
//      logic [REG_ADDR_W-1:0] rd_addr_ex;
//      logic [REG_ADDR_W-1:0] rs1_addr_ex;
//      logic [REG_ADDR_W-1:0] rs2_addr_ex;
//      logic [XLEN-1:0]       rs1_data_ex;
//      logic [XLEN-1:0]       rs2_data_ex;
//      ex_ctrl_s              ex_ctrl_id;
//      mem_ctrl_s             mem_ctrl_id;
//      logic                  extension_id;
//      wb_ctrl_s              wb_ctrl_id;


//     id_stage   u_id_stage  (.*);





 



// /// id_ex_pipeline 
// //input 
 
//      logic             id_ex_flush;
//      id_ex_reg_t       id;



// //output 
//      id_ex_reg_t      ex;

//      id_ex_reg u_id_ex_reg (.*);



// // ex_stage
// // input
//       logic [2:0]            f3_ex;
//       logic                  f7_5_ex;
//       logic [XLEN-1:0]       pc4_ex;
//       logic [REG_ADDR_W-1:0] rd_addr_ex;
//       logic [REG_ADDR_W-1:0] rs1_addr_ex;
//       logic [REG_ADDR_W-1:0] rs2_addr_ex;
//       logic [XLEN-1:0]       rs1_data_ex;
//       logic [XLEN-1:0]       rs2_data_ex;
//       logic [XLEN-1:0]       pc_cur_ex;
//       logic [XLEN-1:0]       imm_ex;
//       ex_ctrl_s              ex_ctrl_ex;
//       mem_ctrl_s             mem_ctrl_ex;
//       wb_ctrl_s              wb_ctrl_ex;

//       logic [REG_ADDR_W-1:0] rd_mem_ex;
//       logic                  reg_en_mem;
//       logic [XLEN-1:0]       alu_mem_fwd;

//       logic [REG_ADDR_W-1:0] rd_wb_ex;
//       logic                  reg_en_wb;
//       logic [XLEN-1:0]       alu_wb_fwd;



//     // output

//      logic [XLEN-1:0]       pc4_mem;
//      logic [XLEN-1:0]       alu_result_mem;
//      logic [XLEN-1:0]       rs2_data_mem;
//      logic [REG_ADDR_W-1:0] rd_addr_mem;
//      mem_ctrl_s             mem_ctrl_mem;
//      wb_ctrl_s              wb_ctrl_mem;

//     ex_stage u_ex_stage (.*);




//     // exx_mem_pipeline 
//     // input 
     
//      ex_mem_reg_t       ex;
//      // output
//      ex_mem_reg_t      mem;

//     ex_mem_reg u_ex_mem_reg (.*);








//     // mem_stage 
//     // input 
//       ex_mem_reg_t  ex_mem_reg_i;

//       i_type_load_f3_e f3_mem_i;
//       logic             extension_mem_i;


//     // output

//      mem_wb_reg_t  mem_wb_reg_o;


//      mem_stage u_mem_stage(.*);







//     // mem_wb_pipeline
//     //input 
    
//      mem_wb_reg_t mem;
//      //output
//      mem_wb_reg_t wb;

     
//     mem_wb_reg u_mem_wb_reg (.*);



//     // wb_stage
//     // input 
    



// endmodule















module top
  import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input clk,
    input rst_n
);

    //=========================================================
    // IF stage
    //=========================================================
    logic stall_pc;
    logic br_taken_id, br_en_id, jal_id, jalr_id;
    logic [XLEN-1:0] pc_jump_id;

    logic [XLEN-1:0] pc_cur_if, pc4_if, ins_if;

    if_stage u_if_stage (.*);

    // pack -> if_id_reg
    if_id_reg_t if_i;
    always_comb begin
        if_i.pc_cur = pc_cur_if;
        if_i.pc_4   = pc4_if;
        if_i.ins    = ins_if;
    end

    //=========================================================
    // IF/ID pipeline reg
    //=========================================================
    logic stall_if_id, flush_if_id;
    if_id_reg_t id_o;

    if_id_reg u_if_id_reg (.*);

    //=========================================================
    // ID stage
    //=========================================================
    // unpack id_o -> input rời cho id_stage
    logic [XLEN-1:0] pc_cur_id, pc4_id, ins_id;
    assign pc_cur_id = id_o.pc_cur;
    assign pc4_id    = id_o.pc_4;
    assign ins_id     = id_o.ins;

    // writeback / forward inputs (giữ nguyên, đến từ WB/EX/MEM)
    logic                  reg_en_wb;
    logic [REG_ADDR_W-1:0] rd_addr_wb;
    logic [XLEN-1:0]       rd_data_wb;

    logic [REG_ADDR_W-1:0] rd_ex;
    logic                  reg_en_ex;
    logic                  mem_re_ex;
    logic [XLEN-1:0]       alu_result_ex;

    logic [REG_ADDR_W-1:0] rd_mem;
    logic                  reg_en_mem;
    logic                  mem_re_mem;
    logic [XLEN-1:0]       wb_data_mem;

    // output rời của id_stage
    logic              jal_id_o;      // đổi tên tránh trùng input trên
    logic              jalr_id_o;
    logic [XLEN-1:0]   pc_jump_id_o;
    logic              br_taken_id_o;

    logic stall_id_ex, flush_id_ex;   // control

    logic [2:0]            f3_id;
    logic                  f7_5_id;
    logic [XLEN-1:0]       pc_cur_ex_id;
    logic [XLEN-1:0]       pc4_ex_id;
    logic [XLEN-1:0]       imm_ex_id;
    logic [REG_ADDR_W-1:0] rd_addr_ex_id;
    logic [REG_ADDR_W-1:0] rs1_addr_ex_id;
    logic [REG_ADDR_W-1:0] rs2_addr_ex_id;
    logic [XLEN-1:0]       rs1_data_ex_id;
    logic [XLEN-1:0]       rs2_data_ex_id;
    ex_ctrl_s              ex_ctrl_id_id;
    mem_ctrl_s             mem_ctrl_id;
    logic                  extension_id;
    wb_ctrl_s              wb_ctrl_id;

    id_stage u_id_stage (.*);

    // pack -> id_ex_reg
    id_ex_reg_t id_i;
    always_comb begin
        id_i.f3        = f3_id;
        id_i.f7_5      = f7_5_id;
        id_i.pc_cur    = pc_cur_ex;
        id_i.pc_4      = pc4_ex;
        id_i.imm       = imm_ex;
        id_i.rd_addr   = rd_addr_ex;
        id_i.rs1_addr  = rs1_addr_ex;
        id_i.rs2_addr  = rs2_addr_ex;
        id_i.rs1_data  = rs1_data_ex;
        id_i.rs2_data  = rs2_data_ex;
        id_i.ex_ctrl   = ex_ctrl_id;
        id_i.mem_ctrl  = mem_ctrl_id;
        id_i.extension = extension_id;
        id_i.wb_ctrl   = wb_ctrl_id;
    end

    //=========================================================
    // ID/EX pipeline reg
    //=========================================================
    id_ex_reg_t ex_o;
    id_ex_reg u_id_ex_reg (.*);

    //=========================================================
    // EX stage
    //=========================================================
    // unpack ex_o -> input rời cho ex_stage
    logic [2:0]            f3_ex;
    logic                  f7_5_ex;
    // logic [XLEN-1:0]       pc_cur_ex;
    // logic [XLEN-1:0]       pc4_ex;
    logic [XLEN-1:0]       imm_ex;
    logic [REG_ADDR_W-1:0] rd_addr_ex;
    logic [REG_ADDR_W-1:0] rs1_addr_ex;
    logic [REG_ADDR_W-1:0] rs2_addr_ex;
    logic [XLEN-1:0]       rs1_data_ex;
    logic [XLEN-1:0]       rs2_data_ex;
    ex_ctrl_s               ex_ctrl_ex;
    mem_ctrl_s              mem_ctrl_ex;
    wb_ctrl_s               wb_ctrl_ex;

    always_comb begin
        f3_ex          = ex_o.f3;
        f7_5_ex        = ex_o.f7_5;
        pc_cur_ex_i    = ex_o.pc_cur;
        pc4_ex_i       = ex_o.pc_4;
        imm_ex_i       = ex_o.imm;
        rd_addr_ex_i   = ex_o.rd_addr;
        rs1_addr_ex_i  = ex_o.rs1_addr;
        rs2_addr_ex_i  = ex_o.rs2_addr;
        rs1_data_ex_i  = ex_o.rs1_data;
        rs2_data_ex_i  = ex_o.rs2_data;
        ex_ctrl_ex     = ex_o.ex_ctrl;
        mem_ctrl_ex    = ex_o.mem_ctrl;
        wb_ctrl_ex     = ex_o.wb_ctrl;
    end

    // forwarding path input (mem/wb fwd) — giữ nguyên
    logic [REG_ADDR_W-1:0] rd_mem_ex;
    logic                  reg_en_mem_fwd;
    logic [XLEN-1:0]       alu_mem_fwd;
    logic [REG_ADDR_W-1:0] rd_wb_ex;
    logic                  reg_en_wb_fwd;
    logic [XLEN-1:0]       alu_wb_fwd;

    // output rời của ex_stage
    logic [XLEN-1:0]       pc4_mem;
    logic [XLEN-1:0]       alu_result_mem;
    logic [XLEN-1:0]       rs2_data_mem;
    logic [REG_ADDR_W-1:0] rd_addr_mem;
    logic                  extension_mem;
    mem_ctrl_s              mem_ctrl_mem;
    wb_ctrl_s               wb_ctrl_mem;

    ex_stage u_ex_stage (.*);

    // pack -> ex_mem_reg
    ex_mem_reg_t ex_i;
    always_comb begin
        ex_i.pc_4       = pc4_mem;
        ex_i.alu_result = alu_result_mem;
        ex_i.rs2_data   = rs2_data_mem;
        ex_i.rd_addr    = rd_addr_mem;
        ex_i.extension  = extension_mem;
        ex_i.mem_ctrl   = mem_ctrl_mem;
        ex_i.wb_ctrl    = wb_ctrl_mem;
    end

    //=========================================================
    // EX/MEM pipeline reg
    //=========================================================
    ex_mem_reg_t mem_o;
    ex_mem_reg u_ex_mem_reg (.*);

    //=========================================================
    // MEM stage
    //=========================================================
    ex_mem_reg_t ex_mem_reg_i;
    assign ex_mem_reg_i = mem_o;

    i_type_load_f3_e f3_mem_i;
    logic             extension_mem_i;

    mem_wb_reg_t mem_wb_reg_o;

    mem_stage u_mem_stage (.*);

    //=========================================================
    // MEM/WB pipeline reg
    //=========================================================
    mem_wb_reg_t mem_i;
    assign mem_i = mem_wb_reg_o;

    mem_wb_reg_t wb;
    mem_wb_reg u_mem_wb_reg (.*);

    //=========================================================
    // WB stage
    //=========================================================
    // TODO: chưa có wb_stage — cần instantiate ở đây
    // wb_stage u_wb_stage (.*);

      mem_wb_reg_t wb;   // output của mem_wb_reg, cũng chính là input của wb_stage — tên trùng, .* tự nối

      wb_stage u_wb_stage (.*);


endmodule