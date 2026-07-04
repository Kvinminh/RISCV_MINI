package isa_pkg;

///////////////////////////// 
// Instruction Set Architecture (ISA) Package
/////////////////////////////

// 1. OPCODE Definitions
typedef enum logic [6:0] {
   OPCODE_LOAD    = 7'b0000011,
   OPCODE_STORE   = 7'b0100011,
   OPCODE_BRANCH  = 7'b1100011,
   OPCODE_JAL     = 7'b1101111,
   OPCODE_JALR    = 7'b1100111,
   OPCODE_OP_IMM  = 7'b0010011,
   OPCODE_OP      = 7'b0110011,
   OPCODE_LUI     = 7'b0110111,
   OPCODE_AUIPC   = 7'b0010111
}opcode_e;


// 2. FUNCT3 Definitions    

typedef enum logic [2:0]{
   F3_ADD_SUB  = 3'b000,
   F3_SLL      = 3'b001,
   F3_SLT      = 3'b010,
   F3_SLTU     = 3'b011,
   F3_XOR      = 3'b100,
   F3_SRL_SRA  = 3'b101,
   F3_OR       = 3'b110,
   F3_AND      = 3'b111
} r_type_f3_e;

typedef enum logic [2:0]{
   F3_BEQ      = 3'b000,
   F3_BNE      = 3'b001,
   F3_BLT      = 3'b100,
   F3_BGE      = 3'b101,
   F3_BLTU     = 3'b110,
   F3_BGEU     = 3'b111
}b_type_f3_e;

typedef enum logic [2:0]{
   F3_LB       = 3'b000,
   F3_LH       = 3'b001,
   F3_LW       = 3'b010,
   F3_LBU      = 3'b100,
   F3_LHU      = 3'b101
}i_type_load_f3_e;

typedef enum logic [2:0]{
   F3_SB       = 3'b000,
   F3_SH       = 3'b001,
   F3_SW       = 3'b010
}s_type_store_f3_e;


typedef enum logic [2:0]{
   F3_ADDI     = 3'b000,
   F3_SLTI     = 3'b010,
   F3_SLTIU    = 3'b011,
   F3_XORI     = 3'b100,
   F3_ORI      = 3'b110,
   F3_ANDI     = 3'b111,
   F3_SLLI     = 3'b001,
   F3_SRLI_SRAI= 3'b101
}i_type_f3_e;

typedef enum logic [2:0]{
   F3_JALR     = 3'b000
}i_type_jalr_f3_e;


//3. Immediate Generation Selection
typedef struct packed {
        logic [6:0] funct7;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] rd;
        logic [6:0] opcode;
    } r_type_t;

    typedef struct packed {
        logic [11:0] imm_11_0;
        logic [4:0]  rs1;
        logic [2:0]  funct3;
        logic [4:0]  rd;
        logic [6:0]  opcode;
    } i_type_t;

    typedef struct packed {
        logic [6:0] imm_11_5;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] imm_4_0;
        logic [6:0] opcode;
    } s_type_t;

    typedef struct packed {
        logic       imm_12;
        logic [5:0] imm_10_5;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [3:0] imm_4_1;
        logic       imm_11;
        logic [6:0] opcode;
    } b_type_t;

    typedef struct packed {
        logic [19:0] imm_31_12;
        logic [4:0]  rd;
        logic [6:0]  opcode;
    } u_type_t;

    typedef struct packed {
        logic        imm_20;
        logic [9:0]  imm_10_1;
        logic        imm_11;
        logic [7:0]  imm_19_12;
        logic [4:0]  rd;
        logic [6:0]  opcode;
    } j_type_t;

   typedef struct packed {
         r_type_t r_type;
         i_type_t i_type;
         s_type_t s_type;
         b_type_t b_type;
         u_type_t u_type;
         j_type_t j_type;
      } instr_format_u;



// 4. Register Definitions


typedef enum logic [4:0] {
    REG_ZERO = 5'd0,  // x0:  Thanh ghi chứa giá trị 0 không đổi (Hard-wired zero)
    REG_RA   = 5'd1,  // x1:  Return address (Địa chỉ trả về)
    REG_SP   = 5'd2,  // x2:  Stack pointer (Con trỏ ngăn xếp)
    REG_GP   = 5'd3,  // x3:  Global pointer (Con trỏ toàn cục)
    REG_TP   = 5'd4,  // x4:  Thread pointer (Con trỏ luồng)
    
    // Các thanh ghi tạm (Temporaries)
    REG_T0   = 5'd5,  // x5:  Temporary / Alternate link register
    REG_T1   = 5'd6,  // x6:  Temporary
    REG_T2   = 5'd7,  // x7:  Temporary
    
    // Thanh ghi lưu trữ (Saved registers)
    REG_S0   = 5'd8,  // x8:  Saved register / Frame pointer (fp)
    REG_S1   = 5'd9,  // x9:  Saved register
    
    // Các thanh ghi đối số hàm / Giá trị trả về (Function arguments / Return values)
    REG_A0   = 5'd10, // x10: Function argument / Return value
    REG_A1   = 5'd11, // x11: Function argument / Return value
    REG_A2   = 5'd12, // x12: Function argument
    REG_A3   = 5'd13, // x13: Function argument
    REG_A4   = 5'd14, // x14: Function argument
    REG_A5   = 5'd15, // x15: Function argument
    REG_A6   = 5'd16, // x16: Function argument
    REG_A7   = 5'd17, // x17: Function argument
    
    // Các thanh ghi lưu trữ tiếp theo
    REG_S2   = 5'd18, // x18: Saved register
    REG_S3   = 5'd19, // x19: Saved register
    REG_S4   = 5'd20, // x20: Saved register
    REG_S5   = 5'd21, // x21: Saved register
    REG_S6   = 5'd22, // x22: Saved register
    REG_S7   = 5'd23, // x23: Saved register
    REG_S8   = 5'd24, // x24: Saved register
    REG_S9   = 5'd25, // x25: Saved register
    REG_S10  = 5'd26, // x26: Saved register
    REG_S11  = 5'd27, // x27: Saved register
    
    // Các thanh ghi tạm tiếp theo
    REG_T3   = 5'd28, // x28: Temporary
    REG_T4   = 5'd29, // x29: Temporary
    REG_T5   = 5'd30, // x30: Temporary
    REG_T6   = 5'd31  // x31: Temporary
} riscv_reg_e;


endpackage : isa_pkg

