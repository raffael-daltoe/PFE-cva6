#pragma once

#include <stdlib.h>
#include <stdio.h>

#include "misc.h"
#include "perf.h"
#include "resources.h"
#include "xadac.h"

void inference(const uint8_t* input, int32_t* output, uint8_t* credence);
