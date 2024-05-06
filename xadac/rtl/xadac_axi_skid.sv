`include "axi/assign.svh"
`include "axi/typedef.svh"

module xadac_axi_skid #(
    parameter int unsigned IdWidth   = 0,
    parameter int unsigned AddrWidth = 0,
    parameter int unsigned DataWidth = 0,
    parameter int unsigned UserWidth = 0,

    parameter bit BypassAw = 0,
    parameter bit BypassW  = 0,
    parameter bit BypassB  = 0,
    parameter bit BypassAr = 0,
    parameter bit BypassR  = 0
) (
    logic clk,
    logic rstn,

    AXI_BUS.Slave  slv,
    AXI_BUS.Master mst
);

    localparam int unsigned StrbWidth = DataWidth/8;

    typedef logic [IdWidth-1:0]   id_t;
    typedef logic [AddrWidth-1:0] addr_t;
    typedef logic [DataWidth-1:0] data_t;
    typedef logic [StrbWidth-1:0] strb_t;
    typedef logic [UserWidth-1:0] user_t;

    `AXI_TYPEDEF_AW_CHAN_T(aw_t, addr_t, id_t, user_t);
    `AXI_TYPEDEF_W_CHAN_T(w_t, data_t, strb_t, user_t);
    `AXI_TYPEDEF_B_CHAN_T(b_t, id_t, user_t);
    `AXI_TYPEDEF_AR_CHAN_T(ar_t, addr_t, id_t, user_t);
    `AXI_TYPEDEF_R_CHAN_T(r_t, data_t, id_t, user_t);

    aw_t slv_aw;
    w_t  slv_w;
    b_t  slv_b;
    ar_t slv_ar;
    r_t  slv_r;

    aw_t mst_aw;
    w_t  mst_w;
    b_t  mst_b;
    ar_t mst_ar;
    r_t  mst_r;

    `AXI_ASSIGN_TO_AW (slv_aw, slv);
    `AXI_ASSIGN_TO_W  (slv_w,  slv);
    `AXI_ASSIGN_FROM_B(slv,    slv_b);
    `AXI_ASSIGN_TO_AR (slv_ar, slv);
    `AXI_ASSIGN_FROM_R(slv,    slv_r);

    `AXI_ASSIGN_FROM_AW(mst,   mst_aw);
    `AXI_ASSIGN_FROM_W (mst,   mst_w);
    `AXI_ASSIGN_TO_B   (mst_b, mst);
    `AXI_ASSIGN_FROM_AR(mst,   mst_ar);
    `AXI_ASSIGN_TO_R   (mst_r, mst);

    xadac_skid #(
        .Bypass (BypassAw),
        .DataT  (aw_t)
    ) aw_skid (
        .clk  (clk),
        .rstn (rstn),

        .slv_data  (slv_aw),
        .slv_valid (slv.aw_valid),
        .slv_ready (slv.aw_ready),

        .mst_data  (mst_aw),
        .mst_valid (mst.aw_valid),
        .mst_ready (mst.aw_ready)
    );

    xadac_skid #(
        .Bypass (BypassW),
        .DataT  (w_t)
    ) w_skid (
        .clk  (clk),
        .rstn (rstn),

        .slv_data  (slv_w),
        .slv_valid (slv.w_valid),
        .slv_ready (slv.w_ready),

        .mst_data  (mst_w),
        .mst_valid (mst.w_valid),
        .mst_ready (mst.w_ready)
    );

    xadac_skid #(
        .Bypass (BypassB),
        .DataT  (b_t)
    ) b_skid (
        .clk  (clk),
        .rstn (rstn),

        .slv_data  (mst_b),
        .slv_valid (mst.b_valid),
        .slv_ready (mst.b_ready),

        .mst_data  (slv_b),
        .mst_valid (slv.b_valid),
        .mst_ready (slv.b_ready)
    );

    xadac_skid #(
        .Bypass (BypassAr),
        .DataT  (ar_t)
    ) ar_skid (
        .clk  (clk),
        .rstn (rstn),

        .slv_data  (slv_ar),
        .slv_valid (slv.ar_valid),
        .slv_ready (slv.ar_ready),

        .mst_data  (mst_ar),
        .mst_valid (mst.ar_valid),
        .mst_ready (mst.ar_ready)
    );

    xadac_skid #(
        .Bypass (BypassR),
        .DataT  (r_t)
    ) r_skid (
        .clk  (clk),
        .rstn (rstn),

        .slv_data  (mst_r),
        .slv_valid (mst.r_valid),
        .slv_ready (mst.r_ready),

        .mst_data  (slv_r),
        .mst_valid (slv.r_valid),
        .mst_ready (slv.r_ready)
    );

endmodule
