#include "perf.h"

static uint32_t perf_cycles;
static uint32_t perf_retired;
#ifdef ADAC_HPM
    static uint32_t perf_mhpcounters[32];
#endif

void perf_init()
{
    perf_cycles = 0;
    perf_retired = 0;

#ifdef ADAC_HPM
    for (int i = 0; i < 32; i++) {
        perf_mhpcounters[i] = 0;
    }

    CSR_WRITE(0x323, 0x01); // mhpevent[3]  - L1_ICACHE_MISS
    CSR_WRITE(0x324, 0x02); // mhpevent[4]  - L1_DCACHE_MISS
    CSR_WRITE(0x325, 0x05); // mhpevent[5]  - INSTR_LOAD
    CSR_WRITE(0x326, 0x06); // mhpevent[6]  - INSTR_STORE
    CSR_WRITE(0x327, 0x07); // mhpevent[7]  - EXCP
    CSR_WRITE(0x328, 0x08); // mhpevent[8]  - EXCP_HANDLER_RET
    CSR_WRITE(0x329, 0x09); // mhpevent[9]  - INSTR_BRANCH
    CSR_WRITE(0x32A, 0x0A); // mhpevent[10] - BRANCH_MISPRED
    CSR_WRITE(0x32B, 0x0B); // mhpevent[11] - BRACH_EXCEP
    CSR_WRITE(0x32C, 0x0C); // mhpevent[12] - INSTR_CALL
    CSR_WRITE(0x32D, 0x0D); // mhpevent[13] - INSTR_RET
    CSR_WRITE(0x32E, 0x0E); // mhpevent[14] - SCOREBOARD_FULL
    CSR_WRITE(0x32F, 0x12); // mhpevent[15] - CACHE_LINE_EVICT
    CSR_WRITE(0x330, 0x14); // mhpevent[16] - INSTR_INTEGER
    CSR_WRITE(0x331, 0x15); // mhpevent[17] - INSTR_FLOAT
    CSR_WRITE(0x332, 0x20); // mhpevent[18] - IF_ID_FETCH_BOUND
    CSR_WRITE(0x333, 0x21); // mhpevent[19] - IS_EX_ISSUED
    CSR_WRITE(0x334, 0x22); // mhpevent[20] - IS_EX_ALU_BOUND
    CSR_WRITE(0x335, 0x23); // mhpevent[21] - IS_EX_BRANCH_BOUND
    CSR_WRITE(0x336, 0x24); // mhpevent[22] - IS_EX_CSR_BOUND
    CSR_WRITE(0x337, 0x25); // mhpevent[23] - IS_EX_MULT_BOUND
    CSR_WRITE(0x338, 0x26); // mhpevent[24] - IS_EX_LSU_BOUND
    CSR_WRITE(0x339, 0x27); // mhpevent[25] - IS_EX_FPU_BOUND
    CSR_WRITE(0x33A, 0x28); // mhpevent[26] - IS_EX_CVXIF_BOUND
    CSR_WRITE(0x33B, 0x29); // mhpevent[27] - IS_EX_IDLE
    CSR_WRITE(0x33C, 0x2A); // mhpevent[28] - L1_DCACHE_TRANSFERS
    CSR_WRITE(0x33D, 0x2B); // mhpevent[29] - L1_DCACHE_STALL
    CSR_WRITE(0x33E, 0x2C); // mhpevent[30] - L1_DCACHE_LATENCY
    CSR_WRITE(0x33F, 0);    // mhpevent[31]
#endif

}

