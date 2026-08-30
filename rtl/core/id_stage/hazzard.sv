module hazzard 
import core_pkg::*;
(
    input logic [REG_ADDR_W-1:0] rs1_addr_i,
    input logic [REG_ADDR_W-1:0] rs2_addr_i,
    input logic                  rs1_used_i,
    input logic                  rs2_used_i,

    input logic                  jump_en_i,       // jal || jalr từ decode
    input logic                  br_en_i,       //          từ doecode
    input logic                  br_taken_i,      // từ br_compare

    input for_info_t             for_info_ex_i,

    input for_info_t             for_info_mem_i,

    output hzd_ctrl_t            hzd_ctrl_o
);

logic take_jump;
assign take_jump = jump_en_i || (br_taken_i && br_en_i);



// 1 kiểm tra xem có trường hợp nào 
// kiểm tra xem đó là forward ở stage ex, mem
// kiểm tra xem đó là forward ở rs1 hay rs2


logic rs1_ex, rs2_ex, rs1_mem,rs2_mem;

// assign rs1_ex =  rs1_used_i && reg_en_ex && ( rd_ex != 5'd0) && ( rd_ex == rs1_addr_i);
// assign rs2_ex =  rs2_used_i && reg_en_ex && ( rd_ex != 5'd0) && ( rd_ex == rs2_addr_i);
// assign rs1_mem = rs1_used_i && reg_en_mem && ( rd_mem != 5'd0) && ( rd_mem == rs1_addr_i);
// assign rs2_mem = rs2_used_i && reg_en_mem && ( rd_mem != 5'd0) && ( rd_mem == rs2_addr_i);


    always_comb begin : miss
        rs1_ex = (rs1_used_i) && (for_info_ex_i.reg_en) && (for_info_ex_i.rd_addr != 5'b0) && (for_info_ex_i.rd_addr == rs1_addr_i);
        rs2_ex = (rs2_used_i) && (for_info_ex_i.reg_en) && (for_info_ex_i.rd_addr != 5'b0) && (for_info_ex_i.rd_addr == rs2_addr_i);

        rs1_mem = (rs1_used_i) && (for_info_mem_i.reg_en) && (for_info_mem_i.rd_addr != 5'b0) && (for_info_mem_i.rd_addr == rs1_addr_i);
        rs2_mem = (rs2_used_i) && (for_info_mem_i.reg_en) && (for_info_mem_i.rd_addr != 5'b0) && (for_info_mem_i.rd_addr == rs2_addr_i);
    end



// 2 các case trong forward id 
logic br2alu_ex, /*br2mem,*/ br2load_ex, br2load_mem;


assign br2alu_ex = (rs1_ex || rs2_ex) && br_en_i && !for_info_ex_i.mem_re;
//assign br2mem = (rs1_mem || rs2_mem) && br_en_id && !mem_re_mem;
assign br2load_ex = (rs1_ex || rs2_ex) && br_en_i && for_info_ex_i.mem_re;
assign br2load_mem = (rs1_mem || rs2_mem) && br_en_i && for_info_mem_i.mem_re;



// 3 các case trong forward EX 

logic alu2load; // load to hazard
assign alu2load = (rs1_ex || rs2_ex ) && for_info_ex_i.mem_re && !br_en_i ;


// 4 quyết định stall và flush 
logic need_stall;
assign need_stall = br2alu_ex || br2load_ex || br2load_mem || alu2load;

// quyết đing stall
assign     hzd_ctrl_o.stall_pc    = need_stall;
assign     hzd_ctrl_o.stall_if_id = need_stall;
assign     hzd_ctrl_o.flush_id_ex = need_stall;


// quyết định flush
assign     hzd_ctrl_o.flush_if_id = take_jump && !need_stall;

endmodule
