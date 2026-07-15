module mux_base
 import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input  logic [31:0] rs1_data_id,
    input  logic [31:0] pc_cur_id,
    input  logic         jalr_id,     // 1 = jalr -> base = rs1
    output logic [31:0] base_addr
);

    mux_base_e sel;
    assign sel = jalr_id ? RS1_DATA : PC_CUR_ID;

    always_comb begin
        case (sel)
            RS1_DATA:  base_addr = rs1_data_id;
            PC_CUR_ID: base_addr = pc_cur_id;
            default:   base_addr = pc_cur_id;
        endcase
    end

endmodule
