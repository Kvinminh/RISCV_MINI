class regfile_transaction;

    //input
    rand bit [4:0]  rs1_addr_id;
    rand bit [4:0]  rs2_addr_id;
    rand bit        reg_en_wb;
    rand bit [4:0]  rd_addr_wb;
    rand bit [31:0] rd_data_wb;
    // output
    bit [31:0] rs1_data_id;
    bit [31:0] rs2_data_id;

    constraint c_reg_en_wb_weight {
        reg_en_wb dist {1'b1 := 80,
                        1'b0 := 20};
    }
    
    function void copy( regfile_transantion rhs);
        if(rhs == null) return;
        this.rs1_addr_id = rhs.rs1_addr_id
        this.rs2_addr_id = rhs.rs2_addr_id
        this.reg_en_wb   = rhs.reg_en_wb
        this.rd_addr_wb  = rhs.rd_addr_wb
        this.rd_data_wb  = rhs.rd_data_wb
        this.rs1_data_id = rhs.rs1_data_id
        this.rs2_data_id = rhs.rs2_data_id
    endfunction

    function regfile_transaction clone();
        regfile_transaction t = new();
        t.copy(this);
        retuen t;
    endfunction
    

    function bit compare ( regfile_transaction t);
        return ( this.rs1_data_id === t.rs1_data_id) && ( this.rs2_data_id === t.rs2_data_id);
    endfunction



    function string convert2string();
    return $sformatf(
      "rs1_addr_id=%0d rs2_addr_id=%0d reg_en_wb=%0b rd_addr_wb=%0d rd_data_wb=%0h | rs1_data_id=%0h rs2_data_id=%0h",
      rs1_addr_id, rs2_addr_id, reg_en_wb, rd_addr_wb, rd_data_wb, rs1_data_id, rs2_data_id);
    endfunction

endclass