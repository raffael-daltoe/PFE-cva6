module xadac_vclobber
    import xadac_pkg::*;
(
    input logic  clk,
    input logic  rstn,
    xadac_if.slv slv,
    xadac_if.mst mst
);

    assign mst.dec_req = slv.dec_req;
    assign slv.dec_rsp = mst.dec_rsp;
    assign mst.exe_req = slv.exe_req;
    assign slv.exe_rsp = mst.exe_rsp;

    typedef struct packed {
        RegAddrT vd_addr;
        logic    vd_clobber;

        logic [NoVs-1:0] vs_read;

        logic  dec_req_done;
        logic  dec_rsp_done;
        logic  exe_req_done;
        logic  exe_rsp_done;
    } entry_t;

    entry_t [SbLen-1:0] sb_d, sb_q;
    logic   [NoVec-1:0] clobber_d, clobber_q;

    always_comb begin
        automatic IdT id;
        automatic RegAddrT [NoVs-1:0] vs_addr;

        sb_d      = sb_q;
        clobber_d = clobber_q;

        // dec req ============================================================

        id = slv.dec_req.id;

        mst.dec_req_valid = (
            slv.dec_req_valid &&
            !sb_d[id].dec_req_done
        );

        slv.dec_req_ready = (mst.dec_req_valid && mst.dec_req_ready);

        if (slv.dec_req_valid && slv.dec_req_ready) begin
            sb_d[id].vd_addr = slv.dec_req.instr[11:7];
            sb_d[id].dec_req_done = '1;
        end

        // dec rsp ============================================================

        id = mst.dec_rsp.id;

        slv.dec_rsp_valid = (
            mst.dec_rsp_valid &&
            // sb_d[id].dec_req_done &&
            !sb_d[id].dec_rsp_done
        );

        mst.dec_rsp_ready = (slv.dec_rsp_valid && slv.dec_rsp_ready);

        if (mst.dec_rsp_valid && mst.dec_rsp_ready) begin
            sb_d[id].vd_clobber = mst.dec_rsp.vd_clobber;
            sb_d[id].vs_read    = mst.dec_rsp.vs_read;
            sb_d[id].dec_rsp_done = '1;
            if (!mst.dec_rsp.accept) sb_d[id] = '0;
        end

        // exe req ============================================================

        id = slv.exe_req.id;

        vs_addr[0] = slv.exe_req.instr[19:15];
        vs_addr[1] = slv.exe_req.instr[24:20];
        vs_addr[2] = slv.exe_req.instr[11: 7];

        mst.exe_req_valid = (
            slv.exe_req_valid &&
            sb_d[id].dec_rsp_done &&
            !sb_d[id].exe_req_done
        );

        if (sb_d[id].vd_clobber && clobber_d[sb_d[id].vd_addr]) begin
            mst.exe_req_valid = '0;
        end

        for (SizeT i = 0; i < NoVs; i++) begin
            if (sb_d[id].vs_read[i] && clobber_d[vs_addr[i]]) begin
                mst.exe_req_valid = '0;
            end
        end

        slv.exe_req_ready = (mst.exe_req_valid && mst.exe_req_ready);

        if (slv.exe_req_valid && slv.exe_req_ready) begin
            if (sb_d[id].vd_clobber) clobber_d[sb_d[id].vd_addr] = '1;
            sb_d[id].exe_req_done = '1;
        end

        // exe rsp ============================================================

        id = mst.exe_rsp.id;

        slv.exe_rsp_valid = (
            mst.exe_rsp_valid &&
            sb_d[id].exe_req_done &&
            !sb_d[id].exe_rsp_done
        );

        mst.exe_rsp_ready = (slv.exe_rsp_valid && slv.exe_rsp_ready);

        if (mst.exe_rsp_valid && mst.exe_rsp_ready) begin
            if (sb_d[id].vd_clobber) clobber_d[sb_d[id].vd_addr] = '0;
            sb_d[id].exe_rsp_done = '1;
        end

        // end ================================================================

        for (int i = 0; i < SbLen; i++) begin
            if (
                sb_d[i].dec_req_done &&
                sb_d[i].dec_rsp_done &&
                sb_d[i].exe_req_done &&
                sb_d[i].exe_rsp_done
            ) begin
                sb_d[i] = '0;
            end
        end
    end

    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            sb_q      <= '0;
            clobber_q <= '0;
        end
        else begin
            sb_q      <= sb_d;
            clobber_q <= clobber_d;
        end
    end

endmodule
