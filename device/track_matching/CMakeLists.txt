###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB matching_match "match/src/*cu")
file(GLOB matching_consolidate "consolidate/src/*cu")

allen_add_device_library(track_matching STATIC
  ${matching_match}
  ${matching_consolidate}
)

target_link_libraries(track_matching PRIVATE Backend HostEventModel EventModel Utils)

target_include_directories(track_matching PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/match/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/consolidate/include>)

target_include_directories(WrapperInterface INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/common/include>)
