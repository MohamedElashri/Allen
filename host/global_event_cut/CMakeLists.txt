###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB host_gec "src/*cpp")

allen_add_host_library(HostGEC STATIC
  ${host_gec}
)

target_link_libraries(HostGEC PRIVATE HostEventModel EventModel Gear Common Backend)

target_include_directories(HostGEC PUBLIC
  include
  ${CMAKE_SOURCE_DIR}/device/UT/common/include
  ${CMAKE_SOURCE_DIR}/device/SciFi/common/include)

include(mep_test.cmake)
