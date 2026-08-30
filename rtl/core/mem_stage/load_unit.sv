module load_unit (
    input  logic [31:0] mem_rdata_raw_i,
    input  logic [3:0]  mask_i,
    input  logic        extension_i, // 1: Sign Extend, 0: Zero Extend
    
    output logic [31:0] mem_rdata_o
);

    logic [31:0] aligned_data; 


    always_comb begin
        case (mask_i)
            // Load Byte (Cắt 8 bit)
            4'b0001: aligned_data = {24'h0, mem_rdata_raw_i[7:0]};
            4'b0010: aligned_data = {24'h0, mem_rdata_raw_i[15:8]};
            4'b0100: aligned_data = {24'h0, mem_rdata_raw_i[23:16]};
            4'b1000: aligned_data = {24'h0, mem_rdata_raw_i[31:24]};
            
            // Load Halfword (Cắt 16 bit)
            4'b0011: aligned_data = {16'h0, mem_rdata_raw_i[15:0]};
            4'b1100: aligned_data = {16'h0, mem_rdata_raw_i[31:16]};
            
            // Load Word (Lấy cả 32 bit)
            4'b1111: aligned_data = mem_rdata_raw_i;
            default: aligned_data = 32'h0;
        endcase
    end

    
    always_comb begin
        
        mem_rdata_o = aligned_data; 

       
        if (extension_i == 1'b1) begin
            case (mask_i)              
                4'b0001, 4'b0010, 4'b0100, 4'b1000: begin
                    if (aligned_data[7]) 
                        mem_rdata_o = {24'hFF_FFFF, aligned_data[7:0]};
               end                        
                4'b0011, 4'b1100: begin
                    if (aligned_data[15]) 
                        mem_rdata_o = {16'hFFFF, aligned_data[15:0]};
                end             
                default: mem_rdata_o = aligned_data;
            endcase
        end
    end

endmodule
