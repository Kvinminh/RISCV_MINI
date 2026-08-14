// 7 file cần test 

// 1. decode

// 2. forward_id

// 3. immgen

// 4. mux_compare

// 5. br_compare

// 6. mux_base_jump_adder

// 7. jump_addr


module id_stage_7
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
    // output hzd_ctrl_t hzd_ctrl_o,
    output id_ex_reg_t id_reg_o
);
    logic [REG_ADDR_W-1:0] rs1_addr, rs2_addr, rd_addr;
    assign rs1_addr = reg_id_i.ins[19:15];
    assign rs2_addr = reg_id_i.ins[24:20];
    assign rd_addr  = reg_id_i.ins[11:7];

    logic [F3-1:0]      f3 ;
    assign f3 = reg_id_i.ins[14:12];

    logic f7_5;
    assign f7_5 = reg_id_i.ins[30];


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
    // hzd_ctrl_t hzd_ctrl;
    // hazzard u_hazzard(
    //     .rs1_addr_i(rs1_addr),
    //     .rs2_addr_i(rs2_addr),
    //     .rs1_used_i(rs1_used),
    //     .rs2_used_i(rs2_used),

    //     .jump_en_i(jump_en),
    //     .br_en_i(deco.br_en),
    //     .br_taken_i(br_taken),

    //     .for_info_ex_i(for_info_ex_i),
    //     .for_info_mem_i(for_info_mem_i),

    //     .hzd_ctrl_o(hzd_ctrl)
    // );



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
        .f3_i(f3),
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


    // always_comb begin : pack_hzd
    //     hzd_ctrl_o = hzd_ctrl;
    // end


    always_comb begin : pack_id_reg_i
        id_reg_o.f3 = f3;
        id_reg_o.f7_5 = f7_5;

        id_reg_o.pc_cur = reg_id_i.pc_cur;
        id_reg_o.pc_4 = reg_id_i.pc_4;

        id_reg_o.imm_out = imm_out;
        id_reg_o.rd_addr = rd_addr;
        id_reg_o.rs1_addr = rs1_addr;
        id_reg_o.rs2_addr = rs2_addr;
        id_reg_o.rs1_data = rs1_data;
        id_reg_o.rs2_data = rs2_data;

        id_reg_o.ex_ctrl = deco.ex_ctrl;
        id_reg_o.mem_ctrl = deco.mem_ctrl;
        id_reg_o.extension = deco.extension;
        id_reg_o.wb_ctrl  = deco.wb_ctrl;
    end


endmodule




