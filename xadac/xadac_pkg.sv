package xadac_pkg;

    import obi_pkg::*;

    localparam type SizeT = int unsigned;

    localparam SizeT NoRs = 2;
    localparam SizeT NoVs = 3;

    localparam SizeT AddrWidth    = 32;
    localparam SizeT IdWidth      = 4;
    localparam SizeT InstrWidth   = 32;
    localparam SizeT RegAddrWidth = 5;
    localparam SizeT RegDataWidth = 32;

    localparam type AddrT    = logic [AddrWidth-1:0];
    localparam type IdT      = logic [IdWidth-1:0];
    localparam type InstrT   = logic [InstrT-1:0];
    localparam type RegAddrT = logic [RegAddrWidth-1:0];
    localparam type RegDataT = logic [RegDataWidth-1:0];

    localparam SizeT VecAddrWidth = 5;
    localparam SizeT VecDataWidth = 128;
    localparam SizeT VecElemWidth = 8;
    localparam SizeT VecLenWidth  = $clog(VecDataWidth/VecElemWidth);
    localparam SizeT VecSumWidth  = 32;
    localparam SizeT VecStrbWidth = VecDataWidth/8;

    localparam type VecAddrT = logic [VecAddrWidth-1:0];
    localparam type VecDataT = logic [VecDataWidth-1:0];
    localparam type VecElemT = logic [VecElemWidth-1:0];
    localparam type VecLenT  = logic [VecLenWidth-1:0];
    localparam type VecSumT  = logic [VecSumWidth-1:0];
    localparam type VecStrbT = logic [VecStrbWidth-1:0];

    localparam SizeT NoReg = 2**RegAddrWidth;
    localparam SizeT NoVec = 2**VecAddrWidth;
    localparam SizeT SbLen = 2**IdWidth;

    localparam type DecReqT = struct packed {
        IdT    id;
        InstrT instr;
    };

    localparam type DecRspT = struct packed {
        IdT   id;
        logic rd_clobber;
        logic vd_clobber;
        logic [NoRs-1:0] rs_read;
        logic [NoVs-1:0] vs_read;
        logic accept;
    };

    localparam type ExeReqT = struct packed {
        IdT    id;
        InstrT instr;
        RegAddrT [NoRs-1:0] rs_addr;
        RegDataT [NoRs-1:0] rs_data;
        VecAddrT [NoVs-1:0] vs_addr;
        VecDataT [NoVs-1:0] vs_data;
    };

    localparam type ExeRspT = struct packed {
        IdT      id;
        RegAddrT rd_addr;
        RegDataT rd_data;
        logic    rd_write;
        VecAddrT vd_addr;
        VecDataT vd_data;
        logic    vd_write;
    };

    localparam obi_cfg_t ObiCfg = obi_default_cfg(
        AddrWidth,
        VectorWidth,
        IdWidth,
        ObiMinimalOptionalConfig
    );

    function automatic SizeT min(SizeT a, SizeT b);
        return (a < b) ? a : b;
    endfunction

    function automatic SizeT max(SizeT a, SizeT b);
        return (a > b) ? a : b;
    endfunction

endpackage
