
`timescale 1ns/1ps

import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;

//////////////////////////////////////////////////////////////
// Reference Model
//////////////////////////////////////////////////////////////

class wb_ref_model;

    function new();
    endfunction

    function void predict(
        input  mem_wb_reg_t wb_i,
        output regfile_wb   expected
    );
        expected = '0;
        case (wb_i.wb_ctrl.sel_wb)
            PC4_MEM:
                expected.rd_data = wb_i.pc_4;
            ALU_MEM:
                expected.rd_data = wb_i.alu_result;
            MEM_RDATA:
                expected.rd_data = wb_i.mem_rdata;
            default:
                expected.rd_data = '0;

        endcase
        expected.reg_en  = wb_i.wb_ctrl.reg_en;
        expected.rd_addr = wb_i.rd_addr;
    endfunction
endclass


//////////////////////////////////////////////////////////////
// Testbench
//////////////////////////////////////////////////////////////

module tb_wb_stage;
    //=========================================================
    // Signals
    //=========================================================

    mem_wb_reg_t wb_i;
    regfile_wb   wb_o;

    regfile_wb expected;

    wb_ref_model ref_model;

    int pass_cnt = 0;
    int fail_cnt = 0;

    //=========================================================
    // DUT
    //=========================================================

    wb_stage dut (
        .wb_i (wb_i),
        .wb_o (wb_o)
    );

    //=========================================================
    // Scoreboard
    //=========================================================

    task automatic check_result();
        ref_model.predict(wb_i, expected);
        #1;
        if (wb_o !== expected) begin

            fail_cnt++;

            $error(
                "[SB][FAIL] "                           \
                "sel=%0d | "                           \
                "pc4=%08h | "                          \
                "alu=%08h | "                          \
                "mem=%08h | "                          \
                "rd=x%0d | "                           \
                "reg_en=%0b | "                        \
                "actual=%p | "                         \
                "expected=%p",
                wb_i.wb_ctrl.sel_wb,
                wb_i.pc_4,
                wb_i.alu_result,
                wb_i.mem_rdata,
                wb_i.rd_addr,
                wb_i.wb_ctrl.reg_en,
                wb_o,
                expected
            );
        end
        else begin
            pass_cnt++;
        end
    endtask

    //=========================================================
    // Test
    //=========================================================

    initial begin
        //=====================================================
        // Waveform
        //=====================================================
        $dumpfile("wb_stage.vcd");
        $dumpvars(0, tb_wb_stage);

        //=====================================================
        // Create reference model
        //=====================================================
        ref_model = new();

        //=====================================================
        // Initial values
        //=====================================================
        wb_i = '0;
        #1;


        //=====================================================
        // Random test
        //=====================================================
        repeat (1000) begin
            wb_i.pc_4       = $urandom;
            wb_i.alu_result = $urandom;
            wb_i.mem_rdata  = $urandom;

            wb_i.rd_addr = $urandom_range(0, 31);

            wb_i.wb_ctrl.reg_en =
                $urandom_range(0, 1);

            wb_i.wb_ctrl.sel_wb =
                wb_sel_e'($urandom_range(
                    PC4_MEM,
                    MEM_RDATA
                ));
            check_result();
        end


        //=====================================================
        // Directed test: default case
        //=====================================================
        wb_i.pc_4       = $urandom;
        wb_i.alu_result = $urandom;
        wb_i.mem_rdata  = $urandom;

        wb_i.rd_addr =
            $urandom_range(0, 31);

        wb_i.wb_ctrl.reg_en =
            $urandom_range(0, 1);

        wb_i.wb_ctrl.sel_wb =
            wb_sel_e'('hf);

        check_result();


        //=====================================================
        // Report
        //=====================================================

        $display("");
        $display("============================================================");
        $display("                    WB STAGE TEST");
        $display("============================================================");

        $display("[TB] PASS = %0d", pass_cnt);
        $display("[TB] FAIL = %0d", fail_cnt);

        if (fail_cnt == 0)
            $display("[TB] RESULT = PASS");
        else
            $display("[TB] RESULT = FAIL");

        $display("============================================================");


        $finish;

    end

endmodule
```
