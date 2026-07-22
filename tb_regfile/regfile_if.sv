interface regfile_if(input logic clk, input logic rst_n);
    //input
    logic [4:0] rs1_addr_id;
    logic [4:0] rs2_addr_id;
    logic                  reg_en_wb;
    logic [4:0] rd_addr_wb;
    logic [31:0] rd_data_wb;
    // output
    logic [31:0] rs1_data_id;
    logic [31:0] rs2_data_id;



    clocking drv_cb @(posedge clk);
    default: input #1step output #1;
    output  rs1_addr_id,
            rs2_addr_id,
            reg_en_wb,
            rd_addr_wb,
            rd_data_wb;
    endclocking

    clocking mon_cb @(posedge clk);
    default: input #1step output #1;
    input   rs1_addr_id,
            rs2_addr_id,
            reg_en_wb,
            rd_addr_wb,
            rd_data_wb,
            rs1_data_id,
            rs2_data_id;
    endclocking

modport DRV ( clocking drv_cb, input clk , input rst_n);
modport MON ( clocking mon_cb, input clk , input rst_n);

endinterface //regfile