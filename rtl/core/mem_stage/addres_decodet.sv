module addr_deco
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic [XLEN-1:0]  alu_result_mem,
    input logic             mem_re_mem,
    input logic             mem_wri_mem,
    output dev_sel_e            dev_sel
);

logic valid_req;
assign valid_req = mem_re_mem || mem_wri_mem;

    always_comb begin
        dev_sel = DEV_NONE; // Default an toàn

        if (valid_req) begin
            // LEVEL 1: TÌM QUẬN (Giải mã 4 bit cao nhất [31:28])
            case (alu_result_mem[31:28])
                
                // --- QUẬN 0: KHU BỘ NHỚ ---
                4'h0: dev_sel = DEV_SRAM; 
                
                // --- QUẬN 4: KHU NGOẠI VI (Chứa tất cả IO) ---
                4'h4: begin 
                    // LEVEL 2: TÌM SỐ NHÀ (Giải mã các bit thấp, VD [15:12])
                    case (alu_result_mem[15:12])
                        4'h0: dev_sel = DEV_UART; // 0x4000_0...
                        4'h1: dev_sel = DEV_GPIO; // 0x4000_1...
                        
                        // Sau này thêm SPI, I2C, Timer... chỉ cần gõ thêm 1 dòng ở đây!
                        // 4'h2: dev_sel = DEV_SPI; 
                        // 4'h3: dev_sel = DEV_TIMER;
                        
                        default: dev_sel = DEV_NONE;
                    endcase
                end
                
                default: dev_sel = DEV_NONE;
            endcase
        end
    end



endmodule
