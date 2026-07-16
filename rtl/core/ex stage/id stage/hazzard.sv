module hazzard 
import core_pkg::*;
(
    input loigc [REG_ADDR_W-1:0] rs1_addr_id,
    input logic [REG_ADDR_W-1:0] rs2_addr_id,
    input logic                  rs1_used_id,
    input logic                  rs2_used_id,

    input logic                  jump_id,       // jal || jalr từ decode
    input logic                  br_en_id,       //          từ doecode
    input logic                  br_taken,      // từ br_compare


    input logic [REG_ADDR_W-1:0] rd_ex,
    input logic                  reg_en_ex,
    input logic                  mem_re_ex,

    input logic [REG_ADDR_W-1:0] rd_mem,
    input logic                  reg_en_mem,
    input logic                  mem_re_mem,

    output logic                 stall_pc,
    output logic                 stall_if_id,
    output logic                 flush_if_id,
    output logic                 flush_id_ex
);

logic take_jump;
assign take_jump = jump_id || (br_taken && br_en_id);



// 1 kiểm tra xem có trường hợp nào 
// kiểm tra xem đó là forward ở stage ex, mem
// kiểm tra xem đó là forward ở rs1 hay rs2


logic rs1_ex, rs2_ex, rs1_mem,rs2_mem;

assign rs1_ex =  rs1_used_id && reg_en_ex && ( rd_ex != 5'd0) && ( rd_ex == rs1_addr_id);
assign rs2_ex =  rs2_used_id && reg_en_ex && ( rd_ex != 5'd0) && ( rd_ex == rs2_addr_id);
assign rs1_mem = rs1_used_id && reg_en_mem && ( rd_mem != 5'd0) && ( rd_mem == rs1_addr_id);
assign rs2_mem = rs2_used_id && reg_en_mem && ( rd_mem != 5'd0) && ( rd_mem == rs2_addr_id);



// 2 các case trong forward id 
logic br2alu_ex,br2mem,br2load_ex,br2load_mem;


assign br2alu_ex = (rs1_ex || rs2_ex) && br_en_id && !mem_re_ex;
//assign br2mem = (rs1_mem || rs2_mem) && br_en_id && !mem_re_mem;
assign br2load_ex = (rs1_ex || rs2_ex) && br_en_id && mem_re_ex;
assign br2load_mem = (rs1_mem || rs2_mem) && br_en_id && mem_re_mem;



// 3 các case trong forward EX 

logic alu2load; // load to hazard
assign alu2load = (rs1_ex || rs2_ex ) && mem_re_ex && !br_en_id ;


// 4 quyết định stall và flush 
logic need_stall;
assign need_stall = br2alu_ex || br2load_ex || br2load_mem || alu2load;

// quyết đing stall
assign     stall_pc    = need_stall;
assign     stall_if_id = need_stall;
assign     flush_id_ex = need_stall;


// quyết định flush
assign     flush_if_id = take_jump && !need_stall;

endmodule