package xadac_pkg;

    typedef int unsigned SizeT;

    localparam SizeT NoRs = 2;
    localparam SizeT NoVs = 3;

    localparam SizeT AddrWidth    = 32;
    localparam SizeT IdWidth      = 4;
    localparam SizeT InstrWidth   = 32;
    localparam SizeT RegAddrWidth = 5;
    localparam SizeT RegDataWidth = 32;

    typedef logic [AddrWidth-1:0]    AddrT;
    typedef logic [IdWidth-1:0]      IdT;
    typedef logic [InstrWidth-1:0]   InstrT;
    typedef logic [RegAddrWidth-1:0] RegAddrT;
    typedef logic [RegDataWidth-1:0] RegDataT;

    localparam SizeT VecAddrWidth = 5;
    localparam SizeT VecDataWidth = 128;
    localparam SizeT VecElemWidth = 8;
    localparam SizeT VecLenWidth  = $clog2(VecDataWidth/VecElemWidth+1);
    localparam SizeT VecSumWidth  = 32;
    localparam SizeT VecStrbWidth = VecDataWidth/8;

    typedef logic [VecAddrWidth-1:0] VecAddrT;
    typedef logic [VecDataWidth-1:0] VecDataT;
    typedef logic [VecElemWidth-1:0] VecElemT;
    typedef logic [VecLenWidth-1:0]  VecLenT;
    typedef logic [VecSumWidth-1:0]  VecSumT;
    typedef logic [VecStrbWidth-1:0] VecStrbT;

    localparam SizeT NoReg = 2**RegAddrWidth;
    localparam SizeT NoVec = 2**VecAddrWidth;
    localparam SizeT SbLen = 2**IdWidth;

    typedef struct packed {
        IdT    id;
        InstrT instr;
    } DecReqT;

    typedef struct packed {
        IdT   id;
        logic rd_clobber;
        logic vd_clobber;
        logic [NoRs-1:0] rs_read;
        logic [NoVs-1:0] vs_read;
        logic accept;
    } DecRspT;

    typedef struct packed {
        IdT    id;
        InstrT instr;
        RegAddrT [NoRs-1:0] rs_addr;
        RegDataT [NoRs-1:0] rs_data;
        VecAddrT [NoVs-1:0] vs_addr;
        VecDataT [NoVs-1:0] vs_data;
    } ExeReqT;

    typedef struct packed {
        IdT      id;
        RegAddrT rd_addr;
        RegDataT rd_data;
        logic    rd_write;
        VecAddrT vd_addr;
        VecDataT vd_data;
        logic    vd_write;
    } ExeRspT;

    function automatic SizeT min(SizeT a, SizeT b);
        return (a < b) ? a : b;
    endfunction

    function automatic SizeT max(SizeT a, SizeT b);
        return (a > b) ? a : b;
    endfunction

endpackage
