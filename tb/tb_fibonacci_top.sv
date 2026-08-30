`timescale 1ns/1ps

// End-to-end RV32I test: calculate and print the first seven Fibonacci terms.
// Expected UART stream: "0 1 1 2 3 5 8 \n".
module tb_fibonacci_top;
    localparam time CLK_PERIOD = 10ns;
    localparam int  RESET_CYCLES = 5;
    localparam int  TIMEOUT_CYCLES = 500;
    localparam string EXPECTED = "0 1 1 2 3 5 8 \n";

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

    initial begin
        rst_n = 1'b0;
        cycle_count = 0;
        char_index = 0;

        // Override IMEM's default image after its time-zero initialization.
        #1;
        $readmemh("program_fibonacci.mem", dut.u_imem.memory);

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
                    $display("\n[TB][PASS] Fibonacci UART output: %s", EXPECTED);
                    $finish;
                end
            end

            if (cycle_count >= TIMEOUT_CYCLES)
                $fatal(1, "[TB][FAIL] Timeout after %0d cycles; received %0d/%0d UART bytes",
                       TIMEOUT_CYCLES, char_index, EXPECTED.len());
        end
    end
endmodule
