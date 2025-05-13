
FROM nvidia/cuda:12.2.0-devel-rockylinux9
RUN dnf install 'dnf-command(config-manager)' -y && dnf config-manager --enable crb -y && dnf install epel-release -y 
RUN dnf upgrade -y
RUN dnf install git cmake clang-devel llvm-devel json-devel zeromq-devel zlib-devel root\* python3-pip tbb-devel zip unzip lbzip2 -y
RUN pip install wrapt cachetools pydot sympy clang==15.0.7
RUN ln -s /usr/lib64/libclang.so.15.0.7 /usr/lib64/libclang-15.so

RUN mkdir deps
WORKDIR /deps

RUN git clone https://github.com/microsoft/GSL.git &&\
    cd GSL &&\
    mkdir build && cd build &&\
    cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_GMOCK=OFF -DGSL_TEST=OFF -DINSTALL_GTEST=OFF .. &&\
    make -j && make install

RUN git clone https://github.com/catchorg/Catch2.git &&\
    cd Catch2 &&\
    mkdir build && cd build &&\
    cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCATCH_INSTALL_DOCS=OFF -DCATCH_INSTALL_EXTRAS=OFF .. &&\
    make -j && make install

RUN curl -L https://boostorg.jfrog.io/artifactory/main/release/1.82.0/source/boost_1_82_0.tar.gz -o boost_1_82_0.tar.gz &&\
    tar -xzf boost_1_82_0.tar.gz &&\
    cd boost_1_82_0 &&\
    ./bootstrap.sh &&\
    ./b2 -j 4 &&\
    ./b2 install

RUN git clone https://gitlab.cern.ch/lhcb/Gaudi.git
RUN git clone https://gitlab.cern.ch/lhcb/LHCb.git
RUN git clone https://gitlab.cern.ch/lhcb-datapkg/ParamFiles.git

RUN dnf install ninja-build bash-completion -y

ARG USERNAME=allenuser
RUN useradd -m $USERNAME

USER $USERNAME