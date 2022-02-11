###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB scifi_preprocessing "preprocessing/src/*cu")
file(GLOB scifi_looking_forward "looking_forward/src/*cu")
file(GLOB scifi_consolidate "consolidate/src/*cu")

allen_add_device_library(SciFi STATIC
  ${scifi_preprocessing}
  ${scifi_looking_forward}
  ${scifi_consolidate})

target_link_libraries(SciFi PRIVATE Backend HostEventModel EventModel Utils)

target_include_directories(SciFi PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/common/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/preprocessing/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/looking_forward/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/consolidate/include>)
