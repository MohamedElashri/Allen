###############################################################################
# (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
file(GLOB backend_sources "src/*cpp")

# Vectorization interface library
add_library(Vectorization INTERFACE)
target_include_directories(Vectorization INTERFACE $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/external>)
install(TARGETS Vectorization EXPORT Allen)

# Backend library
allen_add_host_library(Backend STATIC ${backend_sources})
target_link_libraries(Backend PUBLIC Vectorization Gear Common)
target_include_directories(Backend PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
