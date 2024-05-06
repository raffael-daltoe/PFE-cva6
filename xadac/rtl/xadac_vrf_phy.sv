module xadac_vrf_phy
    import xadac_pkg::*;
(
    input logic clk,
    input logic rstn,

    input  VecAddrT [NoVs-1:0] raddr,
    output VecDataT [NoVs-1:0] rdata,
    input  VecAddrT            waddr,
    input  VecDataT            wdata,
    input  logic               we
);

    VecDataT [NoVec-1:0] vrf;

    always_ff @(posedge clk) begin
        if (we) begin
            vrf[waddr] <= wdata;
            // $display("vrf: [%x] <= %x", waddr, wdata);
        end
    end

    always_comb begin
        for (SizeT i = 0; i < NoVs; i++) begin
            rdata[i] = vrf[raddr[i]];
        end
    end

endmodule
