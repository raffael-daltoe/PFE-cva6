#pragma once

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include "config.h"

#define STR_(x) #x
#define STR(x) STR_(x)

#define MIN(x, y) (((x) <= (y)) ? (x) : (y))
#define MAX(x, y) (((x) >= (y)) ? (x) : (y))

// config =====================================================================

#define TAG STR([IMAGE]) " "

// assert =====================================================================

#define ASSERT(condition) \
do { \
    if (!(condition)) { \
        printf(TAG "Assertion failed: %s:%d\n", \
            __FILE__, __LINE__); \
    } \
} while (0)

// csr ========================================================================

#define CSR_READ(reg) \
(__extension__({ \
    unsigned long __tmp; \
    asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
    __tmp; \
}))

#define CSR_WRITE(reg, val) \
(__extension__({ \
    asm volatile ("csrw " #reg ", %0" :: "rK"(val)); \
}))

#define CSR_SWAP(reg, val) \
(__extension__({ \
    unsigned long __tmp; \
    asm volatile ("csrrw %0, " #reg ", %1" : "=r"(__tmp) : "rK"(val)); \
  __tmp; \
}))

#define CSR_SET(reg, bit) \
(__extension__({ \
    unsigned long __tmp; \
    asm volatile ("csrrs %0, " #reg ", %1" : "=r"(__tmp) : "rK"(bit)); \
    __tmp; \
}))

#define CSR_CLEAR(reg, bit) \
(__extension__({ \
    unsigned long __tmp; \
    asm volatile ("csrrc %0, " #reg ", %1" : "=r"(__tmp) : "rK"(bit)); \
    __tmp; \
}))

// crc32 ======================================================================

#define CRC32_POLY (0xEDB88320)

void crc32_table_init(void);
void crc32(uint32_t *crc, const void *buf, size_t len);

// hexdump ====================================================================

void hexdump(const void *buf, size_t len);

// decode_img =================================================================

void decode_img(const void *buf, void **image, int32_t *label);