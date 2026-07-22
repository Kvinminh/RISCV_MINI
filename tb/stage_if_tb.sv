`timescale 1ns/1ps;
parameter XLEN = 32;

module stage_if_tb;
//1.
logic clk, rst_n;

//pc_adder
logic [XLEN-1:0] pc4_if;

// pc_mux
//input
logic br_taken_id;
logic br_en_id;
logic jal_id;
logic jalr_id;
logic [XLEN-1:0] pc_jump_id;
// output
logic [XLEN-1:0] pc_next_if;


// pc
//input 
logic stall_pc;
// logic [XLEN-1:0] pc_next_if
//out put 
logic [XLEN-1:0] pc_cur_if;

// 
//imem 
//logic [XLEN-1:0] pc_cur_if;
//output 
logic [XLEN-1:0] ins;

//2.
int pass = 0;
int fail = 0;


//3 clkcl 

always #5 clk = ~clk;

initial begin 
    clk = 0;
    rst_n = 0;
    #20 rst_n = 1;
end


//4 nối dây theo đúng datapath


pc_addr u_pc_adder(
    .pc_cur_if  ( pc_cur_if),
    .pc4_if     (pc4_if),
);



pc_mux u_pc_mux (
    .br_taken_id (br_taken_id),
    .br_en_id     (be_en_id),
    .jal_id      (jal_id),
    .jalr_id     (jalr_id),
    .pc4_if      (pc4_if),
    .pc_jump      (pc_jump),
    pc_next_if   (pc_next_if)
);

pc u_pc (
    .clk        (clk),
    .rst_n      (rst_n),
    .stall_pc   (stall_pc),
    .pc_next_if (pc_next_if),
    .pc_cur_if  (pc_cur_if)
  );

  imem u_imem (
    .pc_cur_if (pc_cur_if),
    .ins_if    (ins_if)
  );

// 5. Task nạp sẵn nội dung imem — CẦN SỬA LẠI theo đúng cách RTL
task automatic load_imem(int addr_word, logic [31:0] data);
    u_imem.mem[addr_word] = data;   // TODO: đổi "mem" cho đúng tên mảng trong imem.sv
  endtask

  // ------------------------------------------------------------------
  // 6. Checker dùng chung cho mọi task test — thay cho compare() bên OOP.
  // ------------------------------------------------------------------
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
    br_taken_id = 0;
    br_en_id    = 0;
    jal_id      = 0;
    jalr_id     = 0;
    pc_jump     = '0;
    stall_pc    = 0;
    stall       = 0;
    flush       = 0;
  endtask


/// 8 các case và các test case trong direct
task automatic test_control();
    idle_control();
    @(posedge clk);
    #1;
    check("reset: pc_cur_if = 0", pc_cur_if, 32'h0;);
endtask

task automatic test_sequential_fetch();
    idle_control();
    load_imem(0, 32'h00000013); // NOP tại addr 0
    load_imem(1, 32'h00100093); // ví dụ addi x1,x0,1 tại addr 4 (word index 1)
    

    @(posedge clk); #1;
    check("seq: pc4_if = pc_cur_if+4", pc4_if, pc_cur_if + 32'd4);

    @(posedge clk); #1;
    check("seq: pc_cur_if tang 4", pc_cur_if, 32'd4);
  endtask


task automatic test_stall_pc();
    logic [31:0] pc_before;
    idle_control();
    pc_before = pc_cur_if;

    stall_pc = 1;
    @(posedge clk); #1;
    check("stall_pc: pc khong doi", pc_cur_if, pc_before);

    stall_pc = 0;   // thả stall để test sau không bị ảnh hưởng
  endtask



task automatic test_branch_taken();
    idle_control();
    pc_jump     = 32'h0000_1000;
    br_taken_id = 1;
    br_en_id    = 1;

    #1; // pc_mux là combinational, không cần chờ clock để check pc_next_if
    check("branch: pc_next_if = pc_jump", pc_next_if, pc_jump);

    @(posedge clk); #1;
    check("branch: pc_cur_if nhay toi pc_jump", pc_cur_if, pc_jump);

    idle_control();
  endtask



 task automatic test_jal();
    idle_control();
    pc_jump = 32'h0000_2000;
    jal_id  = 1;

    #1;
    check("jal: pc_next_if = pc_jump", pc_next_if, pc_jump);

    idle_control();
  endtask

task automatic test_jalr();
    idle_control();
    pc_jump = 32'h0000_3000;
    jalr_id = 1;

    #1;
    check("jalr: pc_next_if = pc_jump", pc_next_if, pc_jump);

    idle_control();
  endtask
endmodule








