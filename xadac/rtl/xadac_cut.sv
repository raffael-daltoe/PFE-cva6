// Copy of PULP's spill_register
module xadac_cut #(
    parameter bit  Bypass = 'b0,
    parameter type DataT  = logic
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

    if (Bypass) begin : gen_bypass
        assign mst_data  = slv_data;
        assign mst_valid = slv_valid;
        assign slv_ready = mst_ready;
    end
    else begin : gen_cut
        DataT a_data_q, b_data_q;
        logic a_full_q, b_full_q;
        logic a_fill,   b_fill;
        logic a_drain,  b_drain;

        assign a_fill = slv_valid && slv_ready;
        assign a_drain = (a_full_q && !b_full_q);

        assign b_fill = (a_drain && !mst_ready);
        assign b_drain = (b_full_q && mst_ready);

        assign slv_ready = !a_full_q || !b_full_q;

        assign mst_valid = a_full_q || b_full_q;

        assign mst_data = (b_full_q) ? b_data_q : a_data_q;

        always_ff @(posedge clk, negedge rstn) begin
            if (!rstn) begin
                a_data_q <= '0;
                b_data_q <= '0;
                a_full_q <= '0;
                b_full_q <= '0;
            end
            else begin
                if (a_fill) begin
                    a_data_q <= slv_data;
                    a_full_q <= '1;
                end
                else if (a_drain) begin
                    a_full_q <= '0;
                end

                if (b_fill) begin
                    b_data_q <= a_data_q;
                    b_full_q <= '1;
                end
                else if (b_drain) begin
                    b_full_q <= '0;
                end
            end
        end
    end
endmodule
