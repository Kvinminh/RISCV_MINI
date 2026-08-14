`timescale 1ns/1ps



module tb_if_stage
    import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;
();

initial begin
    $dumpfile("wave.vcd");   // hoặc dùng $dumpfile("wave.fst") nếu dùng --trace-fst
    $dumpvars(0, tb_if_stage);
end


logic clk;
logic rst_n;
logic stall_pc_i;
jump_t jump_id_i;
if_id_reg_t if_reg_o;

if_stage u_if_stage(
    .clk(clk),
    .rst_n(rst_n),
    .stall_pc_i(stall_pc_i),
    .jump_id_i(jump_id_i),
    .if_reg_o(if_reg_o)
);


int pass_cnt= 0;
int fail_cnt= 0;
 
always #5 clk = ~clk;
initial begin
    clk = 0;
    rst_n = 0;
     #20 rst_n = 1;
end


task automatic load_imem(int addr_word, logic [31:0] data);
    u_if_stage.u_imem.memory[addr_word] = data;
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


//// 7. Task khởi tạo control mặc định — gọi ở đầu mỗi test case để
  task automatic idle_control();
    stall_pc_i = 0;
    jump_id_i = 0;
  endtask


// 8 các test case
task automatic test_control();
    idle_control();
    #1;
    check("reset: pc_cur = 0", u_if_stage.pc_cur, 32'h0);
endtask

task automatic test_sequential_fetch();
    idle_control();
    load_imem(0 , NOP);
    load_imem(1,  32'h00100093);

    @(posedge clk ); #1;
    check("seq : pc4 = pc_cur", u_if_stage.pc_cur , u_if_stage.pc4 - 32'd4);

    @(posedge clk); #1;
    check(" seq: sau 1 clk tang 4 ", u_if_stage.pc_cur , u_if_stage.pc4 - 32'd4 );
endtask


task automatic test_stall_pc();
  logic [31:0] pc_before;
  idle_control();
  pc_before = u_if_stage.pc_cur;

  stall_pc_i = 1;
  @(posedge clk); #1;
  check("stall_pc: pc khong doi",  u_if_stage.pc_cur,pc_before );
  stall_pc_i = 0;
endtask



task automatic test_branch_taken();
  idle_control();
  jump_id_i.jump_addr  = 32'h0000_1000;
  jump_id_i.br_en    = 1;
  jump_id_i.br_taken = 1;

  #1; // pc_mux là combinational, không cần chờ clock để check pc_next_if
  check ( " branch: pc_next = pc_jump", u_if_stage.pc_next, jump_id_i.jump_addr );
  @(posedge clk ); #1;
  check ( "branch: pc_cur = pc_jump", u_if_stage.pc_cur, jump_id_i.jump_addr);

endtask 

task automatic test_jal();
    idle_control();
    jump_id_i.jump_addr = 32'h0000_2000;
    jump_id_i.jal  = 1;

#1; // pc_mux là combinational, không cần chờ clock để check pc_next_if
  check ( " jal: pc_next = jump_addr", u_if_stage.pc_next,jump_id_i.jump_addr );




endtask


task automatic test_jalr();
    idle_control();
    jump_id_i.jump_addr = 32'h0000_2000;
    jump_id_i.jalr  = 1;

#1; // pc_mux là combinational, không cần chờ clock để check pc_next_if
  check ( " jalr: pc_next = jump_addr", u_if_stage.pc_next,jump_id_i.jump_addr );




endtask








initial begin
    // đợi qua reset trước khi bắt đầu test
    wait(rst_n == 1);
    #1;

    test_control();
    test_sequential_fetch();  // đang comment, bật lại khi sửa xong
    test_stall_pc();
    test_branch_taken();
    test_jal();
    test_jalr();

    $display("========================================");
    $display("Total: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    $display("========================================");
    $finish;
end




  
endmodule

