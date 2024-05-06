module xadac_axi_wizard
    import xadac_pkg::*;
#(
    parameter SizeT MstDataWidth = 32
) (
    input logic clk,
    input logic rstn,

    AXI_BUS.Slave  slv,
    AXI_BUS.Master mst
);

    localparam SizeT SlvDataWidth = VecDataWidth;
    localparam SizeT SlvStrbWidth = SlvDataWidth/8;
    localparam SizeT MstStrbWidth = MstDataWidth/8;

    localparam SizeT IntDataWidth = SlvDataWidth + MstDataWidth;
    localparam SizeT IntStrbWidth = IntDataWidth/8;

    typedef logic [SlvDataWidth-1:0] slv_data_t;
    typedef logic [SlvStrbWidth-1:0] slv_strb_t;
    typedef logic [MstDataWidth-1:0] mst_data_t;
    typedef logic [MstStrbWidth-1:0] mst_strb_t;
    typedef logic [IntDataWidth-1:0] int_data_t;
    typedef logic [IntStrbWidth-1:0] int_strb_t;

    typedef logic [$clog2(IntStrbWidth+1)-1:0] len_t;

    function automatic AddrT aligned(AddrT addr);
        return {
            addr[AddrWidth-1:$clog2(MstStrbWidth)],
            {$clog2(MstStrbWidth){'0}}
        };
    endfunction

    function automatic logic [$clog2(MstStrbWidth)-1:0] unaligned(AddrT addr);
        return addr[$clog2(MstStrbWidth)-1:0];
    endfunction

    // write ==================================================================

    typedef struct packed {
        IdT        id;
        AddrT      addr;
        int_data_t data;
        int_data_t strb;

        logic slv_aw_done;
        logic slv_w_done;
        logic slv_b_done;

        len_t mst_aw_count;
        len_t mst_w_count;
        len_t mst_b_count;

        IdT   mst_aw_id;
        AddrT mst_aw_addr;
        logic mst_aw_valid;

        mst_data_t mst_w_data;
        mst_strb_t mst_w_strb;
        logic      mst_w_valid;

        IdT   slv_b_id;
        logic slv_b_valid;
    } write_t;

    write_t write_d, write_q;

    assign mst.aw_id     = write_q.mst_aw_id;
    assign mst.aw_addr   = write_q.mst_aw_addr;
    assign mst.aw_len    = '0;
    assign mst.aw_size   = $unsigned($clog2(MstDataWidth/8));
    assign mst.aw_burst  = '0;
    assign mst.aw_lock   = '0;
    assign mst.aw_cache  = '0;
    assign mst.aw_prot   = '0;
    assign mst.aw_qos    = '0;
    assign mst.aw_region = '0;
    assign mst.aw_atop   = '0;
    assign mst.aw_user   = '0;
    assign mst.aw_valid  = write_q.mst_aw_valid;

    assign mst.w_data  = write_q.mst_w_data;
    assign mst.w_strb  = write_q.mst_w_strb;
    assign mst.w_last  = '1;
    assign mst.w_user  = '0;
    assign mst.w_valid = write_q.mst_w_valid;

    assign slv.b_id    = write_q.slv_b_id;
    assign slv.b_resp  = '0;
    assign slv.b_user  = '0;
    assign slv.b_valid = write_q.slv_b_valid;

    always_comb begin
        write_d = write_q;

        // slv aw =============================================================

        slv.aw_ready = !write_d.slv_aw_done;

        if (slv.aw_valid && slv.aw_ready) begin
            write_d.id   = slv.aw_id;
            write_d.addr = slv.aw_addr;

            write_d.slv_aw_done = '1;
        end

        // slv w ==============================================================

        slv.w_ready = write_d.slv_aw_done && !write_d.slv_w_done;

        if (slv.w_valid && slv.w_ready) begin
            write_d.data = int_data_t'(slv.w_data);
            write_d.strb = int_strb_t'(slv.w_strb);

            write_d.slv_w_done = '1;
        end

        // advance ============================================================

        for (SizeT i = 0; i < IntStrbWidth/MstStrbWidth; i++) begin

            if (write_d.strb[MstStrbWidth-1:0] != '0) break;

            write_d.data >>= MstStrbWidth * 8;
            write_d.strb >>= MstStrbWidth;
            write_d.addr +=  MstStrbWidth;
        end

        // align ==============================================================

        write_d.data <<= unaligned(write_d.addr) * 8;
        write_d.strb <<= unaligned(write_d.addr);
        write_d.addr -=  unaligned(write_d.addr);

        // mst aw =============================================================

        if (mst.aw_valid && mst.aw_ready) begin
            write_d.mst_aw_count = write_q.mst_aw_count + 1;
        end

        write_d.mst_aw_id    = '0;
        write_d.mst_aw_addr  = '0;
        write_d.mst_aw_valid = '0;

        if (
            (write_d.strb != '0) &&
            (write_d.mst_aw_count == write_d.mst_w_count)
        ) begin
            write_d.mst_aw_id    = write_d.id;
            write_d.mst_aw_addr  = write_d.addr;
            write_d.mst_aw_valid = '1;
        end

        // mst w ==============================================================

        if (mst.w_valid && mst.w_ready) begin
            write_d.mst_w_count = write_q.mst_w_count + 1;
            write_d.strb[MstStrbWidth-1:0] = '0;
        end

        write_d.mst_w_data  = '0;
        write_d.mst_w_strb  = '0;
        write_d.mst_w_valid = '0;

        if (
            (write_d.strb != '0) &&
            (write_d.mst_w_count < write_d.mst_aw_count)
        ) begin
            write_d.mst_w_data  = write_d.data[MstDataWidth-1:0];
            write_d.mst_w_strb  = write_d.strb[MstStrbWidth-1:0];
            write_d.mst_w_valid = '1;
        end

        // mst b ==============================================================

        mst.b_ready = (write_q.mst_b_count < write_d.mst_w_count);

        if (mst.b_valid && mst.b_ready) begin
            write_d.mst_b_count = write_q.mst_b_count + 1;
        end

        // slv b ==============================================================

        if (slv.b_valid && slv.b_ready) begin
            write_d.slv_b_done = '1;
        end

        write_d.slv_b_id    = '0;
        write_d.slv_b_valid = '0;

        if (
            (write_d.slv_aw_done && write_d.slv_w_done) &&
            (!write_d.slv_b_done) &&
            (write_d.strb == '0) &&
            (write_d.mst_b_count == write_d.mst_w_count)
        ) begin
            write_d.slv_b_id    = write_d.id;
            write_d.slv_b_valid = '1;
        end

        // end ================================================================

        if (
            write_q.slv_aw_done &&
            write_q.slv_w_done &&
            write_q.slv_b_done
        ) begin
            write_d = '0;
        end
    end

    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            write_q <= '0;
        end
        else begin
            write_q <= write_d;
        end
    end

    // read ===================================================================

    typedef struct packed {
        IdT        id;
        AddrT      addr;
        int_data_t data;

        logic slv_ar_done;
        logic slv_r_done;

        len_t mst_ar_count;
        len_t mst_r_count;

        IdT   mst_ar_id;
        AddrT mst_ar_addr;
        logic mst_ar_valid;

        IdT      slv_r_id;
        VecDataT slv_r_data;
        logic    slv_r_valid;
    } read_t;

    read_t read_d, read_q;

    assign mst.ar_id     = read_q.mst_ar_id;
    assign mst.ar_addr   = read_q.mst_ar_addr;
    assign mst.ar_len    = '0;
    assign mst.ar_size   = $unsigned($clog2(MstDataWidth/8));
    assign mst.ar_burst  = '0;
    assign mst.ar_lock   = '0;
    assign mst.ar_cache  = '0;
    assign mst.ar_prot   = '0;
    assign mst.ar_qos    = '0;
    assign mst.ar_region = '0;
    assign mst.ar_user   = '0;
    assign mst.ar_valid  = read_q.mst_ar_valid;

    assign slv.r_id    = read_q.slv_r_id;
    assign slv.r_data  = read_q.slv_r_data;
    assign slv.r_resp  = '0;
    assign slv.r_last  = '1;
    assign slv.r_user  = '0;
    assign slv.r_valid = read_q.slv_r_valid;

    always_comb begin
        read_d = read_q;

        // slv ar =============================================================

        slv.ar_ready = !read_d.slv_ar_done;

        if (slv.ar_valid && slv.ar_ready) begin
            read_d.id   = slv.ar_id;
            read_d.addr = slv.ar_addr;

            read_d.slv_ar_done  = '1;
            read_d.mst_ar_count = SlvDataWidth/MstDataWidth;
            read_d.mst_r_count  = SlvDataWidth/MstDataWidth;

            if (unaligned(read_d.addr) != 0) begin
                read_d.mst_ar_count += 1;
                read_d.mst_r_count  += 1;
            end
        end

        // mst ar =============================================================

        if (mst.ar_valid && mst.ar_ready) begin
            read_d.addr = read_q.addr + SlvDataWidth/MstDataWidth;
            read_d.mst_ar_count = read_q.mst_ar_count - 1;
        end

        read_d.mst_ar_id    = '0;
        read_d.mst_ar_addr  = '0;
        read_d.mst_ar_valid = '0;

        if (read_d.mst_ar_count > 0) begin
            read_d.mst_ar_id    = read_d.id;
            read_d.mst_ar_addr  = aligned(read_d.addr);
            read_d.mst_ar_valid = '1;
        end

        // mst r ==============================================================

        mst.r_ready = (read_d.mst_r_count > 0);

        if (mst.r_valid && mst.r_ready) begin
            read_d.data = {
                mst.r_data,
                read_q.data[MstDataWidth +: SlvDataWidth]
            };
            read_d.mst_r_count = read_q.mst_r_count - 1;
        end

        // slv r ==============================================================

        if (slv.r_valid && slv.r_ready) begin
            read_d.slv_r_done = '1;
        end

        read_d.slv_r_id    = '0;
        read_d.slv_r_data  = '0;
        read_d.slv_r_valid = '0;

        if (
            (read_d.slv_ar_done) &&
            (!read_d.slv_r_done) &&
            (read_d.mst_r_count == 0)
        ) begin
            read_d.slv_r_id    = read_d.id;
            read_d.slv_r_valid = '1;

            if (unaligned(read_d.addr) == 0) begin
                read_d.slv_r_data = read_d.data[
                    MstDataWidth +: SlvDataWidth
                ];
            end
            else begin
                read_d.slv_r_data = read_d.data[
                    unaligned(read_d.addr) * 8 +: SlvDataWidth
                ];
            end
        end

        // end ================================================================

        if (
            read_d.slv_ar_done &&
            read_d.slv_r_done
        ) begin
            read_d = '0;
        end
    end

    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            read_q <= '0;
        end
        else begin
            read_q <= read_d;
        end
    end

endmodule
