// // =============================================================
// // tb_if_stage.sv
// // Directed testbench cho CỤM IF stage: pc_adder + pc_mux + pc +
// // imem + if_id_reg. Đây KHÔNG phải OOP — không có class, không có
// // mailbox — chỉ có task + assert trực tiếp trong 1 module duy nhất.
// //
// // Lý do gộp 5 module này lại thành 1 file thay vì test riêng lẻ:
// // chúng phụ thuộc dữ liệu vào nhau theo 1 vòng khép kín trong cùng
// // 1 chu kỳ (pc -> pc_adder -> pc_mux -> quay lại pc), nên test rời
// // từng module sẽ phải tự giả lập input của module kia — test chung
// // nguyên cụm vừa đúng thực tế, vừa đỡ trùng lặp code giả lập.
// //
// // GIẢ ĐỊNH cần em xác nhận lại theo đúng RTL thật của mình:
// //  - imem đọc COMBINATIONAL (không có độ trễ 1 chu kỳ). Nếu imem
// //    của em là SRAM đồng bộ (đọc ra ở chu kỳ SAU khi đưa địa chỉ),
// //    sửa lại các task test bên dưới, thêm 1 @(posedge clk) trước khi check ins_if.
// //  - Mã NOP khi flush là 32'h00000013 (theo quy ước ADDI x0,x0,0 của em).
// //  - flush chỉ có tác dụng khi KHÔNG stall (đúng rule em đã chốt:
// //    "flush_ifid phải gate bởi !stall").
// // =============================================================

// `timescale 1ns/1ps

// module tb_if_stage;

//   // ------------------------------------------------------------------
//   // 1. Khai báo tín hiệu — gộp toàn bộ port của 5 module con lại,
//   //    đặt tên đúng như RTL thật để lúc nối instance khỏi nhầm.
//   // ------------------------------------------------------------------
//   logic clk, rst_n;

//   // --- pc_adder ---
//   // input: pc_cur_if (lấy từ output của pc)
//   // output: pc4_if
//   logic [31:0] pc4_if;

//   // --- pc_mux ---
//   // input control: br_taken_id, br_en_id, jal_id, jalr_id (quyết định từ ID stage)
//   // input datapath: pc4_if, pc_jump
//   // output: pc_next_if
//   logic        br_taken_id, br_en_id, jal_id, jalr_id;
//   logic [31:0] pc_jump;
//   logic [31:0] pc_next_if;

//   // --- pc ---
//   // input control: stall_pc
//   // input datapath: pc_next_if
//   // output: pc_cur_if
//   logic        stall_pc;
//   logic [31:0] pc_cur_if;

//   // --- imem ---
//   // input: pc_cur_if
//   // output: ins_if
//   logic [31:0] ins_if;

//   // --- if_id_reg ---
//   // input control: stall, flush
//   // input datapath: ins_if, pc4_if, pc_cur_if
//   // output: ins_id, pc4_id, pc_cur_id
//   logic        stall, flush;
//   logic [31:0] ins_id, pc4_id, pc_cur_id;

//   // ------------------------------------------------------------------
//   // 2. Đếm pass/fail toàn cục — thay cho Scoreboard bên OOP.
//   //    Directed test không cần Reference model tách riêng vì mỗi
//   //    task tự biết trước giá trị expected (em tự tính tay khi viết test).
//   // ------------------------------------------------------------------
//   int pass_cnt = 0;
//   int fail_cnt = 0;

//   // ------------------------------------------------------------------
//   // 3. Clock 10ns, reset 20ns đầu — y hệt cách làm bên OOP, không đổi.
//   // ------------------------------------------------------------------
//   always #5 clk = ~clk;

//   initial begin
//     clk   = 0;
//     rst_n = 0;
//     #20 rst_n = 1;
//   end


// // dump file
//   initial begin
//     $dumpfile("wave.vcd");
//     $dumpvars(0, tb_if_stage);
//   end

//   // ------------------------------------------------------------------
//   // 4. Instance 5 module con, nối đúng theo datapath thật của IF stage.
//   //    Đây là phần THAY THẾ cho "Driver + Interface" bên OOP — ở mức
//   //    directed, em nối dây thẳng bằng wire, không cần interface/clocking block.
//   // ------------------------------------------------------------------
//   pc_adder u_pc_adder (
//     .pc_cur_if (pc_cur_if),
//     .pc4_if    (pc4_if)
//   );

