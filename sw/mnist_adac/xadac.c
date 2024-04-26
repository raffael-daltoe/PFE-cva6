#include "xadac.h"

#ifdef MODEL

static uint8_t vrf[VNUM*V8LEN];

static int32_t *vrf_i32 = (int32_t *) vrf;
static uint8_t *vrf_u8 = (uint8_t *) vrf;
static int8_t *vrf_i8 = (int8_t *) vrf;

void vload(size_t vd, const void *rs1, int32_t imm)
{

#ifdef VALIDATE
    ASSERT(imm <= V8LEN);
#endif

    uint8_t *ptr = (uint8_t *) rs1;

    for (size_t i = 0; i < V8LEN; i++) {
        vrf_u8[vd*V8LEN + i] = ptr[i % imm];
    }
}

void vbias(size_t vd, int32_t rs1, int32_t imm)
{

#ifdef VALIDATE
    ASSERT(imm <= V32LEN);
#endif

    for (size_t i = 0; i < V32LEN; i++) {
        if (i < imm) {
            vrf_i32[vd*V32LEN + i] = rs1;
        } else {
            vrf_i32[vd*V32LEN + i] = 0;
        }
    }
}

#define PRINT128(n) { printf("%08lx%08lx%08lx%08lx", (n)[3], (n)[2], (n)[1], (n)[0]); }

void vmacc(size_t vd, size_t vs1, size_t vs2, int32_t imm)
{

#ifdef VALIDATE
    ASSERT(imm <= 4);
#endif

    for (size_t i = 0; i < V32LEN; i++) {
        for (size_t j = 0; j < imm; j++) {
            vrf_i32[vd*V32LEN + i] +=
                vrf_i8[vs1*V8LEN + i*imm + j] * vrf_u8[vs2*V8LEN + i*imm + j];
        }
    }
}

void vactv(size_t vs3, void *rs1, int32_t rs2, int32_t imm)
{

#ifdef VALIDATE
    ASSERT(imm <= V32LEN);
#endif

    uint8_t *ptr = (uint8_t *) rs1;

    for (size_t i = 0; i < V32LEN; i++) {
        if (i < imm) {
            int32_t sum = vrf_i32[vs3*V32LEN + i];
            sum = (sum > 0) ? (sum >> rs2) : 0;
            ptr[i] = (uint8_t) sum;
        }
    }
}

#endif