



module for_muxbase_muxbr
    import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;
(
    // forward_id
    input logic [REG_ADDR_W-1:0]   rs1_addr_i,
    input logic [REG_ADDR_W-1:0]   rs2_addr_i,
    input for_info_t               for_info_ex_i,
    input for_info_t               for_info_mem_i,

    output for_sel_e               for_id_a_o,
    output for_sel_e               for_id_b_o,

    //mux_base
    input  logic [XLEN-1:0] rs1_data_i,   // raw từ regfile
    input  logic [XLEN-1:0] pc_cur_i,
    input  logic [XLEN-1:0] imm_out_i,

    input  logic            jalr_i,
    input  logic [XLEN-1:0] alu_ex_i,
    input  logic [XLEN-1:0] alu_mem_i,
    output logic [XLEN-1:0] jump_a_o,
    output logic [XLEN-1:0] jump_b_o,

    //mux_br  (đã bổ sung 3 port đang bị thiếu)
    input  logic [XLEN-1:0]   rs2_data_i,
    input  logic [2:0]       f3_i,
    input  logic              br_en_i,

    output logic [XLEN-1:0]   compare_a_o,
    output logic [XLEN-1:0]   compare_b_o,

    output logic [XLEN-1:0] jump_addr_o,
    output logic            br_taken_o
);

    logic [1:0] for_id_a, for_id_b;

    forward_id u_forward_id(
        .rs1_addr_i     (rs1_addr_i),
        .rs2_addr_i     (rs2_addr_i),
        .for_info_ex_i  (for_info_ex_i),
        .for_info_mem_i (for_info_mem_i),
        .for_id_a_o     (for_id_a),
        .for_id_b_o     (for_id_b)
    );

    logic [XLEN-1:0] compare_a, compare_b;

    mux_br_compare u_mux_br_compare(
        .rs1_data_i (rs1_data_i),
        .rs2_data_i (rs2_data_i),
        .alu_ex_i   (alu_ex_i),
        .alu_mem_i  (alu_mem_i),
        .for_id_a_i (for_id_a),
        .for_id_b_i (for_id_b),
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
        .f3_i       (f3_i),
        .br_en_i    (br_en_i),
        .br_taken_o (br_taken)
    );

    logic [XLEN-1:0] jump_a, jump_b;
    mux_base_jump_adder u_mux_base_jump_adder(
        .rs1_data_i (rs1_data_i),
        .pc_cur_i   (pc_cur_i),
        .imm_out_i  (imm_out_i),
        .jalr_i     (jalr_i),
        .alu_ex_i   (alu_ex_i),
        .alu_mem_i  (alu_mem_i),
        .for_id_a_i (for_id_a),
        .jump_a_o   (jump_a),
        .jump_b_o   (jump_b)
    );

    //=========================================================
    // jump_adder
    //=========================================================
    logic [XLEN-1:0] jump_adder;

    jump_adder u_jump_adder(
        .jump_a_i    (jump_a),
        .jump_b_i    (jump_b),
        .jump_adder_o(jump_adder)
    );

    // assign for_id_a_o  = for_id_a;
    // assign for_id_b_o  = for_id_b;
    // assign jump_a_o    = jump_a;
    // assign jump_b_o    = jump_b;
    // assign compare_a_o = compare_a;
    // assign compare_b_o = compare_b;
    assign jump_addr_o = jump_adder;
    assign br_taken_o  = br_taken;

endmodule


// // === Tác động vào for_muxbase_muxbr (9) ===
// localparam logic [31:0] BEQ   = 32'b00000000001000001000010001100011;
// localparam logic [31:0] BNE   = 32'b00000000010000011001100001100011;
// localparam logic [31:0] BLT   = 32'b11111110011000101100111011100011;
// localparam logic [31:0] BGE   = 32'b00000000100000111101101001100011;
// localparam logic [31:0] BLTU  = 32'b00000000101001001110110001100011;
// localparam logic [31:0] BGEU  = 32'b11111110110001011111100011100011;
// localparam logic [31:0] JAL   = 32'b00000010000000000000001011101111;
// localparam logic [31:0] JALR  = 32'b00000001000000011000001001100111;
// localparam logic [31:0] AUIPC = 32'b10101011110011011110001100010111;

