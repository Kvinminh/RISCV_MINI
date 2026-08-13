module regfile 
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic                  clk,
    input logic                  rst_n,
    input logic [REG_ADDR_W-1:0] rs1_addr_i,
    input logic [REG_ADDR_W-1:0] rs2_addr_i,
    
    input regfile_wb              wb_i,
    output logic [XLEN-1:0]      rs1_data_o,
    output logic [XLEN-1:0]      rs2_data_o
);

    logic [XLEN-1:0] mem_reg [0: XLEN-1];

    integer i;
    always_ff @( posedge clk  or negedge rst_n) begin 
        if ( !rst_n) begin 
            for ( i = 0; i < XLEN; i =i + 1 ) begin 
                mem_reg[i] <= '0;
            end
        end
        else begin
            if  (wb_i.reg_en && (wb_i.rd_addr != 0)) begin
                mem_reg[wb_i.rd_addr] <= wb_i.rd_data;
            end
        end

        // else if ( wb_i.reg_en) begin
        //     if ( wb_i.rd_addr == 0) mem_reg[wb_i.rd_addr] = '0;
        //     else mem_reg[wb_i.rd_addr] = wb_i.rd_data;
        // end
    end



    always_comb begin 
        if(rs1_addr_i == 0) rs1_data_o = '0;
        else rs1_data_o = mem_reg[rs1_addr_i];
        if(rs2_addr_i == 0) rs2_data_o = '0;
        else rs2_data_o = mem_reg[rs2_addr_i];
    end

endmodule
