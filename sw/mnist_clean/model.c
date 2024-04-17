#include "model.h"

#ifdef MODEL_RUN

static uint8_t vrf[VNUM*V8LEN];

static int32_t *vrf_i32 = (int32_t *) vrf;
static uint8_t *vrf_u8 = (uint8_t *) vrf;
static int8_t *vrf_i8 = (int8_t *) vrf;

void vload(size_t vd, void *rs1, int32_t imm)
{
    uint8_t *ptr = (uint8_t *) rs1;

    for (size_t i = 0; i < V8LEN; i++) {
        if (i < imm) {
            vrf_u8[vd*V8LEN + i] = ptr[i];
        } else {
            vrf_u8[vd*V8LEN + i] = 0;
        }
    }
}

void vbias(size_t vd, int32_t rs1, int32_t imm)
{
    for (size_t i = 0; i < V32LEN; i++) {
        if (i < imm) {
            vrf_i32[vd*V32LEN + i] = rs1;
        } else {
            vrf_i32[vd*V32LEN + i] = 0;
        }
    }
}

void vmacc(size_t vd, size_t vs2, size_t vs1, int32_t imm)
{
    for (size_t i = 0; i < V32LEN; i++) {
        for (size_t j = 0; j < 4; j++) {
            int32_t mul;
            if (j < imm) {
                mul = vrf_i8[vs2*V8LEN + j] * vrf_u8[vs1*V8LEN + j];
            } else {
                mul = 0;
            }
            vrf_i32[vd*V32LEN + i] += mul;
        }
    }
}

void vactv(size_t vs2, void *rs1, int32_t rs2, int32_t imm)
{
    uint8_t *ptr = (int32_t *) rs1;
    for (size_t i = 0; i < V32LEN; i++) {
        if (i < imm) {
            int32_t sum = vrf_i32[vs2*V32LEN + i];
            sum = (sum > 0) ? (sum >> rs2) : 0;
            ptr[i] = (uint8_t) sum;
        }
    }
}

#endif