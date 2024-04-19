module xadac_mux
    import xadac_pkg::*;
#(
    parameter int unsigned NoMst = 4,
    parameter InstrT [NoMst-1:0] Mask = '0,
    parameter InstrT [NoMst-1:0] Match = '0
) (
    input logic  clk,
    input logic  rstn,
    xadac_if.slv slv,
    xadac_if.mst mst [NoMst]
);

    typedef logic [$clog2(NoMst)-1:0] idx_t;

    DecReqT [NoMst-1:0] mst_dec_req;
    logic   [NoMst-1:0] mst_dec_req_valid;
    logic   [NoMst-1:0] mst_dec_req_ready;

    DecRspT [NoMst-1:0] mst_dec_rsp;
    logic   [NoMst-1:0] mst_dec_rsp_valid;
    logic   [NoMst-1:0] mst_dec_rsp_ready;

    ExeReqT [NoMst-1:0] mst_exe_req;
    logic   [NoMst-1:0] mst_exe_req_valid;
    logic   [NoMst-1:0] mst_exe_req_ready;

    ExeRspT [NoMst-1:0] mst_exe_rsp;
    logic   [NoMst-1:0] mst_exe_rsp_valid;
    logic   [NoMst-1:0] mst_exe_rsp_ready;

    idx_t [SbLen-1:0] sb_d, sb_q;
    idx_t dec_rsp_idx_d, dec_rsp_idx_q;
    idx_t exe_rsp_idx_d, exe_rsp_idx_q;

    for (genvar i = 0; i < NoMst; i++) begin : gen_mst_signal_assign
        assign mst[i].dec_req       = mst_dec_req[i];
        assign mst[i].dec_req_valid = mst_dec_req_valid[i];
        assign mst_dec_req_ready[i] = mst[i].dec_req_ready;

        assign mst_dec_rsp[i]       = mst[i].dec_rsp;
        assign mst_dec_rsp_valid[i] = mst[i].dec_rsp_valid;
        assign mst[i].dec_rsp_ready = mst_dec_rsp_ready[i];

        assign mst[i].exe_req       = mst_exe_req[i];
        assign mst[i].exe_req_valid = mst_exe_req_valid[i];
        assign mst_exe_req_ready[i] = mst[i].exe_req_ready;

        assign mst_exe_rsp[i]       = mst[i].exe_rsp;
        assign mst_exe_rsp_valid[i] = mst[i].exe_rsp_valid;
        assign mst[i].exe_rsp_ready = mst_exe_rsp_ready[i];
    end

    always_comb begin
        automatic SizeT idx;

        sb_d          = sb_q;
        dec_rsp_idx_d = dec_rsp_idx_q;
        exe_rsp_idx_d = exe_rsp_idx_q;

        // dec req ============================================================

        mst_dec_req         = '0;
        mst_dec_req_valid   = '0;
        slv.dec_req_ready   = '0;

        if (slv.dec_req_valid) begin
            for (idx = 0; idx < NoMst; idx++) begin
                if (slv.instr & Mask[idx] == Match[idx]) break;
            end

            mst_dec_req[idx]       = slv.dec_req;
            mst_dec_req_valid[idx] = slv.dec_req_valid;
            slv.dec_req_ready      = mst_dec_req_valid[idx];

            sb_d[slv.dec_req.id] = idx;
        end

        // dec rsp ============================================================

        slv.dec_rsp       = '0;
        slv.dec_rsp_valid = '0;
        mst_dec_rsp_ready = '0;

        for (idx = 0; idx < NoMst; idx++) begin
            if (mst_dec_rsp_valid[dec_rsp_idx_d]) break;
            if (mst_dec_rsp_valid[idx]) break;
        end

        slv.dec_rsp            = mst_dec_rsp[idx];
        slv.dec_rsp_valid      = mst_dec_rsp_valid[idx];
        mst_dec_rsp_ready[idx] = slv.dec_rsp_ready;

        dec_rsp_idx_d = idx;

        // exe req ============================================================

        mst_exe_req       = '0;
        mst_exe_req_valid = '0;
        slv.exe_req_ready = '0;

        if (slv.exe_req_valid) begin
            idx = sb_d[slv.exe_req.id];

            mst_exe_req[idx]       = slv.exe_req;
            mst_exe_req_valid[idx] = slv.exe_req_valid;
            slv.exe_req_ready      = mst_exe_req_ready[idx];
        end

        // exe rsp ============================================================

        slv.exe_rsp            = '0;
        slv.exe_rsp_valid      = '0;
        mst_exe_rsp_ready[idx] = '0;

        for (idx = 0; idx < NoMst; idx++) begin
            if (mst_exe_rsp_valid[exe_rsp_idx_d]) break;
            if (mst_exe_rsp_valid[idx]) break;
        end

        slv.exe_rsp            = mst_exe_rsp[idx];
        slv.exe_rsp_valid      = mst_exe_rsp_valid[idx];
        mst_exe_rsp_ready[idx] = slv.exe_rsp_ready;

        exe_rsp_idx_d = idx;
    end

    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            sb_q          <= '0;
            dec_rsp_idx_q <= '0;
            exe_rsp_idx_q <= '0;
        end
        else begin
            sb_q          <= sb_d;
            dec_rsp_idx_q <= dec_rsp_idx_d;
            exe_rsp_idx_q <= exe_rsp_idx_d;
        end
    end

endmodule
