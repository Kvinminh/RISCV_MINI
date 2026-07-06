module pc_4
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic [XLEN-1:0] pc_cur_id,
    output logic [XLEN-1:0] pc4
);

assign pc4 = pc_cur_id + 32'd4;

endmodule
