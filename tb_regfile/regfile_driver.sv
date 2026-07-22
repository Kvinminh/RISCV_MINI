class regfile_driver;

//1 gọi modporrt trong interface 
virtual regfile_if.DRV vif;   
//2 nhận mailbox từ gểnator ( nhận transaction từ generator)
mailbox #(regfile_transaction) gen2drv;
//3 tạo 1 mailbox dùng để chuyển cho monitor
mailbox #(regfile_transaction) drv2m;

//4 tạo contructor  khỏi tạo object ( là giá trị khi class này new())
// nhưng do là data đã dc tạo ra từ class khác nên chỉ cần hanđle rồi  gán vào class khi new
function new(virtual regfile_if.DRV vif,
             mailbox #(regfile_transaction) gen2drv,
             mailbox #(regfile_transaction) drv2m);
    this.vif = vif;
    this.gen2drv = gen2drv;
    this.drv2m = drv2m;
endfunction

task reset_dut();
    vif.drv_cb.rs1_addr_id <= '0;
    vif.drv_cb.rs2_addr_id <= '0;
    vif.drv_cb.reg_en_wb   <= '0;
    vif.drv_cb.rd_addr_wb  <= '0;
    vif.drv_cb.rd_data_wb  <= '0;
    repeat (3) @(vif.drv_cb);
  endtask


task run();
    regfile_transaction txn;
    forever begin
      gen2drv.get(txn); // get dùng để láy itme ra khỏi mailbox 
                        // sau khi lấy item ra thì ko còn trong mailbox nữa

      // Lái qua clocking block (output #1) -> tự động đúng timing,
      // không cần tự tính delay bằng tay.
      vif.drv_cb.rs1_addr_id <= txn.rs1_addr_id;
      vif.drv_cb.rs2_addr_id <= txn.rs2_addr_id;
      vif.drv_cb.reg_en_wb   <= txn.reg_en_wb;
      vif.drv_cb.rd_addr_wb <= txn.rd_addr_wb;
      vif.drv_cb.rd_data_wb  <= txn.rd_data_wb;

      @(vif.drv_cb);   // chờ đúng 1 chu kỳ clock để DUT lấy mẫu tín hiệu này

      drv2m.put(txn.copy());  //put là đặt item vào mailbox để truyền cho monitor chứ còn j nữa
                             
    end
  endtask

endclass