#include "perf.h"

static uint32_t perf_cycles;
static uint32_t perf_retired;
static uint32_t perf_mhpcounters[32];

void perf_init()
{  
    perf_cycles = 0;
    perf_retired = 0;

    for (int i = 0; i < 32; i++) {
        perf_mhpcounters[i] = 0;
    }
    
    write_csr(0x323, 0x01); // mhpevent[3]  - L1_ICACHE_MISS
    write_csr(0x324, 0x02); // mhpevent[4]  - L1_DCACHE_MISS
    write_csr(0x325, 0x05); // mhpevent[5]  - INSTR_LOAD
    write_csr(0x326, 0x06); // mhpevent[6]  - INSTR_STORE 
    write_csr(0x327, 0x07); // mhpevent[7]  - EXCP
    write_csr(0x328, 0x08); // mhpevent[8]  - EXCP_HANDLER_RET
    write_csr(0x329, 0x09); // mhpevent[9]  - INSTR_BRANCH
    write_csr(0x32A, 0x0A); // mhpevent[10] - BRANCH_MISPRED
    write_csr(0x32B, 0x0B); // mhpevent[11] - BRACH_EXCEP
    write_csr(0x32C, 0x0C); // mhpevent[12] - INSTR_CALL
    write_csr(0x32D, 0x0D); // mhpevent[13] - INSTR_RET
    write_csr(0x32E, 0x0E); // mhpevent[14] - SCOREBOARD_FULL
    write_csr(0x32F, 0x12); // mhpevent[15] - CACHE_LINE_EVICT 
    write_csr(0x330, 0x14); // mhpevent[16] - INSTR_INTEGER 
    write_csr(0x331, 0x15); // mhpevent[17] - INSTR_FLOAT 
    write_csr(0x332, 0x20); // mhpevent[18] - IF_ID_FETCH_BOUND
    write_csr(0x333, 0x21); // mhpevent[19] - IS_EX_ISSUED
    write_csr(0x334, 0x22); // mhpevent[20] - IS_EX_ALU_BOUND 
    write_csr(0x335, 0x23); // mhpevent[21] - IS_EX_BRANCH_BOUND
    write_csr(0x336, 0x24); // mhpevent[22] - IS_EX_CSR_BOUND
    write_csr(0x337, 0x25); // mhpevent[23] - IS_EX_MULT_BOUND
    write_csr(0x338, 0x26); // mhpevent[24] - IS_EX_LSU_BOUND
    write_csr(0x339, 0x27); // mhpevent[25] - IS_EX_FPU_BOUND
    write_csr(0x33A, 0x28); // mhpevent[26] - IS_EX_CVXIF_BOUND
    write_csr(0x33B, 0x29); // mhpevent[27] - IS_EX_IDLE
    write_csr(0x33C, 0x2A); // mhpevent[28] - L1_DCACHE_TRANSFERS
    write_csr(0x33D, 0x2B); // mhpevent[29] - L1_DCACHE_STALL
    write_csr(0x33E, 0x2C); // mhpevent[30] - L1_DCACHE_LATENCY 
    write_csr(0x33F, 0);    // mhpevent[31]
}

void perf_tic()
{
    printf("tic\n");
    
    perf_cycles  = -read_csr(mcycle);
    perf_retired = -read_csr(minstret);

    perf_mhpcounters[0]  = 0;
    perf_mhpcounters[1]  = 0;
    perf_mhpcounters[2]  = 0;
    perf_mhpcounters[3]  = -read_csr(0xB03);
    perf_mhpcounters[4]  = -read_csr(0xB04);
    perf_mhpcounters[5]  = -read_csr(0xB05);
    perf_mhpcounters[6]  = -read_csr(0xB06);
    perf_mhpcounters[7]  = -read_csr(0xB07);
    perf_mhpcounters[8]  = -read_csr(0xB08);
    perf_mhpcounters[9]  = -read_csr(0xB09);
    perf_mhpcounters[10] = -read_csr(0xB0A);
    perf_mhpcounters[11] = -read_csr(0xB0B);
    perf_mhpcounters[12] = -read_csr(0xB0C);
    perf_mhpcounters[13] = -read_csr(0xB0D);
    perf_mhpcounters[14] = -read_csr(0xB0E);
    perf_mhpcounters[15] = -read_csr(0xB0F);
    perf_mhpcounters[16] = -read_csr(0xB10);
    perf_mhpcounters[17] = -read_csr(0xB11);
    perf_mhpcounters[18] = -read_csr(0xB12);
    perf_mhpcounters[19] = -read_csr(0xB13);
    perf_mhpcounters[20] = -read_csr(0xB14);
    perf_mhpcounters[21] = -read_csr(0xB15);
    perf_mhpcounters[22] = -read_csr(0xB16);
    perf_mhpcounters[23] = -read_csr(0xB17);
    perf_mhpcounters[24] = -read_csr(0xB18);
    perf_mhpcounters[25] = -read_csr(0xB19);
    perf_mhpcounters[26] = -read_csr(0xB1A);
    perf_mhpcounters[27] = -read_csr(0xB1B);
    perf_mhpcounters[28] = -read_csr(0xB1C);
    perf_mhpcounters[29] = -read_csr(0xB1D);
    perf_mhpcounters[30] = -read_csr(0xB1E);
    perf_mhpcounters[31] = -read_csr(0xB1F);
}

