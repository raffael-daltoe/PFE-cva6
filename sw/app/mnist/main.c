#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "cpp_utils.h"
#include "env.h"
#include "Network.h"
#include "util.h"

int max_instr(int rs1, int rs2)
{
    int rd;

    asm (
        "mv x10, %1\n\t"           // Move input1 to x10
        "mv x11, %2\n\t"           // Move input2 to x11
        //"add x12, x10, x11\n\t"  // Perform addition: x12 = x10 + x11
        ".word 0x00b5062b\n\t"
        "mv %0, x12\n\t"           // Move the result from x12 to result
        : "=r" (rd)                // Output operand
        : "r" (rs1), "r" (rs2)     // Input operands
        : "x10", "x11", "x12"      // Clobbered registers
    );

    return rd;
}

void experiments(void)
{
    printf("experiments begin\n");

    for (int a = 0; a <= 5; a++) {
        for (int b = 0; b <= 5; b++) {
            int res = max_instr(a, b);
            printf("max(%d, %d) -> %d\n", a, b, res);
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
    instret = -read_csr(minstret);
    cycles = -read_csr(mcycle);
    const int success = processInput(inputBuffer, 
                                                        expectedOutputBuffer, 
                                                        predictedOutputBuffer,
							&output_value);
    instret += read_csr(minstret);
    cycles += read_csr(mcycle);
    
    experiments();

    printf("Expected  = %d\n", expectedOutputBuffer[0]);
    printf("Predicted = %d\n", predictedOutputBuffer[0]);
    printf("Result : %d/1\n", success);
    printf("credence: %d\n", output_value);
    printf("image %s: %d instructions\n", stringify(MNIST_INPUT_IMAGE), (int)(instret));
    printf("image %s: %d cycles\n", stringify(MNIST_INPUT_IMAGE), (int)(cycles));

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