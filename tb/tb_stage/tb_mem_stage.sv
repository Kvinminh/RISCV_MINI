`timescale 1ps/1ps
import core_pkg::*;
import ctrl_pkg::*;
import isa_pkg::*;

// ============================================================================
// INTERFACE
// ============================================================================

interface mem_stage_if(input logic clk);
    ex_mem_reg_t reg_mem;
    mem_wb_reg_t mem_reg;

    logic [31:0] sram_rdata;
    logic [31:0] uart_rdata;

    logic [31:0] sram_wdata;
    logic [3:0]  sram_mask;
    logic        sram_we;
    logic [7:0]  uart_tx_data;
    logic        uart_tx_valid;

    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output reg_mem, sram_rdata, uart_rdata;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #1;
        input reg_mem, mem_reg;
        input sram_rdata, uart_rdata;
        input sram_wdata, sram_mask, sram_we;
        input uart_tx_data, uart_tx_valid;
    endclocking

    modport DRV(clocking drv_cb,input clk);
    modport MON(clocking mon_cb,input clk);
endinterface

// ============================================================================
// TRANSACTION
// ============================================================================

class mem_stage_transaction;
    rand bit [2:0]            f3;
    rand bit [XLEN-1:0]       pc_4;
    rand bit [XLEN-1:0]       alu;
    rand bit [XLEN-1:0]       rs2_data;
    rand bit [REG_ADDR_W-1:0] rd_addr;
    rand bit                   extension;
    rand bit                   dmem_re;
    rand bit                   dmem_wri;
    rand bit                   reg_en;

    rand bit [31:0] sram_rdata;
    rand bit [31:0] uart_rdata;

    bit [31:0] mem_rdata;
    bit [31:0] sram_wdata;
    bit [3:0]  sram_mask;
    bit        sram_we;
    bit [7:0]  uart_tx_data;
    bit        uart_tx_valid;

    bit [31:0] expected_mem_rdata;
    bit [31:0] expected_sram_wdata;
    bit [3:0]  expected_sram_mask;
    bit        expected_sram_we;
    bit [7:0]  expected_uart_tx_data;
    bit        expected_uart_tx_valid;

    constraint c_mem_op_exclusive {
        !(dmem_re && dmem_wri);
    }

    constraint c_f3_valid {
        f3 inside {
            3'b000,
            3'b001,
            3'b010,
            3'b100,
            3'b101
        };
    }

    constraint c_f3_store_no_unsigned {
        dmem_wri ->
            f3 inside {
                3'b000,
                3'b001,
                3'b010
            };
    }

    constraint c_addr_offset_dist {
    alu dist {
        32'h0000_0000 := 4,
        32'h0000_0001 := 2,
        32'h0000_0002 := 2,
        32'h0000_0003 := 2
    };
}

    constraint c_addr_align_by_size {
        (f3 == 3'b001 || f3 == 3'b101) -> alu[0] == 1'b0;
        (f3 == 3'b010) -> alu[1:0] == 2'b00;
    }

    // constraint c_addr_dev_dist {
    //     alu dist {
    //         [32'h0000_0000:32'h0000_03FF] :/ 70,
    //         [32'h4000_0000:32'h4000_0FFF] :/ 20,
    //         [32'h4000_1000:32'h4000_1FFF] :/ 10
    //     };
    // }

    function void copy(mem_stage_transaction rhs);
        this.f3 = rhs.f3;
        this.pc_4 = rhs.pc_4;
        this.alu = rhs.alu;
        this.rs2_data = rhs.rs2_data;
        this.rd_addr = rhs.rd_addr;
        this.extension = rhs.extension;
        this.dmem_re = rhs.dmem_re;
        this.dmem_wri = rhs.dmem_wri;
        this.reg_en = rhs.reg_en;
        this.sram_rdata = rhs.sram_rdata;
        this.uart_rdata = rhs.uart_rdata;
        this.mem_rdata = rhs.mem_rdata;
        this.sram_wdata = rhs.sram_wdata;
        this.sram_mask = rhs.sram_mask;
        this.sram_we = rhs.sram_we;
        this.uart_tx_data = rhs.uart_tx_data;
        this.uart_tx_valid = rhs.uart_tx_valid;
        this.expected_mem_rdata = rhs.expected_mem_rdata;
        this.expected_sram_wdata = rhs.expected_sram_wdata;
        this.expected_sram_mask = rhs.expected_sram_mask;
        this.expected_sram_we = rhs.expected_sram_we;
        this.expected_uart_tx_data = rhs.expected_uart_tx_data;
        this.expected_uart_tx_valid = rhs.expected_uart_tx_valid;
    endfunction

    function mem_stage_transaction clone();
        mem_stage_transaction t;
        t = new();
        t.copy(this);
        return t;
    endfunction
endclass

// ============================================================================
// GENERATOR
// ============================================================================

class mem_stage_generator;
    mailbox #(mem_stage_transaction) gen2drv;
    int num_txn;

    function new(
        mailbox #(mem_stage_transaction) gen2drv,
        int num_txn
    );
        this.gen2drv = gen2drv;
        this.num_txn = num_txn;
    endfunction

    task run();
        mem_stage_transaction txn;

        for(int i=0;i<num_txn;i++) begin
            txn = new();

            if(txn.randomize() == 0) begin
                $error("[GEN] Randomization failed at txn #%0d",i);
                continue;
            end

            gen2drv.put(txn);
        end
    endtask
endclass

// ============================================================================
// DRIVER
// ============================================================================

class mem_stage_driver;
    virtual mem_stage_if.DRV vif;
    mailbox #(mem_stage_transaction) gen2drv;

    function new(
        virtual mem_stage_if.DRV vif,
        mailbox #(mem_stage_transaction) gen2drv
    );
        this.vif = vif;
        this.gen2drv = gen2drv;
    endfunction

    task drive(mem_stage_transaction txn);
        vif.drv_cb.reg_mem.f3 <= txn.f3;
        vif.drv_cb.reg_mem.pc_4 <= txn.pc_4;
        vif.drv_cb.reg_mem.alu <= txn.alu;
        vif.drv_cb.reg_mem.rs2_data <= txn.rs2_data;
        //vif.drv_cb.rd_addr <= txn.rd_addr;
        vif.drv_cb.reg_mem.extension <= txn.extension;

        vif.drv_cb.reg_mem.mem_ctrl.dmem_re <= txn.dmem_re;
        vif.drv_cb.reg_mem.mem_ctrl.dmem_wri <= txn.dmem_wri;
        vif.drv_cb.reg_mem.wb_ctrl.reg_en <= txn.reg_en;

        vif.drv_cb.sram_rdata <= txn.sram_rdata;
        vif.drv_cb.uart_rdata <= txn.uart_rdata;
    endtask

    task run();
        mem_stage_transaction txn;

        forever begin
            gen2drv.get(txn);
            @(vif.drv_cb);
            drive(txn);
        end
    endtask
endclass

// ============================================================================
// REFERENCE MODEL
// ============================================================================

class mem_stage_ref_model;
    bit [31:0] model_mem_rdata;
    bit [31:0] model_sram_wdata;
    bit [3:0]  model_sram_mask;
    bit        model_sram_we;
    bit [7:0]  model_uart_tx_data;
    bit        model_uart_tx_valid;

    function void predict(input mem_stage_transaction txn);
        dev_sel_e dev_sel;
        bit [3:0] mask;
        bit [31:0] raw_data;

        dev_sel = DEV_NONE;

        if(txn.dmem_re || txn.dmem_wri) begin
            case(txn.alu[31:28])
                4'h0: dev_sel = DEV_SRAM;

                4'h4: begin
                    case(txn.alu[15:12])
                        4'h0: dev_sel = DEV_UART;
                        4'h1: dev_sel = DEV_GPIO;
                        default: dev_sel = DEV_NONE;
                    endcase
                end

                default: dev_sel = DEV_NONE;
            endcase
        end

        mask = 4'b0000;

        case(txn.f3)
            F3_LB,F3_LBU: begin
                case(txn.alu[1:0])
                    2'b00: mask = 4'b0001;
                    2'b01: mask = 4'b0010;
                    2'b10: mask = 4'b0100;
                    2'b11: mask = 4'b1000;
                endcase
            end

            F3_LH,F3_LHU: begin
                if(txn.alu[1] == 1'b0)
                    mask = 4'b0011;
                else
                    mask = 4'b1100;
            end

            F3_LW:
                mask = 4'b1111;

            default:
                mask = 4'b0000;
        endcase

        model_sram_wdata = txn.rs2_data << (txn.alu[1:0] * 8);
        model_sram_mask = (dev_sel == DEV_SRAM) ? mask : 4'b0000;
        model_sram_we = (dev_sel == DEV_SRAM) ? txn.dmem_wri : 1'b0;

        model_uart_tx_data = txn.rs2_data[7:0];
        model_uart_tx_valid =
            (dev_sel == DEV_UART) ? txn.dmem_wri : 1'b0;

        case(dev_sel)
            DEV_SRAM: raw_data = txn.sram_rdata;
            DEV_UART: raw_data = txn.uart_rdata;
            default: raw_data = 32'h0000_0000;
        endcase

        model_mem_rdata = 32'h0000_0000;

        case(mask)
            4'b0001:
                model_mem_rdata = txn.extension ?
                    {{24{raw_data[7]}},raw_data[7:0]} :
                    {24'h0,raw_data[7:0]};

            4'b0010:
                model_mem_rdata = txn.extension ?
                    {{24{raw_data[15]}},raw_data[15:8]} :
                    {24'h0,raw_data[15:8]};

            4'b0100:
                model_mem_rdata = txn.extension ?
                    {{24{raw_data[23]}},raw_data[23:16]} :
                    {24'h0,raw_data[23:16]};

            4'b1000:
                model_mem_rdata = txn.extension ?
                    {{24{raw_data[31]}},raw_data[31:24]} :
                    {24'h0,raw_data[31:24]};

            4'b0011:
                model_mem_rdata = txn.extension ?
                    {{16{raw_data[15]}},raw_data[15:0]} :
                    {16'h0,raw_data[15:0]};

            4'b1100:
                model_mem_rdata = txn.extension ?
                    {{16{raw_data[31]}},raw_data[31:16]} :
                    {16'h0,raw_data[31:16]};

            4'b1111:
                model_mem_rdata = raw_data;

            default:
                model_mem_rdata = 32'h0000_0000;
        endcase
    endfunction
endclass

// ============================================================================
// MONITOR
// ============================================================================

class mem_stage_monitor;
    virtual mem_stage_if.MON vif;
    mailbox #(mem_stage_transaction) mon2sb;
    mailbox #(mem_stage_transaction) mon2cov;
    mem_stage_ref_model ref_model;

    int num_txn;
    event done;

    function new(
        virtual mem_stage_if.MON vif,
        mailbox #(mem_stage_transaction) mon2sb,
        mailbox #(mem_stage_transaction) mon2cov,
        mem_stage_ref_model ref_model,
        int num_txn
    );
        this.vif = vif;
        this.mon2sb = mon2sb;
        this.mon2cov = mon2cov;
        this.ref_model = ref_model;
        this.num_txn = num_txn;
    endfunction

    task run();
        mem_stage_transaction txn;

        for(int i=0;i<num_txn;i++) begin
            @(posedge vif.clk);
            #1;

            txn = new();

            txn.f3 = vif.mon_cb.reg_mem.f3;
            txn.pc_4 = vif.mon_cb.reg_mem.pc_4;
            txn.alu = vif.mon_cb.reg_mem.alu;
            txn.rs2_data = vif.mon_cb.reg_mem.rs2_data;
            //txn.rd_addr = vif.mon_cb.reg_mem.rd_addr;
            txn.extension = vif.mon_cb.reg_mem.extension;

            txn.dmem_re =
                vif.mon_cb.reg_mem.mem_ctrl.dmem_re;
            txn.dmem_wri =
                vif.mon_cb.reg_mem.mem_ctrl.dmem_wri;
            txn.reg_en =
                vif.mon_cb.reg_mem.wb_ctrl.reg_en;

            txn.sram_rdata = vif.mon_cb.sram_rdata;
            txn.uart_rdata = vif.mon_cb.uart_rdata;

            txn.mem_rdata = vif.mon_cb.mem_reg.mem_rdata;
            txn.sram_wdata = vif.mon_cb.sram_wdata;
            txn.sram_mask = vif.mon_cb.sram_mask;
            txn.sram_we = vif.mon_cb.sram_we;
            txn.uart_tx_data = vif.mon_cb.uart_tx_data;
            txn.uart_tx_valid = vif.mon_cb.uart_tx_valid;

            ref_model.predict(txn);

            txn.expected_mem_rdata =
                ref_model.model_mem_rdata;
            txn.expected_sram_wdata =
                ref_model.model_sram_wdata;
            txn.expected_sram_mask =
                ref_model.model_sram_mask;
            txn.expected_sram_we =
                ref_model.model_sram_we;
            txn.expected_uart_tx_data =
                ref_model.model_uart_tx_data;
            txn.expected_uart_tx_valid =
                ref_model.model_uart_tx_valid;

            mon2sb.put(txn.clone());
            mon2cov.put(txn.clone());
        end

        ->done;
    endtask
endclass

// ============================================================================
// SCOREBOARD
// ============================================================================

class mem_stage_scoreboard;
    mailbox #(mem_stage_transaction) mon2sb;

    int pass_cnt = 0;
    int fail_cnt = 0;

    function new(mailbox #(mem_stage_transaction) mon2sb);
        this.mon2sb = mon2sb;
    endfunction

    task run();
        mem_stage_transaction txn;

        forever begin
            mon2sb.get(txn);

            if(txn.mem_rdata === txn.expected_mem_rdata)
                pass_cnt++;
            else begin
                fail_cnt++;
                $error("[SB][FAIL] MEM_RDATA actual=%08h expected=%08h | addr=%08h f3=%03b",
                    txn.mem_rdata,txn.expected_mem_rdata,txn.alu,txn.f3);
            end

            if(txn.sram_wdata === txn.expected_sram_wdata)
                pass_cnt++;
            else begin
                fail_cnt++;
                $error("[SB][FAIL] SRAM_WDATA actual=%08h expected=%08h | addr=%08h",
                    txn.sram_wdata,txn.expected_sram_wdata,txn.alu);
            end

            if(txn.sram_mask === txn.expected_sram_mask)
                pass_cnt++;
            else begin
                fail_cnt++;
                $error("[SB][FAIL] SRAM_MASK actual=%04b expected=%04b | addr=%08h",
                    txn.sram_mask,txn.expected_sram_mask,txn.alu);
            end

            if(txn.sram_we === txn.expected_sram_we)
                pass_cnt++;
            else begin
                fail_cnt++;
                $error("[SB][FAIL] SRAM_WE actual=%0b expected=%0b | addr=%08h",
                    txn.sram_we,txn.expected_sram_we,txn.alu);
            end

            if(txn.uart_tx_data === txn.expected_uart_tx_data)
                pass_cnt++;
            else begin
                fail_cnt++;
                $error("[SB][FAIL] UART_DATA actual=%02h expected=%02h | addr=%08h",
                    txn.uart_tx_data,txn.expected_uart_tx_data,txn.alu);
            end

            if(txn.uart_tx_valid === txn.expected_uart_tx_valid)
                pass_cnt++;
            else begin
                fail_cnt++;
                $error("[SB][FAIL] UART_VALID actual=%0b expected=%0b | addr=%08h",
                    txn.uart_tx_valid,txn.expected_uart_tx_valid,txn.alu);
            end
        end
    endtask

    function void report();
        $display("\n[SB] PASS=%0d FAIL=%0d RESULT=%s",
            pass_cnt,fail_cnt,(fail_cnt==0)?"PASS":"FAIL");
    endfunction
endclass

// ============================================================================
// COVERAGE
// ============================================================================

class mem_stage_coverage;
    mailbox #(mem_stage_transaction) mon2cov;

    covergroup cg_operation with function sample(mem_stage_transaction t);
        cp_f3 : coverpoint t.f3 {
            bins byte_access = {3'b000};
            bins half_access = {3'b001};
            bins word_access = {3'b010};
            bins byte_unsigned = {3'b100};
            bins half_unsigned = {3'b101};
        }

        cp_read : coverpoint t.dmem_re {
            bins no_read = {0};
            bins read = {1};
        }

        cp_write : coverpoint t.dmem_wri {
            bins no_write = {0};
            bins write = {1};
        }

        cp_extension : coverpoint t.extension {
            bins zero_extend = {0};
            bins sign_extend = {1};
        }

        cp_load : coverpoint (t.dmem_re && !t.dmem_wri) {
            bins load = {1};
            bins other = {0};
        }

        cp_store : coverpoint (t.dmem_wri && !t.dmem_re) {
            bins store = {1};
            bins other = {0};
        }

        cp_idle : coverpoint (!t.dmem_re && !t.dmem_wri) {
            bins idle = {1};
            bins active = {0};
        }
    endgroup

    covergroup cg_address with function sample(mem_stage_transaction t);
        cp_offset : coverpoint t.alu[1:0] {
            bins offset_0 = {2'b00};
            bins offset_1 = {2'b01};
            bins offset_2 = {2'b10};
            bins offset_3 = {2'b11};
        }

        cp_address_region : coverpoint t.alu[31:28] {
            bins sram = {4'h0};
            bins peripheral = {4'h4};
            bins invalid = default;
        }

        cp_peripheral_addr : coverpoint t.alu[15:12] {
            bins uart = {4'h0};
            bins gpio = {4'h1};
            bins invalid = default;
        }

        cp_address_boundary : coverpoint t.alu {
            bins zero = {32'h0000_0000};
            bins sram_high = {32'h0000_03FF};
            bins uart_base = {32'h4000_0000};
            bins uart_high = {32'h4000_0FFF};
            bins gpio_base = {32'h4000_1000};
            bins gpio_high = {32'h4000_1FFF};
            bins invalid = {32'h4002_0000};
            bins max = {32'hFFFF_FFFF};
        }
    endgroup

    covergroup cg_lsu with function sample(mem_stage_transaction t);
        cp_mask : coverpoint t.sram_mask {
            bins byte0 = {4'b0001};
            bins byte1 = {4'b0010};
            bins byte2 = {4'b0100};
            bins byte3 = {4'b1000};
            bins half_low = {4'b0011};
            bins half_high = {4'b1100};
            bins word = {4'b1111};
            bins none = {4'b0000};
        }

        cp_byte_offset : coverpoint t.alu[1:0] {
            bins b0 = {2'b00};
            bins b1 = {2'b01};
            bins b2 = {2'b10};
            bins b3 = {2'b11};
        }
    endgroup

    covergroup cg_store with function sample(mem_stage_transaction t);
       cp_rs2_data : coverpoint t.rs2_data {
            bins zero = {32'h0000_0000};
            bins one = {32'h0000_0001};
            bins ff = {32'h0000_00FF};
            bins ffff = {32'h0000_FFFF};
            bins aa = {32'hAAAA_AAAA};
            bins pattern_55 = {32'h5555_5555};
            bins max = {32'hFFFF_FFFF};
        }

        cp_sram_wdata : coverpoint t.sram_wdata {
            bins zero = {32'h0000_0000};
            bins low = {[32'h0000_0001:32'h0000_FFFF]};
            bins middle = {[32'h0001_0000:32'hFFFE_FFFF]};
            bins high = {[32'hFFFF_0000:32'hFFFF_FFFF]};
        }
        cp_sram_we : coverpoint t.sram_we {
            bins disabled = {0};
            bins enabled = {1};
        }

        cp_uart_valid : coverpoint t.uart_tx_valid {
            bins disabled = {0};
            bins enabled = {1};
        }
    endgroup

    covergroup cg_load with function sample(mem_stage_transaction t);
        cp_sram_rdata : coverpoint t.sram_rdata {
            bins zero = {32'h0000_0000};
            bins max = {32'hFFFF_FFFF};
            bins aa = {32'hAAAA_AAAA};
            bins pattern_55 = {32'h5555_5555};
            bins sign_byte = {32'h0000_0080};
            bins sign_half = {32'h0000_8000};
            bins sign_word = {32'h8000_0000};
        }

        cp_uart_rdata : coverpoint t.uart_rdata {
            bins zero = {32'h0000_0000};
            bins nonzero = {[32'h0000_0001:32'hFFFF_FFFF]};
        }

        cp_mem_rdata : coverpoint t.mem_rdata {
            bins zero = {32'h0000_0000};
            bins all_one = {32'hFFFF_FFFF};
            bins sign_extended_half = {32'hFFFF_8000};
            bins positive = {[32'h0000_0001:32'h7FFF_FFFF]};
            bins negative = {[32'h8000_0000:32'hFFFE_FFFF]};
        }

        cp_sign : coverpoint t.extension {
            bins zero_extend = {0};
            bins sign_extend = {1};
        }
    endgroup

    covergroup cg_wb with function sample(mem_stage_transaction t);
        cp_rd_addr : coverpoint t.rd_addr {
            bins x0 = {0};
            bins x1 = {1};
            bins x31 = {31};
            bins middle = {[2:30]};
        }

        cp_reg_en : coverpoint t.reg_en {
            bins disabled = {0};
            bins enabled = {1};
        }
    endgroup

    covergroup cg_special with function sample(mem_stage_transaction t);
        cp_invalid_addr : coverpoint (
            (t.alu[31:28] != 4'h0) &&
            (t.alu[31:28] != 4'h4)
        ) {
            bins invalid = {1};
            bins valid = {0};
        }

        cp_uart : coverpoint (
            t.alu[31:28] == 4'h4 &&
            t.alu[15:12] == 4'h0
        ) {
            bins uart = {1};
            bins other = {0};
        }

        cp_gpio : coverpoint (
            t.alu[31:28] == 4'h4 &&
            t.alu[15:12] == 4'h1
        ) {
            bins gpio = {1};
            bins other = {0};
        }

        cp_load_sign_case : coverpoint (
            t.dmem_re && t.extension
        ) {
            bins sign_load = {1};
            bins other = {0};
        }

        cp_sram_store : coverpoint (
            t.dmem_wri &&
            t.alu[31:28] == 4'h0
        ) {
            bins sram_store = {1};
            bins other = {0};
        }

        cp_uart_store : coverpoint (
            t.dmem_wri &&
            t.alu[31:28] == 4'h4 &&
            t.alu[15:12] == 4'h0
        ) {
            bins uart_store = {1};
            bins other = {0};
        }

        cp_x0_write : coverpoint (
            t.reg_en && t.rd_addr == 0
        ) {
            bins x0 = {1};
            bins other = {0};
        }
    endgroup

    function new(mailbox #(mem_stage_transaction) mon2cov);
        this.mon2cov = mon2cov;

        cg_operation = new();
        cg_address = new();
        cg_lsu = new();
        cg_store = new();
        cg_load = new();
        cg_wb = new();
        cg_special = new();
    endfunction

    task run();
        mem_stage_transaction txn;

        forever begin
            mon2cov.get(txn);

            cg_operation.sample(txn);
            cg_address.sample(txn);
            cg_lsu.sample(txn);
            cg_store.sample(txn);
            cg_load.sample(txn);
            cg_wb.sample(txn);
            cg_special.sample(txn);
        end
    endtask

    function void report();
        $display("\n============================================================");
        $display("MEM-STAGE COVERAGE");
        $display("============================================================");
        $display("[COV] Operation = %0.2f%%",cg_operation.get_inst_coverage());
        $display("[COV] Address   = %0.2f%%",cg_address.get_inst_coverage());
        $display("[COV] LSU       = %0.2f%%",cg_lsu.get_inst_coverage());
        $display("[COV] Store     = %0.2f%%",cg_store.get_inst_coverage());
        $display("[COV] Load      = %0.2f%%",cg_load.get_inst_coverage());
        $display("[COV] WB        = %0.2f%%",cg_wb.get_inst_coverage());
        $display("[COV] Special   = %0.2f%%",cg_special.get_inst_coverage());
        $display("============================================================");
    endfunction
endclass

// ============================================================================
// AGENT
// ============================================================================

class mem_stage_agent;
    virtual mem_stage_if vif;

    mailbox #(mem_stage_transaction) gen2drv;
    mailbox #(mem_stage_transaction) mon2sb;
    mailbox #(mem_stage_transaction) mon2cov;

    mem_stage_generator generator;
    mem_stage_driver driver;
    mem_stage_monitor monitor;
    mem_stage_ref_model ref_model;

    function new(
        virtual mem_stage_if vif,
        int num_txn
    );
        this.vif = vif;

        gen2drv = new();
        mon2sb = new();
        mon2cov = new();

        ref_model = new();

        generator = new(gen2drv,num_txn);
        driver = new(vif.DRV,gen2drv);
        monitor = new(vif.MON,mon2sb,mon2cov,ref_model,num_txn);
    endfunction

    task run();
        fork
            generator.run();
            driver.run();
            monitor.run();
        join_none
    endtask
endclass

// ============================================================================
// ENVIRONMENT
// ============================================================================

class mem_stage_env;
    mem_stage_agent agent;
    mem_stage_scoreboard scoreboard;
    mem_stage_coverage coverage;

    function new(
        virtual mem_stage_if vif,
        int num_txn
    );
        agent = new(vif,num_txn);
        scoreboard = new(agent.mon2sb);
        coverage = new(agent.mon2cov);
    endfunction

    task run();
        fork
            agent.run();
            scoreboard.run();
            coverage.run();
        join_none
    endtask
endclass

// ============================================================================
// DIRECT TEST
// ============================================================================

class mem_stage_test;
    virtual mem_stage_if vif;
    mem_stage_env env;

    int direct_pass = 0;
    int direct_fail = 0;
    int num_random_txn;

    function new(
        virtual mem_stage_if vif,
        int num_random_txn
    );
        this.vif = vif;
        this.num_random_txn = num_random_txn;
        env = new(vif,num_random_txn);
    endfunction

    task direct_check32(
        string name,
        logic [31:0] actual,
        logic [31:0] expected
    );
        if(actual !== expected) begin
            direct_fail++;
            $error("[DIRECT][FAIL] %s actual=%08h expected=%08h",
                name,actual,expected);
        end
        else begin
            direct_pass++;
            $display("[DIRECT][PASS] %s value=%08h",name,actual);
        end
    endtask

    task direct_check4(
        string name,
        logic [3:0] actual,
        logic [3:0] expected
    );
        if(actual !== expected) begin
            direct_fail++;
            $error("[DIRECT][FAIL] %s actual=%04b expected=%04b",
                name,actual,expected);
        end
        else begin
            direct_pass++;
            $display("[DIRECT][PASS] %s value=%04b",name,actual);
        end
    endtask

    task direct_check1(
        string name,
        logic actual,
        logic expected
    );
        if(actual !== expected) begin
            direct_fail++;
            $error("[DIRECT][FAIL] %s actual=%0b expected=%0b",
                name,actual,expected);
        end
        else begin
            direct_pass++;
            $display("[DIRECT][PASS] %s value=%0b",name,actual);
        end
    endtask

    task drive_idle();
        vif.reg_mem = '0;
        vif.sram_rdata = 32'h0;
        vif.uart_rdata = 32'h0;
        #1;
    endtask

    task direct_idle();
        drive_idle();

        direct_check1("IDLE SRAM_WE",vif.sram_we,1'b0);
        direct_check4("IDLE SRAM_MASK",vif.sram_mask,4'b0000);
        direct_check1("IDLE UART_VALID",vif.uart_tx_valid,1'b0);
        direct_check32("IDLE MEM_RDATA",
            vif.mem_reg.mem_rdata,32'h0);
    endtask

    task direct_lb();
        vif.reg_mem = '0;
        vif.reg_mem.f3 = F3_LB;
        vif.reg_mem.mem_ctrl.dmem_re = 1'b1;
        vif.reg_mem.alu = 32'h0000_0000;
        vif.reg_mem.extension = 1'b1;
        vif.sram_rdata = 32'h0000_0080;
        #1;

        direct_check4("LB MASK",vif.sram_mask,4'b0001);
        direct_check32("LB SIGN",
            vif.mem_reg.mem_rdata,32'hFFFF_FF80);
    endtask

    task direct_lbu();
        vif.reg_mem = '0;
        vif.reg_mem.f3 = F3_LBU;
        vif.reg_mem.mem_ctrl.dmem_re = 1'b1;
        vif.reg_mem.alu = 32'h0000_0000;
        vif.reg_mem.extension = 1'b0;
        vif.sram_rdata = 32'h0000_0080;
        #1;

        direct_check4("LBU MASK",vif.sram_mask,4'b0001);
        direct_check32("LBU ZERO",
            vif.mem_reg.mem_rdata,32'h0000_0080);
    endtask

    task direct_lh();
        vif.reg_mem = '0;
        vif.reg_mem.f3 = F3_LH;
        vif.reg_mem.mem_ctrl.dmem_re = 1'b1;
        vif.reg_mem.alu = 32'h0000_0000;
        vif.reg_mem.extension = 1'b1;
        vif.sram_rdata = 32'h0000_8000;
        #1;

        direct_check4("LH MASK",vif.sram_mask,4'b0011);
        direct_check32("LH SIGN",
            vif.mem_reg.mem_rdata,32'hFFFF_8000);
    endtask

    task direct_lhu();
        vif.reg_mem = '0;
        vif.reg_mem.f3 = F3_LHU;
        vif.reg_mem.mem_ctrl.dmem_re = 1'b1;
        vif.reg_mem.alu = 32'h0000_0000;
        vif.reg_mem.extension = 1'b0;
        vif.sram_rdata = 32'h0000_8000;
        #1;

        direct_check4("LHU MASK",vif.sram_mask,4'b0011);
        direct_check32("LHU ZERO",
            vif.mem_reg.mem_rdata,32'h0000_8000);
    endtask

    task direct_lw();
        vif.reg_mem = '0;
        vif.reg_mem.f3 = F3_LW;
        vif.reg_mem.mem_ctrl.dmem_re = 1'b1;
        vif.reg_mem.alu = 32'h0000_0000;
        vif.sram_rdata = 32'h1234_5678;
        #1;

        direct_check4("LW MASK",vif.sram_mask,4'b1111);
        direct_check32("LW",
            vif.mem_reg.mem_rdata,32'h1234_5678);
    endtask

    task direct_sb();
        vif.reg_mem = '0;
        vif.reg_mem.f3 = F3_SB;
        vif.reg_mem.mem_ctrl.dmem_wri = 1'b1;
        vif.reg_mem.alu = 32'h0000_0001;
        vif.reg_mem.rs2_data = 32'h0000_00AA;
        #1;

        direct_check32("SB DATA",
            vif.sram_wdata,32'h0000_AA00);
        direct_check4("SB MASK",
            vif.sram_mask,4'b0010);
        direct_check1("SB WE",vif.sram_we,1'b1);
    endtask

    task direct_sh();
        vif.reg_mem = '0;
        vif.reg_mem.f3 = F3_SH;
        vif.reg_mem.mem_ctrl.dmem_wri = 1'b1;
        vif.reg_mem.alu = 32'h0000_0002;
        vif.reg_mem.rs2_data = 32'h0000_ABCD;
        #1;

        direct_check32("SH DATA",
            vif.sram_wdata,32'hABCD_0000);
        direct_check4("SH MASK",
            vif.sram_mask,4'b1100);
        direct_check1("SH WE",vif.sram_we,1'b1);
    endtask

    task direct_sw();
        vif.reg_mem = '0;
        vif.reg_mem.f3 = F3_SW;
        vif.reg_mem.mem_ctrl.dmem_wri = 1'b1;
        vif.reg_mem.alu = 32'h0000_0000;
        vif.reg_mem.rs2_data = 32'h1234_5678;
        #1;

        direct_check32("SW DATA",
            vif.sram_wdata,32'h1234_5678);
        direct_check4("SW MASK",
            vif.sram_mask,4'b1111);
        direct_check1("SW WE",vif.sram_we,1'b1);
    endtask

    task direct_sb_all_offsets();
        logic [31:0] expected_data;
        logic [3:0] expected_mask;

        for(int i=0;i<4;i++) begin
            vif.reg_mem = '0;
            vif.reg_mem.f3 = F3_SB;
            vif.reg_mem.mem_ctrl.dmem_wri = 1'b1;
            vif.reg_mem.alu = i;
            vif.reg_mem.rs2_data = 32'h0000_00AA;
            #1;

            expected_data = 32'h0000_00AA << (i*8);
            expected_mask = 4'b0001 << i;

            direct_check32(
                $sformatf("SB OFFSET %0d DATA",i),
                vif.sram_wdata,expected_data
            );

            direct_check4(
                $sformatf("SB OFFSET %0d MASK",i),
                vif.sram_mask,expected_mask
            );

            direct_check1(
                $sformatf("SB OFFSET %0d WE",i),
                vif.sram_we,1'b1
            );
        end
    endtask

    task direct_sh_all_offsets();
        vif.reg_mem = '0;
        vif.reg_mem.f3 = F3_SH;
        vif.reg_mem.mem_ctrl.dmem_wri = 1'b1;
        vif.reg_mem.rs2_data = 32'h0000_ABCD;

        vif.reg_mem.alu = 32'h0000_0000;
        #1;

        direct_check32("SH OFFSET0 DATA",
            vif.sram_wdata,32'h0000_ABCD);
        direct_check4("SH OFFSET0 MASK",
            vif.sram_mask,4'b0011);

        vif.reg_mem.alu = 32'h0000_0002;
        #1;

        direct_check32("SH OFFSET2 DATA",
            vif.sram_wdata,32'hABCD_0000);
        direct_check4("SH OFFSET2 MASK",
            vif.sram_mask,4'b1100);
    endtask

    task direct_uart_store();
        vif.reg_mem = '0;
        vif.reg_mem.f3 = F3_SB;
        vif.reg_mem.mem_ctrl.dmem_wri = 1'b1;
        vif.reg_mem.alu = 32'h4000_0000;
        vif.reg_mem.rs2_data = 32'h0000_0041;
        #1;

        direct_check1("UART VALID",
            vif.uart_tx_valid,1'b1);

        direct_check32("UART DATA",
            {24'h0,vif.uart_tx_data},32'h0000_0041);

        direct_check1("UART SRAM WE",
            vif.sram_we,1'b0);

        direct_check4("UART SRAM MASK",
            vif.sram_mask,4'b0000);
    endtask

    task direct_gpio_store();
        vif.reg_mem = '0;
        vif.reg_mem.f3 = F3_SB;
        vif.reg_mem.mem_ctrl.dmem_wri = 1'b1;
        vif.reg_mem.alu = 32'h4000_1000;
        vif.reg_mem.rs2_data = 32'h0000_55AA;
        #1;

        direct_check1("GPIO SRAM WE",
            vif.sram_we,1'b0);

        direct_check4("GPIO SRAM MASK",
            vif.sram_mask,4'b0000);

        direct_check1("GPIO UART VALID",
            vif.uart_tx_valid,1'b0);
    endtask

    task direct_invalid();
        vif.reg_mem = '0;
        vif.reg_mem.f3 = F3_SB;
        vif.reg_mem.mem_ctrl.dmem_wri = 1'b1;
        vif.reg_mem.alu = 32'h2000_0000;
        vif.reg_mem.rs2_data = 32'h1234_5678;
        #1;

        direct_check1("INVALID SRAM WE",
            vif.sram_we,1'b0);

        direct_check4("INVALID SRAM MASK",
            vif.sram_mask,4'b0000);

        direct_check1("INVALID UART",
            vif.uart_tx_valid,1'b0);
    endtask

    task direct_patterns();
        logic [31:0] patterns[5];

        patterns[0] = 32'h0000_0000;
        patterns[1] = 32'hFFFF_FFFF;
        patterns[2] = 32'hAAAA_AAAA;
        patterns[3] = 32'h5555_5555;
        patterns[4] = 32'h1234_5678;

        for(int i=0;i<5;i++) begin
            vif.reg_mem = '0;
            vif.reg_mem.f3 = F3_SW;
            vif.reg_mem.mem_ctrl.dmem_wri = 1'b1;
            vif.reg_mem.alu = 32'h0;
            vif.reg_mem.rs2_data = patterns[i];
            #1;

            direct_check32(
                $sformatf("PATTERN %0d DATA",i),
                vif.sram_wdata,patterns[i]
            );

            direct_check4(
                $sformatf("PATTERN %0d MASK",i),
                vif.sram_mask,4'b1111
            );
        end
    endtask

    task direct_boundaries();
        vif.reg_mem = '0;
        vif.reg_mem.f3 = F3_LW;
        vif.reg_mem.mem_ctrl.dmem_re = 1'b1;

        vif.reg_mem.alu = 32'h0000_0000;
        vif.sram_rdata = 32'hAAAA_AAAA;
        #1;

        direct_check32("ADDR 0",
            vif.mem_reg.mem_rdata,32'hAAAA_AAAA);

        vif.reg_mem.alu = 32'h0000_03FC;
        vif.sram_rdata = 32'h5555_5555;
        #1;

        direct_check32("ADDR 3FC",
            vif.mem_reg.mem_rdata,32'h5555_5555);
    endtask

    task run_direct_tests();
        $display("");
        $display("============================================================");
        $display("DIRECT MEM-STAGE TESTS");
        $display("============================================================");

        direct_idle();
        direct_lb();
        direct_lbu();
        direct_lh();
        direct_lhu();
        direct_lw();
        direct_sb();
        direct_sh();
        direct_sw();
        direct_sb_all_offsets();
        direct_sh_all_offsets();
        direct_uart_store();
        direct_gpio_store();
        direct_invalid();
        direct_patterns();
        direct_boundaries();

        $display("[DIRECT] PASS=%0d FAIL=%0d",
            direct_pass,direct_fail);
    endtask

    task run_oop_test();
        $display("");
        $display("============================================================");
        $display("OOP RANDOM MEM TEST");
        $display("============================================================");

       
    $display("[%0t] OOP START", $time);

    env.run();

    @env.agent.monitor.done;
    #2;

    $display("[%0t] OOP END", $time);

        $display("[OOP] Random generation completed.");
    endtask

    task report();
        $display("");
        $display("============================================================");
        $display("MEM-STAGE FINAL REPORT");
        $display("============================================================");

        $display("[DIRECT] PASS=%0d FAIL=%0d",
            direct_pass,direct_fail);

        $display("[OOP] SCOREBOARD PASS=%0d FAIL=%0d",
            env.scoreboard.pass_cnt,
            env.scoreboard.fail_cnt);

        env.coverage.report();

        if((direct_fail == 0) &&
           (env.scoreboard.fail_cnt == 0))
            $display("[FINAL] FUNCTIONAL CHECKING = PASS");
        else
            $display("[FINAL] FUNCTIONAL CHECKING = FAIL");

        $display("============================================================");
    endtask

    task run();
        run_direct_tests();
        run_oop_test();
        report();
    endtask
endclass

// ============================================================================
// TOP
// ============================================================================

module tb_mem_stage;

    logic clk;

    mem_stage_if vif(clk);

    mem_stage dut(
        .clk(vif.clk),
        .reg_mem_i(vif.reg_mem),
        .sram_rdata_i(vif.sram_rdata),
        .uart_rdata_i(vif.uart_rdata),
        .mem_reg_o(vif.mem_reg),
        .for_mem_reg_o(),
        .sram_wdata_o(vif.sram_wdata),
        .sram_mask_o(vif.sram_mask),
        .sram_we_o(vif.sram_we),
        .uart_tx_data_o(vif.uart_tx_data),
        .uart_tx_valid_o(vif.uart_tx_valid)
    );

    always #5 clk = ~clk;

    mem_stage_test test;

    initial begin
        $dumpfile("mem_stage.vcd");
        $dumpvars(0,tb_mem_stage);
    end

    initial begin
        clk = 0;

        vif.reg_mem = '0;
        vif.sram_rdata = '0;
        vif.uart_rdata = '0;

        test = new(vif,500);
        test.run();

        $display("");
        $display("============================================================");
        $display("SIMULATION FINISHED");
        $display("============================================================");

        #20;
        $finish;
    end

    initial begin
        #600_000;

        $error("[TB] TIMEOUT");
        $finish;
    end

endmodule