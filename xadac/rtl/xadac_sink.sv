module xadac_sink
    import xadac_pkg::*;
(
    input logic  clk,
    input logic  rstn,
    xadac_if.slv slv
);

    always_comb begin : comb_dec
        slv.dec_rsp_valid = slv.dec_req_valid;
        slv.dec_req_ready = (slv.dec_rsp_valid && slv.dec_rsp_ready);

        slv.dec_rsp.id = slv.dec_req.id;
        slv.dec_rsp.rd_clobber = '0;
        slv.dec_rsp.vd_clobber = '0;
        slv.dec_rsp.rs_read[0] = '0;
        slv.dec_rsp.rs_read[1] = '0;
        slv.dec_rsp.vs_read[0] = '0;
        slv.dec_rsp.vs_read[1] = '0;
        slv.dec_rsp.vs_read[2] = '0;
        slv.dec_rsp.accept = '0;
    end

    always_comb begin : comb_exe
        slv.exe_req_ready = '0;

        slv.exe_rsp    = '0;
        slv.exe_rsp_valid = '0;
    end

endmodule