//   pc_mux u_pc_mux (
//     .br_taken_id (br_taken_id),
//     .br_en_id    (br_en_id),
//     .jal_id      (jal_id),
//     .jalr_id     (jalr_id),
//     .pc4_if      (pc4_if),
//     .pc_jump     (pc_jump),
//     .pc_next_if  (pc_next_if)
//   );

//   pc u_pc (
//     .clk        (clk),
//     .rst_n      (rst_n),
//     .stall_pc   (stall_pc),
//     .pc_next_if (pc_next_if),
//     .pc_cur_if  (pc_cur_if)
//   );

//   imem u_imem (
//     .pc_cur_if (pc_cur_if),
//     .ins_if    (ins_if)
//   );

//   if_id_reg u_if_id_reg (
//     .clk       (clk),
//     .rst_n     (rst_n),
//     .stall     (stall),
//     .flush     (flush),
//     .ins_if    (ins_if),
//     .pc4_if    (pc4_if),
//     .pc_cur_if (pc_cur_if),
//     .ins_id    (ins_id),
//     .pc4_id    (pc4_id),
//     .pc_cur_id (pc_cur_id)
//   );

//   // ------------------------------------------------------------------
//   // 5. Task nạp sẵn nội dung imem — CẦN SỬA LẠI theo đúng cách RTL
//   //    imem của em cho phép ghi từ bên ngoài. 2 cách phổ biến:
//   //      a) imem có sẵn task/function load, hoặc cổng ghi test-only
//   //      b) poke thẳng qua hierarchical path: u_imem.mem[addr] = data;
//   //    Dưới đây dùng cách (b) làm ví dụ — đổi tên mảng cho khớp RTL thật.
//   // ------------------------------------------------------------------
//   task automatic load_imem(int addr_word, logic [31:0] data);
//     u_imem.mem[addr_word] = data;   // TODO: đổi "mem" cho đúng tên mảng trong imem.sv
//   endtask

//   // ------------------------------------------------------------------
//   // 6. Checker dùng chung cho mọi task test — thay cho compare() bên OOP.
//   // ------------------------------------------------------------------
//   task automatic check(string name, logic [31:0] actual, logic [31:0] expected);
//     if (actual !== expected) begin
//       fail_cnt++;
//       $error("[FAIL] %s: actual=%0h expected=%0h", name, actual, expected);
//     end else begin
//       pass_cnt++;
//       $display("[PASS] %s: %0h", name, actual);
//     end
//   endtask

//   // ------------------------------------------------------------------
//   // 7. Task khởi tạo control mặc định — gọi ở đầu mỗi test case để
//   //    đảm bảo test trước không để lại tín hiệu rác ảnh hưởng test sau.
//   //    (thói quen bắt buộc trong directed test vì không có Generator
//   //    tự random lại từ đầu mỗi lần).
//   // ------------------------------------------------------------------
//   task automatic idle_control();
//     br_taken_id = 0;
//     br_en_id    = 0;
//     jal_id      = 0;
//     jalr_id     = 0;
//     pc_jump     = '0;
//     stall_pc    = 0;
//     stall       = 0;
//     flush       = 0;
//   endtask

//   // ==================================================================
//   // 8. CÁC TEST CASE DIRECTED — mỗi task = 1 kịch bản cụ thể, tự tính
//   //    tay expected value rồi gọi check(). Đây là phần em sẽ viết
//   //    tương tự cho các stage còn lại: liệt kê hết case quan trọng
//   //    của cụm module đó, mỗi case 1 task riêng, dễ đọc dễ debug.
//   // ==================================================================

//   // Case 1 — sau reset, pc_cur_if phải về 0
//   task automatic test_reset();
//     idle_control();
//     @(posedge clk);
//     #1;  // chờ 1 chút để tín hiệu ổn định sau cạnh clock
//     check("reset: pc_cur_if=0", pc_cur_if, 32'h0);
//   endtask

//   // Case 2 — fetch tuần tự bình thường: không branch, không stall,
//   // pc phải tăng đều +4 mỗi chu kỳ, pc4_if = pc_cur_if + 4
//   task automatic test_sequential_fetch();
//     idle_control();
//     load_imem(0, 32'h00000013); // NOP tại addr 0
//     load_imem(1, 32'h00100093); // ví dụ addi x1,x0,1 tại addr 4 (word index 1)
    

//     @(posedge clk); #1;
//     check("seq: pc4_if = pc_cur_if+4", pc4_if, pc_cur_if + 32'd4);

//     @(posedge clk); #1;
//     check("seq: pc_cur_if tang 4", pc_cur_if, 32'd4);
//   endtask

