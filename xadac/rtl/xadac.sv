module xadac
    import xadac_pkg::*;
(
    input logic    clk,
    input logic    rstn,
    xadac_if.slv   slv,
    AXI_BUS.Master axi
);

    localparam SizeT NoUnits = 5;

    localparam InstrT [NoUnits-1:0] Mask = '{
        32'h0000_0000, // sink
        32'h0000_3077, // vactv
        32'h0000_707f, // vmacc
        32'h01f0_707f, // vbias
        32'h01f0_707f  // vload
    };

    localparam InstrT [NoUnits-1:0] Match = '{
        32'h0000_0000, // sink
        32'h0000_3077, // vactv
        32'h0000_2077, // vmacc
        32'h0000_1077, // vbias
        32'h0000_0077  // vload
    };

    xadac_if vclobber_to_vrf ();
    xadac_if vrf_to_mux_cut ();
    xadac_if mux_cut_to_mux ();
    xadac_if mux_to_unit_cut  [NoUnits] ();
    xadac_if unit_cut_to_unit [NoUnits] ();

    IdT   axi_aw_id;
    AddrT axi_aw_addr;
    logic axi_aw_valid;
    logic axi_aw_ready;

    VecDataT axi_w_data;
    VecStrbT axi_w_strb;
    logic    axi_w_valid;
    logic    axi_w_ready;

    IdT   axi_b_id;
    logic axi_b_valid;
    logic axi_b_ready;

    IdT   axi_ar_id;
    AddrT axi_ar_addr;
    logic axi_ar_valid;
    logic axi_ar_ready;

    IdT      axi_r_id;
    VecDataT axi_r_data;
    logic    axi_r_valid;
    logic    axi_r_ready;

    xadac_vclobber i_vclobber (
        .clk  (clk),
        .rstn (rstn),
        .slv  (slv),
        .mst  (vclobber_to_vrf)
    );

    xadac_vrf i_vrf (
        .clk  (clk),
        .rstn (rstn),
        .slv  (vclobber_to_vrf),
        .mst  (vrf_to_mux_cut)
    );

    xadac_if_cut i_mux_cut (
        .clk  (clk),
        .rstn (rstn),
        .slv  (vrf_to_mux_cut),
        .mst  (mux_cut_to_mux)
    );

    xadac_mux #(
        .NoMst (NoUnits),
        .Mask  (Mask),
        .Match (Match)
    ) i_mux (
        .clk  (clk),
        .rstn (rstn),
        .slv  (mux_cut_to_mux),
        .mst  (mux_to_unit_cut)
    );

    for (genvar i = 0; i < NoUnits; i++) begin : gen_cut
        xadac_if_cut i_unit_cut (
            .clk  (clk),
            .rstn (rstn),
            .slv  (mux_to_unit_cut[i]),
            .mst  (unit_cut_to_unit[i])
        );
    end

    xadac_vload i_vload (
        .clk  (clk),
        .rstn (rstn),
        .slv  (unit_cut_to_unit[0]),

        .axi_ar_id    (axi_ar_id),
        .axi_ar_addr  (axi_ar_addr),
        .axi_ar_valid (axi_ar_valid),
        .axi_ar_ready (axi_ar_ready),

        .axi_r_id    (axi_r_id),
        .axi_r_data  (axi_r_data),
        .axi_r_valid (axi_r_valid),
        .axi_r_ready (axi_r_ready)
    );

    xadac_vbias i_vbias (
        .clk  (clk),
        .rstn (rstn),
        .slv  (unit_cut_to_unit[1])
    );

    xadac_vmacc i_vmacc (
        .clk  (clk),
        .rstn (rstn),
        .slv  (unit_cut_to_unit[2])
    );

    xadac_vactv i_vactv (
        .clk  (clk),
        .rstn (rstn),
        .slv  (unit_cut_to_unit[3]),

        .axi_aw_id    (axi_aw_id),
        .axi_aw_addr  (axi_aw_addr),
        .axi_aw_valid (axi_aw_valid),
        .axi_aw_ready (axi_aw_ready),

        .axi_w_data  (axi_w_data),
        .axi_w_strb  (axi_w_strb),
        .axi_w_valid (axi_w_valid),
        .axi_w_ready (axi_w_ready),

        .axi_b_id    (axi_b_id),
        .axi_b_valid (axi_b_valid),
        .axi_b_ready (axi_b_ready)
    );

    xadac_sink i_sink (
        .clk  (clk),
        .rstn (rstn),
        .slv  (unit_cut_to_unit[4])
    );

    // axi assign =============================================================

    localparam axi_pkg::size_t AxiSize = axi_pkg::size_t'(
        $unsigned($clog2(VecDataWidth/8))
    );

    assign axi.aw_id     = axi_aw_id;
    assign axi.aw_addr   = axi_aw_addr;
    assign axi.aw_len    = '0;
    assign axi.aw_size   = AxiSize;
    assign axi.aw_burst  = '0;
    assign axi.aw_lock   = '0;
    assign axi.aw_cache  = '0;
    assign axi.aw_prot   = '0;
    assign axi.aw_qos    = '0;
    assign axi.aw_region = '0;
    assign axi.aw_atop   = '0;
    assign axi.aw_user   = '0;
    assign axi.aw_valid  = axi_aw_valid;
    assign axi_aw_ready  = axi.aw_ready;

    assign axi.w_data  = axi_w_data;
    assign axi.w_strb  = axi_w_strb;
    assign axi.w_last  = '1;
    assign axi.w_user  = '0;
    assign axi.w_valid = axi_w_valid;
    assign axi_w_ready = axi.w_ready;

    assign axi_b_id    = axi.b_id;
    assign axi_b_valid = axi.b_valid;
    assign axi.b_ready = axi_b_ready;

    assign axi.ar_id     = axi_ar_id;
    assign axi.ar_addr   = axi_ar_addr;
    assign axi.ar_len    = '0;
    assign axi.ar_size   = AxiSize;
    assign axi.ar_burst  = '0;
    assign axi.ar_lock   = '0;
    assign axi.ar_cache  = '0;
    assign axi.ar_prot   = '0;
    assign axi.ar_qos    = '0;
    assign axi.ar_region = '0;
    assign axi.ar_user   = '0;
    assign axi.ar_valid  = axi_ar_valid;
    assign axi_ar_ready  = axi.ar_ready;

    assign axi_r_id    = axi.r_id;
    assign axi_r_data  = axi.r_data;
    assign axi_r_valid = axi.r_valid;
    assign axi.r_ready = axi_r_ready;

    // always_ff @(posedge clk) begin
    //     if (axi.ar_valid && axi.ar_ready) begin
    //         $display("ar: %x", axi.ar_addr);
    //     end

    //     if (axi.r_valid && axi.r_ready) begin
    //         $display("r: %x", axi.r_data);
    //     end

    //     if (axi.aw_valid && axi.aw_ready) begin
    //         $display("aw: %x", axi.aw_addr);
    //     end

    //     if (axi.w_valid && axi.w_ready) begin
    //         $display("w: %x %x", axi.w_data, axi.w_strb);

    //         if (axi.w_data == 'h00000000000000000000000000000100) begin
    //             $finish();
    //         end
    //     end
    // end

endmodule
