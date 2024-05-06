module xadac_if_cut
    import xadac_pkg::*;
#(
    parameter bit BypassDecReq = 0,
    parameter bit BypassDecRsp = 0,
    parameter bit BypassExeReq = 0,
    parameter bit BypassExeRsp = 0
) (
    input logic  clk,
    input logic  rstn,
    xadac_if.slv slv,
    xadac_if.mst mst
);

    xadac_cut #(
        .Bypass (BypassDecReq),
        .DataT  (DecReqT)
    ) i_dec_req_cut (
        .clk  (clk),
        .rstn (rstn),

        .slv_data  (slv.dec_req),
        .slv_valid (slv.dec_req_valid),
        .slv_ready (slv.dec_req_ready),

        .mst_data  (mst.dec_req),
        .mst_valid (mst.dec_req_valid),
        .mst_ready (mst.dec_req_ready)
    );

    xadac_cut #(
        .Bypass (BypassDecRsp),
        .DataT  (DecRspT)
    ) i_dec_rsp_cut (
        .clk  (clk),
        .rstn (rstn),

        .slv_data  (mst.dec_rsp),
        .slv_valid (mst.dec_rsp_valid),
        .slv_ready (mst.dec_rsp_ready),

        .mst_data  (slv.dec_rsp),
        .mst_valid (slv.dec_rsp_valid),
        .mst_ready (slv.dec_rsp_ready)
    );

    xadac_cut #(
        .Bypass (BypassExeReq),
        .DataT  (ExeReqT)
    ) i_exe_req_cut (
        .clk  (clk),
        .rstn (rstn),

        .slv_data  (slv.exe_req),
        .slv_valid (slv.exe_req_valid),
        .slv_ready (slv.exe_req_ready),

        .mst_data  (mst.exe_req),
        .mst_valid (mst.exe_req_valid),
        .mst_ready (mst.exe_req_ready)
    );

    xadac_cut #(
        .Bypass (BypassExeRsp),
        .DataT  (ExeRspT)
    ) i_exe_rsp_cut (
        .clk  (clk),
        .rstn (rstn),

        .slv_data  (mst.exe_rsp),
        .slv_valid (mst.exe_rsp_valid),
        .slv_ready (mst.exe_rsp_ready),

        .mst_data  (slv.exe_rsp),
        .mst_valid (slv.exe_rsp_valid),
        .mst_ready (slv.exe_rsp_ready)
    );

endmodule
