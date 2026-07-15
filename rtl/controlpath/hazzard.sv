module hazzard 
import core_pkg::*;
(
    input loigc [REG_ADDR_W-1:0] rs1_addr_id,
    input logic [REG_ADDR_W-1:0] rs2_addr_id,
    input logic                  rs1_used_id,
    input logic                  rs2_used_id,

    input logic                  take_jump_id,
    input logic [REG_ADDR_W-1:0] rd_ex,
    input logic                  reg_en_ex,
    input logic                  mem_re_ex,
    input logic [REG_ADDR_W-1:0] rd_mem,
    input logic                  reg_en_mem,

    output logic                 stall_pc,
    output logic                 stall_if_id,
    output logic                 flush_if_id
);





// 1 kiểm tra xem có trường hợp nào 
// kiểm tra xem đó là forward ở stage ex, mem
// kiểm tra xem đó là forward ở rs1 hay rs2


logic rs1_ex, rs2_ex, rs1_mem,rs2_mem;

assign rs1_ex =  rs1_used_id && reg_en_ex && ( rd_ex != 5'd0) && ( rd_ex == rs1_addr_id);
assign rs2_ex =  rs2_used_id && reg_en_ex && ( rd_ex != 5'd0) && ( rd_ex == rs2_addr_id);
assign rs1_mem = rs1_used_id && reg_en_mem && ( rd_mem != 5'd0) && ( rd_mem == rs1_addr_id);
assign rs2_mem = rs2_used_id && reg_en_mem && ( rd_mem != 5'd0) && ( rd_mem == rs2_addr_id);



// 2 các case trong forward id 
logic br2alu,br2mem,br2load_ex,br2load_mem;


assign br2alu = (rs1_ex || rs2_ex) && take_jump && !mem_re_ex;
assign br2mem = (rs1_mem || rs2_mem) && take_jump && !mem_re_mem;
assign br2load_ex = (rs1_ex || rs2_ex) && take_jump && mem_re_ex;
assign br2load_mem = (rs1_mem || rs2_mem) && take_jump && mem_re_mem;



// 3 các case trong forward EX 

logic alu2load;

assign alu2load = (rs1_ex || rs2_ex ) && mem_re_ex;



// 4 quyết định stall và flush 


assign     stall_pc    = br2alu || br2load_ex || br2load_mem || alu2load; 
assign     stall_if_id = br2alu || br2load_ex || br2load_mem || alu2load; 
assign     flush_if_id = br2alu || br2load_ex || br2load_mem || alu2load; 


endmodule