#include "network.h"

// CONV1
#define L0_LON   ( 16) // Number of Outputs
#define L0_LOY   ( 11) // Output Height
#define L0_LOX   ( 11) // Output Width
#define L0_LIN   (  1) // Number of Inputs
#define L0_LIY   ( 24) // Input Height
#define L0_LIX   ( 24) // Input Width
#define L0_LWY   (  4) // Weight Height (Kernel Height)
#define L0_LWX   (  4) // Weight Width (Kernel Width)
#define L0_SY    (  2) // Input Stride Y
#define L0_SX    (  2) // Input Stride X
#define L0_BIAS  (128) // Bias Value
#define L0_SHIFT (  8) // Output Left Shift

#define L0_O_SIZE (L0_LON*L0_LOY*L0_LOX)
#define L0_I_SIZE (L0_LIN*L0_LIY*L0_LIX)
#define L0_W_SIZE (L0_LON*L0_LWX*L0_LWY*L0_LIN)

// CONV2
#define L1_LON   ( 24) // Number of Outputs
#define L1_LOY   (  4) // Output Height
#define L1_LOX   (  4) // Output Width
#define L1_LIN   ( 16) // Number of Inputs
#define L1_LIX   ( 11) // Input Height
#define L1_LIY   ( 11) // Input Width
#define L1_LWY   (  5) // Weight Height (Kernel Height)
#define L1_LWX   (  5) // Weight Width (Kernel Width)
#define L1_SY    (  2) // Input Stride Y
#define L1_SX    (  2) // Input Stride X
#define L1_BIAS  (128) // Bias Value
#define L1_SHIFT (  8) // Output Left Shift

#define L1_O_SIZE (L1_LON*L1_LOY*L1_LOX)
#define L1_I_SIZE (L1_LIN*L1_LIY*L1_LIX)
#define L1_W_SIZE (L1_LON*L1_LWX*L1_LWY*L1_LIN)

// FC1
#define L2_LON   (150) // Number of Outputs
#define L2_LOY   (  1) // Output Height
#define L2_LOX   (  1) // Output Width
#define L2_LIN   (384) // Number of Inputs
#define L2_LIX   (  1) // Input Height
#define L2_LIY   (  1) // Input Width
#define L2_LWY   (  1) // Weight Height (Kernel Height)
#define L2_LWX   (  1) // Weight Width (Kernel Width)
#define L2_SY    (  1) // Input Stride Y
#define L2_SX    (  1) // Input Stride X
#define L2_BIAS  (128) // Bias Value
#define L2_SHIFT (  8) // Output Left Shift

#define L2_O_SIZE (L2_LON*L2_LOY*L2_LOX)
#define L2_I_SIZE (L2_LIN*L2_LIY*L2_LIX)
#define L2_W_SIZE (L2_LON*L2_LWX*L2_LWY*L2_LIN)

// FC2
#define L3_LON   (  10) // Number of Outputs
#define L3_LOY   (   1) // Output Height
#define L3_LOX   (   1) // Output Width
#define L3_LIN   ( 150) // Number of Inputs
#define L3_LIX   (   1) // Input Height
#define L3_LIY   (   1) // Input Width
#define L3_LWY   (   1) // Weight Height (Kernel Height)
#define L3_LWX   (   1) // Weight Width (Kernel Width)
#define L3_SY    (   1) // Input Stride Y
#define L3_SX    (   1) // Input Stride X
#define L3_BIAS  (1024) // Bias Value
#define L3_SHIFT (  11) // Output Left Shift

#define L3_O_SIZE (L3_LON*L3_LOY*L3_LOX)
#define L3_I_SIZE (L3_LIN*L3_LIY*L3_LIX)
#define L3_W_SIZE (L3_LON*L3_LWX*L3_LWY*L3_LIN)

static uint8_t l0_out[L0_O_SIZE];
static uint8_t l1_out[L1_O_SIZE];
static uint8_t l2_out[L2_O_SIZE];
static uint8_t l3_out[L3_O_SIZE];

