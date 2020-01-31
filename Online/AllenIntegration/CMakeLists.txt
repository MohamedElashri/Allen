################################################################################
# Package: AllenIntegration
################################################################################
gaudi_subdir(AllenIntegration v1r0)

gaudi_depends_on_subdirs(Online/OnlineKernel
                         Online/GaudiOnline
                         Online/DIM
                         Online/RPC
                         Online/Parsers)

find_package(Boost REQUIRED)
find_package(cppgsl REQUIRED)
find_package(ROOT REQUIRED)
find_package(Rangev3 REQUIRED)
include_directories(SYSTEM ${Boost_INCLUDE_DIRS} ${Rangev3_INCLUDE_DIRS})

include_directories(${CMAKE_SOURCE_DIR}/main/include)

gaudi_add_module(AllenIntegration
                 src/*.cpp
                 INCLUDE_DIRS OnlineBase ROOT Online/DIM GaudiKernel cppgsl Online/OnlineKernel
                 LINK_LIBRARIES GaudiKernel GaudiAlgLib dim OnlineBase GaudiOnline RPC Parsers -lrt)
