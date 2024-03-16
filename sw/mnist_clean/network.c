#include "network.h"

#define CONV1_ON   ( 16) // Number of Outputs               
#define CONV1_OY   ( 11) // Output Height
#define CONV1_OX   ( 11) // Output Width
#define CONV1_IN   (  1) // Number of Inputs
#define CONV1_IY   ( 24) // Input Height
#define CONV1_IX   ( 24) // Input Width
#define CONV1_WY   (  4) // Weight Height (Kernel Height)
#define CONV1_WX   (  4) // Weight Width (Kernel Width)
#define CONV1_SY   (  2) // Input Stride Y
#define CONV1_SX   (  2) // Input Stride X
#define CONV1_BIAS (128) // Bias Value

#define CONV1_O_SIZE (CONV1_ON*CONV1_OY*CONV1_OX)
#define CONV1_I_SIZE (CONV1_IN*CONV1_IY*CONV1_IX)
#define CONV1_W_SIZE (CONV1_ON*CONV1_WX*CONV1_WY*CONV1_IN)

#define CONV2_ON   ( 24) // Number of Outputs               
#define CONV2_OY   (  4) // Output Height
#define CONV2_OX   (  4) // Output Width
#define CONV2_IN   ( 16) // Number of Inputs
#define CONV2_IX   ( 11) // Input Height
#define CONV2_IY   ( 11) // Input Width
#define CONV2_WY   (  5) // Weight Height (Kernel Height)
#define CONV2_WX   (  5) // Weight Width (Kernel Width)
#define CONV2_SY   (  2) // Input Stride Y
#define CONV2_SX   (  2) // Input Stride X
#define CONV2_BIAS (128) // Bias Value

#define CONV2_O_SIZE (CONV2_ON*CONV2_OY*CONV2_OX)
#define CONV2_I_SIZE (CONV2_IN*CONV2_IY*CONV2_IX)
#define CONV2_W_SIZE (CONV2_ON*CONV2_WX*CONV2_WY*CONV2_IN)

#define FC1_O    (150) // Number of Outputs
#define FC1_I    (384) // Number of Inputs
#define FC1_BIAS (128) // Bias Value

#define FC2_O    (  10) // Number of Outputs
#define FC2_I    ( 150) // Number of Inputs
#define FC2_BIAS (1024) // Bias Value

static uint8_t conv1_output[CONV1_O_SIZE];
static uint8_t conv2_output[CONV2_O_SIZE];
static uint8_t fc1_output[FC1_O];
static uint8_t fc2_output[FC2_O];

static void conv1(
    const uint8_t *input,
          uint8_t *output,
    const int8_t  *weight
)
{
    for (size_t oy = 0; oy < CONV1_OX; oy++) {
        for (size_t ox = 0; ox < CONV1_OY; ox++) {
            for (size_t on = 0; on < CONV1_ON; on++) {
                
                size_t o = (oy*CONV1_OX + ox)*CONV1_ON + on;
                
                int32_t sum = CONV1_BIAS;

                for (size_t wy = 0; wy < CONV1_WY; wy++) {
                    for (size_t wx = 0; wx < CONV1_WX; wx++) {
                        for (size_t in = 0; in < CONV1_IN; in++) {
                            size_t iy = CONV1_SY*oy + wy;
                            size_t ix = CONV1_SX*ox + wx;
                            
                            size_t i = (iy*CONV1_IX + ix)*CONV1_IN + in;
                            size_t w = ((on*CONV1_WY + wy)*CONV1_WX + wx)*CONV1_IN + in;
        
                            sum += input[i] * weight[w];
                        }
                    }
                }

                // activation
                if (sum > 0) {
                    output[o] = (sum >> 8) & 0xFF;
                } else {
                    output[o] = 0;
                }
            }
        }
    }
}

static void conv2(
    const uint8_t *input,
          uint8_t *output,
    const int8_t  *weight
)
{
    for (size_t oy = 0; oy < CONV2_OX; oy++) {
        for (size_t ox = 0; ox < CONV2_OY; ox++) {
            for (size_t on = 0; on < CONV2_ON; on++) {
                
                size_t o = (oy*CONV2_OX + ox)*CONV2_ON + on;
                
                int32_t sum = CONV2_BIAS;

                for (size_t wy = 0; wy < CONV2_WY; wy++) {
                    for (size_t wx = 0; wx < CONV2_WX; wx++) {
                        for (size_t in = 0; in < CONV2_IN; in++) {
                            size_t iy = CONV2_SY*oy + wy;
                            size_t ix = CONV2_SX*ox + wx;
                            
                            size_t i = (iy*CONV2_IX + ix)*CONV2_IN + in;
                            size_t w = ((on*CONV2_WY + wy)*CONV2_WX + wx)*CONV2_IN + in;
        
                            sum += input[i] * weight[w];
                        }
                    }
                }

                // activation
                if (sum > 0) {
                    output[o] = (sum >> 8) & 0xFF;
                } else {
                    output[o] = 0;
                }
            }
        }
    }
}

static void fc1(
    const uint8_t *input,
          uint8_t *output,
    const int8_t  *weight
)
{
    for (size_t o = 0; o < FC1_O; o++) {
        int32_t sum = FC1_BIAS;

        for (size_t i = 0; i < FC1_I; i++) {
            size_t w = o*FC1_I + i;
            sum += input[i] * weight[w];
        }

        // activation
        if (sum > 0) {
            output[o] = (sum >> 8) & 0xFF;
        } else {
            output[o] = 0;
        }
    }    
}

static void fc2(
    const uint8_t *input,
          uint8_t *output,
    const int8_t  *weight
)
{
    for (size_t o = 0; o < FC2_O; o++) {
        int32_t sum = FC2_BIAS;

        for (size_t i = 0; i < FC2_I; i++) {
            size_t w = o*FC2_I + i;
            sum += input[i] * weight[w];
        }

        // activation
        sum = (sum >> 11);
        if (sum < 0) {
            output[o] =  0;
        } else if (sum > 255) { // 2047
            output[o] = 255; // 2047
        } else {
            output[o] = sum;
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

    for(size_t i = 1; i < FC2_O; i++) {
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
    crc32(&crc, input, 576);
    ASSERT(crc == 0x4dfde263);
#endif

    conv1(input, conv1_output, conv1_weight);

#ifdef VALIDATION_RUN
    crc = 0;
    crc32(&crc, conv1_output, CONV1_O_SIZE);
    ASSERT(crc == 0xa6062dba);
#endif

    conv2(conv1_output, conv2_output, conv2_weight);

#ifdef VALIDATION_RUN    
    crc = 0;
    crc32(&crc, conv2_output, CONV2_O_SIZE);
    ASSERT(crc == 0x0aa1524f);
#endif

    fc1(conv2_output, fc1_output, fc1_weight);

#ifdef VALIDATION_RUN 
    crc = 0;
    crc32(&crc, fc1_output, FC1_O);
    ASSERT(crc == 0x7e1d772e);
#endif

    fc2(fc1_output, fc2_output, fc2_weight);

#ifdef VALIDATION_RUN
    crc = 0;
    crc32(&crc, fc2_output, FC2_O);
    ASSERT(crc == 0x6d779679);
#endif

    argmax1(fc2_output, output, credence);

#ifdef VALIDATION_RUN
    crc = 0;
    crc32(&crc, output, 1);
    ASSERT(crc == 0xd56f2b94);
#endif

}





