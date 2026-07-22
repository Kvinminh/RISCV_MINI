/* verilator lint_off MODDUP */
module mem_stage
    import core_pkg::*;
    import ctrl_pkg::*;
    import isa_pkg::*;
(
    input  logic         clk,

    // Thanh ghi pipeline EX/MEM đưa vào
    input  ex_mem_reg_t  ex_mem_reg_i,

    // 2 tín hiệu này KHÔNG có trong ex_mem_reg_t hiện tại,
    // cần forward riêng từ ID/EX (hoặc bổ sung field vào ex_mem_reg_t)
    input  i_type_load_f3_e f3_mem_i,
    input  logic             extension_mem_i,

    // Kết quả ra cho thanh ghi MEM/WB
    output mem_wb_reg_t  mem_wb_reg_o
);

    // ------------------------------------------------------------
    // Tín hiệu nội bộ
    // ------------------------------------------------------------
    logic [3:0]   mask;
    dev_sel_e     dev_sel;

    logic [31:0]  sram_wdata;
    logic [3:0]   sram_mask;
    logic         sram_we;
    logic [31:0]  sram_rdata;

    logic [7:0]   uart_tx_data;
    logic         uart_tx_valid;
    logic [31:0]  uart_status_rdata;

    logic [31:0]  mem_rdata_raw;
    logic [31:0]  mem_rdata;

    // ------------------------------------------------------------
    // 1. Giải mã địa chỉ -> chọn thiết bị (SRAM / UART / ...)
    // ------------------------------------------------------------
    addr_deco u_addr_deco (
        .alu_result_mem (ex_mem_reg_i.alu_result),
        .mem_re_mem     (ex_mem_reg_i.mem_ctrl.dmem_re),
        .mem_wri_mem    (ex_mem_reg_i.mem_ctrl.dmem_wri),
        .dev_sel        (dev_sel)
    );

    // ------------------------------------------------------------
    // 2. Sinh mask (byte enable) dựa vào funct3 + 2 bit offset địa chỉ
    // ------------------------------------------------------------
    lsu_ctrl u_lsu_ctrl (
        .f3_mem         (f3_mem_i),
        .alu_result_mem (ex_mem_reg_i.alu_result[1:0]),
        .mask           (mask)
    );

    // ------------------------------------------------------------
    // 3. Store unit: căn chỉnh dữ liệu ghi + định tuyến we/valid
    // ------------------------------------------------------------
    store_unit u_store_unit (
        .rs2_data_mem   (ex_mem_reg_i.rs2_data),
        .f3_mem         (f3_mem_i),
        .alu_result_mem (ex_mem_reg_i.alu_result),
        .mem_wri_mem    (ex_mem_reg_i.mem_ctrl.dmem_wri),
        .mask           (mask),
        .dev_sel        (dev_sel),

        .sram_wdata     (sram_wdata),
        .sram_mask      (sram_mask),
        .sram_we        (sram_we),

        .uart_tx_data   (uart_tx_data),
        .uart_tx_valid  (uart_tx_valid)
    );

    // ------------------------------------------------------------
    // 4. SRAM lý tưởng
    //    (đã sửa: cổng dev_sel của sram_ideal giờ là dev_sel_e, nối thẳng)
    // ------------------------------------------------------------
    sram_ideal #(
        .DEPTH (1024)
    ) u_sram_ideal (
        .clk        (clk),
        .addr       (ex_mem_reg_i.alu_result),
        .sram_wdata (sram_wdata),
        .sram_mask  (sram_mask),
        .sram_we    (sram_we),
        .dev_sel    (dev_sel),
        .rdata      (sram_rdata)
    );

    // ------------------------------------------------------------
    // 5. UART lý tưởng
    // ------------------------------------------------------------
    uart_ideal u_uart_ideal (
        .clk      (clk),
        .tx_data  (uart_tx_data),
        .tx_valid (uart_tx_valid),
        .rdata    (uart_status_rdata)
    );

    // ------------------------------------------------------------
    // 6. Mux chọn dữ liệu đọc thô theo dev_sel
    // ------------------------------------------------------------
    read_data_mux u_read_data_mux (
        .sram_rdata    (sram_rdata),
        .status_rdata  (uart_status_rdata),
        .dev_sel       (dev_sel),
        .mem_rdata_raw (mem_rdata_raw)
    );

    // ------------------------------------------------------------
    // 7. Load unit: căn chỉnh + sign/zero extension
    // ------------------------------------------------------------
    load_unit u_load_unit (
        .mem_rdata_raw (mem_rdata_raw),
        .mask          (mask),
        .extension_mem (extension_mem_i),
        .mem_rdata     (mem_rdata)
    );

    // ------------------------------------------------------------
    // Đóng gói kết quả cho thanh ghi MEM/WB (chưa qua flop ở đây)
    // ------------------------------------------------------------
    always_comb begin
        mem_wb_reg_o.pc_4       = ex_mem_reg_i.pc_4;
        mem_wb_reg_o.alu_result = ex_mem_reg_i.alu_result;
        mem_wb_reg_o.mem_rdata  = mem_rdata;
        mem_wb_reg_o.rd_addr    = ex_mem_reg_i.rd_addr;
        mem_wb_reg_o.wb_ctrl    = ex_mem_reg_i.wb_ctrl;
    end

endmodule
/* verilator lint_on MODDUP */