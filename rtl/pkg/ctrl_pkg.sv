
/* verilator lint_off MODDUP */
package ctrl_pkg;
import isa_pkg::*;
// stage 1: IF

typedef enum logic {
   PC4_ID = 1'b0,
   PC_JUMP_ID = 1'b1
}pc_sel_e;

// stage 2: ID


typedef enum logic [1:0] { 
    RS1_ID = 2'b00,
    RD_EX  =2'b01,
    RD_MEM  =2'b10,
    RS2_ID = 2'b11
} for_sel_e;

// typedef enum logic [1:0] { 
//     RS2_ID = 2'b00,
//     RD_EX  = 2'b01,
//     RD_MEM  = 2'b10
// }  sel_for_id_n;







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
    ALU_ADD_SUB = 2'b00,
    ALU_RTYPE   = 2'b01, // R-type: cần f3 + f7[5]
    ALU_ITYPE   = 2'b10  // I-type ALU: chỉ cần f3, f7[5] dùng cho SRAI
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
    RS1_EX    = 2'b00,
    PC_CUR_EX = 2'b01,
    ZERO_EX   = 2'b10   // added: cần cho LUI (rd = 0 + imm)
}sel_a_decode_e;


typedef enum logic [1:0] {
    RS2_EX = 2'b00,
    IMM_EX = 2'b01
}sel_b_decode_e;


typedef enum logic [1:0]{
    RS_EX_EX = 2'b00,
    RD_MEM_EX = 2'b01,
    RD_WB_EX = 2'b10
}forward_e;


// typedef enum logic [1:0]{
//     B_BASE_EX = 2'b00,
//     B_EX_MEM = 2'b01,
//     B_MEM_WB = 2'b10
// }forward_b_e;


// stage 4: MEM

typedef enum logic [1:0]{
    PC4_MEM = 2'b00,
    ALU_MEM = 2'b01,
    MEM_RDATA = 2'b10
}wb_sel_e;


    typedef enum logic [7:0] {
        // Trạng thái mặc định (Không chọn thiết bị / Địa chỉ lỗi)
        DEV_NONE = 8'h00,

        // --- NHÓM BỘ NHỚ (Memory - Dải 0x01 đến 0x0F) ---
        DEV_SRAM = 8'h01,
        DEV_ROM  = 8'h02, // Dự phòng cho Boot ROM / Flash
        
        // --- NHÓM GIAO TIẾP (Comms - Dải 0x10 đến 0x1F) ---
        DEV_UART = 8'h10,
        DEV_SPI  = 8'h11,
        DEV_I2C  = 8'h12, // Dự phòng thêm giao tiếp I2C
        
        // --- NHÓM ĐIỀU KHIỂN & ĐỊNH THỜI (Control & Timers - Dải 0x20 đến 0x2F) ---
        DEV_GPIO = 8'h20,
        DEV_TMR  = 8'h21,
        DEV_PWM  = 8'h22, // Dự phòng cho bộ phát xung PWM
        
        // --- NHÓM HỆ THỐNG (System - Dải 0xF0 đến 0xFF) ---
        DEV_PLIC = 8'hF0  // Dự phòng cho Bộ điều khiển Ngắt (Interrupt Controller)
        
    } dev_sel_e;



endpackage : ctrl_pkg

/* verilator lint_on MODDUP */


