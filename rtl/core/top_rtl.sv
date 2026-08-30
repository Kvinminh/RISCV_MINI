`timescale 1ns/1ps

module top_rtl
    import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;
(
    input logic clk,
    input logic rst_n
);

    //=========================================================
    // Internal signals
    //=========================================================

    // --------------------------------------------------------
    // IF
    // --------------------------------------------------------
    logic       stall_pc;
    jump_t      jump_id_if;
    if_id_reg_t if_reg;

    // --------------------------------------------------------
    // IF/ID
    // --------------------------------------------------------
    if_id_reg_t reg_id;

    // --------------------------------------------------------
    // Hazard
    // --------------------------------------------------------
    hzd_ctrl_t hzd_ctrl;

    // --------------------------------------------------------
    // ID
    // --------------------------------------------------------
    regfile_wb regfile_wb_id;

    // Information for forwarding / hazard
    // Instruction currently in EX
    for_info_t ex_id;

    // Instruction currently in MEM
    for_info_t mem2id_ex;

    // ALU results used for forwarding
    logic [XLEN-1:0] alu_ex_val;
    logic [XLEN-1:0] alu_mem_val;
    logic [XLEN-1:0] alu_wb_val;

    id_ex_reg_t id_reg;

    // --------------------------------------------------------
    // ID/EX
    // --------------------------------------------------------
    id_ex_reg_t reg_ex;

    // --------------------------------------------------------
    // EX
    // --------------------------------------------------------
    for_info_t wb_ex;

    ex_mem_reg_t ex_reg;

    // --------------------------------------------------------
    // EX/MEM
    // --------------------------------------------------------
    ex_mem_reg_t reg_mem;

    // --------------------------------------------------------
    // MEM
    // --------------------------------------------------------
    mem_wb_reg_t mem_reg;

    // Device select
    dev_sel_e mem_dev_sel;

    // SRAM interface
    logic [31:0] sram_rdata;
    logic [31:0] sram_wdata;
    logic [3:0]  sram_mask;
    logic        sram_we;

    // UART interface
    logic [31:0] uart_rdata;
    logic [7:0]  uart_tx_data;
    logic        uart_tx_valid;

    // --------------------------------------------------------
    // MEM/WB
    // --------------------------------------------------------
    mem_wb_reg_t reg_wb;


    //=========================================================
    // 1. IF STAGE
    //=========================================================
    logic [XLEN-1:0] ins;
    imem u_imem(
        .pc_cur_i(if_reg.pc_cur),
        .ins_o(ins)
    );

    if_stage u_if_stage (
    .clk           (clk),
    .rst_n         (rst_n),
    .stall_pc_i    (stall_pc),
    .jump_id_i     (jump_id_if),
      
    .ins_i  (ins),  
    .if_reg_o      (if_reg)
);
    //=========================================================
    // 2. IF/ID PIPELINE REGISTER
    //=========================================================

    if_id_reg u_if_reg_id_reg (
        .clk           (clk),
        .rst_n         (rst_n),

        .flush_if_id_i (hzd_ctrl.flush_if_id),
        .stall_if_id_i (hzd_ctrl.stall_if_id),

        .if_reg_i      (if_reg),
        .id_reg_o      (reg_id)
    );


    // PC stall comes from hazard unit
    assign stall_pc = hzd_ctrl.stall_pc;


    //=========================================================
    // 3. ID STAGE
    //=========================================================

    id_stage u_id_stage (
        .clk            (clk),
        .rst_n          (rst_n),

        .reg_id_i       (reg_id),

        // WB -> ID register-file write / bypass
        .wb_i           (regfile_wb_id),

        // Forwarding information
        .for_info_ex_i  (ex_id),
        .for_info_mem_i (mem2id_ex),

        // Forwarded ALU values
        .alu_ex_i       (alu_ex_val),
        .alu_mem_i      (alu_mem_val),

        // Branch / jump
        .jump_o         (jump_id_if),

        // Hazard control
        .hzd_ctrl_o     (hzd_ctrl),

        // ID -> ID/EX
        .id_reg_i       (id_reg)
    );


    //=========================================================
    // 4. ID/EX PIPELINE REGISTER
    //=========================================================

    id_ex_reg u_id_ex_reg (
        .clk         (clk),
        .rst_n       (rst_n),

        .id_ex_flush (hzd_ctrl.flush_id_ex),

        .id_reg_i    (id_reg),
        .ex_reg_o    (reg_ex)
    );


    //=========================================================
    // 5. EX INFORMATION -> ID
    //=========================================================
    //
    // reg_ex = instruction currently in EX
    //
    // ID needs this information for:
    //   - load-use hazard
    //   - EX forwarding
    //
    //=========================================================

    always_comb begin
        ex_id = '0;

        ex_id.rd_addr = reg_ex.rd_addr;
        ex_id.mem_re  = reg_ex.mem_ctrl.dmem_re;
        ex_id.reg_en  = reg_ex.wb_ctrl.reg_en;
    end


    //=========================================================
    // 6. EX STAGE
    //=========================================================

    ex_stage u_ex_stage (
        .reg_ex_i       (reg_ex),

        // Forwarding information
        .for_info_mem_i (mem2id_ex),
        .for_info_wb_i  (wb_ex),

        // Forwarded ALU results
        .alu_mem_i      (alu_mem_val),
        .alu_wb_i       (alu_wb_val),

        // EX -> EX/MEM
        .ex_reg_o       (ex_reg)
    );


    // ALU result of instruction currently in EX
    assign alu_ex_val = ex_reg.alu;


    //=========================================================
    // 7. EX/MEM PIPELINE REGISTER
    //=========================================================

    ex_mem_reg u_ex_mem_reg (
        .clk   (clk),
        .rst_n (rst_n),

        .reg_i (ex_reg),
        .reg_o (reg_mem)
    );


    //=========================================================
    // 8. MEM STAGE
    //=========================================================

    mem_stage u_mem_stage (
        //.clk             (clk),

        // EX/MEM -> MEM
        .reg_mem_i       (reg_mem),

        // Memory read data
        .sram_rdata_i    (sram_rdata),
        .uart_rdata_i    (uart_rdata),

        // MEM -> MEM/WB
        .mem_reg_o       (mem_reg),
        .dev_sel_o(mem_dev_sel),

        // MEM forwarding information
        .for_mem_reg_o   (mem2id_ex),

        // SRAM write interface
        .sram_wdata_o    (sram_wdata),
        .sram_mask_o     (sram_mask),
        .sram_we_o       (sram_we),

        // UART TX interface
        .uart_tx_data_o  (uart_tx_data),
        .uart_tx_valid_o (uart_tx_valid)
    );


    // ALU result of instruction currently in MEM
    assign alu_mem_val = mem_reg.alu_result;


   //=========================================================
// 9. IMEM PERIPHERAL
//=========================================================


//=========================================================
// 10. SRAM PERIPHERAL && UART
//=========================================================

    sram u_sram (
        .clk          (clk),

        .addr         (reg_mem.alu),
        .dev_sel_i (mem_dev_sel),
        .sram_wdata_i (sram_wdata),
        .sram_mask_i  (sram_mask),
        .sram_we_i    (sram_we),

        .rdata_o      (sram_rdata)
    );

    uart u_uart (
        .clk          (clk),

        .tx_data_i    (uart_tx_data),
        .tx_valid_i   (uart_tx_valid),

        .uart_rdata_o (uart_rdata)
    );

    //=========================================================
    // 11. MEM/WB PIPELINE REGISTER
    //=========================================================

    mem_wb_reg u_mem_wb_reg (
        .clk   (clk),
        .rst_n (rst_n),

        .reg_i (mem_reg),
        .reg_o (reg_wb)
    );


    //=========================================================
    // 12. WB STAGE
    //=========================================================

    wb_stage u_wb_stage (
        .wb_i (reg_wb),
        .wb_o (regfile_wb_id)
    );


    //=========================================================
    // 13. WB -> EX FORWARDING  
    //=========================================================

    assign wb_ex.rd_addr = regfile_wb_id.rd_addr;
    assign wb_ex.reg_en  = regfile_wb_id.reg_en;

    // WB instruction is no longer a load
    assign wb_ex.mem_re  = 1'b0;

    assign alu_wb_val = regfile_wb_id.rd_data;


endmodule
