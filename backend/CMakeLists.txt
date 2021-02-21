###############################################################################
# (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
include_directories(include)

file(GLOB backend_sources "src/*cpp")

# Vectorization interface library
add_library(Vectorization INTERFACE)
target_include_directories(Vectorization INTERFACE ${CMAKE_SOURCE_DIR}/external)

# Backend library
allen_add_host_library(Backend STATIC ${backend_sources})
target_link_libraries(Backend PUBLIC Vectorization Gear Common)
target_include_directories(Backend PUBLIC include)
