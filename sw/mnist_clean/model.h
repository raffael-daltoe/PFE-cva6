#pragma once

#include <stdint.h>
#include <stdlib.h>

#include "config.h"
#include "misc.h"

#ifdef MODEL_RUN

#define V8LEN (16)
#define V32LEN (V8LEN/4)
#define VNUM (32)

void vload(size_t vd, const void *rs1, int32_t imm);
void vbias(size_t vd, int32_t rs1, int32_t imm);
void vmacc(size_t vd, size_t vs2, size_t vs1, int32_t imm);
void vactv(size_t vs2, void *rs1, int32_t rs2, int32_t imm);

#endif