//   // Case 3 — stall_pc=1: pc phải GIỮ NGUYÊN, không tăng, dù pc_next_if
//   // vẫn đang là pc4_if bình thường ở input
//   task automatic test_stall_pc();
//     logic [31:0] pc_before;
//     idle_control();
//     pc_before = pc_cur_if;

//     stall_pc = 1;
//     @(posedge clk); #1;
//     check("stall_pc: pc khong doi", pc_cur_if, pc_before);

//     stall_pc = 0;   // thả stall để test sau không bị ảnh hưởng
//   endtask

//   // Case 4 — branch taken: br_taken_id=1, br_en_id=1 -> pc_next_if
//   // phải chọn pc_jump, KHÔNG phải pc4_if  
//   task automatic test_branch_taken();
//     idle_control();
//     pc_jump     = 32'h0000_1000;
//     br_taken_id = 1;
//     br_en_id    = 1;

//     #1; // pc_mux là combinational, không cần chờ clock để check pc_next_if
//     check("branch: pc_next_if = pc_jump", pc_next_if, pc_jump);

//     @(posedge clk); #1;
//     check("branch: pc_cur_if nhay toi pc_jump", pc_cur_if, pc_jump);

//     idle_control();
//   endtask

//   // Case 5 — jal: jal_id=1 -> pc_mux cũng phải chọn pc_jump giống branch,
//   // tách riêng vì đây là 2 điều kiện khác nhau trong logic pc_mux,
//   // cần test độc lập để chắc chắn cả 2 nhánh code đều đúng
//   task automatic test_jal();
//     idle_control();
//     pc_jump = 32'h0000_2000;
//     jal_id  = 1;

//     #1;
//     check("jal: pc_next_if = pc_jump", pc_next_if, pc_jump);

//     idle_control();
//   endtask

//   // Case 6 — jalr: jalr_id=1, tương tự jal nhưng địa chỉ đích tính
//   // từ thanh ghi + immediate (đã cộng sẵn ở bên ngoài, pc_mux chỉ
//   // chọn lại pc_jump y hệt jal/branch)
//   task automatic test_jalr();
//     idle_control();
//     pc_jump = 32'h0000_3000;
//     jalr_id = 1;

//     #1;
//     check("jalr: pc_next_if = pc_jump", pc_next_if, pc_jump);

//     idle_control();
//   endtask

//   // Case 7 — if_id_reg stall=1: ins_id/pc4_id/pc_cur_id phải GIỮ
//   // NGUYÊN giá trị cũ, không latch giá trị mới từ ins_if
//   task automatic test_ifid_stall();
//     logic [31:0] ins_id_before, pc4_id_before, pc_cur_id_before;
//     idle_control();

//     @(posedge clk); #1;
//     ins_id_before     = ins_id;
//     pc4_id_before      = pc4_id;
//     pc_cur_id_before   = pc_cur_id;

//     stall = 1;
//     @(posedge clk); #1;
//     check("ifid stall: ins_id khong doi",    ins_id,    ins_id_before);
//     check("ifid stall: pc4_id khong doi",    pc4_id,    pc4_id_before);
//     check("ifid stall: pc_cur_id khong doi", pc_cur_id, pc_cur_id_before);

//     stall = 0;
//   endtask

//   // Case 8 — if_id_reg flush=1 (không stall): ins_id phải bị ép về
//   // NOP (32'h00000013), đây là case dùng khi hazard/branch mispredict
//   // cần xóa instruction sai trong pipeline
//   task automatic test_ifid_flush();
//     idle_control();
//     flush = 1;
//     @(posedge clk); #1;
//     check("ifid flush: ins_id = NOP", ins_id, 32'h00000013);
//     flush = 0;
//   endtask

//   // ------------------------------------------------------------------
//   // Case 9 — CORNER CASE quan trọng nhất: stall=1 VÀ flush=1 xảy ra
//   // CÙNG LÚC. Theo đúng rule em đã chốt khi review RTL trước đây —
//   // "flush_ifid phải gate bởi !stall" — nghĩa là khi cả 2 cùng bật,
//   // stall phải THẮNG, ins_id phải GIỮ NGUYÊN (không bị flush thành NOP).
//   // Đây chính là case dễ bị code sai nhất nếu viết nhầm thứ tự if/else
//   // trong RTL (flush check trước stall thay vì ngược lại).
//   // ------------------------------------------------------------------
//   task automatic test_ifid_stall_flush_priority();
//     logic [31:0] ins_id_before;
//     idle_control();

//     @(posedge clk); #1;
//     ins_id_before = ins_id;

