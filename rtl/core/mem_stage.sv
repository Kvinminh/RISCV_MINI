module mem_stage
    import core_pkg::*;
    import ctrl_pkg::*;
    import isa_pkg::*;
(
    //input  logic         clk,
    input  ex_mem_reg_t  reg_mem_i,

    // Read data từ memory/peripheral bên ngoài
    input  logic [31:0]  sram_rdata_i,
    input  logic [31:0]  uart_rdata_i,
    
    output  dev_sel_e    dev_sel_o,

    output mem_wb_reg_t  mem_reg_o,
    output for_info_t    for_mem_reg_o,

    // Store outputs
    output logic [31:0]  sram_wdata_o,
    output logic [3:0]   sram_mask_o,
    output logic         sram_we_o,
    output logic [7:0]   uart_tx_data_o,
    output logic         uart_tx_valid_o
);

    dev_sel_e dev_sel;
    logic [3:0] mask;

    logic [31:0] mem_rdata_raw;
    logic [31:0] mem_rdata;


    // =========================================================
    // 1. Address Decoder
    // =========================================================
    addres_decodet u_addres_decodet (
        .alu_result_i (reg_mem_i.alu),
        .mem_re       (reg_mem_i.mem_ctrl.dmem_re),
        .mem_wri      (reg_mem_i.mem_ctrl.dmem_wri),
        .dev_sel_o    (dev_sel)
    );


    // =========================================================
    // 2. LSU Ctrl
    // =========================================================
    lsu_ctrl u_lsu_ctrl (
        .f3_mem_i     (reg_mem_i.f3),
        .alu_result_i (reg_mem_i.alu[1:0]),
        .mask_o       (mask)
    );


    // =========================================================
    // 3. Store Unit
    // =========================================================
    store_unit u_store_unit (
        .rs2_data_i      (reg_mem_i.rs2_data),
        .alu_result_i    (reg_mem_i.alu),
        .mem_wri_i       (reg_mem_i.mem_ctrl.dmem_wri),
        .mask_i          (mask),
        .dev_sel_i       (dev_sel),

        .sram_wdata_o    (sram_wdata_o),
        .sram_mask_o     (sram_mask_o),
        .sram_we_o       (sram_we_o),

        .uart_tx_data_o  (uart_tx_data_o),
        .uart_tx_valid_o (uart_tx_valid_o)
    );


    // =========================================================
    // 4. Read Data Mux
    // =========================================================
    read_data_mux u_read_data_mux (
        .sram_rdata_i    (sram_rdata_i),
        .uart_rdata_i    (uart_rdata_i),
        .dev_sel_i       (dev_sel),
        .mem_rdata_raw_o (mem_rdata_raw)
    );


    // =========================================================
    // 5. Load Unit
    // =========================================================
    load_unit u_load_unit (
        .mem_rdata_raw_i (mem_rdata_raw),
        .mask_i          (mask),
        .extension_i     (reg_mem_i.extension),
        .mem_rdata_o     (mem_rdata)
    );


    // =========================================================
    // 6. MEM/WB output
    // =========================================================
    always_comb begin : pack_mem_wb

        mem_reg_o = '0;

        mem_reg_o.pc_4       = reg_mem_i.pc_4;
        mem_reg_o.alu_result = reg_mem_i.alu;
        mem_reg_o.mem_rdata  = mem_rdata;
        mem_reg_o.rd_addr    = reg_mem_i.rd_addr;
        mem_reg_o.wb_ctrl    = reg_mem_i.wb_ctrl;

    end

    assign dev_sel_o = dev_sel;

    // =========================================================
    // 7. Forward information
    // =========================================================
    always_comb begin : pack_for_info

        for_mem_reg_o = '0;

        for_mem_reg_o.rd_addr = reg_mem_i.rd_addr;
        for_mem_reg_o.mem_re  = reg_mem_i.mem_ctrl.dmem_re;
        for_mem_reg_o.reg_en  = reg_mem_i.wb_ctrl.reg_en;

    end

endmodule
