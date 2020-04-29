FROM nvidia/cuda:10.2-devel-centos7

RUN yum install -y -q zlib1g-dev git libx11-dev \
                    libxpm-dev libxft-dev libxext-dev python python-dev \
                    libboost-all-dev zlib1g-dev git libx11-dev libxpm-dev \
                    libxft-dev libxext-dev python python-dev cmake gcc-c++ \
                    centos-release-scl devtoolset-8-gcc devtoolset-8-gcc-c++ \
 > /dev/null
RUN yum install -y -q epel-release
RUN yum install -y -q devtoolset-8-gcc devtoolset-8-gcc-c++ zeromq-devel zlib-devel boost-devel
RUN yum group install -y "Development Tools"

ADD https://cmake.org/files/v3.14/cmake-3.14.7-Linux-x86_64.sh /cmake-3.14.7-Linux-x86_64.sh
RUN mkdir /opt/cmake
RUN sh /cmake-3.14.7-Linux-x86_64.sh --prefix=/opt/cmake --skip-license
RUN ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake
RUN ln -s /opt/cmake/bin/ctest /usr/local/bin/ctest
COPY . /app
WORKDIR /app/build
