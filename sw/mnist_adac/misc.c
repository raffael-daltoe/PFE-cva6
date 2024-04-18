#include "misc.h"

// config =====================================================================

void print_config(void)
{
    printf("Current Configuration:\n");
    printf("   IMAGE = " STR(IMAGE) "\n");
#ifdef GLOBAL_PERF
    printf("   GLOBAL_PERF\n");
#endif
#ifdef LAYER_PERF
    printf("   LAYER_PERF\n");
#endif
#ifdef ADAC_HPM
    printf("   ADAC_HPM\n");
#endif
#ifdef VALIDATE
    printf("   VALIDATE\n");
#endif
#ifdef VECTOR
    printf("   VECTOR\n");
#endif
#ifdef MODEL
    printf("   MODEL\n");
#endif
    printf("\n");
}

// crc32 ======================================================================

static uint32_t crc32_table[256];

void crc32_table_init(void)
{
    for(size_t i = 0; i < 256; i++) {
        uint32_t ch = i;
        uint32_t crc = 0;

        for(size_t j = 0; j < 8; j++) {
            uint32_t b = (ch ^ crc) & 1;
            crc >>= 1;
            if(b) crc = crc ^ CRC32_POLY;
            ch >>= 1;
        }

        crc32_table[i] = crc;
    }
}

void crc32(uint32_t *crc, const void *buf, size_t len)
{
    (*crc) = ~(*crc);

    uint8_t *u8_ptr = (uint8_t *) buf;

    while(len--) {
        uint32_t t = (*(u8_ptr++) ^ *crc) & 0xFF;
        *crc = (*crc >> 8) ^ crc32_table[t];
    }

    (*crc) = ~(*crc);
}

// hexdump ====================================================================

void hexdump(const void *buf, size_t len) {
    const uint8_t *ptr = (const uint8_t *) buf;

    for (size_t i = 0; i < len; i += 4) {
        uint32_t word = 0;

        // Construct the 32-bit word from individual bytes
        for (size_t j = 0; j < 4; j++) {
            if (i + j < len) {
                word |= (uint32_t) ptr[i + j] << (8 * j);
            } else {
                // Handle incomplete words (less than 4 bytes)
                word |= (uint32_t) 0xFF << (8 * j);
            }
        }

        printf("0x%08lx, ", word);
        if ((i + 4) % 16 == 0) {
            printf("\n");
        }
    }
    printf("\n");
}

// decode_img =================================================================

// The buffer contains a 24x24 PGM image followed by its label.

void decode_img(const void *buf, void **image, int32_t *label)
{
    uint8_t *ptr = (uint8_t *) buf;

    *image = (void *) (ptr += 13);
    *label = *(uint8_t *) (ptr += 24*24);
}