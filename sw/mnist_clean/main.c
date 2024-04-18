#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "network.h"
#include "perf.h"
#include "resources.h"

int main() {

#ifdef VALIDATE
    printf(TAG "Validation Run\n");
#endif

    uint8_t *input;
    int32_t expected;
    decode_img(img0003, (void **) &input, &expected);

#ifdef GLOBAL_PERF
    perf_tic();
#endif

    int32_t output;
    uint8_t credence;
    inference(input, &output, &credence);

#ifdef GLOBAL_PERF
    perf_toc();
#endif

    printf(TAG "expected: %ld\n", expected);
    printf(TAG "output: %ld\n", output);
    printf(TAG "credence: %d\n", credence);
}
