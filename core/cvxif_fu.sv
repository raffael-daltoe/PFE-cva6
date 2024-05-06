// Copyright 2021 Thales DIS design services SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Guillaume CHAUVON (guillaume.chauvon@thalesgroup.com)

// Functional Unit for the logic of the CoreV-X-Interface


module cvxif_fu
  import ariane_pkg::*;
  import riscv::*;
  import xadac_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
) (
    input  logic                                       clk_i,
    input  logic                                       rst_ni,
    input  fu_data_t                                   fu_data_i,
    input  riscv::priv_lvl_t                           priv_lvl_i,
    //from issue
    input  logic                                       x_valid_i,
    output logic                                       x_ready_o,
    input  logic                   [             31:0] x_off_instr_i,
    //to writeback
    output logic                   [TRANS_ID_BITS-1:0] x_trans_id_o,
    output exception_t                                 x_exception_o,
    output riscv::xlen_t                               x_result_o,
    output logic                                       x_valid_o,
    output logic                                       x_we_o,
    //to coprocessor
    xadac_if.mst                                       xadac
);

    if (TRANS_ID_BITS != IdWidth) $error("TRANS_ID_BITS != IdWidth");
    if (NR_RGPR_PORTS < NoRs)     $error("NR_RGPR_PORTS <= NoRs");
    if (XLEN != RegDataWidth)     $error("XLEN != RegDataWidth");
    if (XLEN != RegDataWidth)     $error("XLEN != RegDataWidth");

    // req ====================================================================

    typedef struct packed {
        IdT                 id;
        InstrT              instr;
        RegAddrT [NoRs-1:0] rs_addr;
        RegDataT [NoRs-1:0] rs_data;
    } x_req_t;

    x_req_t x_req;
    logic   x_req_valid;
    logic   x_req_ready;

    x_req_t x_req_mid;
    logic   x_req_mid_valid;
    logic   x_req_mid_ready;

    x_req_t x_req_spill;
    logic   x_req_spill_valid;
    logic   x_req_spill_ready;

    assign x_req.id         = fu_data_i.trans_id;
    assign x_req.instr      = x_off_instr_i;
    assign x_req.rs_addr[0] = x_off_instr_i[19:15];
    assign x_req.rs_addr[1] = x_off_instr_i[24:20];
    assign x_req.rs_data[0] = fu_data_i.operand_a;
    assign x_req.rs_data[1] = fu_data_i.operand_b;
    assign x_req_valid      = x_valid_i;
    assign x_ready_o        = x_req_ready;

    spill_register #(
        .T      (x_req_t),
        .Bypass (0)
    ) i_x_req_mid (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),

        .valid_i (x_req_valid),
        .ready_o (x_req_ready),
        .data_i  (x_req),

        .valid_o (x_req_mid_valid),
        .ready_i (x_req_mid_ready),
        .data_o  (x_req_mid)
    );

    spill_register #(
        .T      (x_req_t),
        .Bypass (0)
    ) i_x_req_spill (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),

        .valid_i (x_req_mid_valid),
        .ready_o (x_req_mid_ready),
        .data_i  (x_req_mid),

        .valid_o (x_req_spill_valid),
        .ready_i (x_req_spill_ready),
        .data_o  (x_req_spill)
    );

    assign xadac.dec_req.id    = x_req_spill.id;
    assign xadac.dec_req.instr = x_req_spill.instr;

    assign xadac.exe_req.id         = x_req_spill.id;
    assign xadac.exe_req.instr      = x_req_spill.instr;
    assign xadac.exe_req.rs_addr    = x_req_spill.rs_addr;
    assign xadac.exe_req.rs_data    = x_req_spill.rs_data;
    assign xadac.exe_req.vs_addr[0] = x_req_spill.instr[19:15];
    assign xadac.exe_req.vs_addr[1] = x_req_spill.instr[24:20];
    assign xadac.exe_req.vs_addr[2] = x_req_spill.instr[11: 7];
    assign xadac.exe_req.vs_data = '0;

    logic dec_req_done_d, dec_req_done_q;
    logic exe_req_done_d, exe_req_done_q;

    always_comb begin : comb_req

        dec_req_done_d = dec_req_done_q;
        exe_req_done_d = exe_req_done_q;

        /* xadac dec req */

        xadac.dec_req_valid = x_req_spill_valid && !dec_req_done_d;

        if (xadac.dec_req_valid && xadac.dec_req_ready) begin
            dec_req_done_d = '1;
        end

        /* xadac exe req */

        xadac.exe_req_valid = x_req_spill_valid && !exe_req_done_d;

        if (xadac.exe_req_valid && xadac.exe_req_ready) begin
            exe_req_done_d = '1;
        end

        /* cva6 issue */

        x_req_spill_ready = (dec_req_done_d && exe_req_done_d);

        if (x_req_spill_valid && x_req_spill_ready) begin
            dec_req_done_d = '0;
            exe_req_done_d = '0;
        end
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin : seq_req
        if (~rst_ni) begin
            dec_req_done_q <= '0;
            exe_req_done_q <= '0;
        end
        else begin
            dec_req_done_q <= dec_req_done_d;
            exe_req_done_q <= exe_req_done_d;
        end
    end

    // rsp ====================================================================

    always_comb begin : gen_rsp

        x_trans_id_o        = '0;
        x_exception_o.cause = '0;
        x_exception_o.valid = '0;
        x_exception_o.tval  = '0;
        x_result_o          = '0;
        x_valid_o           = '0;
        x_we_o              = '0;

        /* xadac dec rsp */

        xadac.dec_rsp_ready = !xadac.exe_rsp_valid;

        if (xadac.dec_rsp_valid && xadac.dec_rsp_ready) begin
            if (!xadac.dec_rsp.accept) begin
                x_trans_id_o        = xadac.dec_rsp.id;
                x_exception_o.cause = riscv::ILLEGAL_INSTR;
                x_exception_o.valid = '1;
                x_exception_o.tval  = 32'h0BAD_ADAC;
                x_result_o          = '0;
                x_valid_o           = '1;
                x_we_o              = '0;
            end
        end

        /* xadac exe rsp */

        xadac.exe_rsp_ready = '1;

        if(xadac.exe_rsp_valid && xadac.exe_rsp_ready) begin
            x_trans_id_o        = xadac.exe_rsp.id;
            x_exception_o.cause = '0;
            x_exception_o.valid = '0;
            x_exception_o.tval  = '0;
            x_result_o          = xadac.exe_rsp.rd_data;
            x_valid_o           = '1;
            x_we_o              = xadac.exe_rsp.rd_write;
        end

    end

endmodule
