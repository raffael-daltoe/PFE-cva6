module xadac_verilator
    import xadac_pkg::*;
(
    input logic clk,
    input logic rstn,

    input  IdT    dec_req_id,
    input  InstrT dec_req_instr,
    input  logic  dec_req_valid,
    output logic  dec_req_ready,

    output IdT   dec_rsp_id,
    output logic dec_rsp_rd_clobber,
    output logic dec_rsp_vd_clobber,
    output logic dec_rsp_rs_read_0,
    output logic dec_rsp_rs_read_1,
    output logic dec_rsp_vs_read_0,
    output logic dec_rsp_vs_read_1,
    output logic dec_rsp_vs_read_2,
    output logic dec_rsp_accept,
    output logic dec_rsp_valid,
    input  logic dec_rsp_ready,

    input  IdT      exe_req_id,
    input  InstrT   exe_req_instr,
    input  RegAddrT exe_req_rs_addr_0,
    input  RegAddrT exe_req_rs_addr_1,
    input  RegDataT exe_req_rs_data_0,
    input  RegDataT exe_req_rs_data_1,
    input  VecAddrT exe_req_vs_addr_0,
    input  VecAddrT exe_req_vs_addr_1,
    input  VecAddrT exe_req_vs_addr_2,
    input  VecDataT exe_req_vs_data_0,
    input  VecDataT exe_req_vs_data_1,
    input  VecDataT exe_req_vs_data_2,
    input  logic    exe_req_valid,
    output logic    exe_req_ready,

    output IdT      exe_rsp_id,
    output RegAddrT exe_rsp_rd_addr,
    output RegDataT exe_rsp_rd_data,
    output logic    exe_rsp_rd_write,
    output VecAddrT exe_rsp_vd_addr,
    output VecDataT exe_rsp_vd_data,
    output logic    exe_rsp_vd_write,
    output logic    exe_rsp_valid,
    input  logic    exe_rsp_ready,

    output IdT   axi_aw_id,
    output AddrT axi_aw_addr,
    output logic axi_aw_valid,
    input  logic axi_aw_ready,

    output VecDataT axi_w_data,
    output VecStrbT axi_w_strb,
    output logic    axi_w_valid,
    input  logic    axi_w_ready,

    input  IdT   axi_b_id,
    input  logic axi_b_valid,
    output logic axi_b_ready,

    output IdT   axi_ar_id,
    output AddrT axi_ar_addr,
    output logic axi_ar_valid,
    input  logic axi_ar_ready,

    input  IdT      axi_r_id,
    input  VecDataT axi_r_data,
    input  logic    axi_r_valid,
    output logic    axi_r_ready
);

    import xadac_pkg::*;

    xadac_if mst ();

    assign mst.dec_req.id    = dec_req_id;
    assign mst.dec_req.instr = dec_req_instr;
    assign mst.dec_req_valid = dec_req_valid;
    assign dec_req_ready     = mst.dec_req_ready;

    assign dec_rsp_id         = mst.dec_rsp.id;
    assign dec_rsp_rd_clobber = mst.dec_rsp.rd_clobber;
    assign dec_rsp_vd_clobber = mst.dec_rsp.vd_clobber;
    assign dec_rsp_rs_read_0  = mst.dec_rsp.rs_read[0];
    assign dec_rsp_rs_read_1  = mst.dec_rsp.rs_read[1];
    assign dec_rsp_vs_read_0  = mst.dec_rsp.vs_read[0];
    assign dec_rsp_vs_read_1  = mst.dec_rsp.vs_read[1];
    assign dec_rsp_vs_read_2  = mst.dec_rsp.vs_read[2];
    assign dec_rsp_accept     = mst.dec_rsp.accept;
    assign dec_rsp_valid      = mst.dec_rsp_valid;
    assign mst.dec_rsp_ready  = dec_rsp_ready;

    assign mst.exe_req.id         = exe_req_id;
    assign mst.exe_req.instr      = exe_req_instr;
    assign mst.exe_req.rs_addr[0] = exe_req_rs_addr_0;
    assign mst.exe_req.rs_addr[1] = exe_req_rs_addr_1;
    assign mst.exe_req.rs_data[0] = exe_req_rs_data_0;
    assign mst.exe_req.rs_data[1] = exe_req_rs_data_1;
    assign mst.exe_req.vs_addr[0] = exe_req_vs_addr_0;
    assign mst.exe_req.vs_addr[1] = exe_req_vs_addr_1;
    assign mst.exe_req.vs_addr[2] = exe_req_vs_addr_2;
    assign mst.exe_req.vs_data[0] = exe_req_vs_data_0;
    assign mst.exe_req.vs_data[1] = exe_req_vs_data_1;
    assign mst.exe_req.vs_data[2] = exe_req_vs_data_2;
    assign mst.exe_req_valid      = exe_req_valid;
    assign exe_req_ready          = mst.exe_req_ready;

    assign exe_rsp_id        = mst.exe_rsp.id;
    assign exe_rsp_rd_addr   = mst.exe_rsp.rd_addr;
    assign exe_rsp_rd_data   = mst.exe_rsp.rd_data;
    assign exe_rsp_rd_write  = mst.exe_rsp.rd_write;
    assign exe_rsp_vd_addr   = mst.exe_rsp.vd_addr;
    assign exe_rsp_vd_data   = mst.exe_rsp.vd_data;
    assign exe_rsp_vd_write  = mst.exe_rsp.vd_write;
    assign exe_rsp_valid     = mst.exe_rsp_valid;
    assign mst.exe_rsp_ready = exe_rsp_ready;

    AXI_BUS #(
        .AXI_ID_WIDTH   (IdWidth),
        .AXI_ADDR_WIDTH (AddrWidth),
        .AXI_DATA_WIDTH (VecDataWidth),
        .AXI_USER_WIDTH (1)
    ) axi ();

    assign axi_aw_id    = axi.aw_id;
    assign axi_aw_addr  = axi.aw_addr;
    assign axi_aw_valid = axi.aw_valid;
    assign axi.aw_ready = axi_aw_ready;

    assign axi_w_data  = axi.w_data;
    assign axi_w_strb  = axi.w_strb;
    assign axi_w_valid = axi.w_valid;
    assign axi.w_ready = axi_w_ready;

    assign axi.b_id    = axi_b_id;
    assign axi.b_valid = axi_b_valid;
    assign axi_b_ready = axi.b_ready;

    assign axi_ar_id    = axi.ar_id;
    assign axi_ar_addr  = axi.ar_addr;
    assign axi_ar_valid = axi.ar_valid;
    assign axi.ar_ready = axi_ar_ready;

    assign axi.r_id    = axi_r_id;
    assign axi.r_data  = axi_r_data;
    assign axi.r_valid = axi_r_valid;
    assign axi_r_ready = axi.r_ready;

    xadac i_xadac (
        .clk  (clk),
        .rstn (rstn),
        .slv  (mst),
        .axi  (axi)
    );

endmodule