//     stall = 1;
//     flush = 1;
//     @(posedge clk); #1;
//     check("stall+flush: stall phai thang, ins_id khong doi", ins_id, ins_id_before);

//     idle_control(); 
//   endtask

//   // ==================================================================
//   // 9. Điều phối chạy toàn bộ test case theo thứ tự, in báo cáo cuối.
//   //    Đây là phần thay thế cho Test class bên OOP — nhưng ở mức
//   //    directed chỉ cần gọi task tuần tự, không cần build Env.
//   // ==================================================================
//   initial begin
//     wait (rst_n == 1);

//     test_reset();
//     test_sequential_fetch();
//     test_stall_pc();
//     test_branch_taken();
//     test_jal();
//     test_jalr();
//     test_ifid_stall();
//     test_ifid_flush();
//     test_ifid_stall_flush_priority();

//     $display("========================================");
//     $display("[TB_IF_STAGE] PASS = %0d, FAIL = %0d", pass_cnt, fail_cnt);
//     $display("========================================");
//     $finish;
//   end

//   // Timeout bảo vệ — tránh treo simulation nếu 1 task nào đó chờ mãi
//   initial begin
//     #10000;
//     $display("[TB_IF_STAGE] Timeout - ket thuc simulation");
//     $finish;
//   end

// endmodule













// =============================================================
// tb_if_stage_top.sv
// Directed testbench cho MODULE if_stage (đã đóng gói sẵn) +
// if_id_reg (đứng ngoài, thuộc controlpath, không nằm trong if_stage).
//
// Khác biệt so với bản cũ (tb_if_stage.sv test rời từng module con):
//  - Chỉ instance if_stage (1 dòng) thay vì 4 module con
//  - KHÔNG còn thấy pc_next_if nữa (đã bị chôn bên trong if_stage) 
//    -> mọi check liên quan branch/jal/jalr phải chờ 1 clock rồi
//       nhìn pc_cur_if, không check combinational tức thời được nữa
//  - load_imem phải trỏ qua thêm 1 cấp hierarchy: u_if_stage.u_imem.mem
// =============================================================

