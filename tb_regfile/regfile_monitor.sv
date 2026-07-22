class regfile_monitor;

    virtual regfile_if.MON vif;
    mailbox #(regfile_transaction) mon2sb;
    mailbox #(regfile_transaction) mon2cov;

    function  new(virtual regfile_if.MON vif,
                 mailbox #(regfile_transaction) mon2sb
                mailbox #(regfile_transaction) mon2cov);
        this.vif = vif;
        this.mon2sb = mon2sb;
        this.mon2cov = mon2cov;
    endfunction

    task run();
        regfile_transaction txn;
        forever begin
            @(vif.mon_cb);

            txn = new();
            txn.rs1_addr = vif.mon_cb.rs1_addr;
            txn.rs2_addr = vif.mon_cb.rs2_addr;
            txn.reg_en   = vif.mon_cb.reg_en;
            txn.rd_addr  = vif.mon_cb.rd_addr;
            txn.rd_data  = vif.mon_cb.rd_data;
            txn.rs1_data = vif.mon_cb.rs1_data;  // giá trị THẬT DUT xuất ra
            txn.rs2_data = vif.mon_cb.rs2_data;  // giá trị THẬT DUT xuất ra

            mon2sv.put(txn.copy());
            mon2cov.put(txn.copy());
        end
    endtask

endclass