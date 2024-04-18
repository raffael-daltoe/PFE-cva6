#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "network.h"
#include "perf.h"
#include "resources.h"

int main()
{
    print_config();

    uint8_t *input;
    int32_t expected;
    decode_img(IMAGE, (void **) &input, &expected);

#ifdef GLOBAL_PERF
    perf_tic();
#endif

    int32_t output;
    uint8_t credence;
    inference(input, &output, &credence);

#ifdef GLOBAL_PERF
    perf_toc();
#endif

    printf("expected: %ld\n", expected);
    printf("output: %ld\n", output);
    printf("credence: %d\n", credence);
    printf("end\n");
}
