# Copyright (c) 2023 Thales.
#
# Copyright and related rights are licensed under the Apache
# License, Version 2.0 (the "License"); you may not use this file except in
# compliance with the License.  You may obtain a copy of the License at
# https://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable law
# or agreed to in writing, software, hardware and materials distributed under
# this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#
# Author:         Sebastien Jacq - sjthales on github.com
#
# Additional contributions by:
#
#
# script Name:    Dockerfile
# Project Name:   cva6-softcore-contest
# Language:
#
# Description:    This dokerfile aims at building a container image including
#                 RISCV GCC13.1.0 and OpenOCD
#
# =========================================================================== #
# Revisions  :
# Date        Version  Author       Description
# 2023-11-22  0.1      S.Jacq       Created
# =========================================================================== #

FROM ubuntu:20.04

ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive

# Install base packages
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get install --no-install-recommends -y \
    ca-certificates \
    autoconf \
    automake \
    autotools-dev \
    bc \
    build-essential \
    bison \
    ccache \
    cmake \
    curl \
    device-tree-compiler \
    gawk \
    gcc \
    git \
    gperf \
    g++ \
    flex \
    help2man \
    libfl-dev \
    libfl2 \
    libftdi1-dev \
    libgmp-dev \
    libmpc-dev \
    libmpfr-dev \
    libgoogle-perftools-dev \
    libtool \
    libusb-1.0-0-dev \
    locales \
    make \
    net-tools \
    ninja-build \
    numactl \
    openssh-client \
    perl-doc \
    perl \
    pkg-config \
    python3-dev \
    python3-pip \
    python3-ply \
    python3-setuptools \
    python-is-python3 \
    python3 \
    srecord \
    sudo \
    texinfo \
    udev \
    zlibc \
    zlib1g-dev \
    zlib1g

RUN git clone https://github.com/verilator/verilator && \
    cd verilator && \
    git checkout v5.024 && \
    autoconf && \
    ./configure && \
    make -j$(nproc) && \
    make install

RUN mkdir -p /opt/riscv/bin
ENV RISCV="/opt/riscv"
ENV PATH="$PATH:$RISCV/bin"

# Install OpenOCD
RUN git clone https://github.com/openocd-org/openocd && \
    cd openocd && \
    git checkout v0.11.0 && \
    mkdir build && \
    ./bootstrap && \
    ./configure --enable-ftdi --prefix=$RISCV --exec-prefix=$RISCV  && \
    make && \
    make install

# Install rule for udev to access HS2 cable
RUN echo "ATTRS{idVendor}==\"0403\", ATTRS{idProduct}==\"6014\", MODE=\"660\", GROUP=\"plugdev\", TAG+=\"uaccess\"" > /etc/udev/rules.d/60-openocd.rules

# Install toolchain
COPY ./util/gcc-toolchain-builder /gcc-toolchain-builder
RUN cd gcc-toolchain-builder && \
    ls -al && \
    bash ./get-toolchain.sh && \
    bash ./build-toolchain.sh $RISCV && \
    cd .. && rm -rf gcc-toolchain-builder

# Install Spike
RUN git clone https://github.com/riscv/riscv-isa-sim.git && \
    cd riscv-isa-sim && \
    git checkout 530af85d83781a3dae31a4ace84a573ec255fefa && \
    mkdir build/ && cd build/ && \
    ../configure --prefix=/opt/riscv \
        --enable-histogram \
        --with-isa=rv32gcv \
    && make -j$(nproc) && \
    make install && \
    cd ../.. && rm -rf riscv-isa-sim

# Install RISC-V pk
RUN git clone https://github.com/riscv-software-src/riscv-pk.git && \
    cd riscv-pk && \
    git checkout fafaedd2825054222ce2874bf4a90164b5b071d4 && \
    mkdir build/ && cd build/ && \
    ../configure --prefix=/opt/riscv \
        --host=riscv32-unknown-elf \
        --with-arch=rv32gcv \
    && make -j$(nproc) && \
    make install && \
    cd ../.. && rm -rf riscv-pk

RUN mkdir /workdir
WORKDIR /workdir

# Create user
RUN groupadd -g $GID -o user && \
    useradd -u $UID -m -g user -G plugdev user && \
    echo 'user ALL = NOPASSWD: ALL' > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user

USER user