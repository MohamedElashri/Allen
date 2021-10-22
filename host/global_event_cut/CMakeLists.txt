###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB host_gec "src/*cpp")

allen_add_host_library(HostGEC STATIC
  ${host_gec}
)

target_link_libraries(HostGEC PRIVATE HostEventModel EventModel Gear AllenCommon Backend)

target_include_directories(HostGEC PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/device/UT/common/include>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/device/SciFi/common/include>)
