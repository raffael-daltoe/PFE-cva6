// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 06.10.2017
// Description: Performance counters


module perf_counters
  import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg  = config_pkg::cva6_cfg_empty,
    parameter int unsigned           NumPorts = 3,                            // number of miss ports
    parameter int unsigned           MHPMCounterNum = 6
) (
    input logic clk_i,
    input logic rst_ni,
    input logic debug_mode_i,  // debug mode
    // SRAM like interface
    input logic [11:0] addr_i,  // read/write address
    input logic we_i,  // write enable
    input riscv::xlen_t data_i,  // data to write
    output riscv::xlen_t data_o,  // data to read
    // from commit stage
    input  scoreboard_entry_t [CVA6Cfg.NrCommitPorts-1:0] commit_instr_i,     // the instruction we want to commit
    input  logic [CVA6Cfg.NrCommitPorts-1:0]              commit_ack_i,       // acknowledge that we are indeed committing
    // from L1 caches
    input logic l1_icache_miss_i,
    input logic l1_dcache_miss_i,
    // from MMU
    input logic itlb_miss_i,
    input logic dtlb_miss_i,
    // from issue stage
    input logic sb_full_i,
    // from frontend
    input logic if_empty_i,
    // from PC Gen
    input exception_t ex_i,
    input logic eret_i,
    input bp_resolve_t resolved_branch_i,
    // for newly added events
    input exception_t branch_exceptions_i,  //Branch exceptions->execute unit-> branch_exception_o
    input icache_dreq_t l1_icache_access_i,
    input dcache_req_i_t [2:0] l1_dcache_req_i_i,
    input dcache_req_o_t [2:0] l1_dcache_req_o_i,
    input logic [NumPorts-1:0][DCACHE_SET_ASSOC-1:0]miss_vld_bits_i,  //For Cache eviction (3ports-LOAD,STORE,PTW)
    input logic i_tlb_flush_i,
    input logic stall_issue_i,  //stall-read operands
    input logic [31:0] mcountinhibit_i,
    // for adac events
    input logic if_id_fetch_valid_i,
    input logic if_id_fetch_ready_i,
    input logic is_ex_alu_valid_i,
    input logic is_ex_alu_ready_i,
    input logic is_ex_branch_valid_i,
    input logic is_ex_branch_ready_i,
    input logic is_ex_csr_valid_i,
    input logic is_ex_csr_ready_i,
    input logic is_ex_mult_valid_i,
    input logic is_ex_mult_ready_i,
    input logic is_ex_lsu_valid_i,
    input logic is_ex_lsu_ready_i, 
    input logic is_ex_fpu_valid_i,
    input logic is_ex_fpu_ready_i,
    input logic is_ex_cvxif_valid_i,
    input logic is_ex_cvxif_ready_i
);

  localparam ELEN = 8;

  typedef enum logic [ELEN-1:0] {
    L1_ICACHE_MISS   = 'h01, // L1 Instruction Cache Miss
    L1_DCACHE_MISS   = 'h02, // L1 Data Cache Miss
    ITLB_MISS        = 'h03, // Instruction TLB Miss
    DTLB_MISS        = 'h04, // Data TLB Miss
    INSTR_LOAD       = 'h05, // Load Instruction
    INSTR_STORE      = 'h06, // Store Instruction
    EXCP             = 'h07, // Exception
    EXCP_HANDLER_RET = 'h08, // Exception Handler Return
    INSTR_BRANCH     = 'h09, // Branch Instruction
    BRANCH_MISPRED   = 'h0A, // Branch Misprediction
    BRANCH_EXCP      = 'h0B, // Branch Exception
    INSTR_CALL       = 'h0C, // Call Instruction
    INSTR_RET        = 'h0D, // Return Instruction
    SCOREBOARD_FULL  = 'h0E, // Scoreboard Full
    IFETCH_EMPTY     = 'h0F, // Instruction Fetch Empty
    L1_ICACHE_REQ    = 'h10, // L1 Instruction Cache Request Valid
    L1_DCACHE_REQ    = 'h11, // L1 Data Cache Request Valid
    CACHE_LINE_EVICT = 'h12, // Cache Line Eviction
    ITLB_FLUSH       = 'h13, // ITLB Flush
    INSTR_INTEGER    = 'h14, // Integer Instruction
    INSTR_FLOAT      = 'h15, // Floating Point Instruction
    PIPELINE_STALL   = 'h16, // Pipeline Stall

    // ADAC Events
    IF_ID_FETCH_BOUND   = 'h20,
    IS_EX_ISSUED        = 'h21,
    IS_EX_ALU_BOUND     = 'h22,
    IS_EX_BRANCH_BOUND  = 'h23,
    IS_EX_CSR_BOUND     = 'h24,
    IS_EX_MULT_BOUND    = 'h25,
    IS_EX_LSU_BOUND     = 'h26,
    IS_EX_FPU_BOUND     = 'h27,
    IS_EX_CVXIF_BOUND   = 'h28,
    IS_EX_IDLE          = 'h29,
    L1_DCACHE_TRANSFERS = 'h2A,
    L1_DCACHE_STALL     = 'h2B,
    L1_DCACHE_LATENCY   = 'h2C
  } event_id_t;

  logic if_id_fetch_bound;
  logic is_ex_issued;
  logic is_ex_alu_bound;
  logic is_ex_branch_bound;
  logic is_ex_csr_bound;
  logic is_ex_mult_bound;
  logic is_ex_lsu_bound;
  logic is_ex_fpu_bound;
  logic is_ex_cvxif_bound;
  logic is_ex_idle;

  logic [ELEN-1:0] dcache_inflight_d;
  logic [ELEN-1:0] dcache_inflight_q;

  always_comb begin : adac_events
    
    if_id_fetch_bound = !if_id_fetch_valid_i && if_id_fetch_ready_i;

    is_ex_issued = 
      (is_ex_alu_valid_i && is_ex_alu_ready_i) ||
      (is_ex_branch_valid_i && is_ex_branch_ready_i) ||
      (is_ex_csr_valid_i && is_ex_csr_ready_i) ||
      (is_ex_mult_valid_i && is_ex_mult_ready_i) ||
      (is_ex_lsu_valid_i && is_ex_lsu_ready_i) ||
      (is_ex_fpu_valid_i && is_ex_fpu_ready_i) ||
      (is_ex_cvxif_valid_i && is_ex_cvxif_ready_i);

    is_ex_alu_bound = 0;
    is_ex_branch_bound = 0;
    is_ex_csr_bound = 0;
    is_ex_mult_bound = 0;
    is_ex_lsu_bound = 0;
    is_ex_fpu_bound = 0;
    is_ex_cvxif_bound = 0;
    is_ex_idle = 0;

    if (is_ex_issued) begin
      // EMPTY
    end
    else if (is_ex_alu_valid_i && !is_ex_alu_ready_i) begin
      is_ex_alu_bound = 1;
    end
    else if (is_ex_branch_valid_i && !is_ex_branch_ready_i) begin
      is_ex_branch_bound = 1;
    end
    else if (is_ex_csr_valid_i && !is_ex_csr_ready_i) begin
      is_ex_csr_bound = 1;
    end
    else if (is_ex_mult_valid_i && !is_ex_mult_ready_i) begin
      is_ex_mult_bound = 1;
    end
    else if (is_ex_lsu_valid_i && !is_ex_lsu_ready_i) begin
      is_ex_lsu_bound = 1;
    end
    else if (is_ex_fpu_valid_i && !is_ex_fpu_ready_i) begin
      is_ex_fpu_bound = 1;
    end
    else if (is_ex_cvxif_valid_i && !is_ex_cvxif_ready_i) begin
      is_ex_cvxif_bound = 1;
    end
    else begin
      is_ex_idle = 1;
    end

    dcache_inflight_d = dcache_inflight_q;
    for (int unsigned i = 0; i < 3; i++) begin
      dcache_inflight_d -= l1_dcache_req_o_i[i].data_rvalid;
      dcache_inflight_d += (l1_dcache_req_i_i[i].data_req &&
        l1_dcache_req_o_i[i].data_gnt);
    end
  end
    
  logic [63:0] generic_counter_d [MHPMCounterNum-1:0];
  logic [63:0] generic_counter_q [MHPMCounterNum-1:0];

  logic [ELEN-1:0] mhpmevent_d [MHPMCounterNum-1:0];
  logic [ELEN-1:0] mhpmevent_q [MHPMCounterNum-1:0];

  //internal signal to keep track of exception
  logic read_access_exception, update_access_exception;

  logic [3:0] events [MHPMCounterNum-1:0];

  //Multiplexer
  always_comb begin : Mux
    events[MHPMCounterNum-1:0] = '{default: 0};

    for (int unsigned i = 0; i < MHPMCounterNum; i++) begin
      unique case (mhpmevent_q[i])
        
        L1_ICACHE_MISS: begin
          events[i] += l1_icache_miss_i;
        end

        L1_DCACHE_MISS: begin
          events[i] += l1_dcache_miss_i;
        end

        ITLB_MISS: begin
          events[i] += itlb_miss_i;
        end

        DTLB_MISS: begin
          events[i] += dtlb_miss_i;
        end

        INSTR_LOAD: begin
          for (int unsigned j = 0; j < CVA6Cfg.NrCommitPorts; j++) begin
            if (commit_ack_i[j]) begin
              events[i] += commit_instr_i[j].fu == LOAD;
            end
          end
        end

        INSTR_STORE: begin
          for (int unsigned j = 0; j < CVA6Cfg.NrCommitPorts; j++) begin
            if (commit_ack_i[j]) begin
              events[i] += commit_instr_i[j].fu == STORE; 
            end
          end
        end

        EXCP: begin
          events[i] += ex_i.valid;
        end

        EXCP_HANDLER_RET: begin
          events[i] += eret_i;
        end

        INSTR_BRANCH: begin
          for (int unsigned j = 0; j < CVA6Cfg.NrCommitPorts; j++) begin
            if (
              (commit_ack_i[j]) &&
              (commit_instr_i[j].fu == CTRL_FLOW)
            ) begin
              events[i] += 1;
            end
          end
        end

        BRANCH_MISPRED: begin
          events[i] = resolved_branch_i.valid && resolved_branch_i.is_mispredict;
        end

        BRANCH_EXCP: begin
          events[i] = branch_exceptions_i.valid;
        end

        INSTR_CALL: begin
          // The standard software calling convention uses register x1 to hold the return address on a call
          // the unconditional jump is decoded as ADD op

          for (int unsigned j = 0; j < CVA6Cfg.NrCommitPorts; j++) begin
            if (
              (commit_ack_i[j]) &&
              (commit_instr_i[j].fu == CTRL_FLOW) &&
              (commit_instr_i[j].op == ADD || commit_instr_i[j].op == JALR) &&
              (commit_instr_i[j].rd == 'd1 || commit_instr_i[j].rd == 'd5)
            ) begin
              events[i] += 1;
            end
          end
        end

        INSTR_RET: begin
          for (int unsigned j = 0; j < CVA6Cfg.NrCommitPorts; j++) begin
            if (
              (commit_ack_i[j]) &&
              (commit_instr_i[j].op == JALR) &&
              (commit_instr_i[j].rd == 'd0)
            ) begin
              events[i] += 1;
            end
          end
        end

        SCOREBOARD_FULL: begin
          events[i] = sb_full_i;  //MSB Full
        end

        IFETCH_EMPTY: begin
          events[i] = if_empty_i;
        end

        L1_ICACHE_REQ: begin
          events[i] = l1_icache_access_i.req;
        end

        L1_DCACHE_REQ: begin
          events[i] += l1_dcache_req_i_i[0].data_req;
          events[i] += l1_dcache_req_i_i[1].data_req;
          events[i] += l1_dcache_req_i_i[2].data_req;
        end

        CACHE_LINE_EVICT: begin
          events[i] += l1_dcache_miss_i && miss_vld_bits_i[0] == 8'hFF;
          events[i] += l1_dcache_miss_i && miss_vld_bits_i[1] == 8'hFF;
          events[i] += l1_dcache_miss_i && miss_vld_bits_i[2] == 8'hFF;
        end

        ITLB_FLUSH: begin
          events[i] = i_tlb_flush_i;
        end

        INSTR_INTEGER: begin
          for (int unsigned j = 0; j < CVA6Cfg.NrCommitPorts; j++) begin
            if (commit_ack_i[j]) begin
              events[i] += commit_instr_i[j].fu == ALU;
              events[i] += commit_instr_i[j].fu == MULT;
            end
          end
        end

        INSTR_FLOAT: begin
          for (int unsigned j = 0; j < CVA6Cfg.NrCommitPorts; j++) begin
            if (commit_ack_i[j]) begin
              events[i] += commit_instr_i[j].fu == FPU;
              events[i] += commit_instr_i[j].fu == FPU_VEC;
            end
          end
        end

        PIPELINE_STALL: begin
          events[i] = stall_issue_i;  //Pipeline bubbles
        end

        IF_ID_FETCH_BOUND: begin
          events[i] = if_id_fetch_bound;
        end

        IS_EX_ISSUED: begin
          events[i] = is_ex_issued;  
        end

        IS_EX_ALU_BOUND: begin
          events[i] = is_ex_alu_bound;
        end

        IS_EX_BRANCH_BOUND: begin
          events[i] = is_ex_branch_bound;
        end

        IS_EX_CSR_BOUND: begin
          events[i] = is_ex_csr_bound;
        end

        IS_EX_MULT_BOUND: begin
          events[i] = is_ex_mult_bound;
        end

        IS_EX_LSU_BOUND: begin
          events[i] = is_ex_lsu_bound;
        end

        IS_EX_FPU_BOUND: begin
          events[i] = is_ex_fpu_bound;
        end

        IS_EX_CVXIF_BOUND: begin
          events[i] = is_ex_cvxif_bound;
        end

        IS_EX_IDLE: begin
          events[i] = is_ex_idle;
        end

        L1_DCACHE_TRANSFERS: begin
          for (int unsigned j = 0; j < 3; j++) begin
            events[i] += (l1_dcache_req_i_i[j].data_req &&
              l1_dcache_req_o_i[j].data_gnt);
          end
        end

        L1_DCACHE_STALL: begin
          for (int unsigned j = 0; j < 3; j++) begin
            events[i] += (l1_dcache_req_i_i[j].data_req &&
              !l1_dcache_req_o_i[j].data_gnt);
          end
        end

        L1_DCACHE_LATENCY: begin
          events[i] += dcache_inflight_q;
        end

      endcase
    end

  end

  always_comb begin : generic_counter
    generic_counter_d = generic_counter_q;
    data_o = 'b0;
    mhpmevent_d = mhpmevent_q;
    read_access_exception = 1'b0;
    update_access_exception = 1'b0;

    // Increment the non-inhibited counters with active events
    for (int unsigned i = 0; i < MHPMCounterNum; i++) begin
      if ((!debug_mode_i) && (!we_i)) begin
        if (!mcountinhibit_i[i+3]) begin
          generic_counter_d[i] = generic_counter_q[i] + events[i];
        end
      end
    end

    // Read and Write
    if (
      (addr_i >= riscv::CSR_MHPM_COUNTER_3) &&
      (addr_i < riscv::CSR_MHPM_COUNTER_3 + MHPMCounterNum)
    ) begin
      // MHPM_COUNTER

      // Read
      if (riscv::XLEN == 32) begin
        data_o = generic_counter_q[addr_i-riscv::CSR_MHPM_COUNTER_3][31:0];
      end
      else begin
        data_o = generic_counter_q[addr_i-riscv::CSR_MHPM_COUNTER_3];
      end

      // Write
      if (we_i) begin
        if (riscv::XLEN == 32) begin
          generic_counter_d[addr_i-riscv::CSR_MHPM_COUNTER_3][31:0] = data_i;
        end
        else begin
          generic_counter_d[addr_i-riscv::CSR_MHPM_COUNTER_3] = data_i;
        end
      end

    end
    else if (
      (addr_i >= riscv::CSR_MHPM_COUNTER_3H) &&
      (addr_i < riscv::CSR_MHPM_COUNTER_3H + MHPMCounterNum)
    ) begin
      // MHPM_COUNTER_H

      // Read
      if (riscv::XLEN == 32) begin
        data_o = generic_counter_q[addr_i-riscv::CSR_MHPM_COUNTER_3H][63:32];
      end
      else begin
        read_access_exception = 1'b1;
      end

      // Write
      if (we_i) begin
        if (riscv::XLEN == 32) begin
          generic_counter_d[addr_i-riscv::CSR_MHPM_COUNTER_3H][63:32] = data_i;
        end
        else begin
          update_access_exception = 1'b1;
        end
      end
    
    end
    else if (
      (addr_i >= riscv::CSR_MHPM_EVENT_3) &&
      (addr_i < riscv::CSR_MHPM_EVENT_3 + MHPMCounterNum)
    ) begin
      // MHPM_EVENT

      // Read
      data_o = mhpmevent_q[addr_i-riscv::CSR_MHPM_EVENT_3];

      // Write
      if (we_i) begin
        mhpmevent_d[addr_i-riscv::CSR_MHPM_EVENT_3] = data_i;
      end

    end
    else begin
      // Default

      // Read
      data_o = 'b0;

      // Write
      if (we_i) begin
        update_access_exception = 1'b1;
      end

    end
  end

  //Registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      generic_counter_q <= '{default: 0};
      mhpmevent_q       <= '{default: 0};
      dcache_inflight_q <= '{default: 0};
    end 
    else begin
      generic_counter_q <= generic_counter_d;
      mhpmevent_q       <= mhpmevent_d;
      dcache_inflight_q <= dcache_inflight_d;
    end
  end

endmodule