// =====================================================================
// Directed test vectors - RV32I core instruction set (37 lệnh)
// =====================================================================
// R-type (10)
  localparam logic [31:0] ADD = 32'b00000000001000001000000110110011; // add  x3, x1, x2
  localparam logic [31:0] SUB = 32'b01000000011000101000001110110011; // sub  x7, x5, x6
  localparam logic [31:0] SLL = 32'b00000000101001001001010110110011; // sll  x11, x9, x10
  localparam logic [31:0] SLT = 32'b00000000111001101010011110110011; // slt  x15, x13, x14
  localparam logic [31:0] SLTU = 32'b00000001001010001011100110110011; // sltu x19, x17, x18
  localparam logic [31:0] XOR = 32'b00000001011010101100101110110011; // xor  x23, x21, x22
  localparam logic [31:0] SRL = 32'b00000001101011001101110110110011; // srl  x27, x25, x26
  localparam logic [31:0] SRA = 32'b01000001111011101101111110110011; // sra  x31, x29, x30
  localparam logic [31:0] OR = 32'b00000000010000011110010000110011; // or   x8,  x3, x4
  localparam logic [31:0] AND = 32'b00000000110001011111100000110011; // and  x16, x11, x12

  // I-type ALU (9)
  localparam logic [31:0] ADDI = 32'b00000110010000001000000100010011; // addi  x2, x1, 100
  localparam logic [31:0] SLTI = 32'b11111111101100100010001010010011; // slti  x5, x4, -5
  localparam logic [31:0] SLTIU = 32'b00001100100000110011001110010011; // sltiu x7, x6, 200
  localparam logic [31:0] XORI = 32'b00000000111101000100010010010011; // xori  x9, x8, 0x0F
  localparam logic [31:0] ORI = 32'b00001111000001010110010110010011; // ori   x11, x10, 0xF0
  localparam logic [31:0] ANDI = 32'b00001010101001100111011010010011; // andi  x13, x12, 0xAA
  localparam logic [31:0] SLLI = 32'b00000000010101110001011110010011; // slli  x15, x14, 5
  localparam logic [31:0] SRLI = 32'b00000000001110000101100010010011; // srli  x17, x16, 3
  localparam logic [31:0] SRAI = 32'b01000000011110010101100110010011; // srai  x19, x18, 7

  // Load (5)
  localparam logic [31:0] LB = 32'b00000000010000001000000100000011; // lb  x2, 4(x1)
  localparam logic [31:0] LH = 32'b00000000100000011001001000000011; // lh  x4, 8(x3)
  localparam logic [31:0] LW = 32'b11111111010000101010001100000011; // lw  x6, -12(x5)
  localparam logic [31:0] LBU = 32'b00000001000000111100010000000011; // lbu x8, 16(x7)
  localparam logic [31:0] LHU = 32'b00000001010001001101010100000011; // lhu x10, 20(x9)

  // Store (3)
  localparam logic [31:0] SB = 32'b00000000001000001000001000100011; // sb x2, 4(x1)
  localparam logic [31:0] SH = 32'b11111110010000011001110000100011; // sh x4, -8(x3)
  localparam logic [31:0] SW = 32'b00000000011000101010011000100011; // sw x6, 12(x5)

  // Branch (6)
  localparam logic [31:0] BEQ = 32'b00000000001000001000010001100011; // beq  x1, x2, +8
  localparam logic [31:0] BNE = 32'b00000000010000011001100001100011; // bne  x3, x4, +16
  localparam logic [31:0] BLT = 32'b11111110011000101100111011100011; // blt  x5, x6, -4
  localparam logic [31:0] BGE = 32'b00000000100000111101101001100011; // bge  x7, x8, +20
  localparam logic [31:0] BLTU = 32'b00000000101001001110110001100011; // bltu x9, x10, +24
  localparam logic [31:0] BGEU = 32'b11111110110001011111100011100011; // bgeu x11, x12, -16

  // Jump (2)
  localparam logic [31:0] JAL = 32'b00000010000000000000001011101111; // jal  x5, +32
  localparam logic [31:0] JALR = 32'b00000001000000011000001001100111; // jalr x4, 16(x3)

  // Upper immediate (2)
  localparam logic [31:0] LUI = 32'b00010010001101000101001010110111; // lui   x5, 0x12345
  localparam logic [31:0] AUIPC = 32'b10101011110011011110001100010111; // auipc x6, 0xABCDE



module tb_id_stage_7
import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;
();


initial begin
    $dumpfile("wave.vcd");   // hoặc dùng $dumpfile("wave.fst") nếu dùng --trace-fst
    $dumpvars(0, tb_id_7_stage);
end


logic clk;
logic rst_n;

if_id_reg_t reg_id_i;
regfile_wb wb_i;
for_info_t for_info_ex_i;
for_info_t for_info_mem_i;

logic [XLEN-1:0] alu_ex_i;
logic [XLEN-1:0] alu_mem_i;

jump_t     jump_o;
id_ex_reg_t id_reg_o;


id_stage_7 u_id_stage_7 (.*);


