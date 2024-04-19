module xadac_vrf
    import xadac_pkg::*;
(
    input logic  clk,
    input logic  rstn,
    xadac_if.slv slv,
    xadac_if.mst mst
);

    // decode passthrough =====================================================

    assign mst.dec_req       = slv.dec_req;
    assign mst.dec_req_valid = slv.dec_req_valid;
    assign slv.dec_req_ready = mst.dec_req_ready;

    assign slv.dec_rsp       = mst.dec_rsp;
    assign slv.dec_rsp_valid = mst.dec_rsp_valid;
    assign mst.dec_rsp_ready = slv.dec_rsp_ready;

    // vf phy =================================================================

    RegIdT  [NoVs-1:0] phy_rid;
    VectorT [NoVs-1:0] phy_rdata;
    RegIdT             phy_wid;
    VectorT            phy_wdata;
    logic              phy_we;

    xadac_vrf_phy i_phy (
        .clk  (clk),
        .rstn (rstn),

        .rid   (phy_rid),
        .rdata (phy_rdata),
        .wid   (phy_wid),
        .wdata (phy_wdata),
        .we    (phy_we)
    );

    // exe ====================================================================

    always_comb begin : comb_exe_req
        phy_rid = slv.exe_req.vs_data;

        mst.exe_req.id      = slv.exe_req.id;
        mst.exe_req.instr   = slv.exe_req.instr;
        mst.exe_req.rs_addr = slv.exe_req.rs_addr;
        mst.exe_req.rs_data = slv.exe_req.rs_data;
        mst.exe_req.vs_addr = slv.exe_req.vs_addr;
        mst.exe_req.vs_data = phy_rdata;

        mst.exe_req_valid = slv.exe_req_valid;
        slv.exe_req_ready = mst.exe_req_ready;
    end

    always_comb begin : comb_exe_rsp
        if (mst.exe_rsp_valid && mst.exe_rsp_ready) begin
            phy_wid   = mst.exe_rsp.vd_id;
            phy_wdata = mst.exe_rsp.vd;
            phy_we    = mst.exe_rsp.vd_write;
        end
        else begin
            phy_wid   = '0;
            phy_wdata = '0;
            phy_we    = '0;
        end

        slv.exe_rsp       = mst.exe_rsp;
        slv.exe_rsp_valid = mst.exe_rsp_valid;
        mst.exe_rsp_ready = slv.exe_rsp_ready;
    end

endmodule
