###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB pv_checker_sources "src/*cpp")

allen_add_host_library(PVChecking STATIC
  ${pv_checker_sources}
)
target_include_directories(PVChecking PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
target_link_libraries(PVChecking PRIVATE HostEventModel EventModel Gear Backend AllenCommon TrackChecking)
