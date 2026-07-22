module regfile 
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic                  clk,
    input logic                  rst_n,
    input logic [REG_ADDR_W-1:0] rs1_addr_id,
    input logic [REG_ADDR_W-1:0] rs2_addr_id,
    input logic                  reg_en_wb,
    input logic [REG_ADDR_W-1:0] rd_addr_wb,
    input logic [XLEN-1:0]       rd_data_wb,

    output logic [XLEN-1:0]      rs1_data_id,
    output logic [XLEN-1:0]      rs2_data_id
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
            if  (reg_en_wb && (rd_addr_wb != 0)) begin
                mem_reg[rd_addr_wb] <= rd_data_wb;
            end
        end

        // else if ( reg_en_wb) begin
        //     if ( rd_addr_wb == 0) mem_reg[rd_addr_wb] = '0;
        //     else mem_reg[rd_addr_wb] = rd_data_wb;
        // end
    end



    always_comb begin 
        if(rs1_addr_id == 0) rs1_data_id = '0;
        else rs1_data_id = mem_reg[rs1_addr_id];
        if(rs2_addr_id == 0) rs2_data_id = '0;
        else rs2_data_id = mem_reg[rs2_addr_id];
    end

endmodule
