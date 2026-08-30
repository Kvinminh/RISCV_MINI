`timescale 1ns/1ps

// Pipeline waveform demo.  The program deliberately exercises:
//   1. EX forwarding: x7 <- x6 + 5, then x28 <- x7 + x6
//   2. Load-use hazard: lw x29, then addi x30, x29, 1
//   3. Early branch in ID: beq x31, x8 skips the 'X' UART write
// The expected UART byte is 'P'.
module tb_top;
    localparam time CLK_PERIOD = 10ns;
    localparam int  RESET_CYCLES = 5;
    localparam int  TIMEOUT_CYCLES = 300;

    logic clk;
    logic rst_n;
    int cycle_count;

    top_rtl dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // -----------------------------------------------------------------
    // Waveform probes.  These readable names appear directly in GTKWave.
    // -----------------------------------------------------------------
    logic [31:0] pc_if;
    logic [31:0] instr_if;
    logic [31:0] instr_id;
    logic [31:0] alu_ex;
    logic [31:0] alu_mem;
    logic [31:0] alu_wb;
    logic        stall_pc;
    logic        stall_if_id;
    logic        flush_if_id;
    logic        flush_id_ex;
    logic        branch_enable;
    logic        branch_taken;
    logic [31:0] branch_target;
    logic [1:0]  forward_id_a;
    logic [1:0]  forward_id_b;
    logic [1:0]  forward_ex_a;
    logic [1:0]  forward_ex_b;
    logic        uart_valid;
    logic [7:0]  uart_data;
    logic [31:0] x6_t1;
    logic [31:0] x7_t2;
    logic [31:0] x28_t3;
    logic [31:0] x29_t4;
    logic [31:0] x30_t5;

    assign pc_if         = dut.if_reg.pc_cur;
    assign instr_if      = dut.if_reg.ins;
    assign instr_id      = dut.reg_id.ins;
    assign alu_ex        = dut.alu_ex_val;
    assign alu_mem       = dut.alu_mem_val;
    assign alu_wb        = dut.alu_wb_val;
    assign stall_pc      = dut.hzd_ctrl.stall_pc;
    assign stall_if_id   = dut.hzd_ctrl.stall_if_id;
    assign flush_if_id   = dut.hzd_ctrl.flush_if_id;
    assign flush_id_ex   = dut.hzd_ctrl.flush_id_ex;
    assign branch_enable = dut.jump_id_if.br_en;
    assign branch_taken  = dut.jump_id_if.br_taken;
    assign branch_target = dut.jump_id_if.jump_addr;
    assign forward_id_a  = dut.u_id_stage.for_id_a;
    assign forward_id_b  = dut.u_id_stage.for_id_b;
    assign forward_ex_a  = dut.u_ex_stage.for_ex_a;
    assign forward_ex_b  = dut.u_ex_stage.for_ex_b;
    assign uart_valid    = dut.u_uart.tx_valid_i;
    assign uart_data     = dut.u_uart.tx_data_i;
    assign x6_t1         = dut.u_id_stage.u_regfile.mem_reg[6];
    assign x7_t2         = dut.u_id_stage.u_regfile.mem_reg[7];
    assign x28_t3        = dut.u_id_stage.u_regfile.mem_reg[28];
    assign x29_t4        = dut.u_id_stage.u_regfile.mem_reg[29];
    assign x30_t5        = dut.u_id_stage.u_regfile.mem_reg[30];

    initial clk = 1'b0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        $dumpfile("pipeline_demo.vcd");
        $dumpvars(0, tb_top);

        rst_n = 1'b0;
        cycle_count = 0;

        // Override IMEM's default time-zero image.
        #1;
        $readmemh("program_pipeline_demo.mem", dut.u_imem.memory);

        repeat (RESET_CYCLES) @(posedge clk);
        rst_n = 1'b1;
    end

    always @(posedge clk) begin
        if (!rst_n)
            cycle_count <= 0;
        else begin
            cycle_count <= cycle_count + 1;

            if (uart_valid) begin
                if (uart_data !== "P")
                    $fatal(1, "[TB][FAIL] Branch was not taken: UART sent 0x%02h", uart_data);

                if (x6_t1 !== 32'd10 || x7_t2 !== 32'd15 || x28_t3 !== 32'd25 ||
                    x29_t4 !== 32'd25 || x30_t5 !== 32'd26)
                    $fatal(1, "[TB][FAIL] Forward/hazard result mismatch");

                $display("\n[TB][PASS] Pipeline hazard, forwarding, and early branch demo passed.");
                $finish;
            end

            if (cycle_count >= TIMEOUT_CYCLES)
                $fatal(1, "[TB][FAIL] Timeout after %0d cycles", TIMEOUT_CYCLES);
        end
    end
endmodule
