module xadac_vmacc
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
        slv.dec_rsp.rs_read[0] = '0;
        slv.dec_rsp.rs_read[1] = '0;
        slv.dec_rsp.vs_read[0] = '1;
        slv.dec_rsp.vs_read[1] = '1;
        slv.dec_rsp.vs_read[2] = '1;
        slv.dec_rsp.accept = '1;
    end

    always_comb begin : comb_exe
        automatic SizeT ilen, jlen;

        ilen = VectorWidth/SumWidth;
        jlen = min(slv.exe_req.instr[25 +: VecLenT], SumWidth/ElemWidth);

        slv.exe_rsp_valid = slv.exe_req_valid;
        slv.exe_req_ready = (slv.exe_rsp_valid && slv.exe_rsp_ready);

        slv.exe_rsp         = '0;
        slv.exe_rsp.id      = slv.exe_req_id;
        slv.exe_rsp.vd_addr = slv.exe_req.instr[11:7];
        slv.exe_rsp.vd_data = slv.exe_req.vs_data[2];
        for (SizeT i = 0; i < ilen; i++) begin
            for (SizeT j = 0; j < jlen; j++) begin
                slv.exe_rsp.vd_data[SumWidth*i +: SumWidth] += unsigned'(
                    signed'(slv.exe_req.vs_data[0][jlen*i + j]) *
                    unsigned'(slv.exe_req.vs_data[1][jlen*i + j])
                );
            end
        end
    end

endmodule
