#pragma once

// #define GLOBAL_PERF
// #define LAYER_PERF
#define ADAC_HPM
#define VALIDATE
#define VECTOR
#define MODEL

#ifndef IMAGE
    #define IMAGE img0003
#endif

#if defined(GLOBAL_PERF) && defined(LAYER_PERF)
    #error "Conflict: GLOBAL_PERF and LAYER_PERF."
#endif