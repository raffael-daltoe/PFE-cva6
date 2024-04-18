#pragma once

#include <stdint.h>
#include <stdlib.h>

#include "config.h"
#include "misc.h"

#define V8LEN (16)
#define V32LEN (V8LEN/4)
#define VNUM (32)

#ifdef MODEL

void vload(size_t vd, const void *rs1, int32_t imm);
void vbias(size_t vd, int32_t rs1, int32_t imm);
void vmacc(size_t vd, size_t vs1, size_t vs2, int32_t imm);
void vactv(size_t vs3, void *rs1, int32_t rs2, int32_t imm);

#define VLOAD(VD, RS1, IMM)       vload(VD, RS1, IMM)
#define VBIAS(VD, RS1, IMM)       vbias(VD, RS1, IMM)
#define VMACC(VD, VS1, VS2, IMM)  vmacc(VD, VS1, VS2, IMM)
#define VACTV(VS3, RS1, RS2, IMM) vactv(VS3, RS1, RS2, IMM)

#else

#define VLOAD(VD, RS1, IMM) \
asm volatile ( \
    "xadac.vload %[vd], %[rs1], %[imm]" \
    : : \
    [vd]  "i" (VD), \
    [rs1] "r" (RS1), \
    [imm] "i" (IMM) \
    : \
)

#define VBIAS(VD, RS1, IMM) \
asm volatile ( \
    "xadac.vbias %[vd], %[rs1], %[imm]" \
    : : \
    [vd]  "i" (VD), \
    [rs1] "r" (RS1), \
    [imm] "i" (IMM) \
    : \
)

#define VMACC(VD, VS1, VS2, IMM) \
asm volatile ( \
    "xadac.vmacc %[vd], %[vs1], %[vs2], %[imm]" \
    : : \
    [vd]  "i" (VD), \
    [vs1] "i" (VS1), \
    [vs2] "i" (VS2), \
    [imm] "i" (IMM) \
    : \
)

#define VACTV(VS3, RS1, RS2, IMM) \
asm volatile ( \
    "xadac.vactv %[vs3], %[rs1], %[rs2], %[imm]" \
    : : \
    [vs3] "i" (VS3), \
    [rs1] "r" (RS1), \
    [rs2] "r" (RS2), \
    [imm] "i" (IMM) \
    : \
)

#endif