static inline void conv(
    uint8_t *const output,
    const uint8_t *const input,
    const int8_t *const weight,
    const size_t lon,
    const size_t loy,
    const size_t lox,
    const size_t lin,
    const size_t liy,
    const size_t lix,
    const size_t lwy,
    const size_t lwx,
    const size_t sx,
    const size_t sy,
    const int32_t bias,
    const size_t shift
)
{
    for (size_t oy = 0; oy < loy; oy++) {
        for (size_t ox = 0; ox < lox; ox++) {
            for (size_t on = 0; on < lon; on++) {
                size_t o = (oy*lox + ox)*lon + on;
                int32_t sum = bias;
                for (size_t wy = 0; wy < lwy; wy++) {
                    for (size_t wx = 0; wx < lwx; wx++) {
                        for (size_t in = 0; in < lin; in++) {
                            size_t iy = sy*oy + wy;
                            size_t ix = sy*ox + wx;
                            size_t i = (iy*lix + ix)*lin + in;
                            size_t w = ((on*lwy + wy)*lwx + wx)*lin + in;
                            sum += input[i] * weight[w];
                        }
                    }
                }

                // activation
                sum = (sum > 0) ? sum : 0;
                sum >>= shift;
                output[o] = (uint8_t) sum;
            }
        }
    }
}

static void argmax1(
    const uint8_t *input,
          int32_t *output,
          uint8_t *max
)
{
    *output = 0;
    *max = input[*output];

    for(size_t i = 1; i < L3_O_SIZE; i++) {
        if(input[i] > *max) {
            *output = i;
            *max = input[i];
        }
    }
}

void inference(const uint8_t* input, int32_t* output, uint8_t* credence)
{

#ifdef VALIDATION_RUN
    uint32_t crc;
    crc32_table_init();

    crc = 0;
    crc32(&crc, input, L0_I_SIZE);
    ASSERT(crc == 0x4dfde263);
#endif

    conv(
        l0_out,
        input,
        conv1_weight,
        L0_LON,
        L0_LOY,
        L0_LOX,
        L0_LIN,
        L0_LIY,
        L0_LIX,
        L0_LWY,
        L0_LWX,
        L0_SX,
        L0_SY,
        L0_BIAS,
        L0_SHIFT
    );

#ifdef VALIDATION_RUN
    crc = 0;
    crc32(&crc, l0_out, L0_O_SIZE);
    ASSERT(crc == 0xa6062dba);
#endif

    conv(
        l1_out,
        l0_out,
        conv2_weight,
        L1_LON,
        L1_LOY,
        L1_LOX,
        L1_LIN,
        L1_LIY,
        L1_LIX,
        L1_LWY,
        L1_LWX,
        L1_SX,
        L1_SY,
        L1_BIAS,
        L1_SHIFT
    );

#ifdef VALIDATION_RUN
    crc = 0;
    crc32(&crc, l1_out, L1_O_SIZE);
    ASSERT(crc == 0x0aa1524f);
#endif

    conv(
        l2_out,
        l1_out,
        fc1_weight,
        L2_LON,
        L2_LOY,
        L2_LOX,
        L2_LIN,
        L2_LIY,
        L2_LIX,
        L2_LWY,
        L2_LWX,
        L2_SX,
        L2_SY,
        L2_BIAS,
        L2_SHIFT
    );

#ifdef VALIDATION_RUN
    crc = 0;
    crc32(&crc, l2_out, L2_O_SIZE);
    ASSERT(crc == 0x7e1d772e);
#endif

    conv(
        l3_out,
        l2_out,
        fc2_weight,
        L3_LON,
        L3_LOY,
        L3_LOX,
        L3_LIN,
        L3_LIY,
        L3_LIX,
        L3_LWY,
        L3_LWX,
        L3_SX,
        L3_SY,
        L3_BIAS,
        L3_SHIFT
    );

#ifdef VALIDATION_RUN
    crc = 0;
    crc32(&crc, l3_out, L3_O_SIZE);
    ASSERT(crc == 0x6d779679);
#endif

    argmax1(l3_out, output, credence);

#ifdef VALIDATION_RUN
    crc = 0;
    crc32(&crc, output, 1);
    ASSERT(crc == 0xd56f2b94);
#endif

}