// // === Không tác động (6) - dùng làm case đối chứng ===
// localparam logic [31:0] ADD   = 32'b00000000001000001000000110110011;
// localparam logic [31:0] ADDI  = 32'b00000110010000001000000100010011;
// localparam logic [31:0] LW    = 32'b11111111010000101010001100000011;
// localparam logic [31:0] SW    = 32'b00000000011000101010011000100011;
// localparam logic [31:0] AND   = 32'b00000000110001011111100000110011;
// localparam logic [31:0] LUI   = 32'b00010010001101000101001010110111;


module tb_for_muxbase_muxbr_id
import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;
();
initial begin
    $dumpfile("wave.vcd");   // hoặc dùng $dumpfile("wave.fst") nếu dùng --trace-fst
    $dumpvars(0, tb_for_muxbase_muxbr);
end


logic clk;
logic rst_n;


   logic [REG_ADDR_W-1:0]   rs1_addr_i;
     logic [REG_ADDR_W-1:0]   rs2_addr_i;
     for_info_t               for_info_ex_i;
     for_info_t               for_info_mem_i;

     for_sel_e               for_id_a_o;
     for_sel_e               for_id_b_o;

    //mux_base
      logic [XLEN-1:0] rs1_data_i;   // raw từ regfile
      logic [XLEN-1:0] pc_cur_i;
      logic [XLEN-1:0] imm_out_i;

      logic            jalr_i;
      logic [XLEN-1:0] alu_ex_i;
      logic [XLEN-1:0] alu_mem_i;
     logic [XLEN-1:0] jump_a_o;
     logic [XLEN-1:0] jump_b_o;

    //mux_br  (đã bổ sung 3 port đang bị thiếu)
      logic [XLEN-1:0]   rs2_data_i;
      logic [2:0]       f3_i;
      logic              br_en_i;

     logic [XLEN-1:0]   compare_a_o;
     logic [XLEN-1:0]   compare_b_o;

     logic [XLEN-1:0] jump_addr_o;
     logic            br_taken_o;

for_muxbase_muxbr u_for_muxbase_muxbr(.*);

int pass_cnt  = 0 ;
int fail_cnt = 0; 

localparam logic [2:0] f3_list [0:5] = '{
    3'b000, // BEQ
    3'b001, // BNE
    3'b100, // BLT
    3'b101, // BGE
    3'b110, // BLTU
    3'b111  // BGEU
};

// f3_idx = $urandom_range(0, 5);
// f3_i   = f3_list[f3_idx];


always #5 clk = ~clk;
initial begin
    clk = 0 ;
    rst_n = 0;
    #20 rst_n = 1;
end



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
     input  logic [XLEN-1:0]   rs2_data_i,

    // input   logic [XLEN-1:0]        alu_ex_i,
    // input   logic [XLEN-1:0]        alu_mem_i,

    // input  for_sel_e          for_id_a_i,
    // input  for_sel_e          for_id_b_i,

    // output logic [XLEN-1:0]   compare_a_o,
    // output logic [XLEN-1:0]   compare_b_o

    input  [2:0]     f3_i,
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
    

    logic equal;
    logic less_signed;
    logic less_unsigned;
    logic taken;


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


task automatic idle_control();
    rs1_addr_i = 0;
    rs2_addr_i = 0;
    for_info_ex_i = 0; 
    for_info_mem_i = 0;
    rs1_data_i = 0;
    pc_cur_i = 0;
    imm_out_i = 0;
    jalr_i = 0;
    alu_ex_i  = 0;
    alu_mem_i = 0;
    f3_i  = 3'b010;
    br_en_i  = 0;
    jump_addr_o  = 0;
    br_taken_o  = 0;
endtask