void perf_toc()
{
    perf_cycles  += read_csr(mcycle);
    perf_retired += read_csr(minstret);

    perf_mhpcounters[0]  = 0;
    perf_mhpcounters[1]  = 0;
    perf_mhpcounters[2]  = 0;
    perf_mhpcounters[3]  += read_csr(0xB03);
    perf_mhpcounters[4]  += read_csr(0xB04);
    perf_mhpcounters[5]  += read_csr(0xB05);
    perf_mhpcounters[6]  += read_csr(0xB06);
    perf_mhpcounters[7]  += read_csr(0xB07);
    perf_mhpcounters[8]  += read_csr(0xB08);
    perf_mhpcounters[9]  += read_csr(0xB09);
    perf_mhpcounters[10] += read_csr(0xB0A);
    perf_mhpcounters[11] += read_csr(0xB0B);
    perf_mhpcounters[12] += read_csr(0xB0C);
    perf_mhpcounters[13] += read_csr(0xB0D);
    perf_mhpcounters[14] += read_csr(0xB0E);
    perf_mhpcounters[15] += read_csr(0xB0F);
    perf_mhpcounters[16] += read_csr(0xB10);
    perf_mhpcounters[17] += read_csr(0xB11);
    perf_mhpcounters[18] += read_csr(0xB12);
    perf_mhpcounters[19] += read_csr(0xB13);
    perf_mhpcounters[20] += read_csr(0xB14);
    perf_mhpcounters[21] += read_csr(0xB15);
    perf_mhpcounters[22] += read_csr(0xB16);
    perf_mhpcounters[23] += read_csr(0xB17);
    perf_mhpcounters[24] += read_csr(0xB18);
    perf_mhpcounters[25] += read_csr(0xB19);
    perf_mhpcounters[26] += read_csr(0xB1A);
    perf_mhpcounters[27] += read_csr(0xB1B);
    perf_mhpcounters[28] += read_csr(0xB1C);
    perf_mhpcounters[29] += read_csr(0xB1D);
    perf_mhpcounters[30] += read_csr(0xB1E);
    perf_mhpcounters[31] += read_csr(0xB1F);

    printf("toc\n");
    printf("CYCLES,             %10lu\n", perf_cycles);
    printf("RETIRED,            %10lu\n", perf_retired);
    printf("L1_ICACHE_MISS,     %10lu\n", perf_mhpcounters[3]);
    printf("L1_DCACHE_MISS,     %10lu\n", perf_mhpcounters[4]);
    printf("INSTR_LOAD,         %10lu\n", perf_mhpcounters[5]);
    printf("INSTR_STORE,        %10lu\n", perf_mhpcounters[6]);
    printf("EXCP,               %10lu\n", perf_mhpcounters[7]);
    printf("EXCP_HANDLER_RET,   %10lu\n", perf_mhpcounters[8]);
    printf("INSTR_BRANCH,       %10lu\n", perf_mhpcounters[9]);
    printf("BRANCH_MISPRED,     %10lu\n", perf_mhpcounters[10]);
    printf("BRACH_EXCEP,        %10lu\n", perf_mhpcounters[11]);
    printf("INSTR_CALL,         %10lu\n", perf_mhpcounters[12]);
    printf("INSTR_RET,          %10lu\n", perf_mhpcounters[13]);
    printf("SCOREBOARD_FULL,    %10lu\n", perf_mhpcounters[14]);
    printf("CACHE_LINE_EVICT,   %10lu\n", perf_mhpcounters[15]);
    printf("INSTR_INTEGER,      %10lu\n", perf_mhpcounters[16]);
    printf("INSTR_FLOAT,        %10lu\n", perf_mhpcounters[17]);
    printf("IF_ID_FETCH_BOUND,  %10lu\n", perf_mhpcounters[18]);
    printf("IS_EX_ISSUED,       %10lu\n", perf_mhpcounters[19]);
    printf("IS_EX_ALU_BOUND,    %10lu\n", perf_mhpcounters[20]);
    printf("IS_EX_BRANCH_BOUND, %10lu\n", perf_mhpcounters[21]);
    printf("IS_EX_CSR_BOUND,    %10lu\n", perf_mhpcounters[22]);
    printf("IS_EX_MULT_BOUND,   %10lu\n", perf_mhpcounters[23]);
    printf("IS_EX_LSU_BOUND,    %10lu\n", perf_mhpcounters[24]);
    printf("IS_EX_FPU_BOUND,    %10lu\n", perf_mhpcounters[25]);
    printf("IS_EX_CVXIF_BOUND,  %10lu\n", perf_mhpcounters[26]);
    printf("IS_EX_IDLE,         %10lu\n", perf_mhpcounters[27]);
    printf("L1_DCACHE_TRANSFERS,%10lu\n", perf_mhpcounters[28]);
    printf("L1_DCACHE_STALL,    %10lu\n", perf_mhpcounters[29]);
    printf("L1_DCACHE_LATENCY,  %10lu\n", perf_mhpcounters[30]);
}