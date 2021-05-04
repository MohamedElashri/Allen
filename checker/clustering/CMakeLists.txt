###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB clustering "src/*cpp")
allen_add_host_library(CheckClustering STATIC
  ${clustering}
)

target_link_libraries(CheckClustering PRIVATE HostClustering EventModel Gear Backend TrackChecking)
target_include_directories(CheckClustering PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
set_property(TARGET CheckClustering PROPERTY
             CUDA_SEPARABLE_COMPILATION ON)
