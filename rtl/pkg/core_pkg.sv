
/* verilator lint_off MODDUP */

package core_pkg;
    
import isa_pkg::*;
import ctrl_pkg::*;

parameter int XLEN = 32;
parameter int REG_ADDR_W = 5;
parameter int NUM_REGS = 32;
parameter int F3 = 3;
parameter logic [XLEN-1:0] RESET_PC = 32'h0000_0000;
parameter logic [XLEN-1:0] NOP = 32'h00000013; // addi x0, x0, 0

// stage 1: IF

typedef struct packed {
 logic [XLEN-1:0] pc_cur;
 logic [XLEN-1:0] pc_4;
 logic [XLEN-1:0] ins;
} if_id_reg_t;


// stage 2: ID

typedef struct packed{
    alu_op_e alu_op;
    sel_a_decode_e sel_a;
    sel_b_decode_e sel_b;
}ex_ctrl_s;


typedef struct packed{
    logic dmem_re;
    logic dmem_wri;
} mem_ctrl_s;


typedef struct packed{
    logic reg_en;
    wb_sel_e sel_wb;
} wb_ctrl_s;


typedef struct packed{
    logic br_en;
    logic jal_en;
    logic jalr_en;
    logic extension_ex;
    immgen_sel_e imm_sel;
    ex_ctrl_s ex_ctrl;
    mem_ctrl_s mem_ctrl;
    wb_ctrl_s wb_ctrl;
}decode_s;



typedef struct packed{
    logic [F3-1:0] f3;
    logic          f7_5;
    logic [XLEN-1:0] pc_cur;
    logic [XLEN-1:0] pc_4;

    logic [XLEN-1:0] imm;

    logic [REG_ADDR_W-1:0] rd_addr;
    logic [REG_ADDR_W-1:0] rs1_addr;
    logic [REG_ADDR_W-1:0] rs2_addr;
    logic [XLEN-1:0] rs1_data;
    logic [XLEN-1:0] rs2_data;
    
    ex_ctrl_s ex_ctrl;
    mem_ctrl_s mem_ctrl;
    logic      extension;
    wb_ctrl_s wb_ctrl; 
}id_ex_reg_t;



// stage 3: EX
typedef struct packed {
    logic [XLEN-1:0]        pc_4;
    logic [XLEN-1:0]        alu_result;
    logic [XLEN-1:0]        rs2_data;  
    logic [REG_ADDR_W-1:0]  rd_addr;
    logic                   extension;
    mem_ctrl_s              mem_ctrl;
    wb_ctrl_s               wb_ctrl;
}ex_mem_reg_t;


// stage 4: MEM
typedef struct packed {
    logic [XLEN-1:0]        pc_4;
    logic [XLEN-1:0]        alu_result;
    logic [XLEN-1:0]        mem_rdata;
    logic [REG_ADDR_W-1:0]  rd_addr;
    wb_ctrl_s               wb_ctrl;
}mem_wb_reg_t;

    
endpackage : core_pkg


/* verilator lint_on MODDUP */

