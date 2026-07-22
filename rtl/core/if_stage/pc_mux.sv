module pc_mux
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic br_taken_id,
    input logic br_en_id,
    input logic jal_id,
    input logic jalr_id,
    input logic [XLEN-1:0] pc4_if,
    input logic [XLEN-1:0] pc_jump_id,
    output logic [XLEN-1:0] pc_next_if
);
    logic pc_sel;
    assign pc_sel = ( br_taken_id && br_en_id) || jal_id || jalr_id;

    always_comb begin
        pc_next_if = pc4_if;
        case( pc_sel)
        PC4_ID: pc_next_if = pc4_if;
        PC_JUMP_ID: pc_next_if = pc_jump_id;
        default: pc_next_if = pc4_if;
        endcase
    end 
endmodule
