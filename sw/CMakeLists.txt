cmake_minimum_required(VERSION 3.10)

project(sw C ASM)

set(CMAKE_SYSTEM_NAME      Generic)
set(CMAKE_SYSTEM_PROCESSOR riscv32)

set(GCC_PREFIX riscv32-unknown-elf)

set(CMAKE_C_COMPILER   ${GCC_PREFIX}-gcc)
set(CMAKE_CXX_COMPILER ${GCC_PREFIX}-g++)
set(CMAKE_ASM_COMPILER ${GCC_PREFIX}-gcc)
set(CMAKE_OBJCOPY      ${GCC_PREFIX}-objcopy)
set(CMAKE_OBJDUMP      ${GCC_PREFIX}-objdump)

set(CMAKE_PK /opt/riscv/${GCC_PREFIX}/bin/pk)

set(CMAKE_BIN2MEM ${PROJECT_SOURCE_DIR}/../util/bin2mem.py)
set(CMAKE_MEM2COE ${PROJECT_SOURCE_DIR}/../util/mem2coe.py)

set(COMMON_FLAGS "-g -O3 -static \
    -march=rv32im_zicsr_xadac1 -mabi=ilp32 -mcmodel=medany \
    -fvisibility=hidden -ffunction-sections -fdata-sections")
set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS}   ${COMMON_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAGS}")
set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} ${COMMON_FLAGS}")

set(CVA6_LINK_SCRIPT "${CMAKE_SOURCE_DIR}/cva6/link.ld")
include_directories(${PROJECT_SOURCE_DIR}/cva6)
file(GLOB_RECURSE CVA6_SOURCES
    "${PROJECT_SOURCE_DIR}/cva6/*.S"
    "${PROJECT_SOURCE_DIR}/cva6/*.c")
add_library(cva6 STATIC ${CVA6_SOURCES})
target_compile_options(cva6 PRIVATE -DPREALLOCATE=1 -DSTDIO_THRU_UART -w)

function(add_benchmark NAME)
    file(GLOB_RECURSE BM_SOURCES "${PROJECT_SOURCE_DIR}/${NAME}/*.c")

    add_executable(${NAME} ${BM_SOURCES})
    target_link_libraries(${NAME} cva6)
    target_compile_options(${NAME} PRIVATE -Wall -pedantic)
    set_target_properties(${NAME} PROPERTIES LINK_FLAGS
        "-static -nostartfiles -T ${CVA6_LINK_SCRIPT} \
        -Wl,-gc-sections,-u,_start,-Map=${NAME}.map")
    add_custom_command(TARGET ${NAME} POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -D $<TARGET_FILE:${NAME}> > ${NAME}.dump
        COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${NAME}> ${NAME}.bin
        COMMAND ${CMAKE_BIN2MEM} ${NAME}.bin
        COMMAND ${CMAKE_MEM2COE} ${NAME}.mem)

    add_executable(${NAME}_pk ${BM_SOURCES})
    target_compile_options(${NAME}_pk PRIVATE -Wall -pedantic)
    set_target_properties(${NAME}_pk PROPERTIES LINK_FLAGS
        "-Wl,-gc-sections,-u,main,-Map=${NAME}_pk.map")
    add_custom_command(TARGET ${NAME}_pk POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -D $<TARGET_FILE:${NAME}_pk> > ${NAME}_pk.dump)

    add_custom_target(${NAME}_spike
        COMMAND spike ${CMAKE_PK} $<TARGET_FILE:${NAME}_pk>
        DEPENDS ${NAME}_pk
        COMMENT "Running ${NAME} on Spike")
endfunction()

add_benchmark(mnist)
add_benchmark(mnist_adac)
add_benchmark(mnist_base)
add_benchmark(mnist_clean)

set(GITIGNORE_FILE "${CMAKE_BINARY_DIR}/.gitignore")
if(NOT EXISTS "${GITIGNORE_FILE}")
    file(WRITE "${GITIGNORE_FILE}" "*\n")
endif()