void perf_tic()
{

#ifdef ADAC_HPM
    perf_mhpcounters[0]  = 0;
    perf_mhpcounters[1]  = 0;
    perf_mhpcounters[2]  = 0;
    perf_mhpcounters[3]  = -CSR_READ(0xB03);
    perf_mhpcounters[4]  = -CSR_READ(0xB04);
    perf_mhpcounters[5]  = -CSR_READ(0xB05);
    perf_mhpcounters[6]  = -CSR_READ(0xB06);
    perf_mhpcounters[7]  = -CSR_READ(0xB07);
    perf_mhpcounters[8]  = -CSR_READ(0xB08);
    perf_mhpcounters[9]  = -CSR_READ(0xB09);
    perf_mhpcounters[10] = -CSR_READ(0xB0A);
    perf_mhpcounters[11] = -CSR_READ(0xB0B);
    perf_mhpcounters[12] = -CSR_READ(0xB0C);
    perf_mhpcounters[13] = -CSR_READ(0xB0D);
    perf_mhpcounters[14] = -CSR_READ(0xB0E);
    perf_mhpcounters[15] = -CSR_READ(0xB0F);
    perf_mhpcounters[16] = -CSR_READ(0xB10);
    perf_mhpcounters[17] = -CSR_READ(0xB11);
    perf_mhpcounters[18] = -CSR_READ(0xB12);
    perf_mhpcounters[19] = -CSR_READ(0xB13);
    perf_mhpcounters[20] = -CSR_READ(0xB14);
    perf_mhpcounters[21] = -CSR_READ(0xB15);
    perf_mhpcounters[22] = -CSR_READ(0xB16);
    perf_mhpcounters[23] = -CSR_READ(0xB17);
    perf_mhpcounters[24] = -CSR_READ(0xB18);
    perf_mhpcounters[25] = -CSR_READ(0xB19);
    perf_mhpcounters[26] = -CSR_READ(0xB1A);
    perf_mhpcounters[27] = -CSR_READ(0xB1B);
    perf_mhpcounters[28] = -CSR_READ(0xB1C);
    perf_mhpcounters[29] = -CSR_READ(0xB1D);
    perf_mhpcounters[30] = -CSR_READ(0xB1E);
    perf_mhpcounters[31] = -CSR_READ(0xB1F);
#endif

    perf_cycles  = -CSR_READ(mcycle);
    perf_retired = -CSR_READ(minstret);
}

void perf_toc()
{
    perf_cycles  += CSR_READ(mcycle);
    perf_retired += CSR_READ(minstret);

#ifdef ADAC_HPM
    perf_mhpcounters[0]  += 0;
    perf_mhpcounters[1]  += 0;
    perf_mhpcounters[2]  += 0;
    perf_mhpcounters[3]  += CSR_READ(0xB03);
    perf_mhpcounters[4]  += CSR_READ(0xB04);
    perf_mhpcounters[5]  += CSR_READ(0xB05);
    perf_mhpcounters[6]  += CSR_READ(0xB06);
    perf_mhpcounters[7]  += CSR_READ(0xB07);
    perf_mhpcounters[8]  += CSR_READ(0xB08);
    perf_mhpcounters[9]  += CSR_READ(0xB09);
    perf_mhpcounters[10] += CSR_READ(0xB0A);
    perf_mhpcounters[11] += CSR_READ(0xB0B);
    perf_mhpcounters[12] += CSR_READ(0xB0C);
    perf_mhpcounters[13] += CSR_READ(0xB0D);
    perf_mhpcounters[14] += CSR_READ(0xB0E);
    perf_mhpcounters[15] += CSR_READ(0xB0F);
    perf_mhpcounters[16] += CSR_READ(0xB10);
    perf_mhpcounters[17] += CSR_READ(0xB11);
    perf_mhpcounters[18] += CSR_READ(0xB12);
    perf_mhpcounters[19] += CSR_READ(0xB13);
    perf_mhpcounters[20] += CSR_READ(0xB14);
    perf_mhpcounters[21] += CSR_READ(0xB15);
    perf_mhpcounters[22] += CSR_READ(0xB16);
    perf_mhpcounters[23] += CSR_READ(0xB17);
    perf_mhpcounters[24] += CSR_READ(0xB18);
    perf_mhpcounters[25] += CSR_READ(0xB19);
    perf_mhpcounters[26] += CSR_READ(0xB1A);
    perf_mhpcounters[27] += CSR_READ(0xB1B);
    perf_mhpcounters[28] += CSR_READ(0xB1C);
    perf_mhpcounters[29] += CSR_READ(0xB1D);
    perf_mhpcounters[30] += CSR_READ(0xB1E);
    perf_mhpcounters[31] += CSR_READ(0xB1F);
#endif

    printf("CYCLES,             %10lu\n", perf_cycles);
    printf("RETIRED,            %10lu\n", perf_retired);
#ifdef ADAC_HPM
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
#endif
}