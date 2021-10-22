###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB host_clustering "src/*cpp")

allen_add_host_library(HostClustering STATIC ${host_clustering})

target_link_libraries(HostClustering PRIVATE EventModel Gear AllenCommon Backend)

target_include_directories(HostClustering PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
