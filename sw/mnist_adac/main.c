#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "cpp_utils.h"
#include "env.h"
#include "Network.h"
//#include "util.h"
#include "perf.h"

inline int xadac_max(int rs1, int rs2)
{
    int rd;

    asm volatile (
        "xadac.max %[rd], %[rs1], %[rs2]\n\t"
        : [rd] "=r" (rd)
        : [rs1] "r" (rs1), [rs2] "r" (rs2)
    );

    return rd;
}

void experiments(void)
{
    printf("experiments begin\n");

    for (int a = 0; a <= 5; a++) {
        for (int b = 0; b <= 5; b++) {
            int res = xadac_max(a, b);
            printf("xadac_max(%d, %d) -> %d\n", a, b, res);
        }
    }

    printf("experiments end\n");
}
void readStimulus(
                  UDATA_T* inputBuffer,
                  Target_T* expectedOutputBuffer)
{
    envRead(ENV_SIZE_Y*ENV_SIZE_X*ENV_NB_OUTPUTS,
            ENV_SIZE_Y, ENV_SIZE_X,
            (DATA_T*) inputBuffer, //TODO
            OUTPUTS_SIZE[0], expectedOutputBuffer);
}

int processInput(        UDATA_T* inputBuffer,
                            Target_T* expectedOutputBuffer,
                            Target_T* predictedOutputBuffer,
			    UDATA_T* output_value)
{
    size_t nbPredictions = 0;
    size_t nbValidPredictions = 0;

    propagate(inputBuffer, predictedOutputBuffer, output_value);

    // assert(expectedOutputBuffer.size() == predictedOutputBuffer.size());
    for(size_t i = 0; i < OUTPUTS_SIZE[0]; i++) {
        if (expectedOutputBuffer[i] >= 0) {
            ++nbPredictions;

            if(predictedOutputBuffer[i] == expectedOutputBuffer[i]) {
                ++nbValidPredictions;
            }
        }
    }

    return (nbPredictions > 0)
        ? nbValidPredictions : 0;
}


int main(int argc, char* argv[]) {

    // const N2D2::Network network{};
    size_t instret, cycles;
    
#if ENV_DATA_UNSIGNED
    UDATA_T inputBuffer[ENV_SIZE_Y*ENV_SIZE_X*ENV_NB_OUTPUTS];
#else
    std::vector<DATA_T> inputBuffer(network.inputSize());
#endif

    Target_T expectedOutputBuffer[OUTPUTS_SIZE[0]];
    Target_T predictedOutputBuffer[OUTPUTS_SIZE[0]];
    UDATA_T output_value;

    readStimulus(inputBuffer, expectedOutputBuffer);

    perf_init();
    perf_tic();

    instret = -read_csr(minstret);
    cycles = -read_csr(mcycle);

    const int success = processInput(inputBuffer, expectedOutputBuffer,
        predictedOutputBuffer, &output_value);
    
    instret += read_csr(minstret);
    cycles += read_csr(mcycle);

    perf_toc();

    //experiments();

    printf("Expected  = %d\n", expectedOutputBuffer[0]);
    printf("Predicted = %d\n", predictedOutputBuffer[0]);
    printf("Result : %d/1\n", success);
    printf("credence: %d\n", output_value);
    //printf("image %s: %d instructions\n", stringify(MNIST_INPUT_IMAGE), (int)(instret));
    //printf("image %s: %d cycles\n", stringify(MNIST_INPUT_IMAGE), (int)(cycles));
    
    printf("\n\n\n");

#ifdef OUTPUTFILE
    FILE *f = fopen("success_rate.txt", "w");
    if (f == NULL) {
        N2D2_THROW_OR_ABORT(std::runtime_error,
            "Could not create file:  success_rate.txt");
    }
    fprintf(f, "%f", successRate);
    fclose(f);
#endif
}