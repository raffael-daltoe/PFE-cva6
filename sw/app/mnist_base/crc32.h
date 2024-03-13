#pragma once 

#include <stdint.h>
#include <stdlib.h>

#define CRC32_POLY (0xEDB88320)

void crc32_table_init(void);
void crc32(uint32_t *crc, const void *buf, size_t len);