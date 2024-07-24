FROM ubuntu:24.04

# Install dependencies

RUN apt-get update && apt-get -y install python3 python3-pip git autoconf \
    automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev \ 
    gawk build-essential bison flex texinfo gperf libtool patchutils bc \ 
    zlib1g-dev libexpat-dev opam  build-essential libgmp-dev z3 pkg-config zlib1g-dev \
    gcc-riscv64-linux-gnu

RUN pip install git+https://github.com/riscv/riscof.git --break-system-packages

RUN git clone --recursive https://github.com/riscv/riscv-gnu-toolchain && \
    cd riscv-gnu-toolchain && \
    ./configure --prefix=/opt/riscv/ --with-arch=rv64ima --with-abi=lp64 && \ 
    make -j$(nproc) && \
    rm -rf /riscv-gnu-toolchain
    
RUN git clone --recursive https://github.com/riscv/riscv-opcodes.git && \
    git clone https://github.com/riscv/sail-riscv.git && \
    opam init -y --disable-sandboxing && \
    opam switch create 5.1.0 && \
    opam install sail -y && \
    eval $(opam config env) && \
    opam clean && \
    eval $(opam config env) && \
    cd sail-riscv && \
    #    ARCH=RV32 make && \
    ARCH=RV64 make && \
    #ln -s sail-riscv/c_emulator/riscv_sim_RV64 /usr/bin/riscv_sim_RV32 && \
    #ln -s sail-riscv/c_emulator/riscv_sim_RV32 /usr/bin/riscv_sim_RV64 && \
    cp c_emulator/riscv_sim_RV64 /usr/bin/riscv_sim_RV64 && \
    rm -rf /sail-riscv /riscv-opcodes

COPY . /workspace

RUN echo "PATH=$PATH:/opt/riscv/bin:/sail-riscv/c_emulator/" >> $HOME/.profile 

RUN cd /workspace/ && \
    riscof --verbose info arch-test --clone && \
    riscof validateyaml --config=config.ini && \
    riscof testlist --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env

WORKDIR /workspace

ENTRYPOINT [ "bash", "--login", "-c", " \
    riscof run --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env --work-dir=/workspace/output/riscof_work/ \
    " ]
