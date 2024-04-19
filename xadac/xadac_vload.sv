module xadac_vload
    import xadac_pkg::*;
(
    input logic  clk,
    input logic  rstn,
    xadac_if.slv slv,

    output IdT   axi_ar_id,
    output AddrT axi_ar_addr,
    output logic axi_ar_valid,
    input  logic axi_ar_ready,

    input  IdT      axi_r_id,
    input  VecDataT axi_r_data,
    input  logic    axi_r_valid,
    output logic    axi_r_ready
);

    typedef struct packed {
        AddrT    addr;
        VecAddrT vd_addr;
        VecLenT  vlen;
        VecDataT rdata;
        logic    exe_req_done;
        logic    exe_rsp_done;
        logic    axi_ar_done;
        logic    axi_r_done;
    } entry_t;

    entry_t [SbLen-1:0] sb_d, sb_q;

    ExeRspT exe_rsp_d;
    logic   exe_rsp_valid_d;

    IdT   axi_ar_id_d;
    AddrT axi_ar_addr_d;
    logic axi_ar_valid_d;

    logic axi_r_ready_d;

    always_comb begin : comb
        automatic IdT id;

        sb_d    = sb_q;

        exe_rsp_d       = slv.exe_rsp;
        exe_rsp_valid_d = slv.exe_rsp_valid;

        axi_ar_id_d    = axi_ar_id;
        axi_ar_addr_d  = axi_ar_addr;
        axi_ar_valid_d = axi_ar_valid;

        axi_r_ready_d = axi_r_ready;

        // dec ================================================================

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

        // exe req channel ====================================================

        id = slv.exe_req.id;

        slv.exe_req_ready = (slv.exe_req_valid && !sb_d[id].exe_req_done);

        if (slv.exe_req_valid && slv.exe_req_ready) begin
            sb_d[id].addr     = AddrT'(slv.req_rs1);
            sb_d[id].vd_addr  = slv.exe_req.instr[11:7];
            sb_d[id].vlen     = slv.exe_req.instr[25 +: VecLenWidth];
            sb_d[id].exe_req_done = '1;
        end

        // axi ar =============================================================

        id = axi_ar_id;

        if (axi_ar_valid && axi_ar_ready) begin
            axi_ar_id_d    = '0;
            axi_ar_addr_d  = '0;
            axi_ar_valid_d = '0;
        end

        for(id = 0; id < SbLen; id++) begin
            if(
                !axi_ar_valid_d &&
                sb_d[id].req_done &&
                !sb_d[id].axi_ar_done
            ) begin
                axi_ar_id_d    = id;
                axi_ar_addr_d  = sb_d[id].addr;
                axi_ar_valid_d = '1;
                sb_d[id].axi_ar_done = '1;
            end
        end

        // axi r ==============================================================

        id = axi_r_id;

        if (axi_r_valid && axi_r_ready) begin
            sb_d[id].data = axi_r_data;
            sb_d[id].axi_r_done = '1;
        end

        // exe rsp ============================================================

        id = slv.exe_rsq.id;

        if (slv.exe_rsp_valid && obi.exe_rsp_ready) begin
            exe_rsp_d        = '0;
            exe_rsp_valid_d  = '0;
        end

        for(id = 0; id < SbLen; id++) begin
            if(
                !exe_rsp_valid_d &&
                sb_d[id].axi_r_done &&
                !sb_d[id].exe_rsp_done
            ) begin

                automatic VecDataT vd_data = '0;
                for (VecLenT i = 0; i < VectorWidth/ElemWidth; i++) begin
                    automatic VecLenT j = (i % sb_d[id].vlen);
                    vd_data[VecElemWidth*i +: VecElemWidth] =
                        sb_d[id].rdata[VecElemWidth*j +: VecElemWidth];
                end

                exe_rsp_d          = '0;
                exe_rsp_d.id       = id;
                exe_rsp_d.vd_addr  = sb_d[id].vd_addr;
                exe_rsp_d.vd_data  = vd_data;
                exe_rsp_d.vd_write = '1;
                exe_rsp_valid_d    = '1;

                sb_d[id].exe_rsp_done = '1;
            end
        end

        // end ================================================================

        for (id = 0; id < SbLen; id++) begin
            if (
                sb_d[id].exe_req_done &&
                sb_d[id].exe_rsp_done &&
                sb_d[id].axi_ar_done &&
                sb_d[id].axi_r_done
            ) begin
                sb_d[id] = '0;
            end
        end
    end

    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            sb_q <= '0;

            slv.exe_rsp       <= '0;
            slv.exe_rsp_valid <= '0;

            axi_ar_id    <= '0;
            axi_ar_addr  <= '0;
            axi_ar_valid <= '0;

            axi_r_valid <= '0;
        end
        else begin
            sb_q <= sb_q;

            slv.exe_rsp       <= exe_rsp_d;
            slv.exe_rsp_valid <= exe_rsp_valid_d;

            axi_ar_id    <= axi_ar_id_d;
            axi_ar_addr  <= axi_ar_addr_d;
            axi_ar_valid <= axi_ar_valid_d;

            axi_r_valid <= axi_r_ready_d;
        end
    end

endmodule
