###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB rich_decoding "decoding/src/*cu")

allen_add_device_library(Rich STATIC
  ${rich_decoding}
)

target_link_libraries(Rich PRIVATE Backend HostEventModel EventModel Utils HostPrefixSum)

target_include_directories(Rich PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/decoding/include>)
