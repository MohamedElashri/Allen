################################################################################
# Package: AllenIntegration
################################################################################
gaudi_subdir(AllenIntegration v1r0)

gaudi_depends_on_subdirs(Online/OnlineKernel)

find_package(Boost REQUIRED)
find_package(Rangev3 REQUIRED)
include_directories(SYSTEM ${Boost_INCLUDE_DIRS} ${Rangev3_INCLUDE_DIRS})

include_directories(${CMAKE_SOURCE_DIR}/main/include)

# gaudi_install_headers()

gaudi_add_library(AllenIntegration
                  src/*.cpp
                  PUBLIC_HEADERS Integration
                  INCLUDE_DIRS Online/OnlineKernel
                  LINK_LIBRARIES OnlineKernel)
