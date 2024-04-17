#include "network.h"

// CONV1
#define L0_ON    ( 16) // Number of Outputs
#define L0_OY    ( 11) // Output Height
#define L0_OX    ( 11) // Output Width
#define L0_IN    (  1) // Number of Inputs
#define L0_IY    ( 24) // Input Height
#define L0_IX    ( 24) // Input Width
#define L0_WY    (  4) // Weight Height (Kernel Height)
#define L0_WX    (  4) // Weight Width (Kernel Width)
#define L0_SY    (  2) // Input Stride Y
#define L0_SX    (  2) // Input Stride X
#define L0_BIAS  (128) // Bias Value
#define L0_SHIFT (  8) // Output Left Shift

#define L0_IA     ((L0_IN+3)/4)
#define L0_IB     (MIN(4, L0_IN))
#define L0_O_SIZE (L0_ON*L0_OY*L0_OX)
#define L0_I_SIZE (L0_IN*L0_IY*L0_IX)
#define L0_W_SIZE (L0_WX*L0_WY*L0_IA*L0_ON*L0_IB)

// CONV2
#define L1_ON    ( 24) // Number of Outputs
#define L1_OY    (  4) // Output Height
#define L1_OX    (  4) // Output Width
#define L1_IN    ( 16) // Number of Inputs
#define L1_IX    ( 11) // Input Height
#define L1_IY    ( 11) // Input Width
#define L1_WY    (  5) // Weight Height (Kernel Height)
#define L1_WX    (  5) // Weight Width (Kernel Width)
#define L1_SY    (  2) // Input Stride Y
#define L1_SX    (  2) // Input Stride X
#define L1_BIAS  (128) // Bias Value
#define L1_SHIFT (  8) // Output Left Shift

#define L1_IA     ((L1_IN+3)/4)
#define L1_IB     (MIN(4, L1_IN))
#define L1_O_SIZE (L1_ON*L1_OY*L1_OX)
#define L1_I_SIZE (L1_IN*L1_IY*L1_IX)
#define L1_W_SIZE (L1_WX*L1_WY*L1_IA*L1_ON*L1_IB)

// FC1
#define L2_ON    (150) // Number of Outputs
#define L2_OY    (  1) // Output Height
#define L2_OX    (  1) // Output Width
#define L2_IN    (384) // Number of Inputs
#define L2_IX    (  1) // Input Height
#define L2_IY    (  1) // Input Width
#define L2_WY    (  1) // Weight Height (Kernel Height)
#define L2_WX    (  1) // Weight Width (Kernel Width)
#define L2_SY    (  1) // Input Stride Y
#define L2_SX    (  1) // Input Stride X
#define L2_BIAS  (128) // Bias Value
#define L2_SHIFT (  8) // Output Left Shift

#define L2_IA     ((L2_IN+3)/4)
#define L2_IB     (MIN(4, L2_IN))
#define L2_O_SIZE (L2_ON*L2_OY*L2_OX)
#define L2_I_SIZE (L2_IN*L2_IY*L2_IX)
#define L2_W_SIZE (L2_WX*L2_WY*L2_IA*L2_ON*L2_IB)

// FC2
#define L3_ON    (  10) // Number of Outputs
#define L3_OY    (   1) // Output Height
#define L3_OX    (   1) // Output Width
#define L3_IN    ( 150) // Number of Inputs
#define L3_IX    (   1) // Input Height
#define L3_IY    (   1) // Input Width
#define L3_WY    (   1) // Weight Height (Kernel Height)
#define L3_WX    (   1) // Weight Width (Kernel Width)
#define L3_SY    (   1) // Input Stride Y
#define L3_SX    (   1) // Input Stride X
#define L3_BIAS  (1024) // Bias Value
#define L3_SHIFT (  11) // Output Left Shift

