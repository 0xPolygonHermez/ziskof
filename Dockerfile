FROM ubuntu:24.04

# Install dependencies

RUN apt-get update && apt-get -y install python3 python3-pip git autoconf \
    automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev \ 
    gawk build-essential bison flex texinfo gperf libtool patchutils bc \ 
    zlib1g-dev libexpat-dev opam  build-essential libgmp-dev z3 pkg-config zlib1g-dev \
    gcc-riscv64-linux-gnu python3.12-venv libopenmpi3 libsodium-dev libopenmpi-dev \
    cmake openmpi-bin openmpi-common libomp5

RUN python3 -m venv test && \
    . test/bin/activate && \
    pip3 install git+https://github.com/riscv-non-isa/riscv-arch-test/#subdirectory=riscv-isac && \
    pip3 install git+https://github.com/riscv/riscof && \
    ln -s /test/bin/riscof /usr/local/bin/riscof

RUN git clone --recursive https://github.com/riscv/riscv-gnu-toolchain && \
    cd riscv-gnu-toolchain && \
    ./configure --prefix=/opt/riscv/ --with-arch=rv64imafdc --with-abi=lp64d && \ 
    make -j$(nproc) && \
    rm -rf /riscv-gnu-toolchain

RUN opam init -y --disable-sandboxing && \
    opam switch create 5.1.0 && \
    opam install sail -y && \
    eval $(opam config env) && \
    opam clean && \
    eval $(opam config env)
    
RUN git clone --recursive https://github.com/riscv/riscv-opcodes.git && \
    git clone https://github.com/riscv/sail-riscv.git && \
    eval $(opam config env) && \
    cd sail-riscv && \
    ./build_simulators.sh && \
    cp ./build/c_emulator/sail_riscv_sim /usr/bin/sail_riscv_sim && \
    rm -rf /sail-riscv /riscv-opcodes

COPY . /workspace

RUN echo "PATH=$PATH:/opt/riscv/bin:/sail-riscv/c_emulator/" >> $HOME/.profile 

RUN cd /workspace/ && \
    mkdir -p /workspace/output && \
    riscof --verbose info arch-test --clone && \
    riscof validateyaml --config=config.ini && \
    riscof testlist --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env

WORKDIR /workspace

ENTRYPOINT [ "bash", "--login", "-c", " \
    riscof run --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env --work-dir=/workspace/output/riscof_work/ \
    " ]
