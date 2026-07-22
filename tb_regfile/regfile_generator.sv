class regfile_generator;
// bản chất là để đóng gói dữ liệu để truyền đi 
// đóng gói data của transaction 

  mailbox #(regfile_transaction) gen2drv;  // hàng đợi FIFO gửi cho Driver
  int   num_txn;                            // số lượng transaction cần sinh
  event done;                               // báo hiệu đã sinh xong hết


// Constructor: nhận mailbox và số lượng transaction từ Agent truyền vào
function new(mailbox #(regfile_transaction) gen2drv, int num_txn);
    this.gen2drv = gen2drv;
    this.num_txn = num_txn;
endfunction


// dùng để random ra data thôi 

task run();
regfile_transaction txn;
repeat(num_txn) begin
    txn = new();
    if ( !txn.randomize()) $fatal(1, "[GEN] Randomize failed");

    gen2drv.put(txn); 
end
-> done;
endtask



task run_x0(int n);
     regfile_transaction txn;
    repeat (n) begin
      txn = new();
      if (!txn.randomize() with { rd_addr == 0; reg_en == 1; })
        $fatal(1, "[GEN] Randomize x0 failed");
      gen2drv.put(txn);
    end
    -> done;
endtask



endclass