`timescale 1ns/1ps

module tb_if_stage_top;
  import core_pkg::*;

  // ------------------------------------------------------------------
  // 1. Khai báo tín hiệu — LẤY ĐÚNG PORT của if_stage (chỉ port này,
  //    không quan tâm bên trong nó có gì).
  // ------------------------------------------------------------------
  logic clk, rst_n, stall_pc;

  logic              br_taken_id, br_en_id, jal_id, jalr_id;
  logic [XLEN-1:0]   pc_jump_id;

  logic [XLEN-1:0]   pc_cur_if;
  logic [XLEN-1:0]   pc4_if;
  logic [XLEN-1:0]   ins;

  // if_id_reg đứng NGOÀI if_stage (không nằm trong module bạn đưa),
  // nên vẫn phải khai báo + instance riêng ở đây nếu muốn test luôn
  // cụm pipeline register cùng lúc.
  logic        stall, flush;
  logic [31:0] ins_id, pc4_id, pc_cur_id;

  int pass_cnt = 0;
  int fail_cnt = 0;

  // ------------------------------------------------------------------
  // 2. Clock / reset — không đổi
  // ------------------------------------------------------------------
  always #5 clk = ~clk;

  initial begin
    clk   = 0;
    rst_n = 0;
    #20 rst_n = 1;
  end

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_if_stage_top);
  end

  // ------------------------------------------------------------------
  // 3. Instance if_stage — CHỈ 1 DÒNG, khớp đúng port module bạn gửi
  // ------------------------------------------------------------------
  if_stage u_if_stage (
    .clk         (clk),
    .rst_n       (rst_n),
    .stall_pc    (stall_pc),
    .br_taken_id (br_taken_id),
    .br_en_id    (br_en_id),
    .jal_id      (jal_id),
    .jalr_id     (jalr_id),
    .pc_jump_id  (pc_jump_id),
    .pc_cur_if   (pc_cur_if),
    .pc4_if      (pc4_if),
    .ins         (ins)
  );

  // if_id_reg vẫn instance riêng như cũ, vì nó KHÔNG nằm trong if_stage
  if_id_reg u_if_id_reg (
    .clk       (clk),
    .rst_n     (rst_n),
    .stall     (stall),
    .flush     (flush),
    .ins_if    (ins),        // lấy output "ins" của if_stage làm input
    .pc4_if    (pc4_if),
    .pc_cur_if (pc_cur_if),
    .ins_id    (ins_id),
    .pc4_id    (pc4_id),
    .pc_cur_id (pc_cur_id)
  );

  // ------------------------------------------------------------------
  // 4. load_imem — path bây giờ SÂU HƠN 1 cấp vì imem nằm trong if_stage
  // ------------------------------------------------------------------
  task automatic load_imem(int addr_word, logic [31:0] data);
    u_if_stage.u_imem.mem[addr_word] = data;
  endtask

  // ------------------------------------------------------------------
  // 5. Checker — không đổi
  // actual là giá trị DUT tính ra dc 
  // expexted là giá trị đúng 
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

  task automatic idle_control();
    br_taken_id = 0;
    br_en_id    = 0;
    jal_id      = 0;
    jalr_id     = 0;
    pc_jump_id  = '0;
    stall_pc    = 0;
    stall       = 0;
    flush       = 0;
  endtask

  // ==================================================================
  // 6. TEST CASE — logic giữ nguyên ý tưởng, nhưng case 4/5/6
  //    (branch/jal/jalr) PHẢI SỬA vì pc_next_if không còn lộ ra ngoài.
  // ==================================================================

  task automatic test_reset();
    idle_control();
    @(posedge clk); #1;
    check("reset: pc_cur_if=0", pc_cur_if, 32'h0);
  endtask

  task automatic test_sequential_fetch();
    idle_control();
    load_imem(0, 32'h00000013);
    load_imem(1, 32'h00100093);

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

    stall_pc = 0;
  endtask

  // Case 4 — SỬA: không còn check pc_next_if combinational nữa,
  // chỉ chờ 1 clock rồi check pc_cur_if đã nhảy đúng pc_jump_id chưa
  task automatic test_branch_taken();
    idle_control();
    pc_jump_id  = 32'h0000_1000;
    br_taken_id = 1;
    br_en_id    = 1;

    @(posedge clk); #1;
    check("branch: pc_cur_if nhay toi pc_jump_id", pc_cur_if, 32'h0000_1000);

    idle_control();
  endtask

  task automatic test_jal();
    idle_control();
    pc_jump_id = 32'h0000_2000;
    jal_id     = 1;

    @(posedge clk); #1;
    check("jal: pc_cur_if nhay toi pc_jump_id", pc_cur_if, 32'h0000_2000);

    idle_control();
  endtask

  task automatic test_jalr();
    idle_control();
    pc_jump_id = 32'h0000_3000;
    jalr_id    = 1;

    @(posedge clk); #1;
    check("jalr: pc_cur_if nhay toi pc_jump_id", pc_cur_if, 32'h0000_3000);

    idle_control();
  endtask

  task automatic test_ifid_stall();
    logic [31:0] ins_id_before, pc4_id_before, pc_cur_id_before;
    idle_control();

    @(posedge clk); #1;
    ins_id_before    = ins_id;
    pc4_id_before    = pc4_id;
    pc_cur_id_before = pc_cur_id;

    stall = 1;
    @(posedge clk); #1;
    check("ifid stall: ins_id khong doi",    ins_id,    ins_id_before);
    check("ifid stall: pc4_id khong doi",    pc4_id,    pc4_id_before);
    check("ifid stall: pc_cur_id khong doi", pc_cur_id, pc_cur_id_before);

    stall = 0;
  endtask

  task automatic test_ifid_flush();
    idle_control();
    flush = 1;
    @(posedge clk); #1;
    check("ifid flush: ins_id = NOP", ins_id, 32'h00000013);
    flush = 0;
  endtask

  task automatic test_ifid_stall_flush_priority();
    logic [31:0] ins_id_before;
    idle_control();

    @(posedge clk); #1;
    ins_id_before = ins_id;

    stall = 1;
    flush = 1;
    @(posedge clk); #1;
    check("stall+flush: stall phai thang, ins_id khong doi", ins_id, ins_id_before);

    idle_control();
  endtask

  // ==================================================================
  // 7. Điều phối chạy
  // ==================================================================
  initial begin
    wait (rst_n == 1);

    test_reset();
    test_sequential_fetch();
    test_stall_pc();
    test_branch_taken();
    test_jal();
    test_jalr();
    test_ifid_stall();
    test_ifid_flush();
    test_ifid_stall_flush_priority();

    $display("========================================");
    $display("[TB_IF_STAGE_TOP] PASS = %0d, FAIL = %0d", pass_cnt, fail_cnt);
    $display("========================================");
    $finish;
  end

  initial begin
    #10000;
    $display("[TB_IF_STAGE_TOP] Timeout - ket thuc simulation");
    $finish;
  end

endmodule

