################################################################################
# Package: AllenIntegration
################################################################################
gaudi_subdir(AllenIntegration v1r0)

gaudi_depends_on_subdirs(Online/OnlineKernel
                         Online/GaudiOnline
                         Online/DIM
                         Online/RPC
                         Online/ZeroMQ
                         Online/Parsers)

find_package(cppgsl REQUIRED)
find_package(ROOT REQUIRED)
find_package(Rangev3 REQUIRED)
find_package(ZMQ REQUIRED)
include_directories(SYSTEM ${Rangev3_INCLUDE_DIRS}  ${ZMQ_INCLUDE_DIRS})

find_package(MPI REQUIRED)
include_directories(SYSTEM ${MPI_CXX_INCLUDE_PATH})
add_compile_definitions(HAVE_MPI)

include_directories(${CMAKE_SOURCE_DIR}/main/include)

gaudi_add_module(AllenIntegration
                 src/*.cpp
                 INCLUDE_DIRS OnlineBase ROOT Online/DIM GaudiKernel cppgsl Online/OnlineKernel Online/ZeroMQ
                 LINK_LIBRARIES GaudiKernel GaudiAlgLib dim OnlineBase GaudiOnline MPI ZMQ ZMQLib RPC Parsers -lrt)
