
/* verilator lint_off MODDUP */
package ctrl_pkg;
import isa_pkg::*;
// stage 1: IF

typedef enum logic {
   PC4_ID = 1'b0,
   PC_JUMP_ID = 1'b1
}pc_sel_e;

// stage 2: ID
typedef enum logic [3:0]{
    IMMGEN_I = 4'b0000,
    IMMGEN_S = 4'b0001,
    IMMGEN_B = 4'b0010,
    IMMGEN_U = 4'b0011,
    IMMGEN_J = 4'b0100
} immgen_sel_e;
    
typedef enum logic {
    RS1_DATA = 1'b0,
    PC_CUR_ID = 1'b1
}mux_base_e;
   



// stage 3: EX
typedef enum logic [1:0]{
    ALU_ADD_SUB = 2'b00, // Load, Store, JAL, JALR, AUIPC, LUI
    ALU_ITYPE     = 2'b01,// R-type (cần funct3 + funct7[5])
    ALU_RTYPE     = 2'b10// I-type ALU (cần funct3, funct7[5] chỉ dùng cho SRAI)
} alu_op_e; 

typedef enum logic [3:0]{
    ALU_ADD = 4'b0000,
    ALU_SUB = 4'b0001,
    ALU_SLL = 4'b0010,
    ALU_SLT = 4'b0011,
    ALU_SLTU = 4'b0100,
    ALU_XOR = 4'b0101,
    ALU_SRL = 4'b0110,
    ALU_SRA = 4'b0111,
    ALU_OR  = 4'b1000,
    ALU_AND = 4'b1001
} alu_ctrl_e;


typedef enum logic [1:0] {
    RS1_EX = 2'b00,
    PC_CUR_EX = 2'b01
}sel_a_decode_e;

typedef enum logic [1:0] {
    RS2_EX = 2'b00,
    IMM_EX = 2'b01
}sel_b_decode_e;


typedef enum logic [1:0]{
    A_BASE_EX = 2'b00,
    A_EX_MEM = 2'b01,
    A_MEM_WB = 2'b10
}forward_a_e;


typedef enum logic [1:0]{
    B_BASE_EX = 2'b00,
    B_EX_MEM = 2'b01,
    B_MEM_WB = 2'b10
}forward_b_e;


// stage 4: MEM
typedef enum logic [1:0] {
    DEV_SRAM = 2'b00,
    DEV_UART = 2'b01
    // DEV_GPIO, DEV_TIMER... sau này
} mem_dev_e;

typedef enum logic [1:0]{
    PC4_MEM = 2'b00,
    ALU_MEM = 2'b01,
    MEM_RDATA = 2'b10
}wb_sel_e;


endpackage : ctrl_pkg

/* verilator lint_on MODDUP */


