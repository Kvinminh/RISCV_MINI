module pc_4
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic [XLEN-1:0] pc_cur_if,
    output logic [XLEN-1:0] pc4_if
);

assign pc4_if = pc_cur_if + 32'd4;

endmodule
