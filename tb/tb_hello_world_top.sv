`timescale 1ns/1ps

// Smoke test for the complete CPU.  The test program writes "Hello World!\n"
// to the memory-mapped UART at 0x4000_0000.
module tb_top;
    localparam time CLK_PERIOD = 10ns;
    localparam int  RESET_CYCLES = 5;
    localparam int  TIMEOUT_CYCLES = 300;
    localparam string EXPECTED = "Hello World!\n";

    logic clk;
    logic rst_n;
    int cycle_count;
    int char_index;

    top_rtl dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    initial clk = 1'b0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // imem loads program.mem itself at time 0.  Reload at t=1 so this test
    // always uses the word-oriented Hello World image.
    initial begin
        rst_n = 1'b0;
        cycle_count = 0;
        char_index = 0;

        #1;
        $readmemh("program_hello.mem", dut.u_imem.memory);

        repeat (RESET_CYCLES) @(posedge clk);
        rst_n = 1'b1;
    end

    always @(posedge clk) begin
        if (!rst_n)
            cycle_count <= 0;
        else begin
            cycle_count <= cycle_count + 1;

            if (dut.u_uart.tx_valid_i) begin
                if (char_index >= EXPECTED.len() ||
                    dut.u_uart.tx_data_i !== EXPECTED[char_index]) begin
                    $fatal(1, "[TB][FAIL] UART char %0d: got 0x%02h, expected 0x%02h",
                           char_index, dut.u_uart.tx_data_i, EXPECTED[char_index]);
                end

                char_index <= char_index + 1;
                if (char_index + 1 == EXPECTED.len()) begin
                    $display("\n[TB][PASS] UART printed: %s", EXPECTED);
                    $finish;
                end
            end

            if (cycle_count >= TIMEOUT_CYCLES)
                $fatal(1, "[TB][FAIL] Timeout after %0d cycles; received %0d/%0d UART bytes",
                       TIMEOUT_CYCLES, char_index, EXPECTED.len());
        end
    end
endmodule
