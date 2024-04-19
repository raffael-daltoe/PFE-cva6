module xadac_vrf_phy
    import xadac_pkg::*;
(
    input logic clk,
    input logic rstn,

    input  VecAddrT [NoVs-1:0] raddr,
    output VecDataT [NoVs-1:0] rdata,
    input  VecAddrT            waddr,
    input  VecdataT            wdata,
    input  logic               we
);

    VectorT [NoVec-1:0] vf;

    always_ff @(posedge clk) begin
        if (we) begin
            vf[waddr] <= wdata;
        end
    end

    always_comb begin
        for (SizeT i = 0; i < NoVs; i++) begin
            rdata[i] = vf[raddr[i]];
        end
    end

endmodule
