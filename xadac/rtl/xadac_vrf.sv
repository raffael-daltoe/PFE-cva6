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

    VecAddrT [NoVs-1:0] phy_raddr;
    VecDataT [NoVs-1:0] phy_rdata;
    VecAddrT            phy_waddr;
    VecDataT            phy_wdata;
    logic               phy_we;

    xadac_vrf_phy i_phy (
        .clk  (clk),
        .rstn (rstn),

        .raddr (phy_raddr),
        .rdata (phy_rdata),
        .waddr (phy_waddr),
        .wdata (phy_wdata),
        .we    (phy_we)
    );

    // exe ====================================================================

    assign phy_raddr = slv.exe_req.vs_addr;

    assign mst.exe_req.id      = slv.exe_req.id;
    assign mst.exe_req.instr   = slv.exe_req.instr;
    assign mst.exe_req.rs_addr = slv.exe_req.rs_addr;
    assign mst.exe_req.rs_data = slv.exe_req.rs_data;
    assign mst.exe_req.vs_addr = slv.exe_req.vs_addr;
    assign mst.exe_req.vs_data = phy_rdata;

    assign mst.exe_req_valid = slv.exe_req_valid;
    assign slv.exe_req_ready = mst.exe_req_ready;

    always_comb begin : comb_exe_rsp
        slv.exe_rsp       = mst.exe_rsp;
        slv.exe_rsp_valid = mst.exe_rsp_valid;
        mst.exe_rsp_ready = slv.exe_rsp_ready;

        if (mst.exe_rsp_valid && mst.exe_rsp_ready) begin
            phy_waddr = mst.exe_rsp.vd_addr;
            phy_wdata = mst.exe_rsp.vd_data;
            phy_we    = mst.exe_rsp.vd_write;
        end
        else begin
            phy_waddr = '0;
            phy_wdata = '0;
            phy_we    = '0;
        end
    end

endmodule
