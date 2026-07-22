module tb_top;

  // 1. Sinh clock, reset
  logic clk = 0;
  logic rst_n;
  always #5 clk = ~clk;

  initial begin
    rst_n = 0;
    #20 rst_n = 1;
  end

  // 2. TẠO instance của interface (đây là "khai báo interface" bạn hỏi)
  regfile_if vif (.clk(clk), .rst_n(rst_n));

  // 3. GHÉP NỐI: khởi tạo DUT, nối từng chân DUT vào từng dây trong vif
  regfile dut (
    .clk         (clk),
    .rst_n       (rst_n),
    .rs1_addr_id (vif.rs1_addr_id),
    .rs2_addr_id (vif.rs2_addr_id),
    .reg_en_wb   (vif.reg_en_wb),
    .rd_addr_wb  (vif.rd_addr_wb),
    .rd_data_wb  (vif.rd_data_wb),
    .rs1_data_id (vif.rs1_data_id),
    .rs2_data_id (vif.rs2_data_id)
  );

  // 4. Test đơn giản, không qua agent/env — chỉ để minh họa
  initial begin
    regfile_driver  drv;
    regfile_monitor mon;
    mailbox #(regfile_transaction) gen2drv = new();
    mailbox #(regfile_transaction) drv2rm  = new();
    mailbox #(regfile_transaction) mon2sb  = new();
    mailbox #(regfile_transaction) mon2cov = new();

    drv = new(vif.DRV, gen2drv, drv2rm);
    mon = new(vif.MON, mon2sb, mon2cov);

    fork
      drv.run();
      mon.run();
    join_none

    rgb(240, 255, 108);
    $finish;
  end

endmodule