function automatic void ref_model_decode(
    input  logic [31:0] instr,
    output decode_s      deco_exp,
    output logic         rs1_used_exp,
    output logic         rs2_used_exp,
    output logic         jump_en_exp
);
    logic [6:0] opc;
    logic [2:0] f3;
    opc = instr[6:0];
    f3  = instr[14:12];

    // default an toàn (NOP-safe) — đây là behavior spec, không phải RTL detail
    deco_exp                 = '0;
    deco_exp.imm_sel         = IMMGEN_I;
    deco_exp.ex_ctrl.alu_op  = ALU_ADD_SUB;
    deco_exp.ex_ctrl.sel_a   = RS1_EX;
    deco_exp.ex_ctrl.sel_b   = RS2_EX;
    deco_exp.wb_ctrl.sel_wb  = ALU_MEM;
    rs1_used_exp = 1'b0;
    rs2_used_exp = 1'b0;

    unique case (opc)
        // R-type: rd = rs1 op rs2
        OPCODE_OP: begin
            deco_exp.ex_ctrl.sel_a  = RS1_EX;
            deco_exp.ex_ctrl.sel_b  = RS2_EX;
            deco_exp.ex_ctrl.alu_op = ALU_RTYPE;
            deco_exp.wb_ctrl.reg_en = 1'b1;
            deco_exp.wb_ctrl.sel_wb = ALU_MEM;
            rs1_used_exp = 1'b1;
            rs2_used_exp = 1'b1;
        end

        // I-type ALU: rd = rs1 op imm
        OPCODE_OP_IMM: begin
            deco_exp.imm_sel        = IMMGEN_I;
            deco_exp.ex_ctrl.sel_a  = RS1_EX;
            deco_exp.ex_ctrl.sel_b  = IMM_EX;
            deco_exp.ex_ctrl.alu_op = ALU_ITYPE;
            deco_exp.wb_ctrl.reg_en = 1'b1;
            deco_exp.wb_ctrl.sel_wb = ALU_MEM;
            rs1_used_exp = 1'b1;
        end

        // Load: addr = rs1 + imm, dấu mở rộng phụ thuộc f3
        OPCODE_LOAD: begin
            deco_exp.imm_sel          = IMMGEN_I;
            deco_exp.ex_ctrl.sel_a    = RS1_EX;
            deco_exp.ex_ctrl.sel_b    = IMM_EX;
            deco_exp.ex_ctrl.alu_op   = ALU_ADD_SUB;
            deco_exp.mem_ctrl.dmem_re = 1'b1;
            deco_exp.wb_ctrl.reg_en   = 1'b1;
            deco_exp.wb_ctrl.sel_wb   = MEM_RDATA;
            rs1_used_exp = 1'b1;
            // lb/lh/lw (f3=000/001/010) -> sign-extend = 1
            // lbu/lhu   (f3=100/101)    -> sign-extend = 0
            deco_exp.extension = (f3 == 3'b000) || (f3 == 3'b001) || (f3 == 3'b010);
        end

        // Store: addr = rs1 + imm
        OPCODE_STORE: begin
            deco_exp.imm_sel           = IMMGEN_S;
            deco_exp.ex_ctrl.sel_a     = RS1_EX;
            deco_exp.ex_ctrl.sel_b     = IMM_EX;
            deco_exp.ex_ctrl.alu_op    = ALU_ADD_SUB;
            deco_exp.mem_ctrl.dmem_wri = 1'b1;
            rs1_used_exp = 1'b1;
            rs2_used_exp = 1'b1;
        end

        // Branch
        OPCODE_BRANCH: begin
            deco_exp.imm_sel        = IMMGEN_B;
            deco_exp.ex_ctrl.sel_a  = RS1_EX;
            deco_exp.ex_ctrl.sel_b  = RS2_EX;
            deco_exp.ex_ctrl.alu_op = ALU_ADD_SUB;
            deco_exp.br_en          = 1'b1;
            rs1_used_exp = 1'b1;
            rs2_used_exp = 1'b1;
        end

        // JAL: rd = pc+4, target = pc+imm
        OPCODE_JAL: begin
            deco_exp.imm_sel        = IMMGEN_J;
            deco_exp.jal_en         = 1'b1;
            deco_exp.ex_ctrl.sel_a  = PC_CUR_EX;
            deco_exp.ex_ctrl.sel_b  = IMM_EX;
            deco_exp.ex_ctrl.alu_op = ALU_ADD_SUB;
            deco_exp.wb_ctrl.reg_en = 1'b1;
            deco_exp.wb_ctrl.sel_wb = PC4_MEM;
        end

        // JALR: rd = pc+4, target = rs1+imm
        OPCODE_JALR: begin
            deco_exp.imm_sel        = IMMGEN_I;
            deco_exp.ex_ctrl.sel_a  = RS1_EX;
            deco_exp.ex_ctrl.sel_b  = IMM_EX;
            deco_exp.ex_ctrl.alu_op = ALU_ADD_SUB;
            deco_exp.jalr_en        = 1'b1;
            deco_exp.wb_ctrl.reg_en = 1'b1;
            deco_exp.wb_ctrl.sel_wb = PC4_MEM;
            rs1_used_exp = 1'b1;
        end

        // LUI: rd = imm << 12
        OPCODE_LUI: begin
            deco_exp.imm_sel        = IMMGEN_U;
            deco_exp.ex_ctrl.sel_a  = ZERO_EX;
            deco_exp.ex_ctrl.sel_b  = IMM_EX;
            deco_exp.ex_ctrl.alu_op = ALU_ADD_SUB;
            deco_exp.wb_ctrl.reg_en = 1'b1;
            deco_exp.wb_ctrl.sel_wb = ALU_MEM;
        end

        // AUIPC: rd = pc + (imm << 12)
        OPCODE_AUIPC: begin
            deco_exp.imm_sel        = IMMGEN_U;
            deco_exp.ex_ctrl.sel_a  = PC_CUR_EX;
            deco_exp.ex_ctrl.sel_b  = IMM_EX;
            deco_exp.ex_ctrl.alu_op = ALU_ADD_SUB;
            deco_exp.wb_ctrl.reg_en = 1'b1;
            deco_exp.wb_ctrl.sel_wb = ALU_MEM;
        end

        default: ; // giữ default NOP-safe
    endcase

    jump_en_exp = deco_exp.jal_en || deco_exp.jalr_en;
endfunction


function automatic void ref_model_for_2mux (
 // forward_id
    input logic [REG_ADDR_W-1:0]   rs1_addr_i,  // random dc
    input logic [REG_ADDR_W-1:0]   rs2_addr_i, // random dc
    input for_info_t               for_info_ex_i, 
    input for_info_t               for_info_mem_i,

    // output for_sel_e               for_id_a_o,
    // output for_sel_e               for_id_b_o

    //mux_base
    input  logic [XLEN-1:0] rs1_data_i,   // raw từ regfile // random dc
    input  logic [XLEN-1:0] pc_cur_i,  // random dc
    input  logic [XLEN-1:0] imm_out_i, // random dc

    input  logic            jalr_i,   //random
    input   logic [XLEN-1:0]        alu_ex_i, // random
    input   logic [XLEN-1:0]        alu_mem_i, //random
    //input   for_sel_e                for_id_a_i, 
    // output logic [XLEN-1:0] jump_a_o,
    // output logic [XLEN-1:0] jump_b_o

    //mux_br
    // input  logic [XLEN-1:0]   rs1_data_i,
    // input  logic [XLEN-1:0]   rs2_data_i,

    // input   logic [XLEN-1:0]        alu_ex_i,
    // input   logic [XLEN-1:0]        alu_mem_i,

    // input  for_sel_e          for_id_a_i,
    // input  for_sel_e          for_id_b_i,

    // output logic [XLEN-1:0]   compare_a_o,
    // output logic [XLEN-1:0]   compare_b_o

    input  b_type_f3_e      f3_i,
    input  logic            br_en_i,
   



    output logic [31:0] jump_addr,
    output logic        br_taken
);
    //output forward_id
     for_sel_e               for_id_a_o;
     for_sel_e               for_id_b_o;


    // output mux_base
     logic [XLEN-1:0] jump_a_o;
     logic [XLEN-1:0] jump_b_o;

    // output mux_br
     logic [XLEN-1:0]   compare_a_o;
     logic [XLEN-1:0]   compare_b_o;
    




 logic [XLEN-1:0] rs1_data_fwd; // internal, tương ứng rs1_data_fwd trong mux_base

    // ---------- Stage 1: forward_id ----------
    for_id_a_o = RS1_DATA_ID;
    if (rs1_addr_i != '0) begin
        if (for_info_ex_i.reg_en && (rs1_addr_i == for_info_ex_i.rd_addr))
            for_id_a_o = RD_DATA_EX;
        else if (for_info_mem_i.reg_en && (rs1_addr_i == for_info_mem_i.rd_addr))
            for_id_a_o = RD_DATA_MEM;
    end

    for_id_b_o = RS2_DATA_ID;
    if (rs2_addr_i != '0) begin
        if (for_info_ex_i.reg_en && (rs2_addr_i == for_info_ex_i.rd_addr))
            for_id_b_o = RD_DATA_EX;
        else if (for_info_mem_i.reg_en && (rs2_addr_i == for_info_mem_i.rd_addr))
            for_id_b_o = RD_DATA_MEM;
    end

    // ---------- Stage 2a: mux_base_jump_adder (dùng for_id_a_o vừa tính) ----------
    case (for_id_a_o)
        RD_DATA_EX  : rs1_data_fwd = alu_ex_i;
        RD_DATA_MEM : rs1_data_fwd = alu_mem_i;
        default     : rs1_data_fwd = rs1_data_i;
    endcase

    jump_a_o = jalr_i ? rs1_data_fwd : pc_cur_i;
    jump_b_o = imm_out_i;

    




    // ---------- Stage 2b: mux_br_compare (dùng for_id_a_o, for_id_b_o vừa tính) ----------
    case (for_id_a_o)
        RS1_DATA_ID : compare_a_o = rs1_data_i;
        RD_DATA_EX  : compare_a_o = alu_ex_i;
        RD_DATA_MEM : compare_a_o = alu_mem_i;
        default     : compare_a_o = rs1_data_i;
    endcase

    case (for_id_b_o)
        RS2_DATA_ID : compare_b_o = rs2_data_i;
        RD_DATA_EX  : compare_b_o = alu_ex_i;
        RD_DATA_MEM : compare_b_o = alu_mem_i;
        default     : compare_b_o = rs2_data_i;
    endcase



    //add_jump_addr
    jump_addr = jump_a_o + jump_b_o;

    /// br_compare

    // ---------- Stage 3: br_compare (dùng compare_a_o, compare_b_o vừa tính) ----------
    equal         = (compare_a_o == compare_b_o);
    less_signed   = ($signed(compare_a_o)   < $signed(compare_b_o));
    less_unsigned = (compare_a_o < compare_b_o);

    case (f3_i)
        F3_BEQ:  taken = equal;
        F3_BNE:  taken = !equal;
        F3_BLT:  taken = less_signed;
        F3_BGE:  taken = !less_signed;
        F3_BLTU: taken = less_unsigned;
        F3_BGEU: taken = !less_unsigned;
        default: taken = 1'b0;
    endcase

    br_taken = br_en_i && taken;

endfunction


typedef struct {
    logic [31:0] data;
    string           name;
}ins_test_t;

ins_test_t test_vectors[37] = '{
    '{ADD,   "add x3,x1,x2"},
    '{SUB,   "sub x7,x5,x6"},
    '{SLL,   "sll x11,x9,x10"},
    '{SLT,   "slt x15,x13,x14"},
    '{SLTU,  "sltu x19,x17,x18"},
    '{XOR,   "xor x23,x21,x22"},
    '{SRL,   "srl x27,x25,x26"},
    '{SRA,   "sra x31,x29,x30"},
    '{OR,    "or x8,x3,x4"},
    '{AND,   "and x16,x11,x12"},

    '{ADDI,  "addi x2,x1,100"},
    '{SLTI,  "slti x5,x4,-5"},
    '{SLTIU, "sltiu x7,x6,200"},
    '{XORI,  "xori x9,x8,0x0F"},
    '{ORI,   "ori x11,x10,0xF0"},
    '{ANDI,  "andi x13,x12,0xAA"},
    '{SLLI,  "slli x15,x14,5"},
    '{SRLI,  "srli x17,x16,3"},
    '{SRAI,  "srai x19,x18,7"},

    '{LB,    "lb x2,4(x1)"},
    '{LH,    "lh x4,8(x3)"},
    '{LW,    "lw x6,-12(x5)"},
    '{LBU,   "lbu x8,16(x7)"},
    '{LHU,   "lhu x10,20(x9)"},

    '{SB,    "sb x2,4(x1)"},
    '{SH,    "sh x4,-8(x3)"},
    '{SW,    "sw x6,12(x5)"},

    '{BEQ,   "beq x1,x2,+8"},
    '{BNE,   "bne x3,x4,+16"},
    '{BLT,   "blt x5,x6,-4"},
    '{BGE,   "bge x7,x8,+20"},
    '{BLTU,  "bltu x9,x10,+24"},
    '{BGEU,  "bgeu x11,x12,-16"},

    '{JAL,   "jal x5,+32"},
    '{JALR,  "jalr x4,16(x3)"},

    '{LUI,   "lui x5,0x12345"},
    '{AUIPC, "auipc x6,0xABCDE"}
};


int pass_cnt  = 0 ;
int fail_cnt = 0; 

always #5 clk = ~clk;
initial begin
    clk = 0 ;
    rst_n = 0;
    #20 rst_n = 1;
end

task automatic check(string name, logic [31:0] actual, logic [31:0] expected);
    if (actual !== expected) begin
      fail_cnt++;
      $error("[FAIL] %s: actual=%0h expected=%0h", name, actual, expected);
    end else begin
      pass_cnt++;
      $display("[PASS] %s: %0h", name, actual);
    end
  endtask

task automatic idle_control();
    reg_id_i = 0;
    wb_i = 0 ;
    for_info_ex_i = 0 ; 
    for_info_mem_i = 0;
    alu_ex_i = 0;
    alu_mem_i = 0;
endtask


task automatic run_one_decode(ins_test_t tv);
    decode_s exp_d;
    logic exp_rs1, exp_rs2, exp_jmp;

    idle_control();
    @(posedge clk);
    reg_id_i.ins = tv.data;
    
    #1;
    ref_model_decode(tv.data, exp_d, exp_rs1, exp_rs2, exp_jmp);
    $display("---- %s ----", tv.name);
    //check("imm_sel",  32'(id_reg_o.imm_sel),       32'(exp_d.imm_sel));

    check("alu_op",   32'(id_reg_o.ex_ctrl.alu_op), 32'(exp_d.ex_ctrl.alu_op));
    check("sel_a",    32'(id_reg_o.ex_ctrl.sel_a),  32'(exp_d.ex_ctrl.sel_a));
    check("sel_b",    32'(id_reg_o.ex_ctrl.sel_b),  32'(exp_d.ex_ctrl.sel_b));
    check("reg_en",   32'(id_reg_o.wb_ctrl.reg_en), 32'(exp_d.wb_ctrl.reg_en));
    check("sel_wb",   32'(id_reg_o.wb_ctrl.sel_wb), 32'(exp_d.wb_ctrl.sel_wb));
    check("dmem_re",  32'(id_reg_o.mem_ctrl.dmem_re),  32'(exp_d.mem_ctrl.dmem_re));
    check("dmem_wri", 32'(id_reg_o.mem_ctrl.dmem_wri), 32'(exp_d.mem_ctrl.dmem_wri));

    check("br_en",    32'(jump_o.br_en),   32'(exp_d.br_en));
    check("jal_en",   32'(jump_o.jal),  32'(exp_d.jal_en));
    check("jalr_en",  32'(jump_o.jalr), 32'(exp_d.jalr_en));

    check("extension",32'(id_reg_o.extension), 32'(exp_d.extension));

    // check("rs1_used", 32'(rs1_used_o), 32'(exp_rs1));
    // check("rs2_used", 32'(rs2_used_o), 32'(exp_rs2));
    //check("jump_en",  32'(jump_en_o),  32'(exp_jmp));
endtask



task automatic run_one_for_2mux_random(string name);
    idle_control();
    @(posedge clk);


    logic [31:0] exp_jump_addr;
    logic        exp_br_taken;

    // ----- random input -----
    rs1_addr_i = $urandom_range(0, 31);
    rs2_addr_i = $urandom_range(0, 31);
    for_info_ex_i.reg_en   = $urandom_range(0, 1);
    for_info_ex_i.rd_addr  = $urandom_range(0, 31);
    for_info_mem_i.reg_en  = $urandom_range(0, 1);
    for_info_mem_i.rd_addr = $urandom_range(0, 31);
    rs1_data_i = $urandom;
    rs2_data_i = $urandom;
    pc_cur_i   = $urandom;
    imm_out_i  = $urandom;
    alu_ex_i   = $urandom;
    alu_mem_i  = $urandom;
    jalr_i     = $urandom_range(0, 1);
    f3_i       = f3_list[$urandom_range(0, 5)];
    br_en_i    = $urandom_range(0, 1);

    #1;

    ref_model_for_2mux(
        .rs1_addr_i(rs1_addr_i), .rs2_addr_i(rs2_addr_i),
        .for_info_ex_i(for_info_ex_i), .for_info_mem_i(for_info_mem_i),
        .rs1_data_i(rs1_data_i), .pc_cur_i(pc_cur_i), .imm_out_i(imm_out_i),
        .jalr_i(jalr_i), .alu_ex_i(alu_ex_i), .alu_mem_i(alu_mem_i),
        .rs2_data_i(rs2_data_i), .f3_i(f3_i), .br_en_i(br_en_i),
        .jump_addr(exp_jump_addr), .br_taken(exp_br_taken)
    );

    $display("---- %s ----", name);
    check("jump_addr", jump_addr_dut, exp_jump_addr);
    check("br_taken",  32'(br_taken_dut), 32'(exp_br_taken));
endtask

    


task automatic run_one_for_2mux_directed(string name, int case_sel);
    idle_control();
    @(posedge clk);

    logic [31:0] exp_jump_addr;
    logic        exp_br_taken;

    // ----- data field vẫn random (không ảnh hưởng logic control) -----
    rs1_data_i = $urandom;
    rs2_data_i = $urandom;
    pc_cur_i   = $urandom;
    imm_out_i  = $urandom;
    alu_ex_i   = $urandom;
    alu_mem_i  = $urandom;
    jalr_i     = $urandom_range(0, 1);
    f3_i       = f3_list[$urandom_range(0, 5)];
    br_en_i    = $urandom_range(0, 1);

    // ----- chèn data directed vào field control -----
    case (case_sel)
        0: begin // EX hazard match (rs1)
            rs1_addr_i              = $urandom_range(1, 31);
            for_info_ex_i.reg_en    = 1'b1;
            for_info_ex_i.rd_addr   = rs1_addr_i;
            for_info_mem_i.reg_en   = $urandom_range(0, 1);
            for_info_mem_i.rd_addr  = $urandom_range(0, 31);
        end
        1: begin // MEM hazard match, EX không match (rs1)
            rs1_addr_i              = $urandom_range(1, 31);
            for_info_ex_i.reg_en    = 1'b0;
            for_info_ex_i.rd_addr   = $urandom_range(0, 31);
            for_info_mem_i.reg_en   = 1'b1;
            for_info_mem_i.rd_addr  = rs1_addr_i;
        end
        2: begin // EX và MEM cùng match rs1 → test priority
            rs1_addr_i              = $urandom_range(1, 31);
            for_info_ex_i.reg_en    = 1'b1;
            for_info_ex_i.rd_addr   = rs1_addr_i;
            for_info_mem_i.reg_en   = 1'b1;
            for_info_mem_i.rd_addr  = rs1_addr_i;
        end
        3: begin // x0 — match nhưng không được forward
            rs1_addr_i              = '0;
            for_info_ex_i.reg_en    = 1'b1;
            for_info_ex_i.rd_addr   = '0;
            for_info_mem_i.reg_en   = 1'b1;
            for_info_mem_i.rd_addr  = '0;
        end
        4: begin // EX hazard match cho rs2
            rs2_addr_i              = $urandom_range(1, 31);
            for_info_ex_i.reg_en    = 1'b1;
            for_info_ex_i.rd_addr   = rs2_addr_i;
            rs1_addr_i              = $urandom_range(0, 31);
        end
        5: begin // rs1 và rs2 cùng match EX cùng lúc
            rs1_addr_i              = $urandom_range(1, 31);
            rs2_addr_i              = rs1_addr_i;
            for_info_ex_i.reg_en    = 1'b1;
            for_info_ex_i.rd_addr   = rs1_addr_i;
        end
        default: ;
    endcase

    #1;

    ref_model_for_2mux(
        .rs1_addr_i(rs1_addr_i), .rs2_addr_i(rs2_addr_i),
        .for_info_ex_i(for_info_ex_i), .for_info_mem_i(for_info_mem_i),
        .rs1_data_i(rs1_data_i), .pc_cur_i(pc_cur_i), .imm_out_i(imm_out_i),
        .jalr_i(jalr_i), .alu_ex_i(alu_ex_i), .alu_mem_i(alu_mem_i),
        .rs2_data_i(rs2_data_i), .f3_i(f3_i), .br_en_i(br_en_i),
        .jump_addr(exp_jump_addr), .br_taken(exp_br_taken)
    );

    $display("---- %s (case %0d) ----", name, case_sel);
    check("jump_addr", jump_addr_dut, exp_jump_addr);
    check("br_taken",  32'(br_taken_dut), 32'(exp_br_taken));
endtask

// các testcase



initial begin
    int num_random_test   = 200;
    int num_directed_case = 6;
    // đợi qua reset trước khi bắt đầu test
    wait(rst_n == 1);
    #1;
    // foreach (test_vectors[i])
    //     run_one_decode(test_vectors[i]);

    repeat (200) run_one_random("RANDOM");
    
    run_one_for_2mux_directed("direct",num_directed_case);
    for (int c = 0; c < 6; c++)
        repeat (10) run_one_directed("HAZARD", c);

    $display("========================================");
    $display("Total: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    $display("========================================");
    $finish;
end

endmodule 
