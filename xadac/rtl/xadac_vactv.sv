module xadac_vactv
    import xadac_pkg::*;
(
    input logic     clk,
    input logic     rstn,
    xadac_if.slv    slv,

    output IdT      axi_aw_id,
    output AddrT    axi_aw_addr,
    output logic    axi_aw_valid,
    input  logic    axi_aw_ready,

    output VecDataT axi_w_data,
    output VecStrbT axi_w_strb,
    output logic    axi_w_valid,
    input  logic    axi_w_ready,

    input  IdT   axi_b_id,
    input  logic axi_b_valid,
    output logic axi_b_ready
);

    localparam SizeT ILenWidth = $clog2(VecDataWidth/VecSumWidth+1);

    typedef logic [ILenWidth-1:0] ilen_t;

    typedef struct packed {
        AddrT    addr;
        VecDataT data;
        VecStrbT strb;
        logic    exe_req_done;
        logic    exe_rsp_done;
        logic    axi_aw_done;
        logic    axi_w_done;
        logic    axi_b_done;
    } entry_t;

    entry_t [SbLen-1:0] sb_d, sb_q;

    ExeRspT exe_rsp_d;
    logic   exe_rsp_valid_d;

    IdT   axi_aw_id_d;
    AddrT axi_aw_addr_d;
    logic axi_aw_valid_d;

    VecDataT axi_w_data_d;
    VecStrbT axi_w_strb_d;
    logic    axi_w_valid_d;

    always_comb begin
        automatic IdT       id    = '0;
        automatic VecLenT   vlen  = '0;
        automatic RegDataT  shift = '0;
        automatic VecDataT  data  = '0;
        automatic VecSumT   sum   = '0;
        automatic VecElemT  elem  = '0;

        sb_d = sb_q;

        exe_rsp_d       = slv.exe_rsp;
        exe_rsp_valid_d = slv.exe_rsp_valid;

        axi_aw_id_d    = axi_aw_id;
        axi_aw_addr_d  = axi_aw_addr;
        axi_aw_valid_d = axi_aw_valid;

        axi_w_data_d  = axi_w_data;
        axi_w_strb_d  = axi_w_strb;
        axi_w_valid_d = axi_w_valid;

        // dec ================================================================

        slv.dec_rsp_valid = slv.dec_req_valid;
        slv.dec_req_ready = (slv.dec_rsp_valid && slv.dec_rsp_ready);

        slv.dec_rsp.id = slv.dec_req.id;
        slv.dec_rsp.rd_clobber = '0;
        slv.dec_rsp.vd_clobber = '0;
        slv.dec_rsp.rs_read[0] = '1;
        slv.dec_rsp.rs_read[1] = '0;
        slv.dec_rsp.vs_read[0] = '0;
        slv.dec_rsp.vs_read[1] = '0;
        slv.dec_rsp.vs_read[2] = '1;
        slv.dec_rsp.accept = '1;

        // exe req ============================================================

        id = slv.exe_req.id;

        slv.exe_req_ready = (slv.exe_req_valid && !sb_d[id].exe_req_done);

        if (slv.exe_req_valid && slv.exe_req_ready) begin
            shift = RegDataT'(slv.exe_req.rs_data[1]);
            vlen  = slv.exe_req.instr[25 +: VecLenWidth];

            data = '0;
            for (SizeT i = 0; i < VecDataWidth/VecSumWidth; i++) begin
                if (i < vlen) begin
                    sum = slv.exe_req.vs_data[2][VecSumWidth*i +: VecSumWidth];
                    elem = VecElemT'((signed'(sum) > 0) ? (sum >> shift) : 0);
                    data[VecElemWidth*i +: VecElemWidth] = elem;
                end
            end

            sb_d[id].addr = AddrT'(slv.exe_req.rs_data[0]);
            sb_d[id].strb = VecStrbT'((1 << vlen) - 1);
            sb_d[id].data = data;

            sb_d[id].exe_req_done = '1;
        end

        // axi aw =============================================================

        if (axi_aw_valid && axi_aw_ready) begin
            axi_aw_id_d    = '0;
            axi_aw_addr_d  = '0;
            axi_aw_valid_d = '0;
        end

        for(SizeT i = 0; i < SbLen; i++) begin
            id = IdT'(i);
            if(
                !axi_aw_valid_d &&
                sb_d[id].exe_req_done &&
                !sb_d[id].axi_aw_done
            ) begin
                axi_aw_id_d    = IdT'(id);
                axi_aw_addr_d  = sb_d[id].addr;
                axi_aw_valid_d = '1;
                sb_d[id].axi_aw_done = '1;
            end
        end

        // axi w ==============================================================

        if (axi_w_valid && axi_w_ready) begin
            axi_w_data_d  = '0;
            axi_w_strb_d  = '0;
            axi_w_valid_d = '0;
        end

        for(SizeT i = 0; i < SbLen; i++) begin
            id = IdT'(i);
            if(
                !axi_w_valid_d &&
                sb_d[id].exe_req_done &&
                !sb_d[id].axi_w_done
            ) begin
                axi_w_data_d  = sb_d[id].data;
                axi_w_strb_d  = sb_d[id].strb;
                axi_w_valid_d = '1;
                sb_d[id].axi_w_done = '1;
            end
        end

        // obi b channel ======================================================

        id = axi_b_id;

        axi_b_ready = (
            axi_b_valid &&
            sb_d[id].axi_aw_done &&
            sb_d[id].axi_w_done &&
            !sb_d[id].axi_b_done
        );

        if (axi_b_valid && axi_b_ready) begin
            sb_d[id].axi_b_done = '1;
        end

        // exe rsp ============================================================

        id = slv.exe_rsp.id;

        if (slv.exe_rsp_valid && slv.exe_rsp_ready) begin
            exe_rsp_d       = '0;
            exe_rsp_valid_d = '0;
        end

        for(SizeT i = 0; i < SbLen; i++) begin
            id = IdT'(i);
            if(
                !exe_rsp_valid_d &&
                sb_d[id].axi_b_done &&
                !sb_d[id].exe_rsp_done
            ) begin
                exe_rsp_d       = '0;
                exe_rsp_d.id    = IdT'(id);
                exe_rsp_valid_d = '1;
                sb_d[id].exe_rsp_done = '1;
            end
        end

        // clean sb ===========================================================

        for (SizeT i = 0; i < SbLen; i++) begin
            id = IdT'(i);
            if (
                sb_d[id].exe_req_done &&
                sb_d[id].exe_rsp_done &&
                sb_d[id].axi_aw_done &&
                sb_d[id].axi_w_done &&
                sb_d[id].axi_b_done
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

            axi_aw_id    <= '0;
            axi_aw_addr  <= '0;
            axi_aw_valid <= '0;

            axi_w_data  <= '0;
            axi_w_strb  <= '0;
            axi_w_valid <= '0;
        end
        else begin
            sb_q <= sb_d;

            slv.exe_rsp       <= exe_rsp_d;
            slv.exe_rsp_valid <= exe_rsp_valid_d;

            axi_aw_id    <= axi_aw_id_d;
            axi_aw_addr  <= axi_aw_addr_d;
            axi_aw_valid <= axi_aw_valid_d;

            axi_w_data  <= axi_w_data_d;
            axi_w_strb  <= axi_w_strb_d;
            axi_w_valid <= axi_w_valid_d;
        end
    end
endmodule
