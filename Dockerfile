FROM nvidia/cuda:11.1-cudnn8-devel-centos8
RUN dnf install -y dnf-plugins-core epel-release && \
    dnf config-manager --set-enabled PowerTools
RUN dnf install -y -q \
                      boost-devel \
                      clang \
                      json-devel \
                      patch \
                      python3-devel \
                      openssl-devel \
                      ninja-build \
                      wget \
                      zeromq-devel \
                      zlib-devel && \
    dnf clean -q all

RUN wget -q https://cmake.org/files/v3.14/cmake-3.14.7-Linux-x86_64.sh -O /cmake-3.14.7-Linux-x86_64.sh && \
    mkdir /opt/cmake && \
    sh /cmake-3.14.7-Linux-x86_64.sh -q --prefix=/opt/cmake --skip-license && \
    ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake && \
    ln -s /opt/cmake/bin/ctest /usr/local/bin/ctest

WORKDIR /app/build
