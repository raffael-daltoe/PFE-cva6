module xadac_vmacc
    import xadac_pkg::*;
(
    input logic  clk,
    input logic  rstn,
    xadac_if.slv slv
);

    localparam SizeT ILenWidth = $clog2(VecDataWidth/VecSumWidth+1);
    localparam SizeT JLenWidth = $clog2(VecSumWidth/VecElemWidth+1);

    typedef logic [ILenWidth-1:0] ilen_t;
    typedef logic [JLenWidth-1:0] jlen_t;

    function automatic logic signed [31:0] macc(
        input logic signed [31:0] vrf_i32,
        input logic signed [7:0] vrf_i8,
        input logic [7:0] vrf_u8
    );
        // Sign-extend the 8-bit signed and unsigned integers to 16-bit
        logic signed [15:0] extended_vrf_i8;  // Sign-extended signed 8-bit
        logic signed [15:0] extended_vrf_u8;  // Sign-extended unsigned 8-bit
        logic signed [31:0] product;  // 32-bit to avoid overflow

        extended_vrf_i8 = {{8{vrf_i8[7]}}, vrf_i8};  // Sign-extend vrf_i8
        extended_vrf_u8 = {8'b0, vrf_u8};           // Zero-extend vrf_u8

        // Perform multiplication with the sign-extended operands

        product = extended_vrf_i8 * extended_vrf_u8;

        // Return the updated 32-bit signed integer
        return vrf_i32 + product;
    endfunction

    always_comb begin : comb_dec
        slv.dec_rsp_valid = slv.dec_req_valid;
        slv.dec_req_ready = (slv.dec_rsp_valid && slv.dec_rsp_ready);

        slv.dec_rsp.id = slv.dec_req.id;
        slv.dec_rsp.rd_clobber = '0;
        slv.dec_rsp.vd_clobber = '1;
        slv.dec_rsp.rs_read[0] = '0;
        slv.dec_rsp.rs_read[1] = '0;
        slv.dec_rsp.vs_read[0] = '1;
        slv.dec_rsp.vs_read[1] = '1;
        slv.dec_rsp.vs_read[2] = '1;

        case (slv.dec_req.instr[25 +: JLenWidth])
            'd1:     slv.dec_rsp.accept = '1;
            'd4:     slv.dec_rsp.accept = '1;
            default: slv.dec_rsp.accept = '0;
        endcase
    end

    always_comb begin : comb_exe
        automatic ilen_t ilen = VecDataWidth/VecSumWidth;
        automatic jlen_t jlen = slv.exe_req.instr[25 +: JLenWidth];

        slv.exe_rsp_valid = slv.exe_req_valid;
        slv.exe_req_ready = (slv.exe_rsp_valid && slv.exe_rsp_ready);

        slv.exe_rsp          = '0;
        slv.exe_rsp.id       = slv.exe_req.id;
        slv.exe_rsp.vd_addr  = slv.exe_req.instr[11:7];
        slv.exe_rsp.vd_data  = slv.exe_req.vs_data[2];
        slv.exe_rsp.vd_write = '1;

        if (jlen == 'd1 || jlen == 'd4) begin
            for (ilen_t i = 0; i < ilen; i++) begin
                for (jlen_t j = 0; j < jlen; j++) begin
                    slv.exe_rsp.vd_data[VecSumWidth*i +: VecSumWidth] = macc(
                        slv.exe_rsp.vd_data[VecSumWidth*i +: VecSumWidth],
                        slv.exe_req.vs_data[0][(jlen*i + j)*8 +: 8],
                        slv.exe_req.vs_data[1][(jlen*i + j)*8 +: 8]
                    );
                end
            end
        end
    end

endmodule
