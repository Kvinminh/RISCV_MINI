module uart (
    input  logic       clk,
    input  logic [7:0] tx_data_i,
    input  logic       tx_valid_i,
    
    output logic [31:0] uart_rdata_o  
);
    always_ff @(posedge clk) begin
        
        if (tx_valid_i) begin
            $write("%c", tx_data_i); 
        end
    end
    assign uart_rdata_o = 32'h0000_0000;

endmodule
