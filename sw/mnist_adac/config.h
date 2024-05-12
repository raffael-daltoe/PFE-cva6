#pragma once

#define GLOBAL_PERF
// #define LAYER_PERF
// #define ADAC_HPM
// #define DUMP
// #define VALIDATE
// #define VECTOR
// #define MODEL
#define VECTOR_ASM

#ifndef IMAGE
    #define IMAGE img0003
#endif

#if defined(GLOBAL_PERF) && defined(LAYER_PERF)
    #error "Conflict: GLOBAL_PERF and LAYER_PERF."
#endif

#if defined(VECTOR) && defined(VECTOR_ASM)
    #error "Conflict: VECTOR and VECTOR_ASM."
#endif