#include "crc32.h"

uint32_t crc32_table[256];

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