task automatic run_one_for_2mux_random(string name);
logic [31:0] exp_jump_addr;
    logic        exp_br_taken;
     int          f3_idx;  


    idle_control();
    @(posedge clk);


    
    // ----- random input -----
    rs1_addr_i = 5'($urandom_range(0, 31));
    rs2_addr_i = 5'($urandom_range(0, 31));
    for_info_ex_i.reg_en   = 1'($urandom_range(0, 1));
    for_info_ex_i.rd_addr  = 5'($urandom_range(0, 31));
    for_info_mem_i.reg_en  =1'($urandom_range(0, 1));
    for_info_mem_i.rd_addr =5'($urandom_range(0, 31));
    rs1_data_i = $urandom;
    rs2_data_i = $urandom;
    pc_cur_i   = $urandom;
    imm_out_i  = $urandom;
    alu_ex_i   = $urandom;
    alu_mem_i  = $urandom;
    jalr_i     = 1'($urandom_range(0, 1));
    f3_idx = $urandom_range(0, 5);
    f3_i   = f3_list[f3_idx];
    br_en_i    =1'($urandom_range(0, 1));

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
    check("jump_addr", jump_addr_o, exp_jump_addr);
    check("br_taken",  32'(br_taken_o), 32'(exp_br_taken));
endtask

    


task automatic run_one_for_2mux_directed(string name, int case_sel);
 logic [31:0] exp_jump_addr;
    logic        exp_br_taken;   
     int          f3_idx;  
     idle_control();
    @(posedge clk);

   

    // ----- data field vẫn random (không ảnh hưởng logic control) -----
    rs1_data_i = $urandom;
    rs2_data_i = $urandom;
    pc_cur_i   = $urandom;
    imm_out_i  = $urandom;
    alu_ex_i   = $urandom;
    alu_mem_i  = $urandom;
    jalr_i     = 1'($urandom_range(0, 1));
    f3_idx = $urandom_range(0, 5);
    f3_i   = f3_list[f3_idx];
    br_en_i    = 1'($urandom_range(0, 1));

    // ----- chèn data directed vào field control -----
    case (case_sel)
        0: begin // EX hazard match (rs1)
            rs1_addr_i              = 5'($urandom_range(1, 31));
            for_info_ex_i.reg_en    = 1'b1;
            for_info_ex_i.rd_addr   = rs1_addr_i;
            for_info_mem_i.reg_en   = 1'($urandom_range(0, 1));
            for_info_mem_i.rd_addr  = 5'($urandom_range(1, 31));
        end
        1: begin // MEM hazard match, EX không match (rs1)
            rs1_addr_i              = 5'($urandom_range(1, 31));
            for_info_ex_i.reg_en    = 1'b0;
            for_info_ex_i.rd_addr   = 5'($urandom_range(1, 31));
            for_info_mem_i.reg_en   = 1'b1;
            for_info_mem_i.rd_addr  = rs1_addr_i;
        end
        2: begin // EX và MEM cùng match rs1 → test priority
            rs1_addr_i              = 5'($urandom_range(1, 31));
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
            rs2_addr_i              = 5'($urandom_range(1, 31));
            for_info_ex_i.reg_en    = 1'b1;
            for_info_ex_i.rd_addr   = rs2_addr_i;
            rs1_addr_i              = 5'($urandom_range(1, 31));
        end
        5: begin // rs1 và rs2 cùng match EX cùng lúc
            rs1_addr_i              = 5'($urandom_range(1, 31));
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
    check("jump_addr", jump_addr_o, exp_jump_addr);
    check("br_taken",  32'(br_taken_o), 32'(exp_br_taken));
endtask















task automatic check(string name, logic [31:0] actual, logic [31:0] expected);
    if (actual !== expected) begin
      fail_cnt++;
      $error("[FAIL] %s: actual=%0h expected=%0h", name, actual, expected);
    end else begin
      pass_cnt++;
      $display("[PASS] %s: %0h", name, actual);
    end
  endtask







initial begin
     int num_random_test   = 200;
    int num_directed_case = 6;
    // đợi qua reset trước khi bắt đầu test
    wait(rst_n == 1);
    #1;
    // foreach (test_vectors[i])
    //     run_one_decode(test_vectors[i]);

    repeat (200) run_one_for_2mux_random("RANDOM");
    
    // run_one_for_2mux_directed("direct",num_directed_case);
    for (int c = 0; c < 6; c++)
        repeat (10) run_one_for_2mux_directed("HAZARD", c);

    $display("========================================");
    $display("Total: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    $display("========================================");
end

endmodule


