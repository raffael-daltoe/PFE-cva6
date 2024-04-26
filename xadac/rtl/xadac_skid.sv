module xadac_skid #(
    parameter bit Passthrough = 0,
    parameter type DataT = logic
) (
    input logic clk,
    input logic rstn,

    input  DataT slv_data,
    input  logic slv_valid,
    output logic slv_ready,

    output DataT mst_data,
    output logic mst_valid,
    input  logic mst_ready
);

    if (Passthrough) begin : gen_passthrough
        assign mst_data  = slv_data;
        assign mst_valid = slv_valid;
        assign slv_ready = mst_ready;
    end
    else begin : gen_skid
        logic stall;
        DataT buffer;

        always_comb begin
            mst_data  = (stall) ? buffer : slv_data;
            mst_valid = slv_valid || stall;
        end

        always_ff @(posedge clk, negedge rstn) begin
            if (!rstn) begin
                stall     <= '0;
                buffer    <= '0;
                slv_ready <= '0;
            end
            else begin
                slv_ready <= !stall || mst_ready;

                if (slv_valid && slv_ready && mst_valid && !mst_ready) begin
                    stall     <= '1;
                    buffer    <= slv_data;
                    slv_ready <= '0;
                end

                if (stall && mst_valid && mst_ready) begin
                    stall     <= '0;
                    buffer    <= '0;
                    slv_ready <= '1;
                end
            end
        end
    end

endmodule