#define L3_IA     ((L3_IN+3)/4)
#define L3_IB     (MIN(4, L3_IN))
#define L3_O_SIZE (L3_ON*L3_OY*L3_OX)
#define L3_I_SIZE (L3_IN*L3_IY*L3_IX)
#define L3_W_SIZE (L3_WX*L3_WY*L3_IA*L3_ON*L3_IB)

static uint8_t l0_out[L0_O_SIZE];
static uint8_t l1_out[L1_O_SIZE];
static uint8_t l2_out[L2_O_SIZE];
static uint8_t l3_out[L3_O_SIZE];

static int8_t L0_new[L0_W_SIZE];
static int8_t L1_new[L1_W_SIZE];
static int8_t L2_new[L2_W_SIZE];
static int8_t L3_new[L3_W_SIZE];

#define IDX_O(L, OY, OX, ON) \
    (((OY)*L##_OX + (OX))*L##_ON + (ON))

#define IDX_I(L, IY, IX, IN) \
    (((IY)*L##_IX + (IX))*L##_IN + (IN))

#define IDX_W(L, WY, WX, INA, ON, INB) \
    (((((WY)*L##_WX + (WX))*L##_IA + (INA))*L##_ON + (ON))*L##_IB + (INB))

#ifdef SCALAR_RUN

#define OLD_CONV(L, O, I, W) \
do { \
    for (size_t oy = 0; oy < L##_OY; oy++) { \
        for (size_t ox = 0; ox < L##_OX; ox++) { \
            for (size_t wy = 0; wy < L##_WY; wy++) { \
                size_t iy = L##_SY*oy + wy; \
                for (size_t wx = 0; wx < L##_WX; wx++) { \
                    size_t ix = L##_SX*ox + wx; \
                    for (size_t ina = 0; ina < L##_IA; ina++) { \
                        for (size_t on = 0; on < L##_ON; on++) { \
                            for (size_t inb = 0; inb < L##_IB; inb++) { \
                                size_t in = 4*ina + inb; \
                                if (in < L##_IN) { \
                                    size_t i = IDX_I(L, iy, ix, in); \
                                    size_t w = ((on*L##_WY + wy)*L##_WX + wx)*L##_IN + in; \
                                    size_t n = IDX_W(L, wy, wx, ina, on, inb); \
                                    L##_new[n] = W[w]; \
                                } \
                            } \
                        } \
                    } \
                } \
            } \
        } \
    } \
} while(0)

#define CONV(L, O, I, W) \
do { \
    for (size_t oy = 0; oy < L##_OY; oy++) { \
        for (size_t ox = 0; ox < L##_OX; ox++) { \
            int32_t sum[L##_ON]; \
            for (size_t on = 0; on < L##_ON; on++) { \
                sum[on] = L##_BIAS; \
            } \
            for (size_t wy = 0; wy < L##_WY; wy++) { \
                size_t iy = L##_SY*oy + wy; \
                for (size_t wx = 0; wx < L##_WX; wx++) { \
                    size_t ix = L##_SX*ox + wx; \
                    for (size_t ia = 0; ia < L##_IA; ia++) { \
                        for (size_t on = 0; on < L##_ON; on++) { \
                            for (size_t ib = 0; ib < L##_IB; ib++) { \
                                size_t in = 4*ia + ib; \
                                if (in < L##_IN) { \
                                    size_t i = IDX_I(L, iy, ix, in); \
                                    size_t w = IDX_W(L, wy, wx, ia, on, ib); \
                                    sum[on] += I[i] * W[w]; \
                                } \
                            } \
                        } \
                    } \
                } \
            } \
            for (size_t on = 0; on < L##_ON; on++) { \
                size_t o = IDX_O(L, oy, ox, on); \
                O[o] = (uint8_t) (sum[on] > 0) ? (sum[on] >> L##_SHIFT) : 0; \
            } \
        } \
    } \
} while(0)

#endif

#ifdef MODEL_RUN

#define CONV_LOOP_IN(L, O, I, W, IN_STEP) \
while(in + IN_STEP <= L##_IN) { \
    size_t i = (iy*L##_IX + ix)*L##_IN + in; \
    size_t w = ((on*L##_WY + wy)*L##_WX + wx)*L##_IN + in; \
    vload(input_vu8, (void *) &I[i], IN_STEP); \
    vload(weight_vi8, (void *) &W[w], IN_STEP); \
    vmacc(sum_vi32, weight_vi8, input_vu8, IN_STEP); \
    in += IN_STEP; \
}

#define CONV_LOOP_ON(L, O, I, W, ON_STEP) \
while(on + ON_STEP <= L##_ON) { \
    vbias(sum_vi32, L##_BIAS, ON_STEP); \
    size_t o = (oy*L##_OX + ox)*L##_ON + on; \
    for (size_t wy = 0; wy < L##_WY; wy++) { \
        size_t iy = L##_SY*oy + wy; \
        for (size_t wx = 0; wx < L##_WX; wx++) { \
            size_t ix = L##_SX*ox + wx; \
            size_t in = 0; \
            CONV_LOOP_IN(L, O, I, W, 4); \
            CONV_LOOP_IN(L, O, I, W, 1); \
        } \
    } \
    vactv(sum_vi32, &O[o], L##_SHIFT, ON_STEP); \
    on += ON_STEP; \
}

#define CONV(L, O, I, W) \
do { \
    size_t sum_vi32 = 1; \
    size_t input_vu8 = 2; \
    size_t weight_vi8 = 3; \
    for (size_t oy = 0; oy < L##_OY; oy++) { \
        for (size_t ox = 0; ox < L##_OX; ox++) { \
            size_t on = 0; \
            CONV_LOOP_ON(L, O, I, W, V32LEN); \
            CONV_LOOP_ON(L, O, I, W, 1); \
        } \
    } \
} while(0)

#endif

static void argmax(
    int32_t *arg,
    uint8_t *max,
    const uint8_t *const input,
    const size_t len
)
{
    *arg = 0;
    *max = input[*arg];
    for(size_t i = 1; i < len; i++) {
        if(input[i] > *max) {
            *arg = i;
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

    OLD_CONV(L0, l0_out, input, l0_weight);
    CONV(L0, l0_out, input, L0_new);

    // printf("L0_new\n");
    // hexdump(L0_new, sizeof(L0_new));

#ifdef VALIDATION_RUN
    crc = 0;
    crc32(&crc, l0_out, L0_O_SIZE);
    ASSERT(crc == 0xa6062dba);
#endif

    OLD_CONV(L1, l1_out, l0_out, l1_weight);
    CONV(L1, l1_out, l0_out, L1_new);

    // printf("L1_new\n");
    // hexdump(L1_new, sizeof(L1_new));

#ifdef VALIDATION_RUN
    crc = 0;
    crc32(&crc, l1_out, L1_O_SIZE);
    ASSERT(crc == 0x0aa1524f);
#endif

    OLD_CONV(L2, l2_out, l1_out, l2_weight);
    CONV(L2, l2_out, l1_out, L2_new);

    // printf("L2_new\n");
    // hexdump(L2_new, sizeof(L2_new));

#ifdef VALIDATION_RUN
    crc = 0;
    crc32(&crc, l2_out, L2_O_SIZE);
    ASSERT(crc == 0x7e1d772e);
#endif

    OLD_CONV(L3, l3_out, l2_out, l3_weight);
    CONV(L3, l3_out, l2_out, L3_new);

    // printf("L3_new\n");
    // hexdump(L3_new, sizeof(L3_new));

#ifdef VALIDATION_RUN
    crc = 0;
    crc32(&crc, l3_out, L3_O_SIZE);
    ASSERT(crc == 0x6d779679);
#endif

    argmax(output, credence, l3_out, L3_O_SIZE);

#ifdef VALIDATION_RUN
    crc = 0;
    crc32(&crc, output, 1);
    ASSERT(crc == 0xd56f2b94);
#endif

}
