################################################################################
# Package: AllenIntegration
################################################################################
gaudi_subdir(AllenIntegration v1r0)

gaudi_depends_on_subdirs(Online/OnlineKernel
                         Online/GaudiOnline
                         Online/DIM
                         Online/RPC
                         Online/ZeroMQ
                         Online/Parsers
                         Dumpers/BinaryDumpers)

find_package(cppgsl REQUIRED)
find_package(ZMQ REQUIRED)
find_package(Boost REQUIRED)
find_package(ROOT REQUIRED)
include_directories(SYSTEM ${Boost_INCLUDE_DIRS}
  ${ZMQ_INCLUDE_DIRS}
  ${CPPGSL_INCLUDE_DIR}
  ${ROOT_INCLUDE_DIRS})

# find_package(MPI REQUIRED)
# include_directories(SYSTEM ${MPI_CXX_INCLUDE_PATH})
# add_compile_definitions(HAVE_MPI)

include_directories(${CMAKE_SOURCE_DIR}/main/include)

gaudi_add_module(AllenIntegration
                 src/*.cpp
                 INCLUDE_DIRS OnlineBase ROOT Online/DIM GaudiKernel cppgsl Online/OnlineKernel Online/ZeroMQ
                 LINK_LIBRARIES GaudiKernel dim OnlineBase GaudiOnline ZMQ ZMQLib RPC Parsers
                                OnlineKernel AllenLib DAQEventLib DAQKernelLib GaudiAlgLib
                                PrKernel VPDetLib UTDetLib UTKernelLib
                                FTDetLib -lrt)
if(CMAKE_BUILD_TYPE STREQUAL Debug)
  target_compile_definitions(AllenIntegration PRIVATE ALLEN_DEBUG)
endif()
target_compile_definitions(AllenIntegration PRIVATE ALLEN_DEBUG)

if(TARGET_DEVICE STREQUAL "CPU")
  target_compile_definitions(AllenIntegration PRIVATE CPU)
endif()
