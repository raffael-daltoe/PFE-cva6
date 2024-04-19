interface xadac_if;

    import xadac_pkg::*;

    DecReqT dec_req;
    logic   dec_req_valid;
    logic   dec_req_ready;

    DecRspT dec_rsp;
    logic   dec_rsp_valid;
    logic   dec_rsp_ready;

    ExeReqT exe_req;
    logic   exe_req_valid;
    logic   exe_req_ready;

    ExeRspT exe_rsp;
    logic   exe_rsp_valid;
    logic   exe_rsp_ready;

    modport mst (
        output dec_req,
        output dec_req_valid,
        input  dec_req_ready,

        input  dec_rsp,
        input  dec_rsp_valid,
        output dec_rsp_ready,

        output exe_req,
        output exe_req_valid,
        input  exe_req_ready,

        input  exe_rsp,
        input  exe_rsp_valid,
        output exe_rsp_ready
    );

    modport slv (
        input  dec_req,
        input  dec_req_valid,
        output dec_req_ready,

        output dec_rsp,
        output dec_rsp_valid,
        input  dec_rsp_ready,

        input  exe_req,
        input  exe_req_valid,
        output exe_req_ready,

        output exe_rsp,
        output exe_rsp_valid,
        input  exe_rsp_ready
    );

endinterface
