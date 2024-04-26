module xadac_vbias
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
        slv.dec_rsp.vd_clobber = '1;
        slv.dec_rsp.rs_read[0] = '1;
        slv.dec_rsp.rs_read[1] = '0;
        slv.dec_rsp.vs_read[0] = '0;
        slv.dec_rsp.vs_read[1] = '0;
        slv.dec_rsp.vs_read[2] = '0;
        slv.dec_rsp.accept = '1;
    end

    always_comb begin : comb_exe
        automatic VecLenT vlen;

        vlen = slv.exe_req.instr[25 +: VecLenWidth];

        slv.exe_rsp_valid = slv.exe_req_valid;
        slv.exe_req_ready = (slv.exe_rsp_valid && slv.exe_rsp_ready);

        slv.exe_rsp    = '0;
        slv.exe_rsp.id = slv.exe_req.id;
        slv.exe_rsp.vd_addr  = slv.exe_req.instr[11:7];
        slv.exe_rsp.vd_data  = '0;
        slv.exe_rsp.vd_write = '1;
        for (VecLenT i = 0; i < vlen; i++) begin
            slv.exe_rsp.vd_data[VecSumWidth*i +: VecSumWidth] =
                VecSumT'(slv.exe_req.rs_data[0]);
        end
    end

endmodule
