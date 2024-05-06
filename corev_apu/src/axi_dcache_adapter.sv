module axi_dcache_adapter
    import ariane_pkg::*;
    import riscv::*;
(
    input logic clk,
    input logic rstn,

    AXI_BUS.Slave axi,

    output dcache_req_i_t dcache_req,
    input  dcache_req_o_t dcache_rsp
);

    // parameters =============================================================

    localparam int unsigned LogMaxTrans = 3;
    localparam int unsigned MaxTrans    = 2**LogMaxTrans;

    localparam int unsigned IdWidth    = TRANS_ID_BITS;
    localparam int unsigned UserWidth  = DCACHE_USER_WIDTH;
    localparam int unsigned AddrWidth  = VLEN;
    localparam int unsigned DataWidth  = XLEN;
    localparam int unsigned StrbWidth  = DataWidth/8;

    localparam int unsigned TagWidth   = DCACHE_TAG_WIDTH;
    localparam int unsigned IndexWidth = DCACHE_INDEX_WIDTH;
    localparam int unsigned SizeWidth  = 2;

    // typedefs ===============================================================

    typedef logic [IdWidth-1:0]   id_t;
    typedef logic [AddrWidth-1:0] addr_t;
    typedef logic [DataWidth-1:0] data_t;
    typedef logic [StrbWidth-1:0] strb_t;
    typedef logic [UserWidth-1:0] user_t;

    typedef logic [IndexWidth-1:0] index_t;
    typedef logic [TagWidth-1:0]   tag_t;
    typedef logic [SizeWidth-1:0]  size_t;

    typedef logic  [LogMaxTrans-1:0] ptr_t;

    typedef struct packed {
        logic dir;
    } send_t;

    typedef struct packed {
        id_t   id;
        data_t data;
        user_t user;
    } recv_t;

    // functions ==============================================================

    function automatic index_t index(addr_t addr);
        return addr[IndexWidth-1:0];
    endfunction

    function automatic tag_t tag(addr_t addr);
        return addr[AddrWidth-1:IndexWidth];
    endfunction

    function automatic size_t size(input strb_t strb);
        case (strb)
            4'b0001, 4'b0010, 4'b0100, 4'b1000: return 2'b00;
            4'b0011, 4'b0110, 4'b1100:          return 2'b01;
            4'b1111:                            return 2'b10;
            default:                            return 2'b10;
        endcase
    endfunction

    // signals ================================================================

    dcache_req_i_t req;
    dcache_req_o_t rsp;

    ptr_t ptr_send_d, ptr_send_q;
    ptr_t ptr_recv_d, ptr_recv_q;
    ptr_t ptr_raxi_d, ptr_raxi_q;

    send_t [MaxTrans-1:0] send_d, send_q;
    recv_t [MaxTrans-1:0] recv_d, recv_q;

    tag_t tag_d, tag_q;
    logic tag_valid_d, tag_valid_q;

    AXI_BUS #(
        .AXI_ID_WIDTH   (IdWidth),
        .AXI_ADDR_WIDTH (AddrWidth),
        .AXI_DATA_WIDTH (DataWidth),
        .AXI_USER_WIDTH (UserWidth)
    ) axi_cut ();

    // instances ==============================================================

    xadac_axi_cut #(
        .IdWidth   (IdWidth),
        .AddrWidth (AddrWidth),
        .DataWidth (DataWidth),
        .UserWidth (UserWidth)
    ) i_xadac_axi_cut (
        .clk  (clk),
        .rstn (rstn),

        .slv (axi),
        .mst (axi_cut)
    );

    // assigns ================================================================

    assign dcache_req = req;
    assign rsp = dcache_rsp;

    // logic ==================================================================

    always_comb begin
        ptr_send_d = ptr_send_q;
        ptr_recv_d = ptr_recv_q;
        ptr_raxi_d = ptr_raxi_q;

        send_d = send_q;
        recv_d = recv_q;

        tag_d       = '0;
        tag_valid_d = '0;

        req.address_index = '0;
        req.data_wdata    = '0;
        req.data_wuser    = '0;
        req.data_req      = '0;
        req.data_we       = '0;
        req.data_be       = '0;
        req.data_size     = '0;
        req.data_id       = '0;
        req.kill_req      = '0;

        req.address_tag = '0;
        req.tag_valid   = '0;

        axi_cut.aw_ready = '0;
        axi_cut.w_ready  = '0;
        axi_cut.ar_ready = '0;
        axi_cut.b_id     = '0;
        axi_cut.b_resp   = '0;
        axi_cut.b_user   = '0;
        axi_cut.b_valid  = '0;
        axi_cut.r_id     = '0;
        axi_cut.r_data   = '0;
        axi_cut.r_resp   = '0;
        axi_cut.r_last   = '0;
        axi_cut.r_user   = '0;
        axi_cut.r_valid  = '0;

        if (tag_valid_q) begin
            req.address_tag = tag_q;
            req.tag_valid   = tag_valid_q;
        end

        if (ptr_t'(ptr_send_d + 1) == ptr_raxi_d) begin
            // full
        end
        else if (
            (axi_cut.aw_valid && axi_cut.w_valid) &&
            (!tag_valid_q)
        ) begin
            req.address_index = index(axi_cut.aw_addr);
            req.data_wdata    = axi_cut.w_data;
            req.data_wuser    = axi_cut.aw_user;
            req.data_req      = '1;
            req.data_we       = '1;
            req.data_be       = axi_cut.w_strb;
            req.data_size     = size(axi_cut.w_strb);
            req.data_id       = axi_cut.aw_id;
            req.kill_req      = '0;

            req.address_tag = tag(axi_cut.aw_addr);

            axi_cut.aw_ready = rsp.data_gnt;
            axi_cut.w_ready  = rsp.data_gnt;

            if (rsp.data_gnt) begin
                send_d[ptr_send_q].dir  = '1;
                recv_d[ptr_recv_q].id   = axi_cut.aw_id;
                recv_d[ptr_recv_q].data = '0;
                ptr_send_d = ptr_send_q + 1;
                ptr_recv_d = ptr_recv_q + 1;
            end
        end
        else if (axi_cut.ar_valid) begin
            req.address_index = index(axi_cut.ar_addr);
            req.data_wdata    = '0;
            req.data_wuser    = axi_cut.ar_user;
            req.data_req      = '1;
            req.data_we       = '0;
            req.data_be       = '0;
            req.data_size     = '0;
            req.data_id       = axi_cut.ar_id;
            req.kill_req      = '0;

            tag_d       = tag(axi_cut.ar_addr);
            tag_valid_d = '1;

            axi_cut.ar_ready = rsp.data_gnt;

            if (rsp.data_gnt) begin
                send_d[ptr_send_q].dir = '0;
                ptr_send_d = ptr_send_q + 1;
            end
        end

        if (rsp.data_rvalid) begin
            recv_d[ptr_recv_q].id   = rsp.data_rid;
            recv_d[ptr_recv_q].data = rsp.data_rdata;
            ptr_recv_d = ptr_recv_q + 1;
        end

        if (ptr_raxi_d != ptr_recv_d) begin
            if (send_d[ptr_raxi_d].dir) begin
                axi_cut.b_id    = recv_d[ptr_raxi_d].id;
                axi_cut.b_resp  = '0;
                axi_cut.b_user  = recv_d[ptr_raxi_d].user;
                axi_cut.b_valid = 1;

                if (axi_cut.b_ready) begin
                    ptr_raxi_d = ptr_raxi_q + 1;
                end
            end
            else begin
                axi_cut.r_id    = recv_d[ptr_raxi_d].id;
                axi_cut.r_data  = recv_d[ptr_raxi_d].data;
                axi_cut.r_resp  = '0;
                axi_cut.r_last  = '1;
                axi_cut.r_user  = recv_d[ptr_raxi_d].user;
                axi_cut.r_valid = '1;

                if (axi_cut.r_ready) begin
                    ptr_raxi_d = ptr_raxi_q + 1;
                end
            end
        end
    end

    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            ptr_send_q <= '0;
            ptr_recv_q <= '0;
            ptr_raxi_q <= '0;

            send_q <= '0;
            recv_q <= '0;

            tag_q       <= '0;
            tag_valid_q <= '0;
        end
        else begin
            ptr_send_q <= ptr_send_d;
            ptr_recv_q <= ptr_recv_d;
            ptr_raxi_q <= ptr_raxi_d;

            send_q <= send_d;
            recv_q <= recv_d;

            tag_q       <= tag_d;
            tag_valid_q <= tag_valid_d;
        end
    end

endmodule
