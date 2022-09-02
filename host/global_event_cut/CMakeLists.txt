###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
set(host_gec_sources
  "src/HostSciFiGEC.cpp"
  "src/HostUTGEC.cpp")

allen_add_host_library(HostGEC STATIC
  ${host_gec_sources}
)

target_link_libraries(HostGEC PRIVATE HostEventModel EventModel Gear AllenCommon Backend)

target_include_directories(HostGEC PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/device/SciFi/common/include>)
